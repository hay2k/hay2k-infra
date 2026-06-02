# 20260601-13 — Network Discovery & Verification

> **STATUS: KEPT — superseded by `20260601-14_network_discovery_peers.md`.**
> Current prompt of record is 20260601-14.

**Prompt ID:** 20260601-13 (assigned per the prompt-versioning policy,
GOVERNANCE.md §8)
**Date:** 2026-06-01
**Role:** infra_admin
**Type:** Environment discovery (read-only). **No configuration, firewall,
routing, DNS, or service was changed; no software installed.**
**Outcome:** Created NETWORK_DISCOVERY.md from live read-only inspection of
`gpu-01`.

---

## Key facts recorded

- `gpu-01`: Rocky Linux 10.1, SELinux enforcing, ~3 days uptime.
- NIC: Intel I350 quad-port GbE (`igb`); only `ens100f0` UP at **1 Gb/s**, MTU
  1500; three ports DOWN (no carrier).
- IP: **public** `222.231.57.30/24`, gw `222.231.57.1`, DNS `164.124.101.2`;
  IPv6 link-local only.
- Listening: **only `sshd` on `0.0.0.0:22`** → SSH publicly exposed; firewalld
  active (zone `public`; rules need root to read).
- **No inter-node network; `gpu-02`/`gpu-03` unknown/unreachable** from `gpu-01`
  (no hosts/SSH/known_hosts entries; no private interface).

## Conclusion

Enough information exists to design **cluster networking requirements** and a
**security hardening plan for `gpu-01`**, but **not** to design NFS, Slurm, or
cross-node monitoring deployment plans — those require inter-node connectivity
and `gpu-02`/`gpu-03` inventory that must be obtained first.

## Verbatim prompt of record

> The architecture design phase is largely complete. Before creating any
> additional strategy documents, perform an environment discovery and
> verification phase for the cluster networking layer. Goal: document the actual
> networking environment and constraints before any networking, NFS, Slurm,
> monitoring, or security implementation plans are created.
>
> Inspect and document current state only. Collect: Host Identity (hostname, OS,
> active interfaces); Network Interfaces (names, NIC model/vendor, link speed,
> duplex, MTU, MAC); IP Configuration (IPv4, IPv6, routes, gateways, DNS);
> Inter-node Connectivity (gpu-01/02/03 connectivity, latency, bandwidth
> assumptions, public/private separation); Network Topology (public/private IP
> usage, switch topology, IDC assumptions, management plane); NFS-relevant
> constraints (bandwidth, bottlenecks, network-bound?); Monitoring-relevant
> constraints (exporter comms, scrape path, Grafana access); Security-relevant
> constraints (exposed interfaces, trusted boundaries, future firewall).
> Deliverable: NETWORK_DISCOVERY.md with observations, assumptions, unknowns,
> risks, recommended next actions. Do NOT modify config/install/firewall/
> services/routing/DNS — inspection and documentation only. Afterward provide
> executive summary, key findings, remaining unknowns, and whether enough info
> exists to design cluster networking / NFS / monitoring / Slurm plans; if
> missing, identify what must be obtained.
