# Access by stage — pre-live, the loop never waits on a human for infrastructure

## The failure this exists for

In recent pre-live projects the loop repeatedly stalled on infrastructure a human had to
provide: a new database had to be created, new IAM roles had to be granted — and the loop
waited, sometimes overnight, on things that could not have broken anything because
**nothing was live**. Pre-live, an infrastructure wait is pure lost speed: no users, no
revenue, no data anyone would miss. The posture (deploy-gate.md, `stage`) is therefore:

> **In `pre-live`, every permission and access the loop could need is provisioned up
> front, and what was missed can be self-served — the loop creates databases, roles and
> resources itself instead of queueing a request into an empty room.**

From `live` on, the restrictive doctrine returns ([`iam-repair.md`](iam-repair.md)): the
click gate, the read-only monitor, the bounded write paths. The stage dial is what
reconciles the two — both are right, at different moments.

## The stage-1 provisioning package

Run once at project creation, with owner rights — after this, no human is in the loop's
infrastructure path until go-live:

| # | What | How |
|---|---|---|
| 1 | Deployer + monitor + **admin identity** | `CREATE_IAM_ADMIN=1 ./scripts/setup-keyless-deploy.sh` — in `pre-live` the admin identity is the **default**, not the exception |
| 2 | **Self-served IAM repair** | Pre-live, the loop itself may trigger `iam-repair.yml` (`workflow_dispatch` fires via the GitHub API — `gh workflow run iam-repair.yml`). Missing role → the loop converges IAM and continues, no click. **At `live`, the human click returns** — that is part of the go-live checklist. |
| 3 | Databases and resources | The admin path covers creating Firestore databases, indexes, buckets and secrets. Creating a resource pre-live is always allowed; deleting one still needs the founder (it may hold test data someone relies on). |
| 4 | Logs | The monitor identity reads them keyless (`ops-watch.md`); pre-live the loop may also dispatch ad-hoc log queries through the same lane. |
| 5 | **Service MCPs on the founder's machine** | `.mcp.json` in the project wires the **Firebase MCP server** (`npx -y firebase-tools@latest mcp`, experimental — Firestore browse/query, auth users, deploy state) and the **Stripe MCP** (test-mode key ONLY pre-live). Interactive sessions then see databases and payments directly. |

## The two access lanes — and why MCP alone is not the answer

An MCP server runs where its credentials live. On the founder's machine that is `gcloud`
ADC — fine for interactive sessions. **The autonomous cloud loop has no such credentials
and must not get long-lived ones** (keyless doctrine). So:

| Lane | Who | Carries |
|---|---|---|
| **MCP lane** | Interactive sessions on a machine with ADC | Firebase MCP, Stripe MCP (test mode) — inspect, query, create in conversation |
| **WIF lane** | The autonomous loop, CI, scheduled runs | The dispatchable workflows: deploy, ops-watch, iam-repair — every privileged action is a bounded, reviewed script under a short-lived identity |

Pre-live loosens **who may pull the trigger** on the WIF lane (the loop itself) — it never
replaces the lane with a standing credential.

## Backups — required before anything real depends on the data

Pre-live "nothing can break" has one honest exception: the moment test data represents
real work (seeded content, tuning, early testers), losing it costs days. So:

- **Enable Firestore point-in-time recovery** (7-day window) as soon as the database
  exists, and a **daily scheduled backup** with weekly retention:
  ```bash
  gcloud firestore databases update --database='(default)' --enable-pitr
  gcloud firestore backups schedules create --database='(default)' \
    --recurrence=daily --retention=7d
  ```
- **Storage:** turn on object versioning for buckets holding user or content uploads.
- **Restore is a drill, not a hope:** before `live`, restore one backup into a scratch
  database once and prove the app reads it. A backup that has never been restored is a
  wish. This drill is a go-live checklist item ([`going-live.md`](going-live.md)).
- The backup schedule itself is created through the admin path — pre-live the loop can do
  it, which means **"no backups yet" is a `T` package, never a founder task.**

## Go-live flips the dial

Entering `live` (founder decision, `stage: live` in the config) means, on this stack:
self-served IAM repair off (click returns) · Stripe MCP stays test-mode until the live-key
decision is its own gated step · backups verified by an actual restore · the deploy gate's
full checklist active. The speed was real, and it ends exactly where real users begin.
