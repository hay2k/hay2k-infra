# CLUSTER READINESS REVIEW

**Date:** 2026-06-02. Review/assessment only — no installation performed.
Grounded in verified state (CLUSTER_STATUS.md) + a live multi-node smoke test
(SSH dispatch → compute → shared NFS, 6 GPUs across 3 nodes, passed).

---

## 1. Current operational capabilities

| Capability | State | Assessment |
|------------|-------|------------|
| **NFS** | ✅ server (gpu-01) + mounts on peers, persistent, cross-node R/W validated | Good for shared models/datasets/results. **Bandwidth-bound (1 GbE)**; on gpu-01's **single non-redundant disk, no backup** (see Risks). |
| **Monitoring** | ◑ node metrics on all 3 in Prometheus; Grafana up; DCGM telemetry on all 3 | System observability ready. **GPU metrics not yet in Prometheus** (dcgm-exporter pending); **no alerting** (Alertmanager/Slack deferred). |
| **Apptainer** | ✅ all nodes, `--nv` | Ready for reproducible, GPU-enabled containers. |
| **Nextflow** | ✅ all nodes (JDK 21) | Local executor ready; **no Slurm executor** (use local/SSH). |
| **Snakemake** | ✅ all nodes | Local execution ready; cluster execution needs a scheduler or generic/SSH config. |
| **Multi-node execution** | ✅ validated (SSH + shared NFS) | Coordinated multi-node runs work **manually / via workflow engines**. **No queue, no fair-share, no preemption** (no scheduler). |

**Net:** a working reproducible-compute cluster for *coordinated* multi-node
work; it is **not** a *scheduled, multi-tenant, queued* cluster yet.

## 2. Remaining technical gaps

- **No GPU scheduler/queue** (Slurm absent — no el10 package). Manual GPU
  coordination only.
- **GPU metrics not in Prometheus/Grafana** (dcgm-exporter not deployed).
- **No alerting** wired (Alertmanager → Slack deferred).
- **No automated data backup** — only the governance repo is off-host (GitHub).
  NFS bulk data + secrets have no backup yet.
- **1 GbE interconnect on a public `/24`; no private network**; NFS throughput
  capped (~110–118 MB/s).
- **No cluster name resolution** (`/etc/hosts`/DNS) — IP-based.
- **Security hardening designed but not applied** (e.g., default `cockpit`
  firewall allowance).
- **Subnet trust boundary unknown** (dedicated vs shared `/24`).

## 3. Risks

| # | Risk | Severity |
|---|------|----------|
| R1 | **NFS data on gpu-01's single non-redundant disk with NO backup** — disk loss = total loss of shared data. | **Critical** |
| R2 | **gpu-01 is a SPOF** — NFS server + Prometheus + Grafana + control all on one node; its loss removes shared storage + monitoring. | High |
| R3 | **No backups** for precious bulk data / secrets (single-copy). | High |
| R4 | **GPU contention** without a scheduler — multi-user collisions, no fairness. | Medium |
| R5 | **1 GbE** — inadequate for multi-node distributed GPU training (gradient sync). | Medium (hard limit for some workloads) |
| R6 | **Public-IP exposure** + unhardened hosts + unknown shared subnet. | Medium |

## 4. Recommended architecture updates

1. **Backups first (gate for any precious data):** implement an off-host backup
   for NFS precious data + an encrypted secrets backup (BACKUP_AND_RECOVERY.md,
   SECRETS_POLICY.md). Add disk redundancy (RAID) on the NFS server if possible.
2. **Reduce gpu-01 SPOF:** plan NFS/monitoring failover to gpu-02 (NODE_ARCHITECTURE
   warm-backup) once backups exist.
3. **Complete monitoring:** dcgm-exporter (GPU metrics) + Alertmanager (at least
   the §2 thresholds: disk, GPU temp, node-down, NFS health).
4. **Name resolution:** a cluster `/etc/hosts` on all nodes (gpu-01/02/03 → IPs).
5. **GPU coordination:** adopt the lightweight "who-holds-which-card" record now
   (RESOURCE_POLICY §2); Slurm later via deliberate source build when queueing is
   needed.
6. **Networking:** pursue a private VLAN / ≥10 GbE if data-heavy or multi-node
   training is anticipated.
7. **Apply security hardening** (SECURITY_AND_HARDENING_POLICY.md mandatory set).

## 5. Workload readiness

| Domain | Ready? | Rationale |
|--------|--------|-----------|
| **Research** | ✅ **Ready** (with caveats) | Toolchain + containers + NFS + system monitoring support reproducible single/multi-node research now. Caveats: coordinate GPUs manually; **only store regenerable/reproducible data on NFS until backups exist.** |
| **Surplus / background runtime** | ✅ **Ready** | Best-effort low-priority compute that yields to foreground; no durability/uptime guarantees needed. Good fit. |
| **Business** | ⚠️ **Defer (production)** | Production business workloads typically need uptime + data durability + security — currently lacking backups, redundancy, hardening. Internal/dev business work is OK. |
| **Investment** | ⛔ **Not ready** | Usually involves sensitive/regulated data + auditability; requires security hardening, data isolation, backups, and access controls not yet applied. Defer until those are in place. |

## 6. Recommended resource allocation strategy

- **Until Slurm:** RESOURCE_POLICY.md model — **whole-GPU allocation**, explicit
  `CUDA_VISIBLE_DEVICES`, **claim → use → release**, a shared "who-holds-which-
  card" record; soft RAM/disk budgets; **background runtime yields to foreground.**
- 6 GPUs across domains, **no static per-domain ownership**; standing
  reservations are User decisions.
- Domain isolation by directory ownership/permissions now; per-domain service
  accounts later (SECURITY_AND_HARDENING_POLICY.md §7) for stronger separation.

## 7. Recommended directory / domain structure

- Keep the approved namespace (DIRECTORY_STANDARD.md): `research/ business/
  investment/ runtime/ resources/ infra/`; create a domain dir only with its
  first **approved** project (PROJECT_LIFECYCLE.md).
- **Place domain/project working trees on shared NFS** so Workers on any node
  see them (node-agnostic). Suggested realization (when first project approved):
  - `infra/` → stays in `/home/hha/infra` (git, off-host backed up). ✅
  - shared assets (models/datasets/images) → `/srv/nfs/resources` (already live).
  - project work → under a shared NFS work tree (e.g. export `/srv/nfs/work` and
    place `<domain>/<project>/` there) — **requires expanding the NFS export**
    (a small, deliberate addition) + backups before precious data lands.
- No speculative empty domain dirs (GOVERNANCE.md §0).

## 8. Recommended backup strategy

Priority order (R1/R3 are the gating risks):
1. **Governance/code:** ✅ already on GitHub (off-host).
2. **Secrets:** encrypt (age/sops) → off-host; currently single-copy — **close
   this** (SECRETS_POLICY.md §5–§6).
3. **NFS precious data:** a scheduled, **off-host** backup (e.g. MinIO/object
   store on separate hardware, another host, or cloud) **before** any
   irreplaceable data is stored. Until then, **store only regenerable/
   reproducible data on NFS.**
4. **Redundancy:** RAID on the NFS disk; **test restores** (BACKUP_AND_RECOVERY.md
   — an untested backup is not a backup).
5. Regenerable assets (re-downloadable models, caches) → not backed up; recorded
   by source + SHA256.

## 9. Recommended first production project

A **research** project that exercises the stack while staying within current
limits:
- **Shape:** a self-contained, reproducible **single-node or lightly-coordinated
  multi-node** GPU workload (e.g. model fine-tuning / inference benchmarking /
  a data-processing pipeline) — **not** multi-node distributed training (1 GbE).
- **Stack:** env via **uv** (or an Apptainer image), pipeline via **Snakemake or
  Nextflow** (local executor), shared models/data on **NFS**, metrics in
  **Grafana**.
- **Data rule:** inputs regenerable or small; **no sole-copy precious data until
  backups exist.**
- Created via PROJECT_LIFECYCLE.md (User-approved); materialized under the
  research domain.

---

## Summary

### Already production-ready
- Reproducible compute: **uv / Python / Apptainer** on all nodes.
- Workflow orchestration: **Snakemake / Nextflow** (local + SSH + shared NFS).
- **Shared storage** (NFS) for regenerable/reproducible data, cluster-wide.
- **System monitoring** (node metrics in Prometheus/Grafana) + GPU telemetry
  (DCGM).
- **Research** and **surplus/background** workloads (within the data-backup
  caveat).

### Should be deferred
- **Slurm** (no el10 package; not needed at this scale — use workflow engines).
- **dcgm-exporter** + **Alertmanager/Slack alerting** (complete monitoring).
- **Business (production)** workloads — until backups + redundancy + hardening.
- **Private VLAN / faster interconnect** (until data-heavy needs justify it).

### Should NEVER be deployed on this architecture (as-is)
- **Sole-copy / irreplaceable data with no backup** — single non-redundant NFS
  disk (R1). Forbidden until backups + redundancy exist.
- **Multi-node distributed GPU training** relying on fast gradient sync — **1 GbE
  is inadequate**; impractical until a ≥10/25 GbE private fabric exists.
- **Public-facing production services** — public-IP hosts with no DMZ/hardening;
  keep services localhost/peer-firewalled (as monitoring/NFS already are).
- **Regulated / sensitive (PII, financial-regulated) investment data** — without
  security hardening, isolation, auditability, and access controls.
- **Untrusted multi-tenant workloads** — no strong tenant isolation today.

**Bottom line:** the cluster is **production-ready for reproducible research and
best-effort/surplus compute today**, provided **precious data is backed up first**
(R1 is the one must-fix before storing anything irreplaceable). Business is
internal/dev-only for now; investment and any durability/compliance/public-facing
or multi-node-training workloads should wait for backups, hardening, and (for
training) a faster interconnect.
