# Workflow — Dependency Update

**Use when:** adding a new dependency, or upgrading an existing one.
**Entry:** `/dev-loop` for a manual change; Dependabot PRs enter at step 4.

---

## Adding a new dependency

| # | Who | What | Gate |
|---|---|---|---|
| 1 | Dev | **JUSTIFY** — why not write it yourself? Per harness §2: never adopt for something you can write in under 30 lines and fully test. | The justification survives that test. |
| 2 | Dev | **EVALUATE** — age, last release, maintainer count, weekly downloads, transitive dependency count, licence, known CVEs. | No red flags. Licence compatible. |
| 3 | Security | **SUPPLY CHAIN** — is this the package you think it is? Check name for typosquatting, check install scripts, check who publishes it. | Clean. |
| 4 | Dev | **ADD** — pinned version, lockfile committed, justification in the commit body. | `npm audit --audit-level=high` clean. |
| 5 | QA | **VERIFY** — full chain plus build size delta. | All green. Size delta noted. |
| 6 | Release | **SHIP** | Health watch clean. |

**A dependency added without step 1 and step 2 documented in the commit body is a contract
violation.** The commit body is where the next agent — or the next auditor — finds out why
this is here.

---

## Upgrading an existing dependency

| # | Who | What | Gate |
|---|---|---|---|
| 1 | Dev | **CLASSIFY** — patch, minor, or major? Security-driven or routine? | — |
| 2 | Dev | **READ THE CHANGELOG.** For majors, read the migration guide fully before touching anything. | Breaking changes identified and listed. |
| 3 | Dev | **UPGRADE** — one dependency per commit for majors. Patches and minors may be grouped. | Lockfile committed. |
| 4 | Dev | **VERIFY** — full chain. **Test files unchanged** unless the changelog explicitly requires it — and then, the commit body says which change and why. | All green. |
| 5 | QA | **REVIEW** — for majors: has behaviour changed anywhere the changelog warned about? | No behavioural surprise. |
| 6 | Release | **SHIP** | Health watch clean. |

---

## Security-driven upgrades

A High or Critical CVE in a production dependency **jumps the queue** — it goes to *Now*
regardless of what is there.

If no fixed version exists: pin, document the exposure in `docs/learnings/` with
`area: security` and `severity: high`, and add the mitigation to `ROADMAP.md` → *Next*. Do
not leave it undocumented because there is no immediate fix.

---

## Dependabot PRs

They enter at step 4. They are not exempt from review, and they are not exempt from the
verification chain. A grouped patch/minor PR with a green pipeline can be merged with a light
review; **any major version bump goes through the full upgrade path above.**

The `dependabot.yml` in the templates groups patch and minor deliberately, so that routine
updates are one PR per week instead of eleven — reviewer attention is the scarce resource.
