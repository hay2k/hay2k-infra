# STORAGE ARCHITECTURE

**Status:** Ratified design (2026-06-01) + **partial implementation (2026-06-02,
20260601-15):** the **NFS server** is deployed on `gpu-01`, exporting
`/srv/nfs/resources` to the peer IPs only (`root_squash`, peer-IP firewall),
validated server-side. **Peer client mounts pending** (peer sudo). NFS remains
the canonical primary shared filesystem; MinIO/Syncthing tiers still deferred.
**Scope:** Shared-storage strategy for the 3-node cluster — the enabler for
node-agnostic Workers and a cluster-wide `resources/` (NODE_ARCHITECTURE.md §3,
RESOURCE_POLICY.md §7).

---

## 1. Why this matters

Each node has its own ~1.8 TB volume, **not pooled**. Without shared storage,
"Workers never tied to a node" and a single-source-of-truth `resources/`
(shared model weights, SIF images) cannot be realized, and Slurm cannot run
(it needs identical shared paths across nodes). This is the gating decision for
most of the roadmap.

**Key dependency:** the right choice partly depends on the **network
interconnect** (1 GbE vs 10/25 GbE+), which is itself an open decision
(GOVERNANCE.md §11). Model-loading bandwidth over a shared FS is network-bound.

## 2. Summary matrix

Ratings: ✅ strong · 🟢 good · 🟡 fair · 🔴 weak · ➖ n/a. (Object Storage and
Syncthing are **not POSIX shared filesystems**, which is why several rows read
🔴/➖ — they are complementary tiers, not drop-in shared FS.)

| Criterion | NFS | GlusterFS | Ceph | Syncthing | Object (MinIO/S3) |
|-----------|-----|-----------|------|-----------|-------------------|
| 3-node suitability | ✅ | 🟢 | 🟡 (3 = bare min) | 🟡 (sync, not FS) | 🟢 |
| Simplicity | ✅ | 🟡 | 🔴 | ✅ | 🟡 |
| Maintenance burden | ✅ low | 🟡 | 🔴 high | 🟢 | 🟡 |
| Performance | 🟢 (NIC-bound, no parallelism) | 🟡 (small-file weak) | 🟢 at scale, 🔴 on 3 hyperconverged | ✅ local reads / 🔴 eventual consistency | 🟢 throughput / 🔴 no POSIX |
| AI workload suitability | 🟢 read-heavy/model serving | 🟡 | 🟢 at scale | 🟡 static replication only | 🟢 dataset/artifact registry |
| Slurm compatibility | ✅ canonical | 🟢 | 🟢 (CephFS) | 🔴 (eventual consistency) | 🔴 (not a shared FS) |
| Apptainer compatibility | ✅ run SIF from share | 🟢 | 🟢 | 🟢 (replicate SIF locally) | 🟡 (pull-then-run) |
| Shared model storage | ✅ single source of truth | 🟢 + redundancy | 🟢 + redundancy | 🟡 3× copies, lag | ✅ versioned registry |
| Domain separation | 🟢 dir + perms (soft) | 🟢 per-volume | ✅ pools/subvols/quotas (hard) | 🟡 per-folder | ✅ buckets + IAM |
| Backup implications | 🟢 one place to back up; server = SPOF | 🟡 replication≠backup | 🟡 redundant, complex snapshots | 🟡 copies≠backup | ✅ versioning/lifecycle, backup-friendly |

## 3. Per-option verdicts

- **NFS** — The canonical small-cluster shared filesystem. Simplest networked
  POSIX share; exactly what Slurm and Apptainer expect; ideal for shared model
  weights read by all nodes. Limits: the server is a SPOF and a bandwidth
  ceiling (mitigate with a fast NIC + RAID/redundant disks), and domain
  separation is permission-based (soft), not hard multi-tenancy. **Best
  fit for now.**
- **GlusterFS** — Scale-out POSIX with replication (redundancy is the upside).
  But more moving parts than NFS, historically weak small-file/metadata
  performance, and declining project momentum/packaging — questionable on
  Rocky 10. Disproportionate for 3 nodes.
- **Ceph** — The most powerful (RBD/CephFS/RGW, real multi-tenancy, strong
  redundancy) and the most complex. 3 nodes is the bare minimum; hyperconverging
  OSDs onto GPU nodes steals CPU/RAM/network from GPU jobs, and it needs a fast
  network and real ops expertise. Overkill for one admin at this scale; the
  right answer only at larger scale or when HA storage is mandatory.
- **Syncthing** — File *sync*, not a shared FS. Eventual consistency makes it
  unsafe for Slurm state or concurrent job I/O, and every node needs a full
  copy (3× storage; dataset can't exceed one node's disk). Genuinely useful for
  one job: replicating **static, read-only** assets (a model bundle, SIF images)
  to each node's local NVMe for max-speed local reads. Complementary, not
  primary.
- **Object storage (MinIO self-hosted, or cloud S3)** — S3 API, not POSIX.
  Excellent as a **versioned model/dataset/artifact registry** and a
  backup-friendly target (lifecycle, replication), with strong per-bucket/IAM
  domain separation. AI data loaders increasingly stream from S3. But it cannot
  be a Slurm working directory or a POSIX job dir, and Apptainer must pull
  images before running. Complementary second tier; cloud S3 is also an
  external SaaS (high-risk, off-host data).

## 4. Hybrid approaches (the realistic target)

Real AI clusters layer storage by role rather than picking one:

- **Primary POSIX shared FS = NFS** — the cluster namespace: shared
  `resources/`, Slurm state/spool, job files, and shared model weights read by
  all nodes. Single source of truth.
- **Object store (MinIO) as a second tier (later)** — versioned, content-
  addressed model/dataset/artifact registry **and** an off-host-capable backup
  target (helps close the bulk-backup gap in BACKUP_AND_RECOVERY.md §6).
- **Local NVMe scratch + optional Syncthing** — replicate hot, read-only models
  / SIF images to each node's local disk for max-speed reads when NFS bandwidth
  is the measured bottleneck; use local scratch for checkpoint-heavy I/O.

This is additive and staged — add tiers only when a tier's need is demonstrated
(GOVERNANCE.md §0), never all at once.

## 5. Decision (ratified 20260601-10)

Ratified: **NFS = canonical primary shared filesystem.** MinIO/object storage
remains a deferred second-tier design; Syncthing/local caching is an
optimization only if demonstrated by measurements; Ceph and GlusterFS are not
justified for the current 3-node cluster. **Deployment is deferred to a later
implementation phase — no NFS service installed, no shared-storage directories
created.**

1. **Adopt NFS as the primary shared filesystem.** Export a cluster-shared tree
   (`resources/`, shared project areas, Slurm state) from a server role on the
   control node (`gpu-01`, per NODE_ARCHITECTURE.md §5) — ideally backed by
   RAID/redundant disks and a fast NIC. Simplest option that enables
   node-agnostic Workers, shared models, Slurm, and Apptainer.
2. **Defer MinIO object storage** as a second tier (model/dataset registry +
   backup target) — adopt when versioned artifact management or an off-host bulk
   target is actually needed.
3. **Use Syncthing/local cache only if measured** NFS read bandwidth for hot
   models becomes a bottleneck.
4. **Avoid Ceph and GlusterFS at 3 nodes** — revisit Ceph only at larger scale
   or when HA shared storage becomes a hard requirement.

**Risk classification when implemented (GOVERNANCE.md §2):** an NFS *server*
(persistent network service shared across nodes, security surface) and MinIO
(an object-storage service) are **high-risk components → explicit User
approval** (§2.3). An NFS *client mount* on a node is routine. **Nothing is
installed by this document.**

## 6. Caveats & dependencies

- **Network interconnect is decisive** for NFS performance; resolve the cluster
  networking decision (GOVERNANCE.md §11) before committing to a shared-FS
  bandwidth assumption.
- **NFS server = SPOF**; pair with disk redundancy and treat its export as the
  primary backup subject (BACKUP_AND_RECOVERY.md). Control-node placement ties
  this to the `gpu-01` failover story (NODE_ARCHITECTURE.md §4).
- **Domain separation** under NFS is soft (perms); if hard isolation/quotas are
  ever required, object-store buckets (MinIO) or Ceph give stronger separation —
  a reason to keep MinIO on the roadmap.
- Reproducibility: shared model/image artifacts on any tier still carry recorded
  SHA256 / pinned digests (GOVERNANCE.md §6, ENVIRONMENT_POLICY.md §6).
