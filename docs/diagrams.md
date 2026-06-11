# Diagrams From The Talk

These diagrams explain the architecture and control loop behind the demo.

## 1. Talk Thesis

Cloud-native platforms standardized workload delivery. AI-native platforms need to standardize governed intelligent action.

```mermaid
flowchart LR
    A["Cloud-native platform engineering"] --> B["Service catalog"]
    A --> C["CI/CD"]
    A --> D["Runtime"]
    A --> E["Observability"]

    F["AI-native platform engineering"] --> G["Agent identity"]
    F --> H["SKILL.md procedure"]
    F --> I["Scoped MCP tools"]
    F --> J["Governed model route"]
    F --> K["Eval gates"]
    F --> L["Telemetry"]
    F --> M["Replayable evidence"]
    F --> N["Human accountability"]
```

## 2. Full Topology We Demonstrated

The talk demo used a split topology: platform ownership in the cluster, agent execution on the developer device.

```mermaid
flowchart TB
    subgraph cluster["Cluster / Platform Side"]
        catalog["Platform catalog / portal"]
        skillRegistry["Skill registry + policy"]
        centralGateway["Central agentgateway control plane"]
        evals["Eval service"]
        telemetry["Telemetry + evidence systems"]
    end

    subgraph device["Developer Device / Dev Edge"]
        claude["Claude Code"]
        mcp["Demo MCP server"]
        edgeGateway["On-device agentgateway :<port>"]
    end

    backend["Model backend"]

    catalog --> skillRegistry
    skillRegistry --> centralGateway
    centralGateway -- "route + policy" --> edgeGateway
    evals --> mcp
    telemetry --> catalog

    claude -- "MCP calls" --> mcp
    claude -- "LLM traffic" --> edgeGateway
    edgeGateway --> backend
    mcp -- "evidence write" --> telemetry
```

## 3. What Happens In The Live Demo

This is the path the terminal demo reproduces.

```mermaid
sequenceDiagram
    participant Human as Presenter / Platform Engineer
    participant Agent as Claude Code
    participant Skill as SKILL.md
    participant MCP as Demo MCP Server
    participant Gateway as agentgateway Route
    participant Eval as Eval Gate
    participant Evidence as Evidence Ledger
    participant Model as Model Backend

    Human->>Agent: Run governed platform action
    Agent->>Skill: Load procedure and stop rules
    Agent->>MCP: platform.get_context()
    MCP-->>Agent: capability, owner, route, skill
    Agent->>MCP: platform.get_eval_results()
    MCP-->>Agent: PASS, score, gates
    Agent->>Gateway: Send model request through governed route
    Gateway->>Model: Forward request
    Model-->>Gateway: Response
    Gateway-->>Agent: Response + telemetry
    Agent->>MCP: platform.record_evidence(decision, actor)
    MCP->>Evidence: Write JSON record + ledger entry
    Evidence-->>Human: Replayable proof with SHA-256
```

## 4. MCP Is A Tool Boundary, Not A Permission Model

MCP gives the agent an interface. The platform still needs identity, authorization, route policy, evals, evidence, and human accountability.

```mermaid
flowchart TB
    agent["Agent runtime"] --> mcp["MCP server"]

    mcp --> context["platform.get_context<br/>read capability state"]
    mcp --> eval["platform.get_eval_results<br/>read gate result"]
    mcp --> evidence["platform.record_evidence<br/>write audit artifact"]

    context --> controls["Platform controls"]
    eval --> controls
    evidence --> controls

    controls --> identity["Identity"]
    controls --> policy["Policy"]
    controls --> route["Model route"]
    controls --> approval["Human approval"]
    controls --> ledger["Evidence ledger"]
```

## 5. Evidence Flow

The valuable outcome is not that the model answered. The valuable outcome is that the platform can replay what happened.

```mermaid
flowchart LR
    A["Agent decision"] --> B["MCP evidence write"]
    B --> C["Evidence JSON"]
    B --> D["Evidence ledger JSONL"]
    C --> E["SHA-256 digest"]
    D --> E
    E --> F["Replay command"]
    F --> G["Decision"]
    F --> H["Route"]
    F --> I["Eval result"]
    F --> J["Tools used"]
    F --> K["Accountable human"]
```

## 6. How To Adapt The Pattern

Use the local demo to teach the control loop, then replace each local artifact with your platform system.

```mermaid
flowchart LR
    localCatalog["JSON catalog"] --> realCatalog["Developer portal / service catalog"]
    localSkill["Local SKILL.md"] --> realSkill["Skill registry"]
    localMcp["Local MCP server"] --> realMcp["Platform MCP service"]
    localRoute["Route proof JSON"] --> realRoute["agentgateway / model gateway"]
    localEval["Static eval JSON"] --> realEval["Eval service"]
    localEvidence["JSONL ledger"] --> realEvidence["Audit / GRC / signed evidence store"]
```
