---
name: dev-onboard
description: Sets up Agentic Dev in a repository — writes PRODUCT.md, ROADMAP.md, CLAUDE.md, AGENTS.md, spec/ADR/learning templates, CI, security, preview and deploy workflows, and the managed .founder-os directory. Use this skill when the user says "set up agentic dev", "onboard this repo", "apply the blueprint here" or any natural variant. Module 16 (Agentic Dev) — Product & Tech Delivery. Pre-Seed.
---

# Onboard a repository

This skill is part of the **Founder OS** plugin, Module 16 — Agentic Dev (Product & Tech Delivery).

**Contract:** none — this is setup, run by a human.
**Run once per repository.** After this, `/dev-product` and `/dev-loop` take over.

## When to trigger

Run this skill when the user says any of:

- "set up agentic dev"
- "onboard this repo"
- "apply the blueprint here"
- "get this project on Founder OS"
- `founder-os:dev-onboard`

## Key instructions

**Target:** $ARGUMENTS (default: current directory)

State of the repo: !`ls -a 2>/dev/null | head -30`
Existing workflows: !`ls .github/workflows/ 2>/dev/null`
Git: !`git log --oneline -5 2>/dev/null; git remote -v 2>/dev/null | head -2`

---

### Step 1 — Survey before writing anything

Determine, and report back before making changes:

- Language, package manager, framework
- Existing scripts in `package.json` / `Makefile` / `pyproject.toml`
- Existing CI, existing deploy path, hosting provider
- Does `CLAUDE.md`, `AGENTS.md`, or `.cursorrules` already exist?
- **Does the test suite actually run?** Try it.

**Never overwrite anything that exists without asking.** On conflict: show both, ask.

### Step 2 — Install the managed directory

```bash
bash ${CLAUDE_PLUGIN_ROOT}/tools/install.sh
```

This copies `blueprint.md`, `harness.md`, `contracts/`, `workflows/` and `tools/` into
`.founder-os/` in the project, and writes the version stamp. That directory is **managed**:
it is replaced on every update, and CI blocks PRs that edit it.

### Step 3 — Write the intent hierarchy

This is the part only a human can supply. Do not guess it — **interview them.**

Use `AskUserQuestion`, bundled, to fill in `PRODUCT.md`:

- What is this, for whom, in one sentence?
- Who is the target user, specifically?
- What do they do today instead, and why does it hurt?
- What is this product deliberately **not**?
- What version are we on, and what defines "done" for it?

Then write, from the templates in `${CLAUDE_PLUGIN_ROOT}/templates/project/`:

| File | Adapt |
|---|---|
| `PRODUCT.md` | **Yes — from the interview.** Nothing derives correctly without it. |
| `ROADMAP.md` | Yes — seed from existing issues/backlog, max 3 in *Now* |
| `CLAUDE.md` | **Yes — real commands, real architecture** |
| `AGENTS.md` | Light — project name only |
| `CONTRIBUTING.md` | Rarely |
| `SECURITY.md` | Contact address |
| `docs/specs/_template.md` | No |
| `docs/decisions/0000-template.md` | No |
| `docs/learnings/_template.md` | No |
| `.github/workflows/*.yml` | **Yes — commands and hosting provider** |
| `.github/dependabot.yml` | Ecosystem |
| `.github/CODEOWNERS` | Names |
| `.github/PULL_REQUEST_TEMPLATE.md` | No |
| `.claude/settings.json` | No — makes every cloud session load the plugin |

**`CLAUDE.md` and `PRODUCT.md` are the two that matter.** A template left full of
`<PLACEHOLDERS>` is worse than no file at all — it produces agents that guess commands and
build things the product does not want.

### Step 4 — Retrospective ADRs

Write ADRs for the three to five most significant architectural decisions already made.
Without them, every new agent re-litigates them. Each needs the "**binding for agents:**"
line filled in.

### Step 5 — Repository settings (manual, with the human — do it NOW, step 7 tests exactly these)

No repository content can set these; they live in GitHub. Do not just list them — walk the
human through each one with the exact path (or `gh` command), wait for confirmation, and
record the outcome:

| Setting | Exactly where / how | Caveat |
|---|---|---|
| **Branch protection on `main`** | Settings → Branches → *Add branch ruleset* for `main`: require PR, require status checks **by the job names just installed** (e.g. `quality`, `secret scan (gitleaks)`), block force pushes, include administrators. CLI: `gh api -X PUT repos/<owner>/<repo>/branches/main/protection --input protection.json` | Check names must match the workflow job names or "required checks" never turn green. |
| **Actions may create PRs** | Settings → Actions → General → Workflow permissions → tick **"Allow GitHub Actions to create and approve pull requests"** | **Required by `founder-os-update.yml`** — without it the daily update PR dies with 403. |
| **Actions default permissions** | Same page → *Read repository contents* | Individual jobs widen per-workflow `permissions:` blocks. |
| **Secret scanning + push protection** | Settings → Advanced Security → enable both | **Private repos need the paid Secret Protection add-on.** Without it, the gitleaks CI job plus the local scan hook are the working control — report this box as *plan-limited*, never as ticked. |
| **Dependabot alerts + security updates** | Settings → Advanced Security → enable both | Free on all plans. |
| **Environments** | Settings → Environments → create `preview` / `staging` / `production`; bind secrets to the right one; optional **required reviewer on `production`** | The required reviewer is the manual approval gate for deploy-gated changes. |

Report every row as **ticked**, **plan-limited**, or **postponed by the human** — never
silently skipped. This step is where adoption PRs go red for reasons that look like code
but are configuration (see the adoption guide, step 6).

### Step 5b — Learning contribution: ask, never assume

The module improves through learnings travelling from projects back upstream. **That only
happens if this project is allowed to send them — so ask, once, here.** Never assume
consent: upstreaming is a **publication act**. `steffenmaas/founder-os` is a public
repository, so anything sent becomes readable by anyone.

Ask with `AskUserQuestion`, and state that consequence in the question:

| Answer | What it means | Config |
|---|---|---|
| **Yes, contribute** | Generalisable learnings are bundled into a PR against the module. Each one is scrubbed first (blueprint §9.3): no unfixed security finding, no internals — the incident is described generically. | `"contribute_upstream": "yes"` |
| **Ask me each time** *(default)* | Learnings are still written and marked `scope: upstream`, but nothing leaves the repository without your explicit go-ahead per batch. | `"contribute_upstream": "ask"` |
| **No** | Everything stays local. `/dev-learn --upstream` refuses and says why. The project still benefits from incoming updates; it just does not send. | `"contribute_upstream": "no"` |

Write the answer into `preferences/project-config.json` → `learnings.contribute_upstream`,
and say in the onboarding report which mode is active. **A project running on `"ask"` or
`"no"` is a perfectly good citizen** — an unwilling contributor who was never asked is not.

### Step 6 — Baseline measurement

```bash
python3 ${CLAUDE_PLUGIN_ROOT}/tools/repo_metrics.py .
```

Write the result to `docs/checkins/baseline-YYYY-MM-DD.md`. Every gap it surfaces goes into
`ROADMAP.md` under *Later*.

### Step 7 — Verify the setup

- [ ] `PRODUCT.md` has a version line and a non-empty non-goals section
- [ ] `CLAUDE.md` contains no `<PLACEHOLDERS>`
- [ ] Every command in `CLAUDE.md` actually runs
- [ ] `ROADMAP.md` has at most 3 items in *Now*, each with a spec or moved back to *Next*
- [ ] CI passes on a test PR
- [ ] The blueprint gate fails on a deliberately bad commit message
- [ ] Preview URL appears as a PR comment
- [ ] Branch protection blocks a direct push to `main`

Report which boxes are ticked and which are not. Do not claim the setup is complete with open
boxes.

### Step 8 — Start the loop (setup does not start it)

**Onboarding ends with a configured repository and a *stopped* loop.** Say that explicitly —
a human who assumes the loop is now running loses a day waiting. Offer the three ways to
start, and ask which one they want:

1. **Supervised** (recommended for the first days): `/dev-spec <first item>` → fresh session
   `/dev-loop` → `/dev-review` → `/dev-ship`, item by item.
2. **Autonomous, this session** — paste:
   > Work autonomously per `.founder-os/workflows/autonomous-loop.md`: pull from the
   > backlog, bundle, ship through the deploy gate, refresh the dashboard, re-arm every
   > ~15 minutes. Spawn every delegated dispatch, check and watchdog as a **named
   > background task** so I can see what is running. Contact me only for deploy-gate
   > approvals, queued decisions, or finished milestones.
3. **Autonomous, around the clock:** the ~15-minute re-arm lives only as long as its
   session. For 24/7 operation, create a scheduled task / Routine that starts or wakes the
   orchestrator session on a fixed cadence (e.g. hourly) with exactly the prompt from
   option 2 — the schedule is the heartbeat, the session is the loop.

**The onboarding report's final line is always one of:**
`LOOP: not started — awaiting the human's choice` · `LOOP: started (supervised | autonomous | scheduled)`.
