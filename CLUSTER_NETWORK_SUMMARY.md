# CLUSTER NETWORK SUMMARY

**Status:** **COMPLETE (2026-06-02, 20260601-15).** All three nodes inventoried
(`gpu-01` locally; `gpu-02`/`gpu-03` via passwordless SSH). Read-only; nothing
changed.

> **Headline:** The cluster is **three identical, homogeneous nodes** on one
> **public `222.231.57.0/24`** L2 segment with **sub-ms latency** and a confirmed
> **full passwordless-SSH mesh** (control node `gpu-01` → peers; peers reach each
> other). Constraints: **single 1 GbE per node**, **no private/management
> network**, **no passwordless sudo anywhere**, **no shared storage**.

---

## 1. Per-node comparison

| Field | gpu-01 | gpu-02 | gpu-03 |
|-------|--------|--------|--------|
| IPv4 | `222.231.57.30/24` | `222.231.57.31/24` | `222.231.57.32/24` |
| OS / kernel | Rocky 10.1 / 6.12 | same | same |
| CPU / RAM | 48c / 188 GiB | same | same |
| Disk | ~1.8 TB (1% used) | same | same |
| GPU | 2× RTX 6000 Ada (driver 610.43.02) | same | same |
| NIC live link | I350, **1 GbE**, MTU 1500 | same | same |
| Listening | sshd:22 only | sshd:22 only | sshd:22 only |
| firewalld / SELinux | active / Enforcing | same | same |
| Passwordless sudo | **NO** | **NO** | **NO** |
| SSH from gpu-01 | self | **OK** (key) | **OK** (key) |
| DNS | `164.124.101.2` | `8.8.8.8`, `164.124.101.2` | `164.124.101.2` |

## 2. Common topology (confirmed)

- All three on **`222.231.57.0/24`**, gateway `222.231.57.1`, single L2 segment
  (sub-ms RTT: 0.067 ms / 0.123 ms from gpu-01).
- **Full mesh reachable** (verified gpu-02 → gpu-03).
- **No private/management network**; three idle I350 ports per node (uncabled).
- **No cluster-internal name resolution** — hostnames are local only; not in DNS
  or `/etc/hosts`. gpu-01 reaches peers via `~/.ssh/config` aliases (IP-based).
  (A cluster `/etc/hosts` or DNS will be needed for Slurm/NFS — requires root.)

## 3. Available cluster networking paths

- **Verified:** passwordless SSH mesh over the public `/24`, 1 GbE, low latency.
- **Bandwidth ceiling:** **1 GbE confirmed on all three nodes** (~110–118 MB/s).
- **Private path:** none; would require cabling idle ports to a private switch /
  a VLAN (open decision).

## 4. NFS feasibility

**Feasible; bandwidth-bound and security-gated.**
- Connectivity/latency adequate; **1 GbE confirmed** → large model/dataset reads
  are slow (local NVMe caching stays attractive).
- Would traverse the **public** subnet → acceptable **only** with host-firewall
  rules restricting NFS to peer IPs (needs root) + confirmation the `/24` is not
  shared with untrusted tenants. A private VLAN remains preferred.
- **Deploy blockers:** root (no passwordless sudo on any node); the
  shared-vs-dedicated `/24` question; cluster name resolution.

## 5. Slurm feasibility

**Feasible in principle; preconditioned.**
- Connectivity/latency fine; homogeneous nodes are ideal for Slurm.
- **Preconditions:** root on all nodes (blocked); cluster name resolution
  (`/etc/hosts`/DNS — root); munge shared key (a secret); ideally shared storage
  (NFS, itself blocked on root). All high-risk §2.3 → User approval to deploy.

## 6. Remaining inputs (operator / IDC)

1. **Privileged access** (passwordless sudo or operator-run installs) — the sole
   blocker for NFS/Slurm/monitoring/Apptainer on all nodes.
2. Is `222.231.57.0/24` **dedicated** to these 3 hosts or **shared** with other
   tenants? (Sets the trust boundary / NFS-export safety.)
3. Is a **private switch/VLAN** available (to move cluster traffic off the public
   subnet and beyond 1 GbE)?

Connectivity and inventory are now fully resolved; what remains is **privileged
access** + the **subnet/VLAN** facts.
