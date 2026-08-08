# ADR-0000: <Decision title>

- **Status:** Proposed | Accepted | Superseded by ADR-XXXX | Revoked (see ADR-XXXX)
- **Date:** <YYYY-MM-DD>
- **Deciders:** <names>

> An **ADR records a decision that constrains future work.** It is binding from the moment
> the human accepts it. Agents may question it; they may not silently work around it.
>
> If what you want to record is an observation rather than a constraint, it is a learning —
> write it in `docs/learnings/` instead. Confusing the two is the most common mistake here.
>
> **Decisions get revised — by a new ADR, never by editing this one.** When testing or
> production shows a decision was wrong, write a new ADR that states what was observed,
> supersedes this one, and sets the new constraint; mark this one `Superseded by` (or
> `Revoked` if nothing replaces it). The wrong decision stays on record — it is the context
> that stops the next agent from making it again. Silently editing history is how the same
> wrong decision gets made twice.

## Context

<What situation forces a decision? What constraints apply? What did we know at the time?>

## Options

| Option | Upside | Downside |
|---|---|---|
| A: <…> | <…> | <…> |
| B: <…> | <…> | <…> |

## Decision

<We choose X, because …>

## Consequences

**Positive:** <…>

**Negative:** <…> — accepted knowingly.

**Binding for agents:**

> <State the rule that follows, as an instruction. This line is what an agent reads and
> obeys. e.g. "All monetary values are stored as integer minor units. Never introduce a
> float for money, anywhere.">

## Revisit when

<What would have to change for this decision to be worth reopening? "Never" is a valid
answer; "unclear" is not.>
