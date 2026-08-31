# Roadmap — <Product Name>

> Derived from `PRODUCT.md` — current version <0.1.0>, target <0.2.0>. No dates, no story
> points. **This file is the orchestration master: one ordered list of packages, and the
> position IS the priority.** What sits on top is built next. The founder overrides at any
> time by saying so; the loop reorders below that per the backlog doctrine
> (`.founder-os/backlog.md`) and never stops working just because yesterday's feedback is
> worked off — when intake is empty, the next package on this list is the work.
>
> **A package is a release, not a ticket.** It is built as a whole, verified once, merged
> once. Each carries: an id, a speaking name, a spec link, the backlog/feedback ids it
> closes, and one sentence of what a user can do afterwards that they could not before.
>
> **Cut large, not small.** All findings in one area are ONE package; a new package exists
> only when none fits. A list of twenty entries is a ticket pile with headings, not a
> roadmap.
>
> **Done means shipped — and leaves this file.** A finished package needs no line here;
> its record is the release note (`docs/releases/`). This file describes the future only.
>
> **This file is updated by the PR that ships the change, never afterwards.** A merge that
> leaves it untouched is exactly the mechanism by which a roadmap goes stale.

## Package ids

| Prefix | Means | Example |
|---|---|---|
| `F` | **Feature** — afterwards a user can do something that did not work before | `F001` |
| `B` | **Bug** — something does not do what it claims, or lies | `B004` |
| `T` | **Technical** — tooling, build, process; invisible to the user | `T002` |

Rules, and they are the actual point:

1. **One running number per prefix**, at least three digits from `001`, so lists sort
   themselves and the number circle never wraps within a product's life.
2. **A number is never reused and never renumbered** — it is an identity, not a position.
   Reordering changes the order, not the names.
3. **One prefix per package.** A defect *and* an extension are two packages.
4. **The id leads the package name and the PR title** — `B004 · <name>` — so both map
   without lookup. A release then reads cleanly: "contains F003, B004–B006, T002".

## The list — position = priority

<!-- One entry per package. Spec missing? Then writing the spec is the package's first
     increment. Keep each entry to the four lines below — the past is not documented here. -->

- [ ] **F001 · <speaking name>** — <one sentence: what a user can do afterwards>
      Spec: [docs/specs/F001-<slug>.md](docs/specs/F001-<slug>.md) · closes: <feedback ids>
- [ ] **B001 · <speaking name>** — <one sentence: what stops being broken>
      Spec: <link or "to write — first increment">
- [ ] **T001 · <speaking name>** — <one sentence: what the loop or build can do afterwards>
      Spec: <link>
