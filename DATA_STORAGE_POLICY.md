# DATA STORAGE POLICY

**Status:** CANONICAL from 2026-06-06 (promoted M3-0, 20260606-01). Supersedes the
M2-2 draft in `ChatGPT_handoff/`.
**Scope:** Where research data lives and how projects reach it.

---

## 1. Rationale
Sequencing data (esp. Tier-1 Nanopore raw signal) is **large and read-heavy**; code
is **small and shared**. So: **code/assets on shared NFS; large data on fast local
disk.** This protects the modest shared/OS volume and keeps big I/O off 1 GbE NFS.

## 2. Domain / priority context
The cluster is shared, governed by **Research > Business > Investment > Surplus**.
Each domain has a **Primary Node** (non-exclusive): Research→gpu-01, Business→gpu-02,
Investment/Surplus→gpu-03. `analysis/` (code) is **shared NFS** on all nodes (M2-1,
unchanged); `/data` is **per-node local**. Research may burst to any node by priority.

## 3. Grounded storage facts (verified)
| Path | Device | Size | Type | Shared? | Redundant? |
|------|--------|------|------|---------|------------|
| `/home/hha/analysis` (code) | `/dev/sda3` via `/srv/nfs/analysis` | 1.8 TB (shared w/ OS) | ext4+NFS | **Yes (all nodes)** | No |
| `/data` (large data) | gpu-01 `sdb1` · gpu-02 `sda1` · gpu-03 `sdb1` | **10.9 TB each (~33 TB total)** | ext4 **local** | **No — per-node** | No |

## 4. Frozen decisions
- **Code/assets:** `analysis/projects/<ID>/` (shared NFS).
- **Large datasets:** `/data/<ID>/` (per-node local).
- **Access:** `analysis/projects/<ID>/data -> /data/<ID>` — the **symlink lives in
  shared NFS** but **resolves to node-local `/data`** on the executing node.

## 5. Node affinity (managed via Primary Node)
Because `/data` is node-local while research bursts cluster-wide, **node-affinity is
real**:
- A project's `/data/<ID>` lives on its **Primary Node** (PROJECT_REGISTRY) —
  affinity is managed via **Primary Node**; there is **no separate Data-Node field**.
- **Data-heavy work runs on its Primary Node;** compute-bound research bursts move
  freely; **staging** (copy `/data/<ID>` to the executing node) is the future option
  for data-heavy bursts.
- `ENVIRONMENT_MANIFEST.md` records the **Primary Node** the result was produced on
  (reproducibility, GOVERNANCE §4).

## 6. Ownership, permissions, backup (implementation notes — not done here)
- `/data` is `root:root`; `/data/<ID>/` is created **owned `hha`** at project
  creation (a later phase). Not performed in M3-0.
- **Backup:** the 3-node replication covers `/srv/nfs/resources`; extend scope to
  **precious, non-re-derivable** `/data` inputs (exclude regenerables via the
  `.regenerable` marker, VERSION_GOVERNANCE). `/data` has **no redundancy**.

## 7. Future scalability
- Per-node 10.9 TB (~33 TB) is ample near-term. A project exceeding one node's
  10.9 TB forces a split or pooled storage.
- **Future shared-data options** (each a later, explicit decision): NFS-export
  `/data` (1 GbE-limited); a parallel/distributed FS (high-risk §2.3); or
  **data-staging tooling** (preferred — keeps local-speed reads).
- Redundancy/quotas for `/data` remain open (RESOURCE_POLICY §7).
- A top-level `analysis/data -> /data` convenience symlink is **not recommended**
  (it would present a shared path with node-divergent content).
