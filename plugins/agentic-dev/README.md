# Founder OS · Module 16 — Agentic Dev

**Product & Tech Delivery · Pre-Seed**

The development loop for startups where AI agents write the product code.
11 skills, 5 agent contracts, 5 subagents, 9 workflows, 2 enforcement hooks, CI/CD templates
and metrics tooling.

---

## Where this sits in the stack

| Module | Owns |
|---|---|
| **16 · Agentic Dev** (this) | **Building product code** — loop, specs, review, deploy, security, metrics |
| 15 · Design Mockup | Produces the design this module implements |
| 17 · PMF Tracker | Measures whether what was built holds |
| 18 · Scaling Architect | Takes over when architecture becomes the bottleneck |
| 28 · AI Operations / 30 · Autonomous Ops | **Running the company** — internal agent infrastructure, autonomous business processes |

Rule of thumb: anything that lands in `git` and a user touches → Module 16. Anything that
keeps the company running internally → 28/30.

---

## The one rule

> **Never hand off work you have not verified yourself.**

In agentic development the bottleneck is not writing, it is verification. An agent produces
more code in ten minutes than a human can review in ten minutes — and wrong code looks
exactly as convincing as right code. Everything below follows from that.

---

# Installation

**There is exactly one way to install this. It is a Claude Code plugin.**

```
/plugin marketplace add steffenmaas/founder-os
/plugin install agentic-dev@founder-os
```

That is the whole installation. No `git clone`, no `git pull`, no submodule, no subtree.

**To update:**

```
/plugin update
```

### What that gives you

| | |
|---|---|
| Skills | `/dev-onboard` `/dev-product` `/dev-spec` `/dev-loop` `/dev-review` `/dev-ship` `/dev-security` `/dev-metrics` `/dev-checkin` `/dev-learn` `/dev-dashboard` |
| Subagents | `planner` `builder` `reviewer` `verifier` `security-auditor` |
| Hooks | active immediately — force-push to `main`, `--no-verify`, local deploys and `.env` printing are blocked |

### If you are not using Claude Code

Only then, and only as a fallback:

```bash
git clone https://github.com/steffenmaas/founder-os /tmp/founder-os
bash /tmp/founder-os/plugins/agentic-dev/tools/install.sh
```

You get the rulebook, the templates, and the tooling in the project. You do not get the
skills, the subagents, or the hooks — those are Claude Code features. Codex and Cursor read
the rules through `AGENTS.md`.

---

# Using it

## Runbook A — a brand-new project

```bash
gh repo create my-product --private --clone && cd my-product
git commit --allow-empty -m "chore: init" && git push -u origin main
claude
```

Then, in Claude Code:

```
/dev-onboard
```

It will **interview you** to fill in `PRODUCT.md` — this is the step that matters most, and
it is the one only you can answer. Expect questions about the target user, the problem, the
non-goals, and what defines "done" for version 0.1.0.

Then:

| Step | Command | What happens |
|---|---|---|
| 1 | `/dev-product` | Turn `PRODUCT.md`'s version scope into a roadmap. Max 3 items in *Now*. |
| 2 | `/dev-spec <first item>` | Interview → spec with executable acceptance criteria. **Stops before code.** |
| 3 | *(new session)* `/dev-loop <first item>` | Orient → plan → build → verify → hand to review |
| 4 | `/dev-review` | QA Agent, fresh context, sees only the diff and the criteria |
| 5 | `/dev-ship` | **You** run this. Never the agent. |
| 6 | `/dev-checkin` | End of day: what was built, what is open, what is blocked |

Before step 3, finish the manual setup `/dev-onboard` listed: branch protection, secret
scanning, Dependabot, environments. The pipeline is not decoration — it is the layer that
catches what prose cannot.

## Runbook B — an existing project

```bash
cd ~/Repository/my-existing-project
git checkout -b chore/agentic-dev-onboarding
claude
```

```
/dev-onboard
```

It surveys first and reports before writing: language, package manager, existing CI, existing
deploy path, whether the test suite actually runs. **It never overwrites anything without
asking** — on conflict it places the template alongside as `<file>.founder-os-new` and tells
you.

For an existing project, four things need your attention:

1. **`PRODUCT.md` is written retrospectively.** You have a product; write down what it is and
   what it is not. The non-goals section is the one that pays off — it is what stops agents
   proposing adjacent features forever.
2. **`ROADMAP.md` is seeded from your real backlog**, then cut to 3 items in *Now*. That
   limit will feel wrong. It is the point.
3. **Write 3–5 retrospective ADRs** for decisions already made. Without them, every new agent
   re-litigates them, every time.
4. **Run `/dev-metrics` as a baseline** before changing how you work. Otherwise you will
   never know whether this helped.

Then the same loop as Runbook A from step 2.

---

# How the pieces fit

## The intent hierarchy

Everything derives downward. Nothing may contradict the level above it.

```
  PRODUCT.md      version · vision · principles · non-goals · target user
       ▼          "What is this product, and what is it not?"
  ROADMAP.md      Now (max 3) · Next (max 7) · Later · Done
       ▼          "What do we build, in what order?"
  docs/specs/     one spec per unit of work
       ▼          "What exactly does this one change do?"
  Plan            ordered steps, each with its own check
       ▼
  Commits         one logical step each
```

`PRODUCT.md` carries the **product version**. The roadmap is the path from the current
version to the next one. When a version's scope completes, the version is bumped and the
roadmap is re-cut — see `workflows/version-cut.md`.

A roadmap item that does not trace to `PRODUCT.md` gets flagged, not silently built.

## The loop

```
  ORIENT ─▶ SPEC ─▶ PLAN ─▶ BUILD ─▶ VERIFY ─▶ SHIP ─▶ LEARN
     ▲                                                   │
     └───────────────────────────────────────────────────┘
```

Full rules: [`knowledge/blueprint.md`](knowledge/blueprint.md)

## Agent contracts

Each contract defines one role: mandate, inputs, outputs, allowed tools, hard boundaries,
definition of done, escalation. An agent works under exactly one at a time.

| Contract | Role | The boundary that matters |
|---|---|---|
| [`product-agent`](knowledge/contracts/product-agent.md) | Product, roadmap, specs | Proposes priority, never sets it |
| [`dev-agent`](knowledge/contracts/dev-agent.md) | Writes production code | Never approves or merges its own work |
| [`qa-agent`](knowledge/contracts/qa-agent.md) | Verifies and reviews | Never fixes what it finds |
| [`security-agent`](knowledge/contracts/security-agent.md) | Security review | Never holds deploy credentials |
| [`release-agent`](knowledge/contracts/release-agent.md) | Ships to production | Human-invoked only |

**Dev and QA are separate contracts because an agent that writes and approves its own code
has no verification loop — it has a rubber stamp.** Everything else here is downstream of
that one decision.

## The harness — deciding when the rules run out

[`knowledge/harness.md`](knowledge/harness.md) holds the decision guidelines: the priority
ladder, trade-off heuristics, stop conditions, ambiguity resolution order, **decision
confidence** (score every open decision; above the project's threshold the agent decides
and logs, below it the decision is queued for the human — bundled, never blocking), and
code judgement defaults.

Two companion doctrines: [`knowledge/deploy-gate.md`](knowledge/deploy-gate.md) — the
checklist that decides, deterministically, whether a change auto-ships or waits on a preview
channel for human approval — and [`knowledge/backlog.md`](knowledge/backlog.md) — the live,
source-weighted backlog (admin → paying → free → anonymous; bugs always beat features;
excellence before expansion) the autonomous loop pulls from.

The ladder, when two things conflict — higher wins:

```
1. Correctness  2. Security & data integrity  3. Reversibility  4. The stated requirement
5. Consistency  6. Simple and obvious         7. Shipping something small
```

## Workflows

[`workflows/`](workflows/) — the named sequence for each kind of work. Each is a table of
steps: **who** (contract), **what**, and **the gate** before the next step.

| Workflow | Use when |
|---|---|
| [`autonomous-loop`](workflows/autonomous-loop.md) | Continuous development from a live backlog — the standing meta-workflow |
| [`new-feature`](workflows/new-feature.md) | Building something that does not exist |
| [`bug-fix`](workflows/bug-fix.md) | Behaves incorrectly, production stable |
| [`hotfix`](workflows/hotfix.md) | Production is broken right now |
| [`refactor`](workflows/refactor.md) | Structure changes, behaviour does not |
| [`dependency-update`](workflows/dependency-update.md) | Adding or upgrading a dependency |
| [`incident`](workflows/incident.md) | Something is on fire, cause unknown |
| [`version-cut`](workflows/version-cut.md) | A product version is complete |
| [`ux-audit`](workflows/ux-audit.md) | A bundle group shipped — simulated-user check of direction |

---

# Where project knowledge lives

This is the question that decides whether the system compounds or leaks.

| What | Where | Binding? | Lifecycle |
|---|---|---|---|
| **Rules** | `.founder-os/` | Yes | Managed upstream. Replaced on update. **Never edit locally.** |
| **Decisions** (ADR) | `docs/decisions/` | **Yes** | Written once, superseded rather than edited |
| **Learnings** | `docs/learnings/` | No | Append-only log |
| **Specs** | `docs/specs/` | For one change | Archived after shipping |
| **Check-ins** | `docs/checkins/` | No | Running log |
| **Product & roadmap** | `PRODUCT.md`, `ROADMAP.md` | Yes | Living |

## Decisions vs. learnings — the distinction that gets confused

| | Decision (ADR) | Learning |
|---|---|---|
| Is | A **constraint** | An **observation** |
| Binds future work | Yes | No |
| Example | "All money is integer minor units" | "The seed script hangs when run twice" |
| Lives in | `docs/decisions/` | `docs/learnings/` |
| Ends with | "**Binding for agents:** …" | "What we do differently now" |

An ADR that is really an observation clutters the constraint set. A learning that is really a
constraint gets ignored. `/dev-learn` asks this question first, every time.

## How learnings reach the Founder OS repo

This is the feedback loop that keeps the module honest.

```
  incident in a project
        ▼
  docs/learnings/YYYY-MM-DD-slug.md      scope: project | upstream
        ▼                                 (project → stays; upstream → travels)
  /dev-learn --upstream
        ▼   groups related learnings, drafts the rule change,
        │   picks the enforcement level, runs validate + hook tests
        ▼
  PR against steffenmaas/founder-os
        ▼   reviewed by a human — a rule has a cost, and the PR must state it
        ▼
  merged → /plugin update → the rule reaches every project
        ▼
  learning marked `submitted: <PR URL>` so it is never sent twice
```

**A rule is created after an incident, never preventively.** Preventive rules inflate the
blueprint without preventing anything, and an inflated blueprint stops being read — at which
point the rules that do matter stop working too. If you cannot name the incident, do not
propose the rule.

---

# Four levels of enforcement

A rule that is only written down gets followed *most* of the time. That is not enough at a
hundred changes a week.

| Level | Effect | Example |
|---|---|---|
| **Blueprint** | Covers everything, enforces nothing | "Do not widen a spec's scope" |
| **Contracts** | Bind a role | QA never fixes what it finds |
| **Hooks** | Block locally, immediately | Force-push to `main` → exit code 2 |
| **CI gates** | Last line, humans included | Deleted tests → PR red |

Rule of thumb for adding one: violation merely annoying → blueprint. Violation destroys work
or endangers security → hook **and** CI gate.

Three boundaries are enforced mechanically, because prose is not enough at volume:

| Boundary | Mechanism |
|---|---|
| QA and Security cannot write files | Subagent `tools:` restriction |
| No local deploys, no force-push to `main` | `hooks/scripts/guard-bash.sh`, exit code 2 |
| Release is human-invoked | `disable-model-invocation: true` |

---

# Structure

```
agentic-dev/
├── knowledge/
│   ├── blueprint.md              The binding rulebook
│   ├── harness.md                How to decide when the rules run out
│   ├── deploy-gate.md            Auto-ship or human approval — the checklist
│   ├── backlog.md                The live, source-weighted backlog
│   └── contracts/                5 agent contracts
├── workflows/                    9 named work sequences
├── skills/dev-*/SKILL.md         11 skills
├── agents/                       5 subagents (only `builder` may write)
├── hooks/                        Guards + scripts
├── templates/project/            Copied into a project by /dev-onboard
│   ├── PRODUCT.md  ROADMAP.md  CLAUDE.md  AGENTS.md
│   ├── CONTRIBUTING.md  SECURITY.md
│   ├── docs/{specs,decisions,learnings}/_template.md
│   └── .github/  ci · security · preview · deploy · dependabot · CODEOWNERS · PR template
├── tools/
│   ├── install.sh                Called by /dev-onboard; fallback for non-Claude-Code
│   ├── repo_metrics.py           Cadence, failure rate, rework, hotspots from git
│   ├── validate.py               Self-check of this module
│   └── test_hooks.sh             Regression test for the guards
└── docs/                         Developer guide, sources, analysis method
```

---

# Self-checks

```bash
python3 tools/validate.py     # JSON, YAML, front matter, shell syntax, links, placeholders
bash    tools/test_hooks.sh   # does the guard block what it must, pass what it must
```

Both green as of the current version.

---

# The governing principle

The blueprint is a living document. A rule is created **after** an incident, not
preventively. And when a rule does not work in practice, it gets **changed** — not ignored.
A rulebook that is quietly violated is worse than none: it manufactures the illusion of
control.

## Lean by design

Modern models already contain engineering knowledge — teaching it back to them wastes the
context that the rules that matter need. So the rulebook carries only what a model cannot
know: **policy** (where things live, limits, thresholds, role boundaries), **enforcement**
(hooks, gates, guard tests — knowledge is not compliance), and **incident-tagged rules**
(things a model got wrong here, stated tersely). All reasoning lives in
[`docs/lean-rationale.md`](docs/lean-rationale.md), read by humans and never loaded as agent
context. When cutting further: cut knowledge, never policy — and never remove a rule whose
incident you cannot name as resolved.

*Ocean One Ventures · Founder OS v2.0 · Module 16 · agentic-dev v0.4.1*
