#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

trace_file="$(mktemp)"
metrics_file="${RUN_DIR}/route-metrics-$(timestamp).json"

if [[ -t 1 ]]; then
  bold="$(tput bold 2>/dev/null || true)"
  reset="$(tput sgr0 2>/dev/null || true)"
  green="$(tput setaf 2 2>/dev/null || true)"
  blue="$(tput setaf 4 2>/dev/null || true)"
  magenta="$(tput setaf 5 2>/dev/null || true)"
  cyan="$(tput setaf 6 2>/dev/null || true)"
  yellow="$(tput setaf 3 2>/dev/null || true)"
else
  bold=""; reset=""; green=""; blue=""; magenta=""; cyan=""; yellow=""
fi

section() {
  printf "\n%s%s%s\n" "${bold}${cyan}" "$1" "${reset}"
  printf "%s\n" "----------------------------------------------------------------------"
}

architecture_map() {
  printf "\n%sArchitecture%s\n" "${bold}" "${reset}"
  printf "  %s[Platform catalog]%s\n" "${green}" "${reset}"
  printf "          |\n"
  printf "          v\n"
  printf "  %s[SKILL.md procedure]%s ---- allowed tools ----> %s[MCP server]%s\n" "${green}" "${reset}" "${blue}" "${reset}"
  printf "          |                                      |-- platform.get_context\n"
  printf "          |                                      |-- platform.get_eval_results\n"
  printf "          |                                      '-- platform.record_evidence --> %s[Evidence JSON + ledger]%s\n" "${magenta}" "${reset}"
  printf "          v\n"
  printf "  %s[Agent runtime]%s ---- model route proof ----> %s[Governed route]%s ----> [Model backend]\n" "${cyan}" "${reset}" "${yellow}" "${reset}"
}

section "AI-Native Platform Engineering Demo"
printf "This demo shows one governed AI platform action.\n"
printf "It is local by default: no cluster, VPN, or private gateway required.\n"

printf "\n%sWhat is set up%s\n" "${bold}" "${reset}"
printf "  1. A governed capability catalog\n"
printf "  2. A SKILL.md procedure\n"
printf "  3. A local MCP server with scoped tools\n"
printf "  4. A route proof artifact\n"
printf "  5. An append-only evidence ledger\n"
architecture_map

section "Run The Platform Action"
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
fs.writeFileSync(path.join(root, "harness/runs", `route-metrics-${Date.now()}.json`), JSON.stringify(metrics, null, 2) + "\n");

console.log("Governed action proof");
console.log(`  capability: ${context.project.name}`);
console.log(`  tools:      ${context.skill.allowedTools.join(", ")}`);
console.log(`  route:      ${context.gateway.route} -> ${context.gateway.backend}`);
console.log(`  eval:       ${evalResult.passed ? "PASS" : "CHECK"} (${evalResult.score})`);
console.log(`  evidence:   ${evidence.file}`);
console.log(`  sha256:     ${evidence.sha256}`);
child.kill();
})().catch((error) => {
  console.error(error);
  process.exit(1);
});
NODE

section "Actual MCP Trace"
node - "${trace_file}" <<'NODE'
const fs = require("fs");

for (const line of fs.readFileSync(process.argv[2], "utf8").split(/\n/).filter(Boolean)) {
  const event = JSON.parse(line);
  if (event.type === "tools/list") {
    console.log(`MCP LIST   ${event.result.join(", ")}`);
  } else if (event.type === "tools/call") {
    console.log(`MCP CALL   ${event.tool} ${JSON.stringify(event.arguments || {})}`);
  } else if (event.type === "tools/result") {
    const result = event.result || {};
    if (event.tool === "platform.record_evidence") {
      console.log(`MCP RESULT stored=${result.stored}, file=${result.file}, sha256=${result.sha256}`);
    } else {
      console.log(`MCP RESULT ${JSON.stringify(result)}`);
    }
  }
}
NODE

section "Replay"
"${DEMO_ROOT}/scripts/replay-evidence.sh"

section "Close"
printf "AI-native platform engineering is not about giving agents vague power.\n"
printf "It is about giving them governed paths to do useful work:\n"
printf "  skill -> scoped tools -> route -> eval -> telemetry -> evidence -> accountable human\n"
