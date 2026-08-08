# Workflows

A **workflow** is the named sequence for one kind of work: which contracts act, in what
order, with which gates between them. The blueprint says what the rules are; a workflow says
what happens next.

Pick the workflow that matches the work. If none fits, use `new-feature.md` and say in the
check-in that the workflow did not fit — that is a learning with `scope: upstream`.

| Workflow | Use when | Entry point |
|---|---|---|
| [`autonomous-loop.md`](autonomous-loop.md) | Continuous development from a live backlog — the standing meta-workflow | standing orchestrator session |
| [`new-feature.md`](new-feature.md) | Building something that does not exist yet | `/dev-loop` |
| [`bug-fix.md`](bug-fix.md) | Something works incorrectly, but production is stable | `/dev-loop` |
| [`hotfix.md`](hotfix.md) | Production is broken right now | `/dev-ship` after the fix |
| [`refactor.md`](refactor.md) | Changing structure without changing behaviour | `/dev-loop` |
| [`dependency-update.md`](dependency-update.md) | Upgrading or adding a dependency | `/dev-loop` |
| [`incident.md`](incident.md) | Something is on fire and the cause is unknown | manual, then `hotfix` |
| [`version-cut.md`](version-cut.md) | A product version is complete | `/dev-product` |
| [`ux-audit.md`](ux-audit.md) | A bundle group shipped — check direction from the user's point of view | `autonomous-loop` step 8, or `/dev-review` |

## Reading a workflow

Each one is a table of steps. Per step: **who** (contract), **what**, and **the gate** that
must hold before the next step starts. A gate that does not hold is a stop, not a judgement
call.

## The common shape

Every workflow is a specialisation of the loop:

```
  ORIENT ─▶ SPEC ─▶ PLAN ─▶ BUILD ─▶ VERIFY ─▶ SHIP ─▶ LEARN
```

What differs between them is which phases compress, which gates tighten, and who is allowed
to skip what. `hotfix.md` compresses SPEC and PLAN to near zero and tightens the SHIP gate.
`refactor.md` inverts VERIFY: the test suite must pass **unchanged**, because unchanged
behaviour is the whole point.

`autonomous-loop.md` is the exception to the shape: it is the **standing meta-workflow**
that pulls from the live backlog, bundles work, and runs the others inside its increments.
Its SHIP phase is always the deploy gate (`../knowledge/deploy-gate.md`), and its VERIFY is
two-tier — scoped per increment, full suite once per bundle.
