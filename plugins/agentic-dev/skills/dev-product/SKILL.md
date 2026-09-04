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

Current state: !`head -5 PRODUCT.md 2>/dev/null; echo '---'; grep -E '^- \\[ \\] \\*\\*[FBT][0-9]' ROADMAP.md 2>/dev/null | head -12`
Recent work: !`git log --oneline -15 2>/dev/null`

---

### The hierarchy you maintain

```
  PRODUCT.md   version, vision, principles, non-goals, target user
       ▼
  ROADMAP.md   ONE ordered list of packages — F/B/T ids, position = priority
       ▼
  docs/specs/  one spec per package, file named after its id (F001-<slug>.md)
```

Three invariants, checked every time you run:

1. **Every package traces to something in `PRODUCT.md`.** Flag any that does not.
   Do not silently keep it.
2. **The top package has a spec.** If not, writing the spec is that package's first
   increment — never a reason to skip past it to something easier.
3. **Ids follow the roadmap's rules:** one prefix per package (a defect and an extension
   are two packages), numbers never reused or renumbered, id in the package name and the
   PR title.

### Your boundary

**You re-order freely; an order the founder set, you never override.**

- You may append packages and fold intake into existing ones freely — tech debt, missing
  tests, security gaps, ideas found during other work become `T`/`B` packages or join one.
- You may re-order per the backlog doctrine, in the commit that changes the file. You may
  **not** override an order the founder set by saying so. There, recommend with a reason,
  and wait.
- You may **not** bump the product version. Prepare the proposal; the human decides.

### Modes

**"Update the roadmap"** — reconcile `ROADMAP.md` against what actually shipped. A shipped
package **leaves the file** — its record is the release note, the roadmap describes only
the future. Surface drift: was work merged that belongs to no package? Report it; do not
retro-fit the roadmap to hide it. (The reconciliation belongs in the PR that ships the
change, not in a cleanup afterwards.)

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
