# Workflow — Refactor

**Use when:** changing structure without changing behaviour.
**Entry:** `/dev-loop refactor <what>`

> The defining property of this workflow: **the test suite must pass unchanged.** That is
> not a convenience, it is the definition of refactoring. If tests need changing, you are not
> refactoring — you are changing behaviour, and that needs `new-feature.md` and a spec.

---

| # | Who | What | Gate |
|---|---|---|---|
| 1 | Dev | **JUSTIFY** — one paragraph: what is hard *today* because of the current structure, with a concrete example. | The justification names an actual friction, not an aesthetic preference. **No friction, no refactor.** |
| 2 | Dev | **BASELINE** — run the full suite, record the result. If coverage on the affected code is thin, **add tests first, in a separate commit**, before touching structure. | Suite green. Affected code has real coverage. |
| 3 | Product | **SCOPE** — write down which files are in scope and which are explicitly not. This is the whole spec for a refactor. | Human approved the scope. |
| 4 | Dev | **REFACTOR** — mechanical, small commits, suite green after every one. | **Test files unchanged.** Suite green at every commit. |
| 5 | Dev | **VERIFY** — full chain plus a behavioural spot check on the main path. For UI: screenshot comparison against before. | Identical behaviour demonstrated, not assumed. |
| 6 | QA | **REVIEW** — one question above all others: did behaviour change anywhere? | No behavioural difference found. |
| 7 | Release | **SHIP** — human-invoked. | Health watch clean. |
| 8 | Dev | **LEARN** — update `ROADMAP.md`. ADR if the new structure is now the pattern to follow. | Done. |

---

## Hard rules

1. **Test files are not touched.** If a test breaks, the refactor broke behaviour. Revert the
   step; do not adjust the test. This is the single check that makes a refactor safe, and
   adjusting the test destroys it.
2. **Add coverage before, not during.** Tests written during a refactor test the new
   structure, not the old behaviour — they cannot catch a regression they were written after.
3. **No behaviour changes ride along.** Not a bug fix, not a small improvement, not a
   "while I'm here". Those go on the roadmap.
4. **No refactor without stated friction.** "Cleaner" is not a reason. "Adding a new payment
   provider currently requires editing four files in three modules" is.

## Why agents get this wrong

Refactoring is the work agents most enjoy producing and are least equipped to justify. The
pattern is: an agent notices structure it would have built differently, and rebuilds it. The
result is a large diff, no behavioural change, real regression risk, and no benefit.

Step 1 exists to stop exactly that. If you cannot fill it in with a concrete example, the
refactor does not happen.
