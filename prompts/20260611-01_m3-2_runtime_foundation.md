# 20260611-01 — M3-2: Runtime Foundation

**Date:** 2026-06-11
**Role:** User (operator `hha`) → first runtime implementation phase
**Outcome:** Installed Tier-1 host `bio` conda env (Miniforge; 11 tools / 62 pinned
pkgs; `infra/bio-environment.yml`; `conda activate bio`) on gpu-01, and built +
`--nv`-validated + registered the first Tier-2 production container (PyTorch
2.9.1-cuda13.0, digest-pinned source, SIF SHA256 recorded, `current` set, accel=both/
preferred=gpu) via `analysis-install`. Closes deferred Phase B GPU validation. New
canonical docs: RUNTIME_FOUNDATION, CONTAINER_STANDARDS, BIO_ENVIRONMENT. GPU-first
enforced. **No pipelines/references/projects; no P0001.**

---

## Verbatim prompt (operative content)

> Proceed with M3-2 — Runtime Foundation. First runtime implementation phase. Use
> `analysis-install` where appropriate. Do NOT install research pipelines, populate
> references, create projects, or create P0001.
>
> Objective: establish the foundational runtime separating (1) core bioinformatics
> utilities, (2) containerized software, (3) future project-specific software.
> Runtime philosophy: small/stable/frequent utilities on the host; large/complex/
> fast-changing software containerized; GPU-first, CPU-compatible.
>
> Task 1: design + implement a shared `bio` conda/mamba environment (`conda activate
> bio`); evaluate location/management; review the tool list (samtools, bcftools,
> htslib, bedtools, tabix, bgzip, seqkit, pigz, parallel, csvtk, jq, yq, ripgrep).
> Task 2: integrate bio into governance docs (purpose, update policy, version
> tracking, relationship with analysis-install). Task 3: design first container
> standards (container/apptainer structure, naming, versioning, registration) — do
> not build many. Task 4: build + register the first production container (PyTorch)
> at analysis/container/apptainer/pytorch/<version> with current symlink; record
> source, version, SHA256, manifest.
>
> Validate: bio activation; version tracking; container registration; current symlink;
> rollback compatibility. Deliverables: Runtime Foundation / Container Standards / Bio
> environment docs; update IMPLEMENTATION_LOG, INFRA_CHANGELOG, prompt archive.
