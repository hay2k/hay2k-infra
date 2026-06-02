# INFRASTRUCTURE CHANGELOG

Append-only record of infrastructure changes (GOVERNANCE.md §10). Newest first.
Each entry: date, prompt ID, what changed, why.

---

## 2026-06-02 — Backup strategy ratified: 3-node replication; off-site out of scope

**Decision (operator):** no off-site backup will be implemented. The **3-node
on-cluster replicated backup is the approved backup strategy**; whole-site/IDC
loss is an **accepted risk**.

- **GOVERNANCE.md §11:** backup/off-host decision → **RESOLVED** (on-cluster
  replication approved; off-site out of scope, accepted).
- **BACKUP_AND_RECOVERY.md:** §3 reframed as the approved 3-node strategy; §4
  recovery rewritten for single-node loss (peer restore) vs whole-site loss
  (not recoverable — accepted); §6 "gaps" → "accepted risks & scope".
- **SECRETS_POLICY.md §6:** off-site identity requirement removed; secrets backup
  covers accidental-deletion; total-`gpu-01`-loss → regenerate (secrets are
  regenerable).
- **CLUSTER_READINESS_REVIEW.md:** R1 closed; §8 marked approved/implemented;
  **addendum reassessing priorities** → next recommended task = **security
  hardening**.
- No system changes; documentation reconciliation + decision record only.

---

## 2026-06-02 — Backup gap closed (R1 mitigated)

**Rationale:** Close the top readiness risk (R1: NFS data single-copy on a
non-redundant disk) before onboarding data.

- **Installed:** `rsync` 3.4.1 (all nodes), `age` 1.3.1 (gpu-01, user-space,
  SHA256 recorded). Generated cluster **age identity** (`~/.secrets/age/`).
- **Data backup:** daily `systemd` timer `cluster-backup.timer` →
  `infra/scripts/cluster-backup.sh` mirrors `/srv/nfs/resources` to **gpu-02 +
  gpu-03 independent disks** with a sibling SHA256 manifest. **3 copies.**
- **Secrets backup:** `~/.secrets` + SSH keys **age-encrypted** (identity
  excluded) → peers, rotation 7.
- **Restore tested** (`infra/scripts/cluster-restore.sh`): data restored +
  manifest-verified + no pollution (fixed a manifest-in-mirror bug → sibling);
  secrets decrypted and matched.
- **Docs:** BACKUP_AND_RECOVERY.md §6 + SECRETS_POLICY.md §6 → implemented;
  CLUSTER_STATUS.md + CLUSTER_READINESS_REVIEW.md R1 downgraded. Scripts tracked
  in `infra/scripts/`.
- **Residual (honest):** **not off-SITE** (3 nodes = one IDC) — whole-site loss
  still needs an external target/credentials (open). The **age identity must be
  kept off-site by the operator**. Push model (gpu-01→peers); no RAID.

---

## 2026-06-02 — Cluster readiness review (review only)

**Rationale:** Assess production readiness before dcgm-exporter/Slurm. No installs.

- **Created CLUSTER_READINESS_REVIEW.md** — capabilities, gaps, risks, recommended
  architecture updates, workload/domain readiness, resource-allocation + directory
  + backup strategies, recommended first project, and production-ready / defer /
  never-deploy verdicts.
- **Validated** via live health check + a **multi-node execution smoke test**
  (SSH dispatch → compute → shared NFS, 6 GPUs/3 nodes) — passed.
- **Headline verdicts:** ready for **research** + **surplus** compute **iff
  precious data is backed up first** (top risk R1: NFS on gpu-01's single
  non-redundant disk, no backup); **business = internal/dev only**; **investment
  = not ready**; **never (as-is):** sole-copy data without backup, multi-node
  distributed training over 1 GbE, public-facing prod services, regulated data.
- Doc map/tree updated. No new governance documents; no system changes.

---

## 2026-06-02 — 20260601-15 (cont.3) — All-node sudo → 3-node cluster operational

**Rationale:** Passwordless sudo on all nodes. Verified actual state, then
completed multi-node implementation. Authoritative state: **CLUSTER_STATUS.md**
(created).

- **Verified** (no assumptions): sudo ✅ all 3; gpu-01→peers SSH ✅; gpu-01 fully
  provisioned; peers bare → then provisioned.
- **Replicated to peers:** uv 0.11.18 + CPython 3.12.13 + Snakemake 9.22.0 +
  JDK 21.0.11 + Nextflow 26.04.3 (tar/SSH) + Apptainer 1.5.0 (EPEL). Validated.
- **Monitoring mesh:** node_exporter on all 3, Prometheus scrapes all 3 (`up=1`),
  DCGM 4.5.3 on all 3 (2 GPUs each). `dcgm-exporter` deferred (no el10 pkg).
- **NFS:** mounted+persistent on both peers; **cross-node read/write validated**.
- **Slurm:** investigated — **no el10 package** (EPEL none; OpenHPC EL_10=404;
  SchedMD source-only). Not deployed; recommendation in CLUSTER_STATUS.md §7.
- **Docs:** CLUSTER_STATUS.md created; IMPLEMENTATION_LOG.md updated; SYSTEM_OVERVIEW
  map/tree updated. No new governance documents.
- No destructive action / data loss / config replacement / architectural conflict.

**Result:** functional 3-node research cluster — toolchain + containers +
cluster-wide monitoring (node + GPU telemetry) + shared NFS. Remaining: Slurm
(no el10 pkg) and the dcgm-exporter Prometheus bridge — neither blocks research.

---

## 2026-06-02 — 20260601-15 (cont.2) — gpu-01 privileged install: Phases B, D, F

**Rationale:** Passwordless sudo granted **on `gpu-01`** (peers still NO).
Provisioned the control node. Each component validated; localhost-bound where
applicable; rollback notes in IMPLEMENTATION_LOG.md.

- **Phase B ✅ (gpu-01):** Apptainer 1.5.0 (EPEL); container exec validated;
  `--nv` mechanism present (full GPU test needs a glibc/CUDA image).
- **Phase D ◑ (gpu-01):** node_exporter 1.11.1 (SHA256-verified) + Prometheus
  3.11.2 + Grafana 10.2.6 + DCGM 4.5.3, **all bound `127.0.0.1`** (UIs via SSH
  tunnel; no firewall change, no public exposure). Prometheus targets `up=1`;
  Grafana datasource provisioned; admin pw stored as a **secret**
  (`~/.secrets/infra/grafana_admin.txt`); DCGM telemetry validated.
  **Deferred:** `dcgm-exporter` (`:9400` bridge) — not packaged.
- **Phase F ◑ (gpu-01):** NFS server; export `/srv/nfs/resources` to peer IPs
  only, `root_squash`, firewalld rich-rules per peer IP (**not public**).
  Validated: IP-restriction enforced (localhost denied), normal-user write/read
  over NFS works, root_squash works. **Peer mounts pending** (peer sudo).
- **Phase G ⛔:** Slurm **not packaged for el10** (no OpenHPC-el10; only munge)
  **and** needs peer sudo → not attempted.

**Remaining blockers:** (1) **passwordless sudo is gpu-01 only** → peer
Apptainer/exporters, NFS mounts, and Slurm `slurmd`/munge blocked; (2) **Slurm
el10 packaging**. No destructive action / data loss / config replacement /
architectural conflict. **Docs:** IMPLEMENTATION_LOG.md, OBSERVABILITY.md,
STORAGE_ARCHITECTURE.md statuses updated.

---

## 2026-06-02 — 20260601-15 (cont.) — Peer trust authorized; Phases C & E completed

**Rationale:** Operator authorized `cluster_ed25519` on the peers. Resumed from
the blocked state; completed peer inventory and the user-space workflow stack.

- **Phase E ✅ COMPLETE:** passwordless SSH `gpu-01` → `gpu-02`/`gpu-03` verified;
  `~/.ssh/config` aliases added; **full inventory** done — peers are **identical**
  to `gpu-01` (Rocky 10.1, 48c/188 GiB/1.8 TB, 2× RTX 6000 Ada, 1 GbE I350, SSH-
  only, firewalld active, SELinux enforcing). Full SSH mesh confirmed
  (gpu-02→gpu-03). **Peers also have no passwordless sudo.**
- **Phase C ✅ COMPLETE:** **Nextflow 26.04.3** installed user-space on a
  **verified Temurin JDK 21.0.11** (`sha256 4b2220e2…`); validated (minimal
  workflow `[SUCCESS]`). Snakemake already done.
- **Docs:** NETWORK_DISCOVERY_gpu02/03.md → COMPLETE; CLUSTER_NETWORK_SUMMARY.md
  → complete (1 GbE confirmed on all nodes); IMPLEMENTATION_LOG.md (Phases C/E
  complete, blocker report revised); ENVIRONMENT_POLICY.md status.
- **Still blocked (B, D, F, G):** single root cause — **no passwordless sudo on
  any node** (#5). Nothing destructive; no conflicts.

---

## 2026-06-02 — 20260601-15 — Implementation mode (Phases A–G)

**Rationale:** Transition from design to implementation; reach maximum
operational state without further interaction. Full per-phase record (summary/
validation/issues/rollback) in **IMPLEMENTATION_LOG.md**.

**Installed (user-space, reversible):**
- **uv 0.11.18** → `~/.local/bin` (low-risk §2.1; download **SHA256-verified**,
  `588f3e36…55add`).
- uv-managed **CPython 3.12.13** baseline.
- **Snakemake 9.22.0** via `uv tool` (medium-risk; user-space).
- Dedicated **cluster SSH key** `~/.ssh/cluster_ed25519` (`600`, off-repo).

**Validated:** uv venv + `uv pip install` + `uv lock` (reproducibility path);
Snakemake dry-run + real run (2/2 steps, output produced).

**Blocked (stop condition #5 — credentials unavailable; nothing attempted):**
Apptainer (B), Nextflow (no Java), monitoring stack (D), NFS (F), Slurm (G) —
all need **root** (no passwordless sudo); peer inventory + SSH trust (E) need
**peer SSH auth**. All are high-risk §2.3. No destructive action, data loss,
config replacement, or architectural conflict encountered.

**Docs:** IMPLEMENTATION_LOG.md created; ENVIRONMENT_POLICY.md status updated
(uv/Snakemake installed); SYSTEM_OVERVIEW.md map/tree/prompts; prompt
20260601-15 created (14 kept).

**To proceed:** (1) privileged-install path (passwordless sudo or operator-run
installs); (2) authorize `~/.ssh/cluster_ed25519.pub` on `gpu-02`/`gpu-03`.

---

## 2026-06-02 — Amendment to 20260601-14 — Peers reachable; inventory pending SSH auth

**Rationale:** Operator provided peer addresses (`gpu-02` = 222.231.57.31,
`gpu-03` = 222.231.57.32, user `hha`). Re-ran read-only probes. Connectivity
**confirmed**; per-node inventory still blocked on SSH auth. No changes made.

- **Confirmed (measured from gpu-01):** both peers reachable on the shared
  public `222.231.57.0/24`, 0% packet loss, **sub-ms RTT** (0.067 ms / 0.123 ms
  → same L2 segment), **TCP/22 open**; ed25519 host keys recorded.
- **Blocked:** SSH auth → `Permission denied (publickey,…,password)` (no
  authorized key; password is non-interactive). OS/NIC-speed/services/firewall
  for the peers remain UNKNOWN.
- **Docs updated:** NETWORK_DISCOVERY_gpu02.md / _gpu03.md → **PARTIAL** (IP +
  reachability + latency recorded); CLUSTER_NETWORK_SUMMARY.md → topology
  confirmed (shared public /24, no private net), **NFS feasibility = technically
  feasible but bandwidth-bound + security-gated**, **Slurm = plausible, still
  preconditioned**; GOVERNANCE.md §11 updated.
- **Still needed:** SSH access to peers (or pasted inventory output); peer link
  speeds; whether the `/24` is dedicated or shared with other tenants.

---

## 2026-06-02 — 20260601-14 — Peer network discovery (gpu-02/gpu-03) — BLOCKED

**Rationale:** Extend network discovery to `gpu-02`/`gpu-03`. Read-only; no
installs or changes.

| # | Document | Change |
|---|----------|--------|
| 1 | **NETWORK_DISCOVERY_gpu02.md** / **_gpu03.md** | **Created as BLOCKED records.** Both peers are unreachable/unknown from `gpu-01` (no DNS, no SSH resolution, no inventory, no private network). All fields UNKNOWN — **no data fabricated**; each includes the exact read-only command block to run on the node. |
| 2 | **CLUSTER_NETWORK_SUMMARY.md** | **Created (partial).** Per-node comparison (only `gpu-01` measured); common topology = cannot be established; available paths = none verified; **NFS feasibility = indeterminate/not-advisable**, **Slurm feasibility = blocked**; lists what must be obtained. |
| 3 | GOVERNANCE.md / SYSTEM_OVERVIEW.md | §11 + doc map/tree/prompts note the blocked peer inspection. |
| 4 | prompts/20260601-14_network_discovery_peers.md | **Created** current prompt of record; 13 marked kept. |

**Result:** the multi-node roadmap (NFS/Slurm/cross-node monitoring) is **blocked
on peer inventory + a verified inter-node network**, neither of which exists from
`gpu-01`. **Nothing changed on the system; no values invented.**

---

## 2026-06-01 — 20260601-13 — Network discovery (read-only)

**Rationale:** Verify the actual networking environment before any
networking/NFS/Slurm/monitoring/security implementation plan. Read-only — no
config/firewall/routing/DNS/service change, no install.

| # | Document | Change |
|---|----------|--------|
| 1 | **NETWORK_DISCOVERY.md** | **Created** from live inspection of `gpu-01`: host identity, interfaces (Intel I350 quad-GbE, one 1 GbE link up), IP config (**public** `222.231.57.30/24`), inter-node connectivity (**none verified**), topology, NFS/monitoring/security constraints; observations, assumptions, unknowns, risks, next actions. |
| 2 | GOVERNANCE.md | §11 networking entry → **partially discovered** (gpu-01 only; inter-node unknown). |
| 3 | SYSTEM_OVERVIEW.md | §2 networking caveat added; doc map + tree + prompts updated. |
| 4 | prompts/20260601-13_network_discovery.md | **Created** current prompt of record; 12 marked kept. |

**Headline findings:** `gpu-01` is a **public-IP, single-1 GbE** host with
**SSH the only listener** and **no verified inter-node network**; `gpu-02`/
`gpu-03` are unknown from here. NFS/Slurm/cross-node monitoring plans are
**blocked** pending inter-node discovery. **Nothing changed on the system.**

---

## 2026-06-01 — 20260601-12 — Security & hardening policy

**Rationale:** Give the cluster a proportionate, documented security posture —
the last major cross-cutting design area. Document only — no hardening, config,
firewall, account, or service change applied.

| # | Document | Change |
|---|----------|--------|
| 1 | **SECURITY_AND_HARDENING_POLICY.md** | **Created.** Executive summary; principles; **[M]/[R]/[O]** control classification across Host, Network, Filesystem, Secrets, Supply-chain, Agent, Logging/Audit, Backup, Incident Response; per-service future requirements (Slurm/Apptainer/Docker/NFS/Prometheus/Grafana/MinIO); highest-risk register; unresolved User-gated decisions. |
| 2 | GOVERNANCE.md | §11: security & hardening policy **DESIGNED**; its sub-decisions OPEN/User-gated. |
| 3 | SYSTEM_OVERVIEW.md | Doc map + tree + prompts updated. |
| 4 | prompts/20260601-12_security_hardening.md | **Created** current prompt of record; 11 marked kept. |

**Posture:** proportionate, not enterprise (single operator, 3 nodes). Highest
target = control node `gpu-01`; highest-impact asset = secrets + GitHub deploy
key. **Nothing applied or installed.**

---

## 2026-06-01 — Amendment to 20260601-11 — Full observability scope + alert levels

**Rationale:** Clarification — ensure the observability design covers the full
scope (not just Prometheus/Grafana) and defines alert levels. Amendment to
20260601-11 (same topic); 20260601-11 remains the current prompt of record.
Document only.

| # | Document | Change |
|---|----------|--------|
| 1 | OBSERVABILITY.md | §2 expanded into a 12-row full-scope table: node health, GPU utilization, CPU/RAM/disk/network, **NFS/shared-storage health**, **Slurm/job visibility**, **agent runtime heartbeat**, **worker stalled detection**, **GitHub sync status**, **backup/restore status**, **background runtime throttling**, **Slack-alerting self-check**, logs — each with collector, signals, and typical level; added notes on the harder signals. |
| 2 | OBSERVABILITY.md | New §6.1 **alert levels** (info / warning / critical / **approval-required**) with meaning, action/owner, and Slack routing; approval-required defined as the monitoring-side surfacing of a governance gate (GOVERNANCE.md §2) tied to the escalation chain. New §6.2 signal→level mapping table. |

**Net:** observability now spans the full operational surface; alerts are
classified into four levels, with **approval-required** wired to the User
escalation path. Nothing deployed.

---

## 2026-06-01 — 20260601-11 — Monitoring & observability strategy

**Rationale:** Design how the cluster, GPUs, jobs, and agent runtime are
observed. Document only — no monitoring service, exporter, or install.

| # | Document | Change |
|---|----------|--------|
| 1 | **OBSERVABILITY.md** | **Created.** What to observe (system/GPU/storage/jobs/agent/logs) with thresholds tied to existing policy; tool evaluation (Prometheus stack, DCGM-exporter, Loki, netdata, Zabbix/Nagios, VictoriaMetrics, SaaS, zero-install baseline); recommended stack; topology (singleton-on-control + exporters-on-all-nodes); alerting (Alertmanager → Slack-deferred); agent/runtime observability; config-as-code/security/retention; **phased rollout** (Phase 0 zero-install now → Phase 1+ high-risk approval). |
| 2 | GOVERNANCE.md | §11: **monitoring DESIGNED**; full stack high-risk §2.3, nothing installed. |
| 3 | NODE_ARCHITECTURE.md | §6 monitoring row references OBSERVABILITY.md. |
| 4 | SYSTEM_OVERVIEW.md | Doc map + tree + prompts updated. |
| 5 | prompts/20260601-11_observability.md | **Created** current prompt of record; 10 marked kept. |

**Recommended:** Prometheus + node-exporter + DCGM-exporter + Grafana +
Alertmanager (Loki optional). Phase 0 baseline uses pre-approved §2.1 tools (no
approval); the full stack is high-risk §2.3. **Nothing deployed.**

---

## 2026-06-01 — 20260601-10 — NFS ratified + Agent Runtime design

**Rationale:** Ratify the shared-storage recommendation (NFS) and design how
agents actually run. Document only — no installs, services, runtime, or
projects.

| # | Document | Change |
|---|----------|--------|
| 1 | STORAGE_ARCHITECTURE.md | Status → **NFS ratified** as canonical primary shared FS; §5 retitled "Decision (ratified)"; MinIO deferred, Syncthing measured-optimization, Ceph/Gluster not justified. Deployment deferred. |
| 2 | GOVERNANCE.md | §11 shared-storage entry → **RATIFIED** (NFS canonical; deploy deferred; NFS server/MinIO high-risk §2.3). |
| 3 | RESOURCE_POLICY.md | §7 shared-storage entry → ratified NFS; deployment deferred. |
| 4 | **AGENT_RUNTIME.md** | **Created.** Runtime model evaluation (tmux-centric / Claude-Code-centric / **hybrid recommended**); per-tier execution & lifecycle (Domain Orchestrator, Supervisor, Senior Engineer, Worker) covering lifespan, spawning, retirement, communication, logging, escalation, failure handling; cross-cutting substrate/logging/failure/tooling-risk; migration. |
| 5 | AGENT_ARCHITECTURE.md | §8 now points to AGENT_RUNTIME.md as the runtime design. |
| 6 | SYSTEM_OVERVIEW.md | Doc map + tree + prompts updated (AGENT_RUNTIME added). |
| 7 | prompts/20260601-10_agent_runtime.md | **Created** current prompt of record; 09 marked kept. |

**Recommended runtime:** hybrid — Claude Code (cognition) + tmux→Slurm
(persistence/execution); uses only pre-approved tooling (tmux §2.1; Claude Code
itself), so no new approvals to realize at small scale. **Nothing deployed.**

---

## 2026-06-01 — 20260601-09 — Shared storage evaluation

**Rationale:** Address the top open decision from node-role design — shared
storage. Evaluation only; no storage service installed.

| # | Document | Change |
|---|----------|--------|
| 1 | **STORAGE_ARCHITECTURE.md** | **Created.** Evaluation of NFS / GlusterFS / Ceph / Syncthing / object storage / hybrids across 10 criteria (3-node suitability, simplicity, maintenance, performance, AI suitability, Slurm, Apptainer, shared models, domain separation, backup); summary matrix; per-option verdicts; **recommendation = NFS primary + MinIO later + Syncthing-if-measured; avoid Ceph/Gluster at 3 nodes** (pending User ratification). |
| 2 | GOVERNANCE.md | §11 shared-storage entry → **EVALUATED** (NFS recommended, pending ratification; NFS server/MinIO = high-risk §2.3). |
| 3 | RESOURCE_POLICY.md | §7: shared-storage entry points to the evaluation; added **cluster networking/interconnect** as a decisive dependency. |
| 4 | NODE_ARCHITECTURE.md | §3 critical-enabler note references the evaluation. |
| 5 | SYSTEM_OVERVIEW.md | Doc map + tree + prompts updated. |
| 6 | prompts/20260601-09_storage_evaluation.md | **Created** current prompt of record; 08 marked kept. |

**Recommendation (non-binding):** NFS as the primary shared filesystem. **No
storage service installed; no decision ratified.**

---

## 2026-06-01 — 20260601-08 — Node role design + single-host→cluster correction

**Rationale:** Design node roles for the 3-node cluster and reconcile the
governance docs, which had assumed a single host. Design only — no installs, no
services, no node directories.

| # | Document | Change |
|---|----------|--------|
| 1 | **NODE_ARCHITECTURE.md** | **Created.** Node-role analysis (dedicated controller / symmetric / hybrid) across 8 criteria; multi-agent placement; **recommended hybrid control-plane** (`gpu-01` primary + `gpu-02` backup, symmetric compute); single-/all-/never-pinned service taxonomy; roadmap impact (Slurm/Apptainer/Snakemake/Nextflow/monitoring/agent runtime); migration strategy. |
| 2 | SYSTEM_OVERVIEW.md | **Hardware corrected** single host → **3-node cluster** (6 GPUs, 288 GB VRAM); doc map + tree + prompts updated. |
| 3 | RESOURCE_POLICY.md | Multi-node capacity (per-node vs cluster totals); GPU allocation per node; **disk is per-node, not pooled**; **shared storage** added as the top open decision. |
| 4 | AGENT_ARCHITECTURE.md | §5 node-placement note (orchestrators/supervisors on control, Workers node-agnostic). |
| 5 | BACKUP_AND_RECOVERY.md | Multi-node threat model (per-node disks ×3, control-node loss → failover). |
| 6 | GOVERNANCE.md | §11: node-role **DESIGNED**; **shared storage** and **node realization / networking** added as OPEN. |
| 7 | prompts/20260601-08_node_role_design.md | **Created** current prompt of record; 07 marked kept. |

**Recommended design:** hybrid control-plane with symmetric compute — `gpu-01`
primary control + compute, `gpu-02` backup control + compute, `gpu-03` compute;
all 6 GPUs usable. **Nothing installed; no node directories or services
created.** New top decision surfaced: **shared storage** for node-agnostic work.

---

## 2026-06-01 — Amendment to 20260601-07 — Senior Engineer is a side review role

**Rationale:** Correct the agent model: the Senior Engineer is **not** part of
the primary escalation chain. Workers escalate **directly to Supervisors**.
Senior Engineers provide review, architecture guidance, reproducibility review,
and quality assurance (a side function / quality gate). Recorded as an amendment
to 20260601-07 (same topic, same session); 20260601-07 remains the current
prompt of record.

| # | Document | Change |
|---|----------|--------|
| 1 | AGENT_ARCHITECTURE.md | §1/§2: Senior Engineer redefined as a **side review role, not in the chain**; hierarchy diagram redrawn with SE attached to the side; Worker now "escalates to its Supervisor". §3.1 escalation chain → **Worker → Supervisor → Domain Orchestrator → User**; §3.2 retitled "side review" and clarified SE advises/reviews but does not relay escalations. |
| 2 | GOVERNANCE.md | §3 escalation path → **Worker → Supervisor → Domain Orchestrator → User**; added that the Senior Engineer is a side role; §3a retitled "Senior Engineer — side review". |
| 3 | SYSTEM_OVERVIEW.md | §5 operating model: chain corrected; Senior Engineer described as sitting beside the chain. |
| 4 | INFRA_CHANGELOG.md | This entry. |

**Net:** primary escalation chain is now Worker → Supervisor → Domain
Orchestrator → User; Senior Engineer review (§3a / AGENT_ARCHITECTURE.md §3.2)
is unchanged in its triggers but explicitly out-of-chain.

---

## 2026-06-01 — 20260601-07 — Presentation/Output automation ratified + Senior Engineer tier

**Rationale:** Ratify presentation automation as a supported capability (Node.js
foundational runtime + project-local pptxgenjs), frame it within a broader
Output Automation framework, and extend the agent hierarchy with a **Senior
Engineer** review tier plus a review-before-implementation requirement. No
installs; no templates/pipelines.

| # | Document | Change | Rationale |
|---|----------|--------|-----------|
| 1 | GOVERNANCE.md | §2.1: **Node.js/npm** ratified as low-risk **foundational runtime** (already present); project npm packages are separate/project-local. | Ratify Node.js low-risk. |
| 2 | GOVERNANCE.md | §11: **Presentation automation RESOLVED** (approved capability, implementation deferred). | Ratification. |
| 3 | GOVERNANCE.md | §2 matrix: approvers renamed **Orchestrator → Domain Orchestrator**; added **Senior Engineer review** rows; added the architecture/reproducibility/shared-lib/reusable-workflow/infra-standard review row. | New tier + review gate. |
| 4 | GOVERNANCE.md | §3 escalation chain → **Worker → Senior Engineer → Supervisor → Domain Orchestrator → User**; added **§3a Review requirements**. | New hierarchy. |
| 5 | AGENT_ARCHITECTURE.md | Rewritten to the five-tier canonical hierarchy (User / Domain Orchestrator / Supervisor / Senior Engineer / Worker=Subagent); two flows documented — escalation and the Senior Engineer review gate (§3.2); roles, scope, anti-hallucination updated. | Core change. |
| 6 | ENVIRONMENT_POLICY.md | Added **§8 Output Automation framework** (source-of-truth = source artifacts; outputs regenerable; supported types PPTX/PDF/HTML/PNG/SVG) and **§8.1 Presentation Automation** (Node.js foundational; pptxgenjs medium-risk project-local; `package-lock.json` required/pinned; PPTX = output not source). Updated §7 step 6 to "no agent self-approves high-risk". | Document the capability + framework. |
| 7 | SYSTEM_OVERVIEW.md / PROJECT_LIFECYCLE.md | Propagated terminology: §5 operating model now names all five tiers and the new chain; PROJECT_LIFECYCLE "Orchestrator" → "Domain Orchestrator". | Doc-set consistency. |
| 8 | prompts/20260601-07_presentation_and_agent_tiers.md | **Created** as current prompt of record; 06 marked kept. | Prompt versioning (GOVERNANCE.md §8). |

**Deferred (unchanged):** pptxgenjs not installed; no templates; no automation
pipelines. Node.js v22.22.3 / npm 10.9.8 already present on the host (not
installed here).

---

## 2026-06-01 — 20260601-06 — Risk-tier ratification + Presentation Automation deferral

**Rationale:** Ratify the interpretive install-risk classifications into
GOVERNANCE.md §2's canonical (operator-authored) lists, and refine the
workflow-engine classification: the engine binary is not itself high-risk —
only its shared execution backend is. Also open a documented deferred decision
for presentation automation. No installs.

| # | Document | Change | Rationale |
|---|----------|--------|-----------|
| 1 | GOVERNANCE.md | §2.1: **`uv` added** to the canonical low-risk pre-approved list. | Ratified low-risk. |
| 2 | GOVERNANCE.md | §2.2: **Conda/Mamba** and **workflow engines (Nextflow, Snakemake)** named as medium-risk examples; clarified engine-binary = medium, shared backend = high. | Ratified medium-risk; Nextflow reclassified High→Medium. |
| 3 | GOVERNANCE.md | §2.3: added **shared execution/orchestration backends (Slurm, Kubernetes, Seqera/Nextflow Tower)**; noted engine-vs-backend split. | Keep shared backends high-risk. |
| 4 | GOVERNANCE.md | §11: added **Presentation automation** deferred decision (Node.js + pptxgenjs, reproducible PPTX) — OPEN, document only. | Per instruction. |
| 5 | ENVIRONMENT_POLICY.md | §1 table: uv = pre-approved §2.1; Conda/Mamba = medium (ratified); Nextflow = medium with backend-high caveat; Snakemake note. §7 step 6 rewritten (high-risk = Apptainer/Docker/shared backends; engines + conda = medium; uv = low). | Sync policy to ratified tiers. |
| 6 | prompts/20260601-06_risk_ratification.md | **Created** as current prompt of record; 05 marked kept. | Prompt versioning (GOVERNANCE.md §8). |

**Net effect on Nextflow:** High-risk → **Medium-risk** (Supervisor judgment).
Slurm, Kubernetes, Tower, and shared execution backends remain **High-risk**
(User approval). Nothing installed.

---

## 2026-06-01 — 20260601-05 — Environment management policy

**Rationale:** Resolve the long-open environment-manager decision with a policy
(no installs). Codifies the operating principle "containers first, workflow
engines first, conda fallback, system packages foundational-only" and gives
Claude Code a decision procedure so environment choices are consistent and
reproducible (GOVERNANCE.md §4).

| # | Document | Change | Rationale |
|---|----------|--------|-----------|
| 1 | **ENVIRONMENT_POLICY.md** | **Created.** Operating principle; evaluation of Apptainer/Docker/Conda-Mamba/uv/system-packages/Nextflow/Snakemake; what is global vs project-local vs `resources/`; install-risk classification; SHA256/version logging; the container-vs-conda-vs-system decision procedure. | New governance document for environments. |
| 2 | GOVERNANCE.md | §4.2 now references ENVIRONMENT_POLICY (lockfile + image digest + driver/CUDA); §11 marks **environment manager RESOLVED** and version-control remote RESOLVED. | Bind reproducibility to the policy; close deferred items. |
| 3 | SYSTEM_OVERVIEW.md | Added ENVIRONMENT_POLICY.md to the §6 map and the file tree; prompts-of-record updated to 05. | Keep map/tree complete. |
| 4 | DIRECTORY_STANDARD.md | §4: shared container images (`*.sif`)/caches belong in `resources/`; env *definitions/lockfiles* stay project-local. | Avoid duplicated purpose; place build artifacts correctly. |
| 5 | RESOURCE_POLICY.md | §4: shared images in `resources/` stored once; containers use `apptainer --nv` for GPUs. | Disk/GPU consistency. |
| 6 | prompts/20260601-05_environment_policy.md | **Created** as current prompt of record; 04 marked kept. | Prompt versioning (GOVERNANCE.md §8). |

**Risk classifications recorded (derived from §2 characteristics):** uv =
low-risk §2.1 (pre-approvable; recommend ratifying into the canonical list);
Conda/Mamba = medium-risk (Supervisor); Apptainer & Docker = high-risk §2.3
(listed); Nextflow = high-risk by characteristics (recommend ratifying into
§2.3); Snakemake = ordinary project-local dependency (global install =
medium-risk). **No tool installed** — Apptainer, Docker, Conda/Mamba, Nextflow,
Snakemake remain uninstalled per instruction.

---

## 2026-06-01 — Operation: GitHub remote + first push (off-host backup established)

**Rationale:** Execute the Phase 2 remote step — give the precious-but-small
tier an off-host home, closing the "zero disaster recovery" gap flagged since
bootstrap (BACKUP_AND_RECOVERY.md §1, §6). Operational execution; no separate
prompt archived.

- **Auth:** dedicated ed25519 key `~/.ssh/hay2k-infra_ed25519` (generated
  20260601-04, no passphrase, perms 600, **outside the repo** per
  SECRETS_POLICY.md §3). Registered on GitHub (account-level, user `hay2k`).
- **Host trust:** GitHub host key verified against the published ed25519
  fingerprint `SHA256:+DiY3wvvV6TuJJhbpZisF/zLDA0zPMSvHdkr4UvCOqU` before being
  added to `~/.ssh/known_hosts` (not blindly accepted).
- **SSH config:** `~/.ssh/config` binds `Host github.com` to the dedicated key
  with `IdentitiesOnly yes` (machine-specific; not in any repo).
- **Connectivity:** `ssh -T git@github.com` → "Hi hay2k! You've successfully
  authenticated" ✅.
- **Remote:** `origin = git@github.com:hay2k/hay2k-infra.git` (private repo).
- **Push:** `main` pushed and tracking `origin/main` at commit `a167c13`.
- **Scratch clone test:** clone succeeded; HEAD matched `a167c13`; working tree
  clean and up to date with `origin/main`; 15 tracked files (9 root governance
  docs, 4 prompts, `hooks/pre-commit`, `.gitignore`); prompt archive present
  (01–04). Scratch dir removed.

**Note:** secrets are NOT in this remote and never will be (SECRETS_POLICY.md
§6); only the precious-but-small governance tier is backed up here. Bulk
precious data and the encrypted secrets-backup channel remain open.

---

## 2026-06-01 — 20260601-04 — Secrets management policy (Phase 2)

**Rationale (overall):** Close the secrets-management gap that was open since
bootstrap, before any credential (the imminent GitHub push, later Zotero) lands
on the host. Decisions taken with the operator: file-based + permission-enforced
storage now, encryption required before anything goes off-host; add a tracked,
format-based pre-commit secret-scan hook.

| # | Document | Change | Rationale |
|---|----------|--------|-----------|
| 1 | **SECRETS_POLICY.md** | **Created.** Principles, what counts as a secret, file storage model (`~/.secrets/`, 700/600, env-var access), non-secret manifest pattern, encryption upgrade-trigger (age/sops before off-host), backup rules, rotation/incident response, prevention (hook), and GitHub-auth guidance. | New governance document for credentials. |
| 2 | **hooks/pre-commit** | **Created** (tracked) + installed to `.git/hooks/`. Blocks staged content matching credential *formats* (private-key blocks, AKIA/ASIA, ghp_/github_pat_/gho_, xox…, AIza…, sk-…, JWT, assigned long secret values). Matches shapes not vocabulary, so governance prose is not flagged. Tested: passes policy docs, blocks planted `AKIA…`/`ghp_…`. | Defense-in-depth against accidental secret commits (SECRETS_POLICY §8). |
| 3 | GOVERNANCE.md | Added **§6a Secrets (never committed)** and marked secrets management **RESOLVED** in the §11 deferred list; annotated remote/secrets-backup as still open. | Bind the never-commit rule and point to the policy. |
| 4 | SYSTEM_OVERVIEW.md | Added SECRETS_POLICY.md to the §6 document map. | Keep the map complete. |
| 5 | BACKUP_AND_RECOVERY.md | Added a **Secrets** tier (precious, never to the git remote, encrypted off-host only) and recovery steps to reinstall the hook and restore secrets from the encrypted channel. | Secrets are precious but must not enter git history. |
| 6 | prompts/20260601-04_secrets_policy.md | **Created** as current prompt of record; 20260601-03 marked kept/superseded. | Prompt versioning (GOVERNANCE.md §8). |

**Note:** `.gitignore` already covered secret file categories at bootstrap; no
change was required. No secret values exist on the host; this policy is
preventive.

---

## 2026-06-01 — 20260601-03 — Governance refinement, terminology standardization, git bootstrap

**Rationale (overall):** Refine the corrected model into its final, maintainable
form: restate the core principle, make the installation policy an explicit
three-tier risk model, standardize agent terminology, and perform the git
bootstrap. Objective: a maintainable infrastructure — simplicity over
flexibility, clarity over completeness, current needs over hypothetical ones.

### Governance corrections
| # | Document | Change | Rationale |
|---|----------|--------|-----------|
| 1 | GOVERNANCE.md | §0 restated to the core principle **"Create what is required. Avoid what is not required."** and an expanded avoid-list (unnecessary dirs, duplicate dir purposes, speculative structures, empty organizational trees, placeholder projects). | Adopt the refined operating principle verbatim. |
| 2 | GOVERNANCE.md | §1 now lists the six permitted top-level domains and states **project directories may only be created after project approval — approval applies to the project, not the directory operation** (with `research/project_x`, `business/product_y`, `investment/strategy_z` examples). | Clarify project creation policy. |
| 3 | SYSTEM_OVERVIEW.md / DIRECTORY_STANDARD.md / PROJECT_LIFECYCLE.md | Synchronized the principle wording, avoid-list, and the project-vs-directory rule; PROJECT_LIFECYCLE adds the explicit examples and the no-anticipatory-directory rule. | Keep all docs consistent with §0/§1. |

### Installation policy changes (three-tier risk model)
| # | Document | Change | Rationale |
|---|----------|--------|-----------|
| 4 | GOVERNANCE.md | Replaced the two-tier model with **§2.1 low-risk (pre-approved, with five characteristics: CLI / single-host / no daemon / no listener / easily removable)**, **§2.2 medium-risk (shared tooling, reusable services, multi-user impact → Supervisor judgment + documentation)**, **§2.3 high-risk (Slurm, Docker, Apptainer, Prometheus, Grafana, databases, message queues, Kubernetes, external SaaS → explicit User approval)**. Updated the matrix rows accordingly. | Make install risk explicit and graduated. |
| 5 | RESOURCE_POLICY.md / AGENT_ARCHITECTURE.md / SYSTEM_OVERVIEW.md | Updated references to the new §2.1/§2.2/§2.3 tiers (e.g. Slurm = high-risk §2.3). | Consistency. |

### Directory policy changes
| # | Document | Change | Rationale |
|---|----------|--------|-----------|
| 6 | DIRECTORY_STANDARD.md | Header principle and avoid-list expanded to include duplicate directory purposes, empty organizational trees, and placeholder projects. | Match §0. |

### Terminology standardization
| # | Document | Change | Rationale |
|---|----------|--------|-----------|
| 7 | AGENT_ARCHITECTURE.md | Introduced the standard terms — **Agent** (umbrella), **Orchestrator** (project coordination), **Supervisor** (strategy/governance/quality), **Worker** (execution unit), **Subagent** (= Worker). Rewrote roles, the escalation chain to **Worker → Orchestrator → Supervisor → User**, scope boundaries, and anti-hallucination duties. | Standardize and stop term-mixing. |
| 8 | GOVERNANCE.md / SYSTEM_OVERVIEW.md / PROJECT_LIFECYCLE.md | Propagated the terminology: §3 escalation path, matrix approver names (Orchestrator materializes approved project dirs), the one-paragraph operating model, and lifecycle procedures. | Consistency across the doc set. |

### Prompt management
| # | Item | Change | Rationale |
|---|------|--------|-----------|
| 9 | prompts/20260601-01_bootstrap.md | Remains **ARCHIVED** (superseded). | Historical record. |
| 10 | prompts/20260601-02_bootstrap_revision.md | **Kept** (retained, not deleted) but marked superseded-by-03. | Operator instruction to keep 02; it remains a valid milestone record. |
| 11 | prompts/20260601-03_governance_refinement.md | **Created** as the current prompt of record. | Prompt versioning policy (GOVERNANCE.md §8): this prompt materially changed principles (terminology, install tiers) and must be archived to keep the prompt set consistent with current policy. |

### Git bootstrap
| # | Item | Change |
|---|------|--------|
| 12 | /home/hha/infra | `git` installed (low-risk prerequisite §2.1); repository initialized; repo-local identity `hay2k <emperorhay2k@gmail.com>`; first commit `infra bootstrap: governance synchronization and git initialization`. No remote, no push, no GitHub auth. |

---

## 2026-06-01 — 20260601-02 — Governance correction & document synchronization

**Rationale (overall):** The 20260601-01 bootstrap was intentionally
conservative and several documents implied that *installation*, *directory
creation*, or *infrastructure evolution* were prohibited outright. The intended
operating model only prohibits the *unnecessary* and the *speculative*.
Necessary infrastructure work should proceed without unnecessary approval
overhead. The following changes bring every document in line with that model.

| # | Document | Change | Rationale |
|---|----------|--------|-----------|
| 1 | GOVERNANCE.md | Added **§0 Core principles** stating the four corrected principles (unnecessary installs / unnecessary dirs / speculative structures prohibited; necessary work proceeds without approval overhead). | Establish the corrected model as the lens for the whole document. |
| 2 | GOVERNANCE.md | Reworked the **§2 approval matrix**: removed the blanket "install/remove software → User" row; added rows for pre-approved prerequisites (Worker/Supervisor), non-listed necessary installs (Supervisor), and high-impact services (User); reclassified directory/domain creation as Supervisor-level routine. | A blanket install gate implied installation was prohibited; the corrected model gates only high-impact services. |
| 3 | GOVERNANCE.md | Added **§2.1 pre-approved prerequisites** (`git, tmux, vim, curl, wget, jq, tree, htop`) and **§2.2 high-impact services** (Slurm, Docker, Apptainer, Prometheus, Grafana, databases, message queues, Kubernetes, external SaaS). | Operational clarification from prompt 20260601-02. |
| 4 | SYSTEM_OVERVIEW.md | Rewrote §7 "What was deliberately NOT done" → "Scope of work at bootstrap": reframes "no software installed / no dirs" as *not yet needed* rather than *prohibited*; cites §0 and the prerequisite list. | Removed an implication that installation/creation were prohibited. |
| 5 | SYSTEM_OVERVIEW.md | §4 already updated to `/home/hha/infra` git root (prior turn); §6 document map gains PROJECT_LIFECYCLE.md and INFRA_CHANGELOG.md. | Keep the map complete after new docs were added. |
| 6 | DIRECTORY_STANDARD.md | Rewrote the header **Principle** and §6: a *necessary* directory is created without approval; only *unnecessary*/*speculative*/*outside-standard* structures are prohibited or gated. | Removed "creation needs approval" / "default answer is no" framing. |
| 7 | DIRECTORY_STANDARD.md | Rewrote the "why not pre-create all six" callout: approval lives at the *project* level (PROJECT_LIFECYCLE.md), not on the act of making a directory. | Directory creation per se is not the gated act. |
| 8 | AGENT_ARCHITECTURE.md | §7 implementation note: replaced "must not pull in installed software before the software-install gate" with the prerequisite/high-impact distinction. | Removed implication that any tooling install was blocked. |
| 9 | RESOURCE_POLICY.md | §2: clarified that adding a scheduler before contention is *speculative* (prohibited), and that a full scheduler (Slurm) is a high-impact service requiring approval while the lightweight card-ownership record needs none. | Align with §0 and §2.2 without implying evolution is forbidden. |
| 10 | BACKUP_AND_RECOVERY.md | §6: `git` reclassified from "first User-approved install" to "pre-approved prerequisite (§2.1)". | git is now pre-approved. |
| 11 | **PROJECT_LIFECYCLE.md** | **Created.** Consolidates the *remaining* User-approval gates (project create/retire, data deletion, cross-domain migration) and the lifecycle state machine. | Was a required review target but did not exist; gives the surviving gates a home and clarifies they were intentionally *not* relaxed. |
| 12 | **INFRA_CHANGELOG.md** | **Created** (this file). | GOVERNANCE.md §10 requires infrastructure changes to be documented. |
| 13 | prompts/20260601-01_bootstrap.md | Marked **ARCHIVED / superseded by 20260601-02**. | Prompt versioning policy (GOVERNANCE.md §8). |
| 14 | **prompts/20260601-02_bootstrap_revision.md** | **Created** as the current prompt of record. | Prompt versioning policy. |

**Tooling action performed in this change:** installed `git` (pre-approved
prerequisite, §2.1); initialized the git repository at `/home/hha/infra` with a
repository-local identity; made the first local commit. No remote configured,
no push (pending operator-provided private repo URL).

> NOTE: if you are reading this before the git steps completed, the install
> required an interactive `sudo` the operator runs in-session; the commit
> follows immediately after.
