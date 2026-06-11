---
name: publish-governed-incident-assistant
description: Publish and explain a governed AI capability using scoped MCP tools, eval gates, model-route proof, and replayable evidence.
---

# Publish Governed Incident Assistant

## Autonomy

- Autonomy ceiling: L3
- Human approval is required for material or production-impacting changes.
- Agents do not own liability, risk acceptance, or consequences.

## Required MCP Tools

- `platform.get_context`
- `platform.get_eval_results`
- `platform.record_evidence`

## Blocked Actions

- Direct production mutation
- Secret reads
- Unrestricted shell access
- Unapproved model routes
- Customer-impacting external communication

## Procedure

1. Read platform context through MCP.
2. Verify the capability owner, agent identity, and autonomy ceiling.
3. Verify requested MCP tools are allowlisted.
4. Confirm the model route is a governed route.
5. Check the eval result for `governed-ai-capability-smoke`.
6. Record evidence with decision, actor, route, eval, and accountability boundary.
7. Return one of:
   - `promote_for_demo`
   - `needs_human_approval`
   - `blocked`

## Stop Rules

- Eval gate fails
- Unapproved tool requested
- Direct production mutation requested
- Evidence cannot be recorded
- Human accountability is absent

