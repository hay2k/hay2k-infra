# 20260601-09 — Shared Storage Evaluation

> **STATUS: CURRENT.** Supersedes `20260601-08_node_role_design.md` (kept).

**Prompt ID:** 20260601-09 (no explicit ID in the prompt; assigned per the
prompt-versioning policy, GOVERNANCE.md §8)
**Date:** 2026-06-01
**Role:** infra_admin
**Type:** Design / evaluation. **Document only — nothing installed.**
**Outcome:** Created STORAGE_ARCHITECTURE.md evaluating NFS, GlusterFS, Ceph,
Syncthing, object storage, and hybrids across 10 criteria; recommended NFS as
the primary shared FS (recommendation pending User ratification).

---

## Recommendation recorded (pending ratification)

- **NFS** as the primary POSIX shared filesystem (control-node export, fast NIC,
  redundant disks): simplest, Slurm/Apptainer-canonical, enables node-agnostic
  Workers and shared model storage.
- **MinIO object storage** deferred as a second tier (versioned model/dataset/
  artifact registry + backup target).
- **Syncthing / local cache** only if NFS read bandwidth is a measured
  bottleneck for hot models/images.
- **Avoid Ceph / GlusterFS** at 3 nodes (disproportionate maintenance); revisit
  Ceph at larger scale or for mandatory HA storage.
- An NFS *server* and MinIO are **high-risk components (§2.3)** → User approval
  to deploy. **Nothing installed by this evaluation.**

## Verbatim prompt of record

> Evaluate: (1) NFS, (2) GlusterFS, (3) Ceph, (4) Syncthing, (5) Object Storage,
> (6) Hybrid approaches. For each evaluate: 3-node suitability, simplicity,
> maintenance burden, performance, AI workload suitability, Slurm compatibility,
> Apptainer compatibility, shared model storage, research/business/investment
> separation, backup implications.
