#!/usr/bin/env bash
# Founder OS Module 16 - regression test for the hook guards.
# Checks that forbidden commands are blocked and permitted ones pass through.
set -uo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GUARD="$DIR/hooks/scripts/guard-bash.sh"
SCAN="$DIR/hooks/scripts/scan-secrets.sh"
FAILED=0

check() { # $1 = expected exit code, $2 = command
  local want="$1" cmd="$2" got payload
  # Build JSON properly so quotes in the command do not corrupt the test
  payload=$(CMD="$cmd" python3 -c 'import json,os;print(json.dumps({"tool_input":{"command":os.environ["CMD"]}}))')
  printf '%s' "$payload" | "$GUARD" >/dev/null 2>&1
  got=$?
  if [ "$got" != "$want" ]; then
    echo "FAIL  expected $want, got $got  ::  $cmd"
    FAILED=1
  else
    echo "ok    [$got] $cmd"
  fi
}

echo "-- must block (exit 2) --"
check 2 'git push --force origin main'
check 2 'git push -f origin master'
check 2 'git commit --no-verify -m "x"'
check 2 'gh pr merge 12 --admin'
check 2 'git reset --hard origin/main'
check 2 'git clean -fdx'
check 2 'vercel deploy --prod'
check 2 'firebase hosting:channel:deploy live'
check 2 'psql $PRODUCTION_DATABASE_URL'
check 2 'cat .env'

echo
echo "-- must pass through (exit 0) --"
check 0 'npm test'
check 0 'git push origin feat/x'
check 0 'git push --force-with-lease origin feat/x'
check 0 'cat .env.example'
check 0 'rm -rf ./dist'
check 0 'git commit -m "feat(api): add booking endpoint"'

echo
echo "-- secret scan --"
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT
printf 'const k = "sk-abcdefghijklmnopqrstuvwxyz123456";\n' > "$TMP/leak.ts"
if F="$TMP/leak.ts" python3 -c 'import json,os;print(json.dumps({"tool_input":{"file_path":os.environ["F"]}}))' | "$SCAN" 2>&1 | grep -q WARNING; then
  echo "ok    secret detected"
else
  echo "FAIL  secret not detected"; FAILED=1
fi
printf 'const k = process.env.KEY;\n' > "$TMP/clean.ts"
if F="$TMP/clean.ts" python3 -c 'import json,os;print(json.dumps({"tool_input":{"file_path":os.environ["F"]}}))' | "$SCAN" 2>&1 | grep -q WARNING; then
  echo "FAIL  false positive on a clean file"; FAILED=1
else
  echo "ok    clean file, no warning"
fi

echo
[ "$FAILED" = 0 ] && echo "ALL HOOK TESTS PASSED" || echo "HOOK TESTS FAILED"
exit "$FAILED"
