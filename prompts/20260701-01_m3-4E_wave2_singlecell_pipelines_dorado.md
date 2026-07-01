# 20260701-01 — M3-4E: Platform Wave 2 (single-cell + nf-core + Dorado/Remora)

**Date:** 2026-07-01
**Role:** User (operator `hha`) → recovery + execution (Wave 2)
**Prompt (verbatim intent):** "Proceed with M3-4E Wave2. Priority: 1) Single-cell platform
(scanpy, scvi-tools, seurat, celltypist, harmony); 2) nf-core/scrnaseq integration;
3) Dorado + Remora platform. Defer VEP/SnpEff and Structure-AI unless a concrete project
requires them."

**Recovery context:** M3-4E build work from 2026-06-18/19 was on disk but **not committed to
git or handed off** (scanpy + scvi-tools registered; seurat + nf-core payloads staged). This
milestone finished and anchored it (git = authority; tmux/scratch = cache).

**Outcome:**
- Single-cell: promoted `seurat/2026-06-18` (5.5.0 + harmony 2.0.5) to the canonical store;
  built + registered `scanpy/2026-06-24` adding **CellTypist 1.7.1** (now current). Harmony
  present via harmonypy (scanpy) + harmony R (seurat). scvi-tools 1.4.2 GPU already registered.
- Pipelines: registered `nextflow/scrnaseq/4.1.0` (preview PASS; needs `NXF_SYNTAX_PARSER=v1`
  for an upstream missing-include vs Nextflow 26.04.3 strict parser) and `nextflow/rnaseq/3.26.0`
  (preview PASS). Container-first, local-reference (`igenomes_ignore`).
- Dorado + Remora (Tier-1 anchor): built + registered `dorado/2.0.1-cuda13.0` (dorado 2.0.1 +
  ont-remora 3.3.0, FROM pytorch base, torch cu130 preserved), GPU `--nv` validated (2-dev).
  Model-free; `reference/model/` scaffold created for on-first-use model install.
- Deferred: VEP/SnpEff, Structure-AI.

All via `analysis-install` (pinned + SHA256 + MANIFEST + current; `.def`/`pin.txt` recipes-of-record).
Handoff: `2026-07-01_m3-4E-wave2-singlecell-pipelines-dorado.md`.
