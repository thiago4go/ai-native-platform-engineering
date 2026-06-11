# AI-Native Platform Engineering

Build and run the closing demo from the talk: a governed AI platform action with a skill, scoped MCP tools, model-route proof, eval gates, telemetry, and replayable evidence.

This audience version is intentionally standalone. It does not require a Kubernetes cluster, OpenChoreo install, VPN, Grafana, or private agentgateway setup.

## What You Will Run

The demo shows one platform action:

```text
Platform catalog
  -> SKILL.md procedure
  -> MCP tools
  -> model route proof
  -> eval gate
  -> evidence JSON + ledger
  -> replay
```

Default mode runs fully local and deterministic. It uses a local MCP server and creates real evidence files on disk. Optional live mode lets you connect Claude Code and your own model gateway.

## Quick Start

Requirements:

- macOS, Linux, or WSL
- Bash
- Node.js 20+

Run:

```bash
git clone https://github.com/thiago4go/ai-native-platform-engineering.git
cd ai-native-platform-engineering
./scripts/run-demo.sh
```

The demo creates evidence under:

```text
harness/runs/evidence-records/
harness/runs/evidence-ledger.jsonl
```

Replay the latest evidence:

```bash
./scripts/replay-evidence.sh
```

## What Is Actually Happening

The local MCP server exposes three tools:

```text
platform.get_context
platform.get_eval_results
platform.record_evidence
```

The runner calls those tools, prints the MCP trace, writes an evidence record, writes route metrics, and replays the result. The point is not the specific service name. The point is the platform control loop.

## Optional Live Claude Code Run

If you have Claude Code installed and an Anthropic API key:

```bash
export ANTHROPIC_API_KEY=<your-anthropic-api-key>
./scripts/run-claude-code-demo.sh
```

To route Claude Code through your own gateway, set:

```bash
export ANTHROPIC_BASE_URL=http://127.0.0.1:4010
./scripts/run-claude-code-demo.sh
```

See [docs/live-claude-code.md](docs/live-claude-code.md).

## Repository Layout

```text
catalog/                         platform capability catalog
skills/                          SKILL.md procedure
mcp/                             local MCP server and Claude config template
scripts/run-demo.sh              standalone audience demo
scripts/run-claude-code-demo.sh  optional live Claude Code demo
scripts/replay-evidence.sh       replay latest evidence record
docs/architecture.md             architecture notes
docs/build-your-own.md           how to adapt the pattern
harness/runs/                    generated run artifacts
```

## Talk Thesis

Cloud-native platform engineering standardized how workloads run.

AI-native platform engineering must standardize how intelligent systems act:

```text
intent -> skill -> scoped tools -> governed model route -> eval -> telemetry -> evidence -> accountability
```

Agents should not get vague power. They should get governed paths.
