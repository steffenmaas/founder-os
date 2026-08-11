# Stack blueprints

A **stack blueprint** is the answer to "what do we build this on, and how does it get live"
— written down once, for every project that uses the same building blocks.

> **This repository is public.** A blueprint therefore names building blocks, roles and
> failure modes — never a project id, project number, service-account address, hostname or
> repository name. Everything project-specific is derived at setup time from the project's
> own `.firebaserc` and git remote. `validate.py` fails the build if a concrete identifier
> creeps back in.

It exists because the same setup was done twice, by hand, in two projects, and the second
time cost almost as much as the first: the same IAM roles missing, the same deploy failing
after Hosting had already gone out, the same afternoon spent reading the same error message.
A blueprint turns that into a script, a diagram and a table of known failures.

## What a blueprint contains

A blueprint covers the **whole programme** for a product that runs and is published — not
just the happy path of writing code.

| File | What it is for |
|---|---|
| `STACK.md` | The building blocks: what is used, which version, and **why** — including what was deliberately not chosen. The architecture diagram and the index of the rest live here. |
| `auth-and-data.md` | Identity, the security-rule shapes that carry the authorisation, storage, data-model conventions. |
| `payments.md` | Taking money without the client deciding what anything costs or grants. |
| `observability.md` | Error reporting, the visible build id, consent-gated analytics, what to check after a deploy. |
| `keyless-deploy.md` | How code gets from a merge to production without a single long-lived credential. Diagram, one-time setup, and the failure-mode table. |
| `ops-watch.md` | Monitoring with no human login in the path: public signals, a scheduled read-only CI watch, managed uptime checks. Failures become backlog items mechanically. |
| `going-live.md` | The publishing project: legal pages, account deletion, the pre-launch checklist, store submission. |
| `setup-keyless-deploy.sh` | The one-time setup, idempotent, parameterless — it reads the project from the repo. Creates the deployer **and** the read-only monitor identity. |
| `deploy-main.yml` | The deploy workflow, ready to copy. |
| `ops-watch.yml` | The scheduled watch workflow, ready to copy. |

## Available blueprints

| Blueprint | Used by | For |
|---|---|---|
| [`firebase-flutter/`](firebase-flutter/STACK.md) | 2 production projects | One Flutter codebase for web and mobile, Firebase as the backend, GitHub Actions deploying keyless to Google Cloud. |

## How to use one

In a project running the module:

```
/dev-stack firebase-flutter
```

It writes `scripts/setup-keyless-deploy.sh`, `.github/workflows/deploy-main.yml` and
`docs/deployment.md` into the project, filled in with that project's real values. You then
run the setup script once with an account that can administer IAM. Details in the skill.

Without Claude Code, copy the two files out of `.founder-os/stacks/<blueprint>/` by hand.

## The rule that makes this worth having

**A failure that cost one project an afternoon is written here, not in that project's
history.** When a deploy breaks in a way the blueprint does not describe, the fix goes into
this repository as an upstream learning (`/dev-learn --upstream`), and every other project
gets it on the next update. That is the whole point: the second project never pays for the
first project's lesson.

Concretely, that means the failure-mode tables in these blueprints are **not documentation
of the past**. They are the reason the next setup works on the first try.

## Adding a blueprint

Only add one for a stack that is actually running in more than one place, or is about to be.
A blueprint written speculatively is a guess with a directory around it.

1. `stacks/<name>/STACK.md` — building blocks, versions, rejected alternatives, diagram.
2. The setup script — idempotent, and it derives project identifiers from the repository
   rather than asking for them.
3. The failure modes — each one with its **error message verbatim**, the cause, and the fix.
   The error message is what someone searches for at 23:00; without it the entry is decoration.
4. Register it in the table above and in [`../README.md`](../README.md).
