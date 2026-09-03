---
date: 2026-08-13
scope: upstream
area: process
severity: medium
---

# Before grooming, check which store is the source of truth

## What happened

A backlog had been deliberately moved into the repository as a versioned file, with the old
database collection kept as a read-only projection for the app. An ADR recorded the move and
named the file as the single source of truth.

A later grooming pass read the **projection**. Six tickets it expected were not there, and it
concluded they had never been written — publishing that conclusion as a learning that blamed
earlier cycles for fabricating ticket ids.

All six existed. They were in the file, exactly where the ADR said they would be.

## Why it happened

Both stores answered. Neither was broken. The wrong one answered *plausibly* — a well-formed
list of real tickets, just an older set — and nothing in a plausible answer signals that you
asked the wrong question.

The ADR that would have settled it in one minute had never been read.

Underneath sat a second, larger fact the mistake exposed: **the sync that writes the projection
had never been wired into the deploy.** The tool existed and was schema-checked in CI; nothing
ever applied it. Measured drift at the time of discovery: 41 creates, 8 updates, 5 drops. The
app had been showing users a development status frozen two days earlier.

## What we do differently now

- **Grooming starts by naming the source.** If an ADR designates one, read it before reading
  any store. This costs a minute and would have prevented the whole episode.
- **A projection that nothing writes is worse than no projection**, because it looks complete.
  Any one-way sync gets a step that actually runs, and a failure of that step is visible.
- **An empty result is not evidence of absence.** "I cannot find it" means "I may have looked in
  the wrong place" first — especially when the conclusion drawn from it is that someone else was
  careless.

## Generalisable?

Yes. Any project that keeps a working copy of state alongside a canonical one — a repo file
projected into a database, a cache in front of an API, a generated index — can produce exactly
this. The module already encourages moving the backlog into the repo, which creates the two-store
situation by design.

**Level: workflow.** In `workflows/autonomous-loop.md`, at the grooming step:

> **Name the source before you read it.** Where an ADR designates a source of truth for the
> backlog, read that ADR first and groom against the store it names. A projection or cache will
> answer plausibly with stale data, and a plausible answer gives no sign that the wrong store was
> asked. If a projection exists, also confirm that something actually writes it — a projection
> nothing updates looks complete and is the more expensive failure.

**Cost of the rule:** one extra file read at the start of every grooming pass.
