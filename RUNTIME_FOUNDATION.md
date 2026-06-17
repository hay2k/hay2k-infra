# RUNTIME FOUNDATION

**Status:** CANONICAL from 2026-06-11 (M3-2, 20260611-01).
**Scope:** The foundational runtime environment all projects use, and the boundary
between its three tiers. Indexes BIO_ENVIRONMENT.md, CONTAINER_STANDARDS.md, and
VERSION_MANAGEMENT_TOOLING.md.

---

## 1. Runtime philosophy
- **Small, stable, frequently-used utilities → directly on the host** (the `bio`
  conda env, per-node, user-space).
- **Large, complex, rapidly-changing software → containerized** (Apptainer SIFs under
  `analysis/container/`, versioned + registered via `analysis-install`).
- **GPU-first, CPU-compatible** (ENVIRONMENT_POLICY.md §9): prefer GPU execution when
  mature; keep a CPU path; both maintained where practical.
- **Operator experience vs scientific control (the exposure boundary).**
  *General-purpose* runtime utilities are part of the **operator experience** and must
  behave like normal Linux commands **immediately after login** — no `conda activate`.
  *Scientific / bioinformatics* software stays **environment-controlled and
  container-first** (activate `bio`, or run inside a container/pipeline). `bio` remains
  the single source of truth for both; the difference is only **what is exposed to the
  login PATH** (see §5).

## 2. The three runtime tiers
| Tier | What | Where | Managed by | Reproduced from |
|------|------|-------|------------|------------------|
| **1. Core bioinformatics utilities** | small CLI tools (samtools, bcftools, bedtools, seqkit, …) | host **`/data/local/runtime/miniforge3`** env **`bio`** (per-node, all 3 nodes) | conda/mamba | `infra/bio-environment.yml` |
| **2. Containerized software** | frameworks / complex stacks (e.g. **pytorch**) | `analysis/container/apptainer/<env>/<version>/` (shared NFS) | **`analysis-install`** | pinned OCI digest → SIF + SHA256 |
| **3. Project-specific software** | per-project deps not broadly shared | the project tree (`uv`/env/container as appropriate) | per-project (pinned) | project `ENVIRONMENT_MANIFEST.md` |

Decision rule (extends ENVIRONMENT_POLICY.md §7): broadly-useful small utility →
Tier 1 (`bio`); needs full/GPU/system reproducibility or is large/shared → Tier 2
(container); narrow to one project → Tier 3 (project-local, pinned).

## 3. How the tiers interrelate
- A pipeline step typically runs **inside a Tier-2 container** (`apptainer exec --nv`)
  while small glue/QC uses **Tier-1 `bio`** tools on the host.
- Tier-2/3 versions are **pinned per project**; `current` is a human convenience, never
  a recorded provenance value (VERSION_GOVERNANCE.md).
- Containers register `--accel`/`--preferred` so the **GPU-first** preference is
  explicit and recorded.

## 4. M3-2 state
- **Tier 1:** `bio` env installed on gpu-01 (validated; `conda activate bio`), pinned
  to `infra/bio-environment.yml`. Replication to peers is a documented follow-up.
- **Tier 2:** first production container **pytorch** registered under
  `analysis/container/apptainer/pytorch/<version>/` (CONTAINER_STANDARDS.md;
  details + SHA256 in IMPLEMENTATION_LOG M3-2).
- **Tier 3:** governed by PROJECT_SPECIFICATION_POLICY/ENVIRONMENT_POLICY; **no
  project created** (M3-2 builds no project).

## 5. Runtime Utility Exposure Layer (operator experience)
**Added 2026-06-17 (M3-4D follow-up, 20260617-02).** Implements the exposure boundary
in §1.

- **Mechanism:** per-node symlinks in **`~/.local/bin`** → the corresponding binary in
  the `bio` env (`/data/local/runtime/miniforge3/envs/bio/bin/<tool>`). `~/.local/bin`
  is already first-class on the login PATH via the stock `~/.bashrc`, so the tools work
  in a **fresh login shell with no `conda activate`**. Symlinks (not copies) keep `bio`
  the single source of truth; conda RPATH (`$ORIGIN/../lib`) resolves the env's shared
  libs through the symlink, so no `LD_LIBRARY_PATH` or activation is needed.
- **Managed by:** `infra/scripts/expose-runtime-utils.sh` (idempotent; `--remove` to
  roll back). Run **per node** (home is local per-node). The script carries the
  authoritative **allow-list** and a safety **deny-list**.
- **Globally exposed (general-purpose only):** `bat eza fd rg fzf btop jq yq tree pv
  parallel`.
- **Deliberately NOT exposed (scientific → env/container-first):** `samtools bcftools
  bedtools seqkit csvtk` and all heavier bioinformatics software. These remain available
  via `conda activate bio`, containers, and pipelines only.
- **PATH strategy:** no PATH edits introduced. Login PATH order keeps base-conda `bin`
  ahead of `~/.local/bin`; none of the exposed tools exist in base, so symlinks resolve
  unambiguously (a lower-priority system `jq` in `/usr/bin` is correctly overridden).
- Full registry + per-tool table: **RUNTIME_TOOLS.md**.

## 6. Pointers
BIO_ENVIRONMENT.md (Tier 1) · CONTAINER_STANDARDS.md (Tier 2) ·
VERSION_MANAGEMENT_TOOLING.md (`analysis-install`) · ENVIRONMENT_POLICY.md §7/§9 ·
ANALYSIS_ARCHITECTURE.md · RUNTIME_TOOLS.md + `scripts/expose-runtime-utils.sh`
(exposure layer).
