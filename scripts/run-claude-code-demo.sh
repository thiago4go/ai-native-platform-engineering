#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

if ! command -v claude >/dev/null 2>&1; then
  echo "ERROR: claude command not found. Install Claude Code or run ./scripts/run-demo.sh." >&2
  exit 2
fi

if [[ -z "${ANTHROPIC_API_KEY:-}" ]]; then
  echo "ERROR: ANTHROPIC_API_KEY is required for live Claude Code mode." >&2
  exit 2
fi

run_id="claude-code-demo-$(timestamp)"
trace_file="${RUN_DIR}/${run_id}-mcp-trace.jsonl"
log_file="${RUN_DIR}/${run_id}.json"
mcp_config="${RUN_DIR}/${run_id}-mcp.json"

sed \
  -e "s#\${DEMO_ROOT}#${DEMO_ROOT}#g" \
  -e "s#\${MCP_TRACE_FILE}#${trace_file}#g" \
  -e "s#\${AI_MODEL_ROUTE_NAME}#${AI_MODEL_ROUTE_NAME:-local-dev/claude-code-llm}#g" \
  -e "s#\${AI_MODEL_BACKEND}#${AI_MODEL_BACKEND:-local-dev/claude-haiku}#g" \
  -e "s#\${ANTHROPIC_BASE_URL}#${ANTHROPIC_BASE_URL:-}#g" \
  "${DEMO_ROOT}/mcp/claude-code-mcp.template.json" > "${mcp_config}"

prompt="$(cat <<'PROMPT'
You are running the AI-native platform engineering demo.

Call these MCP tools in order:
1. platform.get_context
2. platform.get_eval_results
3. platform.record_evidence with decision="promote_for_demo" and actor="ai-platform-publisher"

Use the returned context as source of truth. Return strict JSON with:
- decision
- mcpTools
- gateway
- eval
- evidence
- human_approval_boundary
PROMPT
)"

if [[ -n "${ANTHROPIC_BASE_URL:-}" ]]; then
  export ANTHROPIC_BASE_URL
fi

claude --bare -p \
  --mcp-config "${mcp_config}" \
  --strict-mcp-config \
  --allowedTools "mcp__ai-native-platform-demo__platform_get_context,mcp__ai-native-platform-demo__platform_get_eval_results,mcp__ai-native-platform-demo__platform_record_evidence" \
  --permission-mode bypassPermissions \
  --output-format json \
  "${prompt}" > "${log_file}"

echo "Claude Code run complete"
echo "raw log:   ${log_file}"
echo "mcp trace: ${trace_file}"
echo
cat "${trace_file}"

