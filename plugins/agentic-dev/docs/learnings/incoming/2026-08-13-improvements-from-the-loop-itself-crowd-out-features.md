---
date: 2026-08-13
scope: upstream
area: process
severity: high
submitted:
---

# An improvement queue the loop fills itself will, by the priority rules, never let a feature through

## What happened

Three days of autonomous cycles, measured afterwards: **48 merges, 14 of them
user-visible — and zero of the last eight.** Every merge was sound. The verification chain
was green throughout, every change had an independent QA verdict, every deploy was
confirmed against the live version marker. Nothing went wrong in the sense the gates are
built to catch.

The work in that last stretch was all internal: four verification mechanisms that were green
and proved nothing, an extended deploy marker, backlog hygiene. Each was genuinely worth
doing — one of them was a payment-path safeguard that had never been executed, so it could
have been deleted with every test still passing.

But the product did not move, and the loop could not have moved it.

## Why it happened

Two rules in `backlog.md`, both working exactly as written.

**Priority 0 — "reachable before refined"** — outranks everything but security while the
product cannot be "opened, used end to end, or **deployed at all**". The first two clauses
have a binary answer. The third does not, once an agent reads it as *deployability* rather
than *deployed*: a deploy proof can always be sharpened, so infrastructure work permanently
qualifies for the top of the queue. The rule's own text names the failure it means to
prevent — *"the most common way an agentic loop looks busy while standing still"* — and this
is that failure arriving through the rule rather than around it.

**Priority 3 — "excellence before expansion"** — pulls features only when no bug and no
improvement is open. That is right when improvements come from users. It behaves differently
when they come from the loop: an agent inspecting its own tooling files improvements faster
than it clears them, and the queue never empties. In this project **14 of 16 open backlog
entries carried `source: agent`, nine of them `improvement`.** Under rule 3 that is a
permanent block on every feature, with no rule broken and nothing to notice from inside.

The weighting in rule 4 (`admin` → `paying` → `free` → `anonymous`) is what would normally
correct this, but it orders *within* a class. It cannot help when one class is full and the
class below it is where the product lives.

## What we do differently now

Recorded as ADR-0007 in this project: Priority 0 counts only when it blocks a **named**
delivery, not as a standing category; an empty *Now* list is not a stop signal but a reach
through to *Next*; and the decision threshold for the agent becomes reversibility.

The measurement that made this visible is worth repeating anywhere: **count merges by
whether a user could notice them, per day.** It took one command and it turned a vague sense
of "we are busy but not moving" into a number that could be argued with.

## Generalisable?

Yes — nothing here depends on the stack, the product, or the team. Any project running an
autonomous loop long enough for the loop to start filing its own improvements will reach the
same state, and the two rules involved are module-level.

Two changes, both in **`backlog.md`** (the backlog doctrine), because that is where the
priority order lives and both are one sentence each.

**1 — bound Priority 0's third clause.** After *"or deployed at all"*, add:

> Each of these three has a yes-or-no answer, and Priority 0 ends when the answer is yes.
> *"The deploy could be proven better"* is not one of them — an improvable proof is never
> finished, and treating it as Priority 0 keeps the queue at the top forever.

**2 — qualify Priority 3 by source.** After *"New features are pulled only when no bug and
no improvement is open"*, add:

> Improvements the loop filed about its own machinery (`source: agent`, `area` internal) do
> not hold features back. A loop that inspects its own tooling can file faster than it
> clears, and rule 3 then blocks every feature indefinitely without any rule being broken.
> User-sourced improvements keep their precedence — the point of rule 3 is that a product
> which gets better beats one which gets bigger, and an agent's note about its own test
> harness is not the product getting better.

**Level: blueprint/doctrine, not a hook or CI gate.** The failure is slow and reversible —
it costs direction, not work or security — and the corrective is a human noticing a ratio.
A hook cannot tell an internal improvement from a product one without judgement, and a rule
that guesses would be worse than the one it replaces.

**Cost of the change, named:** internal quality work loses its automatic top slot, so a
genuine infrastructure defect can now sit behind a feature. That is the intended trade, and
it is only safe while a QA gate still runs on every change — which is what caught the four
meaningless-green checks in the first place. A project that drops both would be trading
away the wrong half.
