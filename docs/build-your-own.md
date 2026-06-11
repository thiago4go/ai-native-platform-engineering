# Build Your Own Version

Use this repo as a template for your own AI-native platform demo.

## First 90 Days

Do not start with a disconnected AI experiment. Start with one platform workflow that teams already care about and make it a governed platform product.

Good candidates:

- incident triage
- service onboarding
- production readiness review
- dependency upgrades
- compliance evidence collection

Build the smallest useful AI-native platform loop around it:

```text
1. Catalog the capability.
2. Write the SKILL.md or equivalent procedure.
3. Define the allowed tool contract.
4. Route model traffic through a governed path.
5. Add one eval gate.
6. Emit telemetry.
7. Record replayable evidence.
8. Name the accountable human or team.
```

The goal is not to prove that an agent can do something impressive once. The goal is to prove the platform can make agentic work repeatable, observable, and governable.

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
- on-device agentgateway listening on your chosen local port
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

## 7. Standardize The Right Things

The first capability every enterprise should standardize is the agent tool contract. Whether you use MCP or another interface, the platform needs a clear way to say:

```text
this agent can call these tools
with this identity
under this policy
through this model route
with this evidence
```

Avoid two common traps:

- treating the developer portal as the platform
- giving agents broad tools and hoping prompts will create governance

The portal is the front door. The platform is the engine. Agents should receive governed paths, not vague power.

## 8. Measure The Control Loop

A useful metric is evidence-covered execution:

```text
For important workflows, what percentage of agent-assisted actions have:
skill + tools + route + eval + telemetry + evidence + accountable owner?
```

This metric is better than counting prompts, agents, or demos. It tells you whether AI-assisted work is becoming part of the platform operating model.

Over the next year, platform teams will increasingly become the control plane for enterprise AI execution. The best teams will not only provide infrastructure. They will provide governed paths for humans and agents to work together safely.
