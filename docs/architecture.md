# Architecture

This repository demonstrates the control loop for AI-native platform engineering.

```text
Platform catalog
        |
        v
SKILL.md procedure ---- allowed tools ----> MCP server
        |                                  |-- platform.get_context
        |                                  |-- platform.get_eval_results
        |                                  '-- platform.record_evidence
        v
Agent runtime ---- model route proof ----> governed route ----> model backend
        |
        '-- proof: MCP trace + route metrics + eval + evidence SHA
```

## Components

| Component | Purpose |
|---|---|
| Catalog | Platform-owned capability state |
| `SKILL.md` | Repeatable operating procedure for the agent |
| MCP server | Scoped tool boundary |
| Model route | Place to enforce route ownership, policy, and telemetry |
| Eval | Gate that decides whether action can proceed |
| Evidence ledger | Replayable proof of what happened |

## Why This Matters

Without a platform path, teams tend to give agents raw tools, copied prompts, broad credentials, and private API keys.

With a platform path, the agent operates through explicit contracts:

```text
intent -> skill -> scoped tools -> route -> eval -> evidence -> accountable human
```

