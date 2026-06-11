# PIPELINE STANDARDS

**Status:** CANONICAL from 2026-06-11 (M3-3, 20260611-02).
**Scope:** Structure, naming, versioning, registration, and execution of pipelines
under `analysis/pipeline/`. Realizes ANALYSIS_ARCHITECTURE.md §2 + VERSION_GOVERNANCE.md
via `analysis-install`; runs steps in registered containers (CONTAINER_STANDARDS.md).
Tier-2/workflow layer of RUNTIME_FOUNDATION.md.

---

## 1. Structure
```
analysis/pipeline/
├── nextflow/   # Nextflow / nf-core workflows
├── snakemake/  # Snakemake workflows
└── custom/     # first-party / bespoke pipelines
    └── <tool>/<version>/   (+ <tool>/current -> <version>)
```
Engine groups: `nextflow | snakemake | custom`.

## 2. Naming & versioning
- **tool:** concise workflow name (e.g. `nf-core-rnaseq`, `runtime-smoke`).
- **version:** the upstream revision (e.g. `3.21`) for installed workflows, or a git
  tag for `custom` first-party pipelines.
- Entry point is always **`<tool>/current`** (VERSION_GOVERNANCE.md). Never overwrite
  a version; no silent upgrades; projects pin the exact `<engine>/<tool>/<version>`.

## 3. Registration (via `analysis-install`)
```
analysis-install install pipeline <engine> <tool> <version> \
    --from <prepared workflow dir> --source '<provenance>' \
    --accel <cpu|gpu|both> --preferred <cpu|gpu> --set-current
```
Records SHA256 + `MANIFEST.md`, appends `VERSIONS.md` + the central log, sets
`current` atomically. Track/switch/rollback/verify/pin with the same tool.
First-party (`custom`) workflow definitions are precious source (version-controlled,
**not** `--regenerable`).

## 4. Execution — engine → container(`--nv`) → GPU
- Workflow **steps run inside registered containers** (CONTAINER_STANDARDS.md), e.g.
  a Snakemake/Nextflow rule invoking `apptainer exec --nv <env>/current/<sif> …`.
- **GPU-first, CPU-compatible** (ENVIRONMENT_POLICY.md §9): GPU pipelines register
  `--accel both`/`gpu`; the container they call carries the actual GPU stack.
- **Nextflow** requires `JAVA_HOME=~/.local/jdk-21`; use current DSL2 syntax.

## 5. Engine container cache (N1)
Nextflow/nf-core fetch their own per-process images into the **managed cache**
`analysis/container/apptainer/_engine-cache/` (created M3-3), via
`NXF_SINGULARITY_CACHEDIR` (set in `infra/scripts/analysis-env.sh`). Engine-fetched
images are pinned by the **pipeline revision** (a documented exception, not a second
container regime).

## 6. Reproducibility
A pipeline result records, in the project `ENVIRONMENT_MANIFEST.md`: the exact
`pipeline=<engine>/<tool>/<version>` (+ SHA256), the `container=apptainer/<env>/<version>`
(+ SHA256), and any `reference=<…>/<version>` it used (GOVERNANCE §4). `current` is a
human convenience, never a recorded provenance value.

## 7. M3-3 state & scope discipline
- First pipeline registered: **`custom/runtime-smoke/0.1`** — a neutral,
  project-independent validation harness (engine → `--nv` container → GPU); validated
  on both Snakemake and Nextflow.
- **Research-specific pipelines (e.g. nf-core workflows) are NOT installed** — that is
  an operator-directed step, normally coupled to an approved project
  (PROJECT_LIFECYCLE.md §3), and avoids speculative multi-GB pulls (GOVERNANCE §0).
