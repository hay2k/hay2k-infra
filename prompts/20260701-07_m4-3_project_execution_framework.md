# 20260701-07 — M4-3: Project Execution Framework

**Date:** 2026-07-01
**Role:** User (operator `hha`) → implementation (M4-3; "priority is implementation")
**Prompt (verbatim intent):** "Establish the reusable Project Execution Framework, project-
independent, to later execute P0001/P0002/P0003 with the same model. (1) Reusable execution
layer — execution always begins from PROJECT_MASTER.md + ENVIRONMENT_MANIFEST.md, never from
docs/. (2) Execution workflow stages: Project → Planning → Capability Resolution → Execution →
Validation → Figure Generation → Result Packaging → Project Update → Handoff; each reusable by
future agents. (3) Reusable execution commands — extend the existing platform, consistent
interface, provider-agnostic. (4) Figure pipeline — every figure preserves Figure → Source Data
Table → Metadata by default. (5) Execution metadata — reproducibility (project, date, capability/
container/reference/pipeline/software versions); reuse existing metadata, avoid duplication. (6)
Future-agent compatible — logic independent of Claude/GPT/Kimi/Gemini/DeepSeek/local; agents
orchestrate, framework executes; Model ≠ Execution Framework. (7) P0003 — do NOT import; verify
the framework can execute a future imported project without modification. Reuse existing
components/governance/CLI; shared-by-default; container-first; pipeline-driven; provider-agnostic;
autonomous; one milestone; validate; one handoff."

**Outcome (all validated):** Built `scripts/project-run` — a provider-agnostic execution harness
(pure shell over the existing CLI; no LLM calls). Stages implemented as reusable commands:
`stages`, `resolve` (Capability Resolution: verify manifest pins against the live registry,
forbid `current`, record version+sha), `metadata` (RUN_MANIFEST reproducibility reusing
pins+registry sha+git+host+GPU+date), `exec` (container-first, references read-only at
`/refs/<name>`), `figure` (enforce PNG+PDF + Source-Data TSV + Metadata MD; `--register` stubs),
`package` (CHECKSUMS + triad re-check), `handoff`, `run` (driver). Starts only from
PROJECT_MASTER.md + ENVIRONMENT_MANIFEST.md; never reads docs/.

**Validation (temp only; no real project):** create-mode project with real pins → full `run`
(resolve→metadata→exec in scanpy container generating a figure→triad check→package→RUN_LOG
update→handoff). **Objective 7:** an import-mode project ran the SAME framework **unmodified**
(docs/ present but excluded). Negative test: lone PNG fails the triad. Artifacts cleaned;
`/data/analysis/projects` empty.

Docs: PLATFORM_ARCHITECTURE §8b; AGENT_WORKFLOW_STANDARD §5. Handoff:
`2026-07-01_m4-3-project-execution-framework.md`.
