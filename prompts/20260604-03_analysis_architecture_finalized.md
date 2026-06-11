# 20260604-03 — Research architecture finalized (analysis/ pipeline + container + versioning)

**Date:** 2026-06-04
**Role:** User (operator `hha`) → architecture finalization
**Outcome:** Finalized the research-domain architecture: `analysis/` =
`pipeline/ container/ reference/ projects/`; pipeline hierarchy
`{nextflow,snakemake,custom}`; container hierarchy `{apptainer,docker}` organized
by functional environment; version-managed (version-named dirs + `current`
symlink, projects pin exact versions, no silent upgrades; Docker = canonical
source, SIF = derived). Created ANALYSIS_ARCHITECTURE.md; reconciled
DIRECTORY_STANDARD.md §2/§5, ENVIRONMENT_POLICY.md §4, GOVERNANCE.md §1. Produced a
revised M1 proposal + M2 (Research Bootstrap) outline as a handoff doc. No
implementation; no directories/tools/containers created.

---

## Verbatim prompt

> The current M1 proposal is generally acceptable, but several architectural
> decisions have now been finalized and should be incorporated before
> implementation begins.
>
> Please update the planning documents and architecture documentation accordingly.
>
> Finalized decisions:
> 1. Research namespace: /home/hha/analysis/ {pipeline, container, reference, projects}
> 2. Pipeline hierarchy: analysis/pipeline/ {nextflow, snakemake, custom}
> 3. Pipeline version policy: version dirs + current symlink + convenience symlink;
>    new installs default to latest stable; projects record exact versions; never
>    silently upgraded; convenience symlink is the normal entry point.
> 4. Container hierarchy: analysis/container/ {apptainer, docker}
> 5. Container organization: by functional environment, not by pipeline
>    (pytorch, tensorflow, bio-r, nfcore, ...).
> 6. Container version policy: same model as pipelines; Docker image is canonical
>    source; Apptainer SIF is derived; projects record exact versions; never
>    silently upgraded.
> 7. ChatGPT handoff policy: README static; new files only; no index maintenance.
>
> Tasks: A reconcile all planning docs; B identify conflicts; C revised M1
> proposal; D reassess M1 workstreams; E proposed M2 (Research Bootstrap) outline.
>
> Do not implement / create directories / install tools / pull containers.
> Planning and documentation only. Save the assessment as a new ChatGPT handoff
> document and report the saved path.
