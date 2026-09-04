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

### The headline numbers — DORA, adapted

The four DORA metrics are the score (founder decision, 2026-09-04). Two of them are
redefined here, deliberately, because the standard definitions measure pipeline friction a
merged-package loop does not have. Report all four first, always, and track them over
time — the point is the trend, not the absolute value.

| DORA | Here it means | Read it as |
|---|---|---|
| **D — Deployment frequency** | Deploys (shipped packages) per day — and the target is a **steady cadence, not a maximum**. Report the longest gap and whether the cadence is drifting; D drifts often, and the drift is the finding. | A loop that is healthy deploys with the regularity of a pulse; growing gaps mean it is standing still while looking busy. |
| **L — Lead time** | **From backlog intake to live deployment**: the item's arrival in the backlog store to the deploy of the package that closes it, median per package. *Not* commit-to-deploy — that is minutes here and measures nothing; the queue is where the time goes. | How long a user who reported something waits until it is live. |
| **C — Change failure rate** | Share of packages that needed a follow-up fix, revert, or hit a red pipeline after merge (the inverse of first-pass quality). Estimated from commit patterns — carry the data-quality caveat. | Whether the pace is real or borrowed from tomorrow. |
| **R — Time to restore** | From the ops-watch issue opening on an incident to its close-on-recovery (`ops-watch.md` closes the issue itself when the check is green again). | How long production stays broken when it breaks. |

**D and C are a pair** — cadence without first-pass quality is not speed, it is debt. Never
report one alone.

**Guard against gaming.** D rises and L falls trivially if packages get smaller, so the
numbers are only honest while the sizing rule holds (`backlog.md`): one item = one change a
user could notice. Report the **median items per package** alongside D and L. If it falls
while they improve, say so plainly — that is measurement drift, not improvement.

Lines of code are not a metric here, in either direction.

### Output

Short report: the four DORA numbers with their trend, three sentences of assessment per
repository, then a table of the remaining numbers, then **at most five** concrete actions,
prioritised. **No action without a reference to a number in the report.**

Close by naming what these metrics cannot see: real incidents, user satisfaction, and work
that happened outside git.

## Retrospective mode — when the founder asks "what actually got done?"

Answer from git, never from memory: a measured retrospective in a production project took
under an hour and found what no one suspected — 62 % of all lines in three days went to
documentation and process rather than product; a 571-minute gap with no merge; the
top-priority workstream served on day one and never again; eight roadmap entries that did
not match the code, in both directions. Measure at least:

1. **Lines by destination** — product code vs. docs/process/infra, from `git log --numstat`
   classified by path. The product share is the headline number.
2. **Merge gaps** — the longest spans with no merge to `main`, and what the loop was doing
   during them.
3. **Top-priority coverage** — merges touching the roadmap's top package, per day.
4. **Roadmap vs. code** — does each open package still describe something the code lacks,
   and is nothing shipped still listed as open?

Report the four numbers first, findings after, feelings never.
