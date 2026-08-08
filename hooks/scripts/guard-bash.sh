#!/usr/bin/env bash
# Founder OS Module 16 - PreToolUse guard for bash commands.
#
# Blocks the actions the blueprint defines as hard violations.
# Deterministic - not left to the model to comply.
#
# Input: JSON on stdin with .tool_input.command
# Exit 2 = block; stderr goes back to the model.

set -uo pipefail

INPUT=$(cat)

CMD=""
if command -v jq >/dev/null 2>&1; then
  CMD=$(printf '%s' "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null) || CMD=""
fi
# Fallback if jq is missing or the input does not parse cleanly: do not fail
# open - extract roughly and check anyway.
if [ -z "$CMD" ]; then
  CMD=$(printf '%s' "$INPUT" | sed -n 's/.*"command"[[:space:]]*:[[:space:]]*"\(.*\)"[[:space:]]*[,}].*/\1/p')
fi
[ -z "$CMD" ] && CMD="$INPUT"   # last resort: check the raw text

[ -z "${CMD:-}" ] && exit 0

deny() {
  echo "BLOCKED by the Agentic Dev blueprint: $1" >&2
  echo "Rule: $2" >&2
  echo "If this is genuinely necessary, the human runs it themselves." >&2
  exit 2
}

# --- Force push to protected branches -----------------------------------
if printf '%s' "$CMD" | grep -Eq 'git[[:space:]]+push\b.*(--force|[[:space:]]-f\b)'; then
  if ! printf '%s' "$CMD" | grep -q -- '--force-with-lease'; then
    deny "git push --force" "Only --force-with-lease, and never on main. (blueprint 8.2)"
  fi
  if printf '%s' "$CMD" | grep -Eq '(origin[[:space:]]+)?(main|master|production)\b'; then
    deny "force push to a protected branch" "Never force-push to main. (blueprint 8.2)"
  fi
fi

# --- Bypassing hooks / branch protection --------------------------------
printf '%s' "$CMD" | grep -Eq 'git[[:space:]]+(commit|push|merge)\b.*--no-verify' \
  && deny "--no-verify" "Pre-commit hooks are not bypassed. (blueprint 6.2)"

printf '%s' "$CMD" | grep -Eq 'gh[[:space:]]+pr[[:space:]]+merge\b.*--admin' \
  && deny "gh pr merge --admin" "Branch protection is not bypassed. (blueprint 8.2)"

# --- Destructive git operations -----------------------------------------
printf '%s' "$CMD" | grep -Eq 'git[[:space:]]+reset[[:space:]]+--hard[[:space:]]+(origin/)?(main|master)\b' \
  && deny "git reset --hard on main" "Destroys local work irreversibly."

printf '%s' "$CMD" | grep -Eq 'git[[:space:]]+clean\b.*-[a-zA-Z]*[fx]' \
  && printf '%s' "$CMD" | grep -Eq '\-[a-zA-Z]*d' \
  && deny "git clean -fdx" "Irreversibly deletes untracked files including .env."

# --- Recursive deletion in dangerous places -----------------------------
printf '%s' "$CMD" | grep -Eq 'rm[[:space:]]+(-[a-zA-Z]*[[:space:]]+)*-?[a-zA-Z]*r[a-zA-Z]*f?[[:space:]]+(/|~|\$HOME|\.\.)' \
  && deny "rm -rf outside the project" "Delete only inside the working directory."

# --- Direct access to production data -----------------------------------
printf '%s' "$CMD" | grep -Eqi '(psql|mysql|mongo|redis-cli)\b.*(prod|production)' \
  && deny "direct connection to a production database" \
          "Production data only through migrations in the repo. (blueprint 8.4)"

# --- Deploying from a local machine -------------------------------------
printf '%s' "$CMD" | grep -Eq '(vercel|netlify|wrangler|firebase|flyctl|fly)\b.*(--prod|deploy[[:space:]]+--prod|hosting:channel:deploy[[:space:]]+live)' \
  && deny "deploying from a local machine" \
          "Deployment runs only through the pipeline. (blueprint 3.6)"

# --- Printing secrets ----------------------------------------------------
printf '%s' "$CMD" | grep -Eq '(cat|less|more|head|tail|bat)[[:space:]]+[^|]*\.env($|[[:space:]])' \
  && ! printf '%s' "$CMD" | grep -q '\.env\.example' \
  && deny "printing .env" "Secrets would land in the transcript. Use .env.example."

exit 0
