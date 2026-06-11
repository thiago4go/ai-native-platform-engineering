#!/usr/bin/env node
import crypto from "node:crypto";
import fs from "node:fs";
import path from "node:path";
import readline from "node:readline";
import { fileURLToPath } from "node:url";

const serverDir = path.dirname(fileURLToPath(import.meta.url));
const root = process.env.DEMO_ROOT || path.resolve(serverDir, "..");
const traceFile = process.env.MCP_TRACE_FILE || "";

function readJson(relativePath) {
  return JSON.parse(fs.readFileSync(path.join(root, relativePath), "utf8"));
}

function readText(relativePath) {
  return fs.readFileSync(path.join(root, relativePath), "utf8");
}

function sha256(text) {
  return crypto.createHash("sha256").update(text).digest("hex");
}

function timestampForFile() {
  return new Date().toISOString().replace(/[-:]/g, "").replace(/\.\d{3}Z$/, "Z");
}

const catalog = readJson("catalog/governed-incident-assistant.json");

const routeName = process.env.AI_MODEL_ROUTE_NAME || catalog.gateway.route;
const backendName = process.env.AI_MODEL_BACKEND || catalog.gateway.backend;

const tools = [
  {
    name: "platform.get_context",
    description: "Return governed AI capability context, skill, route, and accountability data.",
    inputSchema: { type: "object", properties: {}, additionalProperties: false }
  },
  {
    name: "platform.get_eval_results",
    description: "Return the governed AI capability smoke eval result.",
    inputSchema: { type: "object", properties: {}, additionalProperties: false }
  },
  {
    name: "platform.record_evidence",
    description: "Append a demo evidence record and return the stored artifact path and digest.",
    inputSchema: {
      type: "object",
      properties: {
        decision: { type: "string" },
        actor: { type: "string" }
      },
      additionalProperties: true
    }
  }
];

function trace(event) {
  if (!traceFile) return;
  fs.appendFileSync(traceFile, JSON.stringify({
    ts: new Date().toISOString(),
    server: "ai-native-platform-demo",
    ...event
  }) + "\n");
}

function toolResult(payload) {
  return {
    content: [
      {
        type: "text",
        text: JSON.stringify(payload, null, 2)
      }
    ]
  };
}

function writeEvidenceRecord(args) {
  const recordsDir = path.join(root, "harness", "runs", "evidence-records");
  fs.mkdirSync(recordsDir, { recursive: true });

  const timestamp = new Date().toISOString();
  const recordId = `${catalog.evidence.recordId}-${timestampForFile()}`;
  const record = {
    record_id: recordId,
    record_type: "promotion",
    timestamp,
    intent: "Publish a governed AI capability through the AI-native platform control loop.",
    actor: {
      type: "agent",
      id: args.actor || catalog.capability.agent,
      autonomy_level: catalog.capability.autonomyCeiling,
      skill: catalog.skill.name
    },
    accountability: {
      accountable_owner: catalog.capability.accountableOwner,
      risk_acceptance_authority: "human",
      agent_liability: "none",
      liability_boundary: catalog.evidence.liabilityBoundary
    },
    controls: {
      mcp_tools: catalog.skill.allowedTools,
      gateway_route: routeName,
      gateway_backend: backendName,
      eval_suite: catalog.eval.suite
    },
    eval: catalog.eval,
    requested: args,
    verdict: args.decision || catalog.evidence.verdict
  };

  const body = `${JSON.stringify(record, null, 2)}\n`;
  const digest = sha256(body);
  const filePath = path.join(recordsDir, `${recordId}.json`);
  fs.writeFileSync(filePath, body);

  const ledgerPath = path.join(root, "harness", "runs", "evidence-ledger.jsonl");
  const ledgerEntry = {
    ts: timestamp,
    record_id: recordId,
    decision: record.verdict,
    actor: record.actor.id,
    project: catalog.project.name,
    route: routeName,
    file: path.relative(root, filePath),
    sha256: digest
  };
  fs.appendFileSync(ledgerPath, `${JSON.stringify(ledgerEntry)}\n`);

  return {
    stored: true,
    mode: "append-only-demo-evidence",
    recordId,
    file: path.relative(root, filePath),
    ledger: path.relative(root, ledgerPath),
    sha256: digest,
    ledgerEntry,
    evidence: record
  };
}

function summarize(name, payload) {
  if (name === "platform.get_context") {
    return {
      project: payload.project.name,
      owner: payload.capability.owner,
      route: payload.gateway.route,
      backend: payload.gateway.backend,
      skill: payload.skill.name
    };
  }

  if (name === "platform.get_eval_results") {
    return {
      capability: payload.capability,
      passed: payload.passed,
      score: payload.score,
      gates: payload.gates
    };
  }

  if (name === "platform.record_evidence") {
    return {
      stored: payload.stored,
      recordId: payload.recordId,
      file: payload.file,
      ledger: payload.ledger,
      sha256: payload.sha256,
      verdict: payload.evidence.verdict
    };
  }

  return payload;
}

async function handle(message) {
  if (message.method === "initialize") {
    return {
      protocolVersion: "2024-11-05",
      capabilities: { tools: {} },
      serverInfo: { name: "ai-native-platform-demo", version: "0.1.0" }
    };
  }

  if (message.method === "tools/list") {
    trace({ type: "tools/list", result: tools.map((tool) => tool.name) });
    return { tools };
  }

  if (message.method === "tools/call") {
    const name = message.params?.name;
    const args = message.params?.arguments || {};
    trace({ type: "tools/call", tool: name, arguments: args });

    let payload;
    if (name === "platform.get_context") {
      payload = {
        catalog,
        project: catalog.project,
        component: catalog.component,
        capability: catalog.capability,
        skill: {
          ...catalog.skill,
          content: readText(catalog.skill.path)
        },
        gateway: {
          route: routeName,
          backend: backendName,
          model: catalog.gateway.model,
          baseUrl: process.env.ANTHROPIC_BASE_URL || catalog.gateway.baseUrl
        }
      };
    } else if (name === "platform.get_eval_results") {
      payload = {
        capability: catalog.capability.name,
        ...catalog.eval
      };
    } else if (name === "platform.record_evidence") {
      payload = writeEvidenceRecord(args);
    } else {
      trace({ type: "tools/error", tool: name, error: `Unknown tool: ${name}` });
      throw new Error(`Unknown tool: ${name}`);
    }

    trace({ type: "tools/result", tool: name, result: summarize(name, payload) });
    return toolResult(payload);
  }

  if (message.method?.startsWith("notifications/")) return undefined;
  throw new Error(`Unsupported method: ${message.method}`);
}

const rl = readline.createInterface({ input: process.stdin });

rl.on("line", async (line) => {
  if (!line.trim()) return;
  let message;
  try {
    message = JSON.parse(line);
    const result = await handle(message);
    if (message.id === undefined || result === undefined) return;
    process.stdout.write(JSON.stringify({ jsonrpc: "2.0", id: message.id, result }) + "\n");
  } catch (error) {
    if (message?.id !== undefined) {
      process.stdout.write(JSON.stringify({
        jsonrpc: "2.0",
        id: message.id,
        error: { code: -32000, message: error.message }
      }) + "\n");
    }
  }
});

