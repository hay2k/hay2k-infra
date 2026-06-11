# 20260604-04 — Architecture decisions: B3, B4, B5, first container family = pytorch

**Date:** 2026-06-04
**Role:** User (operator `hha`) → architecture decisions
**Outcome:** Resolved the four open items from the M1-revision handoff:
B3 `<name>/current` is the canonical entry point (no bare-name symlink);
B4 the **entire** `analysis/` hierarchy is shared NFS storage (all four subtrees);
B5 `container/docker/` holds canonical image sources only (no Docker daemon;
Apptainer is the runtime); first validated container family is **pytorch**
(`analysis/container/apptainer/pytorch/<version>/`). Updated
ANALYSIS_ARCHITECTURE.md §3/§4.1/§5 and DIRECTORY_STANDARD.md §2. Produced a new
handoff doc with the revised M1 workstream A (pytorch validation) and the M2
implications of full-`analysis/`-on-NFS. No implementation.

---

## Verbatim prompt

> Decisions:
>
> 1. B3 — Use <name>/current as the canonical entry point. Do not implement the
>    bare-name convenience symlink if it conflicts with the directory name.
>
> 2. B4 — analysis/ will be shared via NFS. This applies to: pipeline/, container/,
>    reference/, projects/. Please assume the entire analysis hierarchy is shared
>    storage. Do not implement yet. Document the implications for M2.
>
> 3. B5 — container/docker/ stores canonical image sources only (Dockerfiles, OCI
>    references, digests, metadata). Docker daemon is not planned. Apptainer
>    remains the execution runtime.
>
> 4. First container family — Use pytorch rather than a generic cuda base. The
>    first validated environment should be: analysis/container/apptainer/pytorch/<version>/
>
> Please update the planning documents accordingly. No implementation yet.
> Documentation only. Save a new handoff document.
