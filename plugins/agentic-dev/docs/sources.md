# Sources

Basis for the recommendations in the blueprint, the harness, the contracts and the workflows.
Research current as of August 2026.

---

## Agentic development — practice and patterns

- Anthropic — *Best practices for Claude Code*
  https://code.claude.com/docs/en/best-practices
  → verification loop, explore/plan/implement/commit, context hygiene, failure patterns
- Anthropic — *Building Effective AI Agents*
  https://www.anthropic.com/engineering/building-effective-agents
  → orchestrator-worker, routing, evaluator-optimizer; "add complexity only when it
    demonstrably improves outcomes"
- Anthropic — *How we built our multi-agent research system*
  https://www.anthropic.com/engineering/multi-agent-research-system
  → scaling by task complexity, token cost of multi-agent setups, observability
- Anthropic — *When to use multi-agent systems (and when not to)*
  https://claude.com/blog/building-multi-agent-systems-when-and-how-to-use-them
- Anthropic — *How Claude Code is used in practice*
  https://www.anthropic.com/research/claude-code-expertise
- Martin Fowler — *Agentic Programming*
  https://martinfowler.spicytakes.org/post/2026-05-21-AgenticProgramming
- The Pragmatic Engineer — *TDD, AI agents and coding with Kent Beck*
  https://newsletter.pragmaticengineer.com/p/tdd-ai-agents-and-coding-with-kent
  → tests as the guard layer; the documented pattern of agents deleting tests to make them pass

## Spec-driven development

- GitHub — *Spec Kit* (Specify → Plan → Tasks → Implement)
  https://github.com/github/spec-kit · https://github.github.com/spec-kit/
- GitHub Blog — *Spec-driven development with AI*
  https://github.blog/ai-and-ml/generative-ai/spec-driven-development-with-ai-get-started-with-a-new-open-source-toolkit/
  → "Language models are exceptional at pattern completion, but not at mind reading"

## Delivery performance, metrics, impact

- DORA — *State of AI-assisted Software Development 2025*
  https://dora.dev/dora-report-2025/
  → AI acts as an amplifier of existing organisational strengths and weaknesses
- DORA — *AI Capabilities Model*
  https://dora.dev/ai/capabilities-model/report/
  → including "strong version control practices" and "working in small batches"
- Swarmia — *DORA change failure rate — what, why, and how*
  https://www.swarmia.com/blog/dora-change-failure-rate/
  → calculation and common measurement errors; basis for the proxy in `repo_metrics.py`
- METR — *Measuring the Impact of Early-2025 AI on Experienced Open-Source Developer Productivity*
  https://metr.org/blog/2025-07-10-early-2025-ai-experienced-os-dev-study/
  → slowdown among experienced developers in large familiar codebases; the gap between
    perceived and measured speed
- METR — *We are Changing our Developer Productivity Experiment Design* (Feb 2026)
  https://metr.org/blog/2026-02-24-uplift-update/
  → important caveat: the result above applies to a specific setup and does not generalise
    unexamined
- GitClear — analysis of code churn and copy-paste share (summary)
  https://www.jonas.rs/2025/02/09/report-summary-gitclear-ai-code-quality-research-2025.html
  → basis for rework rate as the agent-specific metric

## Security

- Simon Willison — *The lethal trifecta for AI agents*
  https://simonwillison.net/2025/Jun/16/the-lethal-trifecta/
  → sensitive data + untrusted content + outbound channel; no reliable filter exists
- Anthropic — *How we contain Claude across products*
  https://www.anthropic.com/engineering/how-we-contain-claude
  → environment level before model level, tiered permissions, approval fatigue
- OWASP GenAI — *LLM Top 10*
  https://genai.owasp.org/resource/owasp-genai-llm-top-10-2026/
  → in particular LLM01 prompt injection and LLM06 excessive agency

## Claude Code building blocks

- Skills — https://code.claude.com/docs/en/skills
- Subagents — https://code.claude.com/docs/en/sub-agents
- Hooks — https://code.claude.com/docs/en/hooks
- Plugins — https://code.claude.com/docs/en/plugins
- Plugin marketplaces — https://code.claude.com/docs/en/plugin-marketplaces
- Memory / CLAUDE.md / AGENTS.md — https://code.claude.com/docs/en/memory
- Headless — https://code.claude.com/docs/en/headless
- MCP — https://code.claude.com/docs/en/mcp
- Official plugins — https://github.com/anthropics/claude-plugins-official
- GitHub Action — https://github.com/anthropics/claude-code-action

## Existing frameworks reviewed

| Project | URL | Verdict |
|---|---|---|
| GitHub Spec Kit | https://github.com/github/spec-kit | Pattern adopted for the spec phase |
| BMAD-METHOD | https://github.com/bmad-code-org/BMAD-METHOD | Role idea informed the contracts; toolchain not adopted |
| Agent-OS | https://github.com/buildermethods/agent-os | Standards-discovery idea informed the harness |
| wshobson/agents | https://github.com/wshobson/agents | Granularity principle adopted |
| wshobson/commands | https://github.com/wshobson/commands | Workflow/tool separation adopted |
| awesome-claude-code | https://github.com/hesreallyhim/awesome-claude-code | Used as a catalogue |
| claude-code-templates | https://github.com/davila7/claude-code-templates | Used as an idea source |
| SuperClaude Framework | https://github.com/SuperClaude-Org/SuperClaude_Framework | Too heavy for this purpose |
| ruflo (ex claude-flow) | https://github.com/ruvnet/ruflo | Solves a different problem |

**Deliberate decision:** none of these is a runtime dependency. They all build on the same
three primitives (skills, subagents, hooks) and add a naming convention, roles, and a phased
workflow. Those three ideas are implemented here directly with native building blocks — no
extra toolchain to maintain.

The structural and naming conventions follow the existing **fund-os** plugin by Ocean One
Ventures: plugin manifest shape, skill front matter, description format with trigger list and
phase tag, and the `knowledge/` and `preferences/` directories.

## Other

- agents.md — https://agents.md
- github/github-mcp-server — https://github.com/github/github-mcp-server
- microsoft/playwright-mcp — https://github.com/microsoft/playwright-mcp
- Vercel — *Flags optimized for agents* — https://vercel.com/changelog/vercel-flags-are-now-optimized-for-agents
