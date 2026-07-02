# 20260702-02 — M4 Final Sprint: Platform v1.0 Completion

**Date:** 2026-07-02
**Role:** User (operator `hha`) → rapid implementation to Platform v1.0 freeze
**Prompt (verbatim intent):** "M4 Final Sprint — Platform v1.0 Completion. Prioritize rapid
implementation over governance; no new governance docs unless a genuine architectural gap. Reach a
stable Platform v1.0 fast, then freeze; research projects (P0001 Nanopore direct-RNA AI, P0002 RNA
editing, P0003 TBI scRNA-seq) begin on the same version; do not optimize for P0003; keep the
platform project-independent. Remaining priorities: (1) Platform Constitution — concise
philosophical architectural constitution (NOT governance), read first by humans + future AI; (2)
Agent Layer — reusable agent architecture by role not model (Knowledge/Reference/Analysis/Figure/
Writing/Validation/Supervisor; agents orchestrate, framework executes; Model ≠ Role; provider-
agnostic); (3) Supervisor Layer — reusable orchestration; research highest priority; Business/
Investment/Surplus coexist without changing core architecture; (4) Knowledge Transfer Framework —
reusable, project-independent, not P0003-specific. Then declare + freeze Platform v1.0 (future
changes → v1.1). Reuse existing assets/governance/CLI; extend over new; avoid unnecessary
abstractions/governance/duplication; autonomous; batch into milestones; minimize confirmations.
Future hardware: GPU preferred; CPU parallelism when appropriate; MPI only when justified; aria2
for large downloads. Handoffs only for substantial milestones."

**Outcome:**
- **Constitution:** `PLATFORM_CONSTITUTION.md` (10 principles + domains + acceleration; north star).
- **Agent Layer + Supervisor:** `templates/agents/` role library (supervisor/knowledge/reference/
  analysis/figure/writing/validation) + `orchestration.md` (roles over project-run stages; multi-
  domain). Provider-agnostic, Model ≠ Role; materializes PLATFORM_REUSE_POLICY §8.
- **Knowledge Transfer (Priority 4):** already project-independent (M4-4); referenced, no rework.
- **Hardware:** RESOURCE_POLICY §6a (GPU-first / CPU parallelism / MPI-when-justified / aria2).
- **FREEZE:** `PLATFORM_VERSION.md` (frozen manifest) + git tag `platform-v1.0`; future → v1.1+.

**Nature:** implementation + freeze. No new governance documents (Constitution is explicitly the
architectural north star, not governance; all other changes extended existing docs). Handoff:
`2026-07-02_m4-final-sprint-platform-v1.0.md`.
