# Workflow — New Feature

**Use when:** building something that does not exist yet.
**Entry:** `/dev-loop <what to build>`

---

| # | Who | What | Gate before the next step |
|---|---|---|---|
| 1 | Dev | **ORIENT** — read `PRODUCT.md`, `ROADMAP.md`, ADRs, relevant learnings. Check `git status` and CI on `main`. | CI on `main` is green. If red, that becomes the task. |
| 2 | Product | **SPEC** — interview the human on open questions (bundled), then write `docs/specs/<slug>.md`. | Human approved the spec. Non-goal section is non-empty. Acceptance criteria are executable. |
| 3 | Product | **PLAN** — ordered steps in the spec under `## Plan`, each independently committable, each with its own check. Name what will not be touched. | Human approved the plan. |
| 4 | Dev | **BUILD** — fresh session, spec as the only input. One commit per plan step, Conventional Commits. Test first where behaviour is clear. Unfinished work behind a feature flag. | Every plan step's check passed. Tree is green. |
| 5 | Dev | **VERIFY (self)** — lint, typecheck, test, build. Plus change-specific: screenshot for UI, real request for API, forward+backward migration for schema. | All green, output shown. |
| 6 | QA | **REVIEW** — fresh context, sees only the diff and the acceptance criteria. | Verdict PASS or PASS WITH NOTES. BLOCKED goes back to step 4. |
| 7 | Security | **SECURITY** — only if the diff touches auth, data access, CI, or dependencies. | No open Critical or High. |
| 8 | Dev | **PR** — template filled in, rollback section written. Wait for CI and the preview URL. | CI green, preview URL posted, preview looked at. |
| 9 | Release | **SHIP** — human-invoked. Merge, deploy, 10-minute health watch. | Health watch clean. |
| 10 | Dev | **LEARN** — update `ROADMAP.md`. ADR if a constraining decision was made. Learning if anything surprised you. | Status block emitted. |

---

## Skipping steps

**Steps 2 and 3 may be skipped** when the diff is describable in one sentence. Plan overhead
for a one-liner is pure waste, and a process that is obviously excessive stops being taken
seriously as a whole.

**No other step may be skipped.** In particular, step 6 is not optional because the change
looks small — small diffs are where unreviewed mistakes survive longest.

## Common failure

The most common way this workflow goes wrong is step 4 quietly widening past the spec. The
symptom is a diff much larger than the spec describes. The fix is step 6 reporting it as
BLOCKED: scope creep — which is why QA gets the spec, not just the diff.
