# Panel Q&A Notes

These are Thiago's point-of-view notes from the AI-native platform engineering talk. They are written as speaker-ready answers, with suggested handoffs where Asanka and Mark can add their angles.

## Question 1

**Platform engineering has moved from cloud-native enablement to AI-native execution. What is the one thing that fundamentally changes when AI becomes part of the platform, and what must not change?**

Start: Thiago. Then Asanka. Then Mark.

**Thiago**

The fundamental change is that the platform is no longer only helping humans deploy and operate software. It now has to mediate intelligent execution.

In cloud-native platform engineering, the main question was: how do we give teams a reliable paved road to build, deploy, and run services? In AI-native platform engineering, the question expands: how do we let agents, models, and tools take useful action without giving them vague power?

That means the platform needs new primitives: context, tool contracts, model routing, evals, telemetry, evidence, and accountability boundaries.

What must not change is the platform engineering discipline. We still need golden paths, product thinking, security, reliability, ownership, and a good developer experience. AI does not remove those responsibilities. It makes them more important, because now the platform is shaping actions, not only infrastructure.

My shortest version is:

```text
What changes: the platform becomes part of the execution loop.
What must not change: humans and organizations remain accountable.
```

**Suggested Asanka add**

The portal cannot just be a UI over scattered tools. It has to be a front door into real platform capabilities with clear abstractions, ownership, and lifecycle.

**Suggested Mark add**

Security has to move from after-the-fact review into default execution paths: identity, policy, audit, and guardrails built into how AI work gets done.

## Question 2

**Asanka, your session strongly distinguishes between the portal as the front door and the platform as the engine. Many organizations invest heavily in the developer portal but still leave teams with stitched-together tools and weak abstractions. What separates a demo-friendly IDP from an enterprise-grade IDP?**

Start: Asanka. Then Thiago and Mark add.

**Suggested Asanka start**

A demo-friendly IDP often looks good because it centralizes links, templates, and service metadata. An enterprise-grade IDP changes how work actually flows.

It has strong abstractions behind the portal, clear ownership, integrated workflows, policy, lifecycle management, and measurable outcomes. The portal is the front door, but the platform behind it must be the engine.

**Thiago add**

My addition is that, in an AI-native world, an enterprise-grade IDP also becomes a context and control surface for agents.

If the portal only shows humans a catalog, it is useful. But if the platform catalog can also describe capabilities to agents, expose approved MCP tools, route model traffic through governed paths, and write evidence, then it becomes much more powerful.

That is the shift I wanted to show in the demo. The catalog is not just documentation. It is connected to:

```text
capability -> skill -> tools -> route -> eval -> evidence
```

That is what separates a nice developer experience from an operating model.

**Suggested Mark add**

Enterprise-grade also means the platform can prove what happened: who or what acted, under which policy, with which data, against which model, and with what result.

## Question 3

**Thiago, your session focused on the Platform Intelligence Layer: data, inference, telemetry, and control pathways. For enterprises that already have cloud-native platforms, what is the most important architectural shift they must make to become truly AI-native?**

Start: Thiago. Mark and Asanka add.

**Thiago**

The most important architectural shift is to stop treating AI as an application feature and start treating it as a platform execution layer.

Many enterprises already have strong cloud-native foundations: Kubernetes, CI/CD, service catalogs, observability, security controls, and internal platforms. That is a great base. But AI-native work needs an additional layer that connects four things:

```text
data/context -> inference -> tool/action pathways -> telemetry/evidence
```

I call that the Platform Intelligence Layer.

It answers questions like:

- What context is the agent allowed to see?
- Which tools can it call?
- Which model route is approved?
- Which eval gate decides whether it can proceed?
- What telemetry proves the action happened safely?
- Where is the evidence recorded?
- Who owns the decision and the consequences?

Without that layer, every team builds its own agent, its own prompts, its own tool access, and its own risk model. That becomes another form of platform fragmentation.

So the architectural shift is from static platform control planes to governed execution loops.

```text
intent -> context -> skill -> scoped tools -> model route -> eval -> evidence
```

**Suggested Mark add**

That execution loop needs security architecture from the beginning: identity, least privilege, data boundaries, audit, and policy enforcement at the points where agents read, reason, and act.

**Suggested Asanka add**

The IDP is where teams should discover and consume these capabilities. The intelligence layer should be packaged as platform products, not exposed as raw infrastructure.

## Question 4

**Mark, your session focused on secure-by-default AI-native platforms. In the AI era, how do we design guardrails that preserve trust and control without turning the platform into a bureaucracy machine?**

Start: Mark. Asanka and Thiago add.

**Suggested Mark start**

Guardrails have to be built into the path of least resistance. If security is a separate approval maze, teams will route around it. If security is part of the default platform path, teams get speed and control together.

The goal is not to block AI adoption. The goal is to make the safe path the easiest path.

**Suggested Asanka add**

This is where good platform abstractions matter. Developers should not need to understand every underlying control. They should consume a capability that already includes identity, policy, observability, and lifecycle.

**Thiago add**

My view is that guardrails should be executable, observable, and explainable.

For AI-native platforms, that means:

- Give agents scoped tools, not broad infrastructure access.
- Route model calls through governed gateways.
- Use evals as gates, not as slideware.
- Record evidence automatically.
- Keep humans accountable for material changes.

The bureaucracy risk is real. So I would not create a committee for every agent action. I would standardize the control loop and let the platform enforce it.

```text
policy should travel with the path, not sit in a separate meeting
```

## Question 5

**Most attendees will leave today excited, but excitement alone doesn't create value. What is the first 90-day move an enterprise should make to advance toward an AI-native platform roadmap without creating another disconnected experiment?**

Asanka starts on IDP. Thiago adds on architecture and intelligence layer. Mark wraps with policy and governance.

**Suggested Asanka start**

Pick one platform workflow that teams already care about and make it a real platform product through the IDP. Do not start with a disconnected AI experiment. Start with a workflow that already has demand, ownership, and measurable friction.

**Thiago add**

I would make the first 90 days very concrete.

Choose one workflow where an agent can assist but the platform can still clearly control the path. For example: incident triage, service onboarding, production readiness review, dependency upgrade, or compliance evidence collection.

Then build the minimum AI-native platform loop around it:

```text
1. Catalog the capability.
2. Write the SKILL.md or equivalent procedure.
3. Define the allowed tool contract.
4. Route model traffic through a governed path.
5. Add one eval gate.
6. Emit telemetry.
7. Record replayable evidence.
8. Name the accountable human or team.
```

The goal is not to prove that an agent can do something impressive once. The goal is to prove the platform can make agentic work repeatable, observable, and governable.

At the end of 90 days, I would want one reusable platform pattern, not five demos.

**Suggested Mark wrap**

Define the policy boundary early: data classification, tool permissions, model access, approval requirements, audit requirements, and incident response. Keep it small enough to ship, but real enough that it can become the enterprise standard.

## Question 6: Lightning Round

**One platform capability every enterprise should standardize immediately?**

Thiago: Standardize agent tool contracts. Whether you use MCP or another interface, the platform needs a clear way to say: this agent can call these tools, with this identity, under this policy, with this evidence.

**One thing leaders should stop doing in platform engineering?**

Thiago: Stop treating the developer portal as the platform. The portal is the front door. The platform is the engine behind it.

**One AI-native platform risk that is still underappreciated?**

Thiago: Unaccountable action. The risk is not only that a model gives a bad answer. The deeper enterprise risk is that an agent takes action and nobody can explain which context, tool, model route, policy, eval, or human approval boundary applied.

**One metric that tells you the platform is working?**

Thiago: Evidence-covered execution. For the workflows that matter, what percentage of agent-assisted actions have complete traceability: skill, tools, route, eval, telemetry, evidence, and accountable owner?

**One prediction for platform teams over the next 12 months?**

Thiago: Platform teams will become the control plane for enterprise AI execution. The best teams will not just provide infrastructure. They will provide governed paths for humans and agents to work together safely.

## Closing Thought

AI-native platform engineering is not about giving agents unlimited autonomy.

It is about making useful AI-assisted action possible inside a platform operating model:

```text
clear intent
scoped tools
governed model routes
eval gates
observable execution
replayable evidence
human accountability
```

That is how AI moves from experiment to enterprise capability.
