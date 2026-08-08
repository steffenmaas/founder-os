---
name: dev-dashboard
description: Publishes and refreshes the live development dashboard — a shareable artifact showing product version and scope progress, roadmap, backlog top items, the bundle in flight, changes waiting at the deploy gate with preview URLs, the decision queue, and the last deploys with health state. Use this skill when the user says "dashboard", "show me the roadmap", "development status", "where do I see progress" or any natural variant — and on every autonomous-loop cycle to keep the artifact current. Module 16 (Agentic Dev) — Product & Tech Delivery. Pre-Seed.
---

# Development dashboard

This skill is part of the **Founder OS** plugin, Module 16 — Agentic Dev (Product & Tech Delivery).

> The founder should never have to ask "where are we?" — the answer is a URL that is always
> current. The dashboard is a published artifact: private by default, shareable by the
> founder, **republished to the same URL** every time so the link never changes.

## When to trigger

- The user says "dashboard", "show me the roadmap", "development status", "where do I see
  progress", or any natural variant.
- **Every cycle of the autonomous loop** (step 9, LEARN + RE-ARM) — the loop refreshes the
  dashboard as part of closing the cycle. A dashboard older than the last shipped change is
  a bug.
- After a deploy-gate event: something new is waiting for approval, or an approval landed.

## What it shows — in this order

The dashboard is operated top-down by one person in ten seconds. Needs-you-first:

1. **Waiting on you** — changes parked at the deploy gate: what, which checklist line gated
   it, the **preview URL**, and the rollback plan. Plus the decision queue (harness §5):
   question, options, recommendation, confidence. If both are empty, say exactly that.
2. **Now** — the bundle in flight: its items, each increment's state
   (building / verified / shipped), and what the loop does next.
3. **Version progress** — current product version from `PRODUCT.md`, its scope items each
   marked done / in progress / open. One glance answers "how far is this version?".
4. **Roadmap & backlog** — Now / Next from `ROADMAP.md`, and the top 5 backlog items with
   type and source (the weighting visible: a paying user's bug shows as exactly that).
5. **Shipped** — the last ~10 ships with date, one-line description, auto-ship vs approved,
   and deploy health (landed + healthy, per the post-deploy checks).
6. **Signals** — full-suite runtime vs budget, coverage trend, open learnings, unsubmitted
   upstream learnings, last UX-audit trend (better / worse / not run).

## How to build it

1. **Gather** from the primary sources — never from memory: `PRODUCT.md`, `ROADMAP.md`, the
   backlog store (per `project-config.json` → `backlog.store`), `docs/decisions/QUEUE.md`,
   `git log` since the last refresh, CI/deploy state, open PRs with preview URLs.
2. **Render** one self-contained HTML file (no external resources — CSP blocks them).
   Light and dark theme via tokens. State encoded in form, not only color: chips for
   done / in flight / waiting / blocked. Timestamps in the founder's timezone, plus a
   "generated at" line — a dashboard must show its own age.
3. **Publish** with the Artifact tool. **Always the same file path** (e.g.
   `dashboard.html` in the session workspace) so it redeploys to the same URL — a new URL
   per refresh breaks the founder's bookmark. Keep the same favicon across refreshes.
4. First publication: hand the URL to the user once, and record it in `CLAUDE.md` under
   "Where things are" so every future session refreshes the same artifact
   (`url:` parameter) instead of minting a new one.

## Rules

1. **Evidence, not adjectives.** Every "shipped" links a commit; every "healthy" names the
   check that said so; every "green" is a pipeline run, not an assumption.
2. **The gaps are content.** Not verified, not run, budget exceeded — the dashboard shows
   them. A dashboard that only ever shows green teaches the founder to stop reading it.
3. **Read-only.** The dashboard displays state; it never mutates the backlog, the roadmap,
   or the queue. Acting on what it shows happens through the normal skills.
4. **No secrets, no personal user data.** The artifact may be shared onward — build it so
   that sharing it is always safe: aggregate feedback counts, never quote a user's message
   with identifying detail.
