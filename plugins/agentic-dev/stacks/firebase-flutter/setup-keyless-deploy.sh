#!/usr/bin/env bash
#
# Founder OS · Module 16 — stack blueprint: firebase-flutter
#
# One-time setup: Workload Identity Federation, so GitHub Actions can deploy
# Firebase Hosting, Firestore/Storage rules and Cloud Functions (2nd gen)
# keyless — no service-account key, no FIREBASE_TOKEN, nothing stored in
# GitHub secrets.
#
# It takes no arguments. The project id comes from .firebaserc and the
# repository from the `origin` remote, so the same script works unchanged in
# every project on this stack. Override with PROJECT_ID= / REPO= if needed.
#
#   ./scripts/setup-keyless-deploy.sh
#   ./scripts/setup-keyless-deploy.sh --dry-run
#
# Prerequisite: `gcloud auth login` with an account holding roles/owner (or
# the equivalent IAM-, WIF- and service-account-admin roles) on the project.
# It creates and modifies IAM, so a human runs it — not an agent inside the
# development loop.
#
# Idempotent. Re-running it is safe, and is the right first move whenever a
# deploy fails on a permission.
#
# Background, diagram and the table of known failures:
#   .founder-os/stacks/firebase-flutter/keyless-deploy.md

set -euo pipefail

DRY=0
case "${1:-}" in
  --dry-run) DRY=1 ;;
  "")        ;;
  *) echo "unknown option: $1" >&2; exit 2 ;;
esac

run() { if [ "$DRY" = "1" ]; then printf '    [dry-run] %s\n' "$*"; else "$@"; fi; }

# --------------------------------------------------------------------------- #
# Where are we?
# --------------------------------------------------------------------------- #
command -v gcloud >/dev/null || { echo "gcloud is not installed." >&2; exit 1; }

if [ -z "${PROJECT_ID:-}" ]; then
  [ -f .firebaserc ] || { echo "No .firebaserc here and PROJECT_ID is unset." >&2; exit 1; }
  PROJECT_ID="$(python3 -c 'import json;print(json.load(open(".firebaserc"))["projects"]["default"])')"
fi

if [ -z "${REPO:-}" ]; then
  ORIGIN="$(git remote get-url origin 2>/dev/null || true)"
  [ -n "$ORIGIN" ] || { echo "No git remote 'origin' and REPO is unset." >&2; exit 1; }
  # git@github.com:owner/repo.git | https://github.com/owner/repo(.git)
  REPO="$(printf '%s' "$ORIGIN" | sed -E 's#^.*github\.com[:/]##; s#\.git$##')"
fi

POOL_ID="${POOL_ID:-github}"
PROVIDER_ID="${PROVIDER_ID:-github-oidc}"
SA_NAME="${SA_NAME:-github-hosting-deployer}"
SA_EMAIL="${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"

case "$REPO" in
  */*) ;;
  *) echo "Could not read owner/repo from the origin remote: '$REPO'" >&2; exit 1 ;;
esac

echo "==> Project:    ${PROJECT_ID}"
echo "==> Repository: ${REPO}"
[ "$DRY" = "1" ] && echo "==> dry run — nothing will be changed"
run gcloud config set project "${PROJECT_ID}"

# --------------------------------------------------------------------------- #
# 1. APIs
# --------------------------------------------------------------------------- #
# The indirect ones matter as much as the obvious ones: 2nd-gen Functions pull
# in Cloud Run, Cloud Build, Artifact Registry, and — for triggers — Eventarc
# and Pub/Sub. serviceusage lets the deploy enable a service identity it
# discovers it needs mid-run instead of failing.
echo "==> Enabling the APIs the deploy touches"
run gcloud services enable \
  iamcredentials.googleapis.com \
  sts.googleapis.com \
  cloudresourcemanager.googleapis.com \
  serviceusage.googleapis.com \
  firebasehosting.googleapis.com \
  firebaserules.googleapis.com \
  cloudfunctions.googleapis.com \
  run.googleapis.com \
  artifactregistry.googleapis.com \
  cloudbuild.googleapis.com \
  eventarc.googleapis.com \
  pubsub.googleapis.com \
  storage.googleapis.com \
  secretmanager.googleapis.com \
  compute.googleapis.com \
  cloudbilling.googleapis.com

PROJECT_NUMBER="$(gcloud projects describe "${PROJECT_ID}" --format='value(projectNumber)' 2>/dev/null || echo "PROJECT_NUMBER")"
echo "==> Project number: ${PROJECT_NUMBER}"

# --------------------------------------------------------------------------- #
# 2. The deployer service account
# --------------------------------------------------------------------------- #
echo "==> Deployer service account"
if gcloud iam service-accounts describe "${SA_EMAIL}" >/dev/null 2>&1; then
  echo "    already exists: ${SA_EMAIL}"
else
  run gcloud iam service-accounts create "${SA_NAME}" \
    --display-name="GitHub Actions Firebase Deployer"
fi

# cloudfunctions.admin, not .developer: deploying a NEW public HTTPS function
# sets an IAM policy on it (cloudfunctions.functions.setIamPolicy), which
# `developer` may not do. The role is enough right up until the first public
# endpoint, which is exactly why this bites late.
#
# secretmanager.admin, not .viewer: a function using defineSecret makes the
# deploy bind the runtime identity as secretAccessor — that needs
# secrets.setIamPolicy. Without it the run fails AFTER Hosting is already live.
echo "==> Granting the deployer the roles a full deploy needs"
for ROLE in \
  roles/firebasehosting.admin \
  roles/firebaserules.admin \
  roles/cloudfunctions.admin \
  roles/run.admin \
  roles/artifactregistry.admin \
  roles/cloudbuild.builds.editor \
  roles/iam.serviceAccountUser \
  roles/storage.admin \
  roles/secretmanager.admin \
  roles/datastore.indexAdmin \
  roles/serviceusage.serviceUsageAdmin
do
  run gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
    --member="serviceAccount:${SA_EMAIL}" \
    --role="${ROLE}" \
    --condition=None
done

# --------------------------------------------------------------------------- #
# 3. The identity that actually builds and runs the functions
# --------------------------------------------------------------------------- #
# Cloud Functions (2nd gen) build AND run as the *default Compute Engine*
# service account, not as the deployer. Since ~Sept 2024 new projects no
# longer grant it Editor automatically, so it needs these explicitly. Without
# them the build fails ("missing permission on the build service account") or
# the function fails at runtime ("PERMISSION_DENIED" on its own Firestore
# writes through the Admin SDK) — two very different-looking errors, one cause.
COMPUTE_SA="${PROJECT_NUMBER}-compute@developer.gserviceaccount.com"
echo "==> Granting the default Compute Engine SA (${COMPUTE_SA}) build + runtime roles"
for ROLE in \
  roles/cloudbuild.builds.builder \
  roles/artifactregistry.writer \
  roles/storage.objectViewer \
  roles/logging.logWriter \
  roles/datastore.user
do
  run gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
    --member="serviceAccount:${COMPUTE_SA}" \
    --role="${ROLE}" \
    --condition=None
done

# --------------------------------------------------------------------------- #
# 4. Workload Identity Federation
# --------------------------------------------------------------------------- #
echo "==> Workload Identity Pool"
if gcloud iam workload-identity-pools describe "${POOL_ID}" --location=global >/dev/null 2>&1; then
  echo "    already exists: ${POOL_ID}"
else
  run gcloud iam workload-identity-pools create "${POOL_ID}" \
    --location=global --display-name="GitHub Actions"
fi

# The attribute-condition is the actual lock. A fork presents a token naming a
# different repository and the exchange fails here, server-side — which is why
# the provider path and the SA e-mail may sit in plain sight in the workflow.
# To restrict production to one branch as well, add:
#   && assertion.ref == 'refs/heads/main'
echo "==> OIDC provider, scoped to ${REPO}"
if gcloud iam workload-identity-pools providers describe "${PROVIDER_ID}" \
     --location=global --workload-identity-pool="${POOL_ID}" >/dev/null 2>&1; then
  echo "    already exists: ${PROVIDER_ID}"
  echo "    (check its attribute-condition names ${REPO} if this project was copied from another)"
else
  run gcloud iam workload-identity-pools providers create-oidc "${PROVIDER_ID}" \
    --location=global \
    --workload-identity-pool="${POOL_ID}" \
    --display-name="GitHub OIDC" \
    --attribute-mapping="google.subject=assertion.sub,attribute.repository=assertion.repository,attribute.ref=assertion.ref" \
    --attribute-condition="assertion.repository == '${REPO}'" \
    --issuer-uri="https://token.actions.githubusercontent.com"
fi

echo "==> Allowing only ${REPO} to impersonate the deployer"
run gcloud iam service-accounts add-iam-policy-binding "${SA_EMAIL}" \
  --role="roles/iam.workloadIdentityUser" \
  --member="principalSet://iam.googleapis.com/projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/${POOL_ID}/attribute.repository/${REPO}"

WIF_PROVIDER="projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/${POOL_ID}/providers/${PROVIDER_ID}"

cat <<EOF

==================================================================
Setup complete. These two values go into .github/workflows/deploy-main.yml.
They are NOT secrets — access is restricted server-side by the provider's
attribute-condition (repository == ${REPO}):

  workload_identity_provider: ${WIF_PROVIDER}
  service_account:            ${SA_EMAIL}

Still to do by hand, once per project:
  - Blaze billing enabled (2nd-gen Functions require it)
  - firebase hosting:sites:create … and firebase target:apply …
==================================================================
EOF
