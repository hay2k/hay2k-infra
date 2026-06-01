# 20260601-10 — Storage Ratification + Agent Runtime Design

> **STATUS: CURRENT.** Supersedes `20260601-09_storage_evaluation.md` (kept).

**Prompt ID:** 20260601-10 (assigned per the prompt-versioning policy,
GOVERNANCE.md §8)
**Date:** 2026-06-01
**Role:** infra_admin
**Type:** Ratification + design. **Document only — no implementation, installs,
services, or projects.**
**Outcome:** Ratified NFS as the canonical shared filesystem; created
AGENT_RUNTIME.md (hybrid Claude-Code + tmux→Slurm runtime; lifecycle for all
four agent tiers).

---

## Decisions recorded

**Shared storage (ratified):**
1. NFS = canonical primary shared filesystem.
2. MinIO/object storage = deferred second-tier design.
3. Syncthing/local caching = optimization only if demonstrated by measurement.
4. Ceph and GlusterFS not justified for the 3-node cluster.
   Deployment deferred; no NFS service installed; no shared-storage dirs.

**Agent runtime (design):** Hybrid — Claude Code for cognition
(orchestration/review/Workers), tmux (→Slurm later) for persistence and
long-running execution. Per-tier lifespan, spawning, retirement, communication,
logging, escalation, and failure handling defined for Domain Orchestrator,
Supervisor, Senior Engineer, and Worker. No runtime deployed.

## Verbatim prompt of record

> Ratify the shared-storage recommendation. Decisions: (1) NFS approved as the
> canonical primary shared filesystem; (2) MinIO/object storage remains a
> deferred second-tier design; (3) Syncthing/local caching remains an
> optimization strategy only if demonstrated by measurements; (4) Ceph and
> GlusterFS are not justified for the current 3-node cluster. Update governance
> documents accordingly. Do not deploy NFS yet. Do not install NFS services yet.
> Do not create shared-storage directories yet. Shared-storage implementation
> will be part of a later implementation phase.
>
> Next objective: Agent Runtime Design. The infrastructure now has governance,
> environment policy, agent hierarchy, node-role design, shared-storage
> strategy. Design how agents actually run. Evaluate: tmux-centric runtime,
> Claude-Code-centric runtime, hybrid runtime. Design execution and lifecycle
> for Domain Orchestrator, Supervisor, Senior Engineer, Worker. Define: lifespan,
> spawning rules, retirement rules, communication, logging, escalation, failure
> handling. Document only. No implementation. No installs. No services. No
> projects.
