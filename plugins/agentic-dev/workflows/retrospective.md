# Workflow — Retrospective (measured, not remembered)

**Use when:** at a version cut, after a stretch of autonomous work, or whenever the human asks
what actually got done. **Entry:** `/dev-metrics` for speed and quality signals; this workflow
for the harder question — whether *stated status* still matches reality.

> A human team notices drift by talking to each other. A loop has no such channel and will
> restate its own summary until something external contradicts it. This workflow is that
> contradiction.

---

## The one rule

**Measure first, narrate second.** Every figure comes from `git` or from the code at run time.
Nothing is carried over from an earlier report, and **no claim is reported that has not been
re-derived independently** — in the run that produced this workflow, one of the sharpest
findings in the first draft turned out to be the measurer's own error, caught exactly this way.

---

## The five measurements

1. **Merges per day, and the gaps between them.** The gaps are the signal: they mark cycles
   that ran and produced nothing. One run found a 571-minute gap spanning about nine cycles.
2. **Added lines classified by path** — product · tests · docs · infrastructure · backlog. The
   ratio is the finding, not the total. One run found 62 % of three days' output going to
   documentation, process and infrastructure rather than product.
3. **Merges grouped by area, held against the stated priority.** This is where drift shows.
   Expect the shape to be *abandonment* rather than *never started* — the same run found the
   top priority took 30 of 85 merges on one day and none at all on the two that followed.
4. **Every roadmap entry opened against the code**, with file and line as evidence. **Expect
   errors in both directions.** Finished work recorded as open is as common as the reverse: one
   run found two shipped features still listed as open — one of them 990 lines of code and
   tests — alongside three shipped promises that were quietly broken.
5. **Status fields across specs and docs.** Fields that only ever get written and never read
   back drift from the moment they are committed. One run found every specification in the
   repository still marked "draft", including those whose work had shipped.

---

## Output

**Findings become tickets in the same pass.** A retrospective that ends in a document changes
nothing — the document is for the human, the tickets are what changes the next cycle.

Where a finding is about the loop itself, it becomes a learning with `scope: upstream` and a
concrete proposed rule, so the next project does not rediscover it.

---

## Cost

Roughly an hour, and it produces uncomfortable findings — including about the agent running it.
Both are the point.
