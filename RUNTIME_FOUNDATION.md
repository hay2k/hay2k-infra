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

## 2. The three runtime tiers
| Tier | What | Where | Managed by | Reproduced from |
|------|------|-------|------------|------------------|
| **1. Core bioinformatics utilities** | small CLI tools (samtools, bcftools, bedtools, seqkit, …) | host `~/miniforge3` env **`bio`** (per-node) | conda/mamba | `infra/bio-environment.yml` |
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

## 5. Pointers
BIO_ENVIRONMENT.md (Tier 1) · CONTAINER_STANDARDS.md (Tier 2) ·
VERSION_MANAGEMENT_TOOLING.md (`analysis-install`) · ENVIRONMENT_POLICY.md §7/§9 ·
ANALYSIS_ARCHITECTURE.md.
