# IAM repair — fixing missing permissions without a human login

## The question this answers

A deploy fails on a missing IAM role. Today that means: a human runs `gcloud auth login`
with owner rights and re-runs the setup script — the one remaining task that still drags
a person and a laptop into the credential path. Can that be keyless too?

Yes — but not the way the deploy and the watch are. Those identities are *bounded*: the
deployer can ship, the monitor can read logs, and neither can do more. **An identity that
can write IAM is not bounded — `setIamPolicy` on the project is owner in practice**, because
it can grant anyone anything, including itself. So the design question is never "keyless
yes or no"; it is *who grants the granter, and what stops the granter from granting
everything*.

## Stage note — who pulls the trigger depends on what is at stake

Everything below describes the **`live` posture**. In `pre-live` (deploy-gate.md, stage
dial) the same workflow may be **triggered by the loop itself** via the API — nothing is
live, a wrong grant costs a revision, and waiting overnight on a click costs more. See
[`stage-access.md`](stage-access.md). The mechanism never changes: the only payload is the
reviewed script, the identity is short-lived, and going live returns the trigger to the
human.

## The answer: a click-gated workflow whose only API is the script

[`iam-repair.yml`](iam-repair.yml) — a workflow that:

- runs **only on `workflow_dispatch`**. No cron, no push trigger. A human click is the
  gate — one click, from any device, instead of a laptop login.
- executes **exactly one thing**: `./scripts/setup-keyless-deploy.sh`, the idempotent
  converger. No free-form `gcloud`, no inputs that become commands. The only way to change
  what it can do is a reviewed change to the script on `main`.
- authenticates as its **own** service account (`github-iam-admin`) through the same WIF
  provider as everything else.

That closes the loop this stack already lives by: a deploy fails on a permission → the
failure becomes an upstream learning → the setup script gains the role → **one click**
applies it — no laptop, no login, no key.

```
deploy fails on a role  →  learning → script updated on main  →  Run workflow  →  fixed
                                                                  (the only human act)
```

## What the admin identity holds — and the honest boundary

The setup script needs, and `github-iam-admin` gets, exactly:

| Role | Why |
|---|---|
| `roles/resourcemanager.projectIamAdmin` | grant roles on the project — **this is the owner-equivalent one** |
| `roles/iam.serviceAccountAdmin` | create the deployer/monitor SAs, bind impersonation |
| `roles/iam.workloadIdentityPoolAdmin` | create/repair the pool and provider |
| `roles/serviceusage.serviceUsageAdmin` | enable APIs |

Be clear-eyed about the boundary: with `projectIamAdmin`, this identity **is** the project.
The protections are therefore about *reaching* it, not about what it could do once reached:

1. **The provider's attribute condition** — only this repository's workflows can exchange
   a token at all (server-side, fork-proof).
2. **`workflow_dispatch` only** — nothing automatic ever wakes it.
3. **The script is the only payload** — changing what runs requires a merge to `main`,
   which branch protection routes through review and CI.
4. Optional, for teams: bind the workflow to a GitHub **environment with a required
   reviewer** — then a second person approves every run.

The residual trust statement, said out loud: **whoever can merge to `main` can reach
project-owner power via this workflow.** For a solo founder with branch protection that is
the same trust boundary the deployer already sits behind (whoever merges can ship code to
production). If that boundary is not acceptable, do not create this identity — keep the
one-time human `gcloud auth login` for IAM changes, or use Privileged Access Manager
(next section).

## The complement: Privileged Access Manager (JIT elevation)

Google's **Privileged Access Manager** (IAM & Admin → Privileged Access Manager, no extra
cost) solves a *different* half of the problem, and the two compose:

- **This workflow removes the human from the routine path** — converging IAM to the
  script's declared state needs nobody's login.
- **PAM removes the *standing* privilege from the human** — for everything the script
  does not cover: ad-hoc console work, debugging, one-off grants.

How PAM works, concretely:

1. **An entitlement** is configured once: *this person may request `roles/owner` (or
   `projectIamAdmin`) on this project, for at most N hours, with a written justification,
   with or without a second person's approval.*
2. **Day to day the account holds almost nothing** — viewer-level roles. There is no
   standing owner to steal, phish, or fat-finger.
3. **When elevation is needed**, the person requests it (console, or
   `gcloud pam grants create`), states the reason, and — if configured — an approver
   confirms. The role is bound temporarily and **expires by itself**. Request,
   justification, approval and expiry all land in the audit log.

The honest assessment for a solo founder: without a second person, approval is
self-approval, so PAM does not protect against your account being compromised — the
attacker can request elevation too (it is at least logged). Its solo value is **damage
limitation and hygiene**: no standing owner for a stolen laptop to inherit, no accidental
production change from an account that is owner all day, and a written record of every
elevation. With a co-founder as approver it becomes a real four-eyes control.

What PAM does **not** do: remove logins from automation. A scheduled job cannot "request
elevation" without credentials to ask with — automation stays on WIF. Rule of thumb:

| Need | Tool |
|---|---|
| Routine IAM convergence, no human involved | this workflow |
| Ad-hoc human work without standing owner rights | PAM |
| Automation of any kind | WIF — never PAM, never a key |

## Bootstrap — the one unavoidable human act

Someone with owner rights runs the setup script **once** (it now also creates
`github-iam-admin`). After that, IAM repair never needs a local login again. There is no
way around this first step: the granter cannot grant itself into existence.

```bash
gcloud auth login                                    # owner — the last time this is needed for IAM
CREATE_IAM_ADMIN=1 ./scripts/setup-keyless-deploy.sh # opt-in: the admin SA is never created silently
cp .founder-os/stacks/firebase-flutter/iam-repair.yml .github/workflows/iam-repair.yml
# fill in the two printed values, commit
```

The `CREATE_IAM_ADMIN=1` opt-in is deliberate: the deploy and monitor identities are safe
defaults, an owner-equivalent identity is a decision. Running the script without the flag
never creates or touches it.

Then verify it once end to end: Actions → iam-repair → Run workflow → the script reports
every grant as "already exists" (idempotent) and the run is green. A repair path that has
never been exercised will fail exactly when a deploy is already red.

## Why not an MCP server instead?

The alternative — wiring a Google Cloud / Firebase MCP server into Claude so the agent can
fix IAM — fails the same test twice:

- **It does not solve identity.** An MCP server runs where its credentials live: locally
  that is your `gcloud` ADC (the very session that expires daily and brought you here), or
  a service-account key (a standing secret — rejected outright). Keyless OIDC exists in CI,
  not on a laptop.
- **It widens the blast radius.** Owner-equivalent power behind LLM tool calls means a
  prompt injection anywhere in the agent's context — an issue body, a log line, a fetched
  page — is one step from `setIamPolicy`. The module's own security rules treat injected
  instructions as a finding precisely because this class of wiring makes them lethal.

MCP is fine for **read-only diagnosis** (logs, deploy state) — but the read side is already
covered keyless by [`ops-watch.md`](ops-watch.md), scheduled, with no human in the path.
For writes, the reviewed-script-behind-a-click is strictly safer than any conversational
path to the same power.
