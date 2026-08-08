---
date: 2026-08-08
scope: upstream
area: ci
severity: medium
submitted:
---

# The `security.yml` template ships two jobs that cannot pass on a private repo, and one of them fails silently open

## What happened

The very first PR through the freshly onboarded CI gate (PR #44, adoption day) went red on
two of the three security jobs — before a single line of project code was involved.

1. **`dependency review (PRs, all ecosystems)`** failed with
   `Dependency review is not supported on this repository. Please ensure that Dependency
   graph is enabled along with GitHub Advanced Security`.
2. **`secret scan (gitleaks)`** crashed with
   `Resource not accessible by integration … GET /repos/{owner}/{repo}/pulls/{n}/commits`,
   status 403, and never scanned anything.

The second one is the dangerous one: the job did not report "no leaks found", it *died* while
listing the PR's commits. A secret scan that crashes before scanning looks, from a distance,
much like a secret scan that passed.

Fixing them cost roughly 40 minutes on adoption day and required two extra pushes.

## Why it happened

**gitleaks:** `gitleaks/gitleaks-action@v2` calls the pull-request commits API to scope its
scan to the PR. The template sets `permissions: contents: read` at workflow level and grants
no `pull-requests: read` to that job, so the `GITHUB_TOKEN` is not allowed to make that call.
The template's own `dependency-review` job *does* declare `pull-requests: read` — so the
permission was known to be needed elsewhere in the same file, just not granted here.

**dependency-review:** `actions/dependency-review-action` requires the GitHub Dependency
graph, and on **private** repositories additionally GitHub Code Security (formerly Advanced
Security), which is a paid add-on. Neither is something a workflow file can switch on. The
template assumes a repository where those are available — true for public repos, false for
the typical pre-seed private repo this module targets.

Adding `continue-on-error: true` does **not** rescue this: it keeps the workflow run green
but the check run still reports `failure`, and a check that is permanently red trains
everyone to stop reading red checks.

## What we do differently now

In this project (`.github/workflows/security.yml`):

- `secrets` job now declares `permissions: { contents: read, pull-requests: read }`.
- The `dependency-review` job was **removed**, with its body preserved as a comment plus the
  settings URL and the conditions under which it can come back.
- Vulnerability scanning is instead done by **OSV-Scanner**, which needs no GitHub feature
  flag and — a genuine improvement over the template — also reads `app/pubspec.lock`, so the
  Flutter/Dart dependencies are covered. The template only ever audited the npm project.

## Generalisable?

Yes — every project adopting this module on a private repository hits both of these on its
first PR, which is precisely the PR meant to prove the pipeline works. First impressions of
the gate matter: a gate that is red for reasons unrelated to the code teaches people to
merge past red.

### Proposed change 1 — `templates/project/.github/workflows/security.yml`, `secrets` job

Grant the permission the action actually needs. Paste-ready:

```yaml
  secrets:
    name: secret scan (gitleaks)
    runs-on: ubuntu-latest
    # gitleaks-action lists a PR's commits to scope the scan; without
    # pull-requests: read it exits 403 *before scanning*, which reads as a pass.
    permissions:
      contents: read
      pull-requests: read
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
      - uses: gitleaks/gitleaks-action@v2
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

### Proposed change 2 — same file, replace `dependency-review` with OSV-Scanner

OSV-Scanner is the better default for this module's audience: it runs on any repository
regardless of plan or visibility, and it is multi-ecosystem, so it covers stacks the npm
audit job cannot see (pub, Cargo, Go, Maven …) instead of silently leaving them unscanned.

```yaml
  vulnerabilities:
    name: vulnerability scan (osv)
    runs-on: ubuntu-latest
    permissions:
      contents: read
    steps:
      - uses: actions/checkout@v4
      - uses: google/osv-scanner-action/osv-scanner-action@v2.2.4
        with:
          scan-args: |-
            --recursive
            ./
```

Keep `dependency-review` in the template only as a commented block with a one-line note that
it requires the Dependency graph, and Code Security on private repos.

### Level and why

**CI gate** (`templates/project/.github/workflows/security.yml`) — both are defects in the
shipped template, so they are fixed where the template lives. No blueprint or contract change
is warranted; nobody reasoned wrongly, the template was simply written against a public-repo,
GHAS-enabled assumption.

Worth adding one line to the onboarding checklist in
`docs/adopt-existing-project.md` → *Step 6*: the first PR through the new gate should be
expected to surface gate-configuration defects, and those count as adoption work rather than
project work.
