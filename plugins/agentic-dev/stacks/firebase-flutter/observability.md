# Knowing what happens — analytics, errors, and the live build

Three different questions, three different mechanisms, one shared property: **each has exactly
one place in the code where it happens.** Scatter any of them across call sites and the
promise made in the privacy policy stops being checkable, the error handler stops being
complete, and the version on screen stops being trustworthy.

---

## 1. Error reporting — the first thing to build, and the one most often missing

Before it exists, an app learns about **zero** of its own failures. A user sees a red error
surface or the app freezes, and you find out only if they write to you. For a product that is
live, that is the largest blind spot there is — larger than missing analytics, because a
metric you lack is a question unanswered while a crash you never see is a user gone.

Two handlers, both required, set before the app runs:

| Handler | Catches |
|---|---|
| `FlutterError.onError` | everything the framework reports: build, layout and paint errors, failed assertions, broken images — the red surface the user sees |
| `PlatformDispatcher.instance.onError` | everything unhandled *outside* the framework: `Future` errors without a `catchError`, exceptions in timer callbacks, aborted network calls |

**`runZonedGuarded` is deliberately not a third.** Since Flutter 3.3 the platform dispatcher
covers what it used to be needed for, and wrapping the app in a guarded zone mostly adds a
way to swallow errors in the zone's own error handler.

Report through **one** function. It attaches the build id, the route, and whether the user is
signed in — never the user's data. Sample nothing at the start: at low volume, every error is
worth seeing, and a sampling rate chosen before there is traffic is a guess that hides the
first real incident.

---

## 2. The visible build id — the answer to "is the bug still there?"

Web apps are cached by a service worker. Without a visible identifier there is no way to tell
whether a tester is even running the new version, and "it's still broken for me" turns into an
afternoon of guessing.

- The build is stamped at compile time: `--dart-define=BUILD_ID=…`, read with
  `String.fromEnvironment`. **The call must be `const`** — only a constant call is replaced at
  compile time; a runtime call returns empty in a release build. This trips people up once and
  costs an hour.
- A short, unobtrusive form of it is shown in the UI (settings, or the start screen).
- The same value is written to a small file served with `Cache-Control: no-cache`, which is
  what the post-deploy verification compares against the commit — see
  [`keyless-deploy.md`](keyless-deploy.md).

One stamp, three uses: the tester can read it, the pipeline can verify it, the error report
carries it.

---

## 3. Analytics — measured in one place, gated by one condition

Structure it in three layers, and the promise in the privacy policy stays checkable at a
single point:

1. **A narrow API of named events** (`checkout_started`, `plan_generated`). Call sites use
   only the named methods. This is not decoration: it keeps naming and parameter discipline
   in one file instead of scattered across twenty.
2. **The real implementation, behind the consent gate.** Every call checks one condition.
3. **A no-op implementation** for demo and test mode, selected by the same
   `firebaseConfigured` switch as the rest of the backend. The test suite therefore never
   touches a real analytics instance.

### The finding that makes the gate real

**Disabling collection is not enough on the web.** Constructing the analytics instance pulls
in the measurement script and writes an identifier — *before* the first event is logged, and
therefore before any check runs. So when the user has objected, **no instance is constructed
at all**, and an existing one is shut down. When they have not, the first thing said to the
SDK is still "collection off", before it is turned on.

A gate that is only checked at `logEvent` is a gate with the door already open.

### Consent — say what is legally true

Opt-in and opt-out are not equivalent, and the code should not pretend otherwise. Under § 25
(1) TDDDG, storing or reading on the user's device requires **consent**; an opt-out does not
satisfy that. A founder may still choose opt-out — no consumer app wants a banner — but that
is a decision with a named owner, not a technical detail.

What the code owes that decision:

- **One condition**, referenced everywhere, so the choice can be reversed in one line.
- **The privacy policy matches the mechanism.** Opt-out means the text speaks of a right to
  object and legitimate interest, not of a consent that was never obtained.
- **An explicit refusal is never silently upgraded.** If the basis changes from opt-in to
  opt-out, someone who actively declined stays declined. Migrating a "no" into a "yes"
  because the model changed is the one move that turns a defensible decision into an
  indefensible one.

### Event hygiene

- **Never report exact amounts.** Bucket them (`lt_1k`, `1k_10k`). An exact-value field with
  ten thousand distinct values is useless in every report and a fine re-identification
  signal besides.
- **No free text, no identifiers, no content** in event parameters. Enumerations only.
- **Name the funnel before instrumenting it.** Events added ad hoc measure activity;
  events derived from a funnel measure whether the product works.

---

## 4. After the deploy — looking, systematically

A deployment that fails quietly and is discovered days later by accident is not an
exception; it is what happens by default. The loop's health check (`autonomous-loop.md`,
step 1) covers it, and on this stack that means four things, in this order:

```bash
# 1. Did the pipeline run, and did it go green?
#    (the verify job proves the live build carries the commit)

# 2. Are the functions healthy since the deploy?
firebase functions:log --only <fn> --project "$PROJECT_ID" | tail -50

# 3. Did anything change in the error reports since the deploy?

# 4. Do the rules still do what they claim?
#    (only after a rules change — run the emulator tests)
```

Checked after **every** deploy that touched functions or rules, not when something feels
wrong. "Feels wrong" arrives via a user, days late, and by then the cause is buried under
three more deploys.

---

## 5. What the user reports comes back as work

The feedback path is part of observability, not a separate feature:

- Feedback is written to its own collection, create-only, with the uid pinned — see the
  fourth rule shape in [`auth-and-data.md`](auth-and-data.md).
- It feeds the live backlog, **weighted by source** (`backlog.md`): a paying user's bug
  outranks an anonymous feature wish.
- The user is told what happened to it. That single loop — report, fix, visible result — is
  worth more than any amount of instrumentation, because it is the only channel that tells
  you *why* a number moved.
