# Founder OS

**The AI agent stack for startup building · Ocean One Ventures · v2.0**

Founder OS is a set of Claude Code plugins covering the work of building a startup from
Pre-Seed to Series A: 28 AI agents across 7 modules.

| Module group | Agents |
|---|---|
| Strategy | Feasibility & Opportunity · Business Model · Competitor Analysis · Vision, Roadmap & OKRs |
| Market | Customer Intelligence · Market Research · Journey Mapper · Customer Nurturing |
| Sales & Distribution | GTM Playbook · Marketing & PR · B2B Sales Engine · B2C Growth Engine |
| Product & Tech Delivery | Design Mockup · **Agentic Dev** · PMF Tracker · Scaling Architect |
| Capital | Investor Matcher · Round Manager · Term Navigator · M&A Radar · Grant Navigator |
| Finance & Legal | Unit Economics · Financial Model · Legal Guardrail · Financial Monitor |
| Team & AI Agents | Team Development · AI Operations · Autonomous Ops · Founder Match |

This repository is a **Claude Code plugin marketplace**. One marketplace, one or more
plugins inside it (`plugins/<name>/`).

## Available plugins

| Plugin | Module | Status |
|---|---|---|
| [`agentic-dev`](plugins/agentic-dev/) | 16 · Agentic Dev — Product & Tech Delivery, Pre-Seed | v0.2.0 |

## Install

```
/plugin marketplace add steffenmaas/founder-os
/plugin install agentic-dev@founder-os
```

To update: `/plugin update`

See [`plugins/agentic-dev/README.md`](plugins/agentic-dev/README.md) for what the module
does and how to use it, and [`plugins/agentic-dev/INSTALL.md`](plugins/agentic-dev/INSTALL.md)
for how plugins are wired into this repository.

## Self-checks

```bash
python3 plugins/agentic-dev/tools/validate.py
bash    plugins/agentic-dev/tools/test_hooks.sh
```

Both run in CI (`.github/workflows/validate.yml`) and must be green before merging.
