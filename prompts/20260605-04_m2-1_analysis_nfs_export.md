# 20260605-04 — M2-1: deploy shared analysis/ NFS export

**Date:** 2026-06-05
**Role:** User (operator `hha`) → implementation authorization (M2-1)
**Outcome:** Deployed `/srv/nfs/analysis` NFS export on gpu-01 → peers; presented at
`/home/hha/analysis` on all nodes (gpu-01 bind, peers nfs4.2, persistent). Created
only the four approved top-level dirs (pipeline/container/reference/projects),
empty. No tools/containers/projects/references. Validated (exportfs, all-node
mounts, cross-node write/read, root_squash). Architecture FROZEN — unchanged.
Recorded in IMPLEMENTATION_LOG (M2-1), CLUSTER_STATUS §4, INFRA_CHANGELOG; handoff
saved.

---

## Verbatim prompt

> Proceed with M2-1 exactly as defined in the frozen M2 implementation plan.
>
> Requirements:
> - Implement the shared analysis NFS export.
> - Create the approved top-level hierarchy only: pipeline/ container/ reference/ projects/
> - Do not install tools.
> - Do not pull containers.
> - Do not create research projects.
> - Do not populate references.
>
> After completion:
> 1. Show final NFS layout.
> 2. Show mount verification from all nodes.
> 3. Report any deviations from plan.
> 4. Confirm architecture remains frozen.
> 5. Save a ChatGPT handoff document.
