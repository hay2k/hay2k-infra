# CONTAINER STANDARDS

**Status:** CANONICAL from 2026-06-11 (M3-2, 20260611-01).
**Scope:** Structure, naming, versioning, and registration of containers under
`analysis/container/`. Realizes ANALYSIS_ARCHITECTURE.md §3 and VERSION_GOVERNANCE.md
via the `analysis-install` tool (VERSION_MANAGEMENT_TOOLING.md).

---

## 1. Structure
```
analysis/container/
├── apptainer/    # derived EXECUTION artifacts (*.sif) — what jobs run
│   └── <env>/<version>/<env>-<version>.sif  (+ .sif.sha256 via tool MANIFEST)
│   └── <env>/current -> <version>
└── docker/       # canonical SOURCES only (no daemon): pinned OCI ref + MANIFEST
    └── <env>/<version>/MANIFEST.md   (docker://repo@sha256:..., digest, source, notes)
```
**Organized by functional environment, not by pipeline** (e.g. `pytorch`,
`tensorflow`, `bio-r`, `nfcore`).

## 2. Naming
- **env:** lowercase, concise functional name (`pytorch`, not a pipeline name).
- **version:** the upstream framework version **plus the CUDA line**, mirroring the
  source tag for traceability — e.g. `2.9.1-cuda13.0`. (Matches the source
  `pytorch/pytorch:2.9.1-cuda13.0-cudnn9-runtime`.)
- Entry point is always **`<env>/current`** (VERSION_GOVERNANCE.md §2.1).

## 3. Source → runtime chain (no Docker daemon)
1. **Canonical source = the upstream OCI image, pinned by digest**
   (`docker://repo@sha256:...`), recorded in `container/docker/<env>/<version>/MANIFEST.md`.
2. **Derived runtime = the Apptainer `.sif`**, built locally then registered onto NFS:
   ```
   apptainer build /local/tmp/<env>-<version>.sif docker://repo@sha256:<digest>   # build off-NFS (N3)
   analysis-install install container apptainer <env> <version> \
       --from /local/tmp/<env>-<version>.sif \
       --source 'docker://repo@sha256:<digest>' \
       --accel both --set-current        # GPU-first: accel=both ⇒ preferred=gpu
   ```
3. The tool records the **SIF SHA256**, writes the per-version `MANIFEST.md`, appends
   `VERSIONS.md` and the central install log, and sets `current` atomically.

## 4. Versioning, registration, rollback
- Version-named dirs + `current`; **never overwrite** a version; **no silent
  upgrades** (projects pin exact `apptainer/<env>/<version>` + SHA256).
- Register/track/switch/rollback via `analysis-install`
  (`install / set-current / rollback-current / verify / pin / list`).
- **GPU-first, CPU-compatible** (ENVIRONMENT_POLICY.md §9): GPU containers register
  `--accel both` (or `gpu`); CPU-only register `--accel cpu`. `accel=both` defaults
  `preferred=gpu`.
- **`--regenerable`** is appropriate for SIFs (rebuildable from the pinned digest →
  backup-excluded; BACKUP/ANALYSIS_ARCHITECTURE §7.2).

## 5. Execution
Run with GPU passthrough: `apptainer exec --nv <env>/current/<env>-<version>.sif ...`.
Engine-fetched containers (Nextflow/nf-core) use the managed cache
`apptainer/_engine-cache/` (ANALYSIS_ARCHITECTURE.md §3), pinned by pipeline revision.

## 6. Scope discipline
Build containers deliberately, not speculatively (GOVERNANCE.md §0). **pytorch** is
the first (Tier-1-serving). Add further functional environments only when a real need
exists.
