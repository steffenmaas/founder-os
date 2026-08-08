# The Live Backlog — weighted by source, processed continuously

> `ROADMAP.md` holds **intent**: the path from this product version to the next. The live
> backlog holds **execution**: the queue the loop actually pulls from, around the clock.
> Confusing the two produces either a roadmap nobody executes or a queue nobody steers.

## Where it lives

In an operational store the loop can read and write continuously — a Firestore collection, a
database table, an issue tracker with an API. **Not a markdown file**: the backlog changes
many times a day, from user feedback and from agents, and a file in git makes every triage a
commit. Selected views are user-visible in the product (roadmap, "implemented" timeline) —
users who see their feedback move trust the product more.

## Item shape

| Field | Values |
|---|---|
| `type` | `bug` · `improvement` · `feature` · `idea` · `research` |
| `source` | `admin` · `paying` · `free` · `anonymous` · `ux-audit` · `agent` |
| `reports` | How many independent reports merged into this item |
| `status` | `new` · `triaged` · `open` · `in_progress` · `done` · `rejected` |
| `priority` | Computed — see below. Never hand-set except by the human. |

## Priority — the rules, in order

1. **Security jumps the queue.** A High or Critical vulnerability outranks everything.
2. **Bugs always beat features.** A bug reported by an anonymous user outranks a feature
   requested by the founder. Broken beats new.
3. **Excellence before expansion.** Improvement items (`improvement`, `ux-audit`) outrank
   new features. New features are pulled only when no bug and no improvement is open —
   a product that gets better beats a product that gets bigger.
4. **Within a class, the source decides:** `admin` → `paying` → `free` → `anonymous`.
   A paying user's friction is churn; an anonymous user's friction is signal. Both count —
   in that order.
5. **Independent reports merge and rise.** The same issue reported three times is one item
   with `reports: 3`, and it outranks a single report of the same class and source. Volume
   is evidence.

## Triage — Product Agent contract

- New feedback is triaged, not queued raw: bugs get a reproduction check, ideas get deduped
  against existing items and the product's non-goals.
- **An item that contradicts `PRODUCT.md` is flagged, not queued.** The backlog cannot widen
  the product's scope on its own — that is the roadmap's job, and it belongs to the human.
- **Rejection is allowed and visible.** `rejected` with one line of why, propagated back to
  the reporting user. A visible "no" beats a silent backlog grave.
- **Done propagates back.** When an item ships, the originating feedback is marked
  implemented, so the reporting user sees the loop close.

## Relationship to the roadmap

- Roadmap items enter the backlog as `feature` / `source: admin` — they compete under the
  same rules as everything else, which is exactly why rule 2 and 3 matter: the founder's
  feature list waits while the product is broken.
- At a version cut (`workflows/version-cut.md`), the backlog's `done` list is the evidence
  for what the version actually delivered.
