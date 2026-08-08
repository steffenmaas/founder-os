---
name: dev-metrics
description: Measures development speed, failure rate and code quality from git history — commit cadence, batch size, change failure rate proxy, rework rate, test ratio, hotspots and infrastructure maturity. Use this skill when the user says "how fast are we shipping", "dev metrics", "code quality", "DORA" or any natural variant. Module 16 (Agentic Dev) — Product & Tech Delivery. Pre-Seed.
---

# Development metrics

This skill is part of the **Founder OS** plugin, Module 16 — Agentic Dev (Product & Tech Delivery).

## When to trigger

Run this skill when the user says any of:

- "how fast are we shipping"
- "dev metrics"
- "code quality"
- "DORA"
- "how is development going"
- `founder-os:dev-metrics`

## Key instructions

**Target:** $ARGUMENTS (default: current repository)

### Run

```bash
python3 ${CLAUDE_PLUGIN_ROOT}/tools/repo_metrics.py $ARGUMENTS
```

Add `--json` for machine-readable output, `--since YYYY-MM-DD` to window it.

**Make sure the clone is current first.** `git fetch --all`. A stale clone reports a stale
state without saying so.

### Interpretation — and its limits

Always say this when you report numbers:

- **Change failure rate and rework rate are estimates** from commit patterns (reverts,
  `fix:`, `hotfix:`), not incident measurements. Their value depends on commit discipline.
  The script states its own data quality — carry that statement into your report.
- **Commit count is not a productivity measure.** It measures batch size. Many small commits
  are a good sign, not a lot of work.
- **A high burst share** (commits under 15 minutes apart) indicates agent sessions. Neither
  good nor bad — but it makes review more important, because there is less human pause
  between changes.

### What to look for

| Pattern | Means |
|---|---|
| Rework rate rising at constant deploy frequency | Speed is an illusion; code is being rewritten, not finished |
| `fix:` per `feat:` above 1.0 | Features break more often than they get built |
| Test-to-code ratio under ~20% | Verification gap; agents working without a net |
| One file with very many changes | Refactoring candidate, or a missing abstraction |
| Few active days, high commits/day | Bursty work — risk of large unreviewed batches |
| No CI files, no security files | Infrastructure gap, highest priority |
| Conventional-commit share under 30% | Every other number here is a trend, not a value |

### Output

Short report: three sentences of assessment per repository, then a table of the numbers, then
**at most five** concrete actions, prioritised. **No action without a reference to a number
in the report.**

Close by naming what these metrics cannot see: real incidents, user satisfaction, and work
that happened outside git.
