---
date: 2026-08-13
scope: upstream
area: process
severity: high
---

# Anchor estimates in merged work, and cut anything above 21

## What happened

Three days of autonomous work were measured from git. The loop was productive — dozens of
merges, a growing test suite, real user-facing fixes. But the roadmap's own top priority told a
different story:

| Day | Merges touching the top-priority workstream |
|---|---|
| Day 1 | **30 of 85** |
| Day 2 | 0 of 31 |
| Day 3 | 0 of 1 |

On day one the loop was exactly on target. Then it left and never came back — while continuing
to ship steadily from the backlog.

## Why it happened

Not neglect, and not a bad choice of tickets: nearly every ticket pulled was legitimate. The
cause is structural.

**The backlog always holds something small, self-contained and immediately finishable.** A cycle
that pulls one of those ends reliably with a green merge. The top-priority item was large,
needed a spec pass, and might produce nothing visible in its first cycle.

**A loop optimised for "every cycle ships" will therefore choose the small item every time** —
not from laziness, but because the rule rewards it. The large item was never cut into pieces a
cycle could finish, so no cycle ever started it.

## What we do differently now

A velocity scale whose anchors are **actually merged changes in this repository**, so any new
ticket can be held against something a reader can open:

| Vel. | Anchor |
|---|---|
| 1 | one wrong locale string |
| 3 | one function rewritten, threshold → two segments |
| 5 | a test seam through one widget |
| 8 | four cases where one was expected |
| 13 | two areas, a seam through four layers |
| 21 | a new UI element, ~1 200 lines, design decisions |
| 34 | 744 lines — but deletion semantics and a security review |
| 50 | a new processing pipeline, several cycles, open outcome |

Two rules keep it stable:

1. **Velocity measures uncertainty and coordination, not lines.** From the same history: a
   1 746-line pass of repetitive visual work is a **13**; a 744-line change that deletes data
   irreversibly and needs a security review is a **34**. Estimating by size gets both wrong.
2. **Anything above 21 is cut, not estimated.** A 34 or a 50 is not a work item — it is the
   finding that a spec pass is missing.

And the ordering rule the measurement produced: **pull from the current priority first; only
when nothing there is cut small enough, go to the backlog.**

## Generalisable?

Yes, and the bias is inherent to the loop shape the module describes. Any project with a
prioritised list and a "ship every cycle" expectation will drift toward small items unless the
large ones are cut.

**Level: harness**, plus one line in the orchestrator contract.

`harness.md`, new guideline:

> **Estimate against anchors, not against feelings.** Keep a small scale (1 · 3 · 5 · 8 · 13 ·
> 21) where every step is anchored to a change that actually merged in this repository, so an
> estimate can be checked by opening a diff. Velocity measures uncertainty and coordination, not
> lines — a large repetitive change is small; a small irreversible one is not.
>
> **Anything above 21 is cut, not estimated.** A large number is not a work item; it is the
> observation that a spec pass is missing. Uncut, it will never be pulled, because the backlog
> always offers something a cycle can finish today.

`contracts/orchestrator-agent.md`:

> **Pull from the current priority before the backlog.** Only when nothing there is cut small
> enough to finish does a cycle take a backlog item — and then the missing cut is itself the
> next thing to produce.

**Cost of the rule:** cycles that begin a large item may end without a merge. That is the price
of ever finishing one, and it should be said out loud rather than hidden behind a green cycle.
