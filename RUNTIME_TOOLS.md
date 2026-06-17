# RUNTIME TOOLS

**Status:** CANONICAL from 2026-06-16 (M3-4D, 20260617-01). Lightweight host-level
productivity utilities — **Runtime Foundation Tier-1** (RUNTIME_FOUNDATION.md), **NOT
platform capabilities**. All live in the per-node `bio` conda env
(`/data/local/runtime/miniforge3/envs/bio`; `conda activate bio`), pinned in
**`infra/bio-environment.yml`**, present on **all 3 nodes**.

> Install method (all): `mamba install -n bio -c conda-forge [-c bioconda] <tool>`
> (reproducible; pinned via the committed lockfile). Node scope (all): gpu-01/02/03.
> Heavy/complex software is delivered via **containers** (PLATFORM_ARCHITECTURE), not here.

## General CLI
| Tool | Version | Purpose |
|------|---------|---------|
| bat | 0.26.1 | `cat` with syntax highlighting + paging |
| eza | (cf) | modern `ls` replacement |
| fd | 10.4.2 | fast `find` replacement (pkg `fd-find`) |
| fzf | 0.73 | fuzzy finder (interactive filter) |
| ripgrep (`rg`) | 15.1.0 | fast recursive grep |
| btop | 1.4.7 | resource/process monitor |
| tree | 2.3.2 | directory tree view |
| pv | 1.6.6 | pipe throughput/progress meter |
| jq | 1.8.1 | JSON processor |
| yq | 3.4.3 | YAML/JSON processor |

## Bioinformatics productivity
| Tool | Version | Purpose |
|------|---------|---------|
| seqkit | 2.13.0 | FASTA/FASTQ inspection & manipulation |
| csvtk | 0.37.0 | CSV/TSV manipulation |
| pigz | 2.8 | parallel gzip |
| parallel | 20260422 | GNU parallel (shell parallelism) |
| samtools | 1.23.1 | SAM/BAM/CRAM (also bgzip/tabix via htslib) |
| bcftools | 1.23.1 | VCF/BCF manipulation |
| bedtools | 2.31.1 | genome interval arithmetic |

## Notes
- **Avoid redundancy:** these are small host utilities; pipeline/analysis software
  (aligners, callers, R/Bioconductor, deep-learning) is provided by **platform
  containers** (CONTAINER_STANDARDS) — do not duplicate them here.
- **Reproducible rebuild:** `mamba env create -n bio -f infra/bio-environment.yml`.
- **Update policy:** add only broadly-useful host utilities; on change, re-export
  `bio-environment.yml` + log (BIO_ENVIRONMENT.md §5).
