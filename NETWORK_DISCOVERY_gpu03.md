# NETWORK DISCOVERY — gpu-03

**Status:** **PARTIAL (2026-06-02).** Address provided by operator; network
reachability **confirmed** from `gpu-01`. Per-node inventory (OS/NIC/listeners/
firewall) is **still pending — SSH authentication is not available** from this
session. No data is invented; unmeasured fields are marked UNKNOWN. Read-only —
nothing changed on `gpu-03`.

---

## Confirmed from `gpu-01` (measured)

| Field | Value |
|-------|-------|
| IPv4 | **`222.231.57.32`** (same subnet `222.231.57.0/24` as gpu-01) |
| Reachability (ICMP) | **UP** — 3/3 replies, 0% loss |
| Latency (RTT) | **avg 0.123 ms** (min 0.049 / max 0.227) → same L2 segment |
| TCP/22 (SSH) | **OPEN** |
| SSH host key | ed25519 present (recorded to `known_hosts` on first contact) |
| SSH auth result | `Permission denied (publickey,…,password)` — no authorized key for this session |

## Pending — requires SSH access (UNKNOWN until then)

hostname · OS/kernel · NIC model/speed/duplex/MTU · interfaces/MAC · full IP
config · routes/gateway · DNS · listening services · firewalld state · SELinux.

## How to complete this record

The host is reachable; only **authentication** is missing. Provide **one** of:
1. Authorize key-based SSH for `hha` from `gpu-01` to `gpu-03` (operator action
   on `gpu-03` — a config change I will not make unprompted), then I run the
   read-only inventory; **or**
2. Run the read-only command block (in NETWORK_DISCOVERY.md / this file's
   sibling) **on `gpu-03`** and provide the output.

```bash
hostname; hostname -f 2>/dev/null
grep -E '^(NAME|VERSION|PRETTY_NAME)=' /etc/os-release; uname -r
ip -br link; ip -br addr; ip route; grep -v '^\s*#' /etc/resolv.conf
for i in $(ls /sys/class/net | grep -v lo); do echo "== $i =="; cat /sys/class/net/$i/mtu; ethtool $i 2>/dev/null | grep -E 'Speed|Duplex|Link detected'; ethtool -i $i 2>/dev/null | grep -E 'driver|bus-info'; done
lspci | grep -iE 'ethernet|network'; ss -tlnH | awk '{print $4}' | sort -u
systemctl is-active firewalld; firewall-cmd --get-default-zone 2>/dev/null; getenforce
```

This file changes nothing on `gpu-03`.
