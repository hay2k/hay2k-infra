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

## Blocker report (consolidated, updated 2026-06-02 — sudo on gpu-01)

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
