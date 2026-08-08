# Repository analysis — method

Baseline measurements of existing repositories. Every analysis answers the same six
questions, so that projects and points in time stay comparable.

## Procedure

```bash
git clone <repo> /tmp/analysis/<name>     # or: git -C <path> fetch --all
python3 tools/repo_metrics.py /tmp/analysis/*/ > docs/analysis/<date>-raw.txt
python3 tools/repo_metrics.py /tmp/analysis/*/ --json > docs/analysis/<date>.json
```

In Claude Code: `/dev-metrics /tmp/analysis/*`

**Make sure the clone is current.** A stale clone reports a stale state without saying so —
this has produced wrong conclusions before, which is why it is the first line here.

## The six questions

| # | Question | Derived from |
|---|---|---|
| 1 | **Cadence** — how fast was it built? | commits/week, active days, median gap, burst share |
| 2 | **Batch size** — in what portions? | lines per commit, share of commits over 500 lines |
| 3 | **Failure rate** — how often did things break? | share of `fix:`/`revert`/`hotfix`, `fix:` per `feat:` |
| 4 | **Rework** — how much was rewritten? | 14-day rework rate, hotspot files |
| 5 | **Verification** — was there a net? | test-to-code ratio, share of commits touching tests, CI workflows |
| 6 | **Maturity** — what structure existed? | CI, security files, `PRODUCT.md`, `CLAUDE.md`, `ROADMAP.md`, ADRs, releases |

## Interpretation rules

These apply to every analysis, so they are not reinvented per report:

- **Commit count is not a productivity measure.** It measures batch size. Many small commits
  are a good sign, not a lot of work.
- **Change failure rate is a proxy.** Estimated from commit patterns, not measured from
  incident data. Its value depends on commit discipline; the script states its own data
  quality. Below 30% conventional-commit share, read it as a trend, not a value.
- **A high burst share** (commits under 15 minutes apart) indicates agent sessions. Neither
  good nor bad — but it makes review more important, because there is less human pause
  between changes.
- **Missing structure is not an accusation.** Early projects have no CI because they had to
  move. What matters is the point at which its absence starts costing speed.
- **Compare like with like.** A two-week-old project against a two-year-old one produces
  numbers without meaning. Use `--since` for equal windows.

## Report format

```markdown
# Analysis <project> — <date>

## Numbers
<table from repo_metrics.py>

## What went well
<Concrete, tied to a number.>

## Where speed was lost
<Concrete, tied to a number. No speculation.>

## Actions
<At most five, prioritised. Each tied to a number in the report.>

## Not measurable
<What this analysis cannot see — real incidents, user satisfaction, work outside git.>
```

## Completed analyses

_None yet._

Pending: `yacht-empire`, `vitacoach`, `3d-boatshow`. In the session of 2026-08-07 the GitHub
access to those private repositories was blocked and the local clone was out of date, so the
analysis was deliberately not run rather than computed on a stale state.
