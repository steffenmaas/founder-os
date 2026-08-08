# Wiring this into the `founder-os` repository

This directory is a complete Claude Code plugin. Drop it into the Founder OS repo as a
plugin, add one entry to the marketplace file, done.

---

## Layout in the repo

```
founder-os/
├── .claude-plugin/
│   └── marketplace.json          ← add the entry below
└── plugins/
    └── agentic-dev/              ← this directory, unchanged
        ├── .claude-plugin/plugin.json
        ├── knowledge/  workflows/  skills/  agents/  hooks/
        ├── templates/  tools/  docs/
        └── README.md
```

This mirrors how `fund-os` is structured: one marketplace, one or more plugins inside it.

## The marketplace entry

```json
{
  "name": "founder-os",
  "owner": { "name": "Ocean One Ventures", "url": "https://github.com/steffenmaas" },
  "metadata": {
    "description": "Founder OS — the AI agent stack for startup building. 28 agents, 7 modules, Pre-Seed to Series A.",
    "version": "2.0.0"
  },
  "plugins": [
    {
      "name": "agentic-dev",
      "source": "./plugins/agentic-dev",
      "description": "Module 16 (Agentic Dev) — continuous agentic software development: product-anchored roadmap, specs, separated dev and QA contracts, CI/CD with preview channels, security gate, DORA metrics, and a learning loop back into this repo.",
      "version": "0.2.0",
      "category": "product-tech-delivery"
    }
  ]
}
```

## Install

```
/plugin marketplace add steffenmaas/founder-os
/plugin install agentic-dev@founder-os
```

## Test locally before pushing

```
/plugin marketplace add /path/to/founder-os
/plugin install agentic-dev@founder-os
/dev-metrics .
```

If the metrics report runs, the installation is sound.

## Self-checks

```bash
python3 tools/validate.py
bash    tools/test_hooks.sh
```

Both must be green before merging. CI (`.github/workflows/validate.yml`) runs the same two.

---

## Naming

Skills are prefixed `dev-`, so they will not collide with the other 27 Founder OS agents.
Descriptions end with the module tag:

```
Module 16 (Agentic Dev) — Product & Tech Delivery. Pre-Seed.
```

matching the `fund-os` convention (`Phase 02 (Sourcing & Market Watch). Fund-side only.`).

Called as `/dev-loop` when installed as its own plugin, or `founder-os:dev-loop` if the
skills are later merged into a single Founder OS plugin. Path references use
`${CLAUDE_PLUGIN_ROOT}`, so both work without changes.

---

## The one thing to get right

The plugin ships the **rules**. `/dev-onboard` writes the **project files**. Those are two
different lifecycles and they must not be confused:

- `.founder-os/` in a project is **managed** — replaced on every update. CI blocks PRs that
  edit it. Rule changes travel upstream as learnings (`/dev-learn --upstream`).
- `PRODUCT.md`, `ROADMAP.md`, `CLAUDE.md`, `docs/**` belong to the **project** — written once
  by `/dev-onboard`, owned by the project thereafter.

Getting this wrong is how a rulebook forks into five divergent copies.
