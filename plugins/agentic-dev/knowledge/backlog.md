# The Live Backlog — weighted by source, processed continuously

> `ROADMAP.md` is the **orchestration master**: one ordered list of packages (`F`/`B`/`T`
> ids), and the position is the priority. The live backlog is **intake**: where feedback
> and findings arrive and get triaged. Triage folds items *into* roadmap packages — an item
> either joins the package it belongs to, or (rarely) founds a new one. Two lists that both
> claim to say what happens next produce either a roadmap nobody executes or a queue nobody
> steers; here, the roadmap decides and the backlog feeds it.

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

**Groom against the source of truth, not a projection.** When a store has been moved (say,
from a database collection into a versioned file) the old store often stays alive as a
read-only projection for the app — and it keeps answering *plausibly*, just with an older
set. A grooming pass that reads the projection concluded six existing tickets had never
been written and published that as fact; the ADR naming the real source would have settled
it in one minute. Before grooming: name which store is the source of truth, out loud, and
check `docs/decisions/` if there is any doubt.

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

**Estimate against anchors you can open — and cut anything above 21.** An estimate argued
from the work's description drifts; an estimate compared against two or three *merged*
packages of known size does not, because anyone can open the anchor and look. Whatever
relative scale the project uses: an item scoring above 21 is not an item, it is a theme —
split it before it enters a package. Measured over three days of autonomous work, the
top-priority workstream got its merges on day one and then none, while the loop kept
shipping smaller things; oversized, unanchored items are how that happens.

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

- Triage folds backlog items into roadmap packages: a `bug` joins (or founds) a `B`
  package, `improvement`/`feature` an `F` package, agent-internal work a `T` package. The
  package lists the ids it closes; done propagates back to every folded item.
- **Intake empty is not work done.** When the backlog has nothing new, the loop continues
  with the next package on the roadmap — the observed failure is a loop that works off
  yesterday's feedback overnight and then stops, with the roadmap untouched.
- At a version cut (`workflows/version-cut.md`), the shipped packages' ids (F/B/T) are the
  release's table of contents — see the release note step there.
