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
| [`agentic-dev`](plugins/agentic-dev/) | 16 · Agentic Dev — Product & Tech Delivery, Pre-Seed | v0.3.0 |

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
