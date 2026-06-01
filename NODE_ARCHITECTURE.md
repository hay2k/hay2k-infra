# NODE ARCHITECTURE

**Status:** Design (active from 2026-06-01, 20260601-08). **No node-specific
directories, services, or installs exist yet — this is the intended design.**
**Scope:** Role of each node in the 3-node cluster and how that maps to agents,
services, and the future roadmap.

---

## 1. Context

The infrastructure is a **3-node cluster** (a correction to the earlier
single-host assumption — see §7 and SYSTEM_OVERVIEW.md):

| Node | OS | GPU | VRAM |
|------|----|-----|------|
| `gpu-01` | Rocky Linux 10 | 2 × RTX 6000 Ada | 96 GB |
| `gpu-02` | Rocky Linux 10 | 2 × RTX 6000 Ada | 96 GB |
| `gpu-03` | Rocky Linux 10 | 2 × RTX 6000 Ada | 96 GB |
| **Cluster** | | **6 GPUs** | **288 GB** |

Constraints for this exercise: design only; do not assume project names; do not
create projects; do not install Slurm/Apptainer/Docker.

## 2. Node-role strategies analyzed

### A. Dedicated controller
`gpu-01` = controller + orchestration; `gpu-02`, `gpu-03` = compute.

### B. Symmetric
All three are compute; controller responsibilities float/migrate.

### C. Hybrid
Mixed orchestration + compute: a designated **primary** control node that also
computes, a designated **backup** control node, all nodes compute.

### Evaluation

| Criterion | A. Dedicated controller | B. Symmetric (floating) | C. Hybrid (primary+backup) |
|-----------|-------------------------|-------------------------|----------------------------|
| Reliability | Clear, but controller is a hard SPOF | No single SPOF if migration works | Primary + warm backup; no hard SPOF |
| Operational complexity | Low | High (leader election / VIP / discovery) | Low–moderate |
| Future Slurm integration | Natural (ctld on head, slurmd on compute) | Awkward — Slurm still wants a primary | Best — `slurmctld` primary+backup, `slurmd` everywhere |
| Future multi-agent orchestration | Clean (orchestrators on controller) | Needs service discovery | Clean; can fail over to backup |
| Fault tolerance | Poor (no controller HA) | Best in theory | Good (designated failover) |
| Maintenance burden | Low | High (every node control-capable + floating machinery) | Moderate (two nodes carry control config) |
| Scalability | Excellent (add compute nodes) | Good but coordination scales awkwardly | Excellent (add compute; control stays 1–2 nodes) |
| Suitability for 3 nodes | Wastes ⅓ of GPUs if controller is reserved | Maximizes GPUs but machinery is overkill for 3 nodes / 1 admin | **Best** — all 6 GPUs usable + control + backup |

**Key trade-off on 3 nodes:** dedicating a whole node to control (A) sacrifices
2 of 6 GPUs (33% of capacity) and still leaves a SPOF. Full floating control
(B) buys theoretical HA at the cost of leader-election/VIP machinery that is
premature for 3 nodes managed by one operator (GOVERNANCE.md §0). Hybrid (C)
keeps every GPU available for compute while giving a primary + warm backup, and
is exactly the topology Slurm and monitoring will want later — so it is the
natural target, not speculative scaffolding.

## 3. Multi-agent implications

Default placement (logical, not hardware-locked):

| Agent tier | Where it runs | GPU-bound? |
|------------|---------------|------------|
| **Domain Orchestrator** | Primary control node (`gpu-01`); fails over to backup | No |
| **Supervisor** | Primary control node | No |
| **Senior Engineer** (side review) | Any node; ephemeral | No |
| **Worker / Subagent** | Any compute node (incl. control nodes' GPUs) | Usually yes |

- **tmux orchestration:** persistent control/coordination sessions live on the
  primary control node as the operator/agent surface; attachable, survive
  disconnects. Not a per-node concept — one coordination surface.
- **Background workers:** designed **node-agnostic** — runnable on any compute
  node and tracked centrally. Until a scheduler exists, launched/monitored from
  the control node (tmux + ssh); later, submitted as Slurm jobs.
- **Future Slack integration:** a single cluster-wide notification/bot service
  on the control node — never per-node. External SaaS → high-risk (GOVERNANCE.md
  §2.3, User approval).
- **Future monitoring:** a single Prometheus/Grafana **server** on the control
  node (with backup) scraping **node-exporter agents on every node**. High-risk
  §2.3.

**Critical enabler:** node-agnostic Workers require **shared storage** (or a
sync strategy) so any node sees the same workspace, `resources/`, and data.
This is the single most important new decision the cluster introduces (§7).

## 4. Recommended canonical design

**Hybrid control-plane with symmetric compute (Strategy C).**

```
gpu-01  = PRIMARY control plane  + compute   (orchestrators, supervisors,
                                              tmux surface, monitoring server,
                                              future slurmctld primary)
gpu-02  = BACKUP  control plane  + compute   (warm failover for the above,
                                              future slurmctld backup)
gpu-03  = compute                            (workers / jobs only)
all     = compute (6 GPUs usable), node-level agents (exporter, future slurmd,
                   future Apptainer runtime)
```

**Why preferred:**
- Keeps all 6 GPUs available for research/AI work (no node sacrificed).
- No hard SPOF — control has a designated warm backup without B's machinery.
- Maps 1:1 onto the standard small-cluster Slurm topology and the
  monitoring/agent layout, so later phases are incremental, not rewrites.
- Lowest justified complexity for 3 nodes / one operator (GOVERNANCE.md §0).

**Expected limitations:**
- Control colocated with compute means heavy jobs on `gpu-01` can contend with
  control services — mitigate by reserving a little headroom on control nodes,
  or pinning control off the busiest GPU.
- "Warm backup" is not automatic HA until Slurm/orchestration provides failover;
  initially failover is an operator action.
- Requires shared storage to realize node-agnostic Workers (a new decision).

**Migration path if the cluster grows** (see §8): add nodes as pure compute;
promote a second control node only when scale or HA demands it; introduce Slurm
when manual coordination stops scaling.

## 5. Directory and service implications

- **Single-node services (singletons, on the control node, backup-capable):**
  cluster scheduler control daemon (future `slurmctld`), monitoring server
  (Prometheus/Grafana), Slack bot, the primary agent runtime / Domain
  Orchestrator, any shared job queue. One instance, never duplicated per node.
- **All-node services:** node-level agents that must run where the GPUs are —
  future `slurmd`, `node-exporter`, the container runtime (Apptainer) for
  executing jobs, GPU driver/CUDA userspace, base prerequisites, sshd.
- **Never tied to a specific node:** Workers / jobs / agent *tasks* (must be
  schedulable anywhere); the workspace, `resources/`, and project data (must be
  reachable from any node — hence shared storage); domain/project logic (no
  hard-coded hostnames). The governance repo is already off-node (GitHub).

## 6. Future roadmap impact

| Capability | Impact under the recommended design |
|------------|--------------------------------------|
| **Slurm** | `slurmctld` primary on `gpu-01`, backup on `gpu-02`, `slurmd` on all three. High-risk §2.3 → User approval. Design is Slurm-ready; no install now. |
| **Apptainer** | Runtime on **all** nodes; runs containerized jobs with `--nv`; images in shared `resources/`. High-risk §2.3. |
| **Snakemake** | Project-local; runs from control node; uses the Slurm executor once Slurm exists. Medium-risk (§2.2). |
| **Nextflow** | Engine medium-risk; runs from control node with Slurm executor + Apptainer; the shared execution backend remains high-risk (§2.3). |
| **Monitoring** | Server (Prometheus+Grafana) on control node; exporters on all nodes. High-risk §2.3. |
| **Agent Runtime** | Orchestrators/Supervisors on control node, Workers cluster-wide, tasks node-agnostic. Mechanism still deferred (AGENT_ARCHITECTURE.md §8). |

## 7. Governance impact assessment (amendments)

Continuous improvement: the 3-node reality changes single-host assumptions.
Applied/justified amendments:

1. **SYSTEM_OVERVIEW.md — hardware corrected** from single host to a 3-node
   cluster (6 GPUs, 288 GB VRAM). *(Applied 20260601-08.)*
2. **RESOURCE_POLICY.md — multi-node** GPU allocation (6 GPUs across 3 nodes),
   node roles, and a new **shared-storage** open decision. *(Applied.)*
3. **AGENT_ARCHITECTURE.md — node placement** note (control vs compute; tasks
   node-agnostic). *(Applied.)*
4. **BACKUP_AND_RECOVERY.md — multi-node** recovery: each node's OS/config plus
   shared storage; the "one tree" migration becomes "governance repo + shared
   storage + per-node config." *(Noted.)*
5. **New deferred decisions (GOVERNANCE.md §11):** shared storage (NFS / cluster
   FS) — the enabler for node-agnostic Workers; node hostname/role realization;
   cluster networking/interconnect. *(Added; nothing installed.)*

No change to the agent hierarchy, secrets, environment, or output policies is
required by node-role design beyond placement.

## 8. Migration strategy

- **Now (3 nodes, no scheduler):** roles are a *documented design*. Coordination
  is manual (tmux + ssh from `gpu-01`). Realize node roles only when services
  are actually deployed (with approval). Decide shared storage first.
- **Growth to 4–8 nodes:** add each new node as **pure compute**; keep control
  on `gpu-01` (+ backup `gpu-02`). Introduce **Slurm** when manual dispatch
  stops scaling (primary+backup ctld already designed). Monitoring server stays
  singleton; add exporters per new node.
- **Beyond ~8 nodes / HA-critical:** consider promoting control to dedicated
  nodes (shift toward Strategy A for the control plane), Slurm HA, and a real
  shared/parallel filesystem. The hybrid design degrades gracefully into this —
  no rewrite, just promotion of roles already named here.
