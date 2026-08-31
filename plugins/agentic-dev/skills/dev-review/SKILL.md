---
name: dev-review
description: Reviews a diff with fresh context against the acceptance criteria under the QA Agent contract — correctness, edge cases, security, test integrity, suppressed errors. Reports findings, never fixes them. Use this skill when the user says "review this", "check my changes", "is this ready to merge" or any natural variant. Module 16 (Agentic Dev) — Product & Tech Delivery. Pre-Seed.
---

# Review

This skill is part of the **Founder OS** plugin, Module 16 — Agentic Dev (Product & Tech Delivery).

**Contract:** `.founder-os/contracts/qa-agent.md` — read it before you start.

> **You never review a diff you wrote, and you never fix what you find.** An agent that both
> produces and approves has no verification loop — it has a signature. If you wrote any part
> of this diff, decline and say so.

## When to trigger

Run this skill when the user says any of:

- "review this"
- "check my changes"
- "is this ready to merge"
- "review the PR"
- `founder-os:dev-review`

## Key instructions

**Scope:** $ARGUMENTS (default: diff against `main`)

Changed files: !`git diff --name-only origin/main...HEAD 2>/dev/null | head -40`
Size: !`git diff --shortstat origin/main...HEAD 2>/dev/null`

---

### 1. Load the yardstick

Read the linked spec under `docs/specs/`. The acceptance criteria are the standard.
**No spec and no stated goal → stop and ask what the change is meant to achieve.** No
yardstick, no review.

### 2. Delegate, do not read it all yourself

Start the `reviewer` subagent with the diff and the acceptance criteria. It runs in its own
context and returns only the verdict. If the diff touches auth, data access, CI, or
dependencies, also start `security-auditor`.

If subagents are unavailable, work the checklist yourself.

### 3. Run the verification chain

Do not take "tests pass" on trust. Run lint, typecheck, test, build yourself and report what
actually happened, including what you could **not** run.

### 4. Checklist — in this order

**Brief every delegated reviewer to refute, not confirm.** For any guard or defence in
the diff the instruction is: *construct a concrete input or state that gets past it; if
you cannot, say how hard you tried.* A read-through that "looks solid" is not evidence —
a failed construction attempt is, and the attempt regularly finds unrelated bugs on the
way.

1. **Does the diff meet the acceptance criteria?** Each individually. Unmet criteria are the
   most important finding.
2. **Correctness.** Off-by-one, null/undefined paths, race conditions, unhandled errors,
   timezones, number formats, encoding.
3. **Edge cases** from the spec plus the obvious ones: empty input, very large input,
   concurrency, network failure, partial failure.
4. **Security.** Injection, missing authorisation check, secrets in code, unsafe defaults,
   unvalidated input reaching a dangerous sink.
5. **Test integrity.** Were tests deleted, skipped, or weakened to go green? Always a finding.
6. **Suppressed errors.** Empty `catch`, `# type: ignore`, `any`, `@ts-expect-error`,
   disabled lint rules — each needs an inline justification.
7. **Missing verification.** New logic without a test at the right level.
8. **Scope.** Is the diff much larger than the spec describes? That is BLOCKED: scope creep.

### 5. Calibration — the part that matters most

Report **only** findings affecting correctness or the stated requirements. Style opinions,
naming taste, "you could also do it this way", and theoretical future problems are **not**
findings.

A reviewer sent to look for gaps will find gaps, even when the work is correct. False
findings cost more than missed style issues, because they push the team into
over-engineering. **When unsure: leave it out.**

Every blocking finding needs a **concrete failure case** — which input or state produces which
wrong behaviour. Without that it is a guess, and it belongs under NOTES.

## Output

```
| Check     | Command            | Result | Detail |
|-----------|--------------------|--------|--------|
| Lint      | npm run lint       | GREEN  | —      |
| ...
OVERALL:     GREEN | RED
NOT CHECKED: <what could not be verified, and why>

VERDICT: PASS | PASS WITH NOTES | BLOCKED

BLOCKING
  <file:line> — <what is wrong>
                Failure case: <input/state → wrong behaviour>
                Fix: <concrete>

NOTES (non-blocking)
  <file:line> — <observation>

CHECKED
  <One sentence: what you looked at, what you could not check and why.>
```

**NOT CHECKED and CHECKED are mandatory.** An unmentioned gap is worse than a named one.
A clean PASS with clear depth is a valuable result — do not manufacture findings to look
useful.
