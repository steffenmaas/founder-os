---
name: dev-loop
description: Runs one unit of work through the Agentic Dev loop under the Dev Agent contract — orient, spec, plan, build, verify, hand to review, ship, learn. Use this skill when the user says "build this feature", "implement", "work on", "fix this bug", "start the loop" or any natural variant. Module 16 (Agentic Dev) — Product & Tech Delivery. Pre-Seed.
---

# Dev loop

This skill is part of the **Founder OS** plugin, Module 16 — Agentic Dev (Product & Tech Delivery).

**Contract:** `.founder-os/contracts/dev-agent.md` — read it before you start.
**Decision guidelines:** `.founder-os/harness.md`

## When to trigger

Run this skill when the user says any of:

- "build this feature"
- "implement X"
- "work on <roadmap item>"
- "fix this bug"
- "start the loop"
- `founder-os:dev-loop`

## Key instructions

**Task:** $ARGUMENTS

State: !`git status --short --branch 2>/dev/null | head -20`
Recent: !`git log --oneline -10 2>/dev/null`

---

### Step 0 — Pick the workflow

| The work is | Use |
|---|---|
| Something that does not exist yet | `.founder-os/workflows/new-feature.md` |
| Something that behaves incorrectly | `.founder-os/workflows/bug-fix.md` |
| Production is broken right now | `.founder-os/workflows/hotfix.md` — **stop, tell the human** |
| Structure changing, behaviour not | `.founder-os/workflows/refactor.md` |
| A dependency | `.founder-os/workflows/dependency-update.md` |

Say which one you picked. Follow its step table and its gates. The phases below are the
common shape; the workflow tells you which ones compress.

### Phase 1 — ORIENT

1. `PRODUCT.md` — what is this product, what is out of scope, which version?
2. `ROADMAP.md` — is the task in *Now*? If not, and the human did not explicitly prioritise
   it: **ask before proceeding.**
3. `docs/decisions/` — binding, not re-litigated.
4. `docs/learnings/` — skim entries in the area you are about to change.
5. **Is CI on `main` green?** If red, that is your task. Nothing else.
6. Delegate codebase exploration to an `Explore` subagent with a narrow question. Do not read
   dozens of files yourself — that fills your context before the work begins.

**Gate:** goal unclear → stop and ask. Do not guess.

### Phase 2 — SPEC

If the diff is describable in one sentence: **skip spec and plan**, go to BUILD.

Otherwise run `/dev-spec`. The spec must have a non-empty **non-goal** section and an
**executable verification step**. Without both it is not finished.

**Gate:** human approved the spec.

### Phase 3 — PLAN

Step list in the spec under `## Plan`. Per step: what changes (concrete paths), which command
proves it works, independently committable. Name explicitly what will **not** be touched.

**Gate:** human approved the plan.

### Phase 4 — BUILD

**Delegate each plan step to a `builder` subagent** — one dispatch per step, spawned as a
**named background task** so the human can see what is running (`build:<slug> · step 2/4`).
Give it three things or it stops: the plan step, the files in scope, the check that proves
it. It returns a short report (BUILT / VERIFIED / SCOPE / BLOCKED), never its transcript.
One builder at a time; three failed attempts → it reports `SPLIT` and you re-plan.

Working directly instead of dispatching is fine only for a one-sentence change — the
dispatch overhead would exceed the work.

Each dispatch follows the same rules:

- Short-lived branch, `<type>/<slug>`.
- Where behaviour is clear: failing test first, then the code.
- One commit per plan step, Conventional Commits, `Refs: docs/specs/<slug>.md` in the body.
  **Named files, never `git add -A`.**
- Unfinished work behind a feature flag, not in a long-lived branch.
- Run the step's check after each step. Red → fix before continuing.

**Forbidden** (contract, §Hard boundaries): deleting or skipping tests, suppressing errors
(`catch {}`, `# type: ignore`, `any`), widening scope beyond the spec.

### Phase 5 — VERIFY

1. Full chain: lint, typecheck, test, build — **delegate to the `verifier` subagent**, which
   runs the checks and reports what actually happened. **Put the output in your answer.**
2. Change-specific:
   - UI → screenshot, compare to the reference, name the differences
   - API → real request against a running instance, show the response
   - Data model → migration forward **and** backward against a copy
   - Performance → before/after measurement
3. **Hand to QA:** run `/dev-review` (the `reviewer` subagent). It works under a separate
   contract, is read-only by construction, and sees only the diff and the acceptance
   criteria — not your reasoning. **You do not review your own work.** For diffs touching
   auth, data access, CI, or dependencies, also dispatch `security-auditor`.
4. Fix only findings affecting correctness or the stated requirements.

**Gate:** verdict PASS or PASS WITH NOTES. BLOCKED goes back to Phase 4.

### Phase 6 — SHIP

Open the PR with the rollback section filled in. Wait for CI and the preview URL. Then hand
to the human — **`/dev-ship` is human-invoked only.** You do not deploy.

### Phase 7 — LEARN

1. `ROADMAP.md` — done out, newly discovered work to *Later*.
2. Constraining decision made? → ADR in `docs/decisions/`.
3. Anything surprising, slow, or requiring a non-obvious workaround? → `/dev-learn`.
4. Broke a rule because it did not fit? → learning with `scope: upstream`. The blueprint gets
   changed, not ignored.
5. Explained the same thing twice? → `CLAUDE.md` or a skill.

---

## Close with the status block

Four lines, no prose before them:

```
BUILT:     <what, with commit hashes>
VERIFIED:  <which command, which result>
OPEN:      <what is still missing for definition of done>
BLOCKED:   <what is holding you up, or "nothing">
```
