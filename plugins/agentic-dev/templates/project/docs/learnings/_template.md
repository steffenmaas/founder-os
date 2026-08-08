---
date: <YYYY-MM-DD>
scope: project | upstream
area: ci | testing | deploy | security | process | tooling | product
severity: low | medium | high
submitted: <PR URL, only when scope is upstream and it has been sent>
---

# <One-line statement of what was learned>

> A **learning** is an observation: something that cost time, broke unexpectedly, or needed a
> non-obvious workaround. It is not binding — it is context for whoever comes next.
>
> If what you want to record is a rule that constrains future work, it is a decision —
> write an ADR in `docs/decisions/` instead.

## What happened

<Concrete. What was being attempted, what actually occurred.>

## Why it happened

<The actual cause, as far as you established it. If you did not establish it, say so —
"cause not identified" is a useful learning too.>

## What we do differently now

<Concrete and actionable. Not "be more careful". Either a changed step, a new check,
or a note that the next agent will read at the right moment.>

## Generalisable?

<Only fill this in when `scope: upstream`.

 Would this happen in any project, or is it specific to this codebase?
 If any project: which rule should change, and at which level?

 - Blueprint (prose, covers everything, enforces nothing)
 - Harness (a decision guideline)
 - A contract (a role boundary)
 - A workflow (a step or a gate)
 - A hook (blocks locally, immediately)
 - A CI gate (blocks centrally, last line)

 Write the proposed change concretely enough that it could be pasted in.
 Then run `/dev-learn --upstream` to open the PR against founder-os.>
