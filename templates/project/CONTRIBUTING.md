# Contributing

## Flow

1. The work exists in `ROADMAP.md` under *Now*, and traces to `PRODUCT.md`.
2. Anything over ~30 minutes gets a spec: `docs/specs/<slug>.md` (template: `_template.md`).
3. Branch from `main`, short-lived (max 1 day). Naming: `<type>/<short-slug>`.
4. Small commits, Conventional Commits.
5. Open PR → CI green → preview looked at → review passed → squash merge.

## Commit format

```
<type>(<scope>): <imperative, lowercase, no full stop>

<Why this change — the diff shows the what.>

Refs: docs/specs/<slug>.md
```

Types: `feat` `fix` `refactor` `test` `docs` `chore` `perf` `build` `ci` `revert` `hotfix`

These are not cosmetics: the metrics tooling derives change failure rate and rework rate from
the commit types. Wrong types corrupt the numbers the team steers by.

## Definition of done

- [ ] Acceptance criteria met and each one demonstrated
- [ ] Tests added, all green
- [ ] Lint + typecheck + build green
- [ ] Review with fresh context, no open correctness findings
- [ ] Preview deployment looked at
- [ ] Docs updated (README / ADR / API)
- [ ] `ROADMAP.md` updated
- [ ] Rollback plan named in the PR
- [ ] Learning written if anything was surprising

## For agents

Read `.founder-os/blueprint.md`, then your contract in `.founder-os/contracts/`, then the
matching workflow in `.founder-os/workflows/`. Dev and QA are separate contracts — you do not
review or merge your own work.
