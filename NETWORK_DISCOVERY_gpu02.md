# NETWORK DISCOVERY — gpu-02

**Status:** **COMPLETE (2026-06-02).** Inventoried via passwordless SSH
(`cluster_ed25519`). Read-only — nothing changed on `gpu-02`.

---

| Field | Value |
|-------|-------|
| Hostname | `gpu-02` |
| OS / kernel | Rocky Linux 10.1 / `6.12.0-124.56.1.el10_1.x86_64` |
| CPU / RAM / disk | 48 cores / 188 GiB / ~1.8 TB (1% used) |
| GPU | 2× RTX 6000 Ada, 49140 MiB each, driver 610.43.02 |
| NIC | Intel I350 quad-GbE (`igb`); `ens100f0` **UP @ 1000 Mb/s**, MTU 1500; f1–f3 DOWN |
| IPv4 | `222.231.57.31/24` (public) |
| Gateway | `222.231.57.1` |
| DNS | `8.8.8.8`, `164.124.101.2` |
| Listening | `sshd` :22 only (`0.0.0.0` + `[::]`) |
| firewalld | active, zone `public` |
| SELinux | Enforcing |
| Passwordless sudo | **NO** (peer installs still require credentials) |
| SSH from gpu-01 | **OK** (passwordless via `cluster_ed25519`; alias `gpu-02`) |

**Identical hardware/OS to `gpu-01`.** DNS list differs (adds `8.8.8.8`). See
CLUSTER_NETWORK_SUMMARY.md.
