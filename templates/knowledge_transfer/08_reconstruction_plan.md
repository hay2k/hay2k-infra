# 08 — Recommended Reconstruction Plan — {{PROJECT_ID}}

> Describe the **recommended NEW implementation** on the GPU platform — **not** the legacy one.
> Reuse-First: map every need onto shared platform capabilities (`analysis-install catalog`).

## Target outcome
<what the reconstructed project must produce/answer (from §01)>

## Recommended platform capabilities (Reuse-First — pin exact versions)
| Need | Platform capability (kind/group/name/version) | Reuse / extend / new | Notes |
|---|---|---|---|
| single-cell processing | container/apptainer/scanpy/<ver> | reuse | |
| integration | container/apptainer/scvi-tools/<ver> or scanpy(harmonypy) | reuse | |
| pipeline | pipeline/nextflow/scrnaseq/<ver> | reuse | |
| references | reference/genome + annotation/<ver> | reuse | |

## Execution stages (maps to project-run)
1. Capability Resolution → pin in `ENVIRONMENT_MANIFEST.md`
2. Execution (container-first, references read-only)
3. Validation
4. Figure Generation (PNG+PDF + source-data TSV + metadata MD)
5. Result Packaging → Handoff

## What to seed into canonical files
- **PROJECT_MASTER.md:** objective/scope (§01), method = this plan, key decisions (§02)
- **TODO.md:** open questions (§07) + trial-and-error carry-forwards (§03)
- **ENVIRONMENT_MANIFEST.md:** the pinned capabilities above

## Deliberate differences from the legacy implementation
<where the platform reconstruction intentionally diverges (containerized, pipeline-driven, GPU) and why>

## Risks / validation gates
<what must be checked to trust the reconstruction (GOVERNANCE §4 reproducibility)>
