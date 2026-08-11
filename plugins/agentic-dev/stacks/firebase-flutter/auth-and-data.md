# Identity and data — Auth, Firestore, Storage

On this stack the client talks to the database **directly**. There is no server in between
filtering what comes back. That is what makes it fast to build, and it means the security
rules are not a configuration detail — they *are* the authorisation layer. Everything below
follows from that one fact.

---

## Authentication

**Anonymous first, linked later.** A new visitor is signed in anonymously on first open, so
they can use the product before deciding to register. When they later create an account, the
anonymous identity is *linked* rather than replaced — the uid stays the same, and with it
every document already written under it. Getting this the other way round means a data
migration on the day someone signs up, and losing a user's work at the exact moment they
committed to the product.

**One switch between the real backend and no backend.** A single provider
(`firebaseConfigured`) decides whether the app builds real Firebase repositories or inert
ones:

| Provider | When `firebaseConfigured` is true | When it is false |
|---|---|---|
| Auth | real `firebase_auth` | in-memory identity |
| Persistence | Firestore repository | local repository |
| Payments | callable-backed repository | unavailable repository |
| Analytics | real sink, behind the consent gate | no-op |

Two things this buys, both larger than they look:

1. **The test suite never touches a real Firebase instance** — no emulator required for unit
   and widget tests, no credentials in CI, no flakiness from the network.
2. **The product is demonstrable before the backend exists.** Onboarding, first-run flows
   and screenshots do not wait for a project to be provisioned.

The switch is one provider, checked in the repository constructors and nowhere else. Scatter
the check across call sites and it stops being a switch.

**Re-authentication.** Sensitive operations (delete account, change e-mail) fail with
`requires-recent-login` after a while. The UI must obtain a fresh sign-in **before** starting
the operation, not catch the error halfway through — see the deletion ordering in
[`going-live.md`](going-live.md).

---

## Firestore rules — the doctrine

Rules are deployed from the repository (`firebase deploy --only firestore:rules`), reviewed
in the diff, and never edited in the console. A console edit is a production change with no
author, no review and no history.

**Default deny.** Every collection is matched explicitly. An unmatched path is inaccessible,
which is the correct behaviour for a collection someone adds and forgets to protect.

### The four shapes, and when to use which

**1. Owner-only** — the default for user data.

```
match /users/{uid} {
  allow read, write: if request.auth != null && request.auth.uid == uid;
}
```

**2. Server truth — readable, never writable.** For anything the user must not be able to
grant themselves: entitlements, credits, quotas, roles, plans generated on the server.

```
match /entitlements/{uid} {
  allow read:  if request.auth != null && request.auth.uid == uid;
  allow write: if false;
}
```

`write: if false` looks absolute and is meant to be. The Admin SDK, which Cloud Functions
use, **bypasses rules entirely** — so the server can still write while no client can.
Without this line the whole payment path is a facade: a signed-in user grants themselves
everything with a single `set()`, and no amount of server-side checkout logic matters.

**3. Field-level** — the client owns the document but not every field in it.

```
function noServerFields() {
  return !request.resource.data
    .diff(resource.data).affectedKeys()
    .hasAny(['premium', 'quota', 'role']);
}
match /users/{uid} {
  allow update: if owner(uid) && noServerFields();
}
```

Use this when splitting the server-owned fields into their own document would be worse than
the rule. Keep the field list short; a long list is a document that wants to be two.

**4. Create-only with a fixed initial state** — user submissions that the server then
processes.

```
match /feedback/{id} {
  allow create: if request.auth != null
    && request.resource.data.uid == request.auth.uid
    && request.resource.data.status == 'new';
  allow read:   if request.auth != null && resource.data.uid == request.auth.uid;
  allow update, delete: if false;
}
```

Pinning `status == 'new'` on create is what stops a user filing feedback that is already
marked as handled. Forbidding update and delete is what makes the record trustworthy enough
to feed the backlog.

**Purely server-side collections** — idempotency markers, payment records, audit trails —
get `allow read, write: if false`. Not readable either: a client that can read the payment
event log can enumerate other people's purchases.

### Rules conventions

- **Named helper functions** (`signedIn()`, `owner(uid)`) at the top. Rules repeat
  themselves fast, and a copied condition is where the one missing `uid` check lives.
- **A rules change is a security change.** It goes through `/dev-security`, every time, even
  when the diff is one line — one line is the whole attack surface here.
- **Test the rules, do not read them.** The emulator runs them against real requests:
  ```bash
  firebase emulators:start --only firestore,auth
  ```
  Two cases per rule are enough and worth their runtime forever: the owner succeeds, a
  different signed-in user fails. The second case is the one that catches the regression.
- **Indexes live in `firestore.indexes.json`** and deploy with everything else. An index
  clicked together in the console exists in production and nowhere else — the next
  environment gets a query that fails only under load.

---

## Storage

Same identity, same model, and the rules mirror the database:

```
match /users/{uid}/{allPaths=**} {
  allow read, write: if request.auth != null && request.auth.uid == uid;
}
match /public/{allPaths=**} {
  allow read:  if true;
  allow write: if false;
}
```

Two rules that are easy to get wrong:

- **Uploads are constrained by size and type in the rules**, not only in the picker.
  `request.resource.size < 5 * 1024 * 1024 && request.resource.contentType.matches('image/.*')`
  — the client-side picker is a convenience, not a control.
- **Public means public.** A download URL is unguessable but permanent and unauthenticated;
  it is a link anyone can forward. Anything that must not leave the account goes under the
  per-user path and is read through the SDK, never through a shared URL.

---

## Data-model conventions

- **The uid is the document id** for per-user documents. No lookup, no second source of
  truth about who owns what, and the rule reads as `request.auth.uid == uid`.
- **Money is integer minor units.** Never a float, never a formatted string in the database.
- **Timestamps are server timestamps** (`FieldValue.serverTimestamp()`). A client clock is
  an input, not a fact.
- **Subcollections for unbounded lists**, fields for bounded ones. A document that grows
  without limit hits the size cap in production, on the user who liked the product most.
- **Writes that must happen together happen in one transaction.** Two sequential writes are
  two writes, and the gap between them is where the crash occurs — see the grant and its
  purchase record in [`payments.md`](payments.md).

---

## Local development

```bash
firebase emulators:start --only firestore,auth,functions,storage
```

The emulator suite is the only honest way to develop rules and functions. What it does not
cover: real Auth providers, real payment webhooks, and anything that depends on the deployed
region. Those are verified against the preview environment, never against production.
