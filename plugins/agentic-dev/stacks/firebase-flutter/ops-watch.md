# Ops watch — monitoring that never asks a human to log in

## The problem this solves

The deploy is keyless, but the *watching* was not: checking function logs, deploy state or
the live version meant `gcloud auth login` / `firebase login` on a laptop — and Google
expires user sessions after hours, so somebody re-authenticated **every day** just so the
project could look at itself. That is not an inconvenience; it is a design fault:

> **A monitoring setup that depends on a human's login session has a human as its
> scheduler.** The day they are busy, sick or on a plane, the project goes unwatched —
> and unwatched is exactly when the silent deploy failure happens.

The fix is never a longer-lived token. A service-account key export or a `firebase
login:ci` token would "solve" the daily login by planting a long-lived credential — the
precise thing the keyless design exists to avoid. The fix is to give the watching the same
identity model the deploy already has: **short-lived, machine-minted, renewed by the
platform, scoped read-only.**

---

## Three layers, by how much identity they need

| Layer | Identity | What it catches | Runs |
|---|---|---|---|
| **0 — Public signals** | none | site down, wrong version live, stale service worker | every check, free |
| **1 — Scheduled CI watch** | WIF (OIDC), read-only SA | function errors, failed/silent deploys, version drift | GitHub Actions cron |
| **2 — Managed uptime checks** | Google-internal | outage while GitHub itself is down; alerting independent of the repo | Google, continuously |

The order matters: everything that *can* be checked anonymously should be, because an
unauthenticated check has no credential to expire, no quota to hit and no setup to rot.

### Layer 0 — public signals, zero auth

The stack already exposes them ([`observability.md`](observability.md)):

- `/build-id.json` — which commit is actually live. Comparing it to `main` detects the
  silent non-deploy, the failure class that historically went unnoticed for days.
- A health endpoint (or simply the app shell answering 200).

Anyone — a cron, a phone, a status page — can check these. No Google identity involved.

### Layer 1 — the scheduled watch (the core of this concept)

A GitHub Actions workflow on a cron ([`ops-watch.yml`](ops-watch.yml)), authenticating
through the **same Workload Identity provider as the deploy** but as a **separate,
read-only service account**. Every ~30 minutes, forever, with no standing credential
anywhere:

1. **Live version matches `main`** (layer 0 signals, evaluated with context: a deploy
   currently running is not drift; a deploy that *concluded* without landing is).
2. **The last deploy run is green.** A red deploy that nobody saw is the incident from
   `deploy-gate.md` — this makes it impossible to miss.
3. **Function error logs since the last tick.** `gcloud logging read` with
   `severity>=ERROR` over the cron window — the runtime `PERMISSION_DENIED`s and crash
   loops that only show up under real traffic.

**The response is tiered, and detection stays deterministic.** A watch that treats every
deviation as an incident trains everyone to ignore it. Three tiers, decided by plain
thresholds in the workflow (no model in the detection path):

| Tier | Signal | Response |
|---|---|---|
| **Note** | a single soft miss (one slow probe, one transient error) | log in the run summary, no issue |
| **Diagnose** | repeated misses or error-log findings | file/update the issue with the evidence — read-only diagnosis, no fix attempted |
| **Act** | version drift with a green deploy, red deploy run, site down | the issue is filed as a `B` package candidate; the loop pulls it under the backlog doctrine (bugs outrank features) and proposes the fix as a PR |

**Founder dismissals tune the thresholds.** An issue closed as "not a problem" is not
noise to swallow silently — it is calibration: the workflow's threshold for that check is
raised in the same commit that closes the discussion. A watch nobody has to dismiss twice
for the same reason stays trusted.

**On failure it files a GitHub issue** (one, updated — not a new one per tick). That
closes the loop: the issue lands in the backlog as `source: ops-watch`, the autonomous
loop pulls it as a bug — bugs outrank features (`backlog.md`) — and GitHub notifies the
founder by mail without any new channel. An incident becomes a work item mechanically,
not when someone happens to look.

Why a **separate monitor SA** instead of reusing the deployer: the deployer can write to
production; a watcher never needs to. If the watch workflow is ever compromised via a
malicious action dependency, a read-only identity turns "attacker can deploy" into
"attacker can read logs". Two lines in the setup script buy that boundary.

### Layer 2 — managed uptime checks

One-time console setup (Cloud Monitoring → Uptime checks → check the app URL + alerting
policy to your e-mail; add a **billing budget alert** while there). Google then probes
from outside your infrastructure — this is the layer that still works when GitHub
Actions, your repo or your WIF config is itself the broken thing. It is deliberately
redundant with layer 1: monitoring that shares a failure domain with what it monitors is
a mirror, not a watchdog.

---

## Why your `gcloud` asks you daily — and what actually changes

Local `gcloud auth login` / `firebase login` mint **user** credentials; Google Cloud
session control commonly caps these at 16–24 h, and no flag extends them sustainably.
Every scheme that keeps monitoring on a laptop therefore ends in one of three places:
a human logging in daily (today's state), an exported key (a standing secret — rejected),
or a machine identity in CI (this concept).

After adopting this, the remaining human involvement is **two one-time acts**, both
minutes, neither recurring:

1. Run the setup script once with owner rights (extends the existing WIF setup).
2. Click the uptime check and budget alert together in the console once.

Daily manual authentication: gone. A laptop is no longer part of the monitoring path.

---

## Setup

```bash
# 1. One-time IAM (idempotent, extends the deploy setup — adds the read-only monitor SA)
./scripts/setup-keyless-deploy.sh

# 2. Copy the workflow, fill in the two printed values
cp .founder-os/stacks/firebase-flutter/ops-watch.yml .github/workflows/ops-watch.yml
```

The script prints `workload_identity_provider` and the **monitor** SA e-mail; they go into
`ops-watch.yml` exactly as with the deploy workflow. They are not secrets — access is
locked server-side to this repository by the provider's attribute condition
([`keyless-deploy.md`](keyless-deploy.md)).

Then trigger it once by hand (Actions → ops-watch → Run workflow) and verify both
outcomes: a green run, and — by temporarily pointing the version check at a wrong URL —
that a red run really files the issue. **A watchdog that has never been seen barking is
decoration.**

## What this does not cover

Client-side errors (caught by error reporting, `observability.md`), cost anomalies (budget
alert, layer 2), and anything requiring write access — by design. The watch reads and
files issues; fixing remains the loop's job, shipping remains gated by `deploy-gate.md`.
