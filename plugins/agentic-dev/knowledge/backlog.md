# The Live Backlog — weighted by source, processed continuously

> `ROADMAP.md` holds **intent**: the path from this product version to the next. The live
> backlog holds **execution**: the queue the loop actually pulls from, around the clock.
> Confusing the two produces either a roadmap nobody executes or a queue nobody steers.

## Where it lives — the store is pluggable

The backlog doctrine (item shape, priority rules, triage) is fixed. **The store is not** —
the project chooses one in `project-config.json` (`backlog.store`):

| Store | When | Trade-off |
|---|---|---|
| **Database** (e.g. a Firestore collection) | The product has a backend and users give feedback in-app | The strongest option: real-time, and selected views are **user-visible in the product** — roadmap, "implemented" timeline, feedback threads. A user who reports something in the app, sees it picked up, shipped, and gets told — that loop is a product differentiator, not process overhead. |
| **Ticket system** (e.g. Linear, GitHub Issues) | A team already lives in one | Native triage UI and notifications; in-app visibility needs a sync. |
| **Work directory** (files in the repo) | Small projects, no backend yet | Zero infrastructure; every triage is a commit, and nothing is user-visible. The starting point, not the destination. |

Whichever store: the loop reads and writes it through the same rules below, and switching
stores must never change what gets built next.

## Ticket size — cut to user-observable value

A ticket is **one change a user (or the founder) could notice**, describable in one sentence
of its effect — not an implementation step. Implementation steps live *inside* the loop as
increments of a bundle; they are never tickets themselves.

- Too small: "rename the constant", "part B3 of the folder restructure" — that is an
  increment. A backlog of 500 micro-tickets is unsteerable; the grouping work the loop does
  at BUNDLE time then has to undo the over-cutting.
- Too big: "improve the nutrition module" — that is a roadmap theme. Split until one
  sentence of user-visible effect describes it.
- The test: **would this ticket's completion be worth telling the reporting user about?**
  If not, merge it into one that would.

## Item shape

| Field | Values |
|---|---|
| `type` | `bug` · `improvement` · `feature` · `idea` · `research` |
| `source` | `admin` · `paying` · `free` · `anonymous` · `ux-audit` · `agent` |
| `reports` | How many independent reports merged into this item |
| `status` | `new` · `triaged` · `open` · `in_progress` · `done` · `rejected` |
| `priority` | Computed — see below. Never hand-set except by the human. |

## Priority — the rules, in order

0. **Reachable before refined.** While the product cannot be opened, used end to end, or
   deployed at all, everything that closes that gap outranks everything else except a
   security fix: getting it live, making the critical path work, putting one automated
   check on that path. **Polish on a product nobody can open is waste** — and it is the
   most common way an agentic loop looks busy while standing still.
   Each of the three has a yes-or-no answer, and Priority 0 ends when the answer is yes.
   *"The deploy could be proven better"* is not one of them: an improvable proof is never
   finished, so treating it as Priority 0 holds the top of the queue forever — the same
   standing still, arriving through the rule instead of around it.
1. **Security jumps the queue.** A High or Critical vulnerability outranks everything.
2. **Bugs always beat features.** A bug reported by an anonymous user outranks a feature
   requested by the founder. Broken beats new.
3. **Excellence before expansion.** Improvement items (`improvement`, `ux-audit`) outrank
   new features. New features are pulled only when no bug and no improvement is open —
   a product that gets better beats a product that gets bigger.
   **Improvements the loop filed about its own machinery (`source: agent`, internal area)
   do not hold features back.** A loop inspecting its own tooling files faster than it
   clears, so this rule otherwise blocks every feature indefinitely with no rule broken
   and nothing visible from inside. User-sourced improvements keep their precedence: an
   agent's note about its own test harness is not the product getting better.
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
