# VERSION MANAGEMENT TOOLING

**Status:** CANONICAL from 2026-06-10 (M3-1, 20260610-01).
**Scope:** The `analysis-install` tool that operationalizes VERSION_GOVERNANCE.md for
pipelines, containers, and references. Tested only against throwaway directories —
**no real software/containers/references are installed by M3-1.**

---

## 1. Purpose & architecture
`infra/scripts/analysis-install` is a dependency-free Bash CLI that manages versioned
installation under `ANALYSIS_ROOT` (default `/home/hha/analysis`):

```
$ANALYSIS_ROOT/<kind>/<group>/<name>/<version>/        # the artifact payload
                                    /current -> <ver>   # atomic entry-point symlink
                                    /VERSIONS.md         # per-tool append-only log
                .../<version>/MANIFEST.md                # per-version manifest
$ANALYSIS_ROOT/.analysis-install.log                     # central TSV operation log
```
- **kinds:** `pipeline | container | reference`
- **groups:** pipeline→`{nextflow,snakemake,custom}`; container→`{apptainer,docker}`;
  reference→`<category>` (e.g. `genomes`)
- **Concurrency-safe:** every mutating op takes a `flock` on `<name>/.lock`; `current`
  is switched with a temp symlink + `mv -Tf` (`rename(2)`, atomic, NFS-safe).
- **Testable/portable:** set `ANALYSIS_ROOT` to a temp dir to dry-run anywhere.
- **Does not download or build** — you supply artifacts via `--from`; the tool
  records/places/version-manages them.

## 2. Capabilities (maps to the M3-1 targets)
1. Versioned install `<name>/<version>` — `install` (never overwrites an existing version)
2. `current` symlink management — `--set-current`, `set-current`, `show-current`
3. Atomic switching — temp-symlink + `rename(2)` under `flock`
4. Version manifests — `MANIFEST.md` per version
5. SHA256 recording — `payload_hash` recorded; `--sha256` hard-stop on mismatch
6. Installation logging — central `.analysis-install.log` + per-tool `VERSIONS.md`
7. Rollback — `rollback-current` (revert to previous), `remove` (retire a version)
8. Project reproducibility — `pin` resolves `current`→concrete `version`+sha (never pin `current`)
9/10/11. Pipeline / container / reference tracking — uniform model + `list`

## 3. GPU-first policy hook (ENVIRONMENT_POLICY.md §9)
`--accel cpu|gpu|both` and `--preferred cpu|gpu` are recorded per version. `--accel
both` defaults `preferred=gpu` (**GPU-first, CPU-compatible**). Projects record which
path produced a result.

## 4. Operational examples
```bash
# Install a pipeline version and make it the default (atomic current):
analysis-install install pipeline nextflow nf-core-rnaseq 3.21 \
    --from /path/to/installed/3.21 --source 'https://nf-co.re/rnaseq/3.21' \
    --accel cpu --set-current

# Install a GPU container from a locally-built SIF, pin by published digest:
analysis-install install container apptainer pytorch 2.9-cuda13 \
    --from /tmp/pytorch-2.9-cuda13.sif --source 'docker://nvcr.io/...@sha256:...' \
    --accel both --set-current        # preferred=gpu by policy

# Reference (regenerable → excluded from backup):
analysis-install install reference genomes GRCh38 ensembl-110 \
    --from /staging/grch38 --regenerable --set-current

# Track / inspect:
analysis-install list
analysis-install show-current container apptainer pytorch

# Reproducibility pin (for a project ENVIRONMENT_MANIFEST.md):
analysis-install pin container apptainer pytorch
#  -> container: apptainer/pytorch/2.9-cuda13  (sha256: ...)   # NEVER pin 'current'

# Verify an artifact against its recorded SHA256:
analysis-install verify container apptainer pytorch 2.9-cuda13
```

## 5. Rollback examples
```bash
# Promote 3.22, then roll the default back to the previous version:
analysis-install install pipeline nextflow nf-core-rnaseq 3.22 --from ... --set-current
analysis-install rollback-current pipeline nextflow nf-core-rnaseq   # current -> 3.21

# Retire a non-current version (current is protected; record kept in VERSIONS.md):
analysis-install remove pipeline nextflow nf-core-rnaseq 3.20
# Removing the *current* version is refused until you set-current elsewhere.
```
A bad install is self-protecting: a `--sha256` mismatch deletes the partial version
dir and hard-stops; an existing version is never overwritten.

## 6. Test cases & validation (M3-1)
`infra/scripts/test-analysis-install.sh` runs the tool against a `mktemp` root with
dummy artifacts and asserts all capabilities, then cleans up. **Result: 23/23
PASS** (validation 2026-06-10). Covered: versioned install; manifest; sha256 record;
central log; current symlink; never-overwrite guard; atomic switch; rollback;
GPU-first default; `.regenerable` marker; verify-OK (file & dir payloads); sha256
hard-stop; verify-FAIL on tamper; pin resolution + 'never pin current' warning;
pipeline/container/reference tracking via `list`; remove guards + logging.
Re-run anytime: `infra/scripts/test-analysis-install.sh` (self-contained, throwaway).

## 7. Limitations / future
- Bash + `flock`/`rename` (single-server NFS semantics); a `current` switch is atomic
  but cross-node visibility is eventually-consistent (projects pin exact versions).
- No GC yet — version retention/reclamation per VERSION_GOVERNANCE §5 +
  ANALYSIS_ARCHITECTURE §7.1 is a future addition.
- `--from` accepts a prepared artifact; actual building/pulling (e.g. `apptainer
  build`) is the caller's step (M3-2 Container Layer).
