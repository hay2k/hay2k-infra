# RUNTIME TOOLS

**Status:** CANONICAL from 2026-06-16 (M3-4D, 20260617-01); **exposure layer added
2026-06-17 (20260617-02)**. Lightweight host-level productivity utilities — **Runtime
Foundation Tier-1** (RUNTIME_FOUNDATION.md), **NOT platform capabilities**. All live in
the per-node `bio` conda env (`/data/local/runtime/miniforge3/envs/bio`), pinned in
**`infra/bio-environment.yml`**, present on **all 3 nodes**. `bio` is the **single
source of truth** for every tool below.

> Install method (all): `mamba install -n bio -c conda-forge [-c bioconda] <tool>`
> (reproducible; pinned via the committed lockfile). Node scope (all): gpu-01/02/03.
> Heavy/complex software is delivered via **containers** (PLATFORM_ARCHITECTURE), not here.

## Exposure boundary (operator experience vs scientific control)
There are two ways a `bio` tool reaches you, and the choice is deliberate
(RUNTIME_FOUNDATION.md §1, §5):

- **🌐 Login-exposed** — general-purpose utilities behave like normal Linux commands
  **immediately after login, no `conda activate`**. Exposed via per-node symlinks in
  `~/.local/bin` → the `bio` binary, created by `scripts/expose-runtime-utils.sh`
  (symlinks, not copies → `bio` stays the source of truth).
- **🔒 Env-controlled** — scientific / bioinformatics tools are **only** available after
  `conda activate bio`, or inside containers / pipelines. They are intentionally **not**
  on the login PATH (keeps the host clean and scientific software version-controlled).

The exposed set (the *only* tools symlinked) is the allow-list in
`scripts/expose-runtime-utils.sh`: `bat eza fd rg fzf btop jq yq tree pv parallel`.

## General CLI (all 🌐 login-exposed)
| Tool | Version | Exposure | Purpose |
|------|---------|----------|---------|
| bat | 0.26.1 | 🌐 login | `cat` with syntax highlighting + paging |
| eza | (cf) | 🌐 login | modern `ls` replacement |
| fd | 10.4.2 | 🌐 login | fast `find` replacement (pkg `fd-find`) |
| fzf | 0.73 | 🌐 login | fuzzy finder (interactive filter) |
| ripgrep (`rg`) | 15.1.0 | 🌐 login | fast recursive grep |
| btop | 1.4.7 | 🌐 login | resource/process monitor |
| tree | 2.3.2 | 🌐 login | directory tree view |
| pv | 1.6.6 | 🌐 login | pipe throughput/progress meter |
| jq | 1.8.1 | 🌐 login | JSON processor |
| yq | 3.4.3 | 🌐 login | YAML/JSON processor |

## Bioinformatics productivity
| Tool | Version | Exposure | Purpose |
|------|---------|----------|---------|
| parallel | 20260422 | 🌐 login | GNU parallel (general shell parallelism) |
| pigz | 2.8 | 🔒 `bio` | parallel gzip |
| seqkit | 2.13.0 | 🔒 `bio` | FASTA/FASTQ inspection & manipulation |
| csvtk | 0.37.0 | 🔒 `bio` | CSV/TSV manipulation |
| samtools | 1.23.1 | 🔒 `bio` | SAM/BAM/CRAM (also bgzip/tabix via htslib) |
| bcftools | 1.23.1 | 🔒 `bio` | VCF/BCF manipulation |
| bedtools | 2.31.1 | 🔒 `bio` | genome interval arithmetic |

🌐 = available in any login shell (symlinked to `~/.local/bin`). 🔒 = requires
`conda activate bio` / container / pipeline. `parallel` is general-purpose and exposed;
`pigz` stays env-controlled (not in the exposure allow-list — add it there if it becomes
a routine interactive tool).

## Notes
- **Avoid redundancy:** these are small host utilities; pipeline/analysis software
  (aligners, callers, R/Bioconductor, deep-learning) is provided by **platform
  containers** (CONTAINER_STANDARDS) — do not duplicate them here.
- **Reproducible rebuild (tools):** `mamba env create -n bio -f infra/bio-environment.yml`.
- **Reproducible rebuild (exposure):** `bash scripts/expose-runtime-utils.sh` (per node;
  idempotent). Rollback: `bash scripts/expose-runtime-utils.sh --remove`.
- **Update policy (tools):** add only broadly-useful host utilities; on change, re-export
  `bio-environment.yml` + log (BIO_ENVIRONMENT.md §5).
- **Update policy (exposure):** to expose/unexpose a tool, edit the `EXPOSE` allow-list
  in `scripts/expose-runtime-utils.sh` and re-run on all nodes — never hand-create
  symlinks. Keep scientific tools (`samtools`/`bcftools`/`bedtools`/`seqkit`/`csvtk`/…)
  **off** the allow-list: they stay `bio`/container/pipeline-only by policy.
