---
name: dev-spec
description: Writes or reworks a specification for one unit of work — problem, goal, non-goal, traceability to the product, affected files, executable acceptance criteria, verification step, risks and rollback. Use this skill when the user says "write a spec", "spec this out", "what exactly should we build" or any natural variant. Module 16 (Agentic Dev) — Product & Tech Delivery. Pre-Seed.
---

# Write a spec

This skill is part of the **Founder OS** plugin, Module 16 — Agentic Dev (Product & Tech Delivery).

**Contract:** `.founder-os/contracts/product-agent.md`

## When to trigger

Run this skill when the user says any of:

- "write a spec"
- "spec this out"
- "what exactly should we build"
- "turn this into a spec"
- `founder-os:dev-spec`

## Key instructions

**Topic:** $ARGUMENTS

Existing specs: !`ls docs/specs/ 2>/dev/null | tail -10`
Product: !`head -3 PRODUCT.md 2>/dev/null`

---

### 1. Interview first, write second

If anything about the requirement is open, ask the human **now** — bundled in one pass with
`AskUserQuestion`, not one question at a time. Typical gaps:

- Who is the user and what is their concrete pain?
- Which edge cases matter, which are explicitly out of scope?
- Is there an existing flow this touches?
- Which technical trade-offs are acceptable (effort vs. completeness)?
- What is explicitly **not** part of this?

Time spent making the spec precise beats time spent watching an implementation go the wrong
way.

### 2. Check traceability

Which line in `PRODUCT.md` does this serve? If none, say so — this may be scope drift, and it
is a product decision whether to widen the product or drop the item.

### 3. Research the code

Delegate to an `Explore` subagent: which files, interfaces, and data models are affected?
Do not read half the codebase yourself.

### 4. Write it

Follow `${CLAUDE_PLUGIN_ROOT}/templates/project/docs/specs/_template.md`, save as
`docs/specs/<slug>.md`.

The spec is finished only when:

- [ ] An agent with an **empty context** could implement it alone
- [ ] **Non-goal** is filled in and non-empty — the most important section
- [ ] Acceptance criteria are **executable checks**, not prose
      (bad: "login works" · good: `npm test -- auth.spec.ts` passes)
- [ ] An end-to-end verification step is written as a command
- [ ] Concrete file paths are named, not "somewhere in the auth module"
- [ ] The rollback path is named
- [ ] It traces to `PRODUCT.md`

### 5. Link it

Add or update the entry in `ROADMAP.md` with a link to the spec.

## Handoff

Show the spec to the human for approval. **Then stop — do not write code in this session.**
Implementation starts fresh, with the spec as its only input. A clean context with a precise
spec beats an accumulated context with the conversation history.
