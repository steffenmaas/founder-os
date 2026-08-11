# Workflow — Autonomous Loop

**Use when:** continuous development from a live backlog, with no human dispatching
individual tasks. This is the standing meta-workflow: it pulls work, bundles it, and runs
the other workflows inside its increments.
**Entry:** a standing orchestrator session on a ~15-minute rhythm, driven by a **recurring
scheduled trigger** (a cron the agent cannot forget). It does not ask for work.

> The recurring trigger is the loop's spine, not an optimisation. Self-re-arming — the agent
> scheduling its own next tick at the end of a cycle — is a fast path *on top of* it, never
> the only mechanism. See **"The loop needs a watchdog too"** below for why.

> Distilled from two production systems that ran this loop for months. The speed comes from
> three things: **bundling** related small items, **scoping** verification per increment,
> and paying the full verification depth **once per bundle** instead of once per change.

---

| # | Who | What | Gate before the next step |
|---|---|---|---|
| 1 | Orchestrator | **HEALTH** — CI and deploy state on `main`: last pipeline run green, **deployed version marker matches the last shipped commit**, logs clean since the last cycle (`deploy-gate.md`, "after the deploy"). Analyze clean, dispatch watchdogs armed, **and the loop's own recurring trigger present and last fired within one interval**. **Module current:** loaded plugin version vs. `.founder-os/VERSION` — on mismatch, refreshing the managed copy (`install.sh --update`, one commit) is the first increment of the cycle. **No plugin loaded is a health FAILURE, not a pass:** with one operand missing the comparison succeeds by having nothing to compare, and a loop with no `builder` to dispatch to writes its own code and reviews its own diff. Check the plugin is there before comparing versions. | Healthy. A red `main` or a deploy that did not land is the task, nothing else. |
| 2 | Product | **GROOM + PULL** — sweep the backlog first (merge duplicates, drop what no longer serves `PRODUCT.md`, cut items to user-observable size), then pull the top items per the backlog doctrine (`backlog.md`): **reachable before refined** → security → bugs → improvements → features, weighted by source. | Item traces to `PRODUCT.md`. State the yardstick in one line: *closest gap to the current version scope*. |
| 3 | Product | **BUNDLE** — group 2–5 related items (same feature area, shared verification path) into one bundle. One bundle = one branch. | Each item describable in one sentence. The bundle fits in one day. |
| 4 | Dev | **BUILD** — one `builder` dispatch per increment, **spawned as a named background task** (see below): one increment = one commit, **named files, never `git add -A`**, max 3 attempts, heartbeat while running. | Increment's own check green. |
| 5 | Dev + QA | **VERIFY (scoped)** — `verifier` runs analyze plus the tests of the touched scope; `reviewer` judges the diff at increment scope. **The full suite does not run here.** | QA PASS at increment scope. |
| 6 | Release | **DEPLOY GATE** — run the checklist (`deploy-gate.md`): auto-ship, or preview channel + notify + wait for approval. The loop continues with the next item either way. | Gate outcome recorded in the PR/commit. |
| 7 | QA | **BUNDLE QA** — when the bundle is complete: `verifier` runs the full test suite plus guard tests, once; `reviewer` looks specifically for cross-increment interactions. | Full suite green. Red → fix enters the loop as the top item. |
| 8 | QA | **UX AUDIT** — after a bundle group or milestone: simulated-user audit (`ux-audit.md`). | Findings filed to the backlog (`source: ux-audit`). |
| 9 | Dev | **LEARN + RE-ARM** — queued decisions into the check-in, learnings written, **dashboard artifact refreshed** (`/dev-dashboard`, same URL), next cycle armed. **Re-anchor:** restate the mandate for the next cycle in one line — *stay brief, groom the backlog, work in bundles, keep the version scope in sight* — so the loop corrects itself instead of waiting to be corrected. | **The loop never ends a cycle without re-arming the next one** — including blocked and no-op paths. Re-arming is *checked*, not assumed, and it never replaces the recurring trigger. |

---

## Loop rules

**Strictly sequential builders.** One `builder` at a time per codebase. Parallel is for
read-only work only. Two agents writing produce merge conflicts, not speed.

**Thin orchestrator — under contract.** The orchestrator runs under
`../knowledge/contracts/orchestrator-agent.md`: it acts as the **standing product owner**
between the founder's decisions, writes no product code and no tests, never goes deeper than
the bundle, and decides everything the standing defaults already answer instead of asking.
It reads no large files and pastes no raw logs; every context-heavy step goes to a scoped
subagent that returns a bounded report (≤ 15 lines). **The orchestrator that starts editing
files has stopped orchestrating** — that is the single most common way this loop degrades.

**Watchdog, always.** Every dispatch is covered by a stall watchdog. A dispatch with no
heartbeat for its stall window is killed and salvaged — commit the green part, report
`SPLIT`, re-plan. Kill by PID, never by pattern.

**The loop needs a watchdog too.** The rule above covers every *dispatch*. Nothing covers the
*loop itself* — and a loop that only continues because the agent remembered to schedule the
next tick has a single point of failure with no alarm on it. One missed re-arm and the loop
is dead, silently, until a human notices the absence of commits.

This is not hypothetical. In a production project running this module, the loop was a chain
of one-shot timers, each scheduled by the previous cycle: `09:30 → 10:05 → 10:47 → 13:18 →
14:28 → nothing`. At 14:28 the agent stated it would re-arm and did not. **Four hours of
development were lost**, and nothing reported a fault — every timer in the chain had
completed successfully, so every health signal was green. In the same environment, a
*recurring* trigger on a sibling loop kept firing for days without attention.

So:

- The loop is driven by a **recurring scheduled trigger** — a cron entry, a queue, anything
  that fires without the agent's participation. Create it once, at adoption.
- Self-re-arming may run *on top* for a finer cadence than the scheduler supports (many
  schedulers have a one-hour floor; the loop wants ~15 minutes). When it works, the recurring
  tick finds work already done and exits quietly. When it fails, the recurring tick is what
  resumes the loop instead of nothing.
- Step 1 checks that the recurring trigger exists and fired within one interval. **A loop
  whose own heartbeat has stopped cannot detect that by running** — which is exactly why the
  check belongs to the tick that the agent does not control.
- Recording "next cycle armed" is not the same as arming it. Verify the trigger exists;
  do not trust the intent.

### Who does what — the delegation map

The orchestrator delegates every step; it implements nothing itself. Each dispatch is one
subagent, under one contract, as one background task:

| Step | Subagent | Contract | Writes? |
|---|---|---|---|
| The loop itself — groom, bundle, dispatch, gate, report | `orchestrator` | orchestrator-agent | backlog, specs, check-ins, dashboard — **never product code** |
| PLAN | `planner` | product-agent | no |
| BUILD (one increment) | **`builder`** | dev-agent | **yes — code and tests** |
| VERIFY (scoped) | `verifier` | qa-agent | no |
| REVIEW | `reviewer` | qa-agent | no |
| SECURITY (when the diff touches auth, data, CI, deps) | `security-auditor` | security-agent | no |
| Exploration ("where does X happen?") | any read-only explorer | — | no |

**Only `builder` may write product code.** That is what makes the dev/QA separation structural rather
than a promise: the reviewing agents physically cannot change the code they judge, and the
writing agent never issues a verdict on its own work. One `builder` at a time per codebase;
the read-only ones may run in parallel.

### Visibility — the loop must be watchable while it runs

**Everything delegated runs as a background task.** A founder looking at the session has to
see *that* work is happening, not infer it from commits appearing later. So:

- **Spawn, never block.** Every delegated unit — subagent dispatch, verification run,
  script, watchdog — is started as a **background task** so it appears in the client's task
  list while it runs. The orchestrator never blocks its turn waiting for one, and never
  sleeps in the foreground: a session that looks frozen is indistinguishable from a session
  that died.
- **The task label is the status display.** Name every task for what it does and what it
  touches — `build:water-tracking · increment 2/4`, `verify:nutrition-scope`,
  `watchdog:build-2` — never `task` or `agent`. The list of running labels *is* what the
  human reads to know where the loop stands.
- **The orchestrator's turn stays short:** spawn, record, hand back. Results arrive as
  completion notifications; the next step starts from those.
- **No orphans.** Every background task is either finished, killed by its watchdog, or
  reported at the end of the cycle. Nothing keeps running unnamed and unwatched.

Two views, both required: **background tasks show that work is happening right now**; the
**dashboard artifact** (`/dev-dashboard`, step 9) shows what it amounts to and what waits
on the human. A loop with neither is invisible, and an invisible loop gets switched off.

**Decisions are collected, not blocking** (harness §5). A below-threshold decision goes to
the queue with a recommendation; the loop takes the reversible default or the next item.
The check-in presents the queue bundled.

**A gate stops the increment, not the loop.** When a change hits the deploy gate, finish it,
commit it to **its own branch** (`<dev-branch>-gate-<slug>`), open its PR, leave it for the
human — then reset the development branch to `origin/main` and take the next item in the same
cycle. Two failure modes this avoids: idling for hours until a human wakes up, and — worse —
stacking later work onto the gated PR, where a single approval silently covers changes the
human never looked at. That destroys the gate it was meant to respect.

**A red `main` is the one hard stop.** If shipping is broken, fixing it *is* the work;
anything else just piles up increments that cannot ship.

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
