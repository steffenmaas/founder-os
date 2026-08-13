---
date: 2026-08-13
scope: upstream
area: process
severity: medium
---

# A retrospective measured from git finds what a remembered one cannot

## What happened

After three days of autonomous work, the founder asked a plain question: *what actually got
done, and why does it not feel like progress?*

The honest answer was not available from memory. It came from measuring — commits classified by
path, merges grouped by area, gaps between merges computed, roadmap entries checked against the
code that supposedly implemented them. It took under an hour and produced findings nobody had
suspected:

- **62 % of all lines written over three days** went to documentation, process and
  infrastructure rather than product. The largest single category was documentation.
- A **571-minute gap** with no merge — about nine loop cycles that all ran and shipped nothing.
- The top-priority workstream got **30 of 85 merges on day one, then 0 and 0**.
- Checking the roadmap against the code found **eight entries that did not match** — in both
  directions. Two finished features were still listed as open, including one with 990 lines of
  code and tests. Three shipped promises were broken in ways no one had noticed. One entry
  appeared twice. A test count in the file said 151; the real number was 603.
- Every specification in the repository still carried the status "draft", including the ones
  whose work had shipped.

The measurement also corrected the measurer. A first draft claimed the top priority had received
no work at all in three days. Grouping merges by area disproved it within minutes: that area had
more merges than any other in the project's history. The true finding was sharper — not a
never-started workstream, but an **abandoned** one.

## Why it happened

Status kept flowing one way. Documents were written and never read back against reality, so each
one drifted quietly from the moment it was committed. No single lapse; a missing return path.

An agent reporting from its own context window inherits that drift, and its report will sound
confident because the numbers in it are real — just no longer true.

## What we do differently now

A retrospective is a **measurement**, and the measurement is specified rather than improvised:

1. **Merges per day, and gaps between them.** Gaps are the signal; they mark where cycles ran
   and produced nothing.
2. **Lines classified by path** — product · tests · docs · infrastructure · backlog. The ratio
   is the finding.
3. **Merges grouped by area**, compared against the stated priority. This is what exposes drift
   away from it — and what corrected the first draft above.
4. **Every roadmap entry opened against the code**, with file and line as evidence. Expect
   errors in both directions; finished work recorded as open is as common as the reverse.
5. **Every claim in the report re-derived independently** before it is reported. One of the
   sharpest findings in this retrospective was a first-draft error caught this way.

Findings become tickets in the same pass, not recommendations in a document.

## Generalisable?

Yes — and the case for it is stronger the more autonomous the loop is. A human team notices
drift by talking to each other; a loop has no such channel and will restate its own summary
until something external contradicts it. The module has `dev-metrics` for speed and quality
signals, but nothing that checks **stated status against reality**.

**Level: workflow** — a new `workflows/retrospective.md`, run at a version cut or on request:

> **Measure first, narrate second.** Every figure comes from `git` or from the code at run time;
> nothing is carried over from an earlier report, and no claim is reported that has not been
> re-derived independently.
>
> 1. Merges per day and the gaps between them — gaps mark cycles that produced nothing.
> 2. Added lines classified by path: product · tests · docs · infrastructure · backlog.
> 3. Merges grouped by area, held against the stated priority — this is where drift shows.
> 4. Every roadmap entry opened against the code, with file and line as evidence. Expect errors
>    in both directions: finished work recorded as open is as common as the reverse.
> 5. Every finding becomes a ticket in the same pass. A retrospective that ends in a document
>    changes nothing.

**Cost of the rule:** roughly an hour, and it produces uncomfortable findings — including about
the agent running it. Both are the point.
