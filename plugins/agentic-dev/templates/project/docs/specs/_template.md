# <Title>

> Status: Draft | Approved | Implemented | Dropped
> Roadmap: Now | Next · Product version: <0.1.0>
> Author: <human/agent> · Date: <YYYY-MM-DD>

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

## Affected files and interfaces

| Path | Change |
|---|---|
| `<src/…>` | <new / modified / deleted> |

Data-model changes: <none / migration `xyz`>
Breaking changes: <none / …>

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
