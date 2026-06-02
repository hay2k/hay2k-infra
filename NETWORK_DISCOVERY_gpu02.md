# NETWORK DISCOVERY — gpu-02

**Status:** **BLOCKED — inspection could not be performed (2026-06-02).**
`gpu-02` is **not reachable or known from `gpu-01`**, the only host accessible
to this operator session. No data below is invented; every field is **UNKNOWN**
pending direct access. Read-only — nothing was changed.

---

## Inspection attempt (from `gpu-01`, read-only)

| Method | Result |
|--------|--------|
| Name resolution (`getent hosts gpu-02` / `gpu02`) | **no resolution** (no DNS, no `/etc/hosts`) |
| SSH (`ssh -o BatchMode=yes gpu-02`) | **`Could not resolve hostname gpu-02`** |
| Local inventory / SSH config / credentials for gpu-02 | **none** (only `github.com` in `~/.ssh/config`) |
| Passive neighbor table (`ip neigh`) | only the gateway `222.231.57.1` is known; gpu-02 not present |

`gpu-01` has a single 1 GbE public-IP link and **no private/internal network**
(NETWORK_DISCOVERY.md), so there is no path over which to inspect `gpu-02`.

## Requested fields (to be collected on `gpu-02`)

| Field | Value |
|-------|-------|
| hostname | UNKNOWN |
| OS / kernel | UNKNOWN |
| NIC model/vendor | UNKNOWN |
| link speed / duplex / MTU | UNKNOWN |
| interfaces / MAC | UNKNOWN |
| IPv4 / IPv6 | UNKNOWN |
| routes / gateway | UNKNOWN |
| DNS | UNKNOWN |
| listening services | UNKNOWN |
| firewalld state | UNKNOWN |

## How to complete this record

Provide **one** of: (a) `gpu-02`'s address + SSH access from `gpu-01`, or
(b) the output of the read-only command block below, run **on `gpu-02`**:

```bash
hostname; hostname -f 2>/dev/null
grep -E '^(NAME|VERSION|PRETTY_NAME)=' /etc/os-release; uname -r
ip -br link; ip -br addr; ip route; ip -6 route | head
grep -v '^\s*#' /etc/resolv.conf
for i in $(ls /sys/class/net | grep -v lo); do
  echo "== $i =="; cat /sys/class/net/$i/mtu
  ethtool $i 2>/dev/null | grep -E 'Speed|Duplex|Link detected'
  ethtool -i $i 2>/dev/null | grep -E 'driver|bus-info'
done
lspci | grep -iE 'ethernet|network'
ss -tlnH | awk '{print $4}' | sort -u
systemctl is-active firewalld; firewall-cmd --get-default-zone 2>/dev/null
getenforce
```

This file changes nothing; it records that inspection was attempted and was not
possible from `gpu-01`.
