<!--
  TEMPLATE — copy to the repository root as CLAUDE.md.
  Replace everything in <ANGLE BRACKETS>. DELETE anything that does not apply.

  Rule of thumb for every line in this file:
  "Would an agent make a mistake without this line?" If no: cut it.
  An overloaded CLAUDE.md buries the rules that matter.
-->

# <Project Name>

<One sentence: what this is, for whom.>

## Operating mode — binding

This project runs on **Founder OS Module 16 — Agentic Dev**.

@AGENTS.md

Read `.founder-os/blueprint.md` in full before working. Then read the contract for the role
you are acting in: `.founder-os/contracts/<role>.md`. Then pick the workflow that matches the
work: `.founder-os/workflows/`.

Short version of the non-negotiables:

- Never hand off work you have not verified yourself.
- `PRODUCT.md` → `ROADMAP.md` → `docs/specs/` → plan → commits. Nothing contradicts the level above.
- Loop: ORIENT → SPEC → PLAN → BUILD → VERIFY → SHIP → LEARN.
- Status block (BUILT / VERIFIED / OPEN / BLOCKED) on every handoff.
- Conventional Commits, small batches, trunk-based.
- Never delete or skip tests to go green.
- Never commit secrets.
- Dev and QA are separate contracts. You do not approve your own work.
- Unclear goal → ask, do not guess.

## Commands

| Purpose | Command |
|---|---|
| Dev server | `<npm run dev>` |
| Tests | `<npm test>` |
| Single test | `<npm test -- <path>>` |
| Lint | `<npm run lint>` |
| Typecheck | `<npm run typecheck>` |
| Build | `<npm run build>` |
| E2E | `<npm run test:e2e>` |
| DB migration | `<npm run db:migrate>` |

**Before any "done":** `<npm run lint && npm run typecheck && npm test && npm run build>`

## Architecture in five sentences

<Stack. Where things live. What the boundaries are. What the central data structure is.
What is deliberately NOT built the way you would expect.>

## Project-specific rules

<Only things an agent cannot work out by reading the code. Examples:>

- <Migrations are never hand-edited, always generated with `x`.>
- <`src/legacy/` is frozen — replacement in progress, see ADR-0007.>
- <All prices are integer cents, never floats.>
- <Deployment only through CI. Never `vercel --prod` locally.>

## Environments

| Environment | URL | Deploy |
|---|---|---|
| Preview | automatic per PR | automatic |
| Staging | `<https://staging.example.com>` | merge to `main` |
| Production | `<https://example.com>` | `<automatic after merge / on tag>` |

## Where things are

- `PRODUCT.md` — what this product is, current version, scope, non-goals
- `ROADMAP.md` — what gets built next (Now / Next / Later)
- `docs/specs/` — one spec per unit of work
- `docs/decisions/` — ADRs. Binding. Not re-litigated.
- `docs/learnings/` — what we learned the hard way
- `docs/checkins/` — running log
- `.founder-os/` — blueprint, harness, contracts, workflows. **Managed — never edit locally.**
