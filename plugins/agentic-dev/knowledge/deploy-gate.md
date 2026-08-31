# The Deploy Gate — ship automatically, or ask a human

> Neither "everything auto-deploys" nor "a human approves everything" survives contact with
> an agent shipping many changes a day. The first loses the human's judgement exactly where
> it matters; the second makes the human the bottleneck everywhere it does not. The gate is
> the explicit line between the two — a checklist, not a judgement call.

**How much gate a change gets follows what is actually at stake** — the project's
`stage`, the master dial in `project-config.json`:

| `stage` | Reality | Posture |
|---|---|---|
| **`pre-live`** *(default for new projects)* | Not live. No users, no revenue, no data anyone would miss. **Nothing can break that matters.** | **Speed is everything.** Checklist lines 1–3 and 7 are suspended: every change auto-ships once verification (line 4) is green. Merges, tests, releases happen immediately — package done, merge, next. Decisions: **decide whenever the cost of being wrong is bearable and the call is revisable; collect and present only what is irreversible or existential.** The worst case of a wrong autonomous decision here is revising it — that is cheaper than waiting a night for an answer. Confidence threshold default drops to 40 (harness §5). |
| **`live`** | First real users. | The checklist below, as written. Threshold default 70. First user-visible versions and the untouchable surfaces see a human. |
| **`scaled`** | Paying users at volume. | The checklist plus: untouchable surfaces (line 2) are **always** gated, `mode: strict` is the recommended setting, threshold default 85. |

**Moving to `live` is a founder decision and a checklist** (the go-live list in the stack
blueprint: backups on, error reporting live, legal pages up). Tightening the stage is a
config change; loosening it back is an ADR. And one line survives every stage, including
`pre-live`: **verification green before merge** — speed comes from skipping approvals, never
from skipping the proof that it works.

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
| `stage` | `pre-live` · `live` · `scaled` — the master dial above; sets gate posture and the confidence-threshold default | `pre-live` |
| `mode` | `strict` = every change is gated · `standard` = this checklist · never looser than the stage's posture | `standard` |
| `always_gate` | Path globs that force the gate regardless of change class (e.g. `lib/payments/**`) | `[]` |

Tightening is a config change. **Loosening is an ADR** — it removes a human from a loop, and
that decision must be written down with its reasoning.

## After the deploy — verify from the source

**A deploy is not done when the command exits.** Deploys fail silently: the pipeline goes
red after you stopped watching, the CDN keeps serving the old version, a function fails to
roll out. Discovering that days later, by accident, in the Actions list, is an incident that
has already happened. So after **every** ship, verify from the primary sources — never from
the assumption:

1. **The pipeline run** for your commit: completed and green. Not "started".
2. **The deployed version marker** (e.g. `/version.json` with the build id): matches your
   commit. This is the check that catches "old version still serving".
3. **The health endpoint** answers healthy.

After a **major deploy** (new feature area, migration, dependency major), additionally,
over the first ~10 minutes:

4. **Runtime logs** (functions, server) clean of new errors.
5. **Error rate** at baseline.
6. **The user feedback channel** — reports arriving right after a deploy are the fastest
   signal there is; route them into the backlog as bugs immediately.

Anything found here is handled as `hotfix.md` or `incident.md` — never as "watch it for a
while". The deploy template (`templates/project/.github/workflows/deploy.yml`) automates
checks 1–3; 4–6 are the loop's HEALTH step until the project automates them too.

## The audit trail

Every auto-ship records its checklist result (7 lines, pass/fail) in the PR or commit body.
The daily check-in lists what auto-shipped since the last one. Trust in the gate is built by
being able to audit it — an auto-ship the human cannot reconstruct afterwards is a gate
failure even if the change was fine.
