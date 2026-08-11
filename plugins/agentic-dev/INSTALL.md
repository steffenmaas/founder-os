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
      "description": "… keep in sync with plugins/agentic-dev/.claude-plugin/plugin.json — that file is the source of truth for description and version …",
      "version": "X.Y.Z",
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

### Updating: the marketplace cache is refreshed separately from the plugin

**A greyed-out "Update" button usually means the client's copy of the marketplace is stale,
not that you are current.** The client caches the marketplace file when you add it, and
compares your installed version against that *cache* — not against the repository. If the
cache still says `0.5.0` and you have `0.5.0`, the button is correctly disabled and you are
six releases behind.

Symptom that identifies it precisely: the panel shows an **old version together with an old
description**. Metadata and version travel in the same file, so both go stale together.

| Where | How to refresh |
|---|---|
| Terminal | `/plugin marketplace update founder-os`, then `/plugin update` |
| App (desktop/mobile) | the plugin's or marketplace's `⋮` menu → refresh/update the marketplace |
| Anywhere, guaranteed | remove the marketplace and add it again — that forces a fresh fetch |

Toggling the plugin off and on does **not** refetch metadata; neither does restarting the
app. Compare against the source of truth before assuming the client is right:

```bash
curl -sS https://raw.githubusercontent.com/steffenmaas/founder-os/main/.claude-plugin/marketplace.json
```

None of this affects cloud sessions or CI — those never load the plugin at all and take
their runtime from the committed `.claude/` mirror (below).

The `/plugin` slash commands do not exist outside the terminal. The app's plugin screen is the
equivalent path there, and it is the one most adopters will actually use — it was missing from
this document entirely.

### Cloud and other ephemeral environments

Plugin install state is machine-level: it lives in `~/.claude/plugins/installed_plugins.json`.
A cloud session, a CI job, or a scheduled run gets a **fresh container**, so that file starts
empty and any earlier installation — terminal or app — never reaches it.

> **Do not commit `extraKnownMarketplaces` into a project.** A marketplace declared by
> project settings is not one the human added, so the client refuses to let them manage it:
> removing it in the plugin UI has no effect (the setting re-declares it on the next
> session, and the add dialog answers *"this marketplace was already added"*), and the
> **Update button stays greyed out** because there is no user-owned entry to update. Both
> symptoms were hit in production, and both look like client bugs rather than a committed
> setting. The template therefore ships `enabledPlugins` only — the marketplace is added
> once, by the human, wherever they actually work. Recovery when it is already committed:
> remove the block, then use **Synchronise** in the add dialog to refresh the cache.
>
> `enabledPlugins` is an **object** (`{"agentic-dev@founder-os": true}`), not an array. The
> template shipped the array form while the running production project carried the object
> form — they must not diverge.

Committing `.claude/settings.json` with `extraKnownMarketplaces` and `enabledPlugins` is not a
substitute: measured in a project that had exactly that committed, `installed_plugins.json` was
still `{"version": 2, "plugins": {}}` on a live container. Measured again on a second cloud
container, there was no `~/.claude/plugins/` directory at all. **Declaring a marketplace is not
fetching it.**

So a loop in an ephemeral container cannot be equipped by installing anything once. **Only
what is in the repository survives** — and `.claude/agents/*.md` and `.claude/skills/*/SKILL.md`
are read straight from the project directory, with no marketplace and no fetch.

`install.sh` therefore **mirrors the runtime into `.claude/`** (section 1b): the six subagents,
eleven of the twelve skills, and the two hook scripts, with the hooks wired into
`.claude/settings.json` by merging rather than overwriting. `dev-onboard` is the one skill left
out — it rewrites `PRODUCT.md`, `ROADMAP.md`, `CLAUDE.md` and `AGENTS.md` from blank templates,
correct for a first-time setup and dangerous mirrored into a project that has been running for
weeks. Commit `.claude/` — it is what carries the module into an environment that cannot
install it.

| | |
|---|---|
| **Managed, replaced on update** | `.claude/agents/`, `.claude/skills/dev-*/`, `.claude/hooks/` — recorded in `.claude/.founder-os-manifest` |
| **Never touched** | your own skills and agents under `.claude/`; only manifest paths are removed |
| **Merged, not overwritten** | `.claude/settings.json` |
| **Opt out** | `install.sh --no-claude-assets`, when the plugin is properly installed and you would rather not have both |

Why on by default: a duplicate agent name on a machine that also loads the plugin is visible
and harmless. A missing `builder` is neither — the loop writes its own code and reviews its own
diff, and the state looks completely healthy from the outside.

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
- `agents/`, `skills/` and `hooks/` are plugin-native — loaded through `plugin.json` where a
  plugin can be loaded, and **mirrored into `.claude/` where one cannot** (see *Cloud and
  other ephemeral environments* above). Those copies are managed like `.founder-os/`:
  replaced on every update, recorded in `.claude/.founder-os-manifest`, never hand-edited.
  What is *not* managed is everything else under `.claude/` — the project keeps its own
  skills and agents there, and the installer only ever removes paths it wrote itself.

Getting this wrong is how a rulebook forks into five divergent copies.
