# 20260616-01 — Platform architecture: common-platform vs project-specific

**Date:** 2026-06-16
**Role:** User (operator `hha`) → architecture/governance update
**Outcome:** Created PLATFORM_ARCHITECTURE.md formalizing the Common Platform
Capabilities vs Project-Specific Assets distinction; platform scientific scope;
container-first/pipeline-driven operating model (Project→Pipeline→Container→Shared
Reference); reusable capability catalog (bulk RNA-seq, single-cell, protein/structure,
long-read) as capabilities not projects. Added reference categories
`singlecell/structure/model/nanopore`. Reclassified Dorado/Remora as platform
capabilities (not P0001-gated). Documentation only; no installs. Human refs remain
default priority.

---

## Verbatim prompt

> Review and update the reference/platform architecture with the following principles.
>
> 1. Distinguish between: A. Common Platform Capabilities  B. Project-Specific Assets.
>    Common Platform Capabilities should be reusable across many future projects and
>    not tied to P0001, P0002, or any specific project.
> 2. The cluster is intended to support: Core Human Genomics; Bulk RNA-seq and DEG;
>    Single-cell genomics; Long-read sequencing; Protein structure / foundation-model
>    workflows; General AI/ML workflows.
> 3. Consider reusable platform categories: singlecell/ structure/ model/ or equivalent.
> 4. Container-first, pipeline-driven execution is the default operating model:
>    Project → Pipeline (Nextflow preferred; nf-core when suitable; Snakemake when
>    appropriate) → Container → Shared Reference. Containers provide software;
>    references/indexes/models/datasets remain external shared assets mounted into
>    containers; host-installed software minimal.
> 5. Evaluate additional reusable platform capabilities — Bulk RNA-seq (DESeq2, edgeR,
>    limma-voom, fgsea, GSVA, clusterProfiler); Single-cell (Seurat, Scanpy, Harmony,
>    CellTypist, Azimuth, scVI); Protein/Structure (AlphaFold, ESM, Chai, Boltz);
>    Long-read (minimap2, sniffles, cuteSV, modkit) — as platform capabilities rather
>    than project definitions. Human references remain the default priority.
