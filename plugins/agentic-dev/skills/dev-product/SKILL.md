---
name: dev-product
description: Maintains the intent hierarchy — writes and updates PRODUCT.md and ROADMAP.md, checks that every roadmap item traces to the product, and prepares product version cuts. Use this skill when the user says "update the roadmap", "what should we build next", "cut a version", "is this on the roadmap" or any natural variant. Module 16 (Agentic Dev) — Product & Tech Delivery. Pre-Seed.
---

# Product and roadmap

This skill is part of the **Founder OS** plugin, Module 16 — Agentic Dev (Product & Tech Delivery).

**Contract:** `.founder-os/contracts/product-agent.md` — read it first.
**Workflow for a version cut:** `.founder-os/workflows/version-cut.md`

## When to trigger

Run this skill when the user says any of:

- "update the roadmap"
- "what should we build next"
- "cut a version" / "bump the version"
- "is this on the roadmap"
- "reprioritise"
- `founder-os:dev-product`

## Key instructions

**Request:** $ARGUMENTS

Current state: !`head -5 PRODUCT.md 2>/dev/null; echo '---'; awk '/^## Now/{f=1} /^## Later/{f=0} f' ROADMAP.md 2>/dev/null | head -12`
Recent work: !`git log --oneline -15 2>/dev/null`

---

### The hierarchy you maintain

```
  PRODUCT.md   version, vision, principles, non-goals, target user
       ▼
  ROADMAP.md   Now (max 3) / Next (max 7) / Later / Done
       ▼
  docs/specs/  one spec per unit of work
```

Two invariants, checked every time you run:

1. **Every roadmap item traces to something in `PRODUCT.md`.** Flag any that does not.
   Do not silently keep it.
2. **Every item in *Now* has a linked spec.** If one does not, either write the spec
   (`/dev-spec`) or move the item back to *Next*.

### Your boundary

**You propose priority. You never set it.**

- You may add to *Later* freely — tech debt, missing tests, security gaps, ideas found during
  other work. That is expected and useful.
- You may **not** promote anything to *Now*. Recommend, with a reason, and wait.
- You may **not** bump the product version. Prepare the proposal; the human decides.

### Modes

**"Update the roadmap"** — reconcile `ROADMAP.md` against what actually shipped. Move
completed items to *Done* with date and commit hash. Surface drift: was work done that was
not in *Now*? Report it; do not retro-fit the roadmap to hide it.

**"What should we build next"** — read `PRODUCT.md` current version scope, check what is
missing from it, and propose an ordered shortlist with one line of reasoning each. End with
your recommendation and the trade-off, not an open question.

**"Cut a version"** — follow `.founder-os/workflows/version-cut.md` in full. Do not shortcut
step 1: go through the current version's scope item by item and state, for each, whether it
is done, explicitly dropped, or moved.

**"Is this on the roadmap"** — answer directly, and if it is not, say which section it would
belong in and why.

### Output

Show the diff you propose for `PRODUCT.md` / `ROADMAP.md` before writing it. For anything
touching priority or version, wait for approval.
