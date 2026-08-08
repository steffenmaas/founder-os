#!/usr/bin/env bash
# Founder OS Module 16 - PostToolUse scan after every Edit/Write.
#
# Warns (does not block) when a just-written file looks like it contains a secret.
# Deliberately only a warning: false positives must not halt work;
# the hard control sits in CI (gitleaks) and in GitHub push protection.

set -uo pipefail

INPUT=$(cat)

if command -v jq >/dev/null 2>&1; then
  FILE=$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null)
else
  FILE=$(printf '%s' "$INPUT" | sed -n 's/.*"file_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
fi

[ -z "${FILE:-}" ] || [ ! -f "$FILE" ] && exit 0

case "$FILE" in
  *.env.example|*/node_modules/*|*/.git/*|*.lock|*.min.js) exit 0 ;;
esac

PATTERNS='(AKIA[0-9A-Z]{16})|(sk-[A-Za-z0-9]{20,})|(ghp_[A-Za-z0-9]{30,})|(github_pat_[A-Za-z0-9_]{50,})|(xox[baprs]-[A-Za-z0-9-]{10,})|(-----BEGIN [A-Z ]*PRIVATE KEY-----)|((api[_-]?key|secret|password|passwd|token)[[:space:]]*[:=][[:space:]]*.[A-Za-z0-9/+_-]{16,})'

if grep -EIn --color=never "$PATTERNS" "$FILE" >/dev/null 2>&1; then
  {
    echo "WARNING (Agentic Dev): '$FILE' contains a pattern that looks like a secret."
    echo "Blueprint 8.2: no secrets in code, commits, logs or test data - not even temporarily."
    echo "If it is a placeholder, make that visible in the name (e.g. EXAMPLE_KEY, <your-key>)."
    echo "Lines:"
    grep -EIn --color=never "$PATTERNS" "$FILE" 2>/dev/null | head -5 | cut -c1-160
  } >&2
fi

exit 0
