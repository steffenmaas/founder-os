# Adopting Agentic Dev in an existing project

The concrete, do-this-then-that guide for pointing at a running project — one with real
users, an existing deploy path, maybe its own home-grown agent loop — and saying:
**"from now on, work exactly like this."** Everything happens inside Claude Code.

One principle governs the whole migration: **the templates and workflows are a menu, not a
mandate.** Take what the project needs, simplify it to fit, delete the rest. A project that
already deploys keyless to Firebase keeps its deploy workflow; a project with no UI skips
the persona set. What is *not* negotiable is the doctrine underneath: verification before
handoff, dev/QA separation, the deploy gate, Conventional Commits from adoption day.

---

## Step 0 — Preconditions (5 minutes)

1. The module must be installable: `steffenmaas/founder-os` `main` must contain the plugin
   (merged marketplace layout). To test before a merge, add the marketplace from a local
   clone instead: `/plugin marketplace add /path/to/founder-os`.
2. In Claude Code (terminal or desktop app):

```
/plugin marketplace add steffenmaas/founder-os
/plugin install agentic-dev@founder-os
```

   **Working in Claude Code on the web (cloud sessions)?** The `/plugin` commands are not
   available there. Instead, commit `.claude/settings.json` to the project (the template
   ships it — `templates/project/.claude/settings.json`): it declares the marketplace under
   `extraKnownMarketplaces` and the plugin under `enabledPlugins`, and every cloud session
   of the repo loads the module automatically. Commit that file as the *first* step of the
   onboarding branch; the rest of this guide is identical in cloud and terminal.

   **No manual file handling needed:** don't download or copy anything — tell the session
   to do it. One paste-able prompt in a cloud session on the target repo covers this whole
   step: *"Write `.claude/settings.json` declaring the `founder-os` marketplace
   (`github: steffenmaas/founder-os`) and enabling `agentic-dev@founder-os`, commit and
   push. Then clone `steffenmaas/founder-os` and follow
   `plugins/agentic-dev/docs/adopt-existing-project.md` from step 1."* The clone gives the
   *current* session the rulebook right away; the settings file makes every *future*
   session load the plugin natively (plugins load at session start).

3. Open the project, start from a clean tree, and create the onboarding branch:

```bash
cd ~/Repository/<project>
git checkout -b chore/agentic-dev-onboarding
claude
```

## Step 1 — Onboard (30–60 minutes, interactive)

```
/dev-onboard
```

It surveys first (language, package manager, existing CI, existing deploy path, whether the
test suite runs) and reports before writing. It never overwrites: conflicts land alongside
as `<file>.founder-os-new`. After it runs, do the pruning pass yourself:

- **Keep** what the project already does well. An existing keyless deploy workflow beats
  the template — keep it, and add only the missing piece (usually the post-deploy
  verification job from `deploy.yml`).
- **Simplify** what you take. Cut every template section that does not apply. A template
  kept "just in case" is noise that buries the rules that matter.
- **Delete** the rest, including `.founder-os-new` files you decided against.

Minimum that must exist afterwards: `CLAUDE.md` (with real commands), `AGENTS.md`,
`.founder-os/`, `docs/{specs,decisions,learnings,checkins}/`, a CI quality gate
(lint + typecheck + tests + coverage measurement on every PR — from `ci.yml`, adapted).

## Step 2 — Write the past down (1–2 hours, the step that pays most)

An existing project has history the agents cannot see. Capture it once:

1. **`PRODUCT.md` retrospectively.** What the product is, current version, target user —
   and above all the **non-goals**. This is what stops agents proposing adjacent features
   forever.
2. **3–5 retrospective ADRs** for decisions already made and not up for re-litigation
   (stack, hosting, data model, "web first", pricing model). Use the template's revision
   rule: a decision later proven wrong gets a *new* superseding ADR, never an edit.
3. **Harvest existing learnings.** If the project has a home-grown runbook with dated
   incident rules ("X is a trap", "never do Y — see 29.07"), each of those is a learning:
   move them into `docs/learnings/` with the template, `scope:` set honestly. Generalisable
   ones go upstream later via `/dev-learn --upstream`.
4. **Re-cut `ROADMAP.md`**: Now (max 3) / Next (max 7) / Later / Done — seeded from the
   real backlog, cut hard.

## Step 3 — Wire the backlog (30 minutes)

Pick the store in `preferences/project-config.json` (`backlog.store`) — the doctrine in
`.founder-os/backlog.md` is the same for all three:

- **Project has in-app feedback already** (e.g. a Firestore `feedback`/`roadmap` pair with
  a CLI): keep it — that user-visible loop is a differentiator. Add what is missing,
  usually the `source` field (`admin | paying | free | anonymous`) so weighting works.
- **Team lives in a ticket system**: connect it, map the fields.
- **Neither**: start with files in `docs/backlog/`, migrate to a store when in-app
  feedback exists.

## Step 4 — Set the dials (10 minutes)

In `preferences/project-config.json`:

| Dial | Question it answers |
|---|---|
| `decisions.confidence_threshold` | Above which confidence does the agent decide alone? Start at 70; lower it as the decision log earns trust. |
| `deploy_gate.mode` + `always_gate` | Which paths always need your approval? List the money/auth/data paths of *this* project. |
| `testing.full_suite_budget_minutes` | How long may the full suite take? If the suite already blows the budget, trimming it becomes a backlog item on day one. |
| `loop.bundle_max_items` | How much lands in one bundle before the full-suite + audit pass. |

## Step 5 — Baseline, then switch the commits (10 minutes)

1. `/dev-metrics` once, for the record — the before-picture.
2. **From this commit on: Conventional Commits.** History is not rewritten; metrics are
   simply read from the adoption date forward (`--since`). Put the adoption date in
   `CLAUDE.md` so the cut is documented.

## Step 6 — Merge, then run

1. PR the onboarding branch through the new CI gate — this PR is the first test of the
   pipeline itself. Merge.
2. Supervised warm-up (recommended for the first days): work item by item —
   `/dev-spec <item>` → fresh session `/dev-loop <item>` → `/dev-review` → `/dev-ship`.
3. Autonomous operation: start an orchestrator session on
   `.founder-os/workflows/autonomous-loop.md`. It pulls from the backlog, bundles, ships
   through the deploy gate, and re-arms itself. If the project had a home-grown loop
   runbook, **retire it explicitly** — one line at its top: "superseded by
   `.founder-os/workflows/autonomous-loop.md`" — so no agent follows two doctrines.

## Adoption is done when

- [ ] CI quality gate green on a real PR (lint, typecheck, tests, coverage measured)
- [ ] `PRODUCT.md` non-goals filled; roadmap cut to 3/7
- [ ] ADRs and learnings folders populated from history, not empty scaffolds
- [ ] Backlog store chosen, `source` weighting works
- [ ] Deploy gate configured with this project's `always_gate` paths
- [ ] Post-deploy verification runs (pipeline green + version marker + health)
- [ ] First bundle shipped through the loop, full-suite pass green, audit findings filed
- [ ] Old process docs retired with a pointer, not deleted
