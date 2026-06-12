# 20260612-01 — M3-3F: legacy asset cleanup

**Date:** 2026-06-12
**Role:** User (operator `hha`) → cleanup execution authorization
**Outcome:** Removed rollback-only legacy assets after re-confirming no active
consumers: `/home/hha/miniforge3` (2.1 G), `/srv/nfs/analysis` (2.9 G), and the
`/home/hha/ChatGPT_handoff` compatibility symlink. ~4 GB reclaimed on the gpu-01 root
volume. Kept snapshots/backups/historical docs. Updated GOVERNANCE §1/§12 +
DIRECTORY_STANDARD §7 (symlink removed; `/home/hha` clean). Validated all 3 nodes
(namespace, conda→/data/local, analysis→/data/analysis, container --nv, GPU, handoff
write). Storage refactor finalized.

---

## Verbatim prompt (operative content)

> Proceed with M3-3F — Legacy Asset Cleanup. Execution approved. Re-confirm no active
> refs to /home/hha/miniforge3 and /srv/nfs/analysis; canonical handoff /data/admin/handoff
> and runtime /data/local/runtime/miniforge3. Remove /home/hha/miniforge3,
> /srv/nfs/analysis, and the /home/hha/ChatGPT_handoff symlink (verify canonical
> location remains, governance already references /data/admin/handoff, no component
> depends on old path). Do NOT remove *.pre-m3-3d.*, rollback snapshots, backup
> artifacts, historical documentation. Post-cleanup validate: /home/hha namespace,
> conda activation, analysis mount, container access, GPU visibility, handoff writing
> location. Deliverable: 2026-06-12_m3-3F-legacy-cleanup.md.
