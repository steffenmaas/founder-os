# Workflow — Bug Fix

**Use when:** something behaves incorrectly, but production is stable enough to go through
the normal path. If production is broken right now, use `hotfix.md` instead.
**Entry:** `/dev-loop fix <what is broken>`

---

| # | Who | What | Gate before the next step |
|---|---|---|---|
| 1 | Dev | **REPRODUCE** — write a failing test that demonstrates the bug. Not a description of it, a test. | The test fails, and it fails for the stated reason. |
| 2 | Dev | **ORIENT** — `git log` on the affected files. When did this last work? Which change introduced it? Check `docs/learnings/` for the same area. | You can name what changed, or state explicitly that you could not. |
| 3 | Dev | **DIAGNOSE** — find the root cause, not the symptom. Write it in one sentence. | The sentence explains *why* the failing test fails, not just *that* it does. |
| 4 | Dev | **FIX** — the smallest change that makes the failing test pass without weakening it. | Failing test now passes. **No other test changed.** |
| 5 | Dev | **VERIFY** — full chain. Then check whether the same root cause exists elsewhere in the codebase. | All green. Sibling occurrences either fixed or added to `ROADMAP.md` → *Later*. |
| 6 | QA | **REVIEW** — with the failing-test-turned-passing as the primary evidence. | PASS. Specifically: the test would still fail against the old code. |
| 7 | Dev | **PR** — rollback section. Reference the reproducing test explicitly. | CI green, preview looked at. |
| 8 | Release | **SHIP** — human-invoked. | Health watch clean. |
| 9 | Dev | **LEARN** — write a learning. **Every bug that reached production is a learning**, with `area:` set and a note on whether a gate should have caught it. | Learning written. |

---

## The non-negotiable part

**Step 1 comes first.** A fix without a reproducing test is a guess that happens to make the
symptom go away. You will not know whether it worked, and neither will the next agent when it
regresses.

**Step 4 changes no other test.** If the fix requires changing an existing test, one of two
things is true: the test encoded the bug, or your fix is wrong. Determine which, and say so
in the commit body. Do not do it silently.

## Root cause, not symptom

A fix is a symptom fix if it does any of these:

- catches and swallows the error
- adds a guard that hides the invalid state instead of preventing it
- special-cases the input that triggered the report
- retries until it works

Each of those is a violation of blueprint §12.2, regardless of whether the bug report closes.
