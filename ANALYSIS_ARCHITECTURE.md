# ANALYSIS ARCHITECTURE (research domain)

**Status:** Active from 2026-06-04 (operator decisions 20260604-02/-03).
**Scope:** The on-disk architecture of the **research domain**, realized as
`analysis/`. Canonical home for the namespace layout, the pipeline and container
sub-hierarchies, and the **version-management policy**. Referenced by
DIRECTORY_STANDARD.md §2/§5 and ENVIRONMENT_POLICY.md §4. **Version management is
canonically governed by VERSION_GOVERNANCE.md** (promoted M3-0); §4/§7 here remain as
architectural context. The research domain operates under the cluster priority model
(GOVERNANCE.md §1; ANALYSIS_STANDARDS.md).

> Governance note: this realizes the "research" domain (GOVERNANCE.md §1).
> `/home/hha/research` is **not** used.

---

## 1. Top-level layout

```
analysis/
├── pipeline/     # reusable analysis workflows (version-managed)
├── container/    # execution environments (version-managed)
├── reference/    # reference assets shared across research projects
└── projects/     # individual research projects (standard project tree, DIRECTORY_STANDARD.md §3)
```

- `pipeline/`, `container/`, `reference/` are **research-domain-shared** (used by
  many projects in this domain). Assets shared across **≥2 domains** still go in
  `resources/` (DIRECTORY_STANDARD.md §4); these three are research-only.
- Each subtree materializes **when its first content arrives** — never as empty
  scaffolding (GOVERNANCE.md §0).

## 2. `pipeline/` — workflows

```
analysis/pipeline/
├── nextflow/     # Nextflow / nf-core workflows
├── snakemake/    # Snakemake workflows
└── custom/       # first-party / bespoke pipelines
```

Within each engine, workflows are installed **by version** (§4):

```
analysis/pipeline/nextflow/
└── nf-core-rnaseq/
    ├── 3.21/
    └── current -> 3.21
```

## 3. `container/` — execution environments

```
analysis/container/
├── apptainer/    # derived execution artifacts (*.sif)
└── docker/       # canonical image sources (Dockerfiles / pinned OCI references)
```

**Containers are organized by functional environment, not by pipeline** — e.g.:

```
analysis/container/apptainer/
├── pytorch/
│   ├── 2.9-cuda13/
│   └── current -> 2.9-cuda13
├── tensorflow/
├── bio-r/
├── nfcore/
└── ...
```

**Source-of-truth chain (ENVIRONMENT_POLICY.md §6):**
- The **Docker / OCI image is the canonical source**, pinned by digest
  (`docker://repo/img@sha256:…`). Each `container/docker/<env>/<version>/` holds a
  **single `MANIFEST.md`** (pinned ref, digest, source URL, notes) plus any
  `Dockerfile`/`.def` — *not* separate `source.txt`/`image.digest` files
  (C1, 20260605-03).
- The **Apptainer `.sif` is a derived execution artifact**, built from that
  source into `container/apptainer/<env>/<version>/`, with a recorded SHA256
  sidecar. A digest/SHA mismatch is a hard stop.
- **No Docker daemon (decided 20260604-04).** `container/docker/` stores
  **canonical image sources only** — Dockerfiles, OCI references, digests, and
  metadata. **Apptainer is the sole execution runtime;** there is no Docker engine
  on the cluster. (Were one ever wanted, it is high-risk GOVERNANCE.md §2.3 →
  User approval.)

**Workflow-engine container cache (N1, 20260605-03).** Nextflow/nf-core fetch their
own per-process images; `NXF_SINGULARITY_CACHEDIR` points at a **managed cache**,
`analysis/container/apptainer/_engine-cache/` (set via
`infra/scripts/analysis-env.sh`), so engine-pulled images stay inside the governed
store. Such images are **pinned by the consuming pipeline's revision** (not
organized under the functional-env tree) — one documented exception, **not** a
second container regime. The Apptainer **build** cache (`APPTAINER_CACHEDIR`) is
separate and local (§7.3).

## 4. Version-management policy (pipelines and containers — identical model)

1. **Version-named directories.** Each installed tool/env keeps every version in
   its own directory: `<name>/<version>/` (e.g. `nf-core-rnaseq/3.21/`,
   `pytorch/2.9-cuda13/`). This is the **required** exception to the
   no-version-in-dirname rule (DIRECTORY_STANDARD.md §5): these are installed
   third-party artifacts, not first-party source under VCS.
2. **`current` symlink = the normal entry point.** Each tool/env has
   `<name>/current -> <version>` pointing at the active default. Day-to-day use
   references `<name>/current`.
3. **New installs default to the latest stable version**, and `current` is
   pointed at it (an explicit, logged action — never automatic).
4. **Projects pin exact versions.** Every project records the *resolved version*
   (e.g. `nf-core-rnaseq/3.21`, `pytorch/2.9-cuda13` + the `.sif` SHA256) in its
   `ENVIRONMENT_MANIFEST.md` (GOVERNANCE.md §4, ENVIRONMENT_POLICY.md §6) — never
   just `current`.
5. **No silent upgrades.** Moving `current` to a new version never rewrites a
   project's pinned reference; existing projects keep resolving the exact version
   they recorded until deliberately migrated.

### 4.1 Entry-point / symlink convention — resolved detail

**Decided (20260604-04):** the **`<name>/current` symlink is the canonical entry
point** — e.g. `analysis/container/apptainer/pytorch/current`. A bare convenience
symlink named `pytorch` **cannot coexist** with the version directory `pytorch/`
in the same parent (filename collision — filesystem-impossible), so the
**bare-name convenience symlink is NOT created**. Day-to-day use, and the example
references throughout this doc, resolve through `<name>/current`. (The hidden
`_versions/` alternative that would preserve a bare shortcut was considered and
**not adopted**.)

**Cross-node visibility (N4, 20260605-03):** `current` is swapped atomically
(`rename(2)`, M2 plan §5) so readers see old-or-new, never missing — but other NFS
clients may serve the **previous** target until their attribute cache expires
(seconds). This is acceptable because runs **pin exact versions**, not `current`;
`current` is a human convenience whose cross-node propagation is
eventually-consistent.

## 5. Storage placement (decided 20260604-04)

**The entire `analysis/` hierarchy is shared NFS storage** — all four subtrees
(`pipeline/`, `container/`, `reference/`, `projects/`), no exceptions. It is
presented at `/home/hha/analysis` on **every** node (the rest of `/home/hha`
remains per-node). This makes research fully node-agnostic (NODE_ARCHITECTURE.md
§3/§5) — any node sees the same workflows, containers, references, and projects.

Realization (deployed in **M2**, STORAGE_ARCHITECTURE.md ratified NFS): a new
NFS export **`/data/analysis`** (on the `gpu-01` server's 11 TB disk; relocated from
`/srv/nfs/analysis` in M3-3D, 2026-06-11), mounted on all three
nodes and presented at `/home/hha/analysis`, with `root_squash` and per-peer-IP
firewalling like the existing `resources` export. Implications (capacity on the
single non-redundant `gpu-01` volume, 1 GbE bandwidth for container/reference
loads, backup, NFS-safe atomic `current` symlink swaps) are detailed in the
2026-06-04 M1-revision/M2 handoff doc. **M1 single-node GPU validation is
unaffected and does not require this export.**

## 6. Reproducibility hooks

A research result must state, in addition to the GOVERNANCE.md §4 tuple: the exact
**pipeline version** (`<engine>/<tool>/<version>`) and **container version**
(`<runtime>/<env>/<version>` + `.sif` SHA256) it used. `current` is a convenience
for humans, never a recorded provenance value.

## 7. Operational policies (M2-0, 20260605-03)

Approved punch-list policies (M2 review Pass-1 + Pass-2). **Operational layer — the
frozen architecture (§1–§6) is unchanged.** Cross-cutting canonical docs
(RESOURCE_POLICY, BACKUP_AND_RECOVERY, OBSERVABILITY, ENVIRONMENT_POLICY) point
here for the research-domain specifics.

### 7.1 Storage pressure & M1 placement
- **Reclamation runbook (P2):** node_exporter tracks fs usage; at **80% (~1.44 TB
  on the single `/dev/sda3`)** escalate. Reclaim **regenerable** artifacts first —
  order: apptainer `.sif` → reference indices → reference FASTA → caches/engine
  cache — **preferring Tier-2 over Tier-1** (see research-program tiers), and
  **never** precious/active data of either tier. Future (undefined) programs reclaim
  before Tier-2.
- **M1 placement (I1):** M1 GPU validation must **not** write under
  `/home/hha/analysis` (the future M2-1 mountpoint — content there would be shadowed
  by the mount). Use a temp path (e.g. `~/m1-validation/`); the canonical pytorch
  env is built on shared storage in M2-4.

### 7.2 Backup scope for `analysis/` (BACKUP_AND_RECOVERY.md §3)
- **Single traversal (I5):** back up via the backing path **`/data/analysis`
  once**; on `gpu-01` skip the `/home/hha/analysis` bind view (avoids double-count).
- **`.regenerable` marker (C2):** the install tooling drops a `.regenerable` file
  into every regenerable version dir; backup **excludes any dir containing it** —
  replacing fragile version-name globs.
- **Include (precious):** `projects/<p>/{src,results,prompts,README.md,
  ENVIRONMENT_MANIFEST.md}`, non-re-downloadable raw inputs, and all
  `VERSIONS.md`/`MANIFEST.md`/`CHECKSUMS.md`.
- **Exclude (regenerable):** anything marked `.regenerable` — `.sif`s, installed
  pipeline payloads, reference data, build/engine caches.
- **Per-project VCS (N2):** each `projects/<project>/` is its **own git repo with a
  GitHub remote** (off-host durability — the on-cluster backup is not off-site;
  GOVERNANCE §4). `.gitignore` the NFS-resident regenerables/data.

### 7.3 Container & environment operations
- **Build cache (N5):** `APPTAINER_CACHEDIR` is set to a known **local** path (not
  NFS) via `infra/scripts/analysis-env.sh`, cleaned after each build, excluded from
  backup. Builds run **on local disk, then the verified `.sif` is moved to NFS**
  (N3) — avoids multi-GB writes / partial files over 1 GbE.
- **Security patches vs reproducibility (P3):** a patched image is a **new version**
  (`current` advanced explicitly, logged in `VERSIONS.md`); existing projects
  migrate **deliberately**. Never patch a version in place — versioning lets
  reproducibility and patching coexist.

### 7.4 Reference data operations
- **Index provenance (I4):** each built index records the **builder tool+version**
  (e.g. `STAR 2.7.x built this index`) in its `MANIFEST.md`/`CHECKSUMS.md`; a
  project using a different aligner version must rebuild or accept mismatch.
- **Raw-data ingest (N7):** record **source + SHA256 on arrival** (GOVERNANCE §6);
  land under the project's `data/`; back up large raw inputs only if
  non-re-downloadable.
- **Licensing/provenance (P5):** reference datasets record source URL **and
  license/provenance** in `CHECKSUMS.md`.

### 7.5 GPU coordination registry (I3, RESOURCE_POLICY.md §2)
- The "who holds which card" registry lives at **`/srv/nfs/resources/gpu-claims/`**
  as **cross-domain coordination state** — so `resources/` holds cross-domain
  *coordination state* in addition to shared binary assets (clarifies
  ENVIRONMENT_POLICY.md §4 / DIRECTORY_STANDARD.md §4). Schema:
  `node  gpu_idx  holder  job  tier  started  expected_release` (the `tier` field
  carries the T1>T2 priority).

### 7.6 Availability & monitoring
- **NFS SPOF (P1):** `gpu-01` is the NFS server → a single point of failure for all
  of `analysis/` cluster-wide. **Accepted risk** (consistent with the accepted
  whole-site-loss posture, BACKUP_AND_RECOVERY §3). Degraded mode: peers' `nofail`
  mounts make jobs **fail cleanly**, not hang boot; the `gpu-02` warm backup does
  **not yet** cover NFS (deferred).
- **Monitoring (P4):** add (a) a per-peer **NFS mount-health** check (`analysis`
  mounted?) and (b) an **`analysis`-fs usage** alert, via the existing
  Prometheus/node_exporter stack (OBSERVABILITY.md).

### 7.7 No empty scaffolding (C3)
- M2-0 created **no** `analysis/` directories; `analysis/` and its subtrees still
  materialize **on first content at M2-1+** (GOVERNANCE §0). Verified: `analysis/`
  absent at M2-0 completion.
