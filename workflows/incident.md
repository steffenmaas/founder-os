# Workflow — Incident

**Use when:** something is wrong in production and the cause is **not yet known**.
**Entry:** manual. If the cause is known, go straight to `hotfix.md`.

> The difference between this and a hotfix: a hotfix knows what to fix. An incident is the
> work of finding out — and the failure mode is starting to fix before you know what is
> broken.

---

| # | Who | What | Gate |
|---|---|---|---|
| 1 | Human | **DECLARE** — say out loud that this is an incident, and who is running it. | One named owner. |
| 2 | Dev | **ASSESS** — what is the user-visible impact? How many, how badly, since when? | Impact stated in one sentence. |
| 3 | Human | **DECIDE SEVERITY** — is a blind rollback to the last known good state cheaper than diagnosis? | **If yes: roll back now, diagnose after.** Go to step 7. |
| 4 | Dev | **TIMELINE** — what changed? `git log`, deploy history, dependency updates, config changes, and anything external (provider status pages). | A list of candidate causes, ordered by likelihood. |
| 5 | Dev | **ISOLATE** — narrow it down with evidence, not intuition. One hypothesis at a time; state it, test it, record the result. | Cause identified **and demonstrated**, or explicitly escalated as unknown. |
| 6 | Dev | **CONTAIN** — flag off, roll back, or scale out. Stop the impact before fixing the cause. | Users no longer affected. |
| 7 | Dev | **FIX** — switch to `hotfix.md` from step 3 onwards. | — |
| 8 | Human | **COMMUNICATE** — during, not only after. Status at start, at containment, at resolution. | — |
| 9 | Dev | **POSTMORTEM** — within 24 hours, blameless. | Written, learning filed. |

---

## Diagnosis discipline

**One hypothesis at a time.** State it, test it, write down the result. An agent under
pressure will change three things at once, and then nobody knows which one mattered — or
whether the problem is actually fixed.

**Evidence over intuition.** "It's probably the cache" is a hypothesis, not a finding. It
becomes a finding when you have the log line, the metric, or the reproduction.

**Write the timeline as you go.** Not afterwards from memory. The postmortem is only as good
as the notes taken during, and memory of an incident is reliably wrong about ordering.

---

## Postmortem format

`docs/learnings/YYYY-MM-DD-incident-<slug>.md`, with `severity: high` and `scope:` set
honestly.

```markdown
# Incident: <one line>

## Impact
Who, how many, how long, how badly.

## Timeline
UTC timestamps. What happened, what was observed, what was done.

## Root cause
The actual cause. Not "a bug was introduced" — which bug, and why it got through.

## What went well
Genuinely. Detection speed, containment, communication.

## What did not
Blameless. Systems and gates, not people or agents.

## Which gate should have caught this?
The most important section. One of:
  - a gate exists and did not fire → why not?
  - a gate exists and was bypassed → how, and can that be closed?
  - no gate exists → propose one, and name its level (blueprint / hook / CI)

## Actions
Concrete, owned, on the roadmap. Not "be more careful".
```

---

## The one rule

**Blameless means blameless — including toward the agent.** "The agent should have noticed"
is not a finding; it is a description of the failure, not its cause. The finding is always
about the missing gate, because the gate is the thing you can change.
