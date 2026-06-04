# CLUSTER SSH CONSISTENCY AUDIT

**Date:** 2026-06-02. **Read-only audit — no configuration changed.**
Purpose: verify the SSH topology before any H1/H2 hardening. **Conclusion: H1
(disabling `PasswordAuthentication`) MUST NOT proceed until remediation — there
is currently no working key-login path into `gpu-01`, and password auth is the
de-facto access method on all nodes.**

---

## 1. Per-node facts

| Fact | gpu-01 | gpu-02 | gpu-03 |
|------|--------|--------|--------|
| Resolves cluster names (gpu-0x) | only self | only self | only self |
| `/etc/hosts` cluster entries | none | none | none |
| `~/.ssh/config` aliases | `gpu-02`,`gpu-03` (HostName=IP, cluster key) | none | none |
| `cluster_ed25519` **private** key | PRESENT | absent | absent |
| `~/.ssh/authorized_keys` | **DOES NOT EXIST** | cluster key only | cluster key only |
| `PasswordAuthentication` (sshd -T) | **yes** | **yes** | **yes** |

- Cluster key fingerprint authorized on peers: `SHA256:bgQB…o0M`
  (`hha-cluster-gpu01`).
- No node resolves another by name (only its own hostname → link-local IPv6 via
  `nss-myhostname`). `gpu-01` reaches peers **only** via `~/.ssh/config` aliases.

## 2. Directed connectivity matrix

| Path | Result | Mechanism |
|------|--------|-----------|
| gpu-01 → gpu-02 (alias) | ✅ WORKS | alias pins `cluster_ed25519` (IdentitiesOnly) |
| gpu-01 → gpu-03 (alias) | ✅ WORKS | same |
| gpu-01 → peer **by raw IP** | ❌ FAIL | cluster key offered **only** via the alias; agentless/raw-IP connections don't present it |
| gpu-02 → gpu-01 | ❌ FAIL | gpu-02 has no private key, no alias |
| gpu-02 → gpu-03 | ❌ FAIL | same |
| gpu-03 → gpu-01 | ❌ FAIL | same |
| gpu-03 → gpu-02 | ❌ FAIL | same |
| **any → gpu-01 by key (inbound)** | ❌ IMPOSSIBLE | `gpu-01` has **no `authorized_keys`** |

## 3. Working paths
- **`gpu-01 → gpu-02` and `gpu-01 → gpu-03`** via the SSH aliases (cluster key).
  This is the control-node automation path (backup push, monitoring scrape SSH,
  admin) — and it is sufficient for the current architecture.

## 4. Failing / missing paths + root cause
- **Inbound key login to `gpu-01`: none** — `~/.ssh/authorized_keys` does not
  exist. **Root cause:** no operator/client public key was ever deployed to
  `gpu-01`; access today is **password-based** (`PasswordAuthentication yes`) or
  console.
- **All peer-initiated SSH fails** (gpu-02/gpu-03 → anything). **Root cause:**
  the `cluster_ed25519` **private** key lives only on `gpu-01`; peers hold no
  private key and no alias. *(This is acceptable by the control-node design —
  peers are not required to initiate; see §6.)*
- **`gpu-01 → peer` works only via the alias.** **Root cause:** `cluster_ed25519`
  is a non-default key offered only because the alias sets `IdentityFile` +
  `IdentitiesOnly`; raw-IP or other tooling that bypasses `~/.ssh/config` won't
  authenticate.
- **No cluster name resolution anywhere.** **Root cause:** no `/etc/hosts`
  entries and no DNS for `gpu-0x`; only `gpu-01`'s ssh aliases mask it.
- **`authorized_keys` inconsistent:** `gpu-01` = none; peers = cluster key only;
  **the operator's own client key is on no node.**

## 5. Impact on H1 (why hardening must wait)
H1 sets `PasswordAuthentication no`. Today the **only** working inbound auth is
**password** (gpu-01 has no authorized key; peers accept only the cluster key
*from gpu-01*). Applying H1 as-is would:
- **Lock the operator out of `gpu-01`** (no key, no password) — the control node
  and the only cluster-SSH origin; recoverable only via console/IPMI.
- Leave peers reachable **only by hopping through `gpu-01`** — and if gpu-01 is
  itself locked, the whole cluster is console-only.

The ratified "key-auth is the standard" decision is the **target**; it is **not
yet realized in configuration.** Remediation (§6) closes that gap first.

## 6. Remediation plan (no changes made — plan only)

**Prereq (operator input required):** provide the **operator workstation public
key** to install — I cannot fabricate the operator's client key. (Alternatively
confirm an existing key you use to reach the nodes.)

Ordered steps, each verified before the next; nothing applied until approved:

1. **Deploy the operator public key → `authorized_keys` on ALL nodes**
   (`gpu-01`, `gpu-02`, `gpu-03`; file `600`, owner `hha`). This is the **hard
   prerequisite for H1.**
2. **VERIFY key login from the operator's real client** to all three nodes
   (`ssh hha@<node>` succeeds with the key, no password) **before** any sshd
   change. Keep a console/IPMI break-glass confirmed.
3. **Add cluster name resolution:** `/etc/hosts` entries `gpu-01/02/03 → IPs` on
   all nodes (removes reliance on ssh aliases; needed for Slurm/NFS-by-name).
4. **Keep the control-node SSH model (intentional asymmetry):** `gpu-01` →
   peers is the required path and works; peer→peer / peer→`gpu-01` SSH are **not
   required** by the architecture (Slurm uses munge, NFS needs no SSH, backups
   push from gpu-01). Document this as deliberate; only add peer-initiated keys
   later if a pull-backup or peer-autonomy need arises.
5. **(Optional) robustness:** ensure ops tooling uses the alias (it does), or add
   the cluster key to `ssh-agent`, so `gpu-01→peer` isn't alias-fragile.
6. **Only after 1–3 verify green → proceed to H1** (per HARDENING_IMPACT_REVIEW
   §7), peers first, gpu-01 last, reversible drop-ins, reconnect-tested.

## 7. Verdict
- **Topology is consistent enough for current automation** (gpu-01→peers works).
- ~~It is NOT consistent enough for H1.~~ **RESOLVED:** the operator key was
  installed on all nodes (migration Phase 2, 2026-06-02), removing the lockout
  risk; **H1 (disable password auth) was applied and verified 2026-06-04**
  (INFRA_CHANGELOG; SSH_KEY_MIGRATION_PLAN Phase 5). H2 (firewall) still pending.
This audit changed nothing.
