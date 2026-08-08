# Workflow — UX Audit (simulated users)

**Use when:** a bundle group has shipped, at a version cut, or on demand. This is the check
that development is going in the right direction **from the user's point of view** — the
one direction unit tests cannot see.
**Entry:** step 8 of `autonomous-loop.md`, or `/dev-review` with the audit as the stated goal.

> A technically correct flow that loses the user is a finding. The goal chain this audit
> serves: experience → retention → monetisation. A user whose expectations are met keeps
> using the product; a user who keeps using it pays.

---

## Personas

Simulated users live in `docs/personas/*.md`, derived from `PRODUCT.md`'s target user. Each
persona is a profile the auditor **stays in character as**: who they are, what they came
for, what they expect at each step, what makes them leave, and what would make them pay.
Minimum set: a **new anonymous user**, a **returning free user**, a **paying user**.

---

| # | Who | What | Gate |
|---|---|---|---|
| 1 | QA | **SELECT** — 2–4 personas covering the minimum set above. | Personas exist. If not: write them first, from `PRODUCT.md`. No personas, no audit. |
| 2 | QA | **WALK** — for each persona, walk their critical journeys on the preview or production build, as that persona: their goal, their patience, their vocabulary. Screenshot every step. | Every step has evidence, not memory. |
| 3 | QA | **JUDGE** — per step: was the persona's expectation met? Is there a drop-off edge — a dead end, an unclear next step, a broken promise, a wait without feedback? Is the value of the next step visible before it is asked for? | Every finding has the persona, the step, and the expectation that broke. |
| 4 | QA | **MONETISE** — walk the paying moment explicitly: is the value clear *before* the paywall? Does the purchase path work end to end? Does the paying user visibly get what was promised, immediately? | Funnel documented step by step. |
| 5 | Product | **FILE** — findings become backlog items: broken → `bug`, friction → `improvement`, both `source: ux-audit`. Per the backlog doctrine they outrank new features. | Filed with persona and step reference. |
| 6 | Product | **REPORT** — one page: per persona, per journey — OK / friction / abort, with the trend against the previous audit. Into the check-in. | Trend visible. An audit that cannot say "better or worse than last time" ran too rarely. |

---

## Rules

1. **The audit judges the experience, not the code.** "The API returned 200" is not a
   result; "the persona did not understand what to do next" is.
2. **Stay in character.** The moment the auditor uses knowledge the persona does not have —
   where a button is, what a term means — the audit stops measuring anything real.
3. **Drop-off edges are the primary finding.** Every point where the persona would abandon
   is worth more than ten cosmetic observations.
4. **The audit never fixes.** Findings go to the backlog; the loop fixes them under the
   normal contracts.
5. **Cadence:** once per bundle group is the floor. An audit per increment is too slow;
   an audit per quarter measures nothing anyone remembers causing.
