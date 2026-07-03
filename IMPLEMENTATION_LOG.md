# IMPLEMENTATION LOG

**Started:** 2026-06-02 (20260601-15, implementation mode)
**Operator context (updated 2026-06-02):** `hha` on `gpu-01`. **Passwordless
sudo on `gpu-01` only** (peers `gpu-02`/`gpu-03` still NO). Passwordless SSH mesh
established. Outbound HTTPS works. gpu-01 system services now deployed (root);
peer/all-node steps remain blocked on peer sudo.

This log records, per phase: summary · validation · issues · rollback notes.
Blockers are consolidated in §"Blocker report".

---

## Phase A — uv + Python baseline + utility validation ✅ COMPLETE

**Summary:** Installed **uv 0.11.18** to `~/.local/bin` (low-risk §2.1,
pre-approved). Download was **SHA256-verified against the published checksum
(match)** per GOVERNANCE.md §6. Installed a uv-managed **CPython 3.12.13**
baseline (user-space).

- `sha256(uv-x86_64-unknown-linux-gnu.tar.gz)` =
  `588f3e360f69ce02b6982aa99f2240e803933a6b7e176ac01617830adf955add` (verified).

**Validation:**
- `uv --version` → `uv 0.11.18` ✅
- `uv python install 3.12` → CPython 3.12.13 installed ✅
- End-to-end (in `/tmp`, throwaway): `uv venv` → `uv pip install rich==13.9.4`
  → import OK on py 3.12.13 → `uv lock` produced `uv.lock` ✅ (reproducibility
  path works). Throwaway removed.

**Issues:** none. (`pip3` is absent system-wide; uv replaces that need.)

**Rollback:** `rm ~/.local/bin/uv ~/.local/bin/uvx`;
`rm -rf ~/.local/share/uv ~/.cache/uv`.

## Phase B — Apptainer ⛔ BLOCKED

**Summary (updated 2026-06-02, sudo on gpu-01):** **Apptainer 1.5.0** (EPEL)
installed on `gpu-01`. **Peers blocked** (no peer sudo).

**Validation:** `apptainer --version` → 1.5.0 ✅; `apptainer exec docker://alpine`
→ ran, read `/etc/os-release` ✅. `--nv` GPU passthrough: mechanism present, but
the test failed against Alpine (musl can't run the glibc `nvidia-smi`) — full
GPU validation needs a glibc/CUDA image (deferred to avoid a large pull).

**Rollback:** `sudo dnf remove -y apptainer`.

## Phase C — Snakemake + Nextflow (workflow validation) ✅ COMPLETE (2026-06-02)

**Summary:** **Snakemake 9.22.0** via `uv tool` (user-space). **Nextflow 26.04.3**
installed user-space after installing a **verified Temurin JDK 21.0.11** to
`~/.local/jdk-21` (Java needs no root — like uv). Both medium-risk, executed
under the autonomous mandate; both reversible.
- `sha256(JDK 21.0.11 tar.gz)` = `4b2220e2…a4ca4de` (verified, match).
- `sha256(nextflow launcher)` = `a56de126…9e3c51e0` (recorded; Nextflow
  self-verifies its runtime jars on bootstrap).

**Validation:**
- Snakemake: dry-run planned 2 jobs ✅; real run "2 of 2 steps done", output
  produced ✅.
- JDK: `java -version` → OpenJDK 21.0.11 LTS ✅.
- Nextflow: `nextflow -version` → 26.04.3 ✅; minimal workflow
  (`channel.of(...).view()`) → `[SUCCESS]`, output emitted ✅.

**Issues:** Nextflow **26.x has a stricter DSL2 parser** — a naive process-block
test failed to compile (usage nuance, not an install defect; the engine executes
workflows correctly). Note for future workflow authors: target current DSL2
syntax. **Nextflow requires `JAVA_HOME=~/.local/jdk-21`** in the environment.

**Rollback:** `uv tool uninstall snakemake`; `rm ~/.local/bin/nextflow`;
`rm -rf ~/.local/jdk-21 ~/.local/share/nextflow`.

## Phase D — Node Exporter / DCGM / Prometheus / Grafana ◑ COMPLETE on gpu-01 (2026-06-02)

**Summary:** Deployed on `gpu-01`, **all bound to `127.0.0.1`** (no public
exposure, no firewall change needed; UIs reachable via SSH tunnel). Secure by
construction.
- **node_exporter 1.11.1** — official binary, **SHA256-verified**
  (`sha256sums.txt -c`), systemd, `127.0.0.1:9100`. 2158 `node_` metrics.
- **Prometheus 3.11.2** (EPEL), systemd, `127.0.0.1:9090`, scraping self +
  node_exporter.
- **Grafana 10.2.6** (AppStream), systemd, `127.0.0.1:3000`, Prometheus
  datasource provisioned; admin password stored as a **secret**
  (`~/.secrets/infra/grafana_admin.txt`, `600`) — never in the repo.
- **DCGM 4.5.3** (`datacenter-gpu-manager-4-cuda12`, NVIDIA repo) — `nvidia-dcgm`
  service, hostengine `127.0.0.1:5555`; `dcgmi discovery` sees both GPUs;
  telemetry sampled (GPUTL/FBUSD/TENSO).

**Validation:** node target `up=1`, prometheus target `up=1`; Grafana
`/api/health` → `database: ok`; all listeners confirmed `127.0.0.1` only;
`dcgmi dmon` returned live per-GPU metrics.

**Deferred (one sub-item):** **dcgm-exporter** (Prometheus `:9400` bridge) is not
packaged; it needs the NVIDIA container (via Apptainer `--nv`) or a source build.
DCGM telemetry is available now via DCGM core; the Prometheus GPU-metrics scrape
job is left commented in `prometheus.yml` pending the exporter. **Peer
exporters blocked** (peer sudo).

**Rollback:** `sudo systemctl disable --now grafana-server prometheus
node_exporter nvidia-dcgm`; `sudo dnf remove -y grafana prometheus
datacenter-gpu-manager-4-cuda12`; `sudo rm /etc/systemd/system/node_exporter.service
/usr/local/bin/node_exporter`; `sudo userdel node_exporter`; restore
`/etc/default/prometheus.orig`, `/etc/prometheus/prometheus.yml.orig`,
`/etc/grafana/grafana.ini.orig`; `sudo systemctl daemon-reload`.

## Phase E — SSH trust + cluster inventory refresh ✅ COMPLETE (2026-06-02)

**Summary:** Operator authorized `cluster_ed25519` on `gpu-02`/`gpu-03`.
**Passwordless SSH from `gpu-01` to both peers now works.** Added
`~/.ssh/config` aliases (`gpu-02`/`gpu-03` → IPs, `cluster_ed25519`,
IdentitiesOnly). Completed the **full peer inventory** (NETWORK_DISCOVERY_gpu02/
03.md, CLUSTER_NETWORK_SUMMARY.md).

**Validation:**
- `ssh gpu-02 hostname` / `ssh gpu-03 hostname` → OK, passwordless ✅
- Full mesh: `gpu-02 → gpu-03` reachable ✅
- Inventory: peers **identical** to gpu-01 (Rocky 10.1, 48c/188 GiB/1.8 TB,
  2× RTX 6000 Ada, 1 GbE I350); only SSH listening; firewalld active; SELinux
  enforcing; **passwordless sudo NO on peers too**.

**Issues:** no cluster-internal name resolution (hostnames not in DNS/`/etc/hosts`)
— gpu-01 uses SSH aliases; a cluster `/etc/hosts`/DNS is needed for Slurm/NFS
(root). Minor DNS inconsistency across nodes (gpu-02 adds `8.8.8.8`).

**Rollback:** `rm ~/.ssh/cluster_ed25519*`; remove the `gpu-02`/`gpu-03` blocks
from `~/.ssh/config`; (peer `authorized_keys` entries are operator-managed).

## Phase F — NFS deployment ◑ SERVER COMPLETE on gpu-01 (2026-06-02)

**Summary:** **NFS server** stood up on `gpu-01` (`nfs-utils`, `nfs-server`
enabled). Export **`/srv/nfs/resources`** (owned `hha`, the shared `resources/`
realization) to **peer IPs only** (`222.231.57.31`, `222.231.57.32`) with
**`root_squash`**. firewalld **rich rules** allow NFS **only from the two peer
IPs** — *not* added to the public zone, so it is **not internet-exposed**
(verified). SSH rules untouched.

**Validation:**
- Export active to both peers (`exportfs -v`).
- IP restriction enforced: a `127.0.0.1` mount was **denied** (not in allow-list) ✅.
- Data path: a temporary localhost export → mount → **write as `hha`** → read-back
  matched, file landed in the backing store owned `hha` ✅; **root write squashed**
  (root_squash working) ✅; temporary export removed, restored to peers-only.

**Blocked:** **peer mounts** (`gpu-02`/`gpu-03` need peer sudo to mount). **Open
input:** confirm `222.231.57.0/24` is dedicated vs shared; consider `sec=krb5`
and a private VLAN as hardening (SECURITY_AND_HARDENING_POLICY.md). Residual risk
is bounded by the per-IP firewall + export ACL + root_squash.

**Rollback:** `sudo systemctl disable --now nfs-server`; restore
`/etc/exports.orig` (or empty) + `sudo exportfs -ra`; remove the two NFS
firewall rich-rules + `--reload`; `sudo dnf remove -y nfs-utils`;
`sudo rm -rf /srv/nfs`.

## Phase G — Slurm deployment ⛔ BLOCKED

**Summary:** Doubly blocked. (1) **Not packaged for el10** — no `slurm*` in
baseos/appstream/crb/EPEL/cuda, and no OpenHPC-el10 repo; only `munge` is
available. Deploying would require OpenHPC-el10 (uncertain availability) or a
source/rpmbuild. (2) **Peer sudo required** — `slurmd` + munge must run on
`gpu-02`/`gpu-03`, which lack passwordless sudo, plus a cluster `/etc/hosts`/DNS
(root). A controller-only build on `gpu-01` would give no real scheduling. Not
attempted (avoids a source-build that cannot complete without the peers).

**Rollback:** n/a (nothing installed).

---

## Update 2026-06-02 (cont.3) — peer sudo on ALL nodes → cluster-wide completion

Passwordless sudo confirmed on **all three nodes**. Verified actual state (no
assumptions), then completed multi-node implementation. Authoritative current
state: **CLUSTER_STATUS.md**.

- **Replicated to gpu-02/gpu-03 (Priority 1):** `~/.local` stack (uv 0.11.18,
  CPython 3.12.13, Snakemake 9.22.0, JDK 21.0.11, Nextflow 26.04.3) via tar/SSH;
  Apptainer 1.5.0 via EPEL. All validated on peers.
- **Monitoring mesh (Priority 2):** node_exporter 1.11.1 on peers (firewalled to
  gpu-01); Prometheus now scrapes **all 3** (`up=1` ×3); DCGM 4.5.3 active on all
  nodes (2 GPUs each). `dcgm-exporter` bridge still deferred (not packaged).
- **NFS (Priority 3):** mounted + persistent (`/etc/fstab`) on both peers;
  **cross-node validated** (gpu-02 write → gpu-03 read). Server unchanged.
- **Slurm (Priority 4):** **no el10 path** — not in EPEL; **OpenHPC EL_10 = 404**
  (EL_9 only); SchedMD source-only. `munge` + gcc/make available; source build
  feasible but not low-risk → recommendation in CLUSTER_STATUS.md §7 (interim:
  Nextflow/Snakemake over SSH+NFS; Slurm via deliberate source build when
  queueing is needed).
- **Obsolete blockers:** peer sudo, peer SSH, peer installs, NFS mounts — all
  resolved.

Rollback (peers): mirror the gpu-01 per-phase rollbacks via SSH; unmount NFS +
remove fstab line; `rm -rf ~/.local` to remove the user-space stack.

## Blocker report (historical — see CLUSTER_STATUS.md for current)

**Done on gpu-01:** Apptainer (B), monitoring core (D: node_exporter +
Prometheus + Grafana + DCGM), NFS server (F). **Resolved earlier:** SSH trust +
inventory (E), Snakemake + Nextflow (C).

| Item | Status | Blocker | Unblock with |
|------|--------|---------|--------------|
| B Apptainer (peers) | gpu-01 ✅ / peers ⛔ | **no peer sudo** | passwordless sudo on `gpu-02`/`gpu-03` |
| D node/Prometheus/Grafana/DCGM (peers) | gpu-01 ✅ / peers ⛔ | no peer sudo | peer sudo |
| D dcgm-exporter (Prom `:9400`) | ◑ deferred | not packaged | NVIDIA container via Apptainer, or source build |
| F NFS peer mounts | server ✅ / mounts ⛔ | no peer sudo | peer sudo (+ subnet dedicated/shared answer) |
| G Slurm | ⛔ | **not packaged for el10** + no peer sudo | OpenHPC-el10 / source build **and** peer sudo |

**Two remaining root causes:** (1) **passwordless sudo is gpu-01 only** — every
*peer* and *all-node* step (peer Apptainer/exporters/NFS-mounts, all of Slurm) is
blocked; (2) **Slurm has no el10 package** (independent of sudo). No destructive
action, data loss, config replacement, or architectural conflict occurred. All
changes are on `gpu-01`, reversible (rollback per phase above).

## Security observations (for the hardening phase)

- **Monitoring UIs are localhost-only** (verified: 127.0.0.1 for 3000/9090/9100/
  5555) — reach via SSH tunnel, never public. ✅
- **NFS** daemons bind `0.0.0.0` (rpcbind/nfsd/mountd) **but firewalld restricts
  them to the two peer IPs** (NFS not in the public zone) → not internet-exposed.
- **Pre-existing default:** firewalld public zone allows `cockpit` and
  `dhcpv6-client` (Rocky defaults). `cockpit` is **not currently listening**
  (no socket active), so no live exposure — but the rule is latent and should be
  reviewed/removed in the security-hardening phase
  (SECURITY_AND_HARDENING_POLICY.md §3). Not changed here (out of this phase's
  scope).

## M2-1 — shared `analysis/` NFS export ✅ COMPLETE (2026-06-05, 20260605-04)

**Summary:** Deployed the research-domain shared storage. Second NFS export
**`/srv/nfs/analysis`** on `gpu-01` (owner `hha`, mode 2775), exported to peer IPs
`.31`/`.32` with `rw,sync,root_squash,no_subtree_check` — **no firewall change**
(the existing per-IP `service=nfs` rich-rules already admit both peers). Presented
at the uniform path **`/home/hha/analysis`** on every node: `gpu-01` **bind**
(`/srv/nfs/analysis → /home/hha/analysis`), peers **nfs4.2** mounts
(`_netdev,noatime,nofail`). Created **only** the four approved top-level dirs
(`pipeline container reference projects`), all empty. **No tools/containers/
projects/references** created (per M2-1 scope).

**Validation:**
- `exportfs -v` shows both exports to both peers ✅.
- Mounts present + persistent (fstab) on all 3 nodes ✅ (gpu-01 bind ext4; peers
  nfs4.2).
- Cross-node: `gpu-02` wrote → `gpu-03` read → `gpu-01` backing confirmed, owner
  `hha:hha` ✅.
- `root_squash`: peer-`root` write squashed to `nobody` (throwaway 777 dir) ✅.
- 4 dirs present and **empty** ✅; `analysis/` absent before, now realized.

**Deviations:** (1) Backup include/exclude update + restore test (M2 plan §8 M2-1
checkpoint) **deferred** — dirs are empty, the `.regenerable`-marker exclusion only
applies once content exists; apply at first content. (2) Persistence is configured
via fstab but **not reboot-tested** (production nodes not rebooted). (3) The four
top-level dirs are pre-created empty **per explicit M2-1 instruction** (a deliberate,
operator-authorized exception to "materialize on first content"); deeper subtrees
still materialize on first content.

**Rollback:** unmount peers (`sudo umount /home/hha/analysis`) + remove their fstab
line; on gpu-01 unmount the bind + remove its fstab line; remove the
`/srv/nfs/analysis` line from `/etc/exports` + `sudo exportfs -ra`;
`sudo rm -rf /srv/nfs/analysis`. (Backups of `/etc/exports` and `/etc/fstab` made
with `.pre-analysis.<ts>` suffixes on each node.)

## M3-0 — Governance promotion & canonicalization ✅ COMPLETE (2026-06-06, 20260606-01)

**Summary:** Promoted the M2-2 governance drafts to **canonical** documents in
`infra/` and applied all approved corrections (priority model, Surplus definition,
identifiers). **No services/NFS/mounts/projects/containers/workloads changed.**

- **Created (canonical, `infra/`):** `ANALYSIS_STANDARDS.md`, `PROJECT_ID_POLICY.md`,
  `DATA_STORAGE_POLICY.md`, `VERSION_GOVERNANCE.md`, `PROJECT_REGISTRY.md`.
- **Reconciled:** GOVERNANCE.md §1 (four-domain **priority model R>B>I>S**; **Surplus**
  = idle-capacity utilization; domains = priority/accounting, **not** isolation;
  former `runtime` domain superseded); RESOURCE_POLICY.md §2 (priority clause,
  fairness→priority); DIRECTORY_STANDARD.md §2 (namespace + `surplus`); 
  ANALYSIS_ARCHITECTURE.md (VERSION_GOVERNANCE pointer).
- **Identifiers frozen:** `P/B/I/S####` mains; subprojects **`-S##`** (kept).
- **PROJECT_REGISTRY** created as a template (no live project rows — no project created).
- **History:** M2-2A/M2-2B/M2-2C + the M2-2 drafts in `ChatGPT_handoff/` marked
  **historical/review** (retained, not deleted).

**Validation:** the five canonical docs exist in `infra/`; reconciliation edits in
place; no `analysis/` content, no project, no `/data/<ID>` created (verified).

**Rollback:** `rm` the five new `infra/` docs; revert the four reconciliation edits +
this entry + the INFRA_CHANGELOG entry + the prompt file; the handoff historical
banners are additive (revert if desired).

**M2 GOVERNANCE OFFICIALLY CLOSED** — no further governance drafting unless new
architecture decisions are introduced.

## M3-1 — Version-management tooling ✅ COMPLETE (2026-06-10, 20260610-01)

**Summary:** First implementation phase after M2 governance closure. Built and
validated the version-management framework. **No pipelines/containers/references/
projects installed** — tested only against throwaway directories with dummy data.

- **Created:** `infra/scripts/analysis-install` (Bash CLI: versioned install,
  atomic `current`, manifests, SHA256, central log, rollback, pin, verify, tracking
  for pipeline/container/reference); `infra/scripts/test-analysis-install.sh`
  (self-contained test suite); `infra/VERSION_MANAGEMENT_TOOLING.md` (docs).
- **New policy:** **Accelerated Computing Policy** — "GPU-first, CPU-compatible"
  (ENVIRONMENT_POLICY.md §9); operationalized via `--accel`/`--preferred` fields
  (`accel=both` ⇒ `preferred=gpu`).
- **Updated:** VERSION_GOVERNANCE.md §5 (tooling now implemented).

**Validation:** `test-analysis-install.sh` → **23/23 PASS** against
`ANALYSIS_ROOT=$(mktemp -d)` with dummy artifacts (versioning, atomic switch,
rollback, sha256 record + hard-stop + tamper-detect, `.regenerable`, pin resolution,
remove guards, tracking). Throwaway dirs removed; **real `/home/hha/analysis`
untouched (4 dirs still empty)** — verified.

**Rollback:** `rm infra/scripts/analysis-install infra/scripts/test-analysis-install.sh
infra/VERSION_MANAGEMENT_TOOLING.md`; revert the ENVIRONMENT_POLICY §9 +
VERSION_GOVERNANCE §5 edits + this entry + the changelog/prompt. No cluster state to
undo (no real installs).

## M3-2 — Runtime Foundation ✅ COMPLETE (2026-06-11, 20260611-01)

**Summary:** First runtime implementation. Tier-1 host **`bio`** conda env + Tier-2
first production **pytorch** container, both validated. **No pipelines/references/
projects installed; no P0001.** GPU-first policy enforced.

**Tier 1 — `bio` (host, gpu-01, user-space):**
- **Miniforge** → `~/miniforge3` (conda 26.3.2 / mamba 2.5.0). Installer
  `sha256=848194851a98903134187fbb4ab50efe87b003e0c0f808f97644b7524a62bf2c`
  (recorded per §6; no published sibling).
- `bio` env: samtools/bcftools/htslib 1.23.1 (htslib provides bgzip+tabix), bedtools
  2.31.1, seqkit 2.13.0, csvtk 0.37.0, pigz 2.8, GNU parallel 20260422, jq 1.8.1,
  yq 3.4.3, ripgrep 14.1.1. **62 pkgs pinned → `infra/bio-environment.yml`.**
- `conda init bash` (enables `conda activate bio`).

**Tier 2 — pytorch container (shared NFS):**
- Source (digest-pinned): `docker://pytorch/pytorch@sha256:60f22fb80755fd0b470fb47928dbd55816aa9f847edd95cf43c93253507a9ddf`
  (tag `2.9.1-cuda13.0-cudnn9-runtime`). Built locally (2.9 G) → registered via
  `analysis-install` to `analysis/container/apptainer/pytorch/2.9.1-cuda13.0/`,
  `current` set, `accel=both`/`preferred=gpu`, `--regenerable`.
  **SIF `sha256=8b068ec4f591aca1930e7161992ba2d812a5d4c72df61cb12cc3e49d27405804`.**
  Canonical source MANIFEST in `analysis/container/docker/pytorch/2.9.1-cuda13.0/`.

**Validation:** bio `conda activate bio` ✓. Container `--nv`: `nvidia-smi` → **2×
RTX 6000 Ada** ✓; torch 2.9.1+cu130, cuda avail True, **matmul GPU==CPU (sm_89)** ✓,
cuDNN conv ✓, `CUDA_VISIBLE_DEVICES` 0→1 / 0,1→2 ✓ — **closes the deferred Phase B
`--nv` validation**. `analysis-install verify` OK; `current` symlink ✓; rollback guard
✓ (single version → no-previous, mechanism per M3-1 23/23); registered SIF runs `--nv`
from NFS ✓.

**New docs (canonical):** `RUNTIME_FOUNDATION.md`, `CONTAINER_STANDARDS.md`,
`BIO_ENVIRONMENT.md`, `bio-environment.yml`. ENVIRONMENT_POLICY §9 (GPU-first) in force.

**Cleanup:** local build SIF + `apptainer cache clean` (disk 16 G used / 1.6 T free).

**Deviations/notes:** (1) `bio` installed on **gpu-01 only** — replicate to gpu-02/03
via `mamba env create -f infra/bio-environment.yml` (follow-up). (2) Docker source
MANIFEST written manually (not via tool) → `list` shows blank accel for the docker
entry (cosmetic; it's a source record).

**Rollback:** `conda env remove -n bio`; `conda init --reverse bash`;
`rm -rf ~/miniforge3 infra/bio-environment.yml`; for the container: set-current away
then `analysis-install remove container apptainer pytorch 2.9.1-cuda13.0` (or
`rm -rf analysis/container/{apptainer,docker}/pytorch`); revert the new docs + log
entries. SIF is regenerable from the pinned digest.

## M3-3 — Pipeline Layer ✅ COMPLETE (2026-06-11, 20260611-02)

**Summary:** Established + validated the pipeline layer (Tier-2 workflow tier). **No
research pipelines installed, no project/P0001** — validated the mechanism with a
neutral, project-independent workflow. GPU-first enforced.

- **Engines confirmed:** Snakemake 9.22.0, Nextflow (needs `JAVA_HOME=~/.local/jdk-21`).
- **Engine cache created:** `analysis/container/apptainer/_engine-cache/` (N1;
  `NXF_SINGULARITY_CACHEDIR` per `analysis-env.sh`).
- **First pipeline registered:** `analysis/pipeline/custom/runtime-smoke/0.1/`
  (current; accel=both, preferred=gpu; first-party, not regenerable;
  SIF/source `sha256=14a808043a53c2112d0187ecc6f1ac7211d94b29885585c99624e7658c047ede`)
  via `analysis-install`. A neutral engine→container(`--nv`)→GPU validation harness.
- **New canonical doc:** `PIPELINE_STANDARDS.md`.

**Validation:** Snakemake → `apptainer exec --nv` (pytorch `current`) → GPU →
`cuda True, device_count 2, RTX 6000 Ada` ✓ (run both from a temp dir and from the
**canonical store path** via `current`); Nextflow engine ran a DSL2 workflow ✓;
`analysis-install` list/show-current/verify(OK)/pin ✓; store left clean (no
`results/`/`.snakemake/` committed).

**Deviations/notes:** (1) Interpreted M3-3 as establishing/validating the layer with a
**neutral** workflow; **research pipelines (nf-core, …) deliberately NOT installed** —
operator-directed, project-coupled, avoids speculative multi-GB pulls. (2) `--from` a
dir nests the payload under `<version>/workflow/` (tool copies the dir) — cosmetic.
(3) bio-env peer replication + `/data` provisioning still pending (carried).

**Rollback:** `analysis-install` set-current away then remove (or
`rm -rf analysis/pipeline/custom/runtime-smoke`); `rm -rf
analysis/container/apptainer/_engine-cache`; revert PIPELINE_STANDARDS.md + log
entries. No engine/cluster service changed.

## M3-3D — Storage architecture refactor EXECUTED ✅ COMPLETE (2026-06-11, 20260611-03)

**Summary:** Separated namespace (`/home/hha`) from physical storage (`/data`).
`analysis/` **stays cluster-shared**; only its backing moved. Executed per the M3-3C
plan. Infra committed+pushed first (`c12346e`). Config snapshots `*.pre-m3-3d.20260611T153701Z`.

- **Analysis backing moved** `/srv/nfs/analysis` (1.8 TB root) → **`/data/analysis`**
  (gpu-01, 11 TB). `rsync -aHAX` (31 objs, byte-identical/checksum-verified, symlinks +
  SIF sha `8b068ec4…` preserved). Re-exported `/data/analysis` to peers (no firewall
  change); fstab: gpu-01 bind `/data/analysis→/home/hha/analysis`, peers NFS-mount
  `gpu-01:/data/analysis→/home/hha/analysis`. **Namespace `/home/hha/analysis`
  unchanged on all nodes.**
- **Miniforge relocated** (reinstall, not mv) → **`/data/local/runtime/miniforge3`**
  per node; `bio` recreated from `bio-environment.yml` on **all 3 nodes** (closes the
  M3-2 gpu-01-only gap); `conda init` re-pointed (old `~/miniforge3` block reversed on
  gpu-01). Installer sha256 `848194851a…`.
- **Engine cache** → per-node `/data/local/cache/engine` (`NXF_SINGULARITY_CACHEDIR`
  in `analysis-env.sh`); empty shared `_engine-cache` removed.
- **Handoff** moved `/home/hha/ChatGPT_handoff` → **`/data/admin/handoff`** (35/35
  files); transition symlink left; **memory + GOVERNANCE §1/§12 + DIRECTORY_STANDARD §7
  + MEMORY.md updated** to the new path. **Log** → `/data/admin/logs/cluster-backup.log`.
- **Backup extended** (`cluster-backup.sh`): now also mirrors `/data/analysis`
  (precious; **excludes** SIFs/cache/refdata) + `/data/admin` to both peers; ran OK
  (analysis 12 files, admin 36 files, 0 SIFs) — **closes the prior analysis-backup gap.**
- **/data provisioned** on all nodes (root mkdir+chown hha): `analysis` (gpu-01),
  `local/{runtime,cache,scratch,projects}` (all), `admin/{handoff,logs}` (gpu-01).

**Validation (all 3 nodes):** analysis backed by `/data/analysis`; 4 dirs visible;
`conda activate bio` → samtools 1.23.1; container `--nv` → torch 2.9.1+cu130, cuda
True, 2 dev; `analysis-install verify` OK; cross-node R/W + root_squash; runtime-smoke
pipeline runs from store; backup peer-mirrors verified.

**Rollback RETAINED (not yet decommissioned):** old `/srv/nfs/analysis` (2.9 G), old
`~/miniforge3` (2.1 G), config snapshots `*.pre-m3-3d.<ts>` (all nodes), pre-migration
commit `c12346e`. Decommission after a confidence period: `rm -rf /srv/nfs/analysis
~/miniforge3` + drop the old export/fstab snapshots.

## M3-3F — Legacy asset cleanup ✅ COMPLETE (2026-06-12, 20260612-01)

**Summary:** Finalized the storage refactor by removing rollback-only assets
(re-confirmed no active consumers first). ~4 GB reclaimed; `/home/hha` top level now
clean (`analysis` + `infra` + dotfiles).

- **Removed:** `/home/hha/miniforge3` (2.1 G — no PATH/profile ref on any node),
  `/srv/nfs/analysis` (2.9 G — not exported/mounted/in-fstab), and the
  `/home/hha/ChatGPT_handoff` compatibility **symlink** (target `/data/admin/handoff`
  untouched).
- **Kept (per instruction):** `*.pre-m3-3d.<ts>` snapshots, peer backup mirrors,
  historical docs/prompts/changelog.
- **Docs:** GOVERNANCE §1/§12 + DIRECTORY_STANDARD §7 now note the symlink **removed**.
- **Validated (all 3 nodes):** namespace clean; `conda activate bio` →
  `/data/local/runtime/miniforge3`; analysis → `/data/analysis`; container `--nv`
  cuda True/2-dev; 2 GPUs; handoff writes to `/data/admin/handoff`.
- **Rollback now via:** off-host git (`c12346e`/`85380a2`/this commit), kept config
  snapshots, peer backup mirrors, and regeneration recipes (`bio-environment.yml`,
  pinned pytorch digest). Instant revert to old paths is intentionally retired —
  `/data/analysis` + `/data/local` are the baseline.

**Storage refactor (M3-3B→C→D→E→F) COMPLETE. Cluster ready for M3-4 (Reference Layer).**

## M3-4B — Reference Layer: human references + RNA indexes ✅ COMPLETE (2026-06-15, 20260615-01)

**Summary:** Populated the reference layer with the operator-prioritized **human
references** (GENCODE + GRCh38 primary) + the near-term **STAR/Salmon indexes**, all
version-governed via `analysis-install` under `/data/analysis/reference`. Nanopore
model assets remain deferred (need P0001 scoping). New doc: **REFERENCE_LAYER.md**.

**Registered (all `--regenerable`, pinned + SHA256 + MANIFEST):**
| Asset | Version | SHA256 |
|-------|---------|--------|
| `genome/homo_sapiens-GRCh38` | gencode-v50 | b760d18d… |
| `annotation/gencode-human` | v50 (GTF + transcripts) | dd6d33ba… |
| `variation/clinvar` | 2026-06-06 | 2ef1a453… |
| `variation/dbsnp` | b157-GRCh38p14 (28 GB) | 329da439… |
| `index/star-GRCh38-gencode-v50` | 2.7.11b-sjdb100 (29 GB) | 49cc0fac… |
| `index/salmon-GRCh38-gencode-v50` | 2.0.0-k31 (11 GB) | 8dcf267b… |

- **Source:** GENCODE v50 (genome `chr`-prefixed + GTF + transcripts); ClinVar/dbSNP
  from NCBI. **Chrom-naming caveat** recorded (GENCODE `chr1` vs ClinVar `1` vs dbSNP
  `NC_…`) — rename when intersecting (REFERENCE_LAYER §3).
- **Indexes (I4):** STAR 2.7.11b (sjdbOverhang 100) + salmon 2.0.0 (decoy-aware, k=31)
  built from the registered genome+annotation; builder versions + source recorded in
  each index MANIFEST. Build-env pinned: **`infra/rnaseq-buildenv.yml`** (host conda
  `rnaseq`: STAR 2.7.11b, salmon 2.0.0). Pipelines themselves use containers.
- **Backup fix:** `cluster-backup.sh` reference excludes corrected for the
  category-first layout (`reference/index/**`, `model/**`, `*.{fa,fa.gz,gtf.gz,vcf.gz,tbi}`)
  so the 28 GB dbSNP / 29 GB STAR index are **not** mirrored/hashed (regenerable);
  only MANIFEST/CHECKSUMS backed up.
- **Footprint:** reference store ~68 GB on `/data/analysis` (11 TB; 2% used). Build
  scratch removed.
- **Deferred:** Tier-1 Nanopore model assets (Dorado/Remora/ground-truth) — need P0001.

**Rollback:** `analysis-install` set-current-away + remove per asset (or
`rm -rf reference/<category>/<name>`); all `--regenerable` (re-fetch/re-build from
recorded source + build-env). `rnaseq` build-env removable (`conda env remove -n rnaseq`).

## M3-4D — Platform Wave 1 + Runtime tooling ✅ COMPLETE (2026-06-17, 20260617-01)

**Summary:** Host productivity tools standardized on all 3 nodes; 3 reusable platform
containers built/registered/validated; somatic + Dorado evaluated (deferred with rationale).

- **Part A (host tools):** bat 0.26.1, eza, fd 10.4.2, fzf 0.73, btop 1.4.7, tree 2.3.2,
  pv 1.6.6 → `bio` env, all 3 nodes (conda-forge; lockfile re-exported, 67 pkgs).
  ripgrep/jq/yq/seqkit/csvtk/pigz/parallel already present (not reinstalled). 14/14 verified.
- **Part B:** `RUNTIME_TOOLS.md` registry created.
- **Part C (containers, reference-free, analysis-install, pinned+SHA256+MANIFEST+current):**
  `ml/2.9.1-cuda13.0` (03a8725f; PyTorch 2.9.1+cu130 + Lightning 2.6.5 + XGBoost 3.2.0 +
  LightGBM 4.6.0; GPU), `longread/2026-06-17` (e020d020; minimap2 2.31/samtools 1.23.1/
  sniffles2 2.3.2/cuteSV 1.0.8/modkit 0.6.4; CPU), `bioconductor/bioc3.21` (d6975407;
  DESeq2/edgeR/limma/fgsea/GSVA/clusterProfiler; CPU). `.def` recipes saved to
  `container/docker/<env>/<version>/`.
- **somatic:** evaluated → NOT built (Strelka2/Manta need Python 2.7, conflicts with
  GATK4/CNVkit) → Wave-2 **nf-core/sarek** pipeline-first. **Dorado:** evaluated → separate
  GPU container + models, deferred to Wave 2.
- **Validation:** ml `--nv` (cuda True/2-dev) + longread + bioconductor all run, incl.
  **cross-node on gpu-02**. Container store 8.0 GB; /data 78 GB/11 TB.
- **Rollback:** `analysis-install` remove per container; host tools `mamba remove -n bio …`;
  all regenerable from `.def`/lockfile.

## M3-4D follow-up — Runtime Utility Exposure Layer ✅ COMPLETE (2026-06-17, 20260617-02)

**Summary:** Closed the M3-4D usability gap — 11 general-purpose utilities now work in a
fresh login shell with **no `conda activate bio`**, while `bio` stays the single source of
truth and bioinformatics tools stay env/container-controlled.

- **Mechanism:** per-node symlinks `~/.local/bin/<tool>` → `bio` env binary, created by
  new `scripts/expose-runtime-utils.sh` (idempotent; allow-list + deny-list; `--remove`).
  Symlinks (not copies); conda RPATH `$ORIGIN/../lib` resolves env libs through the
  symlink → runs with no activation, no `LD_LIBRARY_PATH`. No PATH/rc/system edits.
- **Exposed (11):** bat eza fd rg fzf btop jq yq tree pv parallel.
  **Not exposed (scientific):** samtools bcftools bedtools seqkit csvtk (+pigz).
- **Validation (fresh login, no activate):** gpu-01/02/03 all **PASS** — 11 resolve to
  `~/.local/bin` + run `--version`; 5 scientific tools confirmed hidden. No base-env
  shadowing; `/usr/bin/jq` correctly overridden.
- **Docs:** RUNTIME_TOOLS.md (exposure boundary + per-tool column), RUNTIME_FOUNDATION.md
  (§1 principle + new §5), BIO_ENVIRONMENT.md (exposure note).
- **Rollback:** `bash scripts/expose-runtime-utils.sh --remove` (per node).
- **Reviewed (not installed):** candidate additions ncdu/dust/duf/tmux/delta/glow —
  recommendation left to operator Decision Layer.

## M3-4E — Platform Wave 2: single-cell + nf-core pipelines + Dorado/Remora ✅ COMPLETE (2026-07-01, 20260701-01)

**Summary:** Completed + anchored the in-flight Wave-2 build. Single-cell platform finished
(scanpy/scvi-tools/seurat/CellTypist/Harmony), nf-core scRNA-seq + RNA-seq pipelines
registered, and the Tier-1 anchor **Dorado + Remora** GPU container built/validated/registered.
All reference-free, version-governed via `analysis-install`, Reuse-First. Recovery note: the
06-18/19 build work (scanpy/scvi-tools registered; seurat/pipelines staged) had not been
committed to git or handed off — this milestone anchors it (git = authority).

- **Single-cell containers (apptainer, pinned+SHA256+MANIFEST+current; `.def` → `container/docker/…`):**
  - `seurat/2026-06-18` (545a7db2; Seurat 5.5.0 + harmony 2.0.5 + Matrix; CPU; FROM bioconductor base) — promoted from scratch, functionally validated.
  - `scanpy/2026-06-24` (3c87892e; scanpy 1.12.1 + **celltypist 1.7.1** + anndata 0.12.17 + leidenalg/igraph/louvain/harmonypy/scrublet/scikit-misc; CPU) — **now current**, adds CellTypist; supersedes `scanpy/2026-06-18` (retained).
  - (already registered 06-18: `scanpy/2026-06-18`, `scvi-tools/2026-06-18-cuda13.0` scvi-tools 1.4.2 GPU.)
- **Pipelines (nextflow, container-first, local-reference `igenomes_ignore`, engine cache `/data/local/cache/engine`):**
  - `pipeline/nextflow/scrnaseq/4.1.0` — nf-core/scrnaseq; **preview test PASS**. Upstream/parser issue: 4.1.0 `nextflow.config` includes a missing `conf/test_multiome.config`; Nextflow 26.04.3 strict (v2) parser aborts → **requires `NXF_SYNTAX_PARSER=v1`** (baked into the pinned `pin.txt`).
  - `pipeline/nextflow/rnaseq/3.26.0` — nf-core/rnaseq; preview PASS 2026-06-19; strict parser OK (no flag). Reuses local STAR/Salmon indexes.
- **Dorado + Remora (Tier-1 anchor):** `container/apptainer/dorado/2.0.1-cuda13.0` (0a1ac2f2;
  **dorado 2.0.1** self-contained ONT binary + **ont-remora 3.3.0**; **torch 2.9.1+cu130 preserved**;
  FROM the validated pytorch base — Reuse-First; build tools added in %post for remora's Cython
  ext). **GPU `--nv` validated: cuda True, 2-dev RTX 6000 Ada.** Model-free — models mount
  read-only from `reference/model/dorado/`. New scaffold: `reference/model/README.md` (+ `dorado/`).
- **Storage:** container store 21 GB (dorado 6.6 GB, scvi 3.2, ml 3.2, pytorch 2.9, bioconductor 1.7,
  seurat 1.6, scanpy 1.2, longread 0.3); `/data` 123 GB / 11 TB (2%). Wave-2 scratch (`/data/local/scratch/m3-4e`) cleaned post-registration.
- **Rollback:** `analysis-install` set-current-away + remove per container/pipeline; all regenerable
  from `.def`/`pin.txt` (recipes-of-record under `container/docker/…` and the pipeline payloads).
- **Deferred (per brief):** VEP/SnpEff, Structure-AI (AlphaFold/ESM/Chai/Boltz) — until a concrete project requires them.

## M4 — Core principle: shared-by-default platform assets ✅ CODIFIED (2026-07-01, 20260701-02)

**Summary:** Adopted the M4 core principle — infrastructure, agents, pipelines, containers,
references, models, and **reusable scripts** are **shared platform assets by default**,
easy to update/version/deprecate/reuse; projects **consume** them by pinning exact versions
in `ENVIRONMENT_MANIFEST.md` and **do not copy/fork** into project trees without a
documented reason. Codified by **extending existing canonical governance** (Reuse-First
applied to governance itself — no new redundant docs).

- **PLATFORM_REUSE_POLICY.md** (the canonical hub) — new **§0 M4 core principle**; **§1**
  broadened asset scope (infra/agents/scripts, not just the 4 `analysis-install` kinds) +
  the full **4-rung ladder** `Reuse > Extend > New shared > Project-specific (justified)`;
  **§4** reconciled the "never fork" rule to a **documented-exception** (rung 4) recorded in
  the project's Capability Resolution; new **§8 Agent components are shared assets** (shared
  logic/prompts in the platform layer; project-specific instructions in PROJECT_MASTER/TODO;
  Model ≠ Role; no premature materialization of a prompt store).
- **AGENT_WORKFLOW_STANDARD.md §4** — cross-ref: agent components are shared assets
  (PLATFORM_REUSE_POLICY §8).
- **Refinement flagged:** the prior "projects **never** fork" (binding) is now "no fork
  **unless a documented project-specific reason**", per the operator's stated principle.
- **No functional/platform change** — governance-only; no assets rebuilt.
- **Prompt archived:** `prompts/20260701-02_m4_core_principle.md`.

## M4 — Execution principle: autonomous progress ✅ CODIFIED (2026-07-01, 20260701-03)

**Summary:** Adopted the M4 Execution Principle — **default behavior is autonomous progress**
(`Plan → Execute → Validate → Document → Handoff`), human interruption minimized, related
work **batched into logical milestones** with a **single handoff**. Operator confirmation is
required only on explicit triggers; otherwise choose per governance, document, and continue.
Codified by **extending GOVERNANCE.md** (Reuse-First on governance — no new doc).

- **GOVERNANCE.md §3b** (new, CANONICAL) — the autonomous-execution default; the 7 confirmation
  triggers (irreversible/destructive · security/credential · financial · licensing/legal ·
  alters approved architecture · governance-unresolvable ambiguity · scientific human-judgment)
  mapped to the §2 User-approval rows; **tie-breaker order** `Reuse-First → Shared-by-default →
  Container-first → Pipeline-driven → Provider-agnostic → Automation-ready`; **batching** clause
  (one milestone → validate → single handoff, don't interrupt long sequences).
- **AGENT_ARCHITECTURE.md §4** — decision procedure now states autonomous progress is the norm;
  escalate only on a §3b trigger.
- **No approval gate relaxed** (§2 unchanged); does not weaken §4/§5/§6/§7. Governance-only.
- **Prompt archived:** `prompts/20260701-03_m4_execution_principle_autonomous.md`.

## M4 — Project Import Policy ✅ CODIFIED (2026-07-01, 20260701-04)

**Summary:** Adopted the Project Import Policy — a project may originate as a **newly
approved** project or an **imported/migrated** one; both use the **same User-approval gate
and standard project tree**. Imports **preserve** prior docs/handoff/protocols/planning
under `analysis/projects/<PROJECT_ID>/docs/` (reference-only) and are **reconstructed** on
the current platform via shared capabilities. *Goal = reproducible reconstruction, not file
migration; the platform is the authoritative execution environment; prior outputs are
reference.* Codified by **extending** PROJECT_LIFECYCLE + DIRECTORY_STANDARD (no new doc).

- **PROJECT_LIFECYCLE.md** — §2 two origins (fresh / imported, same gate); new **§4a Import
  / migration procedure** (approve as project w/ Capability Resolution mapping legacy →
  shared capabilities; preserve prior materials read-only in `docs/`, not an execution
  input; reconstruct current canonical files; provenance in README; re-derive results
  before reporting).
- **DIRECTORY_STANDARD.md §3** — added **`docs/`** to the project shape, **sanctioned for
  imported projects only** (reference-only; explicitly not catch-all sprawl); fresh projects
  don't create it.
- Ties to Reuse-First (PLATFORM_REUSE_POLICY), reproducibility (GOVERNANCE §4/§6), and the
  "execution reads only current canonical files" rule (AGENT_WORKFLOW_STANDARD §2).
- **No approval gate added/relaxed** (import = existing project-creation gate). Governance-only.
- **Prompt archived:** `prompts/20260701-04_m4_project_import_policy.md`.

## M4 — Project Documentation Refinement ✅ CODIFIED (2026-07-01, 20260701-05)

**Summary:** Refined the Project Import Policy: **`docs/` is now standard in every project**
(not imported-only), with a fixed substructure so automation/agents can rely on it. `docs/`
is **documentation only — not an execution workspace**; agents read it as **reference only**
and never treat imported docs as canonical execution instructions. Extended existing docs
(no new governance doc).

- **DIRECTORY_STANDARD.md §3** — `docs/` promoted to REQUIRED (all projects); standard
  substructure `proposal/handoff/protocol/literature/meeting/archive/` created **lazily**
  (fresh projects begin with `docs/proposal/`); `docs/archive/` distinguished from the
  project-level `archive/` (spec snapshots); rule bullet rewritten (docs-only, not sprawl).
- **PROJECT_LIFECYCLE.md** — §4 (fresh projects create `docs/proposal/` for proposals/
  grants/planning); §4a (imported materials mapped to `docs/handoff/`, `docs/protocol/`,
  etc.); status line notes the refinement.
- Canonical execution stays governed only by PROJECT_MASTER / ENVIRONMENT_MANIFEST / TODO /
  project configs (AGENT_WORKFLOW_STANDARD §2).
- **Prompt archived:** `prompts/20260701-05_m4_project_documentation_refinement.md`.
  (Handoff folded into the M4-2 milestone handoff.)

## M4-2 — Platform Discovery Layer + Project Bootstrap ✅ COMPLETE (2026-07-01, 20260701-06)

**Summary:** Implementation milestone (not governance). Built the **Platform Discovery Layer**
(reusable capability catalog for humans + agents) by **extending** `analysis-install`, and
**Project Bootstrap** (create + import) that materializes the standard project tree incl.
`docs/`. Prepared — but did **not** run — the reusable import framework that P0003 (TBI
scRNA-seq) will be the first to use. Reuse-First / container-first / pipeline-driven /
provider-agnostic throughout; the live MANIFEST registry stays the single source of truth.

- **Discovery Layer (extend, not redesign):** `analysis-install`
  - `catalog [--kind|--accel|--category] [--json]` — lists the **current** version of each
    capability; `--json` is the agent interface (validated: 17 entries, valid JSON, queryable
    by category/accel/requires/compat).
  - `describe <kind> <group> <name> [version]` — full detail + version history.
  - Optional additive install metadata `--category/--provides/--requires/--compat` (MANIFEST
    append; `verify`-safe). Category **inferred** when absent. Backfilled current capabilities
    (pipelines' reference requirements + single-cell/dorado compat) — `verify` re-confirmed OK.
  - Fixed a field-parse bug (`manifest_field` → robust `sed`; handles values with `: `).
- **Project Bootstrap:** `scripts/project-bootstrap create|import` + `templates/project/`
  (README, PROJECT_MASTER, TODO, RECONSTRUCTION; reuses existing ENVIRONMENT_MANIFEST).
  `create` → canonical files + `docs/proposal/`; `import` → full `docs/` substructure +
  `docs/RECONSTRUCTION.md` + `--from` staging (reference-only) + per-project git.
  Materialization presupposes User approval; `--dry-run` previews. **Validated** both modes
  into a throwaway temp dir (token substitution, manifest identity fill, git init) — **no real
  project created.**
- **Docs:** PLATFORM_ARCHITECTURE §8a (discovery layer + bootstrap, concrete). PROJECT_REGISTRY
  §4 notes P0003 as anticipated first import (framework ready; not approved/registered/materialized).
- **Prompt archived:** `prompts/20260701-06_m4-2_discovery_and_bootstrap.md`.
- Foundation: consumes the 20260701-05 `docs/` standard.

## M4-3 — Project Execution Framework ✅ COMPLETE (2026-07-01, 20260701-07)

**Summary:** Built the reusable, **project-independent** Project Execution Framework
(`scripts/project-run`) — a **provider-agnostic** harness that will run P0001/P0002/P0003 with
the same execution model. **Agents orchestrate; the framework executes (Model ≠ Execution
Framework).** Execution starts **only** from `PROJECT_MASTER.md` + `ENVIRONMENT_MANIFEST.md` and
**never** from `docs/`. Extends the existing CLI/registry; no redesign.

- **Stages** (`project-run stages`): Project → Planning → Capability Resolution → Execution →
  Validation → Figure Generation → Result Packaging → Project Update → Handoff. Commands:
  `resolve` (verify manifest pins against the live registry; forbid `current`; record
  version+sha), `metadata` (RUN_MANIFEST reproducibility — reuses pins+registry sha+git+host+GPU
  +date, no duplication), `exec` (container-first, references mounted read-only at `/refs/<name>`),
  `figure` (enforce Figure PNG+PDF + Source-Data TSV + Metadata MD — GOVERNANCE §9), `package`
  (CHECKSUMS + triad re-check), `handoff`, and `run` (driver).
- **Figure pipeline** makes the triad the **default** — packaging fails on any incomplete figure.
- **Validated end-to-end (temp only; no real project):** bootstrapped a `create` project with
  real pins → `run` did resolve→metadata→exec(scanpy container, generated a figure)→triad
  check→package→RUN_LOG update→handoff. **Objective 7:** the SAME framework ran an `import`-mode
  project **unmodified** (docs/ present but excluded). Negative test: lone PNG correctly fails the
  triad; `figure --register` creates source-data+metadata stubs. All temp artifacts + stray
  handoffs cleaned; `/data/analysis/projects` still empty.
- **Docs:** PLATFORM_ARCHITECTURE §8b; AGENT_WORKFLOW_STANDARD §5 (execution mechanics; Model ≠
  Execution Framework).
- **Prompt archived:** `prompts/20260701-07_m4-3_project_execution_framework.md`.

## M4-4 — Research Knowledge Transfer Framework ✅ FRAMEWORK COMPLETE / ⛔ P0003 extraction BLOCKED (2026-07-02, 20260702-01)

**Summary:** Built the reusable **Knowledge Transfer Framework** (package structure + scaffold +
governance integration). **Did NOT fabricate P0003 content:** an exhaustive search found **no
P0003 (TBI scRNA-seq) source materials on this platform** — no legacy project, no refactored
version, no prior Claude Code work (only this infra transcript exists), no ChatGPT exports. P0003
is to be migrated *from another environment*; its materials live there. Extracting real research
knowledge is therefore **blocked pending the operator providing the source materials** (GOVERNANCE
§5 — ground or abstain; fabricated science would poison the reconstruction). This is a legitimate
M4 Execution-Principle confirmation trigger (project-specific scientific judgment + missing input).

- **Framework built:** `templates/knowledge_transfer/` — README + `01_project_overview` …
  `08_reconstruction_plan` + `Attachments/`, each encoding the required structure (03 trial-and-error
  = attempt→problem→solution→final decision; 04 = original→refactor→improvements→limitations; 05
  Claude reusable design decisions; 06 ChatGPT ideas/lit/rejected/future; 07 open vs completed; 08
  recommended NEW GPU implementation). Anti-fabrication + source-citation rules baked in.
- **Scaffold:** `project-bootstrap kt-init <dest> --project <ID> --source <env>` (token-substituted).
- **Governance:** PROJECT_LIFECYCLE §4a — imported projects carry `docs/knowledge_transfer/` as the
  **preferred distilled input**; platform consumes it to generate PROJECT_MASTER/TODO/execution plan
  ("transfer knowledge, not files"); never an execution input.
- **Validated** (temp only): kt-init scaffolds all 10 files, tokens substituted, scaffolds remain
  empty (no fabricated P0003 content). No real project created.
- **Prompt archived:** `prompts/20260702-01_m4-4_knowledge_transfer_framework.md`.
- **Next (operator):** provide P0003 source materials → I populate the package from real content.

## M4 Final Sprint — Platform v1.0 COMPLETE + FROZEN ✅ (2026-07-02, 20260702-02)

**Summary:** Completed the remaining reusable platform components and **froze Platform v1.0**.
P0001/P0002/P0003 will all begin on this version; the platform is **not** specialized for any of
them. Rapid implementation; no new governance docs (Constitution is the architectural north star,
explicitly not governance); extended existing assets.

- **Priority 1 — Platform Constitution:** `PLATFORM_CONSTITUTION.md` — concise philosophical north
  star (read first by humans + AI): the 10 principles (Reuse-First, Shared-by-default, Container-
  first, Pipeline-driven, Provider-agnostic, Automation-ready, Reproducibility, Human Decision
  Layer, Knowledge-not-files, Minimalism) + domains + acceleration. Points to detailed docs.
- **Priority 2+3 — Agent Layer + Supervisor orchestration:** `templates/agents/` — reusable,
  provider-agnostic **role library** (supervisor, knowledge, reference, analysis, figure, writing,
  validation) + `orchestration.md` sequencing roles over `project-run` stages; multi-domain
  (Research>Business>Investment>Surplus, same orchestration). **Model ≠ Role**; agents orchestrate,
  framework executes. Materializes PLATFORM_REUSE_POLICY §8 (shared agent logic in platform layer).
- **Priority 4 — Knowledge Transfer:** already delivered project-independent in M4-4
  (`templates/knowledge_transfer/` + `kt-init`); referenced by the Knowledge Agent. No rework.
- **Hardware policy:** RESOURCE_POLICY §6a — GPU-first, CPU parallelism when appropriate, MPI only
  when justified, **aria2** preferred for large downloads (low-risk CLI; SHA256-verify).
- **FREEZE:** `PLATFORM_VERSION.md` — frozen component manifest (constitution/governance set, CLI,
  frameworks, runtime, capability versions @ freeze, deferred list) + **git tag `platform-v1.0`**.
  Freeze policy: future changes are v1.1+, not in-place edits during active projects.
- **Prompt archived:** `prompts/20260702-02_m4-final-sprint_platform_v1.0.md`.

**Platform v1.0 is frozen. Research projects (P0001/P0002/P0003) may now begin.**

## M5-1 — Research Knowledge Acquisition Framework ✅ COMPLETE (2026-07-02, 20260702-03) [platform v1.1]

**Summary:** First platform-utilization milestone on frozen v1.0. Established the reusable,
project-independent **Research Knowledge Acquisition Framework** by **evolving the M4-4 Knowledge
Transfer framework** (Reuse-First; one framework, no duplication) into the definitive `knowledge/`
standard. Recorded as **v1.1** (freeze-compliant: `platform-v1.0` tag unchanged; main → v1.1). Not
P0003-specific — P0001/P0002/P0003 will all use it.

- **`templates/knowledge/`** (was `knowledge_transfer/`): `README` + `01_project_overview` …
  `08_reconstruction_plan` + `attachments/`. Changes vs M4-4: `05_claude_summary`+`06_chatgpt_summary`
  → **`05_ai_knowledge`** (knowledge **by origin**: Claude/ChatGPT/other) + **new `06_literature`**
  (papers/concepts/landmark methods/future directions — summary, not duplicated bibliography);
  `04_refactoring_summary` → `04_refactoring`; trial-and-error now **attempt→problem→reason→solution
  →final decision**; `Attachments/` → `attachments/`. Anti-fabrication + source-citation rules kept.
- **Integration (no duplication):** `project-bootstrap kt-init` scaffolds `knowledge/`;
  PROJECT_LIFECYCLE §4a → `docs/knowledge/`; package **feeds** PROJECT_MASTER / TODO /
  ENVIRONMENT_MANIFEST generation; never an execution input (`project-run` reads only canonical
  files). Agent specs (knowledge/README/orchestration) updated.
- **Future workflow:** Legacy Research → Knowledge Acquisition → PROJECT_MASTER → Capability
  Resolution → Execution → Validation → Figures → Publication.
- **Validated** (temp): kt-init produces the 10-file `knowledge/` package; Reason step, 05 by-origin,
  06 literature, token substitution all present; no residual `knowledge_transfer` refs outside
  historical records. No real project created (P0001/P0002/P0003 not acquired).
- **PLATFORM_VERSION.md** v1.1 changelog updated. **Prompt:** `prompts/20260702-03_m5-1_knowledge_acquisition_framework.md`.

## M5-2 — Project Knowledge Lifecycle ✅ COMPLETE (2026-07-02, 20260702-04) [platform v1.2]

**Summary:** Made project knowledge a **continuously evolving asset**. New CLI
**`scripts/project-knowledge`** extends (does not redesign) the M5-1 `knowledge/` framework with the
full lifecycle: Initialize → Ingestion → Classification → Curation → Update → Reuse → Completion.
Deterministic + **provider-agnostic** (no LLM): agents supply distilled reusable knowledge + judgment;
the tool ingests, records provenance, deduplicates, targets the right section, and derives canonical
files. Knowledge is never an execution input — PROJECT_MASTER is the entry point.

- **Commands:** `init` (delegates to `project-bootstrap kt-init`), `ingest --from <PATH>`
  (operator-specified, **source-agnostic** — md/pdf/txt/docx/xlsx/handoffs/chats/notes/scripts/
  figures; copies to `attachments/_inbox/`, sha256, provenance ledger, classification **hint**),
  `classify` (heuristic hint), `add --section NN --source "PROV"` (**incremental**, provenance-
  stamped, **deduplicated** append — never a full rewrite), `provenance`, `status`, `archive`
  (optional), `derive --out` (assemble PROJECT_MASTER/TODO **drafts** from sections — the Reuse stage).
- **No fixed-directory assumption** (source always via `--from`); knowledge **more organized over
  time** (append under a provenance marker); **no duplication** (dedup by content sha; literature
  summarized not duplicated; feeds — not copies — canonical files). Provenance in `PROVENANCE.tsv`.
- **Validated (temp only; no real project):** init → ingest (md + pdf) → classify → add to 03/05 →
  **dedup** (repeat skipped) → **repeated update** (second wave accumulates a 2nd item in 03) →
  status → provenance ledger (6 records) → archive → derive drafts. `/data/analysis/projects` empty.
- **Freeze-compliant platform v1.2** (`platform-v1.0` tag unchanged; PLATFORM_VERSION v1.2 log).
  PROJECT_LIFECYCLE §4a updated. **Prompt:** `prompts/20260702-04_m5-2_project_knowledge_lifecycle.md`.

## Maximum operational state reached

- **gpu-01 control node is operational:** Apptainer 1.5.0; Prometheus 3.11.2 +
  Grafana 10.2.6 + node_exporter 1.11.1 + DCGM 4.5.3 (all localhost-bound);
  NFS server exporting `resources` to peers (root_squash, peer-IP firewall).
- **Toolchain (all nodes via $HOME, user-space):** uv + CPython 3.12.13 +
  Snakemake 9.22.0 + Nextflow 26.04.3 (JDK 21) — on gpu-01; replicable to peers.
- **Cluster fabric:** passwordless SSH mesh, full inventory (3 homogeneous nodes).

## To reach full multi-node state, the operator must provide

1. **Passwordless sudo on `gpu-02` and `gpu-03`** (currently gpu-01 only) — the
   sole blocker for peer Apptainer/exporters, NFS client mounts, and Slurm
   `slurmd`/munge.
2. **A Slurm package source for el10** (OpenHPC-el10 repo or approval to
   source-build) — independent of sudo.
3. **Open inputs:** is `222.231.57.0/24` dedicated or shared? private VLAN
   available? (gates NFS/Slurm security hardening, not function).
