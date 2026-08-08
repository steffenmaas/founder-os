---
name: dev-learn
description: Captures a learning in docs/learnings, and pushes generalisable ones upstream to the Founder OS repository as a pull request. Use this skill when the user says "write that down", "we learned something", "capture this learning", "send learnings upstream", or after anything surprising, slow, or broken. Module 16 (Agentic Dev) — Product & Tech Delivery. Pre-Seed.
---

# Capture a learning

This skill is part of the **Founder OS** plugin, Module 16 — Agentic Dev (Product & Tech Delivery).

> This is the feedback loop that keeps the module honest. Without it, every project relearns
> the same lesson and the blueprint never improves.

## When to trigger

Run this skill when the user says any of:

- "write that down"
- "we learned something"
- "capture this learning"
- "send learnings upstream"
- `founder-os:dev-learn`
- `founder-os:dev-learn --upstream`

Also run it **on your own initiative** after:

- something took far longer than expected
- something broke in a way you would not have predicted
- a workaround was needed that is not obvious from the code
- a rule from the blueprint did not fit the situation

## Key instructions

**Input:** $ARGUMENTS

Existing learnings: !`ls docs/learnings/ 2>/dev/null | tail -8`
Unsubmitted upstream: !`grep -rl 'scope: upstream' docs/learnings/ 2>/dev/null | xargs grep -L 'submitted: http' 2>/dev/null | head -10`

---

## Mode A — capture (default)

### 1. Decide: learning or decision?

This is the distinction people get wrong most often.

| | Learning | Decision (ADR) |
|---|---|---|
| Is | An observation | A constraint |
| Binds future work | No | **Yes** |
| Lives in | `docs/learnings/` | `docs/decisions/` |
| Example | "The seed script hangs when run twice" | "All money is integer minor units" |

If it constrains future work, stop — write an ADR instead.

### 2. Write it

`docs/learnings/YYYY-MM-DD-<slug>.md`, from
`${CLAUDE_PLUGIN_ROOT}/templates/project/docs/learnings/_template.md`.

Front matter, all fields required:

```yaml
scope:    project | upstream
area:     ci | testing | deploy | security | process | tooling | product
severity: low | medium | high
```

### 3. Set the scope honestly

- **`project`** — specific to this codebase, this stack, this setup. It stays here as context
  for the next agent working in this repo.
- **`upstream`** — this would happen in **any** project using this module. It belongs in
  Founder OS.

When `scope: upstream`, the *Generalisable?* section is mandatory and must name:

1. **Which rule should change** — concretely enough to be pasted in.
2. **At which level:**

| Level | When |
|---|---|
| Blueprint | A principle or a phase rule |
| Harness | A decision guideline or trade-off |
| Contract | A role boundary was wrong or missing |
| Workflow | A step or a gate was wrong or missing |
| Hook | It must be blocked locally, immediately |
| CI gate | It must be blocked centrally, as the last line |

Rule of thumb: violation merely annoying → blueprint. Violation destroys work or endangers
security → hook **and** CI gate.

---

## Mode B — upstream (`--upstream`)

Run at a version cut, or whenever upstream learnings have accumulated.

### 1. Collect

Every file in `docs/learnings/` with `scope: upstream` and **no** `submitted:` value.
If there are none, say so and stop.

### 2. Group and dedupe

Several learnings often point at the same rule. Group them — one proposed change per group,
citing all the incidents behind it. A rule backed by three incidents is far more persuasive
than three separate PRs.

### 2b. Scrub — the module repository is public

**Upstreaming is publishing.** Before a learning leaves the project, check every group
against blueprint §9.3, and refuse rather than guess:

- [ ] **No unfixed security finding.** Is the vulnerability's fix deployed? If not, the
      learning stays `scope: project` — say so and exclude it from this PR.
- [ ] **No project internals quoted:** credentials, infrastructure identifiers, hostnames,
      personal or customer data, revenue, user counts or other business metrics,
      unreleased product plans. Generalise the mechanism; drop the specifics.
- [ ] **Stands alone.** If the rule only makes sense with internal context, it is not
      generalisable — keep it local.

Report what was scrubbed or held back. A learning silently sent with internals in it is a
disclosure, not a contribution.

### 3. Build the change

For each group, produce the concrete diff against the module:

```
knowledge/blueprint.md
knowledge/harness.md
knowledge/contracts/<role>.md
workflows/<name>.md
hooks/scripts/guard-bash.sh          (+ a case in tools/test_hooks.sh)
templates/project/.github/workflows/  (a CI gate)
```

**A new hook rule without a new test case in `test_hooks.sh` is incomplete.**

### 4. Open the PR

```bash
gh repo clone steffenmaas/founder-os /tmp/founder-os-upstream
# branch: learning/<area>-<slug>
# copy the learning files to docs/learnings/incoming/
# apply the proposed rule changes
# run: python3 tools/validate.py && bash tools/test_hooks.sh
gh pr create --repo steffenmaas/founder-os --title "learning(<area>): <rule>" --body-file <body>
```

PR body structure:

```markdown
## Incident
<What happened, in which project, how often. Link the learning files.>

## Proposed rule
<The concrete new or changed rule.>

## Level and why
<blueprint / harness / contract / workflow / hook / CI — and why that level.>

## Cost of the rule
<What does it make harder or slower? Every rule has a cost; name it.>

## Verification
<validate.py green, test_hooks.sh green, new test case added.>
```

### 5. Mark as submitted

Write `submitted: <PR URL>` into the front matter of each learning included, so it is never
sent twice.

### 6. Report

Which learnings went up, grouped how, into which rules, and the PR link.

---

## The rule about rules

**A rule is created after an incident, never preventively.** Preventive rules inflate the
blueprint without preventing anything, and an inflated blueprint stops being read — at which
point the rules that do matter stop working too.

If you cannot name the incident, do not propose the rule.
