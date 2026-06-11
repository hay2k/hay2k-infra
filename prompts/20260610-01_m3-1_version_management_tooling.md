# 20260610-01 — M3-1: version-management tooling

**Date:** 2026-06-10
**Role:** User (operator `hha`) → first implementation phase (post-governance)
**Outcome:** Built + validated `analysis-install` (version-management framework:
versioned install, atomic `current`, manifests, SHA256, logging, rollback, pin,
verify, pipeline/container/reference tracking) with a self-contained test suite
(23/23 PASS against throwaway dirs). Added the **Accelerated Computing Policy**
(GPU-first, CPU-compatible; ENVIRONMENT_POLICY §9) and operationalized it via
`accel`/`preferred`. Docs in VERSION_MANAGEMENT_TOOLING.md. **No pipelines/containers/
references/projects installed; no P0001.** Logs + this prompt updated.

---

## Verbatim prompt (operative content)

> Proceed with M3-1 — Version Management Tooling. First implementation phase after
> M2 governance closure. Do NOT install pipelines/containers, populate references,
> create projects, download datasets, or create P0001 — tooling and operational
> framework only.
>
> New policy — Accelerated Computing Policy: when both CPU and GPU implementations
> exist, install/maintain both; CPU = compatibility/fallback; GPU = preferred when
> stable/reproducible/maintained; new projects default to GPU when mature. Principle:
> GPU-first, CPU-compatible. Incorporate into the implementation framework.
>
> Objective: design + implement the version-management framework that will later
> manage pipelines, containers, references, and future tooling. Create/validate
> `analysis-install` (or equivalent) supporting: versioned install <name>/<version>;
> current symlink; atomic current switching; version manifests; SHA256 recording;
> installation logging; rollback; project reproducibility; pipeline/container/
> reference tracking. Validate against dummy examples / empty test dirs only — do
> NOT install real software/containers/references.
>
> Deliverables: tooling, documentation, test cases, operational examples, rollback
> examples; update IMPLEMENTATION_LOG, INFRA_CHANGELOG, prompt archive.
