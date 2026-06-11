# Live Claude Code Mode

The standalone demo does not require Claude Code. It calls the MCP server directly so anyone can run it.

If you want the agent runtime in the loop, use:

```bash
export ANTHROPIC_API_KEY=<your-anthropic-api-key>
./scripts/run-claude-code-demo.sh
```

The script configures Claude Code with:

```text
mcp/claude-code-mcp.template.json
```

Claude is allowed to call only:

```text
platform.get_context
platform.get_eval_results
platform.record_evidence
```

## Optional Gateway

If you have a model gateway, point Claude Code at it:

```bash
export YOUR_GATEWAY_PORT=<port-your-gateway-listens-on>
export ANTHROPIC_BASE_URL="http://127.0.0.1:${YOUR_GATEWAY_PORT}"
export AI_MODEL_ROUTE_NAME=dev-edge/claude-code-llm
export AI_MODEL_BACKEND=dev-edge/claude-haiku-anthropic
./scripts/run-claude-code-demo.sh
```

The demo does not install a gateway for you. That is intentional: gateway products and cluster environments vary. The important part is the platform pattern:

```text
agent runtime -> governed model route -> telemetry -> evidence
```
