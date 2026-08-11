#!/usr/bin/env python3
"""
validate.py — self-check for the Agentic Dev module.

Checks JSON, YAML, skill/subagent front matter, shell syntax, internal links and
unreplaced placeholders. Runs identically locally and in CI.

    python3 tools/validate.py
"""

from __future__ import annotations

import json
import os
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SKIP_DIRS = {".git", "node_modules", "__pycache__", ".venv"}

# Templates deliberately contain <PLACEHOLDERS> and references to project files that
# do not exist yet — they are exempt from the link and placeholder checks.
LINK_SKIP_PREFIXES = ("templates/",)


def walk(*suffixes: str):
    for dirpath, dirnames, filenames in os.walk(ROOT):
        dirnames[:] = [d for d in dirnames if d not in SKIP_DIRS]
        for fn in filenames:
            if fn.endswith(suffixes):
                yield Path(dirpath) / fn


def rel(p: Path) -> str:
    return str(p.relative_to(ROOT))


def report(label: str, bad: list[str], count: int) -> bool:
    if bad:
        print(f"  {label}: FAILED")
        for b in bad:
            print(f"    - {b}")
        return True
    print(f"  {label}: {count} checked, ok")
    return False


def main() -> int:
    print(f"Validating {ROOT}  (Founder OS · Module 16 — Agentic Dev)\n")
    failed = False

    # --- JSON --------------------------------------------------------------
    files = list(walk(".json"))
    bad = []
    for f in files:
        try:
            json.loads(f.read_text())
        except Exception as e:
            bad.append(f"{rel(f)}: {e}")
    failed |= report("JSON", bad, len(files))

    # --- YAML --------------------------------------------------------------
    try:
        import yaml
    except ImportError:
        print("  YAML: skipped (pyyaml not installed)")
        yaml = None
    if yaml:
        files = list(walk(".yml", ".yaml"))
        bad = []
        for f in files:
            try:
                yaml.safe_load(f.read_text())
            except Exception as e:
                bad.append(f"{rel(f)}: {e}")
        failed |= report("YAML", bad, len(files))

    # --- Skill and subagent front matter -----------------------------------
    if yaml:
        files = sorted(
            list((ROOT / "skills").glob("*/SKILL.md"))
            + list((ROOT / "agents").glob("*.md"))
        )
        bad = []
        for f in files:
            text = f.read_text()
            if not text.startswith("---"):
                bad.append(f"{rel(f)}: no YAML front matter")
                continue
            try:
                data = yaml.safe_load(text.split("---", 2)[1]) or {}
            except Exception as e:
                bad.append(f"{rel(f)}: invalid front matter — {e}")
                continue
            for key in ("name", "description"):
                if not data.get(key):
                    bad.append(f"{rel(f)}: field '{key}' missing")
            desc = str(data.get("description", ""))
            if len(desc) < 40:
                bad.append(
                    f"{rel(f)}: description too short ({len(desc)} chars) — "
                    "it decides whether the skill is found"
                )
            if data.get("name") and f.name == "SKILL.md" and data["name"] != f.parent.name:
                bad.append(f"{rel(f)}: name '{data['name']}' != directory '{f.parent.name}'")
        failed |= report("Skills/subagents", bad, len(files))

    # --- Shell syntax ------------------------------------------------------
    files = list(walk(".sh"))
    bad = []
    for f in files:
        r = subprocess.run(["bash", "-n", str(f)], capture_output=True, text=True)
        if r.returncode != 0:
            bad.append(f"{rel(f)}: {r.stderr.strip()}")
    failed |= report("Shell syntax", bad, len(files))

    # --- Internal links ----------------------------------------------------
    files = list(walk(".md"))
    bad = []
    checked = 0
    for f in files:
        if rel(f).startswith(LINK_SKIP_PREFIXES):
            continue
        for _, link in re.findall(r"\[([^\]]+)\]\(([^)]+)\)", f.read_text()):
            if link.startswith(("http://", "https://", "#", "mailto:")):
                continue
            if "<" in link:  # placeholder inside an example
                continue
            checked += 1
            target = (f.parent / link.split("#")[0]).resolve()
            if not target.exists():
                bad.append(f"{rel(f)}: dead link -> {link}")
    failed |= report("Internal links", bad, checked)

    # --- Placeholders outside templates/ ----------------------------------
    bad = []
    for f in walk(".md"):
        r = rel(f)
        if r.startswith(LINK_SKIP_PREFIXES):
            continue
        for i, line in enumerate(f.read_text().splitlines(), 1):
            # Inside backticks a placeholder is a deliberately quoted example.
            stripped = re.sub(r"`[^`]*`", "", line)
            if re.search(r"<(PRODUCT NAME|PROJECT NAME|PLACEHOLDER|PLACEHOLDERS|TODO)>", stripped):
                bad.append(f"{r}:{i}: unreplaced placeholder")
    failed |= report("Placeholders", bad, 0)

    # --- Leaked identifiers ------------------------------------------------
    # This repository is public; the projects it was distilled from are not. A
    # concrete project number, service-account address or deployed hostname is
    # of no use to a reader and tells an attacker where to aim. Everything
    # project-specific must stay a placeholder (<…>) or a shell variable (${…}).
    #
    # This is a guard test, not documentation: the leak that matters is the one
    # nobody notices while copying a working file out of a real project.
    leaks = [
        (re.compile(r"\b\d{9,}\b"), "looks like a GCP project number"),
        (
            re.compile(r"[\w.%+-]+@[\w.-]*\.iam\.gserviceaccount\.com"),
            "concrete service-account address",
        ),
        (
            re.compile(r"\b[\w-]+\.(?:web\.app|firebaseapp\.com)\b"),
            "concrete deployed hostname",
        ),
    ]
    bad = []
    checked = 0
    for f in walk(".md", ".sh", ".yml", ".yaml", ".json", ".py"):
        if f.name == "validate.py":  # the patterns above live here
            continue
        checked += 1
        for i, line in enumerate(f.read_text().splitlines(), 1):
            # A placeholder or a shell/CI variable is the correct form — skip it.
            if "<" in line or "${" in line or "$(" in line:
                continue
            for pattern, why in leaks:
                m = pattern.search(line)
                if m:
                    bad.append(f"{rel(f)}:{i}: {why} — '{m.group(0)}'")
    failed |= report("Leaked identifiers", bad, checked)

    print("\n" + ("FAILED" if failed else "ALL GREEN"))
    return 1 if failed else 0


if __name__ == "__main__":
    raise SystemExit(main())
