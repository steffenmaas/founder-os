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
| `.github/pull_request_template.md` | No |

**`CLAUDE.md` and `PRODUCT.md` are the two that matter.** A template left full of
`<PLACEHOLDERS>` is worse than no file at all — it produces agents that guess commands and
build things the product does not want.

### Step 4 — Retrospective ADRs

Write ADRs for the three to five most significant architectural decisions already made.
Without them, every new agent re-litigates them. Each needs the "**binding for agents:**"
line filled in.

### Step 5 — Repository settings (manual, with the human)

No repository content can enforce these. Walk the human through them:

- Branch protection on `main`: PR required, status checks required, no force pushes,
  administrators included
- Secret scanning + push protection enabled
- Dependabot security updates enabled
- Actions default permission set to "read repository contents"
- Environments `preview` / `staging` / `production` created, secrets bound to the right one
- Optional: required reviewer on `production` as the manual approval gate

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
