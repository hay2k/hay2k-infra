# 20260702-03 — M5-1: Research Knowledge Acquisition Framework

**Date:** 2026-07-02
**Role:** User (operator `hha`) → platform utilization (first milestone on frozen v1.0)
**Prompt (verbatim intent):** "M5-1 — establish a reusable, platform-wide Research Knowledge
Acquisition Framework (NOT P0003-specific); reused for any legacy project. Objective: acquire the
research knowledge required to reconstruct a project on Platform v1.0 — not migrate code or results.
Standard structure: 01 project overview; 02 analysis strategy (why, not only what; why alternatives
rejected); 03 trial-and-error [high priority] (attempt→problem→reason→solution→final decision;
don't hide failures); 04 refactoring (reusable improvements); 05 AI knowledge (separate by origin:
Claude/ChatGPT/other; reusable only, discard noise); 06 literature (papers/concepts/landmark
methods/future directions; summarize, don't duplicate bibliography); 07 open questions (completed
vs unknown); 08 recommended reconstruction (on Platform v1.0; never legacy as execution target).
Package `knowledge/` with 01..08 + attachments/ → input to PROJECT_MASTER generation. Integrate
with project-bootstrap, project-run, PROJECT_MASTER, TODO, ENVIRONMENT_MANIFEST; no duplicated info.
Do NOT acquire P0001/P0002/P0003 yet — complete + validate the reusable framework. Reuse existing
CLI/governance/assets; shared-by-default; provider-agnostic; container-first; pipeline-driven;
automation-ready; autonomous; one milestone; one handoff."

**Outcome:** Evolved the M4-4 Knowledge Transfer framework into the definitive standard (Reuse-First
— one framework, no duplication); recorded as **platform v1.1** (freeze-compliant; `platform-v1.0`
tag unchanged).
- `templates/knowledge_transfer/` → **`templates/knowledge/`**; `05_claude_summary`+`06_chatgpt_summary`
  → **`05_ai_knowledge`** (by origin) + new **`06_literature`**; `04_refactoring_summary` →
  `04_refactoring`; trial-and-error → attempt→problem→**reason**→solution→final decision;
  `Attachments/` → `attachments/`.
- `project-bootstrap kt-init` → scaffolds `knowledge/`; PROJECT_LIFECYCLE §4a → `docs/knowledge/`
  (feeds PROJECT_MASTER/TODO/ENVIRONMENT_MANIFEST generation; no duplication; never an execution
  input). Agent role specs updated. PLATFORM_VERSION.md v1.1 changelog updated.
- Validated with kt-init in a temp dir (10-file package; reason step; 05 by-origin; 06 literature;
  tokens). No real project acquired (P0001/P0002/P0003 pending).

**Nature:** platform utilization / framework refinement (v1.1). Handoff:
`2026-07-02_m5-1-knowledge-acquisition-framework.md`.
