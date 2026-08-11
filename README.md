# Founder OS

**The AI agent stack for startup building · Ocean One Ventures · v2.0**

Founder OS is a set of Claude Code plugins covering the work of building a startup from
Pre-Seed to Series A: 28 AI agents across 7 modules.

Stages: **PS** = Pre-Seed · **S** = Seed · **SA** = Series A

| Module group | Agents |
|---|---|
| Strategy | 01 `Fo` Feasibility & Opportunity (PS) · 02 `Bm` Business Model (PS) · 03 `Ca` Competitor Analysis (S) · 04 `Vr` Vision, Roadmap & OKRs (S) |
| Market | 05 `Cu` Customer Intelligence (PS) · 06 `Mr` Market Research (S) · 07 `Jm` Journey Mapper (S) · 09 `Cn` Customer Nurturing (PS) |
| Sales & Distribution | 08 `Rv` GTM Playbook (PS) · 10 `Mk` Marketing & PR (S) · 11 `Bs` B2B Sales Engine (S) · 12 `Bg` B2C Growth Engine (S) |
| Product & Tech Delivery | 15 `Dm` Design Mockup (PS) · **16 `Ad` Agentic Dev (PS)** · 17 `Pm` PMF Tracker (S) · 18 `Sc` Scaling Architect (SA) |
| Capital | 19 `Im` Investor Matcher (PS) · 20 `Rm` Round Manager (S) · 21 `Tn` Term Navigator (S) · 22 `Ma` M&A Radar (SA) · 32 `Gn` Grant Navigator (PS) |
| Finance & Legal | 23 `Ue` Unit Economics (PS) · 24 `Fm` Financial Model (PS) · 25 `Lg` Legal Guardrail (S) · 26 `Mo` Financial Monitor (SA) |
| Team & AI Agents | 27 `Td` Team Development (S) · 28 `Ao` AI Operations (PS) · 30 `Au` Autonomous Ops (SA) · 31 `Fx` Founder Match (PS) |

This repository is a **Claude Code plugin marketplace**. One marketplace, one or more
plugins inside it (`plugins/<name>/`).

## Available plugins

| Plugin | Module | Status |
|---|---|---|
| [`agentic-dev`](plugins/agentic-dev/) | 16 · Agentic Dev — Product & Tech Delivery, Pre-Seed | v0.6.0 |

## How to use this — concretely

### In Claude Code (the primary way)

**Terminal or desktop app — install once** (per machine, takes effect in every project):

```
/plugin marketplace add steffenmaas/founder-os
/plugin install agentic-dev@founder-os
```

Update later with `/plugin update`. That gives you 12 skills, 6 subagents, the stack
blueprints, and the enforcement hooks — active immediately.

**Claude Code on the web / cloud sessions:** the `/plugin` commands are terminal- and
desktop-only. For cloud sessions, the plugin is declared in the **project repo** instead —
commit this as `.claude/settings.json` (the onboarding templates ship it):

```json
{
  "extraKnownMarketplaces": {
    "founder-os": {
      "source": { "source": "github", "repo": "steffenmaas/founder-os" }
    }
  },
  "enabledPlugins": ["agentic-dev@founder-os"]
}
```

Commit once; every cloud session of that repo then loads the module automatically —
skills, subagents, and hooks included. (Org-wide alternative for Team/Enterprise: server-
managed settings under Admin Settings → Claude Code.)

**You never create this file by hand.** In a cloud session on the target project, paste:

> Set this project up for Founder OS: write `.claude/settings.json` declaring the
> marketplace `github: steffenmaas/founder-os` under `extraKnownMarketplaces` and enabling
> `agentic-dev@founder-os` under `enabledPlugins`, commit and push it. Then clone
> `steffenmaas/founder-os` and follow
> `plugins/agentic-dev/docs/adopt-existing-project.md` from step 1.

The session writes and commits the file itself and runs the onboarding; the plugin's
skills and hooks are active from the **next** session onward (plugins load at session
start). Cloning the repo mid-session, as in the prompt above, is the bridge for the first
session — it gives that session the full rulebook immediately.

**Start a brand-new project:**

```bash
gh repo create my-product --private --clone && cd my-product
git commit --allow-empty -m "chore: init" && git push -u origin main
claude
```

then, inside Claude Code: `/dev-onboard` — it interviews you and writes `PRODUCT.md`,
`ROADMAP.md`, `CLAUDE.md`, the docs structure, and the CI templates.

**Switch an existing project to this way of working:** follow
[`plugins/agentic-dev/docs/adopt-existing-project.md`](plugins/agentic-dev/docs/adopt-existing-project.md)
step by step — install, `/dev-onboard` with a prune pass, write the history down
(retro ADRs, learnings), wire the backlog, set the dials, switch to Conventional Commits.

**Day-to-day commands:**

| You want | Type |
|---|---|
| Put the project on a proven stack + keyless deploy | `/dev-stack` |
| Decide what to build next | `/dev-product` |
| Specify one unit of work | `/dev-spec <item>` |
| Build it (fresh session) | `/dev-loop <item>` |
| Review with fresh context | `/dev-review` |
| Ship it (you, never the agent) | `/dev-ship` |
| See where development stands | `/dev-dashboard` |
| End-of-day status | `/dev-checkin` |
| Capture what you learned | `/dev-learn` |
| Speed / quality numbers | `/dev-metrics` |
| Security pass | `/dev-security` |

**Run it autonomously:** start a session and say —

```
Work autonomously per .founder-os/workflows/autonomous-loop.md: pull from the backlog,
bundle, ship through the deploy gate, refresh the dashboard, re-arm every ~15 minutes.
Spawn every delegated dispatch, check and watchdog as a named background task so I can
see what is running. Only contact me for deploy-gate approvals, queued decisions, or
finished milestones.
```

### In Codex, Cursor, or any other agent

There is no plugin system there, so use the file-based fallback — once per project:

```bash
git clone https://github.com/steffenmaas/founder-os /tmp/founder-os
cd ~/Repository/<your-project>
bash /tmp/founder-os/plugins/agentic-dev/tools/install.sh
```

That writes the managed rulebook into `.founder-os/` (blueprint, harness, contracts,
workflows, stack blueprints) and creates any missing project files from the templates. Codex reads the rules
through `AGENTS.md` automatically; for other agents, start every task with:

```
Read .founder-os/blueprint.md in full. Act under .founder-os/contracts/<role>.md.
Follow .founder-os/workflows/<workflow>.md for this kind of work.
```

Command equivalents — instead of a skill, state the contract:
`/dev-loop` → *"Work as Dev Agent per `.founder-os/contracts/dev-agent.md` on
`docs/specs/<slug>.md`."* · `/dev-review` → *"Review this diff as QA Agent per
`.founder-os/contracts/qa-agent.md` against the spec's acceptance criteria."*

What you keep: the rulebook, workflows, templates, and `tools/repo_metrics.py`
(`python3 .founder-os/tools/repo_metrics.py .`). What you lose without Claude Code:
skills, read-only subagents, and the enforcement hooks — the rules then bind by being
read, not mechanically.

Full detail: [`plugins/agentic-dev/README.md`](plugins/agentic-dev/README.md) ·
plugin wiring: [`plugins/agentic-dev/INSTALL.md`](plugins/agentic-dev/INSTALL.md)

## Releases

Module versions are cut per `workflows/version-cut.md`: when a version's scope completes,
the plugin version is bumped, tagged (`agentic-dev/vX.Y.Z`), and release notes are written
from the shipped scope.

## Licence

[PolyForm Noncommercial 1.0.0](LICENSE) — free to use for founders, teams, non-profits,
education and research; commercial exploitation by third parties is not licensed.
Rationale: [ADR-0001](docs/decisions/0001-license-polyform-noncommercial.md).

## Self-checks

```bash
python3 plugins/agentic-dev/tools/validate.py
bash    plugins/agentic-dev/tools/test_hooks.sh
```

Both run in CI (`.github/workflows/validate.yml`) and must be green before merging.
