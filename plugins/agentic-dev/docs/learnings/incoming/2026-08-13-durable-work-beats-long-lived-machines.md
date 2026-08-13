---
date: 2026-08-13
scope: upstream
area: process
severity: high
---

# Make the work durable instead of trying to keep the machine alive

## What happened

An autonomous loop ran overnight on an ephemeral cloud container, dispatching build sub-agents
as background tasks. Over roughly nine hours, **six of seven sub-agents were lost** before they
finished. One increment was started four separate times and reached `main` only on the fourth
attempt — not because it was hard, but because each attempt outlived its container by minutes.

Measured from git: **571 minutes with no merge**, spanning about nine loop cycles that all ran
and all produced nothing.

## Why it happened

The hosting documentation states plainly that *"cloud sessions stop after a period of
inactivity and the session's VM is reclaimed."* The span is not documented and not
configurable, and a reclaimed VM takes any `git worktree` with it. Crucially, **a running
background sub-agent does not appear to count as activity** — only the main agent's own work
does.

So the orchestrator's habit of dispatching an agent and then ending its turn was precisely the
thing that killed the agent. The instruction it followed said how to *start* visible work, and
nothing about staying present until that work returned.

## What we do differently now

Two rules, both cheap, both verified in the same session:

1. **A build agent pushes its branch as soon as its first commit exists** — not at the end. A
   reclaimed container then costs minutes of re-orientation instead of the whole increment.
2. **The orchestrator does not end a turn while a sub-agent is running.** Activity by the main
   agent is the only lever against the inactivity span.

The first fix landed mid-session and worked immediately: the next agent's branch was on the
server before it finished, and would have survived a reclaim.

## Generalisable?

Yes — this happens in **any** project whose loop runs on ephemeral infrastructure, which is the
normal case for cloud-hosted agents. Nothing here is stack-specific.

**Level: contract**, in two places.

`contracts/dev-agent.md`, add to the commit rules:

> **Push as soon as the first commit exists, not when the increment is finished.** Work that
> lives only in a local worktree is lost when the environment is reclaimed, and ephemeral
> containers are the normal case. Pushing early costs one command; it turns a lost increment
> into a few minutes of re-orientation.

`contracts/orchestrator-agent.md`, add to the dispatch rules:

> **Do not end a turn while a dispatched agent is still running.** On ephemeral
> infrastructure, the main agent's activity is what keeps the environment alive; a background
> agent's is not. Dispatching and then going idle reliably kills the work you just started —
> stay in the turn with real work until the agent reports back.

**Cost of the rule:** the orchestrator can no longer fire several agents and go quiet, so
wall-clock parallelism drops. That is the correct trade — parallel agents that never finish are
worth less than one that does.
