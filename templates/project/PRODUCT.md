<!--
  TEMPLATE — copy to the repository root as PRODUCT.md.
  Replace everything in <ANGLE BRACKETS>. Delete what does not apply.

  This is the top of the intent hierarchy:
      PRODUCT.md  →  ROADMAP.md  →  docs/specs/  →  plan  →  commits
  Nothing below may contradict it. A roadmap item that does not trace to this file
  is not a roadmap item.
-->

# <Product Name>

**Version: 0.1.0** · Last cut: <YYYY-MM-DD>

## One-liner

<What this is, for whom, in one sentence. If you need two, it is not clear enough yet.>

## Target user

<Who, specifically. Not "businesses" — "charter operators with 5–50 boats in the
Mediterranean who currently list on Boataround and manage enquiries by email".>

## Problem

<The pain that justifies this product existing. What do they do today instead, and why
does that hurt?>

## Principles

<Three to seven lines. These are the rules that settle arguments — when two options are
both reasonable, these decide. Make them specific enough to actually exclude something.>

- <e.g. "A first listing goes live in under 10 minutes, or we have failed.">
- <e.g. "We never ask for data we do not immediately use.">
- <e.g. "Mobile is the primary surface; desktop is the secondary one.">

## Non-goals

<What this product deliberately is **not**. The section that prevents drift — and the one an
agent reads before proposing anything.>

- <e.g. "Not a booking or payment system — we hand off to the operator's existing flow.">
- <e.g. "Not a marketplace. We never take a cut of a transaction.">
- <e.g. "No native apps before 1.0.">

---

## Current version — 0.1.0

**This version is about:** <one paragraph>

**Scope — done when all of these are true:**

- [ ] <A capability a user would notice. Not a task.>
- [ ] <…>
- [ ] <…>

<Between three and seven items. Each one a capability, not a task. A scope made of tasks
is never *complete*, only *abandoned* — which is how version numbers stop meaning anything.>

## Next version — 0.2.0

**Likely about:** <one paragraph. Rough is fine; this gets sharpened at the version cut.>

---

## Constraints

| Constraint | Detail |
|---|---|
| Budget | <e.g. "Under €200/month infrastructure until we have paying users"> |
| Timeline | <e.g. "Demo-ready for METSTRADE in November"> |
| Compliance | <e.g. "GDPR — EU customer data stays in EU regions"> |
| Team | <e.g. "One founder plus agents. Anything requiring a second human is out of scope."> |

## Success metrics

<How do we know this version worked? Two or three numbers, with the current value.>

| Metric | Now | Target for this version |
|---|---|---|
| <e.g. Listings published> | <0> | <25> |
| <e.g. Time to first listing> | <—> | <under 10 min> |

---

*Version bumps are a human decision, prepared by the Product Agent. See
`.founder-os/workflows/version-cut.md`.*
