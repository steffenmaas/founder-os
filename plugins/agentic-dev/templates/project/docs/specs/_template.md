# <F01 · Title>

> File: `docs/specs/<F01-slug>.md` — named after the roadmap package it specifies.
> Status: Draft | Approved | Implemented | Dropped
> Package: <F01> · Product version: <0.1.0>
> Estimate: <n, anchored against two named MERGED packages — anything above 21 is a theme, split it>
> Author: <human/agent> · Date: <YYYY-MM-DD>

<!-- A spec describes BEHAVIOUR, not implementation. The codebase moves while a package
     waits its turn — a spec that names functions and files is stale the day it is built,
     and the builder reads the code fresh anyway. And it describes the FUTURE only: what
     will work, never the history of how we got here. -->

## Problem

<Who hurts, and how? Describe the pain, not the solution.>

## Goal

<One sentence. How do we know it is solved?>

## Non-goal

<Explicitly what will NOT be built. The most important section in this file —
an empty non-goal produces predictable scope creep.>

- <…>

## Traces to

<Which line in `PRODUCT.md` does this serve? If none, this is not ready.>

## Contract changes

<Only what outlives the current code: data-model changes (none / migration), breaking
changes (none / which interface), user-visible behaviour that changes. No file lists —
files are the PLAN phase's business, decided against the codebase as it is on build day.>

## Acceptance criteria

<Written as executable checks, not prose.
 Bad: "login works" · Good: `npm test -- auth.spec.ts` passes>

- [ ] `<command>` returns `<expected>`
- [ ] `<command>` passes
- [ ] <UI: screenshot matches `docs/design/…`>

## Verification step (end to end)

```bash
<the one command or sequence that proves it works>
```

## Risks and rollback

| Risk | Likelihood | Mitigation |
|---|---|---|
| <…> | <low/med/high> | <…> |

Rollback: <reverting the commit is enough / roll migration back with `<command>`, then revert>

## Plan

<Filled in during the PLAN phase. Each step independently committable, each with its check.>

1. <Step> → check: `<command>`
2. <Step> → check: `<command>`

**Not touched:** <explicit list — this is what prevents scope creep>
