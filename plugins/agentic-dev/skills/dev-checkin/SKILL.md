---
name: dev-checkin
description: Produces the Agentic Dev check-in — what was built, how it was verified, what is open, blockers, roadmap drift, quality signals and decisions needed from the human. Use this skill when the user says "check-in", "status", "what happened today", "weekly review" or any natural variant. Module 16 (Agentic Dev) — Product & Tech Delivery. Pre-Seed.
---

# Check-in

This skill is part of the **Founder OS** plugin, Module 16 — Agentic Dev (Product & Tech Delivery).

## When to trigger

Run this skill when the user says any of:

- "check-in"
- "status" / "where are we"
- "what happened today"
- "weekly review"
- `founder-os:dev-checkin`

## Key instructions

**Mode:** $ARGUMENTS (default: daily)

- Commits (7d): !`git log --since="7 days ago" --pretty=format:"%h %ad %an %s" --date=short --no-merges 2>/dev/null | head -60`
- Diffstat: !`git diff --shortstat "@{7 days ago}" HEAD 2>/dev/null`
- Working tree: !`git status --short 2>/dev/null | head -20`
- Branches: !`git branch -a --sort=-committerdate 2>/dev/null | head -12`
- Previous check-ins: !`ls docs/checkins/ 2>/dev/null | tail -5`
- Product: !`head -3 PRODUCT.md 2>/dev/null`

## Additionally gather

1. CI status on `main` and open PRs (GitHub MCP or `gh`, if available).
2. `ROADMAP.md` — does *Now* match what actually happened?
3. `PRODUCT.md` — is the current version's scope closer to complete? Say by how much.
4. Unsubmitted upstream learnings:
   `grep -rl 'scope: upstream' docs/learnings/ | xargs grep -L 'submitted:'`
5. **Weekly mode only:** run
   `python3 ${CLAUDE_PLUGIN_ROOT}/tools/repo_metrics.py . --since "<4 weeks ago>"`
   and compare against the previous week.

## Output

**Lead with the founder-facing block** — four lines, nothing below the surface
(`contracts/orchestrator-agent.md` → Reporting). This is what gets read; the detail below
it is the record, not the message:

```
DONE:      <what a user can now do that they could not before>
IN FLIGHT: <current bundle, how far>
DECISIONS: <needing the founder — PRODUCT (what/for whom) and TECHNICAL (only when
            architectural or costly), each with options and your recommendation.
            "none" is a valid and good answer.>
PROGRESS:  <version scope: x of y · delivery pace · first-pass quality>
```

Never explain package internals, settings, or which line changed. If they want that, they
open the diff.

Then write the full record to `docs/checkins/YYYY-MM-DD.md` **and** print it below.
That path is canonical — one file per day, nowhere else. If the project carries a
root-level status file instead (`docs/autonomous-checkin.md` or similar), fold its
content into today's file and delete it: two status locations means neither is trusted,
and the human checks the empty one.

A check-in records work; it does not replace it. In the autonomous loop this skill runs
at the **end** of a cycle — a tick whose only output is a check-in is a failed tick
(`workflows/autonomous-loop.md`, "A tick is a work unit").

```markdown
# Check-in <date>

## Built
<What got finished, with commit hashes. Grouped by roadmap item.>

## Verified
<Which checks ran, with which result. And what was NOT verified.>

## Open
<Started but not finished. Why.>

## Blocked
<What is holding progress up. If nothing: write exactly that.>

## Version progress
<Current version, which scope items closed, how many remain.>

## Roadmap drift
<Was work done that was not in Now? Why? Should Now be adjusted?>

## Quality signals
<Red CI runs, skipped tests, rework hotspots, open Dependabot PRs,
 security findings, feature flags older than 90 days.>

## Learnings
<Written this period. How many are scope: upstream and not yet submitted.>

## Decisions needed from a human
<Concrete questions with options and your recommendation. If none: write exactly that.>
```

## Tone

Sober and short. No success claims without evidence. If something was not verified, that is
stated explicitly — an unmentioned gap is worse than a named one.
