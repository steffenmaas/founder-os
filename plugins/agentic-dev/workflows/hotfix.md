# Workflow — Hotfix

**Use when:** production is broken **right now** and users are affected.
**Entry:** manual. Tell the human what you are doing before you start.

> This is the only workflow that compresses gates. It compresses them in a specific,
> deliberate way — and it pays the compression back in step 8, which is not optional.

---

| # | Who | What | Gate |
|---|---|---|---|
| 1 | Human | **DECIDE** — is a rollback faster than a fix? | **If yes: roll back. Stop here.** A rollback beats a fix in almost every case where it is available. |
| 2 | Dev | **CONTAIN** — feature flag off, traffic shifted, or revert of the offending commit. Stop the bleeding before diagnosing. | Users are no longer affected, or you have stated that containment is not possible. |
| 3 | Dev | **REPRODUCE** — minimal failing test. Yes, even now. It takes minutes and it is what makes step 4 verifiable. | Test fails. |
| 4 | Dev | **FIX** — smallest possible change. No refactoring, no cleanup, no adjacent improvements. | Failing test passes, full chain green. |
| 5 | QA | **REVIEW** — abbreviated: correctness and blast radius only. Skip style, skip completeness. | No correctness finding. |
| 6 | Release | **SHIP** — human-invoked, straight to production, watch continuously not for 10 minutes but until stable. | Health metrics back to baseline. |
| 7 | Human | **COMMUNICATE** — who was affected, for how long, what was done. | — |
| 8 | Dev | **POSTMORTEM** — within 24 hours. Blameless. Learning with `severity: high`. Plus: what gate would have caught this, and does it exist? | Learning written, gate proposal on `ROADMAP.md` or `scope: upstream`. |

---

## What is compressed, and what is not

**Compressed:** the spec (none), the plan (none), the review depth (correctness only), the
scope discussion (there is none — smallest possible change).

**Not compressed:** the reproducing test, the full verification chain, human invocation of the
deploy, and the postmortem.

Those four are what stop a hotfix from causing the next incident. Every one of them has been
skipped by someone under pressure, and every one of them has caused a second outage.

## The rule that matters most

**Step 1 exists because rolling back is usually right.** An agent under time pressure will
reach for a fix, because fixing feels like progress and rolling back feels like defeat. It is
not. Restore service first; be clever afterwards.

## Scope discipline

While in this workflow you fix **one thing**. Anything else you notice — however obviously
broken — goes on `ROADMAP.md`. A hotfix that touches five files is not a hotfix.
