# Workflow — Autonomous Loop

**Use when:** continuous development from a live backlog, with no human dispatching
individual tasks. This is the standing meta-workflow: it pulls work, bundles it, and runs
the other workflows inside its increments.
**Entry:** a standing orchestrator session on a ~15-minute rhythm. It re-arms itself; it
does not ask for work.

> Distilled from two production systems that ran this loop for months. The speed comes from
> three things: **bundling** related small items, **scoping** verification per increment,
> and paying the full verification depth **once per bundle** instead of once per change.

---

| # | Who | What | Gate before the next step |
|---|---|---|---|
| 1 | Orchestrator | **HEALTH** — CI and deploy state on `main`, analyze clean, watchdog armed. | Healthy. A red `main` is the task, nothing else. |
| 2 | Product | **PULL** — top items per the backlog doctrine (`backlog.md`): security → bugs → improvements → features, weighted by source. | Item traces to `PRODUCT.md`. Contradiction → flag, pull the next. |
| 3 | Product | **BUNDLE** — group 2–5 small related items (same feature area, shared verification path) into one bundle. One bundle = one branch. | Each item describable in one sentence. The bundle fits in one day. |
| 4 | Dev | **BUILD** — one dispatch per increment: one increment = one commit, **named files, never `git add -A`**, max 3 attempts, heartbeat while running. | Increment's own check green. |
| 5 | Dev + QA | **VERIFY (scoped)** — analyze plus the tests of the touched scope only. QA reviews the diff at increment scope. **The full suite does not run here.** | QA PASS at increment scope. |
| 6 | Release | **DEPLOY GATE** — run the checklist (`deploy-gate.md`): auto-ship, or preview channel + notify + wait for approval. The loop continues with the next item either way. | Gate outcome recorded in the PR/commit. |
| 7 | QA | **BUNDLE QA** — when the bundle is complete: full test suite plus guard tests, once, looking specifically for cross-increment interactions. | Full suite green. Red → fix enters the loop as the top item. |
| 8 | QA | **UX AUDIT** — after a bundle group or milestone: simulated-user audit (`ux-audit.md`). | Findings filed to the backlog (`source: ux-audit`). |
| 9 | Dev | **LEARN + RE-ARM** — queued decisions into the check-in, learnings written, next cycle armed. | **The loop never ends a cycle without re-arming the next one** — including blocked and no-op paths. |

---

## Loop rules

**Strictly sequential dev agents.** One dev agent at a time per codebase. Parallel is for
read-only exploration only. Two agents writing produce merge conflicts, not speed.

**Thin orchestrator.** The orchestrator writes no code, reads no large files, and pastes no
raw logs. Every context-heavy step goes to a scoped subagent that returns a bounded report
(≤ 15 lines). The orchestrator that starts reading files stops orchestrating.

**Watchdog, always.** Every dispatch is covered by a stall watchdog. A dispatch with no
heartbeat for its stall window is killed and salvaged — commit the green part, report
`SPLIT`, re-plan. Kill by PID, never by pattern.

**Decisions are collected, not blocking** (harness §5). A below-threshold decision goes to
the queue with a recommendation; the loop takes the reversible default or the next item.
The check-in presents the queue bundled. The loop stops for a red `main` and for the deploy
gate — for nothing else.

**Human contact is an event, not a rhythm.** Message the human when a milestone is done, a
real blocker exists, or a gate needs approval. Everything else goes in the check-in.

## The test budget

The verification depth of this loop is deliberately two-tier, and the suite is kept small
enough that the deep tier stays fast:

- **Per increment:** only the touched scope. Tests are added in the same commit, in scope.
- **Per bundle:** the full suite plus guard tests, once.
- **The full suite has a runtime budget** (`testing.full_suite_budget_minutes`, default 10).
  When it is exceeded, reducing runtime becomes a backlog `improvement` like any other —
  merge redundant cases, replace E2E with contract tests, delete tests that assert nothing.
  A suite nobody can afford to run guards nothing.
- **Prefer one guard test over ten behaviour restatements.** A guard test enforces a rule
  (a banned API, a build-flag invariant, doc/code consistency, a pacing property) and pays
  rent forever. Breadth for its own sake is how a suite reaches thousands of cases that take
  longer to run than the change took to write.
