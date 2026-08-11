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

The module is adopted from three different places, and they do **not** behave the same. Only
the first was documented, which is how a project ended up with the rulebook and no runtime for
three weeks.

| Where you work | How to install | Reach |
|---|---|---|
| **Terminal / CLI** | `/plugin marketplace add steffenmaas/founder-os` then `/plugin install agentic-dev@founder-os` | The machine you ran it on |
| **Claude Code app** (desktop/mobile) | Customize → Plugins → add → add marketplace → the `steffenmaas/founder-os` GitHub repo → enable `agentic-dev` | The account, on the devices that sync it |
| **Cloud sessions** (`claude.ai/code`, scheduled runs) | **Neither of the above reaches them.** See below. | — |

The `/plugin` slash commands do not exist outside the terminal. The app's plugin screen is the
equivalent path there, and it is the one most adopters will actually use — it was missing from
this document entirely.

### Cloud and other ephemeral environments

Plugin install state is machine-level: it lives in `~/.claude/plugins/installed_plugins.json`.
A cloud session, a CI job, or a scheduled run gets a **fresh container**, so that file starts
empty and any earlier installation — terminal or app — never reaches it.

Committing `.claude/settings.json` with `extraKnownMarketplaces` and `enabledPlugins` is not a
substitute: measured in a project that had exactly that committed, `installed_plugins.json` was
still `{"version": 2, "plugins": {}}` on a live container. **Declaring a marketplace is not
fetching it.**

So a loop that runs in ephemeral containers cannot be equipped by installing anything once.
Only what is in the repository survives — `.claude/agents/*.md` is read straight from the
project directory, with no marketplace and no fetch, and mirroring the agent definitions there
is currently the only way to give such a loop a `builder` at all. Whether the module should
offer a blessed path for this (an `install.sh --with-agents`, say) is an open question; today
it does not, and adopters discover the gap by watching their loop write its own code.

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
- `agents/`, `skills/` and `hooks/` belong to **neither**: they are plugin-native, loaded
  through `plugin.json`, and are **deliberately not copied into a project**. `install.sh`
  never touches them. Say this out loud, because the omission is otherwise indistinguishable
  from a bug — someone who finds `agents/` here and not in their project has nothing to tell
  them which it is. **Without the plugin loaded, a project has the rulebook but cannot
  delegate** — see *Install* above for which environments that actually bites in: `autonomous-loop.md` instructs the orchestrator to dispatch to `builder`, and
  there is no `builder`. The orchestrator then writes the code itself and reviews its own
  diff, silently, which is precisely what the contracts exist to prevent.

Getting this wrong is how a rulebook forks into five divergent copies.
