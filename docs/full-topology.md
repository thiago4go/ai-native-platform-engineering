# Full Topology: Cluster + Device

The standalone demo runs anywhere. The full talk architecture adds a cluster/platform side and an on-device/dev-edge side.

## Architecture

```text
Cluster / platform side
  [Platform catalog / portal]
  [Skill registry + policy]
  [Central agentgateway control plane]
  [Eval service]
  [Telemetry + evidence store]
             |
             | route and policy pushed to dev edge
             v
Developer device / dev edge
  [Claude Code]
  [Demo MCP server or remote platform MCP]
  [on-device agentgateway :4010]
             |
             v
  [Model backend]
```

## What Runs Where

| Surface | In the standalone repo | In the full topology |
|---|---|---|
| Platform catalog | `catalog/governed-incident-assistant.json` | portal/service catalog such as OpenChoreo or Backstage |
| Skill | `skills/.../SKILL.md` | skill registry or repo-backed skill package |
| MCP | `mcp/platform-context-server.mjs` | local demo MCP or remote platform MCP service |
| Cluster agentgateway | documented only | route/control-plane owner in Kubernetes |
| Device agentgateway | route proof JSON | local data plane on `127.0.0.1:4010` |
| Telemetry | generated route metrics JSON | Prometheus/OTel/Grafana |
| Evidence | JSON + JSONL ledger | audit log, GRC system, signed evidence store |

## Build Order

1. Run the standalone demo first:

   ```bash
   ./scripts/run-demo.sh
   ```

2. Run Claude Code against the demo MCP server:

   ```bash
   export ANTHROPIC_API_KEY=<your-anthropic-api-key>
   ./scripts/run-claude-code-demo.sh
   ```

3. Put a gateway in front of model traffic on your device:

   ```bash
   export ANTHROPIC_BASE_URL=http://127.0.0.1:4010
   export AI_MODEL_ROUTE_NAME=dev-edge/claude-code-llm
   export AI_MODEL_BACKEND=dev-edge/claude-haiku-anthropic
   ./scripts/run-claude-code-demo.sh
   ```

4. Move route ownership into your platform/cluster control plane.

5. Push route/policy to the device gateway.

6. Replace the local JSON evidence ledger with your audit/evidence system.

## Cluster-Side agentgateway

In the talk, the cluster-side gateway/control plane owns route intent:

```text
route:   dev-edge/claude-code-llm
backend: dev-edge/claude-haiku-anthropic
policy:  allowed model, token telemetry, request/response controls
```

The local demo does not install this for you because clusters vary. Use [examples/agentgateway/cluster-control-plane-route.yaml](../examples/agentgateway/cluster-control-plane-route.yaml) as a shape, not a copy-paste production manifest.

## On-Device agentgateway

The device/dev-edge gateway gives Claude Code a local Anthropic-compatible endpoint:

```bash
export ANTHROPIC_BASE_URL=http://127.0.0.1:4010
```

Claude Code stays local. Model traffic still flows through a governed route. That is the point of the device-side data plane.

Use [examples/agentgateway/device-dev-edge-config.yaml](../examples/agentgateway/device-dev-edge-config.yaml) as a minimal shape.

## What To Prove

A complete run should prove:

- the agent loaded a `SKILL.md` procedure
- the agent called only allowed MCP tools
- the model route was governed
- eval gates passed
- token/request telemetry was visible
- evidence was written
- a human or team remained accountable

