# 20260701-02 — M4: Core principle (shared-by-default platform assets)

**Date:** 2026-07-01
**Role:** User (operator `hha`) → governance codification
**Prompt (verbatim intent):** "Core M4 principle: Infrastructure, agents, pipelines,
containers, references, models, and reusable scripts should be designed as shared platform
assets by default. They must be easy to update, version, deprecate, and reuse across
multiple projects. Projects consume shared platform assets by pinning exact versions in
ENVIRONMENT_MANIFEST.md. Do not copy or fork shared assets into project directories unless
there is a documented project-specific reason. Default order: Reuse existing shared asset →
Extend shared asset with a new version → Create new shared platform asset → Create
project-specific asset only if justified. Agent components must follow the same rule: shared
agent logic and reusable prompts live in the platform layer; project-specific instructions
live in PROJECT_MASTER.md / TODO.md / project configs."

**Outcome:** Codified by **extending existing canonical governance** (Reuse-First applied to
governance — ~80% was already canonical in PLATFORM_REUSE_POLICY.md; no new redundant docs).
- **PLATFORM_REUSE_POLICY.md** — §0 M4 core principle; §1 broadened asset scope
  (infra/agents/reusable scripts) + full 4-rung ladder
  `Reuse > Extend > New shared > Project-specific (justified)`; §4 reconciled "never fork"
  → **documented-exception** (recorded in Capability Resolution); §8 **Agent components are
  shared assets** (shared logic/prompts = platform layer; project-specific =
  PROJECT_MASTER/TODO/configs; Model ≠ Role; no premature prompt-store materialization).
- **AGENT_WORKFLOW_STANDARD.md §4** — cross-ref to §8.

**Refinement flagged:** the previously binding "projects **never** fork" is now "no fork
**unless a documented project-specific reason**", per the operator's stated principle.

**Nature:** governance/documentation only — no assets rebuilt, no functional change.
Handoff: `2026-07-01_m4-core-principle-shared-assets.md`.
