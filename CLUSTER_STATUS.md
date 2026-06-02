# CLUSTER STATUS

**Generated:** 2026-06-02 (20260601-15, implementation). Operational status
report (not a governance document). Source of truth for *what is running*; see
IMPLEMENTATION_LOG.md for per-action detail + rollback.

---

## 1. Actual cluster state

**3-node GPU cluster, all nodes operational and homogeneous.** Passwordless sudo
on all nodes; passwordless SSH from control node `gpu-01` to peers; shared NFS
mounted cluster-wide.

| | gpu-01 (control+compute) | gpu-02 (compute) | gpu-03 (compute) |
|---|---|---|---|
| IP | 222.231.57.30 | 222.231.57.31 | 222.231.57.32 |
| OS / kernel | Rocky 10.1 / 6.12 | same | same |
| GPUs | 2× RTX 6000 Ada (driver 610.43.02) | same | same |
| CPU / RAM / disk | 48c / 188 GiB / 1.8 TB | same | same |
| Network | 1 GbE (I350), public `/24`, sub-ms mesh | same | same |
| sudo / SSH-from-gpu-01 | ✅ / self | ✅ / ✅ | ✅ / ✅ |

## 2. Installed components (all nodes unless noted)

| Component | Version | Nodes | Notes |
|-----------|---------|-------|-------|
| uv | 0.11.18 | all | user-space `~/.local`; SHA256-verified |
| CPython (uv-managed) | 3.12.13 | all | baseline |
| Snakemake | 9.22.0 | all | via uv tool |
| Temurin JDK | 21.0.11 | all | user-space; SHA256-verified |
| Nextflow | 26.04.3 | all | needs `JAVA_HOME=~/.local/jdk-21` |
| Apptainer | 1.5.0 | all | EPEL; `--nv` GPU passthrough available |
| node_exporter | 1.11.1 | all | systemd; gpu-01 localhost, peers firewalled to gpu-01 |
| DCGM | 4.5.3 | all | `nvidia-dcgm` active; `dcgmi` telemetry on 2 GPUs/node |
| Prometheus | 3.11.2 | gpu-01 | `127.0.0.1:9090`; scrapes all 3 node_exporters |
| Grafana | 10.2.6 | gpu-01 | `127.0.0.1:3000`; Prometheus datasource; admin pw = secret |
| NFS server | nfs-utils (el10) | gpu-01 | exports `/srv/nfs/resources` |
| Backup | rsync 3.4.1 + age 1.3.1 | gpu-01→peers | daily timer; 3-copy data + encrypted secrets; restore-tested (BACKUP_AND_RECOVERY.md §6) |

Environment policy compliance: downloads SHA256-verified (uv, JDK, node_exporter);
container/Apptainer ready; secrets (Grafana admin) stored in `~/.secrets`, never
in the repo.

## 3. Monitoring status

- **node metrics:** ✅ all 3 nodes scraped by Prometheus (`up=1` ×3 + self).
- **GPU telemetry:** ✅ DCGM core on all nodes (`dcgmi`), hostengine `:5555`.
- **dashboards:** ✅ Grafana with Prometheus datasource (reach via SSH tunnel:
  `ssh -L 3000:127.0.0.1:3000 gpu-01`; admin pw in `~/.secrets/infra/`).
- **DEFERRED — `dcgm-exporter`:** the Prometheus GPU-metrics bridge (`:9400`) is
  not packaged for el10. GPU telemetry exists via DCGM now; to surface it in
  Prometheus/Grafana, run NVIDIA's `dcgm-exporter` container via Apptainer
  (`apptainer run --nv docker://nvcr.io/nvidia/k8s/dcgm-exporter:<tag>`,
  connect to local nv-hostengine, bind `127.0.0.1:9400`) or build from source,
  then uncomment the `dcgm` scrape job. Bounded follow-up.
- All UIs/exporters are **localhost or peer-IP-firewalled — none internet-exposed.**

## 4. NFS status

- **Server:** `gpu-01:/srv/nfs/resources` (the shared `resources/` realization),
  `root_squash`, exported to peer IPs only, firewalld rich-rules per peer IP
  (not in public zone).
- **Clients:** ✅ mounted on `gpu-02` and `gpu-03` at `/srv/nfs/resources`,
  **persistent via `/etc/fstab`** (`_netdev`).
- **Validated:** cross-node — `gpu-02` wrote, `gpu-03` read, server backing store
  confirmed; `root_squash` enforced; localhost (non-peer) mount denied.
- Bandwidth: 1 GbE (~110–118 MB/s) — large model/dataset reads are network-bound
  (local NVMe caching remains the optimization per STORAGE_ARCHITECTURE.md).

## 5. Software versions (summary)

Rocky Linux 10.1 · kernel 6.12.0-124.56.1 · NVIDIA driver 610.43.02 ·
uv 0.11.18 · CPython 3.12.13 · Snakemake 9.22.0 · JDK 21.0.11 · Nextflow 26.04.3 ·
Apptainer 1.5.0 · node_exporter 1.11.1 · Prometheus 3.11.2 · Grafana 10.2.6 ·
DCGM 4.5.3 · munge 0.5.15 (available, not yet used).

## 6. Remaining blockers

| Item | Status | Reason |
|------|--------|--------|
| Slurm | **not deployed** | No supported el10 package: not in EPEL; **OpenHPC has no EL_10** (404, only EL_9); SchedMD source-only. Source build is feasible but not low-risk. |
| dcgm-exporter | deferred | Not packaged for el10; container/source follow-up (recipe in §3). |
| Private network / faster interconnect | open | Single 1 GbE on public `/24`; idle I350 ports uncabled; private VLAN availability unknown. |
| Subnet trust boundary | open input | Is `222.231.57.0/24` dedicated to these 3 hosts or shared? (gates NFS/security hardening — currently mitigated by per-peer firewall + root_squash). |
| Security hardening | designed, not applied | SECURITY_AND_HARDENING_POLICY.md; e.g. firewalld default allows `cockpit` (not listening). |

## 7. Recommended next actions

1. **Slurm:** no low-risk path today. **Interim recommendation:** run distributed
   work via **Nextflow/Snakemake over the SSH mesh + shared NFS** — at 3 nodes
   this needs no scheduler (research-first, minimalism). Deploy Slurm later via a
   deliberate **source build** (gcc/make present; add `rpmbuild` + munge) **when
   queueing/fair-share is actually needed**, or adopt **OpenHPC once EL_10 ships**.
2. **dcgm-exporter:** add the GPU-metrics bridge via Apptainer container (§3) to
   complete Grafana GPU dashboards.
3. **Networking:** obtain the dedicated-vs-shared `/24` answer and private-VLAN
   availability; if a private 10/25 GbE path is possible, it materially improves
   NFS throughput and lets cluster traffic leave the public subnet.
4. **Security hardening phase:** apply SECURITY_AND_HARDENING_POLICY.md mandatory
   controls (review `cockpit` exposure, SSH hardening, etc.).
5. **First real project:** the cluster can now host an approved project
   (PROJECT_LIFECYCLE.md) — env via uv/Apptainer, pipelines via Snakemake/Nextflow,
   shared data on NFS, metrics in Grafana.

**Bottom line:** a functional 3-node research cluster — homogeneous toolchain,
containers, cluster-wide monitoring (node + GPU telemetry), and shared storage —
is operational. Only Slurm (no el10 package) and the GPU-metrics Prometheus
bridge remain, neither blocking research workflows today.
