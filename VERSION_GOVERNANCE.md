# VERSION GOVERNANCE

**Status:** CANONICAL from 2026-06-06 (promoted M3-0, 20260606-01). Supersedes the
M2-2 draft in `ChatGPT_handoff/`. This is the canonical version-management standard;
it consolidates the inline version model of ANALYSIS_ARCHITECTURE.md §4/§7 (which
remains as architectural context).
**Scope:** How pipelines, containers, and references are versioned, selected, pinned.
**Applies per domain** (each domain's own container/pipeline/reference store under
its tree); examples use the Research domain (`analysis/`). Shared `analysis/` NFS
(M2-1) is unchanged.

---

## 1. Rationale
Reproducibility (GOVERNANCE.md §4) requires exact, coexisting, **non-silently-
changing** versions. The model keeps the default switchable for humans (`current`)
while keeping provenance pinned.

## 2. Frozen decisions
- **Version-named directories** for installed/fetched third-party artifacts:
  `<name>/<version>/` (e.g. `nf-core-rnaseq/3.21/`, `pytorch/2.9-cuda13/`,
  `ensembl-110/`) — the required exception to DIRECTORY_STANDARD.md §5.
- **`<name>/current` is the canonical entry point** (no bare-name symlink).
- **New installs default to latest stable**; `current` advanced **explicitly and
  logged** — never automatically.
- **Projects pin EXACT versions** in `ENVIRONMENT_MANIFEST.md` (never `current`).
- **No silent upgrades:** moving `current` never rewrites a project's pin.
- **Containers:** Docker/OCI image = canonical source (pinned `@sha256:`) recorded in
  `container/docker/<env>/<ver>/MANIFEST.md`; Apptainer `.sif` = derived runtime +
  SHA256 sidecar; **no Docker daemon**.
- **Security patches = a new version** (advance `current` explicitly); **never patch
  in place**.
- **Atomic `current` swaps:** temp symlink → `mv -Tf` (`rename(2)`) under `flock` on
  the shared FS; never `rm`+`ln`. Cross-node visibility is eventually-consistent;
  runs pin exact versions, so this is safe.
- **`.regenerable` marker** in every regenerable version dir drives backup exclusion.
- **Engine cache:** `NXF_SINGULARITY_CACHEDIR` → managed
  `container/apptainer/_engine-cache/`; engine-pulled images pinned by pipeline
  revision.

## 3. Examples
```
analysis/pipeline/nextflow/nf-core-rnaseq/{3.21/, current -> 3.21, VERSIONS.md}
analysis/container/apptainer/pytorch/{2.9-cuda13/, current -> 2.9-cuda13, VERSIONS.md}
analysis/container/docker/pytorch/2.9-cuda13/MANIFEST.md   # docker://...@sha256, digest, source

# project pin (ENVIRONMENT_MANIFEST.md):
pipeline:  nextflow/nf-core-rnaseq/3.21
container: apptainer/pytorch/2.9-cuda13  (sha256: <...>)
reference: genomes/homo_sapiens/GRCh38/ensembl-110
```

## 4. Version lifecycle
1. **Install** → `flock`; create `<name>/<version>/`; populate; record SHA256/digest
   + `VERSIONS.md` entry; drop `.regenerable` if regenerable.
2. **Default** → advance `current` atomically, logged.
3. **Pin** → project records the resolved exact version.
4. **Patch/upgrade** → new version dir; migrate projects deliberately (logged).
5. **Retire** → only when no project manifest references it; record stays.

## 5. Future scalability
- **GC/retention:** periodic unreferenced-version sweep + the disk-pressure
  reclamation runbook (ANALYSIS_ARCHITECTURE.md §7.1).
- **Tooling:** **implemented in M3-1** — `infra/scripts/analysis-install` encodes the
  lifecycle (atomic `current`, `flock`, `.regenerable`, manifest + SHA256, central
  log, pin, rollback). See VERSION_MANAGEMENT_TOOLING.md.
- Applies uniformly to `reference/` and to each domain's stores.
