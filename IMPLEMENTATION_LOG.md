# IMPLEMENTATION LOG

**Started:** 2026-06-02 (20260601-15, implementation mode)
**Operator context:** `hha` on `gpu-01`. **No passwordless sudo on any node**
(root ops blocked). **Peer SSH: resolved 2026-06-02** — passwordless `gpu-01` →
`gpu-02`/`gpu-03` via `cluster_ed25519`. Outbound HTTPS works. All work below is
**user-space, reversible**; nothing required root.

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

**Summary:** Apptainer install requires root (system package) and is a
**high-risk §2.3** component. No passwordless sudo → stop condition #5
(credentials unavailable). Not attempted.

**Rollback:** n/a (nothing done).

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

## Phase D — Node Exporter / DCGM Exporter / Prometheus / Grafana ⛔ BLOCKED

**Summary:** The monitoring stack is **high-risk §2.3** and deploying it as
persistent services requires root (systemd, DCGM library, privileged ports).
No passwordless sudo → #5. Cross-node scraping also needs peer access (blocked).
GPU context confirmed for future DCGM (`nvidia-smi` OK, driver 610.43.02).
Not attempted. (Phase 0 zero-install baseline per OBSERVABILITY.md remains the
fallback.)

**Rollback:** n/a.

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

## Phase F — NFS deployment ⛔ BLOCKED

**Summary:** Requires root (install `nfs-utils`, configure exports, mount) and
peer access; **high-risk §2.3**; and over the public `/24` it is security-gated
(host-firewall to peer IPs + confirmation the subnet isn't shared). Multiple
blockers (#5). Not attempted.

**Rollback:** n/a.

## Phase G — Slurm deployment ⛔ BLOCKED

**Summary:** Requires root, peer access, a munge shared key, consistent name
resolution, and ideally shared storage (NFS, itself blocked); **high-risk §2.3**.
Not attempted.

**Rollback:** n/a.

---

## Blocker report (consolidated, updated 2026-06-02)

**Resolved since the first run:** Phase E (peer SSH trust + inventory) ✅;
Phase C Nextflow ✅ (user-space JDK). Peer NIC speeds confirmed (all 1 GbE).

| Phase / item | Blocker | Stop condition | What unblocks it |
|--------------|---------|----------------|------------------|
| B Apptainer | needs root; high-risk §2.3 | #5 | privileged install (sudo/operator) + approval |
| D Monitoring stack | needs root (services); DCGM needs root; public-IP exposure w/o firewall control; high-risk | #5 | root + approval + firewall/internal-net |
| F NFS | root on all nodes + security gate; high-risk | #5 | root + private-net/firewall decision + approval |
| G Slurm | root on all nodes + munge + name resolution + shared storage; high-risk | #5 | NFS first + root + approval |

**Single remaining root cause:** **no passwordless sudo on any node** — every
system-level install/service (B, D, F, G) is blocked (stop condition #5). The
peer-SSH gap is now resolved. No destructive action, data loss, config
replacement, or architectural conflict was encountered at any point.

> **Note on Phase D:** the stack could *technically* run as user-space processes,
> but (a) DCGM-exporter needs a root-installed library, and (b) Prometheus/
> Grafana on a public-IP host with no internal interface and no firewall control
> would be publicly exposed — a SECURITY_AND_HARDENING_POLICY.md §11 violation.
> A user-space hack is therefore **not "consistent with approved architecture"**,
> so Phase D is held for a proper root-privileged, firewalled deployment.

## Maximum operational state reached (without further interaction)

- **uv** (verified) + **managed CPython 3.12.13** + validated venv/lock path.
- **Snakemake 9.22.0** and **Nextflow 26.04.3** (+ verified **JDK 21.0.11**),
  both validated.
- **Cluster SSH trust established** (passwordless `gpu-01` → `gpu-02`/`gpu-03`,
  aliases configured); **full cluster inventory complete** (3 homogeneous nodes).
- Remaining phases (B, D, F, G) await **privileged (root) access** on the nodes.

## To proceed further, the operator must provide

1. **A privileged-install path** — passwordless sudo for scoped commands, or run
   the documented installs directly. This is now the **sole** blocker for
   Apptainer, the monitoring stack, NFS, and Slurm.
2. Plus the open inputs: is `222.231.57.0/24` **dedicated or shared**? Is a
   **private switch/VLAN** available (to move cluster traffic off the public
   1 GbE subnet)?
