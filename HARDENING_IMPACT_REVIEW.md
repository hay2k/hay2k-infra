# HARDENING IMPACT REVIEW

**Date:** 2026-06-02. **Review only — no system change, no config edit.**
Pre-implementation impact analysis of every **mandatory [M]** control in
SECURITY_AND_HARDENING_POLICY.md, against the live cluster.

**Current security-relevant state (measured):** SSH on `0.0.0.0:22` (all nodes);
monitoring bound `127.0.0.1` (3000/9090/9100/5555); firewalld public zone =
`ssh, cockpit, dhcpv6-client` + NFS rich-rules per peer IP; SELinux **Enforcing**;
sshd `PasswordAuthentication`/`PermitRootLogin` at distro default (not pinned);
key path `gpu-01 → peers` via `cluster_ed25519`; **`hha` has passwordless sudo on
all nodes** (operationally required by the agent runtime).

Classification key: **SAFE** (apply, no operational impact) · **SAFE_WITH_
MODIFICATION** (apply only with a pre-check/adjustment) · **HIGH_RISK** (real
chance of outage/lockout; stage carefully) · **NOT_RECOMMENDED** (conflicts with
the approved operating model as written).

---

## 1. Controls already satisfied — SAFE (verify only, no change)

| Control (§) | Status |
|---|---|
| SELinux enforcing (§2) | ✅ already Enforcing |
| ed25519 keys / verified known_hosts (§2) | ✅ in use |
| Service identities non-login (§2) | ✅ `node_exporter` nologin; prometheus/grafana packaged users |
| No public service exposure — monitoring (§3) | ✅ localhost-bound |
| NFS NFSv4 + root_squash + peer-only export (§3/§4) | ✅ in place |
| Ownership / no world-writable; secrets `700`/`600` off-repo (§4/§5) | ✅ verified |
| Secrets never unencrypted off-node; encrypted backup + tested restore (§5/§9) | ✅ age + peers |
| Dedicated least-scope keys, no PAT, never in repo (hook) (§5) | ✅ |
| Packages gpgcheck; third-party repo = NVIDIA (GPG) (§6) | ✅ |
| Supply-chain/reproducibility/agent-governance/logging-to-journald (§6/§7/§8) | ✅ process controls already followed |
| GitHub repo private; restore validation; least-priv backup creds (§9) | ✅ |

**None of these require a change.** No impact on any of the 10 dimensions.

## 2. Controls requiring action — per-control impact + classification

| # | Control (§) | Class | SSH | NFS | Prom | Graf | Backup | Appt | Snake | Nextf | Slurm(fut) | Agents | Required modification / pre-check |
|---|-------------|-------|-----|-----|------|------|--------|------|-------|-------|------------|--------|-----------------------------------|
| C1 | **SSH `PasswordAuthentication no`** (§2) | **HIGH_RISK** | **lockout risk** | – | – | – | uses key (ok) | – | – | – | ok (munge) | ok | **PRE-CHECK: confirm `hha` has a working key login on *all 3 nodes* AND from the operator's remote origin, before disabling.** Otherwise total lockout. |
| C2 | **SSH `PermitRootLogin no`** (§2) | SAFE_WITH_MODIFICATION | removes root-over-SSH | – | – | – | – | – | – | – | ok | ok | Ensure `hha`+sudo works (✅) and console/IPMI break-glass exists for root. |
| C3 | **`AllowUsers hha`** (§2, [R] but review) | SAFE_WITH_MODIFICATION | restricts to hha | – | – | – | – | – | – | – | add slurm later | ok | Include future operators/service users explicitly before enabling. |
| C4 | **Restrict SSH to management network** (§3, [R]) | **NOT_RECOMMENDED** | **operator lockout** | – | – | – | – | – | – | – | – | – | **No management network exists; operator connects over the public `/24`.** Source-restricting SSH to the cluster subnet would lock out external admin. Defer until a mgmt network/VPN exists. |
| C5 | **Firewall default-deny + drop `cockpit`** (§2 svc-min / §3) | SAFE_WITH_MODIFICATION | **must keep `ssh`** | **must keep peer NFS rich-rules + 9100** | localhost (ok) | localhost (ok) | keep gpu-01→peer | – | – | – | add slurm ports later | ok | Apply additively; **never remove `ssh`**; use a timed auto-revert (`--timeout`) when reloading so a mistake self-heals; keep NFS + node_exporter rich-rules. `cockpit` not listening → safe to remove. |
| C6 | **sudo: no broad `NOPASSWD`** (§2) | **NOT_RECOMMENDED (as written)** | – | – | – | – | breaks unattended backup timer | – | – | – | – | **breaks autonomous agent runtime** | **DIRECT CONFLICT:** `hha` passwordless sudo is required by the agent runtime + the systemd backup. Options: (a) accept passwordless sudo for `hha` as a documented exception; (b) scope `NOPASSWD` to an explicit command allowlist. **Needs a policy amendment + User decision** — do not blindly apply. |
| C7 | **Patch cadence: `dnf update`** (§2) | **HIGH_RISK** | – | – | restart | restart | – | – | – | – | – | – | A kernel/glibc update can **break the NVIDIA driver/DCGM** (610.43.02) until rebuilt, and restarts services. Apply **deliberately** (security-only where possible), verify `nvidia-smi`+`dcgmi` after, one node at a time; **never blind auto-update** on GPU nodes. |
| C8 | **Root password = strong break-glass secret** (§2/§5) | SAFE | – | – | – | – | store in ~/.secrets | – | – | – | – | – | Set a strong root pw, store in `~/.secrets` (already backed up). No service impact. |
| C9 | **Strong `hha` password / pwquality** (§2) | SAFE | – | – | – | – | – | – | – | – | – | – | No service impact (SSH is key-based). |
| C10 | **`no_root_squash` never; secrets never on NFS** (§3/§4) | SAFE (verify) | – | ✅ root_squash on | – | – | – | – | – | – | – | – | Confirm no future export uses `no_root_squash`. |
| C11 | **Outbound pragmatic + verified** (§3) | SAFE | – | – | – | – | – | pulls ok | **pulls ok** | **pulls ok** | – | – | Keep egress open + SHA256-verify. **Do NOT** add egress allowlist [O] — would break uv/conda/nextflow/apptainer pulls. |
| C12 | **No secrets in `/tmp`** (§4) | SAFE_WITH_MODIFICATION | – | – | – | – | **fix backup script** | – | – | – | – | – | `cluster-backup.sh` briefly writes an **unencrypted secrets tar to `/tmp`** before age-encrypting. Modify to use a `0700` private dir (or tmpfs) and `umask 077`. Minor, but a real finding. |
| C13 | **Audit logging: sshd + sudo + agent** (§8) | SAFE | logged | – | – | – | – | – | – | – | – | logged | journald already captures sshd/sudo; agent logs per AGENT_RUNTIME. No change needed; auditd is [R]. |

## 3. Cross-cutting findings (must resolve before/while hardening)

- **F1 — SSH lockout is the dominant risk (C1, C4, C5).** All three touch the
  *only* access path to public-IP hosts. **Gating pre-check:** confirm `hha` key
  login works on every node *and* from the operator's real client, keep a
  console/IPMI break-glass, and make every firewall/sshd change self-reverting
  (timed) and applied gpu-01-last. Never apply C1+C4 together blindly.
- **F2 — sudo control vs. agent runtime (C6) is an architectural conflict.** The
  policy's "no broad NOPASSWD" contradicts the passwordless sudo the autonomous
  agents + backup timer depend on. This needs a **GOVERNANCE/SECURITY policy
  amendment + User decision** (accept the exception, or define a scoped
  `NOPASSWD` allowlist). Not a config to silently flip.
- **F3 — kernel updates vs GPU stack (C7).** GPU nodes couple kernel ↔ NVIDIA
  driver ↔ DCGM. Patch deliberately + verify GPUs after; not unattended.
- **F4 — backup script leaks plaintext secrets to `/tmp` (C12).** Real, fixable;
  fold into the hardening change.
- **F5 — policy doc drift:** SECURITY §5 still says secrets backup is "single-copy
  on-host — a known gap" and "off-host"; the ratified strategy (2026-06-02) is
  on-cluster replication with off-site out-of-scope. Update §5 text during
  hardening for consistency (no behavioral change).

## 4. Recommended hardening implementation plan (phased)

**Guardrails for every step:** change one node at a time, gpu-01 LAST; for any
SSH/firewall edit, keep a second root session open and use a **timed auto-revert**
so a mistake self-heals; validate after each step; record + rollback in
IMPLEMENTATION_LOG.md.

**Phase H0 — zero-risk now (SAFE):**
- Verify/confirm the §1 already-satisfied set (document evidence).
- C8 root break-glass password → `~/.secrets`; C9 `hha` password strength.
- C12 fix `cluster-backup.sh` `/tmp` plaintext-secrets handling.
- F5 update SECURITY_AND_HARDENING_POLICY §5 text to match the ratified backup.
- C10 confirm no `no_root_squash`.

**Phase H1 — SSH/root, gated on F1 pre-check (SAFE_WITH_MODIFICATION):**
- Confirm `hha` key login on all nodes + operator's client (PRE-CHECK).
- C2 `PermitRootLogin no`; C3 `AllowUsers hha` (+ known operators).
- C1 `PasswordAuthentication no` — **only after** the pre-check passes, peers
  first, gpu-01 last, with a timed revert.

**Phase H2 — firewall tightening (SAFE_WITH_MODIFICATION):**
- C5 remove `cockpit` from the public zone (and disable its socket — service
  minimization), keep `ssh` + NFS/node_exporter rich-rules; timed revert.

**Phase H3 — needs User decision (do not apply unilaterally):**
- C6 sudo `NOPASSWD` policy — choose: accept passwordless `hha` as a documented
  exception, or define a scoped command allowlist. Amend policy accordingly.
- C7 patch cadence — agree a deliberate, GPU-verified update process (not
  unattended).
- C4 SSH source restriction — defer until a management network/VPN exists.

## 5. Net assessment

- **Safe to apply now (H0):** root/`hha` passwords, backup `/tmp` fix, policy
  text sync, verifications — **no impact** on SSH/NFS/Prometheus/Grafana/backup/
  Apptainer/Snakemake/Nextflow/Slurm/agents.
- **Apply with care (H1/H2):** SSH key-only, no-root-login, AllowUsers, firewall
  cockpit removal — **safe iff** the F1 pre-check holds and changes are
  self-reverting.
- **Needs a decision, don't auto-apply (H3):** sudo NOPASSWD (conflicts with
  agents — F2), blind kernel patching (GPU risk — F3), SSH-to-mgmt-net (no mgmt
  net — would lock out the operator).

**No control here is free to apply blindly that touches SSH, sudo, or the
kernel.** H0 is genuinely safe; H1/H2 are safe only behind the access pre-checks;
H3 must wait for explicit decisions. This review changes nothing.

---

## 6. Decisions & H0 status (2026-06-02)

**Operator decisions:** (1) `hha` uses **SSH key authentication** — key-based
login is the ratified long-term standard. (2) **Passwordless sudo for `hha` is a
documented architectural exception** (kept; no command allowlist now) — see
§2 sudo policy (C6/F2 resolved as accepted).

**H0 — COMPLETE:** C8 root break-glass password set on all 3 nodes + stored
(`~/.secrets/infra/root_breakglass.txt`, in the encrypted backup); **F4** backup/
restore scripts no longer write plaintext secrets to `/tmp` (now a `0700`
`~/.cache` workdir, trap-cleaned, `shred`); **F5** policy text synced to the
ratified on-cluster backup. C9 (`hha` password) **left to the operator** — not
auto-reset (changing a human's own login password autonomously is over-reach).

## 7. H1 / H2 implementation checklist (DO NOT execute until approved)

### Pre-flight (gates BOTH phases)
- [ ] Confirm `hha` **key login works** on gpu-01, gpu-02, gpu-03 **from the
      operator's real client** (`ssh hha@<ip>` succeeds with key, no password).
      **⚠ CLUSTER_SSH_AUDIT (2026-06-02) found this currently FAILS:** `gpu-01`
      has **no `authorized_keys`** and password auth is the de-facto path.
      **Remediation in CLUSTER_SSH_AUDIT §6 (deploy operator key to all nodes +
      verify) is a HARD PREREQUISITE — H1 stays blocked until it is green.**
- [ ] Confirm an **out-of-band/console (IPMI/provider) path** to each node exists
      (break-glass if SSH breaks). Root break-glass pw is set (H0) ✅.
- [ ] Capture current state for rollback: `sshd -T`, `firewall-cmd --list-all`,
      `--list-rich-rules` on each node.
- [ ] **Universal guardrails:** change **peers first, `gpu-01` LAST**; keep a
      **second independent sudo session open** on the node being changed; verify
      from a **new** connection before moving on; **`reload` not `restart`** sshd.

### H1 — SSH/root hardening (per node, gpu-01 last)  ✅ DONE 2026-06-04
*(Applied via drop-in `00-hardening.conf` — `00-` not `10-`, to win first-match
over `01-permitrootlogin.conf`; `PasswordAuthentication no` + `KbdInteractive no`
+ `PermitRootLogin no` + `PubkeyAuthentication yes`; `AllowUsers hha` deferred.
Verified per node; gpu-01→peer automation intact. INFRA_CHANGELOG 2026-06-04.)*
- [ ] Write a drop-in `/etc/ssh/sshd_config.d/10-hardening.conf` (reversible by
      deleting the file): `PermitRootLogin no`, `PasswordAuthentication no`,
      `KbdInteractiveAuthentication no`, `AllowUsers hha`.
- [ ] `sshd -t` (syntax) — **abort on any error.**
- [ ] `systemctl reload sshd` (keeps live sessions).
- [ ] From a **new** connection: key login works ✅; `ssh -o
      PreferredAuthentications=password -o PubkeyAuthentication=no hha@<node>` is
      **refused** ✅; root SSH refused ✅.
- [ ] Verify `gpu-01 → peer` cluster SSH still works (backup/monitoring depend on
      it) before declaring the node done.
- [ ] **Rollback (if anything fails):** `rm /etc/ssh/sshd_config.d/10-hardening.conf
      && systemctl reload sshd` from the held-open session.
- [ ] **Do NOT** add SSH source-restriction (C4) — operator is external, no mgmt
      network → would lock out.

### H2 — firewall tightening (per node, gpu-01 last)
- [ ] Confirm rich-rules to PRESERVE: NFS per-peer (gpu-01), node_exporter
      `:9100` from gpu-01 (peers). Confirm `ssh` service stays.
- [ ] `systemctl disable --now cockpit.socket` (service minimization; not in use).
- [ ] `firewall-cmd --permanent --remove-service=cockpit` then `--reload`
      (keep `ssh`; keep NFS/exporter rich-rules). `dhcpv6-client` removal is
      **optional** (verify no IPv6/DHCPv6 reliance first; low value).
- [ ] For any change with lockout potential, prefer a **runtime change +
      reconnect test** before `--permanent`, so an un-persisted mistake reverts
      on `--reload`.
- [ ] Verify after: SSH reachable from a new connection; Prometheus still shows
      **4 targets up**; peer **NFS mount intact**; `cockpit` gone from the zone.
- [ ] **Rollback:** re-add the service/rich-rule + `--reload` from the held session.

### Post-H1/H2
- [ ] Record actions + validation + rollback in IMPLEMENTATION_LOG.md and
      INFRA_CHANGELOG.md.
- [ ] Re-run a backup + a multi-node smoke test to confirm nothing regressed.

**Update 2026-06-04: H1 has been executed** (operator go-ahead; pre-flight met —
operator key on all nodes since the 2026-06-02 migration). **H2 (firewall) still
awaits explicit go-ahead** and the pre-flight confirmations above.
