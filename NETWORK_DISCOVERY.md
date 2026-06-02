# NETWORK DISCOVERY

**Status:** Discovery / point-in-time inspection (2026-06-01, 20260601-13).
**Read-only — no configuration, firewall, routing, DNS, or service was changed.**
**Method caveat:** only **`gpu-01`** (this host) was inspectable. `gpu-02` and
`gpu-03` were **not reachable or known** from here (no `/etc/hosts`, SSH config,
or internal network), so their data is **unknown**, not assumed. No active
scanning of external networks was performed.

---

## 1. Host identity (gpu-01)

| Field | Value |
|-------|-------|
| Hostname | `gpu-01` (no domain; FQDN = `gpu-01`) |
| OS | Rocky Linux 10.1 (Red Quartz) |
| Kernel | `6.12.0-124.56.1.el10_1.x86_64` |
| Uptime | ~3 days |
| SELinux | **Enforcing** |
| (Compute, prior discovery) | 48 logical cores, 188 GiB RAM, ~1.8 TB single volume, 2× RTX 6000 Ada |

## 2. Network interfaces

NIC: **Intel I350 quad-port Gigabit** (one physical card, `igb` driver, PCI
`0000:0d:00.{0-3}`). Only port 0 is connected.

| Interface | Model | Speed | Duplex | MTU | MAC | State |
|-----------|-------|-------|--------|-----|-----|-------|
| `ens100f0` | Intel I350 GbE | **1000 Mb/s** | Full | 1500 | `50:79:73:2a:52:d0` | **UP** |
| `ens100f1` | Intel I350 GbE | — | — | 1500 | `50:79:73:2a:52:d1` | DOWN (no carrier) |
| `ens100f2` | Intel I350 GbE | — | — | 1500 | `50:79:73:2a:52:d2` | DOWN (no carrier) |
| `ens100f3` | Intel I350 GbE | — | — | 1500 | `50:79:73:2a:52:d3` | DOWN (no carrier) |

No bonds, bridges, or VLANs. No jumbo frames (MTU 1500). The cluster's only live
link is **a single 1 GbE port.** Three I350 ports are unused (cabled to nothing).

## 3. IP configuration

| Field | Value |
|-------|-------|
| IPv4 (`ens100f0`) | **`222.231.57.30/24`** — a **public, routable** address (not RFC1918) |
| Default gateway | `222.231.57.1` (via `ens100f0`, static) |
| Local subnet | `222.231.57.0/24` |
| IPv6 | link-local only (`fe80::…`); no global IPv6, no IPv6 default route |
| DNS | `164.124.101.2` (public resolver) |

`gpu-01` is **directly on a public/IDC network** (public IP bound to the host),
not behind NAT.

## 4. Inter-node connectivity (gpu-01 ↔ gpu-02 ↔ gpu-03)

**Undetermined.** From `gpu-01` there is:
- no `/etc/hosts` entry, SSH config, or `known_hosts` for `gpu-02`/`gpu-03`;
- no private/internal interface up (only the single public link);
- therefore **no known path** to the other nodes, and **latency/bandwidth could
  not be measured.** (No active subnet scan was performed.)

The other nodes *may* exist on the same public `/24`, or on a private network
not visible from `gpu-01`, or be otherwise reachable — **this is unknown and
must be obtained directly (§ unknowns).** At the network layer, `gpu-01`
currently behaves as a **standalone host**, not a member of a connected cluster.

## 5. Network topology (observed + assumed)

- **Public IP usage:** confirmed — `gpu-01` has a public IP on its only live NIC.
- **Private IP usage:** none observed on `gpu-01` (no RFC1918 address, no
  internal interface up).
- **Switch topology:** unknown. The three idle I350 ports suggest capacity for a
  private cluster network, but nothing is cabled/up.
- **IDC assumptions (unverified):** the `222.231.x.x` range and `164.124.x.x`
  DNS indicate a Korean ISP/IDC; `gpu-01` appears to be a publicly-addressed
  colocated host.
- **Management plane:** none observed — management and (any) data traffic would
  share the single public link today; no separate management network exists.

## 6. NFS-relevant constraints

- **Available bandwidth:** ~**1 Gb/s** (single link) → practical ceiling
  ~110–118 MB/s.
- **Bottleneck:** the 1 GbE link is the dominant constraint. A 100 GB model over
  1 GbE takes ~15 minutes wall-clock just to transfer.
- **Conclusion: NFS would be strongly network-bound** at current networking.
  Shared model/dataset reads across nodes over 1 GbE would be slow; local NVMe
  caching (Syncthing/local copy per STORAGE_ARCHITECTURE.md §4) becomes more
  attractive, and a faster interconnect (10/25 GbE) would materially change the
  NFS calculus. Also: no inter-node path is even confirmed yet (§4).

## 7. Monitoring-relevant constraints

- **Exporter communication:** the designed model (Prometheus on the control node
  scrapes exporters on all nodes, OBSERVABILITY.md §5) **requires an inter-node
  network that is not currently present/known** (§4).
- **Scrape path:** within `gpu-01` (localhost) scraping is fine; cross-node
  scraping is blocked until inter-node connectivity exists.
- **Grafana access:** would be reachable on the public IP — must be bound
  internal-only / behind auth and **never exposed publicly**
  (SECURITY_AND_HARDENING_POLICY.md §11). With only a public link today, "bind
  to internal interface" has no internal interface to bind to — a gap.

## 8. Security-relevant constraints

- **Externally exposed interface:** `ens100f0` carries a **public IP**, so the
  host is directly internet-facing.
- **Listening services:** only **`sshd` on `0.0.0.0:22`** (all interfaces,
  including the public IP) and `[::]:22`. SSH is therefore **exposed to the
  public internet** — the predicted top attack surface
  (SECURITY_AND_HARDENING_POLICY.md §12).
- **Firewall:** `firewalld` is **active and enabled**, default zone **`public`**
  (detailed rules require root and were not read — so whether 22 is filtered by
  source is unconfirmed).
- **Trusted cluster boundary:** **none exists today** — there is no private
  segment; any future "internal" services would currently sit on a public-
  addressed host.
- **SELinux Enforcing** — good.

## 9. Assumptions (explicitly flagged as such)

- The other ports being down implies no private cluster switch is currently
  cabled (assumption from "no carrier").
- `222.231.x.x` / `164.124.x.x` imply a Korean ISP/IDC colocation (inference
  from address ranges, not confirmed).
- `gpu-02`/`gpu-03` are assumed to exist as designed, but their network identity
  is unverified.

## 10. Unknowns (must be obtained — see §12 next actions)

1. `gpu-02` and `gpu-03`: hostnames, IPs, NIC models/speeds, reachability.
2. Whether a **private/internal network** exists between the nodes (switch?
   cabling on the idle I350 ports? any 10/25 GbE NICs not on this host?).
3. Inter-node **latency and bandwidth** (unmeasurable until a path is known).
4. IDC/provider constraints: per-node public IP allocation, any provider
   firewall, available private VLAN/switch, jumbo-frame support.
5. Whether the firewalld ruleset restricts SSH by source (needs root).

## 11. Risks

- **R1 — Public-facing SSH (high):** `sshd` on a public IP is the primary attack
  surface; depends entirely on key-only auth + firewall source limits (the
  latter unconfirmed). Mitigation lives in SECURITY_AND_HARDENING_POLICY.md but
  is **not yet applied**.
- **R2 — No inter-node network (high, architectural):** the cluster designs
  (control plane, NFS, Slurm, cross-node monitoring) assume connectivity that
  **does not currently exist/verified**. Much of the roadmap is blocked on this.
- **R3 — 1 GbE interconnect (medium):** even once nodes are connected, 1 GbE
  makes NFS and large-model movement slow (network-bound).
- **R4 — No private/management plane (medium):** "internal-only" service binding
  (NFS, Prometheus, Grafana, Slurm) has no internal interface to bind to today.
- **R5 — Single link / no redundancy (low-medium):** the one live NIC port is a
  single point of failure for `gpu-01` networking.

## 12. Recommended next actions (discovery, not implementation)

1. **Inventory `gpu-02` and `gpu-03`** with the same read-only commands (run on
   each host or via whatever access exists) — identity, NICs, IPs, firewall,
   listeners.
2. **Establish the physical topology of record:** is there a switch between the
   nodes? Are the idle I350 ports (or other NICs) cabled? Is a private VLAN
   available from the IDC? Obtain this from the operator/IDC — it cannot be
   derived from `gpu-01` alone.
3. **Once a path exists, measure** inter-node latency and bandwidth (e.g.
   `ping`, `iperf3`) — *with approval, as a later step*.
4. **Confirm the firewalld SSH rule** (root-read) and the IDC's external posture.
5. Only **after** §1–§4 are known should the cluster-networking strategy (and
   the NFS/Slurm/monitoring plans that depend on it) be designed.

**This document changes nothing; it records observed state and what remains
unknown.**
