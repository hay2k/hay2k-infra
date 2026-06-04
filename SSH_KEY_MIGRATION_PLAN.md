# SSH KEY MIGRATION PLAN — password → ED25519

**Date:** 2026-06-02. **Plan only — no changes made.** Migrates operator access
on `gpu-01`/`gpu-02`/`gpu-03` from password auth to **ED25519 key auth**, then
disables password auth (H1). Built on CLUSTER_SSH_AUDIT.md (which found: no
operator key anywhere, `gpu-01` has no `authorized_keys`, `PasswordAuthentication
yes` on all nodes). Client = **MobaXterm** (Windows).

**Cardinal safety rule:** *password auth stays ENABLED until key login is
verified on ALL three nodes from the real MobaXterm client.* Never disable
password and apply hardening in the same step.

---

## Key design

A **new, dedicated operator workstation key** — distinct from the two existing
keys (do **not** reuse them):

| Key | Private location | Purpose |
|-----|------------------|---------|
| **`hha_ed25519` (NEW)** | operator's **workstation only** | operator interactive login to all nodes |
| `cluster_ed25519` | `gpu-01` only | gpu-01 → peer automation (backup/monitoring) — unchanged |
| `hay2k-infra_ed25519` | `gpu-01` | GitHub deploy — unchanged |

The new private key **never leaves the workstation** and is **passphrase-
protected**.

**Target `authorized_keys` state:** operator key on **all 3 nodes**; peers also
keep `cluster_ed25519` (for gpu-01 automation). gpu-01 gets an `authorized_keys`
(currently has none).

---

## Phase 0 — Pre-flight (no risk)
- [ ] Confirm **out-of-band/console** access to all 3 nodes (provider console /
      IPMI / VNC) — the recovery path if SSH ever breaks. Root break-glass
      password is already set (H0).
- [ ] Keep an existing authenticated session open throughout.

## Phase 1 — Generate the keypair on the workstation (operator, MobaXterm)
Choose one:
- **A. MobaKeyGen (GUI):** MobaXterm → *Tools → MobaKeyGen* → Key type **ED25519**
  → *Generate* (move mouse) → set a **passphrase** → *Save private key*
  (e.g. `hha_ed25519.ppk`) → copy the **OpenSSH public key** shown in the box
  (one line: `ssh-ed25519 AAAA… hha@workstation`).
- **B. Terminal:** in MobaXterm local shell:
  `ssh-keygen -t ed25519 -a 100 -C "hha@workstation" -f ~/.ssh/hha_ed25519`
  (set a passphrase). Public key = `~/.ssh/hha_ed25519.pub`.
- [ ] **Provide the PUBLIC key** (the `ssh-ed25519 …` line) for installation, or
      install it yourself in Phase 2. **Never share the private key.**

## Phase 2 — Install the public key on all nodes (ADDITIVE; password still on)  ✅ DONE 2026-06-02
Password auth remains on, so there is **no lockout risk** here. Two options:

- **Option A — operator self-service:** from MobaXterm, for each node:
  `ssh-copy-id -i ~/.ssh/hha_ed25519.pub hha@222.231.57.30` (then `.31`, `.32`)
  — prompts for the **password** (still enabled). Done.
- **Option B — I deploy it** (once you paste the public key): I append it to
  `~/.ssh/authorized_keys` on `gpu-01` and push to peers over the existing
  `gpu-01→peer` automation path, with correct perms/SELinux context:
  ```
  install -d -m700 ~/.ssh
  printf '%s\n' "<PUBKEY>" >> ~/.ssh/authorized_keys
  chmod 600 ~/.ssh/authorized_keys && restorecon -R ~/.ssh
  # peers: same via  ssh gpu-02 / ssh gpu-03
  ```
- [ ] Verify each node's `authorized_keys`: `600`, owner `hha`, contains the new
      key (`ssh-keygen -lf`), correct SELinux label.

## Phase 3 — Point MobaXterm at the key (operator)
For each saved session (gpu-01/02/03):
- [ ] Session → *SSH* → *Advanced SSH settings* → tick **"Use private key"** →
      select `hha_ed25519.ppk` (or the OpenSSH key). Username `hha`.
- [ ] (Optional) load the key once into MobaAgent so the passphrase is cached.

## Phase 4 — VERIFY key login (HARD GATE — password still enabled)
- [ ] From MobaXterm, connect to **each** node and confirm login uses the **key**
      (you're prompted for the *key passphrase*, not the account password).
- [ ] Independently confirm all 3 nodes.
- [ ] Confirm automation still works: `gpu-01 → gpu-02/03` (cluster key),
      backup timer, Prometheus targets.
- [ ] **Do not proceed until all three nodes log in by key.** If any fails,
      fix authorized_keys/perms (password still works as fallback).

## Phase 5 — Disable password auth = H1  ✅ DONE 2026-06-04
**Applied** on all 3 nodes (peers first, gpu-01 last) — see INFRA_CHANGELOG
2026-06-04. **Deviation:** drop-in named **`00-hardening.conf`** (not `10-`) so
it sorts **before** `01-permitrootlogin.conf` and wins on `PermitRootLogin`
(first-match) — `10-` would have left root login enabled. **`AllowUsers hha`
deferred** (operator scoped H1 to password-disable). Verified: key login OK,
password + root refused, gpu-01→peer automation intact.

Original plan (per node, **peers first, `gpu-01` LAST**, second session held open):
- [ ] Write reversible drop-in `/etc/ssh/sshd_config.d/10-hardening.conf`:
      `PasswordAuthentication no`, `KbdInteractiveAuthentication no`,
      `PermitRootLogin no`, `AllowUsers hha`.
- [ ] `sudo sshd -t` (abort on error) → `sudo systemctl reload sshd`.
- [ ] From a **new** MobaXterm connection: key login works ✅; password login is
      **refused** ✅. Then move to the next node; gpu-01 last.
- [ ] **Rollback (instant):** `sudo rm /etc/ssh/sshd_config.d/10-hardening.conf
      && sudo systemctl reload sshd` from the held session.

## Phase 6 — Post-migration
- [ ] Add `/etc/hosts` cluster entries (gpu-01/02/03 → IPs) on all nodes
      (CLUSTER_SSH_AUDIT §6.3 — name resolution for ops/Slurm/NFS).
- [ ] Record the operator key as a managed credential (public half in
      authorized_keys; **private half on workstation only** — note it in
      SECRETS_POLICY scope; it is NOT stored on the cluster).
- [ ] Document in IMPLEMENTATION_LOG.md + INFRA_CHANGELOG.md.
- [ ] Re-run a backup + multi-node smoke test to confirm no regression.

## Rollback summary
- Phase 2–4 are additive — nothing to roll back (password still works).
- Phase 5 rollback = delete the sshd drop-in + reload (per node). Because each
  node is verified from a fresh connection before the next, and gpu-01 is last,
  worst case is a single-node reload reverted from the held session or console.

## What I need from you to start
1. The **operator workstation ED25519 public key** (Phase 1 output) — or your
   confirmation to use `ssh-copy-id` yourself.
2. Confirmation that **console/IPMI break-glass** to the nodes exists (Phase 0).

With those, Phases 2–4 are zero-risk (password stays on); H1 (Phase 5) proceeds
only after key login is verified on all three nodes. **This plan changes
nothing until you approve each phase.**
