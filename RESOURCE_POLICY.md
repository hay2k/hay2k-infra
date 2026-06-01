# RESOURCE POLICY

**Status:** Active from 2026-06-01
**Scope:** How GPU, CPU, RAM, and disk on this single node are shared across
four independent domains.

---

## 1. The capacity reality

| Resource | Total | Notes |
|----------|-------|-------|
| GPU | 2 × RTX 6000 Ada (48 GB VRAM each) | Indivisible at the card level by default |
| CPU | 48 logical cores | Soft-shared |
| RAM | 188 GiB | Soft-shared |
| Disk | 1.8 TB, single volume, **no redundancy** | The binding constraint and the single point of failure |

This is **one host shared by four domains that are otherwise independent.**
Independence is organizational (GOVERNANCE.md §1); the *physical* resources are
shared and finite. This document is how we keep shared hardware from breaking
organizational independence.

## 2. GPU allocation

- Default unit of allocation is **a whole GPU**. A workload claims GPU 0 or
  GPU 1 explicitly (e.g. via `CUDA_VISIBLE_DEVICES`); it does not silently
  spread across both.
- With 2 GPUs and 4 domains, GPUs are **not statically owned** by a domain.
  They are claimed per-job and released. Long-lived `runtime` workloads that
  need a permanent GPU are a **User-approved** standing reservation, because
  they reduce capacity for everyone else.
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

The single 1.8 TB volume holds everything and has **no redundancy**. Therefore:

- **Shared large assets go in `resources/`** (model weights, public datasets),
  stored **once** and referenced read-only by every domain (DIRECTORY_STANDARD.md
  §4). Re-downloading or duplicating a 100 GB model per project is prohibited —
  it wastes the scarcest resource.
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

- GPU/job scheduler choice (only when contention is real).
- Whether to enforce hard disk quotas per domain.
- Storage redundancy / a second data volume (see BACKUP_AND_RECOVERY.md — the
  single non-redundant disk is the top infrastructure risk).
