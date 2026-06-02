# CLUSTER NETWORK SUMMARY

**Status:** Partial (2026-06-02, 20260601-14). Synthesizes
NETWORK_DISCOVERY.md (`gpu-01`, measured) with NETWORK_DISCOVERY_gpu02.md /
_gpu03.md (**blocked — unreachable**). Read-only; nothing changed.

> **Headline:** Only `gpu-01` could be inspected. `gpu-02` and `gpu-03` are
> unreachable and unknown from `gpu-01`. **No inter-node network path has been
> verified.** At the network layer there is, today, **no cluster — only one
> publicly-addressed host with two unverified peers.** Conclusions about
> multi-node services are therefore *constraints and conditions*, not plans.

---

## 1. Per-node comparison

| Field | gpu-01 (measured) | gpu-02 | gpu-03 |
|-------|-------------------|--------|--------|
| Reachable from gpu-01 | n/a (self) | **No** | **No** |
| Hostname | `gpu-01` | UNKNOWN | UNKNOWN |
| OS | Rocky Linux 10.1 | UNKNOWN | UNKNOWN |
| NIC | Intel I350 quad-GbE (`igb`) | UNKNOWN | UNKNOWN |
| Live link speed | 1 GbE (1 port up, 3 down) | UNKNOWN | UNKNOWN |
| IPv4 | **public** `222.231.57.30/24` | UNKNOWN | UNKNOWN |
| Gateway | `222.231.57.1` | UNKNOWN | UNKNOWN |
| DNS | `164.124.101.2` | UNKNOWN | UNKNOWN |
| Listening | `sshd` :22 only | UNKNOWN | UNKNOWN |
| firewalld | active, zone `public` | UNKNOWN | UNKNOWN |
| SELinux | Enforcing | UNKNOWN | UNKNOWN |

## 2. Common topology

**Cannot be established.** Only one node is observed. There is no `/etc/hosts`,
DNS, SSH config, or neighbor entry linking the nodes, and `gpu-01` has no private
interface up. Whether the three nodes share an L2 segment, a private switch, or
only the public `/24` is **unknown**.

## 3. Available cluster networking paths

- **Verified paths between nodes: none.**
- **On `gpu-01`:** one live 1 GbE public uplink (`ens100f0`); **three idle I350
  ports** (`ens100f1–f3`, no carrier) — *potential* private-network capacity,
  but cabled to nothing.
- **Theoretical (unconfirmed) paths:** (a) over the public `222.231.57.0/24` if
  `gpu-02`/`gpu-03` are addressed in it — untested and **undesirable** (cluster
  traffic over public addressing); (b) a private network via the idle ports +
  a switch — **does not currently exist**.

## 4. NFS feasibility

**Indeterminate — and not advisable on what's currently visible.**
- Requires a verified inter-node path: **none exists**.
- If the only path is `gpu-01`'s 1 GbE, NFS would be **strongly network-bound**
  (~110–118 MB/s; a 100 GB model ≈ 15 min to transfer).
- There is **no private/management network**, so an NFS export today could only
  ride public addressing — a security non-starter (NFS must be internal-only,
  SECURITY_AND_HARDENING_POLICY.md §11).
- **Condition to become feasible:** a private inter-node network (ideally
  ≥10 GbE), confirmed on all three nodes.

## 5. Slurm feasibility

**Indeterminate — effectively blocked.**
- Slurm requires reliable inter-node connectivity, a shared auth key (munge),
  consistent name resolution, and ideally shared storage — **none of these are
  present or verified**.
- It cannot be designed or deployed until §3 (a real inter-node path) and the
  `gpu-02`/`gpu-03` inventory exist.

## 6. What must be obtained to complete this summary

1. **Inventory `gpu-02` and `gpu-03`** (run the read-only block in their
   discovery files, or grant `gpu-01` access to them).
2. **Physical/topology facts from the operator/IDC:** is there a private switch?
   Are the idle I350 ports (or other NICs) cabled? Is a private VLAN available?
   What link speeds?
3. **Once a path exists:** measure inter-node latency/bandwidth (`iperf3`, with
   approval).

Until #1–#2 are answered, cluster-networking strategy, NFS, Slurm, and
cross-node monitoring **cannot be responsibly planned**. This document records
the gap; it changes nothing.
