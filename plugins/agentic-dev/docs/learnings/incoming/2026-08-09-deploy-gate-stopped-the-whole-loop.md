---
date: 2026-08-09
scope: upstream
area: process
severity: medium
submitted:
---

# The loop rules say a gate stops everything; the harness says decisions never block. Both cannot be true.

## What happened

An increment in a live project (a `firebase-admin` 12 → 14 migration) touched a path listed
in `deploy_gate.always_gate`, so it needed human approval. The PR was opened and the loop
stopped.

The founder was asleep. Nothing moved for hours — and the backlog had plenty of ungated work
ready to go.

Worse was the trap underneath. The gated PR sat on the project's **designated development
branch**. Any further increment would have been committed to that same branch and landed in
that same PR. So the choice was:

1. stall until a human answers, or
2. keep working and let the next approval silently cover unrelated changes the human never
   reviewed — **destroying the very gate that was being respected**, or
3. open a second branch, which the project's own instructions forbade without permission.

The orchestrator picked (1), then asked. The founder's answer:

> „Eine Entscheidung sollte niemals die Entwicklung blockieren. Alle Entscheidungen werden
> gesammelt, und sofern eine Entscheidung dann blockiert, kann natürlich auf einem anderen
> Zweig weiterentwickelt werden. Ansonsten bleibt die Entwicklung ja bei jeder Entscheidung
> stehen."

## Why it happened

The module says both things, in two files, and they contradict each other:

- `knowledge/harness.md` §5 — decisions are **collected, not blocking**.
- `workflows/autonomous-loop.md`, Loop rules — *"The loop stops for a red `main` and for the
  deploy gate — for nothing else."*

The second sentence reads naturally as "the gate halts the loop", and that is how it was
followed. It is also the only place the module says what to do about the branch, which is
nothing — so the branch collision above is not covered anywhere.

A red `main` genuinely is a hard stop: nothing else can ship until it is fixed, so continuing
only piles up unshippable increments. **A gate is not that.** It means *this one increment*
needs a human. The rest of the backlog is unaffected.

## What we do differently now

In the adopting project: a gated increment is committed to its own branch
`<dev-branch>-gate-<slug>`, its PR is opened and left for the human, the development branch
is reset to `origin/main`, and the loop takes the next item in the same cycle. Recorded as a
binding project decision (ADR-0007) rather than a habit, because it changes what the loop is
allowed to do.

## Generalisable?

Yes. Every project adopting this module will eventually hit a gate on its development branch,
at which point it faces the same three bad options. Two of them are actively harmful: idling,
and — the dangerous one — accidentally widening an approval to cover unreviewed work. Nothing
in the module currently warns about the second.

### Proposed change — `workflows/autonomous-loop.md`, Loop rules

Replace:

```markdown
The check-in presents the queue bundled. The loop stops for a red `main` and for the deploy
gate — for nothing else.
```

with:

```markdown
The check-in presents the queue bundled.

**A gate stops the increment, not the loop.** When a change hits the deploy gate, finish it,
commit it to **its own branch** (`<dev-branch>-gate-<slug>`), open its PR, leave it for the
human — then reset the development branch to `origin/main` and take the next item in the same
cycle. Two failure modes this avoids: idling for hours until a human wakes up, and — worse —
stacking later work onto the gated PR, where a single approval silently covers changes the
human never looked at. That destroys the gate it was meant to respect.

**A red `main` is the one hard stop.** If shipping is broken, fixing it *is* the work;
anything else just piles up increments that cannot ship.
```

### Level and why

**Workflow.** No principle changes — `harness.md` §5 was right all along; the loop rules
stated the consequence wrongly and left the branch question unanswered. Fixing it where the
loop is described is enough, and the branch instruction has to live there because that is the
only place the loop's git behaviour is specified.
