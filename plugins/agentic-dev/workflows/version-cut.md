# Workflow — Version Cut

**Use when:** the scope of the current product version is complete, and the roadmap needs
re-cutting against the next one.
**Entry:** `/dev-product` — the Product Agent proposes; the human decides.

> This is the workflow that keeps `PRODUCT.md` from becoming a document nobody reads. Without
> a periodic cut, the roadmap drifts free of the product intent and the version number stops
> meaning anything.

---

| # | Who | What | Gate |
|---|---|---|---|
| 1 | Product | **ASSESS** — is the current version's stated scope actually complete? Go through it item by item against `ROADMAP.md` → *Done*. | Every scope item is either done, explicitly dropped, or moved. No hand-waving. |
| 2 | Product | **MEASURE** — run `/dev-metrics` for the version's time window. Deploy frequency, change failure rate proxy, rework rate, test ratio. | Numbers in hand, with their data-quality caveat. |
| 3 | Product | **HARVEST** — read every `docs/learnings/` entry written during this version. Which are `scope: upstream` and not yet submitted? | Upstream learnings queued for `/dev-learn --upstream`. |
| 4 | Product | **PROPOSE** — draft the version bump: new number, what the next version is about in one paragraph, and its scope. | Human reviews. |
| 5 | Human | **DECIDE** — approve, adjust, or defer. | Approved. |
| 6 | Product | **CUT** — bump the version in `PRODUCT.md`, write the new scope, archive the old *Done* list, re-cut `ROADMAP.md`: *Now* emptied and refilled (max 3) against the new scope. | `ROADMAP.md` traces cleanly to the new `PRODUCT.md`. |
| 7 | Release | **TAG** — git tag for the version, release notes from the *Done* list. | Tag pushed. |
| 8 | Dev | **UPSTREAM** — run `/dev-learn --upstream`. Everything generalisable from this version reaches the Founder OS module. | PR opened against `founder-os`. |

---

## Versioning

Semantic-ish, at the product level rather than the API level:

| Bump | Means | Who decides |
|---|---|---|
| **Major** (`1.0.0` → `2.0.0`) | The product is for a different user, or does a fundamentally different thing | **Founder, always** |
| **Minor** (`0.4.0` → `0.5.0`) | A coherent set of capability landed. This is the normal cut. | **Founder approves before the cut** |
| **Patch** (`0.4.0` → `0.4.1`) | Fixes and polish only, no new capability | Agent, autonomously |

**A version cut is a founder decision, not a side effect of finishing work.** An agent that
completes a capability proposes the bump and waits; it does not release it. Only patch
releases ship autonomously. The failure this rule exists for: three capability releases cut
in one working day, each individually justified, none of them a moment the founder chose —
version numbers signal pace and stability to everyone consuming the module, and that signal
belongs to the founder. When in doubt whether something is patch or minor, it is minor —
which means: ask.

**Pre-1.0 means the product shape is still moving.** Going to `1.0.0` is a statement that the
core is stable and you intend to keep it — not that everything is finished.

## What makes a good version scope

Between three and seven items, each one a capability a user would notice. Not tasks.

- Good: "Charter operators can publish a boat listing with 3D model and take enquiries."
- Bad: "Refactor the upload pipeline, add S3 support, fix the thumbnail bug."

The scope is what makes step 1 answerable. A scope of tasks is never *complete*, only
*abandoned* — which is how version numbers stop meaning anything.

## Cadence

Cut when the scope is done, not on a calendar. But if a version has been open for more than
about eight weeks, that is a signal the scope was too large — split it, cut, and put the rest
in the next one.
