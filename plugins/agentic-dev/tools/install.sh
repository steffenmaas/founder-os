#!/usr/bin/env bash
#
# Founder OS · Module 16 — install into a project
#
# Copies the managed rulebook (blueprint, harness, contracts, workflows, tools) into
# .founder-os/ and creates any missing project files from the templates.
#
# You do not normally run this by hand — `/dev-onboard` calls it. Run it directly only
# when you are not using Claude Code.
#
#   bash install.sh                 install or update
#   bash install.sh --dry-run       show what would happen
#   bash install.sh --update        only refresh .founder-os/, touch nothing else
#
# NEVER edit .founder-os/ in a project. It is replaced on every update, and CI blocks
# PRs that change it. Rule changes travel upstream — see blueprint §9.3.

set -euo pipefail

MODE="install"
case "${1:-}" in
  --dry-run) MODE="dry" ;;
  --update)  MODE="update" ;;
  "")        ;;
  *) echo "unknown option: $1" >&2; exit 2 ;;
esac

# Plugin root: set by Claude Code, otherwise inferred from this script's location.
ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
TARGET="${FOUNDER_OS_TARGET:-$PWD}"

say()  { printf '  %s\n' "$*"; }
head_() { printf '\n\033[1m%s\033[0m\n' "$*"; }
warn() { printf '  ! %s\n' "$*" >&2; }

cd "$TARGET"
[ -d .git ] || { warn "Not a git repository: $(pwd)"; exit 1; }
[ -d "$ROOT/knowledge" ] || { warn "Cannot find the module at $ROOT"; exit 1; }

VERSION=$(python3 -c "import json;print(json.load(open('$ROOT/.claude-plugin/plugin.json'))['version'])" 2>/dev/null || echo "unknown")

head_ "Founder OS · Module 16 — Agentic Dev  (v$VERSION)"
say "target: $(pwd)"
[ "$MODE" = "dry" ] && say "(dry run — nothing will be written)"

# --------------------------------------------------------------------------- #
# 1. The managed directory — fully replaced every time
# --------------------------------------------------------------------------- #
head_ "1. Managed rulebook → .founder-os/"

if [ "$MODE" != "dry" ]; then
  rm -rf .founder-os
  mkdir -p .founder-os/tools
  cp    "$ROOT/knowledge/blueprint.md"    .founder-os/
  cp    "$ROOT/knowledge/harness.md"      .founder-os/
  cp    "$ROOT/knowledge/deploy-gate.md"  .founder-os/
  cp    "$ROOT/knowledge/backlog.md"      .founder-os/
  cp -r "$ROOT/knowledge/contracts"       .founder-os/
  cp -r "$ROOT/workflows"                 .founder-os/
  cp -r "$ROOT/stacks"                    .founder-os/
  cp    "$ROOT/tools/repo_metrics.py"   .founder-os/tools/
  cp    "$ROOT/tools/install.sh"        .founder-os/tools/
  printf '%s\n' "$VERSION" > .founder-os/VERSION
  cat > .founder-os/README.md <<EOF
# Managed — do not edit

This directory is written by Founder OS Module 16 and is **replaced on every update**.
Editing it here has no effect: your change is overwritten, and CI blocks PRs that touch it.

Version: $VERSION

## Contents

- \`blueprint.md\`   — the binding rulebook
- \`harness.md\`     — how to decide when the rules run out
- \`deploy-gate.md\` — auto-ship or human approval
- \`backlog.md\`     — the live-backlog doctrine
- \`contracts/\`     — one contract per agent role
- \`workflows/\`     — the named sequence for each kind of work
- \`stacks/\`        — stack blueprints: building blocks, keyless deploy, known failures
- \`tools/\`         — metrics and installer

## What is deliberately NOT here

The subagents (\`builder\`, \`verifier\`, \`reviewer\`, \`planner\`, \`security-auditor\`), the
\`dev-*\` skills and the hooks are **plugin-native** and are not copied into a project. They
come from the loaded plugin.

**Without the plugin loaded, this project can read the rules but cannot delegate.** The loop
would then write its own code and review its own diff — the thing the separated contracts
exist to prevent.

Confirm before trusting the loop — and note that the check differs by environment: in a
terminal, \`/plugin list\`; in the Claude Code app, the Plugins screen; in a cloud or CI
session, neither exists, so dispatch a one-line task to \`builder\` and see whether anything
comes back. Plugin install state is machine-level (\`~/.claude/plugins/\`), so in ephemeral
containers it does not survive to the next session at all.

## To change a rule

Write a learning with \`scope: upstream\` in \`docs/learnings/\`, then run
\`/dev-learn --upstream\`. It opens a PR against the Founder OS repository. Once merged,
\`/plugin update\` carries it to every project.

## To update

\`\`\`
/plugin update            # in Claude Code
bash .founder-os/tools/install.sh --update   # without Claude Code
\`\`\`
EOF
fi

say "blueprint.md, harness.md, deploy-gate.md, backlog.md, contracts/ (6), workflows/ (9), stacks/, tools/"
[ "$MODE" = "update" ] && { head_ "Updated to v$VERSION. Project files untouched."; exit 0; }

# --------------------------------------------------------------------------- #
# 2. Project files — created only when absent, never overwritten
# --------------------------------------------------------------------------- #
head_ "2. Project files"
CREATED=(); SAME=(); CONFLICT=()

copy_if_absent() { # $1 = path under templates/project, $2 = destination
  local src="$ROOT/templates/project/$1" dst="$2"
  [ -f "$src" ] || return 0
  if [ -e "$dst" ]; then
    if cmp -s "$src" "$dst"; then SAME+=("$dst"); else CONFLICT+=("$1|$dst"); fi
    return 0
  fi
  if [ "$MODE" != "dry" ]; then mkdir -p "$(dirname "$dst")"; cp "$src" "$dst"; fi
  CREATED+=("$dst")
}

copy_if_absent PRODUCT.md                       PRODUCT.md
copy_if_absent ROADMAP.md                       ROADMAP.md
copy_if_absent CLAUDE.md                        CLAUDE.md
copy_if_absent AGENTS.md                        AGENTS.md
copy_if_absent CONTRIBUTING.md                  CONTRIBUTING.md
copy_if_absent SECURITY.md                      SECURITY.md
copy_if_absent docs/specs/_template.md          docs/specs/_template.md
copy_if_absent docs/decisions/0000-template.md  docs/decisions/0000-template.md
copy_if_absent docs/learnings/_template.md      docs/learnings/_template.md
copy_if_absent docs/personas/_template.md       docs/personas/_template.md
copy_if_absent .claude/settings.json            .claude/settings.json
copy_if_absent .github/dependabot.yml           .github/dependabot.yml
copy_if_absent .github/CODEOWNERS               .github/CODEOWNERS
copy_if_absent .github/PULL_REQUEST_TEMPLATE.md .github/PULL_REQUEST_TEMPLATE.md
for w in ci security preview deploy founder-os-update; do
  copy_if_absent ".github/workflows/$w.yml" ".github/workflows/$w.yml"
done

if [ "$MODE" != "dry" ]; then
  mkdir -p docs/checkins docs/specs docs/decisions docs/learnings
  for d in checkins specs decisions learnings; do
    [ -e "docs/$d/.gitkeep" ] || touch "docs/$d/.gitkeep"
  done
fi

for f in "${CREATED[@]:-}";  do [ -n "$f" ] && say "+ $f"; done
for f in "${SAME[@]:-}";     do [ -n "$f" ] && say "= $f (unchanged)"; done
for entry in "${CONFLICT[@]:-}"; do
  [ -z "$entry" ] && continue
  src="${entry%%|*}"; dst="${entry##*|}"
  warn "≠ $dst exists and differs — template placed alongside as $dst.founder-os-new"
  [ "$MODE" != "dry" ] && cp "$ROOT/templates/project/$src" "$dst.founder-os-new"
done

# --------------------------------------------------------------------------- #
# 3. .gitignore safety net
# --------------------------------------------------------------------------- #
head_ "3. .gitignore"
if [ "$MODE" != "dry" ]; then
  for pattern in ".env" ".env.*" "!.env.example" "*.pem" "*.key"; do
    grep -qxF "$pattern" .gitignore 2>/dev/null || echo "$pattern" >> .gitignore
  done
fi
say "credential patterns ensured"

# --------------------------------------------------------------------------- #
# 4. What you still have to do
# --------------------------------------------------------------------------- #
head_ "What you still have to do yourself"
cat <<'EOF'
  1. PRODUCT.md — fill it in. Version, target user, principles, non-goals, current scope.
     Everything else derives from this file. A placeholder here poisons the roadmap.

  2. CLAUDE.md — real commands instead of <PLACEHOLDERS>.
     A template full of placeholders is worse than no file: it produces agents that guess.

  3. Workflows — adjust package manager, test commands, and hosting provider in
     .github/workflows/preview.yml and deploy.yml.
     On a stack that already has a blueprint (see .founder-os/stacks/), do not write
     the deploy path by hand — `/dev-stack <name>` writes the keyless setup script,
     the deploy workflow and the deployment docs with this project's values.

  4. ROADMAP.md — seed from your backlog. Maximum 3 items under Now.

  5. GitHub repository settings (no repo content can enforce these):
     - Branch protection on main: PR required, status checks required, no force pushes
     - Secret scanning + push protection
     - Dependabot security updates
     - Actions default permission: read repository contents
     - Environments preview / staging / production, secrets bound to the right one

  6. Baseline:  python3 .founder-os/tools/repo_metrics.py .

  7. LIVENESS — the one check that matters. Everything above verifies that files exist.
     None of it proves the loop can delegate, which is the whole point of the module:

       /plugin list                  # agentic-dev@founder-os must be listed
       dispatch a one-line task to `builder` and confirm something comes back

     If `builder` is not there, the rulebook is installed and inert. That state looks
     completely healthy from the outside and stays that way until someone asks.
EOF
echo
