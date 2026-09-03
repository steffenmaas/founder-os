# Going live — what has to exist before the product is public

Building it and publishing it are different projects. This is the second one: the work that
is invisible while you develop and blocking on the day you launch. Most of it cannot be done
in an afternoon, and none of it can be done by an agent alone — it involves legal text,
billing details and store accounts.

Treat this as a checklist with owners, not as documentation.

---

## 1. The legal pages — a public product in the EU cannot skip these

Served by the marketing hosting target, reachable from inside the app, and linked from the
store listing:

| Page | Must contain |
|---|---|
| **Imprint** | Provider identification per § 5 DDG: legal entity, address, contact, register and VAT id where applicable |
| **Privacy policy** | Every category of data, the legal basis, retention, processors (Google/Firebase, payment provider, any AI provider), international transfers, and the user's rights |
| **Terms** | What is sold, what is owed, what is not. Also registered in the payment provider's dashboard so it appears at checkout |
| **Right of withdrawal** | Withdrawal terms, and how immediate delivery of digital content interacts with them |

Two rules that make these survive contact with reality:

- **The privacy policy describes the mechanism that is actually in the code**, not the one you
  intended. If measurement runs on opt-out, the text says right to object and legitimate
  interest — not consent. See [`observability.md`](observability.md).
- **Retention exceptions are named.** Purchase records outlive account deletion for tax and
  chargeback reasons; the policy has to say so, or the deletion feature contradicts it.

Everything the app collects is derived from **one inventory**, and that inventory feeds the
privacy policy, the Apple App Privacy form and the Google Data Safety form. Three documents,
one source — otherwise they drift and the store review catches it.

---

## 2. Account deletion — required, and easy to get wrong

Both app stores require an in-app deletion path when the app supports account creation. On
this stack:

1. A **callable function** deletes the user's documents (`users/{uid}` and its subcollections,
   any per-user root documents, their own submissions) and their Storage prefix. The client
   cannot do this itself — the rules forbid touching server-truth documents, which is exactly
   the point.
2. **Then** the auth record is deleted.

**The order matters and is not interchangeable.** Delete the auth record first and the
remaining documents become orphans that nothing can reach — including you, when a user later
asks whether their data is gone. If Firebase demands a fresh sign-in, the UI obtains it
**before** step 1, not between the two steps.

**What is deliberately kept:** payment records, for retention and chargeback attribution.
Say it in the confirmation dialog as well as in the policy. A user who is told is not
surprised; a user who finds out later files a complaint.

---

## 3. The web app itself

- **Caching headers are explicit** in `firebase.json` — `index.html`, the Flutter bootstrap,
  the service worker and the version file must not be cached. Get this wrong and users keep
  running the old app after every deploy, and their bug reports describe a version that no
  longer exists.
- **The service worker updates without a hard refresh.** Test the upgrade path, not just the
  first load: open the old version, deploy, reload once, confirm the new build id.
- **The build id is visible in the UI** — see [`observability.md`](observability.md).
- **Offline and slow-network behaviour** is decided deliberately, even if the decision is "the
  app requires a connection and says so".
- **Deep links resolve.** Every route reachable by URL must survive a cold load; the Hosting
  rewrite to `index.html` is what makes that work.
- **Web manifest and icons** complete, so the app is installable and looks right when it is.

---

## 4. Before the first public deploy

```
[ ] Error reporting live and verified with a deliberate test error
[ ] Post-deploy verification green — the live build carries the commit
[ ] Security rules reviewed via /dev-security, emulator tests for owner + non-owner
[ ] Payment path exercised end to end in test mode, including the webhook
[ ] Legal pages published and linked from inside the app
[ ] Account deletion works, in the correct order
[ ] Feedback path reaches the backlog, and the user gets an answer
[ ] Secrets in Secret Manager only — nothing in the repo, nothing in the workflow
[ ] Analytics gate verified: after objecting, nothing is measured and no instance is built
[ ] Rollback rehearsed once against the preview channel — deploy a previous version and
    verify it serves. The most-needed path under pressure is the least-practised one.
[ ] Backups on AND restored once into a scratch database (stage-access.md — a backup that
    has never been restored is a wish)
[ ] Stage dial flipped: `stage: live` — self-served IAM repair off, full deploy-gate checklist on
[ ] Billing alert set on the cloud project
```

The last one is not paperwork. A recursive Firestore trigger or a runaway function is a
four-figure invoice before anyone notices, and the notice is the invoice.

---

## 5. App store submission

The web build ships first; the stores follow. What they need beyond the binary:

- **App identity** — final name, bundle id, developer account. The bundle id cannot be
  changed after the first submission.
- **Data collection forms** — Apple App Privacy and Google Data Safety, derived from the same
  inventory as the privacy policy.
- **Age rating** — answered honestly. Payments, user-generated content and external links all
  affect it.
- **In-app purchases** — the store SKUs. Note that store IAP and a web payment provider are
  **different products with different rules**; a web checkout inside an iOS app is a
  rejection, and the entitlement model has to serve both without the client deciding.
- **Sign in with Apple** — required as soon as any third-party sign-in is offered.
- **Store listing** — screenshots per device class, description, keywords, support URL.

Budget review time. The first submission is rejected more often than not, usually for the
privacy form or a missing deletion path — the two items above that look like paperwork.

---

## 6. After launch, the loop changes shape

The deploy gate (`deploy-gate.md`) gets stricter the moment real users exist: what auto-shipped
before now needs a preview for anything touching payment, authentication or data deletion.
The backlog re-weights itself around real reports, and the first genuine user bug outranks the
whole feature list.

Two habits worth starting on day one:

- **Watch the first hour after every deploy** — logs, error reports, the version marker. Not
  because something usually breaks, but because the one time it does, an hour of exposure and
  three days of exposure are different incidents.
- **Answer the people who write to you.** On this stack the feedback path is already wired
  into the backlog; the part that is not automatic is telling the user what happened. It is
  the cheapest retention work available and the only channel that explains *why* a number moved.
