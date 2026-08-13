---
date: 2026-08-13
scope: upstream
area: process
severity: medium
---

# Decide by default; a question must carry the cost of each option

## What happened

Over three days the loop put a steady stream of decisions to the founder, each politely framed
with options and a recommendation. His feedback afterwards was direct: several were
self-evident, and answering them was work he should not have been doing.

One was worse than merely unnecessary. Push notifications were failing because a service
account lacked a messaging role. The loop offered two routes and recommended the one it could
build without human involvement — a broader existing account. The recommendation was accurate
about convenience and **silent about the price**: that account carried admin rights over the
entire datastore and auth, including minting tokens for any user. The founder chose the other
route and was right to. A security review afterwards confirmed the concern was real.

## Why it happened

The loop treated "present options clearly" as the whole obligation. Clear options are necessary
and not sufficient: an option without its cost is not a decision basis, it is a menu. And a
loop that asks whenever it *could* ask will ask constantly, because almost every step has two
defensible paths.

## What we do differently now

A written threshold. **The default is to decide, implement, and justify in the pull request.**
A question goes to the human only when at least **two** of four hold:

1. **Hard to reverse.** Data formats needing migration, public URLs, prices, third-party
   commitments. Code almost never qualifies.
2. **Costs real money or rights.** A paid call per user, a subscription, an IAM role, a service
   account.
3. **Changes what the user is promised** — not how a feature is built, but whether it exists and
   what it commits to.
4. **No basis exists.** Neither product doc, roadmap, ADR nor spec answers it, and neither of two
   paths is visibly better.

One point is not enough; "affects the user" is true of nearly every line.

Two supporting rules:

- **At most one question per cycle.** Three questions means two were not attempted.
- **A question names the cost of each option, not just the option.** The incident above is the
  reason this is written down.

And the test that settles most cases: *if I decide it myself and I am wrong, what does the
correction cost?* One cycle → decide. A migration, a store review, or money → ask.

## What would have raised confidence

A written record of which service account holds which role, and what each role grants. The
recommendation was made without it, and the gap was only visible to a reviewer who went looking.
An inventory of privileged identities is cheap and would have surfaced the cost at the moment
the option was written, not afterwards.

## Generalisable?

Yes. The failure mode — a loop that defers upward because deferring feels safe — appears
wherever an autonomous loop reports to one person. And the human is exactly the resource the
module exists to protect: many founders are not technical and do not want to adjudicate
implementation choices at all.

**Level: harness.**

> **Decide by default; escalate by exception.** Implement and justify in the pull request unless
> at least two of these hold: hard to reverse · costs money or rights · changes what the user is
> promised · no basis exists in the product doc, roadmap, ADRs or specs. One of the four is not
> enough — "affects the user" is true of nearly everything.
>
> **At most one question per cycle.** More than one usually means the others were not attempted.
>
> **Every option carries its cost.** An option presented without what it gives up is not a
> decision basis. A recommendation that omits a security or money cost is a defect in the
> question, not a detail.

**Cost of the rule:** the loop will occasionally decide something the human would have decided
differently, and it will have to be corrected. That is cheaper than a human answering ten
questions to prevent one.
