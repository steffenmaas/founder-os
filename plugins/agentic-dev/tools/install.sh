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
MIRROR=1          # copy agents/skills/hooks into .claude/ — see section 1b
while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run)           MODE="dry" ;;
    --update)            MODE="update" ;;
    --no-claude-assets)  MIRROR=0 ;;
    *) echo "unknown option: $1" >&2; exit 2 ;;
  esac
  shift
done

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

## The runtime is in \`.claude/\`, and it is managed too

The subagents, the \`dev-*\` skills and the hook scripts are plugin-native, but they are
**mirrored into \`.claude/\`** so they work where no plugin is installed — cloud sessions, CI
jobs, scheduled runs. Those get a fresh container, and plugin install state is machine-level
(\`~/.claude/plugins/\`), so it starts empty. Declaring a marketplace in
\`.claude/settings.json\` does not fetch one.

Without that mirror the failure is silent and severe: the loop is told to dispatch to
\`builder\`, there is no \`builder\`, so it writes the code itself and reviews its own diff —
exactly what the separated contracts exist to prevent. Nothing reports a fault.

- \`.claude/agents/\`, \`.claude/skills/dev-*/\`, \`.claude/hooks/\` — **managed**, replaced on
  every update, listed in \`.claude/.founder-os-manifest\`. Do not edit them here.
- Your own project skills and agents under \`.claude/\` are untouched: only paths in that
  manifest are ever removed.
- \`.claude/settings.json\` is **merged**, not overwritten — existing keys are preserved.
- **Commit \`.claude/\`.** It is what carries the runtime into an environment that cannot
  install anything.

\`install.sh --no-claude-assets\` skips the mirror, for a machine where the plugin is
properly installed and you would rather not have both.

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

# --------------------------------------------------------------------------- #
# 1b. Plugin-native assets, mirrored into .claude/
# --------------------------------------------------------------------------- #
# Subagents, skills and hooks normally come from the loaded plugin. That works on
# a machine where someone ran `/plugin install` — and nowhere else. Plugin install
# state is machine-level (`~/.claude/plugins/`), so a cloud session, a CI job or a
# scheduled run starts with an empty one. A committed `.claude/settings.json`
# declares a marketplace; it does not fetch one. Measured on a live cloud
# container: no `~/.claude/plugins/` directory at all.
#
# The failure that causes is silent and severe: `autonomous-loop.md` tells the
# orchestrator to dispatch to `builder`, there is no `builder`, so the orchestrator
# writes the code itself and reviews its own diff — the one thing the separated
# contracts exist to prevent. Nothing reports a fault; the loop looks healthy.
#
# So the assets are mirrored into the project, where they load with no marketplace
# and no fetch. This is on by default: a duplicate agent name on a machine that
# also has the plugin is visible and harmless, while a missing `builder` is neither.
# `--no-claude-assets` skips it.
# The manifest lives under .claude/, NOT under .founder-os/: section 1 wipes that
# directory on every run, which would destroy the record of what to clean up before
# this section could read it. A renamed asset then lingers forever.
MANIFEST=".claude/.founder-os-manifest"

if [ "$MIRROR" = "1" ]; then
  head_ "1b. Subagents, skills and hooks → .claude/"

  # Remove what a previous run owned, so a renamed or deleted asset does not
  # linger. Only paths in the manifest — never a blanket rm on .claude/, which
  # would take the project's own skills with it.
  if [ "$MODE" != "dry" ] && [ -f "$MANIFEST" ]; then
    while IFS= read -r old; do
      case "$old" in .claude/*) [ -n "$old" ] && rm -f "$old" ;; esac
    done < "$MANIFEST"
    find .claude/agents .claude/skills .claude/hooks -type d -empty -delete 2>/dev/null || true
  fi

  NEW_MANIFEST=""
  mirror() { # $1 = source file, $2 = destination
    NEW_MANIFEST="${NEW_MANIFEST}$2"$'\n'
    [ "$MODE" = "dry" ] && return 0
    mkdir -p "$(dirname "$2")"
    cp "$1" "$2"
  }

  N_AGENTS=0
  for f in "$ROOT"/agents/*.md; do
    [ -e "$f" ] || continue
    mirror "$f" ".claude/agents/$(basename "$f")"
    N_AGENTS=$((N_AGENTS + 1))
  done

  N_SKILLS=0
  for d in "$ROOT"/skills/*/; do
    [ -f "$d/SKILL.md" ] || continue
    mirror "$d/SKILL.md" ".claude/skills/$(basename "$d")/SKILL.md"
    N_SKILLS=$((N_SKILLS + 1))
  done

  N_HOOKS=0
  for f in "$ROOT"/hooks/scripts/*.sh; do
    [ -e "$f" ] || continue
    mirror "$f" ".claude/hooks/$(basename "$f")"
    [ "$MODE" != "dry" ] && chmod +x ".claude/hooks/$(basename "$f")"
    N_HOOKS=$((N_HOOKS + 1))
  done

  say "$N_AGENTS subagents, $N_SKILLS skills, $N_HOOKS hook scripts"

  # The hooks still need wiring. Merge into .claude/settings.json rather than
  # writing it: that file usually already carries extraKnownMarketplaces and
  # enabledPlugins, and overwriting it would silently undo the cloud setup.
  if [ "$MODE" != "dry" ]; then
    mkdir -p .claude
    python3 - <<'PY'
import json, os

path = ".claude/settings.json"
try:
    with open(path) as fh:
        settings = json.load(fh)
except (FileNotFoundError, json.JSONDecodeError):
    settings = {}

d = "$CLAUDE_PROJECT_DIR/.claude/hooks"
managed = {
    "PreToolUse": ("Bash", f"{d}/guard-bash.sh"),
    "PostToolUse": ("Edit|Write", f"{d}/scan-secrets.sh"),
}

hooks = settings.setdefault("hooks", {})
for event, (matcher, command) in managed.items():
    entries = hooks.setdefault(event, [])
    # Idempotent: replace our entry, leave the project's own hooks alone.
    entries = [
        e for e in entries
        if not any(h.get("command", "").endswith(os.path.basename(command))
                   for h in e.get("hooks", []))
    ]
    entries.append({
        "matcher": matcher,
        "hooks": [{"type": "command", "command": command}],
    })
    hooks[event] = entries

with open(path, "w") as fh:
    json.dump(settings, fh, indent=2)
    fh.write("\n")
PY
    printf '%s' "$NEW_MANIFEST" > "$MANIFEST"
    say "hooks wired in .claude/settings.json (existing keys preserved)"
  fi
  say "managed — replaced on every update; do not edit under .claude/"
fi

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

  7. COMMIT `.claude/` — agents, skills, hooks and settings. That directory is what
     carries the runtime into cloud sessions, CI and scheduled runs, which cannot
     install a plugin. Leave it out and the loop there has no `builder`.

  8. LIVENESS — the one check that matters. Everything above verifies that files exist.
     None of it proves the loop can delegate, which is the whole point of the module:

       dispatch a one-line task to `builder` and confirm something comes back

     If `builder` is not there, the rulebook is installed and inert. That state looks
     completely healthy from the outside and stays that way until someone asks.
EOF
echo
