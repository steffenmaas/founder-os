# Founder OS — instructions for agents working on this repository

## Release policy — binding

**Version bumps are the founder's call, not a side effect of finishing work.**

| Bump | Example | Rule |
|---|---|---|
| Patch | `0.8.0` → `0.8.1` | Ship autonomously: commit, PR, merge, release. |
| Minor | `0.8.0` → `0.9.0` | **Ask the founder first**, with a one-line scope summary. Do not bump, merge, or release until they say so. |
| Major | `0.9.0` → `1.0.0` | Founder only. Never propose-and-proceed. |

Finished capability with no approval yet: merge it **without** touching the version, or
leave the PR open — the work is not lost, the release waits. Bumping the version in
`plugins/*/.claude-plugin/plugin.json` on `main` IS the release trigger
(`.github/workflows/release.yml`), so the version line is exactly where this policy bites.

Rationale and the full doctrine: `plugins/agentic-dev/workflows/version-cut.md`.

## Other standing rules

- This repository is **public**. No project ids, project numbers, service-account
  addresses, deployed hostnames, or private repository names — anywhere, including commit
  messages. `validate.py` guards file content; commit messages are on you.
- Never edit the other product repositories from a session working here. Findings travel
  as blueprint/doc changes in this repo; the projects adopt them themselves.
- Before any merge: `python3 plugins/agentic-dev/tools/validate.py` and
  `bash plugins/agentic-dev/tools/test_hooks.sh`, both green.
