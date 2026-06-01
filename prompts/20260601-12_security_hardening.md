# 20260601-12 — Security and Hardening Policy

> **STATUS: CURRENT.** Supersedes `20260601-11_observability.md` (kept).

**Prompt ID:** 20260601-12 (assigned per the prompt-versioning policy,
GOVERNANCE.md §8)
**Date:** 2026-06-01
**Role:** infra_admin
**Type:** Design. **Document only — no hardening, config, firewall, account, or
service change applied.**
**Outcome:** Created SECURITY_AND_HARDENING_POLICY.md — a proportionate,
single-operator security posture spanning host, network, filesystem, secrets,
supply chain, agents, logging, backup, incident response, and future services,
with Mandatory/Recommended/Optional control classification, a highest-risk
register, and unresolved decisions.

---

## Decisions recorded

- Posture: **proportionate, not enterprise** — minimal mandatory controls + cheap
  recommended ratchets + optional/scale controls. No SIEM/PAM-vault/full-CIS.
- Highest-value target = **control node `gpu-01`**; highest-impact asset =
  **secrets dir + GitHub deploy key**.
- Mandatory anchors: SELinux enforcing; SSH key-only + no root login; root =
  break-glass; password-protected sudo; default-deny firewall + no public
  services; secrets `700`/`600` off-repo; integrity-verify downloads/images;
  high-risk = User approval; test restores.
- Future high-risk services (Slurm/Apptainer/Docker/NFS/Prometheus/Grafana/
  MinIO) carry per-service mandatory requirements; all are §2.3 → User approval.

## Unresolved (User-gated) — see §13

Cluster networking / management-plane separation; SSH MFA; commit signing +
branch protection; auditd + retention; secrets-encryption tool (age/sops);
per-domain service accounts; break-glass recovery copy; egress filtering.

## Verbatim prompt of record

> Design the Security and Hardening Policy for the existing AI infrastructure.
> Context: governance/runtime/storage/monitoring/agent/environment already
> ratified; still design phase; no installs/config/firewall/account/service
> changes allowed; design/documentation only. Environment: Rocky Linux 10,
> 3-node GPU cluster (gpu-01 primary control+compute, gpu-02 backup
> control+compute, gpu-03 compute), operator `hha` (sudo), root reserved for
> emergency/bootstrap, GitHub private repo configured, secrets outside repos,
> NFS/Slurm planned not deployed, Docker/Apptainer not installed, monitoring
> defined, human approval for all high-risk changes.
>
> Requirements: produce SECURITY_AND_HARDENING_POLICY.md covering Host Security
> (Rocky baseline, SSH, root, sudo, password, MFA, account lifecycle, service
> minimization); Network Security (firewall, cluster trust boundaries,
> management-plane separation, outbound philosophy, future NFS, future Slurm);
> Filesystem Security (ownership, permissions, shared-storage model, secrets dir
> protections, temp files, artifact integrity); Secrets Management (storage,
> backup, rotation, emergency recovery, API keys, SSH keys, GitHub creds);
> Supply Chain (container provenance, image verification, package policy,
> third-party repos, workflow provenance, reproducibility); Agent Security
> (Supervisor/Worker permissions, least-privilege, execution boundaries,
> cross-domain restrictions, approval gates, auditability); Logging & Auditing
> (scope, retention, change tracking, GitHub traceability, incident
> reconstruction); Backup Security (encryption, restore validation, access
> controls); Incident Response (warning/critical/approval-required, compromise/
> credential-leak/host-compromise workflows); Future Services security
> requirements (Slurm/Apptainer/Docker/NFS/Prometheus/Grafana/MinIO) without
> assuming installed. Classify controls Mandatory/Recommended/Optional. Identify
> highest-risk attack surfaces / operational mistakes / future deployments.
> Ensure consistency with Minimalism First, Continuous Improvement, Human
> Authority, Domain Separation, Research-first resource policy. Avoid
> enterprise-scale overengineering (single operator, 3-node, self-managed,
> reproducibility/maintainability). Produce executive summary, document
> structure, rationale, unresolved decisions. Do not implement/install/modify;
> design and document only.
