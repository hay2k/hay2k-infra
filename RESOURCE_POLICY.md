# RESOURCE POLICY

**Status:** Active from 2026-06-01 (multi-node, corrected 20260601-08)
**Scope:** How GPU, CPU, RAM, and disk across the **3-node cluster** are shared
across four independent domains.

---

## 1. The capacity reality

A **3-node cluster** (`gpu-01`, `gpu-02`, `gpu-03`; node roles in
NODE_ARCHITECTURE.md):

| Resource | Per node | Cluster total | Notes |
|----------|----------|---------------|-------|
| GPU | 2 × RTX 6000 Ada (48 GB each) | **6 GPUs / 288 GB VRAM** | Indivisible at the card level by default |
| CPU | 48 logical cores | 144 | Soft-shared |
| RAM | 188 GiB | ~564 GiB | Soft-shared |
| Disk | ~1.8 TB single volume, **no redundancy** | ~5.4 TB **not pooled** | Per-node; **no shared storage yet** — an open decision |

This is **a 3-node cluster shared by four domains that are otherwise
independent.** Independence is organizational (GOVERNANCE.md §1); the *physical*
resources are shared and finite. **Disk is per-node and not pooled** — until a
shared-storage decision is made (§7), data/`resources/` are not automatically
visible cluster-wide, which constrains node-agnostic work (NODE_ARCHITECTURE.md
§3, §5).

## 2. GPU allocation

- Default unit of allocation is **a whole GPU**, claimed on a specific node
  (e.g. `gpu-02` GPU 0) via `CUDA_VISIBLE_DEVICES`; a job does not silently
  spread across cards or nodes.
- With 6 GPUs across 3 nodes and 4 domains, GPUs are **not statically owned** by
  a domain. They are claimed per-job and released. Long-lived `runtime`
  workloads needing a permanent GPU are a **User-approved** standing
  reservation, because they reduce capacity for everyone else.
- VRAM oversubscription (multiple jobs on one card) is allowed only when a
  Supervisor has confirmed the combined footprint fits; otherwise one job per
  card.
- There is no scheduler yet. Until one is chosen (deferred decision),
  coordination is by Supervisor agreement and a simple "who holds which card"
  record. **A scheduler is the first thing to add when GPU contention becomes
  real** — adding one before there is contention would be speculative structure
  (prohibited, GOVERNANCE.md §0). Note that a full scheduler (e.g. Slurm) is a
  **high-risk component requiring explicit User approval** (GOVERNANCE.md §2.3);
  the lightweight "who holds which card" record needs none.

## 3. CPU and RAM

- Soft-shared, best-effort. No hard cgroup limits at bootstrap.
- A job that would consume a large fraction of RAM (rule of thumb: > 50% =
  > ~94 GiB) coordinates through its Supervisor first, so it does not OOM
  another domain's work.
- Hard limits (cgroups/quotas) are added only if soft sharing demonstrably
  fails — again, not pre-emptively.

## 4. Disk — the binding constraint

Each node has its own ~1.8 TB volume with **no redundancy**, and the volumes are
**not pooled** (no shared storage yet). `resources/` can therefore only be
"shared" within a node until shared storage exists (§7); cross-node sharing is
currently a sync/copy, which the no-duplication rule discourages. Therefore:

- **Shared large assets go in `resources/`** (model weights, public datasets,
  shared container images per ENVIRONMENT_POLICY.md §4), stored **once** and
  referenced read-only by every domain (DIRECTORY_STANDARD.md §4). Re-downloading
  or duplicating a 100 GB model or image per project is prohibited — it wastes
  the scarcest resource. (Containers access the GPUs via `apptainer --nv`; GPU
  allocation still follows §2.)
- Every domain is expected to live within a **soft disk budget**. No hard
  quotas at bootstrap, but each domain's Supervisor is responsible for its
  footprint and must escalate before a single project exceeds ~200 GB.
- **Regenerable artifacts** (caches, intermediate outputs, re-downloadable
  datasets) are not precious — they are excluded from backups
  (BACKUP_AND_RECOVERY.md §3) and are the first thing reclaimed under pressure.
- Disk usage is monitored; crossing ~80% full is a high-impact condition that
  is escalated to the human.

## 5. Cost / external spend

Any workload that incurs external cost (paid APIs, cloud egress, external GPU)
requires **User approval** (GOVERNANCE.md §2). The local node itself is fixed
cost.

## 6. Fairness and isolation principles

1. **Shared once, owned clearly.** A shared asset has one home (`resources`)
   and read-only consumers.
2. **Claim, use, release.** GPUs and large RAM are claimed for a job and
   released — not hoarded.
3. **Standing reservations are User decisions.** Anything that permanently
   removes capacity from the shared pool (a pinned GPU, a large permanent
   cache) is high-impact.
4. **Add control only when sharing fails.** Schedulers, cgroups, and quotas are
   introduced in response to demonstrated contention, not in anticipation of it.

## 7. Deferred decisions

- **Shared storage** — **RATIFIED: NFS** is the canonical primary shared
  filesystem (STORAGE_ARCHITECTURE.md), the enabler for node-agnostic Workers
  and a cluster-wide `resources/` (NODE_ARCHITECTURE.md §3, §5). Deployment
  deferred to a later implementation phase.
- **Cluster networking / interconnect** (1 GbE vs 10/25 GbE+) — decisive for
  shared-FS bandwidth (STORAGE_ARCHITECTURE.md §6).
- Cluster GPU/job scheduler choice (Slurm; only when contention is real).
- Whether to enforce hard disk quotas per domain.
- Storage redundancy / a second data volume per node (see BACKUP_AND_RECOVERY.md
  — non-redundant per-node disks remain a top infrastructure risk).
