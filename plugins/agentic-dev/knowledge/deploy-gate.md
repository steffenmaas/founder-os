# The Deploy Gate — ship automatically, or ask a human

> Neither "everything auto-deploys" nor "a human approves everything" survives contact with
> an agent shipping many changes a day. The first loses the human's judgement exactly where
> it matters; the second makes the human the bottleneck everywhere it does not. The gate is
> the explicit line between the two — a checklist, not a judgement call.

Run at SHIP time, in **every** workflow. Two outcomes, nothing in between:

```
  AUTO-SHIP     merge → pipeline deploy → health watch. No human in the loop.
  HUMAN GATE    deploy to a preview channel → notify the human → wait for approval
                (Abnahme) → only then merge.
```

---

## The checklist

**AUTO-SHIP only when every line holds.** One failed line → HUMAN GATE, and the failed line
is named in the notification. Never re-argue a line to get to auto-ship.

| # | Check | Holds when |
|---|---|---|
| 1 | **Change class** | The change is: a bug fix restoring already-specified behaviour · an improvement inside an existing feature following existing patterns · copy, content, or docs · internal tooling · a dependency patch/minor · anything fully behind a feature flag that is off. |
| 2 | **Untouchable surfaces untouched** | The diff does **not** touch: auth · payments, money, or pricing · personal-data handling · security rules or secrets handling · CI/deploy configuration · legal texts or store submissions · a destructive or irreversible migration · a breaking public-API change · a new dependency or a major upgrade · anything an ADR reserves for humans. |
| 3 | **First exposure** | This is **not** the first user-visible version of a new feature. The human sees new features before users do — always. |
| 4 | **Verification** | Scoped verification chain green, guard tests green, QA verdict PASS at the given scope. Output shown, not asserted. |
| 5 | **Decision confidence** | No decision in this diff scored below the project's confidence threshold (harness §5). A queued decision inside the diff is an automatic gate. |
| 6 | **Reversibility** | One revert restores the previous state. Rollback plan named. Persisted-data formats stay backward compatible. |
| 7 | **Blast radius** | One feature area. No cross-cutting change riding along. |

## The HUMAN GATE path

1. **Deploy the branch to a preview channel.** Never with production data or production
   secrets.
2. **Put everything the human needs into the PR:** what changed, **which checklist line
   gated it** (by number), the preview URL, screenshots for UI, the rollback plan, and — if a
   decision is pending — the question with options and your recommendation.
3. **Notify the human once**, through the check-in channel. Then **take the next backlog
   item.** The gate parks the change, never the loop.
4. **On approval:** merge, deploy through the pipeline, health watch. Approval covers this
   change only — it is not a precedent that reclassifies the change class.
5. **On change requests:** back to the Dev Agent as a new increment on the same branch.

## Configuration

Per project, in `project-config.json` (`deploy_gate`):

| Key | Meaning | Default |
|---|---|---|
| `mode` | `strict` = every change is gated · `standard` = this checklist · never looser than this checklist | `standard` |
| `always_gate` | Path globs that force the gate regardless of change class (e.g. `lib/payments/**`) | `[]` |

Tightening is a config change. **Loosening is an ADR** — it removes a human from a loop, and
that decision must be written down with its reasoning.

## The audit trail

Every auto-ship records its checklist result (7 lines, pass/fail) in the PR or commit body.
The daily check-in lists what auto-shipped since the last one. Trust in the gate is built by
being able to audit it — an auto-ship the human cannot reconstruct afterwards is a gate
failure even if the change was fine.
