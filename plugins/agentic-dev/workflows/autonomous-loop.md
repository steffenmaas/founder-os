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
| 1 | Orchestrator | **HEALTH** — CI and deploy state on `main`: last pipeline run green, **deployed version marker matches the last shipped commit**, logs clean since the last cycle (`deploy-gate.md`, "after the deploy"). Analyze clean, dispatch watchdogs armed, **and the loop's own recurring trigger present and last fired within one interval**. **Module current:** loaded plugin version vs. `.founder-os/VERSION` — on mismatch, refreshing the managed copy (`install.sh --update`, one commit) is the first increment of the cycle. **No runtime is a health FAILURE, not a pass:** with one operand missing the comparison succeeds by having nothing to compare, and a loop with no `builder` to dispatch to writes its own code and reviews its own diff. Check the runtime is reachable **before** comparing versions — either the plugin is loaded, or `.claude/agents/builder.md` exists in the project (the mirrored runtime, `install.sh` §1b). In a cloud or CI session only the second can be true. | Healthy. A red `main` or a deploy that did not land is the task, nothing else. |
| 2 | Product | **GROOM + PULL** — name the source-of-truth store out loud (never groom a projection; check `docs/decisions/` when in doubt), sweep intake (merge duplicates, drop what no longer serves `PRODUCT.md`, fold items into roadmap packages), then pull **the top package of `ROADMAP.md`** — the one ordered list is the master. **Intake empty is not work done:** when yesterday's feedback is worked off, the next roadmap package is the work; the observed failure is a loop that clears feedback overnight and then stops. | Package traces to `PRODUCT.md`. State the yardstick in one line: *closest gap to the current version scope*. |
| 3 | Product | **BUNDLE** — the roadmap package IS the bundle (`ROADMAP.md`: a package is a release, not a ticket). Confirm its spec exists — a missing spec is the package's first increment. One package = one branch, id in the branch and PR title (`B004 · …`). | Spec present (or being written), each increment describable in one sentence, the package fits in days, not weeks. |
| 4 | Dev | **BUILD** — one `builder` dispatch per increment, **spawned as a named background task** (see below): one increment = one commit, **named files, never `git add -A`**, max 3 attempts, heartbeat while running. **The branch is pushed as soon as the first commit exists** — work that lives only in a local worktree is lost when the environment is reclaimed, and ephemeral containers are the normal case. | Increment's own check green. |
| 5 | Dev + QA | **VERIFY (scoped)** — `verifier` runs analyze plus the tests of the touched scope; `reviewer` judges the diff at increment scope. **The full suite does not run here.** | QA PASS at increment scope. |
| 6 | QA | **PACKAGE QA** — when the package is complete: `verifier` runs the **full test suite plus guard tests, locally, once**; `reviewer` looks specifically for cross-increment interactions. This is the merge gate — GitHub runs no per-PR CI in the default posture (blueprint §7). | Full suite green. Red → fix enters the loop as the top item. **No merge before this is green.** |
| 7 | Release | **GATE + SHIP** — run the checklist (`deploy-gate.md`): auto-ship (merge — the single test-then-deploy workflow takes it from `main`), or preview + notify + wait for approval. The loop continues with the next package either way. | Gate outcome recorded in the PR. One package = one merge. |
| 8 | QA | **UX AUDIT** — after a bundle group or milestone: simulated-user audit (`ux-audit.md`). | Findings filed to the backlog (`source: ux-audit`). |
| 9 | Dev | **LEARN + RE-ARM** — queued decisions into the check-in, learnings written, **dashboard artifact refreshed** (`/dev-dashboard`, same URL), **then the context compacted: finished packages leave the working context** — old topics carried forward are pure token cost, and the dashboard is where the past lives now — and the next cycle armed. **Re-anchor:** restate the mandate for the next cycle in one line — *stay brief, groom the backlog, work in bundles, keep the version scope in sight* — so the loop corrects itself instead of waiting to be corrected. | **The loop never ends a cycle without re-arming the next one** — including blocked and no-op paths. Re-arming is *checked*, not assumed, and it never replaces the recurring trigger. |

---

## Loop rules

**A tick is a work unit, not a status call.** The most deceptive way this loop fails is
also the quietest: the trigger keeps firing, every tick writes a tidy check-in, and no
work happens — for hours, with every signal green. Observed in production: a scheduled
"check-in" prompt produced status reports all day while zero agents were spawned and zero
items moved. Three rules close it:

1. **The trigger's prompt carries the mandate, never the report.** It says *pull, bundle,
   dispatch* — not "check in" or "status". A session asked for a status will deliver
   exactly that and stop.
2. **A cycle that dispatched nothing must name its blocker in one line** — empty backlog,
   gate awaiting approval, red `main` being fixed, runtime missing. "Nothing to report"
   without a named blocker is not an idle loop, it is a broken one.
3. **The check-in is written at the end of a work cycle, never instead of one.** Report
   time is after dispatch time, in the same tick.

**One agent per type at a time — and the SAME builder across a package.** One `builder`
at a time per codebase: two agents writing the same surface produce merge conflicts, not
speed. But the boundary is the **write surface, not writing itself** — an asset agent
producing images, video or 3D objects, a docs writer, or a design agent may run in
parallel to the builder as long as their outputs do not overlap; read-only agents
(`reviewer`, `verifier`, explorers) parallelise freely. The rule stated precisely: **never
two agents of the same type at once, never two writers on the same surface.** Within a
package, continue the same builder conversation from
increment to increment wherever the platform supports it: a fresh builder re-orients on the
codebase every time, and that orientation is the single largest avoidable token cost in the
loop. **Dispatch prompts are pointers, not essays** — the spec path, the increment, the
acceptance check. The builder's standing orientation lives in `CLAUDE.md` and the spec, not
in the prompt; explaining the why costs tokens on every dispatch and adds nothing the
contract does not already bind.

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
read-only agents parallelise freely, and writers of **non-code artifacts** (images, video,
3D, docs) may run alongside the builder — one agent per type, never two writers on the
same surface.

### Visibility — the loop must be watchable while it runs

**Everything delegated runs as a background task.** A founder looking at the session has to
see *that* work is happening, not infer it from commits appearing later. So:

- **Spawn, then stay.** Every delegated unit — subagent dispatch, verification run,
  script, watchdog — is started as a **background task** so it appears in the client's task
  list while it runs. But spawning is only half the rule, and the half this document used
  to state alone was measured killing the work it dispatched: **on ephemeral infrastructure
  a running background sub-agent does not count as activity — only the main agent's own
  work does.** An orchestrator that spawns and ends its turn hands the platform an idle
  session, and the container is reclaimed with the sub-agent inside it. Measured in
  production: six of seven sub-agents lost overnight, one increment started four times,
  **571 minutes without a merge** across nine cycles that all ran and all produced nothing.
- **So the orchestrator does not end its turn while a sub-agent is running.** Its own
  activity is the only lever against the inactivity reclaim. While a dispatch runs, the
  orchestrator does bounded useful foreground work — grooming, spec-writing, reading
  results — and checks on its dispatches; it hands back only when nothing is running.
- **The task label is the status display.** The notation is fixed: **agent type first,
  then the package being worked** — `build:F003-onboarding · increment 2/4`,
  `verify:F003-onboarding`, `asset:F003-hero-video`, `watchdog:build-F003` — never `task` or
  `agent`. Type first means one glance at the running labels shows which stage every
  package is in; that list *is* what the human reads to know where the loop stands.
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
- **The full suite is journeys plus guards, nothing else.** Does onboarding run through,
  does the purchase run through, does the core action work — against the **test
  environment, never production**. Pixel-level and visual-detail assertions do not enter
  the suite; they belong to manual tests and design review. A feature normally extends an
  existing journey rather than adding a test file — when the suite grows faster than the
  functionality, pruning it is the next `T` package.
