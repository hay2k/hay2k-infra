# 20260611-03 — M3-3D: storage architecture refactor EXECUTED

**Date:** 2026-06-11
**Role:** User (operator `hha`) → execution authorization
**Outcome:** Executed the M3-3C plan. Namespace (`/home/hha`) separated from physical
storage (`/data`); `analysis/` backing moved `/srv/nfs/analysis` → `gpu-01:/data/analysis`
(stays cluster-shared, `/home/hha/analysis` unchanged); Miniforge reinstalled to
`/data/local/runtime/miniforge3` + `bio` recreated on all 3 nodes; engine cache →
`/data/local/cache/engine`; handoff → `/data/admin/handoff` (memory + governance
repointed); log → `/data/admin/logs`; backup extended to `/data/analysis`+`/data/admin`
(analysis-backup gap closed). Validated on all nodes. Rollback retained. Infra
committed `c12346e` (pre) + a post-execution commit.

---

## Verbatim prompt (operative content)

> Proceed with M3-3D — Storage Architecture Refactor Execution. Execution approved.
> Preconditions: commit+push infra (report hash); rollback snapshots `*.pre-m3-3d.<ts>`;
> verify no active jobs. Namespace stays `/home/hha/{analysis,business,investment,
> surplus,infra}`; analysis stays cluster-shared; only physical backing changes.
> Tasks: (1) move analysis backing /srv/nfs/analysis → /data/analysis (preserve
> perms/owner/symlinks/structure; verify integrity); (2) re-export from /data/analysis,
> keep /home/hha/analysis unchanged; (3) provision /data/local/runtime; (4) install
> Miniforge → /data/local/runtime/miniforge3, recreate bio from committed
> bio-environment.yml, validate (don't delete old until validated); (5) create
> /data/local/cache/engine + NXF_SINGULARITY_CACHEDIR; (6) move ChatGPT_handoff →
> /data/admin/handoff + update governance refs + handoff memory; (7) move
> cluster-backup.log → /data/admin/logs + update backup scripts; (8) extend backup to
> /data/analysis + /data/admin (exclude regenerables); (9) validate gpu-01/02/03
> (analysis/runtime/container/pipeline/GPU). Post: remove obsolete only if safe; retain
> rollback. Deliverable: 2026-06-11_m3-3D-storage-refactor-executed.md.
