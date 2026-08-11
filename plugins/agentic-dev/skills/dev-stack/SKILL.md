---
name: dev-stack
description: Sets a project up on a proven stack blueprint — the building blocks, the keyless deploy script, the deploy workflow and the deployment documentation, filled in with this project's real values. Use this skill when the user says "set up deployment", "keyless deploy", "WIF", "wire up Firebase", "which stack", "stack blueprint" or any natural variant, or when a project has no working path from a merge to production. Module 16 (Agentic Dev) — Product & Tech Delivery. Pre-Seed.
---

# Stack blueprint — put this project on a known-good stack

This skill is part of the **Founder OS** plugin, Module 16 — Agentic Dev (Product & Tech Delivery).

**Blueprints:** `.founder-os/stacks/` · **Contract:** `.founder-os/contracts/dev-agent.md`

> A blueprint is not a suggestion about architecture. It is the setup two production
> projects converged on after paying for every wrong turn once. The value is the failure
> table, not the file list.

## When to trigger

- "set up deployment" · "deploy this" · "keyless deploy" · "WIF" · "OIDC"
- "wire up Firebase" · "which stack should we use" · "stack blueprint"
- `founder-os:dev-stack`
- Automatically when the project has **no path from a merge to production** — no deploy
  workflow, or one that has never run green.

**Argument:** `$ARGUMENTS` — the blueprint name, e.g. `firebase-flutter`. Absent, pick one
by detection (step 1).

---

## Step 1 — Which blueprint

```bash
ls .founder-os/stacks/
```

Detect what the project already is, and do not argue with it:

```bash
ls app/pubspec.yaml firebase.json .firebaserc functions/package.json 2>/dev/null
ls package.json next.config.* 2>/dev/null
cat .firebaserc 2>/dev/null
git remote get-url origin
```

- `pubspec.yaml` + `firebase.json` → `firebase-flutter`.
- Nothing matches any blueprint → **say so and stop.** Offer to write the deploy workflow
  from `templates/project/.github/workflows/deploy.yml` instead. Do not bend a blueprint
  onto a stack it was not written for; a half-fitting blueprint is worse than none, because
  its failure table then describes failures that cannot happen here.

Read the blueprint before writing anything:

```bash
cat .founder-os/stacks/<name>/STACK.md
cat .founder-os/stacks/<name>/keyless-deploy.md
```

## Step 2 — Gather this project's real values

Never leave a `<placeholder>` behind. A workflow full of them is a workflow that fails on
the first run and teaches the founder that the module does not work.

| Value | Where it comes from |
|---|---|
| Project id | `.firebaserc` → `projects.default` |
| Repository | `git remote get-url origin` → `owner/repo` |
| Hosting targets | `.firebaserc` → `targets.<project>.hosting` keys |
| Live URLs | the Hosting sites those targets map to |
| Functions runtime | `functions/package.json` → `engines.node` |

Anything you cannot derive, **ask once, bundled** — not one question at a time. If the
project has no Firebase project yet, say which console steps the founder has to do first
(create the project, enable Blaze billing) and stop there; those cannot be scripted.

## Step 3 — Write the files

```bash
mkdir -p scripts .github/workflows docs
cp .founder-os/stacks/<name>/setup-keyless-deploy.sh scripts/setup-keyless-deploy.sh
chmod +x scripts/setup-keyless-deploy.sh
cp .founder-os/stacks/<name>/deploy-main.yml .github/workflows/deploy-main.yml
```

The setup script is copied **unchanged** — it derives project and repository itself, and
editing it per project is how two copies drift apart. The workflow is copied and then
filled in with the values from step 2.

**A file that already exists is never overwritten.** If `.github/workflows/deploy-main.yml`
is there, diff it against the blueprint and report the differences as findings — each one is
either something this project needs and the blueprint should learn (step 6), or drift that
should be removed.

Then write `docs/deployment.md`: what deploys where, the one-time setup, and a link to
`.founder-os/stacks/<name>/keyless-deploy.md` for the diagram and the failure table. Do not
copy the failure table into the project — it is maintained upstream, and a copy goes stale
in exactly the way this whole blueprint exists to prevent.

## Step 4 — The parts a human must do

Print these as a checklist. They involve billing or IAM and are **not** for an agent:

1. `gcloud auth login` with an account holding owner rights on the project.
2. `./scripts/setup-keyless-deploy.sh` — once. It prints the two values for the workflow.
3. Paste those two values into `.github/workflows/deploy-main.yml`.
4. Billing on Blaze, Hosting sites created, targets applied (`firebase target:apply`).

Offer `./scripts/setup-keyless-deploy.sh --dry-run` first — it shows every IAM change
without making one.

## Step 5 — Verify, before calling it done

```bash
python3 -c "import yaml,sys;yaml.safe_load(open('.github/workflows/deploy-main.yml'))"
bash -n scripts/setup-keyless-deploy.sh
grep -n '<[a-zA-Z]' .github/workflows/deploy-main.yml   # must print nothing
```

The deploy itself is verified by the first push to `main` going green **and** the verify job
confirming the live build carries that commit. Until that has happened once, the correct
status is `OPEN`, not `BUILT`.

## Step 6 — When something in here was wrong

A deploy that fails for a reason the blueprint's failure table does not cover is a gap in the
blueprint, not a quirk of this project. Write a learning with `scope: upstream` and run
`/dev-learn --upstream`. That is what stops the next project from paying for it again.

## Report

```
BLUEPRINT: <name> — <why it fits>
WRITTEN:   <files, with the values filled in>
YOURS:     <the human steps, in order>
OPEN:      <what cannot be verified until the first deploy runs>
```
