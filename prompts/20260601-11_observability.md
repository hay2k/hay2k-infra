# 20260601-11 — Monitoring & Observability Strategy

> **STATUS: CURRENT.** Supersedes `20260601-10_agent_runtime.md` (kept).

**Prompt ID:** 20260601-11 (assigned per the prompt-versioning policy,
GOVERNANCE.md §8)
**Date:** 2026-06-01
**Role:** infra_admin
**Type:** Design. **Document only — no monitoring service, exporter, or install.**
**Outcome:** Created OBSERVABILITY.md — metrics/logs/alerts strategy for the
cluster, GPUs, jobs, and agent runtime; recommended the Prometheus stack on the
node-role topology; phased (zero-install baseline now, full stack on approval).

---

## Decisions recorded

- **Recommended stack:** Prometheus + node-exporter + DCGM-exporter + Grafana +
  Alertmanager (Loki optional). Pull-based; singleton server on control node
  (`gpu-01`, backup `gpu-02`); exporters on all nodes.
- **Three pillars:** metrics + logs + alerts; tracing deferred.
- **Agent observability** is first-class (agent/task logs on shared storage →
  derived metrics; control-node health drives failover).
- **Alerting** routes via Alertmanager → Slack (Slack deferred high-risk SaaS);
  local sink until Slack is approved.
- **Risk:** full stack = high-risk §2.3 (User approval). Phase 0 baseline
  (`nvidia-smi`/DCGM CLI, `df`/`free`, journald, agent log files, threshold
  scripts) uses pre-approved §2.1 tools — no approval, no daemon.
- **Nothing installed.**

## Verbatim prompt of record

> Design the monitoring and observability strategy.
