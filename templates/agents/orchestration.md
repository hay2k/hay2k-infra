# Agent Orchestration (Supervisor Layer)

Reusable orchestration for future automation. **The Supervisor orchestrates roles; `project-run`
executes.** Provider-agnostic (Model ≠ Role). No runtime is deployed yet (AGENT_ARCHITECTURE §2);
this is the pattern agents follow when they run.

## Role sequence over the execution stages
```
PROJECT_MASTER.md + ENVIRONMENT_MANIFEST.md   (source of truth; docs/ never an execution input)
        │
Planning ───────────── Knowledge Agent (+ Reference Agent)         → drafts spec / knowledge_transfer
        │
Capability Resolution ─ Analysis Agent      → project-run resolve  (pins verified vs registry)
        │
Execution ──────────── Analysis Agent       → project-run exec / runspec (container-first, refs ro)
        │
Validation ─────────── Validation Agent     → reproducibility tuple, outputs vs spec
        │
Figure Generation ──── Figure Agent         → project-run figure (PNG+PDF+TSV+MD)
        │
(Writing) ──────────── Writing Agent        → manuscript/report (citekeys only)
        │
Result Packaging ───── Analysis/Supervisor  → project-run package (CHECKSUMS + triad re-check)
        │
Project Update ─────── Supervisor           → RUN_LOG + PROJECT_MASTER/TODO status
        │
Handoff ────────────── Supervisor           → project-run handoff  → Human Decision Layer
```

## Rules the Supervisor enforces
- **Reuse-First** at Capability Resolution (`analysis-install catalog` before proposing anything new).
- **Autonomous by default; confirm only on a §3b trigger** (GOVERNANCE §3b). Batch → validate →
  single handoff.
- **Human Decision Layer** for project creation/retirement, new capabilities, scientific decisions.
- **No fabrication** anywhere (GOVERNANCE §5); reproducibility tuple required before "final".

## Multi-domain (same orchestration, one priority order)
Research > Business > Investment > Surplus on shared infrastructure. Business/Investment/Surplus
**consume** the same capabilities and orchestration; they do not redefine them. Surplus yields to
higher-priority work (RESOURCE_POLICY). No per-domain architecture.
