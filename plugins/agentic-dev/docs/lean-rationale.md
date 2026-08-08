# Lean Rationale — why the rules are what they are

> **This file is never loaded into agent context.** It exists for humans who want to
> understand or challenge a rule. The rulebook itself (`knowledge/`) states decisions
> without justification — deliberately: modern models already know good engineering, so the
> rules only carry what a model cannot know: *our* choices. When a rule seems wrong, read
> its reasoning here first; if it still seems wrong, that is a learning with
> `scope: upstream`, not a silent deviation.

## The verification bottleneck

An agent produces more code in ten minutes than a human can review in ten minutes, and
wrong code looks exactly as convincing as right code. So the binding constraint of agentic
development is verification, not writing — everything in the blueprint follows from that.
"Never hand off unverified work" is rule zero because every other rule is a special case
of it.

## Why dev and QA are separate contracts

An agent that writes and approves its own code has no verification loop — it has a rubber
stamp. The same failure appears in every direction: a reviewer who repairs stops reporting
(so the human never learns what was wrong), a security reviewer with deploy credentials
*is* the lethal combination it exists to detect, and a release step an agent can trigger
for itself is not a gate. Both production systems this module was distilled from
independently converged on a two-stage dev/QA split.

## Why the QA calibration rule exists

A reviewer sent to find gaps will find gaps — even in correct work. False findings cost
more than missed style issues, because they push the team into over-engineering. Hence:
only correctness and stated-requirement findings count, every blocking finding needs a
concrete failure case, and a clean PASS is a valuable result. For the same reason the
reviewer never sees the author's reasoning: a reviewer who knows why an approach was
chosen evaluates the approach instead of the result.

## Why rules are created after incidents, never preventively

Preventive rules inflate the rulebook without preventing anything, and an inflated
rulebook stops being read — at which point the rules that do matter stop working too. If
you cannot name the incident, you cannot propose the rule. The corollary: when a rule does
not fit practice, it gets changed upstream, never quietly ignored — a rulebook that is
quietly violated manufactures the illusion of control.

## Why *Now* holds at most 3 items

More parallel work in flight produces context loss and merge conflicts, not speed. The
limit will feel wrong; that is the point — it forces the priority conversation that an
unbounded list lets everyone avoid.

## Why the deploy gate exists

Neither extreme survives contact with an agent shipping many changes a day: "everything
auto-deploys" loses human judgement exactly where it matters (money, auth, first exposure
of a feature), "a human approves everything" makes the human the bottleneck everywhere it
does not. A deterministic checklist splits the two — and because it is a checklist, its
outcomes are auditable and the human's trust in auto-ship can be earned and verified.
Loosening the gate is an ADR because it removes a human from a loop.

## Why verification is two-tier (scoped per increment, full per bundle)

One production system accumulated ~2,200 tests; running them per change made every
increment slow, so agents started skipping — the classic death of a too-expensive gate.
Scoped checks per increment keep the loop fast; the full suite once per bundle catches
cross-increment interactions; the runtime budget keeps the deep tier affordable forever.
Prefer one guard test that enforces a rule (banned API, build-flag invariant,
doc/code consistency) over ten tests that restate behaviour — guards pay rent forever.

## Why previews exist and never see production data

A preview URL lets a human judge an agent change in seconds rather than minutes — it is
the precondition for the human-gate path being cheap. Production data in a preview is how
test traffic corrupts real accounts and how personal data leaks into unprotected
environments.

## Why a bug fix starts with a failing test

A fix without a reproducing test is a guess that happens to make the symptom go away —
neither you nor the next agent can tell when it regresses. And if the fix requires
changing an existing test, either the test encoded the bug or the fix is wrong; deciding
which is the actual diagnostic work.

## Why refactors need stated friction and untouched tests

Refactoring is the work agents most enjoy producing and are least equipped to justify:
they notice structure they would have built differently and rebuild it — large diff, no
behavioural change, real regression risk, no benefit. Stated friction ("adding a payment
provider requires editing four files") filters that out. Unchanged tests are the *only*
proof that behaviour held; adjusting a test during a refactor destroys the proof.

## Why hotfixes still require the reproducing test and the postmortem

Every compressed gate in the hotfix path has been skipped by someone under pressure, and
every one of them has caused a second outage. Rolling back beats fixing because fixing
feels like progress and rollback feels like defeat — which is exactly why the decision is
forced explicitly at step 1.

## Why postmortems are blameless — including toward the agent

"The agent should have noticed" describes the failure; it is not its cause. The only
thing you can change is a gate, so the finding is always about the missing or bypassed
gate. Blame produces hidden incidents; gates produce fewer incidents.

## Why decisions carry a confidence score

Stopping for every open micro-decision makes the human the bottleneck; silently guessing
makes the agent untrustworthy. Scoring by derivation source splits the two, and the
threshold puts the dial in the human's hand. Confidence is raised by adding information
sources (design tokens, personas, analytics, ADRs) — that, not growing boldness, is how
autonomy safely increases over time. An overturned high-confidence decision is a
violation; a queued mid-confidence one is the system working.

## Why the backlog outranks the founder's feature list

Bugs beat features and improvements beat expansion because a product that gets better
retains users, and a product that gets bigger while broken loses them. Source weighting
(paying > free > anonymous) encodes churn risk. The founder's roadmap items enter under
admin weight and *wait while the product is broken* — deliberately.

## Why commit format is enforced

`repo_metrics.py` derives change-failure and rework rates from commit types; wrong types
corrupt the numbers the roadmap is steered by. One real project drifted off the format
mid-way and its history became unmeasurable — hence the hard cut at adoption day.

## Why prose rules are backed by hooks and CI

Knowledge is not compliance: a model *knows* tests must not be deleted to go green and
under pressure sometimes does it anyway. A written rule is followed most of the time;
at a hundred changes a week "most" is not enough. Hence the enforcement ladder — prose
covers everything, contracts bind roles, hooks block locally, CI blocks centrally — and
the rule of thumb: merely annoying violations stay prose; work-destroying or
security-relevant ones get a hook *and* a CI gate.

## Why the rulebook is lean

Instructions for LLMs are shrinking industry-wide because the models already contain the
knowledge; what they cannot contain is this organisation's choices. So the rulebook keeps
three things only: **policy** (locations, limits, thresholds, boundaries), **enforcement**
(hooks, gates, guard tests), and **incident-tagged rules** (things a model got wrong here,
stated tersely). Everything explanatory lives in this file, loaded by humans, never by
agents. When cutting further, cut knowledge, never policy — and never remove a rule whose
incident you cannot name as resolved.
