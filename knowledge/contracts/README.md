# Agent Contracts

Each contract defines **one role**: mandate, required inputs, required outputs, allowed
tools, hard boundaries, definition of done, and escalation path.

An agent works under **exactly one contract at a time**. Read your contract before you start.
If you are asked to do something outside it, say so instead of doing it.

| Contract | Role | Invoked by | The boundary that matters |
|---|---|---|---|
| [`product-agent.md`](product-agent.md) | Product, roadmap, specs | `/dev-product`, `/dev-spec` | Proposes priority, never sets it |
| [`dev-agent.md`](dev-agent.md) | Writes production code | `/dev-loop` | Never approves or merges its own work |
| [`qa-agent.md`](qa-agent.md) | Verifies and reviews | `/dev-review` | Never fixes what it finds |
| [`security-agent.md`](security-agent.md) | Security review | `/dev-security` | Never holds deploy credentials |
| [`release-agent.md`](release-agent.md) | Ships to production | `/dev-ship` | Human-invoked only |

## Why the separation exists

**Dev and QA are separate contracts because an agent that writes and approves its own code
has no verification loop — it has a rubber stamp.** Everything else in this module is
downstream of that one structural decision.

The same logic gives the other three their boundaries:

- **QA does not fix.** A reviewer that repairs stops reporting, and the human never learns
  what was wrong.
- **Security holds no credentials.** A security reviewer with production access *is* the
  lethal combination it exists to detect: sensitive access, untrusted input, outbound channel.
- **Release is human-invoked.** No agent decides on its own that now is a good moment to
  deploy.
- **Product proposes, humans prioritise.** Priority is a business decision, and it is the one
  thing an agent has no information to make well.

## Enforcement

Contracts are prose — they bind by being read. Three of the boundaries are additionally
enforced mechanically, because prose is not enough at volume:

| Boundary | Mechanism |
|---|---|
| QA and Security cannot write files | Subagent `tools:` restriction (`Read, Grep, Glob, Bash` only) |
| No local deploys, no force-push to `main`, no `--no-verify` | `hooks/scripts/guard-bash.sh`, exit code 2 |
| Release is human-invoked | `disable-model-invocation: true` in the skill frontmatter |

## Changing a contract

Contracts live upstream in the Founder OS module and are **read-only in a project**. If a
contract does not fit reality, that is a learning with `scope: upstream` — see blueprint §9.3.
Never edit `.founder-os/` locally; the next update overwrites it.
