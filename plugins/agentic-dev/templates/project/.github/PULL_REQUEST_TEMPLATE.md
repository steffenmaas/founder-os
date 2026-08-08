<!-- TEMPLATE — copy to .github/PULL_REQUEST_TEMPLATE.md -->

## What

<One paragraph. What changed, for whom.>

**Spec:** `docs/specs/<slug>.md` <or "one-sentence change, no spec">

## Verification

<Commands run and their actual results — evidence, not adjectives (harness §7).>

```
<lint / typecheck / test / build output summary>
```

**Not checked:** <what could not be verified, and why. Mandatory line — an unmentioned gap
is worse than a named one.>

## Deploy gate

<Result of the deploy-gate checklist (deploy-gate.md): AUTO-SHIP with the 7 lines, or
HUMAN GATE naming the failed line + preview URL.>

## Rollback

<One sentence: "reverting the commit is enough" or the exact command that undoes it,
including the migration reverse path if one exists.>
