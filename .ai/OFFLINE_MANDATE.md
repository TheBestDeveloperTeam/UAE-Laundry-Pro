# OFFLINE MANDATE â€” LaundryPro UAE
> **Version:** 1.0.0 | **Authority:** ABSOLUTE | **Override:** NONE
> **Last Updated:** 2026-09-21

## CRITICAL RULE â€” READ FIRST

> [!CAUTION]
> This system operates **100% offline, 100% local, 100% without tokens, 100% without cloud AI**.
> Every agent, bot, leader, department, protocol, and workflow in this ecosystem is a
> **local Markdown-driven instruction set** â€” NOT a cloud API call.

## What "Agent" Means Here
An agent in LaundryPro UAE is a **structured Markdown file** that defines:
- A role, responsibilities, and decision matrix
- Knowledge domains (references to other local .md files)
- Trigger conditions (pattern matching on the user's prompt)
- Escalation paths (references to other local .md files)

Agents are **activated by the ORCHESTRATOR** reading local files and injecting their
content into the working context. No API calls. No tokens. No cloud. No internet.

## What "Bot" Means Here
A bot is a **passive validation rule set** defined in a local .md file. During the
ORCHESTRATOR's Bot Sweep step, the rules are checked against the current output.
No API calls. No external services. No runtime cost.

## Absolute Rules
1. **ZERO external API calls** for agent/bot operation.
2. **ZERO cloud tokens** (no OpenAI, Anthropic, Google, or any LLM API keys).
3. **ZERO internet requirement** for any agent, bot, or protocol execution.
4. **ALL context** comes from local .ai/ Markdown files on disk.
5. **ALL memory** persists to local .ai/memory/ Markdown files on disk.
6. **ALL logs** append to local .ai/logs/ Markdown files on disk.
7. **ALL knowledge** is embedded in local .ai/knowledge/ Markdown files.
8. The sync engine syncs **application data** (orders, customers, invoices), NOT agent state.
9. Agent definitions are **version-controlled in Git** alongside source code.
10. Any AI assistant (Copilot, Gemini, Claude, etc.) reads these files as context â€” it does not call external services to run agents.

## How It Works at Runtime
```
User types prompt in IDE
       |
IDE AI assistant reads .ai/ORCHESTRATOR.md
       |
ORCHESTRATOR activates agents by READING their .md files
       |
Agent context is INJECTED from local .md knowledge files
       |
Bots VALIDATE output by checking rules from local .md files
       |
Memory PERSISTS by appending to local .md memory files
       |
Response returned to user â€” ZERO external calls made
```

## Enforcement
- Every agent file includes: `## Context Injection Contract` pointing to LOCAL files only.
- Every bot file includes: rules that reference LOCAL patterns only.
- The ORCHESTRATOR never makes HTTP calls, API calls, or network requests.
- Violation of this mandate triggers CRITICAL alert to CEO and CTO.

## Change Log
| Version | Date | Change |
|---------|------|--------|
| 1.0.0 | 2026-09-21 | Established absolute offline mandate |