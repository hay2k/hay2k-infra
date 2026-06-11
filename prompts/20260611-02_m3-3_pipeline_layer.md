# 20260611-02 — M3-3: Pipeline Layer

**Date:** 2026-06-11
**Role:** User (operator `hha`) → pipeline-layer implementation phase
**Prompt (verbatim):** "Proceed with M3-3 — Pipeline Layer"

**Interpretation (stated to operator):** establish + validate the pipeline-layer
*mechanism* with a neutral, project-independent workflow (analogous to M3-2 using
pytorch as a neutral first container); do **not** auto-install a research-specific
pipeline (research-coupled, project-gated, multi-GB) — that is an operator-directed
follow-up.

**Outcome:** Created `PIPELINE_STANDARDS.md`; created the managed engine cache
`analysis/container/apptainer/_engine-cache/`; registered the first pipeline
`custom/runtime-smoke/0.1` via `analysis-install` (current; accel=both/preferred=gpu).
Validated Snakemake → `apptainer --nv` → pytorch container → GPU (cuda True, 2× RTX
6000 Ada) from both temp and the canonical store path, plus Nextflow engine sanity and
analysis-install tracking/verify/pin. **No research pipelines, no project, no P0001.**
GPU-first enforced. Logs + this prompt updated; handoff saved.
