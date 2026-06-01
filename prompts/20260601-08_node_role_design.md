# 20260601-08 — Node Role Design

> **STATUS: KEPT — superseded by `20260601-09_storage_evaluation.md`.**
> Current prompt of record is 20260601-09.

**Prompt ID:** 20260601-08
**Date:** 2026-06-01
**Role:** infra_admin
**Type:** Design + governance review. **Document only — no installs, no runtime
services, no projects, no node-specific directories.**
**Outcome:** Created NODE_ARCHITECTURE.md (node-role analysis, recommended
hybrid design, service implications, roadmap, migration); corrected the
single-host assumption to a 3-node cluster across the governance docs.

---

## Decisions recorded

- The infrastructure is a **3-node cluster** (`gpu-01`, `gpu-02`, `gpu-03`;
  Rocky Linux 10; 2 × RTX 6000 Ada each; 6 GPUs / 288 GB VRAM total).
- **Recommended node-role design: Hybrid control-plane with symmetric compute.**
  `gpu-01` = primary control + compute; `gpu-02` = backup control + compute;
  `gpu-03` = compute. All nodes contribute GPUs; control has a warm backup.
- **New top decision: shared storage** (NFS / cluster FS) — the enabler for
  node-agnostic Workers and a cluster-wide `resources/`.
- Constraints honored: Slurm, Apptainer, Docker **not installed**; no projects;
  no node-specific directories.

## Governance amendments applied (continuous improvement)

SYSTEM_OVERVIEW.md (hardware → 3-node cluster), RESOURCE_POLICY.md (multi-node
GPU/disk + shared-storage open decision), AGENT_ARCHITECTURE.md (node
placement), BACKUP_AND_RECOVERY.md (multi-node threat model), GOVERNANCE.md §11
(node-role designed; shared storage / networking open). See INFRA_CHANGELOG.md.

## Verbatim prompt of record

> Prompt ID: 20260601-08 — Node Role Design. The next objective is node role
> design. Hardware: gpu-01/gpu-02/gpu-03, each Rocky Linux 10, RTX 6000 Ada ×2,
> 96GB+ GPU memory, research/AI workloads. Constraints: do not assume project
> names; do not create research/business/investment projects; do not install
> Slurm/Apptainer/Docker; design first.
>
> Tasks: (1) analyze node-role strategies — A dedicated controller (gpu-01
> controller+orchestration, gpu-02/03 compute), B symmetric (all compute,
> controller floats/migrates), C hybrid (mixed orchestration+compute);
> (2) evaluate each on reliability, operational complexity, future Slurm
> integration, future multi-agent orchestration, fault tolerance, maintenance
> burden, scalability, suitability for a 3-node cluster; (3) multi-agent
> implications (Domain Orchestrators, Supervisors, Senior Engineers, Workers;
> tmux orchestration, background workers, future Slack, future monitoring);
> (4) recommend a canonical design (why preferred, limitations, migration path
> if cluster grows); (5) directory/service implications (services only on one
> node, on all nodes, never tied to a node); (6) future roadmap impact (Slurm,
> Apptainer, Snakemake, Nextflow, Monitoring, Agent Runtime); (7) governance
> review — propose amendments where earlier decisions should change; continuous
> improvement applies.
>
> Deliverables: Node Role Analysis, Recommended Architecture, Governance Impact
> Assessment, Migration Strategy. Document only. Do not install anything; do not
> create runtime services; do not create projects; do not create node-specific
> directories yet.
