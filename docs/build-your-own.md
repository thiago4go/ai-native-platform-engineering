# Build Your Own Version

Use this repo as a template for your own AI-native platform demo.

## 1. Change The Capability

Edit:

```text
catalog/governed-incident-assistant.json
```

Replace:

- project name
- capability owner
- accountable owner
- route name
- backend name
- eval suite

## 2. Change The Skill

Edit:

```text
skills/publish-governed-incident-assistant/SKILL.md
```

Keep these sections explicit:

- autonomy ceiling
- required MCP tools
- blocked actions
- procedure
- stop rules

## 3. Add Or Change MCP Tools

Edit:

```text
mcp/platform-context-server.mjs
```

Add tools only when they represent a real platform contract. Avoid turning MCP into raw shell access.

Good tool shapes:

- read platform context
- read policy/eval result
- create evidence
- request approval
- open a change proposal

Risky tool shapes:

- unrestricted shell
- direct production mutation
- secret reads
- unbounded network access

## 4. Decide What Counts As Evidence

This demo writes JSON evidence records and a JSONL ledger.

For a production platform, evidence should include:

- actor identity
- skill version
- tool calls
- input/output policy result
- model route
- eval result
- approval decision
- accountable human or team
- digest or signature

## 5. Swap In Real Infrastructure

The default demo is local. You can replace pieces gradually:

| Local demo piece | Production-like replacement |
|---|---|
| JSON catalog | service catalog or developer portal |
| Local MCP server | platform MCP service |
| Local route proof | agentgateway, Envoy AI Gateway, or your model gateway |
| JSON eval | eval service |
| JSONL evidence ledger | audit log, GRC system, or signed evidence store |

## 6. Add The Cluster + Device Split

To reproduce the talk topology, split responsibilities:

Cluster/platform side:

- service catalog or developer portal
- skill registry
- central route/control-plane config
- eval service
- telemetry and evidence store

Developer device/dev-edge side:

- Claude Code
- demo MCP server or remote platform MCP endpoint
- on-device agentgateway listening on `127.0.0.1:4010`
- model credentials routed through the gateway

The important behavior is:

```text
cluster owns route intent
device runs agent runtime
MCP scopes tools
gateway carries model traffic
evidence records what happened
```

See [full-topology.md](full-topology.md).
