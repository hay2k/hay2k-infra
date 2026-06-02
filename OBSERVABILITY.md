# OBSERVABILITY

**Status:** Design (2026-06-01) + **partial implementation (2026-06-02,
20260601-15):** on `gpu-01` — Prometheus 3.11.2, Grafana 10.2.6, node_exporter
1.11.1, DCGM 4.5.3 are deployed, **all bound to `127.0.0.1`** (UIs via SSH
tunnel). `dcgm-exporter` (Prom `:9400`) and **peer exporters** are pending
(IMPLEMENTATION_LOG.md). This document remains the intended full strategy.
**Scope:** How the 3-node cluster, its GPU/AI workloads, and the agent runtime
are observed — metrics, logs, alerts — and what gets deployed when.

---

## 1. Principle

Observe what is actually running. Do not stand up a monitoring stack to watch an
idle cluster (GOVERNANCE.md §0 — add control when there is something to control).
Therefore the strategy is **phased**: a zero-install baseline now, the full
stack when real workloads justify continuous monitoring (§9).

Three pillars: **metrics** (numeric time series), **logs** (events/text),
**alerts** (thresholds → notification). Distributed **tracing** is **not**
needed at this scale and is deferred.

## 2. What to observe (full scope)

| # | Target | Collector / source | Example signals | Typical level |
|---|--------|--------------------|-----------------|---------------|
| 1 | **Node health** | node-exporter `up`, uptime, heartbeat | node reachable, unplanned reboot, scrape failure | critical if down |
| 2 | **GPU utilization** | DCGM-exporter | util %, VRAM used/free, temp, power, ECC, per-process | warning→critical on temp/ECC |
| 3 | **CPU / RAM / disk / network** | node-exporter | load, RAM %, disk %/IO, NIC throughput/errors | warning (RAM>50%, disk>80%), critical (disk>95%) |
| 4 | **NFS / shared-storage health** | node-exporter fs + NFS probe (`mountstats`/blackbox) | mount present, server reachable, latency, stale handles, export capacity | critical if unavailable/stale |
| 5 | **Slurm / job visibility** | slurm-exporter (once Slurm) | queue depth, pending/running, node drain/down, exit codes | warning on backlog, critical on ctld down |
| 6 | **Agent runtime heartbeat** | agent writes heartbeat (timestamp) to shared storage → metric | Orchestrator/Supervisor liveness; missed heartbeat = agent down | critical if a live agent goes silent |
| 7 | **Worker stalled detection** | last-progress timestamp + GPU-util-vs-"running" | running but no log/metric movement for N min, or GPU≈0% on an active job | warning→critical (hung job wastes a GPU) |
| 8 | **GitHub sync status** | git ahead/behind + last-push age (script → metric) | uncommitted changes, unpushed commits, push failing, last-push age | warning (drift), critical (push broken = no off-host backup) |
| 9 | **Backup / restore status** | last-success + last-verified-restore age per tier | backup age vs policy, last backup failed, **restore never tested** | warning (stale), critical (failed / untested) |
| 10 | **Background runtime throttling** | per-cgroup/job resource share vs budget | background `runtime` workloads exceeding budget or starving foreground; preemption events | info (throttled OK), warning (over budget) |
| 11 | **Slack alerting (self)** | Alertmanager delivery status | alert send success/failure (observe the alert channel itself) | critical if alert delivery is broken |
| 12 | **Logs** | journald + job + **agent/task logs** (append-only, shared storage) | errors, exceptions, escalation events | feeds the above |

Tie-ins: RESOURCE_POLICY.md §3–§4 (RAM/disk thresholds, background throttling),
NODE_ARCHITECTURE.md §4 (control-node failover), AGENT_RUNTIME.md §5 (heartbeat,
stalled workers, logging), BACKUP_AND_RECOVERY.md (sync/backup/restore — note
that the GitHub push **is** the off-host backup, so #8 and #9 overlap), and
GOVERNANCE.md §6/§8 (downloads, prompts).

Notes on the harder signals:
- **Worker stalled (#7)** is distinct from "failed": the process is alive but not
  progressing. Detect via stalled log/metric output *and* anomalous GPU usage
  (e.g. a "training" job at ~0% GPU). A stalled job silently wastes a scarce GPU,
  so it is treated as at least a warning, critical if long-lived.
- **GitHub sync (#8)** matters because the remote is currently the *only*
  off-host backup; a broken push means the precious tier is single-copy again.
- **Backup/restore (#9)** tracks freshness *and* the "untested backup is not a
  backup" rule (BACKUP_AND_RECOVERY.md §3) — an unverified restore is a standing
  warning.
- **Background throttling (#10)** observes fairness: background `runtime` work
  must yield to foreground; over-budget consumption is the alert.

## 3. Tool evaluation

| Option | Role | Verdict |
|--------|------|---------|
| **Prometheus** | Pull-based metrics TSDB + alert rules | ✅ Canonical; fits the control-node-scrapes-all-nodes topology |
| **node-exporter** | System metrics per node | ✅ Standard; on all nodes |
| **DCGM-exporter** (NVIDIA) | GPU metrics per node (util/VRAM/temp/power/ECC) | ✅ The standard for GPU telemetry; on all nodes |
| **Grafana** | Dashboards + alerting UI | ✅ Standard visualization; singleton on control node |
| **Alertmanager** | Routing/dedup of alerts → notifications | ✅ Pairs with Prometheus |
| **Loki + Promtail** | Log aggregation in Grafana | 🟢 Optional add-on; otherwise centralize logs as files on NFS |
| **netdata** | Lightweight per-node real-time | 🟡 Nice for quick local view; weak central history; redundant with Prometheus |
| **Zabbix / Nagios** | Traditional monitoring | 🔴 Heavier/older ops model; no GPU-native story; not preferred |
| **VictoriaMetrics** | Prometheus-compatible efficient TSDB | 🟡 Overkill at 3 nodes; revisit only if Prometheus storage strains |
| **SaaS (Datadog / Grafana Cloud)** | Hosted | 🔴 External SaaS (high-risk §2.3), cost + data egress; avoid |
| **Zero-install baseline** | `nvidia-smi`/DCGM CLI, `df`, `free`, journald, agent log files + threshold scripts | ✅ **Phase 0**: works now with pre-approved tools, no daemon |

## 4. Recommended stack

**Prometheus + node-exporter + DCGM-exporter + Grafana + Alertmanager**, with
**Loki** as an optional log-aggregation add-on. Pull-based: the Prometheus
server scrapes exporters on every node. This is the cluster-standard stack and
maps exactly onto the node-role service taxonomy (§5). Avoid Zabbix/Nagios,
VictoriaMetrics, and SaaS for now.

## 5. Topology (NODE_ARCHITECTURE.md §5)

- **Singletons on the control node (`gpu-01`, backup-capable on `gpu-02`):**
  Prometheus server, Grafana, Alertmanager, (optional) Loki. One instance each;
  never per-node.
- **Agents on every node:** node-exporter, DCGM-exporter, (optional) Promtail.
  These run where the GPUs/workloads are.
- **Metrics storage:** Prometheus TSDB on the control node; bounded retention
  (e.g. 15–30 days) sized to disk — disk is the binding constraint, so retention
  is a deliberate budget, not unbounded.

## 6. Alerting

Prometheus alert rules → **Alertmanager** → notification. The notification sink
is **Slack** — a deferred high-risk SaaS integration (GOVERNANCE.md §2.3);
**until it is approved, alerts route locally** (log file / console /
email-if-available). Alert rules are defined regardless; only the sink is
deferred. Alerts should be actionable and few — fire on the §2 signals, not on
noise.

### 6.1 Alert levels

Every alert carries exactly one level. The level sets routing and who acts.

| Level | Meaning | Action / who | Routing (when Slack is live) |
|-------|---------|--------------|------------------------------|
| **info** | Normal lifecycle event; no action | Recorded; daily digest | `#infra-info` / log only |
| **warning** | Attention soon; trending toward a limit | Supervisor/operator reviews; no immediate danger | `#infra-warn` |
| **critical** | Immediate action; service/data at risk | Page operator; Domain Orchestrator may act/fail over | `#infra-critical` (page) |
| **approval-required** | A **User decision** is waiting (a governance gate, not just ops) | Surfaced to the User and tracked until resolved | `#infra-approvals` |

- **approval-required** is the monitoring-side surfacing of a governance gate
  (GOVERNANCE.md §2): e.g. disk pressure that needs a **delete-non-regenerable-
  data** decision, a standing GPU reservation request, a cross-domain migration
  request, or a high-risk install awaiting approval. It is the alert form of a
  Supervisor → User escalation (AGENT_RUNTIME.md §4) — **never auto-resolved**;
  it persists until the User decides.
- **critical** may trigger an automated, *reversible* safe action (e.g. control-
  node failover, refusing new background jobs); irreversible responses are
  themselves **approval-required**.
- Levels integrate with the escalation chain: **warning** is handled within the
  domain (Supervisor); **critical** engages the Domain Orchestrator;
  **approval-required** reaches the User.

### 6.2 Example signal → level mapping

| Signal | info | warning | critical | approval-required |
|--------|:----:|:-------:|:--------:|:-----------------:|
| Disk usage | | >80% | >95% | deletion of non-regenerable data to recover space |
| Node reachability | planned reboot | flapping | node down | — |
| GPU | job done | high temp/util | over-temp/ECC shutdown risk | standing GPU reservation request |
| NFS / shared storage | — | high latency | unavailable / stale handles | — |
| Agent heartbeat / worker | — | worker idle | live agent silent / worker stalled (GPU wasted) | — |
| GitHub sync | in sync | unpushed commits / drift | push broken (no off-host backup) | — |
| Backup / restore | backup ok | backup stale / restore untested | backup failed | — |
| Background runtime | throttled (normal) | over budget / starving foreground | — | raise the background budget |
| Governance | — | — | — | high-risk install / cross-domain migration / project lifecycle |

## 7. Agent / runtime observability

Distinctive to this infrastructure (AGENT_RUNTIME.md §5):

- Agent and task logs are append-only, timestamped, on shared storage — the
  primary observability surface for the agent layer.
- Derived metrics (task success/failure counts, escalation counts, agent
  liveness) can be exposed to Prometheus via a textfile/collector reading those
  logs — no bespoke service required initially.
- Control-node health is a first-class signal because it drives failover
  (`gpu-01` → `gpu-02`).
- **Secrets are never logged or exposed by exporters** (SECRETS_POLICY.md §8).

## 8. Config-as-code, security, retention

- **Config as code:** Prometheus rules (YAML), Grafana dashboards (JSON), and
  Alertmanager routes are **version-controlled** (in the infra repo or the
  owning project) — reproducible, reviewable (a §3.2 infrastructure-standard
  change → Senior Engineer review).
- **Security:** exporter/UI ports listen on the **internal cluster network
  only**, never public; Grafana admin credentials and the Slack webhook are
  secrets (SECRETS_POLICY.md §3), never in the repo.
- **Retention:** bounded metric + log retention as an explicit disk budget
  (RESOURCE_POLICY.md §4).

## 9. Risk classification & phasing

**Risk:** the monitoring stack (Prometheus, Grafana, Alertmanager, exporters,
Loki) consists of **persistent network services** → **high-risk §2.3, explicit
User approval** to deploy. The Phase 0 baseline uses only pre-approved §2.1
tools and needs no approval.

- **Phase 0 — now (no approval):** observability via `nvidia-smi`/DCGM CLI,
  `df`/`free`, journald, and agent log files on shared storage, plus simple
  threshold scripts (run under tmux/cron) that log/print warnings. No daemon.
- **Phase 1 — User-approved:** deploy Prometheus + node-exporter +
  DCGM-exporter + Grafana + Alertmanager on the §5 topology when real workloads
  justify continuous monitoring.
- **Phase 2:** add Loki for log aggregation; wire Alertmanager → Slack (when the
  Slack integration is approved); add per-job GPU attribution once Slurm exists.
- **Phase 3 — scale/HA:** Prometheus/Grafana backup on `gpu-02`, longer-term
  metric storage, matured dashboards-as-code.

**Deferred:** all of the above is design. No exporter, server, dashboard, or
alert is deployed by this document.
