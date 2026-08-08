---
name: dev-ship
description: Takes an approved change to production under the Release Agent contract — precondition check, full verification chain, migration reverse test, PR with rollback plan, preview check, merge, deploy, health watch. Use this skill when the user says "ship it", "deploy", "release", "take it live" or any natural variant. Module 16 (Agentic Dev) — Product & Tech Delivery. Pre-Seed.
disable-model-invocation: true
---

# Ship

This skill is part of the **Founder OS** plugin, Module 16 — Agentic Dev (Product & Tech Delivery).

**Contract:** `.founder-os/contracts/release-agent.md`

> **Human-invoked only.** `disable-model-invocation: true` — no agent triggers this on its
> own. An agent never decides that now is a good moment to deploy.

## When to trigger

Run this skill when the user says any of:

- "ship it"
- "deploy"
- "release"
- "take it live"
- `founder-os:dev-ship`

## Key instructions

**Target:** $ARGUMENTS

Status: !`git status --short --branch 2>/dev/null`
Ahead of main: !`git log --oneline origin/main..HEAD 2>/dev/null | head -20`

---

### 1. Preconditions — every one, or refuse

- [ ] Working tree clean, everything committed
- [ ] Branch current against `main`
- [ ] Every acceptance criterion demonstrated
- [ ] QA verdict PASS or PASS WITH NOTES — never BLOCKED
- [ ] No open Critical or High security findings
- [ ] Preview deployment exists and was looked at
- [ ] Rollback plan written in the PR

A missing precondition is a stop, not a judgement call. Name which one and hand back.

### 2. Full verification chain

Run **all** commands from `CLAUDE.md` and show the output:

```
lint → typecheck → test → build → e2e (if present)
```

Red anywhere: **stop here.** Not "it's just a flaky test" — a test that changes outcome
without a code change is a bug. It gets repaired, or quarantined with
`// QUARANTINE #<issue> until <YYYY-MM-DD>`. Never ignored.

### 3. Migrations

- Forward against a copy.
- **Backward against the same copy.** A migration without a tested reverse path does not
  ship. This is not negotiable.
- If it deletes or reshapes data: **ask the human.** Every time, per deploy.

### 4. PR

Template filled in completely. The **rollback section is mandatory** and CI enforces it.
One concrete sentence:

- "Reverting this commit is enough, no migration involved."
- "Roll migration 0042 back with `npm run db:rollback`, then revert."

### 5. Preview

Wait for the URL in the PR. Open it. Actually walk the changed flow. Screenshot into the PR
for UI changes.

**If you cannot check the preview yourself, say so explicitly** — then the human does this
step and you wait.

### 6. Merge and deploy

- Merge only on green CI and a passed review.
- Squash merge, Conventional Commits message.
- Deployment runs through the pipeline. **Never from local** — the guard hook blocks it.

### 7. After the deploy

- Show the health-check result.
- Watch error rate and logs for 10 minutes (the deploy workflow does this — report its result).
- On anomalies: **roll back first, analyse after.** Not the other way round.

### 8. Close out

- `ROADMAP.md`: move the entry to *Done* with date and commit hash.
- If this completed the current version's scope: say so and propose the version bump
  (`/dev-product`, workflow `version-cut.md`). Do not bump it yourself.
- Status block:

```
SHIPPED:   <what, commit hash, version if bumped>
VERIFIED:  <chain result, smoke test, health watch>
ROLLBACK:  <the plan, restated — so it is in the transcript when it is needed>
OPEN:      <anything deferred>
```
