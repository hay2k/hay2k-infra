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
