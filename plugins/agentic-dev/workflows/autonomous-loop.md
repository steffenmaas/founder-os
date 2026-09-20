# Workflow — Autonomous Loop

**Use when:** continuous development from a live backlog, with no human dispatching
individual tasks. This is the standing meta-workflow: it pulls work, bundles it, and runs
the other workflows inside its increments.

**Entry:** a **recurring scheduled trigger** that starts a **fresh session per tick** —
a cron entry, a scheduled workflow, a routine. Create it once, at adoption. It does not ask
for work, and it does not depend on the previous tick still being alive.

---

## The tick is stateless — the repository is the state

This is the load-bearing rule of the whole loop, and every other rule here follows from it.

**A tick starts with no memory and must be able to.** It orients from the repository alone:
the top package of `ROADMAP.md`, the spec's status, the pushed branch, the open PR, the last
check-in. It does one useful step, leaves its state **in the repository**, and ends. The next
tick picks it up without knowing the previous one existed.

**Orienting is cheap by design.** A tick reads **blueprint §0 (the short form)** plus its
contract plus this workflow — not the blueprint end to end. The remaining sections are
reference, opened by number when the work touches them; the numbers are stable for exactly
that reason. Re-reading the whole rulebook every tick is the loop's largest avoidable token
cost, and the orchestrator is already its most expensive process (blueprint §7).

Why this shape and not a long-lived session that keeps itself alive: every measured way this
loop has died is a variant of *the session was the state*.

| Measured failure | What was lost | What a stateless tick does |
|---|---|---|
| Self-re-arm chain missed one link | 4 h, silently — every timer had "succeeded" | The scheduler fires regardless; no link to miss |
| Background sub-agents reclaimed with the idle container | 6 of 7 agents, one increment started 4×, **571 min without a merge** | Work is committed and pushed inside the tick that did it |
| Container restarted under load (4 builders, load 15 on 4 cores) | All four builders | Fewer agents per tick; each commits its own step |
| Shared tree collisions (`pkill`, a collided `--autostash`) — 3 incidents in one session | Every agent stopped at once | One writer per tree per tick (below) |
| A broken module update left the session unable to work | Hours, until a human looked | The next tick starts clean and re-runs HEALTH |

So: **nothing may need to survive between ticks.** A tick that cannot finish its increment
pushes what it has, writes one line of where it stands, and ends — that is a complete tick,
not a failed one.

Two consequences worth stating plainly, because they overturn older advice:

- **Self-re-arming is not the spine, and never was.** A loop that continues only because the
  agent remembered to schedule the next tick has a single point of failure with no alarm on
  it. Self-re-arming may still run *on top* for a finer cadence than the scheduler supports
  (many schedulers have a one-hour floor). When it works, the recurring tick finds the work
  already done and exits quietly. When it fails, the recurring tick is what resumes the loop.
- **"Stay on your turn" is a rule *inside* a tick, not across ticks.** While a dispatch runs,
  the session stays present (see *Dispatching*). What it no longer has to do is stay alive
  between ticks to keep the loop going.

---

## The cycle

**Every tick** runs steps 1–6. **Steps 7–9 are periodic** — running them every tick is
ballast, and ballast is where ticks get stuck.

| # | When | What | Gate before the next step |
|---|---|---|---|
| 1 | every tick | **HEALTH (short)** — is `main` green, did the last deploy land (deployed version marker matches the last shipped commit), is the runtime reachable (**either the plugin is loaded, or `.claude/agents/builder.md` exists** — with no runtime the loop writes its own code and reviews its own diff, so *no runtime is a FAILURE, not a pass*). Module version vs. `.founder-os/VERSION`: on mismatch, refreshing the managed copy (`install.sh --update`, one commit) is this tick's increment. | Healthy. **A red `main` or a deploy that did not land is the task, nothing else.** |
| 2 | every tick | **GROOM + PULL** — name the source-of-truth store out loud (never groom a projection; check `docs/decisions/` when in doubt), sweep intake (merge duplicates, drop what no longer serves `PRODUCT.md`, fold items into roadmap packages), then pull **the top package of `ROADMAP.md`** — the one ordered list is the master, and re-ordering it by the backlog doctrine is grooming, not a violation. **Intake empty is not work done:** when yesterday's feedback is worked off, the next roadmap package is the work. | Package traces to `PRODUCT.md`. State the yardstick in one line: *closest gap to the current version scope*. |
| 3 | every tick | **BUNDLE** — the roadmap package IS the bundle (`ROADMAP.md`: a package is a release, not a ticket). Confirm its spec exists — a missing spec is the package's first increment. One package = one branch, id in branch and PR title (`B004 · …`). | Spec present (or being written); each increment describable in one sentence. |
| 4 | every tick | **BUILD** — one increment = one commit, **named files, never `git add -A`**, max 3 attempts. **The branch is pushed as soon as the first commit exists.** Who writes depends on the stage — see *Who builds* below. | Increment's own check green, and **pushed**. |
| 5 | every tick | **VERIFY (scoped)** — `verifier` runs analyze plus the tests of the touched scope; `reviewer` judges the diff at increment scope, in fresh context. **The full suite does not run here.** | QA PASS at increment scope. |
| 6 | every tick | **PACKAGE QA + SHIP** — when the package is complete: the **full suite plus guard tests, locally, once** (this is the merge gate; GitHub runs no per-PR CI in the default posture, blueprint §7). Then the deploy gate (`deploy-gate.md`) decides auto-ship or human gate. | Full suite green — **no merge before this**. One package = one merge. Gate outcome recorded in the PR. |
| 7 | per merge | **DASHBOARD** — refresh the dashboard artifact (`/dev-dashboard`, same URL) and drop the finished package from the working context. | The past lives in the dashboard and the release notes, not in the context window. |
| 8 | per day | **CHECK-IN + LEARN** — queued decisions bundled into one block during the founder's day, learnings written. | Founder sees one block, not a stream. |
| 9 | per milestone | **UX AUDIT** — simulated-user audit (`ux-audit.md`) after a bundle group or milestone. | Findings filed to the backlog (`source: ux-audit`). |

**A tick that dispatched nothing must name its blocker in one line** — empty backlog, gate
awaiting approval, red `main` being fixed, runtime missing. "Nothing to report" without a
named blocker is not an idle loop, it is a broken one. And the trigger's prompt carries the
**mandate, never the report**: *pull, build, verify, ship* — a session asked for a status
delivers exactly that and stops. Observed in production: a scheduled "check-in" prompt
produced tidy status reports all day while zero agents ran and zero items moved.

---

## Who builds — it depends on the stage

The separation that matters is **the verdict, not the keystrokes**: the agent that writes
code never issues the verdict on its own work (blueprint §12.9). That holds in every stage.
*Who types* is a different question, and dispatching has its own measured cost.

| `stage` | Who writes the code | Why |
|---|---|---|
| **`pre-live`** | **The tick session itself may build.** A `builder` dispatch is allowed, never required. | Nothing is live. The dispatch is the most fragile mechanism in the loop — shared trees, reclaimed containers, resource exhaustion — and in `pre-live` its only benefit is context hygiene, against a measured cost in lost work. |
| **`live`** / **`scaled`** | **`builder` dispatch required.** Only `builder` writes product code. | With real users, structural separation beats convenience: the writing agent must be unable to reach the verdict. |

**In every stage:** verification is scoped and fresh-context (`verifier`, `reviewer` — both
read-only by tool restriction), and **no one approves their own work.** A `pre-live` tick
that builds its own increment still hands the diff to a reviewer that sees only the diff and
the acceptance criteria.

---

## Dispatching — when a tick does delegate

**One agent per type at a time, and never two writers on the same surface.** Two agents
writing the same files produce merge conflicts, not speed. The boundary is the *write
surface*, not writing itself: an asset agent (images, video, 3D), a docs writer or a design
agent may run alongside a builder as long as their outputs do not overlap; read-only agents
parallelise freely.

**Measured, and worth knowing before you parallelise:** seven sub-agents on one container and
one working tree produced **zero merge conflicts on product files** — and **three incidents
that stopped every agent at once**, all from the shared environment rather than the code. The
risk of parallelism on this stack is the *environment*, not the code. So:

- **Check resources, then dispatch.** Resource guard GO before every dispatch; at most three
  builders at once, at most one rendering (blueprint §3.4).
- **Prefer a worktree per agent** over sharing one tree. No shared index, no hook noise.
- **File ownership is in the dispatch.** Every brief names the files the agent owns and the
  trees it must not touch. Without that sentence the brief is incomplete.
- **Same builder across a package.** Continue the same conversation from increment to
  increment: a fresh builder re-orients on the codebase every time, and that orientation is
  the single largest avoidable token cost in the loop.
- **Dispatch prompts are pointers, not essays** — the spec path, the increment, the
  acceptance check, the owned files. The standing orientation lives in `CLAUDE.md` and the
  spec; explaining the why costs tokens on every dispatch and adds nothing the contract does
  not already bind.
- **Spawn, then stay — within the tick.** A running background sub-agent does not count as
  activity on ephemeral infrastructure; only the main session's own work does. While a
  dispatch runs, do bounded foreground work — grooming, spec-writing, reading results — and
  hand back only when nothing is running.
- **Watchdog, always.** Every dispatch is covered by a stall watchdog: no heartbeat for its
  stall window → killed and salvaged, commit the green part, report `SPLIT`, re-plan. **Kill
  by PID, never by pattern** — `pkill` took out another agent's test run twice in one session.
- **No orphans.** Every background task is finished, killed by its watchdog, or reported at
  the end of the tick.

### Who does what — the delegation map

| Step | Subagent | Contract | Writes? |
|---|---|---|---|
| The tick itself — groom, bundle, dispatch, gate, report | `orchestrator` | orchestrator-agent | backlog, specs, check-ins, dashboard |
| PLAN | `planner` | product-agent | no |
| BUILD (one increment) | **`builder`** | dev-agent | **yes — code and tests** |
| VERIFY (scoped) | `verifier` | qa-agent | no |
| REVIEW | `reviewer` | qa-agent | no |
| SECURITY (when the diff touches auth, data, CI, deps) | `security-auditor` | security-agent | no |
| Exploration ("where does X happen?") | any read-only explorer | — | no |

**The reviewing agents physically cannot change the code they judge** — that is what makes
the separation structural rather than a promise, and it is why `pre-live` can relax *who
types* without relaxing anything that matters.

---

## Loop rules

**Thin orchestrator — under contract.** The orchestrator runs under
`../knowledge/contracts/orchestrator-agent.md`: it acts as the **standing product owner**
between the founder's decisions, never goes deeper than the bundle, and decides everything
the standing defaults already answer instead of asking. It reads no large files and pastes
no raw logs; every context-heavy step goes to a scoped subagent that returns a bounded
report (≤ 15 lines). In `live` and `scaled` it also writes no product code and no tests —
**the orchestrator that starts editing files has stopped orchestrating.**

**Decisions are collected, not blocking** (harness §5). A below-threshold decision goes to
the queue with a recommendation and its cost; the tick takes the reversible default or the
next item, and the check-in presents the queue bundled during the founder's day.

**A gate stops the increment, not the loop.** When a change hits the deploy gate, finish it,
commit it to **its own branch** (`<dev-branch>-gate-<slug>`), open its PR, leave it for the
human — then reset the development branch to `origin/main` and take the next item. Two
failure modes this avoids: idling for hours until a human wakes up, and — worse — stacking
later work onto the gated PR, where one approval silently covers changes the human never saw.

**A red `main` is the one hard stop.** If shipping is broken, fixing it *is* the work.

**Human contact is an event, not a rhythm.** Message the human when a milestone is done, a
real blocker exists, or a gate needs approval. Everything else goes in the check-in.

**The loop must be watchable while it runs.** Delegated units run as background tasks so
they appear in the client's task list, and the label is the status display: **agent type
first, then the package** — `build:F003-onboarding · increment 2/4`, `verify:F003-onboarding`,
`asset:F003-hero-video`, `watchdog:build-F003`. Type first means one glance shows which stage
every package is in. Two views, both required: background tasks show work is happening right
now; the **dashboard** shows what it amounts to and what waits on the human. A loop with
neither is invisible, and an invisible loop gets switched off.

---

## The test budget

The verification depth is deliberately two-tier, and the suite is kept small enough that the
deep tier stays fast:

- **Per increment:** only the touched scope. Tests land in the same commit, in scope.
- **Per package:** the full suite plus guard tests, once.
- **The full suite has a runtime budget** (`testing.full_suite_budget_minutes`, default 10).
  Exceeded → reducing runtime becomes a backlog `improvement` like any other. A suite nobody
  can afford to run guards nothing.
- **Prefer one guard test over ten behaviour restatements.** A guard test enforces a rule (a
  banned API, a build-flag invariant, doc/code consistency) and pays rent forever.
- **The full suite is journeys plus guards, nothing else.** Does onboarding run through, does
  the purchase run through, does the core action work — against the **test environment, never
  production**. Pixel-level assertions belong to manual tests and design review. A feature
  normally extends an existing journey rather than adding a test file; when the suite grows
  faster than the functionality, pruning it is the next `T` package.
