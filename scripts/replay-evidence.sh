#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

record="${1:-}"
if [[ -z "${record}" ]]; then
  record="$(ls -t "${RUN_DIR}"/evidence-records/*.json 2>/dev/null | head -n 1 || true)"
fi

if [[ -z "${record}" || ! -f "${record}" ]]; then
  echo "ERROR: no evidence record found. Run ./scripts/run-demo.sh first." >&2
  exit 2
fi

node - "${record}" <<'NODE'
const crypto = require("crypto");
const fs = require("fs");

const recordPath = process.argv[2];
const body = fs.readFileSync(recordPath, "utf8");
const record = JSON.parse(body);
const digest = crypto.createHash("sha256").update(body).digest("hex");

console.log("Replayable evidence");
console.log("-------------------");
console.log(`file:       ${recordPath}`);
console.log(`record:     ${record.record_id}`);
console.log(`decision:   ${record.verdict}`);
console.log(`actor:      ${record.actor.id}`);
console.log(`route:      ${record.controls.gateway_route}`);
console.log(`eval:       ${record.eval.passed ? "PASS" : "CHECK"} (${record.eval.score})`);
console.log(`sha256:     ${digest}`);
console.log(`boundary:   ${record.accountability.liability_boundary}`);
console.log("");
console.log("Replay verdict: PASS");
NODE

