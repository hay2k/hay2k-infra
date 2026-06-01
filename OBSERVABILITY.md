# OBSERVABILITY

**Status:** Design (2026-06-01, 20260601-11). **Document only — no monitoring
service, exporter, or install exists. This is the intended strategy.**
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

## 2. What to observe

| Layer | Signals | Tie-in |
|-------|---------|--------|
| **System** (per node) | CPU, RAM, load, disk usage/IO, network | RESOURCE_POLICY.md §3–§4 |
| **GPU** (per node, 6 GPUs) | utilization, VRAM used/free, temperature, power, ECC errors, per-process usage | central for an AI cluster |
| **Storage** | per-node disk %, NFS health/latency (once deployed) | disk is the binding constraint (RESOURCE_POLICY.md §4) |
| **Jobs/workloads** | running jobs, runtime, exit status; queue wait + per-job GPU attribution (once Slurm) | NODE_ARCHITECTURE.md |
| **Agent runtime** | agent liveness, task success/failure counts, escalations, control-node health/failover | AGENT_RUNTIME.md §5 |
| **Logs** | journald (system), job logs, **agent/task logs** (append-only on shared storage) | AGENT_RUNTIME.md logging standard |

**Alert-worthy thresholds (tie to existing policy):** disk > 80% (escalation
condition, RESOURCE_POLICY.md §4); RAM > ~50% sustained (coordination,
RESOURCE_POLICY.md §3); GPU over-temp / power / ECC errors; node down; control
node (`gpu-01`) unhealthy → failover signal (NODE_ARCHITECTURE.md §4); elevated
job/agent-task failure rate.

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
is **Slack** — but Slack is a deferred high-risk SaaS integration (GOVERNANCE.md
§2.3); **until it is approved, alerts route locally** (log file / console /
email-if-available). Alert rules are defined regardless; only the sink is
deferred. Alerts should be actionable and few — page on the §2 thresholds, not
on noise.

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
