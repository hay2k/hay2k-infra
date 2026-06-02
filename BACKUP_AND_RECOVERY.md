# BACKUP AND RECOVERY

**Status:** Policy active from 2026-06-01. **Mechanism not yet implemented** —
there is no backup target on this host (see §6, a top risk).
**Scope:** What to protect, how to restore, and how to migrate to a future
server.

---

## 1. Threat model

- **Per-node non-redundant ~1.8 TB disks (×3), not pooled.** A node's disk
  failure loses that node's local data. This is the dominant risk.
- **Node loss.** Losing a node loses its local data until a backup exists
  elsewhere; losing the **control node** (`gpu-01`) also halts orchestration
  until failover to `gpu-02` (NODE_ARCHITECTURE.md §4).
- No shared storage yet — data is currently per-node (RESOURCE_POLICY.md §4).
- Accidental deletion (mitigated by version control + the §2 approval gates).
- Silent corruption (mitigated by SHA256 manifests, GOVERNANCE.md §6).

## 2. What is precious vs. regenerable

Back up what cannot be regenerated; do not back up what can.

| Tier | Examples | Backed up? |
|------|----------|-----------|
| **Precious** | Governance docs (`infra/`), prompt archive, source code, configs, citation library (Zotero DB / `.bib`), unique experimental raw data, results that are expensive to recompute | **Yes** |
| **Secrets** | API keys, tokens, PATs, private keys, `.env`, cloud/Zotero credentials | **Yes, but NEVER to the git remote** — encrypted off-host channel only (SECRETS_POLICY.md §5–§6) |
| **Regenerable** | Model weights re-downloadable from a hub, public datasets, build caches, intermediate artifacts, anything with a recorded SHA256 + source URL | **No** (recorded source is the "backup") |

The distinction is enforced by storage layout: regenerable bulk lives in
`resources/` with recorded provenance (GOVERNANCE.md §6); precious data is
small and version-controlled or explicitly flagged for backup; **secrets live
outside the repo entirely** (`~/.secrets/`, SECRETS_POLICY.md §3) and are
backed up only encrypted and off-host — they are never in any git history.

## 3. Backup policy (3-2-1, scaled to one host)

- **3** copies of precious data, **2** media/locations, **1** off-host.
- Precious code/docs/prompts: primary copy is a **version-control remote**
  (off-host) — this satisfies the off-host requirement for the most critical,
  smallest data.
- Bulk precious data (raw experimental data, expensive results): periodic
  snapshot to an **off-host destination** (TBD — §6).
- Every backup set carries a **SHA256 manifest** so restores are verifiable
  (GOVERNANCE.md §6).
- Backups are **tested by restore**, not assumed. An untested backup is not a
  backup.

## 4. Recovery procedure (target shape, once mechanism exists)

1. Provision a clean host; record its OS/driver/CUDA versions.
2. Restore the infrastructure repo `/home/hha/infra/` from the git remote, then
   restore any bulk precious data from its off-host copy.
   - Reinstall git hooks (not version-controlled by git):
     `cp hooks/pre-commit .git/hooks/pre-commit && chmod +x .git/hooks/pre-commit`
     (SECRETS_POLICY.md §8).
   - Restore secrets from the encrypted off-host channel into `~/.secrets/`
     (perms 700/600) — never from git (SECRETS_POLICY.md §6).
3. Verify against SHA256 manifests; any mismatch is a hard stop.
4. Re-acquire regenerable assets from recorded sources into `resources/`,
   verifying each hash.
5. Recreate environments from committed lockfiles (GOVERNANCE.md §4).
6. Reproduce a known result end-to-end as the acceptance test for recovery.

## 5. Future server migration (required capability)

The design supports migration to a future/bigger server by construction:

- **Versioned core.** The infrastructure core is the git repo at
  `/home/hha/infra` — migration of governance + prompts is a `git clone` from
  the remote, independent of bulk domain data. Work domains migrate via their
  own version control plus re-fetch of regenerable bulk.
- **No host-specific absolute paths** baked into projects; reference the
  workspace root via a single configured variable, not hard-coded `/home/hha`
  scattered through code.
- **Provenance over payload.** Because regenerable bulk is referenced by source
  + hash rather than treated as precious, migration moves a *small* precious
  set and re-fetches the rest — fast and verifiable.
- **Environments are declarative** (lockfiles), so they rebuild on new
  hardware; only recorded hardware assumptions (GPU count/VRAM) may need
  revisiting.

Migration is a **cross-host move of the whole workspace** and is a User-level
event (it is structural and high-impact).

## 6. Backup status (implemented 2026-06-02)

- **Governance/code tier — off-host ✅:** GitHub private repo
  `hay2k/hay2k-infra`, pushed continuously since 2026-06-01.
- **Bulk precious data (NFS `resources`) — on-cluster 3-copy ✅:** a daily
  `systemd` timer (`cluster-backup.timer`) runs `infra/scripts/cluster-backup.sh`
  on `gpu-01`, mirroring `/srv/nfs/resources` to **independent disks on `gpu-02`
  and `gpu-03`** (`/srv/backup/resources`) with a **SHA256 manifest** (kept as a
  sibling, never inside the mirror). **Restore tested** (`cluster-restore.sh
  data`) — manifest-verified, no pollution.
- **Secrets — encrypted off-node ✅:** `~/.secrets` + the SSH private keys are
  tar'd (excluding the age identity) and **age-encrypted** to the cluster
  recipient, copied to `gpu-02`/`gpu-03` `/srv/backup/secrets` (rotation: 7).
  **Restore tested** (`cluster-restore.sh secrets`) — decrypts and matches.
- **Regenerable data** (re-downloadable models, caches) — not backed up; recorded
  by source + SHA256 (GOVERNANCE.md §6).

### Remaining gaps (honest)

- **NOT off-SITE.** The three nodes are one IDC/segment, so this protects against
  **single-disk and single-node loss (R1/R2)** but **not whole-site loss.** A
  true off-site/off-IDC target (cloud object store, remote host) still needs an
  external destination + credentials — an open operator decision.
- **age identity is the root of trust:** `~/.secrets/age/identity.txt` decrypts
  the secrets backups. The operator **must keep a copy OFF-SITE** — if the whole
  cluster is lost, the on-cluster identity is lost with it. (Mitigated by most
  secrets being regenerable.)
- **Push model:** backups push from `gpu-01`; a compromised `gpu-01` could affect
  them. A pull model (peers pull) is a future hardening.
- **No RAID** on the per-node disks (redundancy is via cross-node copies).

With on-cluster backup + tested restore in place, **regenerable and
reproducible data may be stored on NFS now**; sole-copy irreplaceable data
should still wait for the **off-site** tier.
