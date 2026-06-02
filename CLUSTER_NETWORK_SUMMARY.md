# CLUSTER NETWORK SUMMARY

**Status:** Partial (updated 2026-06-02, 20260601-14). Synthesizes
NETWORK_DISCOVERY.md (`gpu-01`, fully measured) with NETWORK_DISCOVERY_gpu02.md
/ _gpu03.md (**reachability confirmed; per-node inventory pending SSH auth**).
Read-only; nothing changed.

> **Headline:** Inter-node **connectivity is now confirmed** — all three nodes
> are on the **same `222.231.57.0/24`** with **sub-millisecond latency** (same
> L2 segment / local switch). What remains unknown is each peer's **internal
> inventory** (OS/NIC speed/services/firewall), blocked only by **SSH
> authentication**, and the **link bandwidth** of the peers. There is **no
> separate private network** — inter-node traffic rides the **public** subnet.

---

## 1. Per-node comparison

| Field | gpu-01 (measured) | gpu-02 | gpu-03 |
|-------|-------------------|--------|--------|
| IPv4 | `222.231.57.30/24` | `222.231.57.31` | `222.231.57.32` |
| Reachable from gpu-01 | self | **yes** (0% loss) | **yes** (0% loss) |
| RTT (avg) | — | **0.067 ms** | **0.123 ms** |
| TCP/22 | open (self) | **open** | **open** |
| SSH auth (this session) | n/a | **denied** (no key) | **denied** (no key) |
| Hostname / OS | gpu-01 / Rocky 10.1 | UNKNOWN | UNKNOWN |
| NIC / link speed | Intel I350, **1 GbE** | UNKNOWN | UNKNOWN |
| Listeners / firewalld / SELinux | sshd:22 / active / Enforcing | UNKNOWN | UNKNOWN |

## 2. Common topology

- **Confirmed:** all three nodes share **`222.231.57.0/24`**, gateway
  `222.231.57.1`. Sub-millisecond RTT indicates a **single L2 segment / local
  switch** (likely one rack/IDC switch).
- **No dedicated private/management network observed** — the cluster segment
  *is* the public subnet. (On `gpu-01`, three I350 ports remain idle/uncabled;
  whether the peers differ is unknown.)
- **Unknown:** whether the `/24` is dedicated to these three hosts or shared with
  other IDC tenants (affects trust boundary); peer NIC speeds.

## 3. Available cluster networking paths

- **Verified:** direct L3 reachability `gpu-01 ↔ gpu-02 ↔ gpu-03` over the public
  `/24`, low latency, SSH port open.
- **Bandwidth:** `gpu-01` = 1 GbE; peers **assumed similar (unconfirmed)**. If
  all are 1 GbE on a shared switch, that is the ceiling.
- **Private path:** none today; would require cabling the idle NIC ports to a
  private switch / provisioning a VLAN (open decision).

## 4. NFS feasibility

**Technically feasible, with caveats — no longer "no path".**
- Connectivity + low latency are now adequate for NFS control traffic. ✅
- **Bandwidth-bound:** likely ~1 GbE (~110–118 MB/s) until peer NICs are
  confirmed / a faster interconnect exists — large model/dataset reads will be
  slow; local NVMe caching stays attractive (STORAGE_ARCHITECTURE.md).
- **Security-gated:** an export would traverse the **public** subnet, so it is
  acceptable **only** with strict host-firewall rules limiting NFS ports to the
  peer IPs (and confirmation the `/24` isn't shared with untrusted tenants).
  A dedicated private VLAN remains the preferred end state
  (SECURITY_AND_HARDENING_POLICY.md §3, §11).
- **Still needed:** peer NIC-speed confirmation; the shared-vs-dedicated `/24`
  question.

## 5. Slurm feasibility

**Now plausible; still preconditioned.**
- Connectivity/latency are adequate for `slurmctld`↔`slurmd`. ✅
- **Outstanding preconditions:** SSH/access to the peers; consistent name
  resolution (no `/etc/hosts`/DNS for the names today); munge shared key; ideally
  shared storage; and the per-node inventory. None are blockers of principle now,
  but all must be set up (each high-risk → User approval).

## 6. What remains to complete the assessment

1. **SSH access to `gpu-02`/`gpu-03`** (authorize `hha`'s key, or paste the
   read-only inventory output) → fills OS/NIC-speed/services/firewall.
2. **Peer link speeds** (from #1) → confirms the bandwidth ceiling.
3. **Operator/IDC facts:** is the `/24` dedicated to these 3 hosts or shared?
   Is a private switch/VLAN available, and at what speed?
4. **Later, with approval:** `iperf3` for actual inter-node throughput.

Connectivity is established; the remaining gaps are **authentication** and
**bandwidth/topology confirmation**. This document changes nothing.
