# BIO ENVIRONMENT (shared host bioinformatics utilities)

**Status:** CANONICAL from 2026-06-11 (M3-2, 20260611-01).
**Scope:** The shared, host-level `bio` conda/mamba environment of broadly-useful
bioinformatics utilities. Realizes the runtime philosophy (RUNTIME_FOUNDATION.md):
*small, stable, frequently-used utilities live directly on the host.*

---

## 1. Purpose
A single, stable, host-level environment of small CLI utilities that nearly every
project uses — so they are always available without per-project installs and without
containerization overhead. Large/complex/rapidly-changing software is **not** here;
it is containerized (CONTAINER_STANDARDS.md).

## 2. Provider, location, activation
- **Provider:** Miniforge (conda + mamba), conda-forge default + bioconda.
  conda 26.3.2 / mamba 2.5.0; installer SHA256 recorded in IMPLEMENTATION_LOG (M3-2).
- **Location:** `/data/local/runtime/miniforge3` — **per-node local on `/data`** (no
  root; relocated from `~/miniforge3` in M3-3D, installed on **all 3 nodes**). Matches the
  existing `~/.local` toolchain pattern and the runtime philosophy (host-local for
  speed; conda envs are not NFS-friendly).
- **Activation:** `conda activate bio` (enabled via `conda init bash`).
- **Login exposure:** a defined subset of **general-purpose** utilities
  (`bat eza fd rg fzf btop jq yq tree pv parallel`) is also reachable in a **fresh login
  shell without activation**, via the Runtime Utility Exposure Layer (symlinks into
  `~/.local/bin`; RUNTIME_FOUNDATION.md §5, RUNTIME_TOOLS.md, `scripts/expose-runtime-utils.sh`).
  Scientific tools (`samtools`/`bcftools`/`bedtools`/`seqkit`/`csvtk`/…) stay
  activation/container-only by policy.

## 3. Final tool list (M3-2)
`samtools`, `bcftools`, `htslib` (provides **bgzip + tabix**), `bedtools`, `seqkit`,
`csvtk`, `pigz`, `parallel`, `jq`, `yq`, `ripgrep`.
- **Rationale / review:** explicit `tabix`/`bgzip` packages were **omitted** — both
  binaries ship with `htslib` (and `samtools`/`bcftools` depend on it), avoiding
  duplicate-binary conflicts. `jq`/`ripgrep` are also host-level low-risk utilities
  (GOVERNANCE §2.1) but are included for a self-contained env. Only **broadly useful**
  tools belong here.
- Installed versions (M3-2): samtools/bcftools/htslib 1.23.1, bedtools 2.31.1,
  seqkit 2.13.0, csvtk 0.37.0, pigz 2.8, GNU parallel 20260422, jq 1.8.1, yq 3.4.3,
  ripgrep 14.1.1.

## 4. Version tracking (reproducibility)
- The **fully pinned** environment (62 packages, exact versions+builds) is exported to
  **`infra/bio-environment.yml`** (version-controlled) — the lockfile of record.
- Rebuild a clean host with: `mamba env create -n bio -f infra/bio-environment.yml`.
- A result that depends on a `bio` tool records the tool+version in the project
  `ENVIRONMENT_MANIFEST.md` (GOVERNANCE §4).

## 5. Update policy
- **Add only broadly-useful tools** (used across many projects); project-specific or
  heavy/fast-moving software is containerized instead (medium-risk, Supervisor
  judgment per ENVIRONMENT_POLICY §1/§2.2).
- On any change: update the env, **re-export `infra/bio-environment.yml`**, and log it
  (INFRA_CHANGELOG). Never mutate silently.
- **Replication:** install on every node where work runs (per-node, host-local). M3-2
  installed `bio` on **gpu-01**; replicate to gpu-02/gpu-03 via
  `mamba env create -f infra/bio-environment.yml` (the toolchain replication pattern)
  so research bursting and other domains have it cluster-wide. *(Replication to peers
  is a follow-up operational step — see M3-2 risks.)*

## 6. Relationship with `analysis-install`
- **`bio` is NOT managed by `analysis-install`.** The boundary is deliberate:
  - **Host utilities (small, stable)** → the `bio` conda env (this doc).
  - **Containers / pipelines / references (large, versioned, project-pinned)** →
    `analysis-install` under `analysis/` (VERSION_MANAGEMENT_TOOLING.md).
- `bio` is reproduced from its committed `bio-environment.yml`; `analysis-install`
  artifacts are reproduced from their version dirs + SHA256/digests. Two complementary
  reproducibility paths, one boundary (host vs shared/versioned).

## 7. GPU-first note
`bio` is CPU utility software (compatibility/fallback layer). GPU-accelerated work
runs in containers (CONTAINER_STANDARDS.md) under the GPU-first policy
(ENVIRONMENT_POLICY.md §9).
