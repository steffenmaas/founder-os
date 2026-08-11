#!/usr/bin/env python3
"""
repo_metrics.py - development metrics from git history.

Computes DORA-adjacent proxy metrics and agent-specific quality indicators for one
or more local git repositories.

    python3 tools/repo_metrics.py ~/code/projekt-a ~/code/projekt-b
    python3 tools/repo_metrics.py . --json > metrics.json
    python3 tools/repo_metrics.py . --since 2026-01-01

IMPORTANT - how to read this
----------------------------
Change failure rate and rework rate here are ESTIMATES from commit history, not
measurements from incident data. Their value depends directly on commit discipline
(Conventional Commits). Without clean types the numbers are noise, so the script
reports its own data quality explicitly.
"""

from __future__ import annotations

import argparse
import json
import re
import statistics
import subprocess
import sys
from collections import Counter, defaultdict
from datetime import datetime, timedelta, timezone
from pathlib import Path

# --------------------------------------------------------------------------- #
# Konfiguration
# --------------------------------------------------------------------------- #

CONVENTIONAL = re.compile(
    r"^(?P<type>feat|fix|refactor|test|docs|chore|perf|build|ci|style|revert|hotfix)"
    r"(?:\((?P<scope>[^)]*)\))?(?P<breaking>!)?:\s+(?P<subject>.+)$",
    re.IGNORECASE,
)

# Commits that indicate a previous change failed
FAILURE_SIGNAL = re.compile(
    r"^(revert|hotfix|fix)\b|\brevert\b|\bhotfix\b|\brollback\b|\bregression\b",
    re.IGNORECASE,
)

# Files that are not production work (smoothed out of the churn view)
NOISE_PATHS = re.compile(
    r"(^|/)(package-lock\.json|yarn\.lock|pnpm-lock\.yaml|poetry\.lock|Cargo\.lock|"
    r"go\.sum|composer\.lock|\.min\.(js|css)|dist/|build/|vendor/|node_modules/)"
)

TEST_PATH = re.compile(
    r"(^|/)(tests?|__tests__|spec|e2e|cypress|playwright)/|"
    r"\.(test|spec)\.[jt]sx?$|_test\.(py|go|rb)$|(^|/)test_[^/]+\.py$",
    re.IGNORECASE,
)

CI_PATHS = [
    ".github/workflows",
    ".gitlab-ci.yml",
    ".circleci",
    "azure-pipelines.yml",
    "Jenkinsfile",
    ".travis.yml",
    "bitbucket-pipelines.yml",
]

SECURITY_FILES = ["SECURITY.md", ".github/dependabot.yml", ".github/dependabot.yaml"]

AGENT_FILES = [
    "CLAUDE.md",
    "AGENTS.md",
    ".claude",
    ".cursorrules",
    ".cursor/rules",
    ".github/copilot-instructions.md",
]

QUALITY_FILES = [
    "PRODUCT.md",
    "ROADMAP.md",
    "CONTRIBUTING.md",
    "CODEOWNERS",
    ".github/CODEOWNERS",
    "docs/decisions",
    "docs/adr",
    "docs/specs",
    "docs/learnings",
    "docs/checkins",
    ".founder-os",
]


# --------------------------------------------------------------------------- #
# Git helpers
# --------------------------------------------------------------------------- #

def git(repo: Path, *args: str) -> str:
    try:
        out = subprocess.run(
            ["git", "-C", str(repo), *args],
            capture_output=True,
            text=True,
            check=False,
            timeout=180,
        )
        return out.stdout
    except (subprocess.TimeoutExpired, OSError) as exc:  # pragma: no cover
        print(f"  ! git {' '.join(args)} failed: {exc}", file=sys.stderr)
        return ""


SEP = "\x1e"  # record separator
FIELD = "\x1f"  # field separator


def load_commits(repo: Path, since: str | None) -> list[dict]:
    """Read commit history including numstat."""
    # %b is multi-line, so it must be LAST and must be followed by a field separator.
    # With %b anywhere else, the record cannot be parsed by looking at its first line —
    # see the trailing FIELD below, which is what ends the body and begins the numstat.
    fmt = SEP + FIELD.join(["%H", "%an", "%aI", "%s", "%P", "%b"]) + FIELD
    args = ["log", "--no-merges", f"--pretty=format:{fmt}", "--numstat", "--date=iso-strict"]
    if since:
        args.append(f"--since={since}")
    raw = git(repo, *args)
    commits: list[dict] = []
    dropped: list[str] = []

    for chunk in raw.split(SEP):
        chunk = chunk.strip("\n")
        if not chunk:
            continue
        # Split on the field separator, never on a newline: the body legitimately
        # contains newlines, and the trailing FIELD emitted after %b is what separates
        # it from git's --numstat block. \x1f cannot occur in a commit message.
        parts = chunk.split(FIELD)
        if len(parts) < 7:
            dropped.append(chunk[:40])
            continue
        sha, author, date, subject, parents, body = parts[:6]
        stat_block = parts[6]
        try:
            ts = datetime.fromisoformat(date)
        except ValueError:
            continue

        files: list[tuple[str, int, int]] = []
        for line in stat_block.splitlines():
            cols = line.split("\t")
            if len(cols) != 3:
                continue
            add, dele, path = cols
            if add == "-" or dele == "-":  # binary
                continue
            try:
                files.append((path, int(add), int(dele)))
            except ValueError:
                continue

        commits.append(
            {
                "sha": sha,
                "author": author,
                "ts": ts,
                "subject": subject,
                "body": body,
                "parents": parents.split(),
                "files": files,
            }
        )

    # A parser that silently `continue`s past malformed input is a data filter, not error
    # handling: 98% loss and 0% loss look identical from the outside. Say so.
    if dropped:
        print(
            f"  ! {len(dropped)} of {len(dropped) + len(commits)} commits could not be "
            f"parsed and were skipped — the numbers below cover the rest.",
            file=sys.stderr,
        )
    return commits


def load_merges(repo: Path, since: str | None) -> list[dict]:
    args = ["log", "--merges", "--pretty=format:%H%x1f%aI%x1f%s"]
    if since:
        args.append(f"--since={since}")
    merges = []
    for line in git(repo, *args).splitlines():
        parts = line.split(FIELD)
        if len(parts) < 3:
            continue
        try:
            merges.append({"sha": parts[0], "ts": datetime.fromisoformat(parts[1]), "subject": parts[2]})
        except ValueError:
            continue
    return merges


def load_tags(repo: Path) -> list[dict]:
    raw = git(repo, "for-each-ref", "--sort=creatordate",
              "--format=%(refname:short)" + FIELD + "%(creatordate:iso-strict)", "refs/tags")
    tags = []
    for line in raw.splitlines():
        parts = line.split(FIELD)
        if len(parts) < 2:
            continue
        try:
            tags.append({"name": parts[0], "ts": datetime.fromisoformat(parts[1])})
        except ValueError:
            continue
    return tags


def path_exists_in_head(repo: Path, path: str) -> bool:
    out = git(repo, "ls-tree", "-r", "--name-only", "HEAD")
    if not out:
        return False
    return any(p == path or p.startswith(path.rstrip("/") + "/") for p in out.splitlines())


def head_file_list(repo: Path) -> list[str]:
    return [p for p in git(repo, "ls-tree", "-r", "--name-only", "HEAD").splitlines() if p]


# --------------------------------------------------------------------------- #
# Metrics
# --------------------------------------------------------------------------- #

def analyse(repo: Path, since: str | None) -> dict:
    name = repo.resolve().name
    commits = load_commits(repo, since)
    if not commits:
        return {"repo": name, "error": "no commits found (or not a git repository)"}

    commits.sort(key=lambda c: c["ts"])
    first, last = commits[0]["ts"], commits[-1]["ts"]
    span_days = max((last - first).days, 1)

    # --- Volume ------------------------------------------------------------
    total = len(commits)
    added = 0
    deleted = 0
    noise_added = 0
    for c in commits:
        for path, a, d in c["files"]:
            if NOISE_PATHS.search(path):
                noise_added += a
            else:
                added += a
                deleted += d

    authors = Counter(c["author"] for c in commits)

    # --- Cadence -----------------------------------------------------------
    per_day: Counter[str] = Counter(c["ts"].date().isoformat() for c in commits)
    active_days = len(per_day)
    per_week: Counter[str] = Counter(
        f"{c['ts'].isocalendar().year}-W{c['ts'].isocalendar().week:02d}" for c in commits
    )

    # Burst detection: share of commits landing < 15 min after the previous one
    gaps = [
        (commits[i]["ts"] - commits[i - 1]["ts"]).total_seconds()
        for i in range(1, len(commits))
    ]
    median_gap_min = round(statistics.median(gaps) / 60, 1) if gaps else 0.0
    burst_share = round(100 * sum(1 for g in gaps if g < 900) / len(gaps), 1) if gaps else 0.0

    # --- Commit quality ----------------------------------------------------
    conv = 0
    types: Counter[str] = Counter()
    has_body = 0
    subj_len: list[int] = []
    for c in commits:
        m = CONVENTIONAL.match(c["subject"])
        if m:
            conv += 1
            types[m.group("type").lower()] += 1
        if c["body"].strip():
            has_body += 1
        subj_len.append(len(c["subject"]))

    conv_share = round(100 * conv / total, 1)

    # --- Failure rate (proxy) ----------------------------------------------
    failure_commits = [c for c in commits if FAILURE_SIGNAL.search(c["subject"])]
    reverts = [c for c in commits if c["subject"].lower().startswith("revert")]
    fixes = [c for c in commits if re.match(r"^fix(\(|!|:)", c["subject"], re.I)]
    hotfixes = [c for c in commits if re.search(r"\bhotfix\b", c["subject"], re.I)]
    feats = [c for c in commits if re.match(r"^feat(\(|!|:)", c["subject"], re.I)]

    fix_ratio = round(100 * len(failure_commits) / total, 1)
    fix_per_feat = round(len(fixes) / len(feats), 2) if feats else None

    # --- Rework / churn ----------------------------------------------------
    # Share of files changed again within 14 days of a previous change
    touch: dict[str, list[datetime]] = defaultdict(list)
    for c in commits:
        for path, _, _ in c["files"]:
            if NOISE_PATHS.search(path):
                continue
            touch[path].append(c["ts"])

    quick_rework = 0
    total_touches = 0
    for path, stamps in touch.items():
        stamps.sort()
        total_touches += len(stamps)
        for i in range(1, len(stamps)):
            if (stamps[i] - stamps[i - 1]) <= timedelta(days=14):
                quick_rework += 1
    rework_rate = round(100 * quick_rework / total_touches, 1) if total_touches else 0.0

    hotspots = sorted(
        ((p, len(s)) for p, s in touch.items()), key=lambda x: -x[1]
    )[:12]

    # --- Tests -------------------------------------------------------------
    files_head = head_file_list(repo)
    test_files_head = [p for p in files_head if TEST_PATH.search(p)]
    code_files_head = [
        p for p in files_head
        if re.search(r"\.(ts|tsx|js|jsx|py|go|rb|rs|java|kt|php|cs|swift|vue|svelte)$", p)
        and not NOISE_PATHS.search(p)
    ]
    test_ratio = (
        round(100 * len(test_files_head) / len(code_files_head), 1) if code_files_head else 0.0
    )

    commits_touching_tests = sum(
        1 for c in commits if any(TEST_PATH.search(p) for p, _, _ in c["files"])
    )
    test_commit_share = round(100 * commits_touching_tests / total, 1)

    # --- Infrastructure / maturity -----------------------------------------
    def present(candidates: list[str]) -> list[str]:
        return [c for c in candidates if any(f == c or f.startswith(c.rstrip("/") + "/") for f in files_head)]

    ci_present = present(CI_PATHS)
    workflows = [f for f in files_head if f.startswith(".github/workflows/")]
    agent_present = present(AGENT_FILES)
    sec_present = present(SECURITY_FILES)
    qual_present = present(QUALITY_FILES)

    # --- Releases / deploy frequency ---------------------------------------
    tags = load_tags(repo)
    merges = load_merges(repo, since)
    tags_per_week = round(len(tags) / (span_days / 7), 2) if tags else 0.0
    merges_per_week = round(len(merges) / (span_days / 7), 2)

    # --- Assemble the result -----------------------------------------------
    return {
        "repo": name,
        "period": {
            "first_commit": first.date().isoformat(),
            "last_commit": last.date().isoformat(),
            "span_days": span_days,
            "active_days": active_days,
            "activity_density_pct": round(100 * active_days / span_days, 1),
        },
        "volume": {
            "commits": total,
            "commits_per_active_day": round(total / active_days, 1),
            "commits_per_week": round(total / (span_days / 7), 1),
            "lines_added": added,
            "lines_deleted": deleted,
            "lines_generated": noise_added,
            "authors": dict(authors.most_common()),
            "merge_commits": len(merges),
            "tags": len(tags),
        },
        "cadence": {
            "median_gap_min": median_gap_min,
            "burst_share_pct": burst_share,
            "top_weeks": dict(per_week.most_common(5)),
            "top_days": dict(per_day.most_common(5)),
        },
        "commit_quality": {
            "conventional_commits_pct": conv_share,
            "types": dict(types.most_common()),
            "with_body_pct": round(100 * has_body / total, 1),
            "median_subject_length": int(statistics.median(subj_len)) if subj_len else 0,
        },
        "failure_rate_proxy": {
            "failure_signal_commits": len(failure_commits),
            "failure_signal_share_pct": fix_ratio,
            "reverts": len(reverts),
            "hotfixes": len(hotfixes),
            "fix_commits": len(fixes),
            "feat_commits": len(feats),
            "fix_per_feat": fix_per_feat,
        },
        "rework": {
            "rework_rate_14d_pct": rework_rate,
            "hotspots": [{"file": p, "changes": n} for p, n in hotspots],
        },
        "tests": {
            "test_files_head": len(test_files_head),
            "code_files_head": len(code_files_head),
            "test_to_code_ratio_pct": test_ratio,
            "commits_touching_tests_pct": test_commit_share,
        },
        "infrastructure": {
            "ci": ci_present,
            "workflows": workflows,
            "agent_files": agent_present,
            "security": sec_present,
            "process_files": qual_present,
            "releases_per_week": tags_per_week,
            "merges_per_week": merges_per_week,
        },
        "data_quality": {
            "note": (
                "Change failure rate and rework rate are estimates from commit "
                "history, not incident measurements."
            ),
            "confidence": (
                "high" if conv_share >= 70 else "medium" if conv_share >= 30 else "low"
            ),
            "reason": f"{conv_share}% of commits follow Conventional Commits.",
        },
    }


# --------------------------------------------------------------------------- #
# Rendering
# --------------------------------------------------------------------------- #

def render(r: dict) -> str:
    if "error" in r:
        return f"\n### {r['repo']}\n\n  ERROR: {r['error']}\n"

    z, v, c, q, f, rw, te, inf = (
        r["period"], r["volume"], r["cadence"], r["commit_quality"],
        r["failure_rate_proxy"], r["rework"], r["tests"], r["infrastructure"],
    )
    lines = [
        f"\n{'=' * 70}",
        f"  {r['repo'].upper()}",
        f"{'=' * 70}",
        f"  Period          {z['first_commit']} -> {z['last_commit']}  "
        f"({z['span_days']} days, {z['active_days']} active = {z['activity_density_pct']}%)",
        "",
        "  CADENCE",
        f"    Commits                     {v['commits']}",
        f"    per week                    {v['commits_per_week']}",
        f"    per active day              {v['commits_per_active_day']}",
        f"    median gap                  {c['median_gap_min']} min",
        f"    burst share (<15 min)       {c['burst_share_pct']}%",
        f"    lines +{v['lines_added']} / -{v['lines_deleted']}"
        f"  (+{v['lines_generated']} generated)",
        f"    authors ({len(v['authors'])})"
        f"{' ' * max(1, 20 - len(str(len(v['authors']))))}"
        f"{', '.join(f'{a} ({n})' for a, n in list(v['authors'].items())[:6]) or '-'}"
        f"{' ...' if len(v['authors']) > 6 else ''}",
        "",
        "  COMMIT QUALITY",
        f"    conventional commits        {q['conventional_commits_pct']}%",
        f"    with body                   {q['with_body_pct']}%",
        f"    types                       {q['types'] or '-'}",
        "",
        "  FAILURE RATE (proxy)",
        f"    failure-signal commits      {f['failure_signal_commits']} ({f['failure_signal_share_pct']}%)",
        f"    of which reverts / hotfixes {f['reverts']} / {f['hotfixes']}",
        f"    fix: per feat:              {f['fix_per_feat'] if f['fix_per_feat'] is not None else '-'}",
        "",
        "  REWORK",
        f"    rework rate (14 days)       {rw['rework_rate_14d_pct']}%",
        "    hotspots:",
    ]
    for h in rw["hotspots"][:6]:
        lines.append(f"      {h['changes']:>4}x  {h['file']}")
    lines += [
        "",
        "  TESTS",
        f"    test files / code files     {te['test_files_head']} / {te['code_files_head']}"
        f"  ({te['test_to_code_ratio_pct']}%)",
        f"    commits touching tests      {te['commits_touching_tests_pct']}%",
        "",
        "  INFRASTRUCTURE",
        f"    CI                          {', '.join(inf['ci']) or 'NONE'}",
        f"    workflows                   {len(inf['workflows'])}",
        f"    agent files                 {', '.join(inf['agent_files']) or 'NONE'}",
        f"    security                    {', '.join(inf['security']) or 'NONE'}",
        f"    process files               {', '.join(inf['process_files']) or 'NONE'}",
        f"    releases/week               {inf['releases_per_week']}",
        "",
        f"  Confidence in the proxy metrics: {r['data_quality']['confidence'].upper()}"
        f" - {r['data_quality']['reason']}",
    ]
    return "\n".join(lines)


def main() -> int:
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("repos", nargs="+", type=Path, help="paths to local git repositories")
    p.add_argument("--since", help="only commits from this date (e.g. 2026-01-01)")
    p.add_argument("--json", action="store_true", help="emit JSON instead of a text report")
    args = p.parse_args()

    results = [analyse(repo, args.since) for repo in args.repos]

    if args.json:
        print(json.dumps(results, indent=2, ensure_ascii=False))
    else:
        for r in results:
            print(render(r))
        print()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
