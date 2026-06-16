# PLATFORM ARCHITECTURE

**Status:** CANONICAL from 2026-06-16 (20260616-01). Defines the **common platform vs
project-specific** split, the platform's scientific scope, the container-first
operating model, and the reusable capability catalog. Sits above
REFERENCE_LAYER / CONTAINER_STANDARDS / PIPELINE_STANDARDS / RUNTIME_FOUNDATION.

---

## 1. Core distinction — Common Platform vs Project-Specific
| | **Common Platform Capabilities** | **Project-Specific Assets** |
|---|----------------------------------|------------------------------|
| What | reusable software, workflows, shared reference data/models | one project's code, raw data, configs, results, project-trained models |
| Where | `analysis/{container, pipeline, reference}` (incl. `reference/{…,singlecell,structure,model,nanopore}`) | `analysis/projects/<ID>/` (code/spec/results) + `/data/local/projects/<ID>/` (raw data) |
| Tied to a project? | **No** — must be reusable across many future projects; **never** named for P0001/P0002 | Yes — bound to one `<ID>` |
| Versioning | `analysis-install` (`<name>/<version>` + `current`); projects **pin** exact versions | project `ENVIRONMENT_MANIFEST.md` pins the platform versions it used |
**Rule:** anything reusable across ≥2 (potential) projects is a **platform capability**
and is installed project-agnostically. A project consumes platform capabilities by
pinning exact versions; it never re-installs them.

## 2. Intended scientific scope (capability domains)
The platform is built to support, as **reusable capabilities** (not as projects):
Core Human Genomics · Bulk RNA-seq & DEG · Single-cell genomics · Long-read
sequencing · Protein structure / foundation-model workflows · General AI/ML.
**Human references remain the default priority** (already installed, M3-4B).

## 3. Operating model — container-first, pipeline-driven (DEFAULT)
```
Project  →  Pipeline (Nextflow preferred; nf-core when suitable; Snakemake when appropriate)
         →  Container (provides ALL software + dependencies)
         →  Shared Reference (genomes, indexes, models, datasets — mounted read-only)
```
- **Containers provide software**; **references/indexes/models/datasets are external
  shared assets mounted into containers** (read-only, over the shared NFS at
  `/home/hha/analysis/reference`).
- **Host-installed software stays minimal** — only the `bio` utility env
  (RUNTIME_FOUNDATION Tier-1) + build tooling; everything heavy is containerized.
- Pipelines are pinned (PIPELINE_STANDARDS); engine-pulled images use the managed
  `_engine-cache`; **GPU-first, CPU-compatible** (ENVIRONMENT_POLICY §9).

## 4. Platform layers (where capabilities live)
- **`analysis/container/`** — software environments (functional containers).
- **`analysis/pipeline/`** — reusable workflows (`nextflow`/`snakemake`/`custom`).
- **`analysis/reference/`** — shared assets, **categories** (REFERENCE_LAYER):
  `genome · annotation · variation · index · singlecell · structure · model ·
  nanopore · resource`. New categories adopted here:
  - **`singlecell/`** — single-cell reference atlases / annotation resources
    (e.g. Azimuth references, marker sets).
  - **`structure/`** — protein-structure databases (e.g. AlphaFold genetic DBs:
    UniRef/BFD/MGnify/PDB) and reference structures.
  - **`model/`** — foundation/ML **model weights** (AlphaFold params, ESM, scVI,
    CellTypist, Dorado/Remora) — distinct from the *software* that runs them (containers).
All are version-governed via `analysis-install` and **project-agnostic**.

## 5. Reusable capability catalog (capabilities, NOT project definitions)
Built **on demand** (when first needed, or as deliberate platform investment), each via
container(+pipeline+reference). None implies a project.
| Domain | Software (→ container) | Pipeline | Shared assets (reference/) | GPU |
|--------|------------------------|----------|-----------------------------|-----|
| **Bulk RNA-seq / DEG** | DESeq2, edgeR, limma-voom, fgsea, GSVA, clusterProfiler (R/Bioconductor) | nf-core/rnaseq (+ DEG) | genome, annotation, index(STAR/salmon) ✅ | CPU |
| **Single-cell** | Seurat (R); Scanpy, scVI, CellTypist, Harmony, Azimuth (py/R) | nf-core/scrnaseq | `singlecell/` (Azimuth refs), `model/` (scVI, CellTypist) | scVI: GPU |
| **Protein / Structure** | AlphaFold, ESM, Chai, Boltz | custom | `structure/` (AF DBs ~TB-scale), `model/` (weights) | **GPU-heavy** |
| **Long-read** | minimap2, sniffles, cuteSV, modkit; Dorado/Remora (basecall/mod) | nf-core/nanoseq or custom | genome ✅, `model/` (Dorado/Remora) | Dorado/basecalling: GPU; SV/modkit: CPU |
| **General AI/ML** | PyTorch ✅ (TensorFlow, JAX as needed) | custom | `model/` (foundation models) | GPU |
Current: **pytorch** container ✅; STAR/Salmon indexes + human refs ✅. Others TBD.

## 6. Reconciliation & refinements
- **Human references** (GRCh38/GENCODE/dbSNP/ClinVar/indexes) are **Common Platform
  Capabilities** (serve all human-genomics projects), not P0001-specific. ✅
- **Long-read basecalling/modification models (Dorado/Remora)** are **platform
  capabilities** — reusable by *any* Nanopore project — and may be installed
  **independent of P0001** (refines the earlier "P0001-gated" deferral). The
  genuinely **project-specific** parts are: the raw signal data, and any
  study-specific modification training/ground-truth sets → those live with the project.
- **Storage caution (`structure/`):** AlphaFold genetic DBs are **multi-TB** (~2.5 TB)
  — a large fraction of the 11 TB `/data`. Treat as a deliberate, escalated install
  (RESOURCE_POLICY §4) when the structure capability is built; ESM/Boltz/Chai weights
  are far smaller (model/).
- **Licensing:** some assets/models are license-gated (e.g. COSMIC; some model weights)
  — operator provides credentials/acceptance (GOVERNANCE §2 cost/External).

## 7. Build policy
- Capabilities are added **on demand or as deliberate platform investment**, each as a
  version-governed container (+ pipeline + reference assets), never tied to a project name.
- A project (P0001, P0002, …) is approved separately (PROJECT_LIFECYCLE §3) and
  **consumes** platform capabilities by pinning exact versions — it does not define them.
- Human references remain the **default priority**; other capabilities follow the
  research-program tiers and actual project need.
