#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

auto_mode=0
if [[ "${1:-}" == "--auto" ]]; then
  auto_mode=1
fi

trace_file="$(mktemp)"
before_metrics="$(mktemp)"
after_metrics="$(mktemp)"

if [[ -t 1 ]]; then
  bold="$(tput bold 2>/dev/null || true)"
  dim="$(tput dim 2>/dev/null || true)"
  reset="$(tput sgr0 2>/dev/null || true)"
  green="$(tput setaf 2 2>/dev/null || true)"
  blue="$(tput setaf 4 2>/dev/null || true)"
  magenta="$(tput setaf 5 2>/dev/null || true)"
  cyan="$(tput setaf 6 2>/dev/null || true)"
  yellow="$(tput setaf 3 2>/dev/null || true)"
else
  bold=""; dim=""; reset=""; green=""; blue=""; magenta=""; cyan=""; yellow=""
fi

section() {
  printf "\n%s%s%s\n" "${bold}${cyan}" "$1" "${reset}"
  printf "%s\n" "----------------------------------------------------------------------"
}

pause() {
  if [[ "${auto_mode}" == "1" ]]; then
    return
  fi
  printf "\n%sPress Enter for next scene...%s" "${dim}" "${reset}"
  read -r _
}

stage_note() {
  local title="$1"
  local proof="$2"
  local watch="$3"

  printf "\n%s%s%s\n" "${bold}" "${title}" "${reset}"
  printf "  proof: %s\n" "${proof}"
  printf "  watch: %s\n" "${watch}"
}

architecture_map() {
  printf "\n%sArchitecture%s\n" "${bold}" "${reset}"
  printf "  %sCluster / platform side%s\n" "${green}" "${reset}"
  printf "    [Catalog] [Skill registry] [Route control plane] [Eval / telemetry / evidence]\n"
  printf "             |                 route intent + policy\n"
  printf "             v\n"
  printf "  %sDeveloper device / dev edge%s\n" "${cyan}" "${reset}"
  printf "    [Claude Code or runner] ---- allowed MCP tools ----> %s[Demo MCP server]%s\n" "${blue}" "${reset}"
  printf "             |                                      |-- platform.get_context\n"
  printf "             |                                      |-- platform.get_eval_results\n"
  printf "             |                                      '-- platform.record_evidence\n"
  printf "             v\n"
  printf "    %s[on-device agentgateway :<port>]%s ----> [Model backend]\n" "${yellow}" "${reset}"
  printf "\n  This script runs the same control loop locally and can read live gateway metrics when provided.\n"
}

capture_metrics() {
  local output_file="$1"
  if [[ -z "${AGENTGATEWAY_METRICS_URL:-}" ]]; then
    return
  fi
  curl -fsS "${AGENTGATEWAY_METRICS_URL}" -o "${output_file}" || true
}

show_metric_delta() {
  if [[ -z "${AGENTGATEWAY_METRICS_URL:-}" || ! -s "${before_metrics}" || ! -s "${after_metrics}" ]]; then
    printf "No live gateway metrics URL configured. Local route proof artifact was written instead.\n"
    printf "Set AGENTGATEWAY_METRICS_URL=http://127.0.0.1:<metrics-port>/metrics to show live traffic deltas.\n"
    return
  fi

  node - "${before_metrics}" "${after_metrics}" <<'NODE'
const fs = require("fs");

function read(path) {
  const values = {
    requests200: 0,
    inputTokens: 0,
    outputTokens: 0,
    tokenSamples: 0
  };

  for (const line of fs.readFileSync(path, "utf8").split(/\n/)) {
    if (!line || line.startsWith("#")) continue;
    const value = Number(line.trim().split(/\s+/).at(-1));
    if (!Number.isFinite(value)) continue;

    if (/agentgateway_requests_total/.test(line) && /status="200"/.test(line)) {
      values.requests200 += value;
    }
    if (/agentgateway_gen_ai_client_token_usage_(sum|count)/.test(line)) {
      values.tokenSamples += value;
      if (/input/.test(line)) values.inputTokens += value;
      if (/output/.test(line)) values.outputTokens += value;
    }
  }

  return values;
}

const before = read(process.argv[2]);
const after = read(process.argv[3]);
const delta = {};
for (const key of Object.keys(after)) delta[key] = Math.max(0, after[key] - before[key]);

console.log("Live gateway traffic delta");
console.log(`  200 responses:        +${Math.round(delta.requests200)}`);
console.log(`  input token signal:   +${Math.round(delta.inputTokens)}`);
console.log(`  output token signal:  +${Math.round(delta.outputTokens)}`);
console.log(`  token samples:        +${Math.round(delta.tokenSamples)}`);
NODE
}

run_platform_action() {
  DEMO_ROOT="${DEMO_ROOT}" MCP_TRACE_FILE="${trace_file}" node - <<'NODE'
const { spawn } = require("child_process");
const fs = require("fs");
const path = require("path");

(async () => {
const root = process.env.DEMO_ROOT;
const traceFile = process.env.MCP_TRACE_FILE;
const child = spawn("node", [path.join(root, "mcp/platform-context-server.mjs")], {
  env: { ...process.env, DEMO_ROOT: root, MCP_TRACE_FILE: traceFile },
  stdio: ["pipe", "pipe", "inherit"]
});

let buffer = "";
const pending = [];
child.stdout.on("data", (chunk) => {
  buffer += chunk.toString();
  let index;
  while ((index = buffer.indexOf("\n")) >= 0) {
    const line = buffer.slice(0, index);
    buffer = buffer.slice(index + 1);
    if (line.trim()) pending.shift()?.(JSON.parse(line));
  }
});

let id = 1;
function rpc(method, params) {
  return new Promise((resolve) => {
    pending.push(resolve);
    child.stdin.write(JSON.stringify({ jsonrpc: "2.0", id: id++, method, params }) + "\n");
  });
}

function payload(response) {
  return JSON.parse(response.result.content[0].text);
}

await rpc("initialize", {});
await rpc("tools/list", {});
const context = payload(await rpc("tools/call", { name: "platform.get_context", arguments: {} }));
const evalResult = payload(await rpc("tools/call", { name: "platform.get_eval_results", arguments: {} }));
const evidence = payload(await rpc("tools/call", {
  name: "platform.record_evidence",
  arguments: { decision: "promote_for_demo", actor: context.capability.agent }
}));

const metrics = {
  ts: new Date().toISOString(),
  route: context.gateway.route,
  backend: context.gateway.backend,
  status: 200,
  input_tokens: 1280,
  output_tokens: 420,
  evidence_record: evidence.recordId,
  evidence_sha256: evidence.sha256
};
const metricsFile = path.join(root, "harness/runs", `route-metrics-${Date.now()}.json`);
fs.writeFileSync(metricsFile, JSON.stringify(metrics, null, 2) + "\n");

console.log("Governed action proof");
console.log(`  capability: ${context.project.name}`);
console.log(`  accountable: ${context.capability.accountableOwner}`);
console.log(`  tools:      ${context.skill.allowedTools.join(", ")}`);
console.log(`  route:      ${context.gateway.route} -> ${context.gateway.backend}`);
console.log(`  eval:       ${evalResult.passed ? "PASS" : "CHECK"} (${evalResult.score})`);
console.log(`  evidence:   ${evidence.file}`);
console.log(`  sha256:     ${evidence.sha256}`);
console.log(`  metrics:    ${metricsFile}`);
child.kill();
})().catch((error) => {
  console.error(error);
  process.exit(1);
});
NODE
}

show_mcp_trace() {
  node - "${trace_file}" <<'NODE'
const fs = require("fs");

console.log("Actual MCP trace");
for (const line of fs.readFileSync(process.argv[2], "utf8").split(/\n/).filter(Boolean)) {
  const event = JSON.parse(line);
  if (event.type === "tools/list") {
    console.log(`  MCP LIST   ${event.result.join(", ")}`);
  } else if (event.type === "tools/call") {
    console.log(`  MCP CALL   ${event.tool} ${JSON.stringify(event.arguments || {})}`);
  } else if (event.type === "tools/result") {
    const result = event.result || {};
    if (event.tool === "platform.get_context") {
      console.log(`  MCP RESULT project=${result.project}, owner=${result.owner}, route=${result.route}`);
    } else if (event.tool === "platform.get_eval_results") {
      console.log(`  MCP RESULT ${result.passed ? "PASS" : "CHECK"}, score=${result.score}, gates=${(result.gates || []).join(",")}`);
    } else if (event.tool === "platform.record_evidence") {
      console.log(`  MCP RESULT stored=${result.stored}, record=${result.recordId}, sha256=${result.sha256}`);
    } else {
      console.log(`  MCP RESULT ${JSON.stringify(result)}`);
    }
  }
}
NODE
}

show_agent_activity() {
  node - "${trace_file}" <<'NODE'
const fs = require("fs");

const events = fs.readFileSync(process.argv[2], "utf8")
  .split(/\n/)
  .filter(Boolean)
  .map((line) => JSON.parse(line));

const results = new Map();
for (const event of events) {
  if (event.type === "tools/result") results.set(event.tool, event.result || {});
}

const context = results.get("platform.get_context") || {};
const evalResult = results.get("platform.get_eval_results") || {};
const evidence = results.get("platform.record_evidence") || {};

console.log("Agent activity timeline");
console.log(`  1. Loaded platform context for ${context.project || "the capability"}`);
console.log(`  2. Confirmed governed route ${context.route || "configured route"}`);
console.log(`  3. Checked eval gate: ${evalResult.passed ? "PASS" : "CHECK"} (${evalResult.score ?? "n/a"})`);
console.log(`  4. Wrote evidence record ${evidence.recordId || "n/a"}`);
console.log("  5. Preserved accountability: agents execute delegated steps; humans own risk and consequences");
NODE
}

section "AI-Native Platform Engineering Demo"
printf "This is the presenter-style run: staged, visible, and replayable.\n"
printf "It shows the platform control loop rather than only printing a final result.\n"

stage_note "Opening claim" \
  "AI-native platforms standardize how intelligent systems act." \
  "The loop: skill -> tools -> route -> eval -> evidence -> accountable human."
architecture_map
pause

section "Scene 1: The Governed Capability"
stage_note "What the platform owns" \
  "Capability state, allowed tools, model route, eval gate, evidence contract." \
  "The agent receives a path, not broad authority."
printf "Capability catalog: %s\n" "${DEMO_ROOT}/catalog/governed-incident-assistant.json"
printf "Skill procedure:    %s\n" "${DEMO_ROOT}/skills/publish-governed-incident-assistant/SKILL.md"
pause

section "Scene 2: Run The Platform Action"
stage_note "What executes" \
  "The runner calls the same MCP tools an agent would call." \
  "Each tool call creates traceable proof."
capture_metrics "${before_metrics}"
run_platform_action
capture_metrics "${after_metrics}"
pause

section "Scene 3: Show The MCP Calls"
stage_note "What to notice" \
  "The trace shows the tool boundary explicitly." \
  "Context, eval, and evidence are platform tools, not hidden prompt magic."
show_mcp_trace
pause

section "Scene 4: Show Traffic And Token Proof"
stage_note "What to notice" \
  "A real gateway can expose request and token telemetry." \
  "Without a live gateway, the demo still writes a local route proof artifact."
show_metric_delta
pause

section "Scene 5: Show What The Agent Did"
stage_note "What to notice" \
  "The platform can explain the action as a timeline." \
  "This is the bridge from automation to accountable execution."
show_agent_activity
pause

section "Scene 6: Replay Evidence"
stage_note "Why it matters" \
  "The result is not only a terminal success message." \
  "The run leaves evidence that can be replayed after the fact."
"${DEMO_ROOT}/scripts/replay-evidence.sh"

section "Close"
printf "AI-native platform engineering is not about giving agents vague power.\n"
printf "It is about giving them governed paths to do useful work:\n"
printf "  intent -> skill -> scoped tools -> route -> eval -> telemetry -> evidence -> accountable human\n"
