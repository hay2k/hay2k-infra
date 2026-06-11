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
| **Secrets** | API keys, tokens, PATs, private keys, `.env`, cloud/Zotero credentials | **Yes, but NEVER to the git remote** — age-encrypted to peer disks (SECRETS_POLICY.md §6) |
| **Regenerable** | Model weights re-downloadable from a hub, public datasets, build caches, intermediate artifacts, anything with a recorded SHA256 + source URL | **No** (recorded source is the "backup") |

The distinction is enforced by storage layout: regenerable bulk lives in
`resources/` with recorded provenance (GOVERNANCE.md §6); precious data is
small and version-controlled or explicitly flagged for backup; **secrets live
outside the repo entirely** (`~/.secrets/`, SECRETS_POLICY.md §3) and are
backed up only encrypted (age) to peer disks — never in any git history.

## 3. Backup policy — APPROVED: 3-node on-cluster replication (2026-06-02)

The approved strategy is **3-copy replication across the cluster's independent
node disks**. Off-site/off-IDC backup is **explicitly out of scope** — a
deliberate operator decision (the whole-site-loss risk is **accepted**, see §6).

- **3 copies of precious data on independent disks:** primary on `gpu-01`
  (`/srv/nfs/resources`) + mirrors on `gpu-02` and `gpu-03` (`/srv/backup/
  resources`), via the daily `cluster-backup.timer`.
- **Precious code/docs/prompts:** also on the **GitHub remote** (this happens to
  be off-host, the one off-host copy that exists — for the small governance tier
  only).
- **Secrets:** age-encrypted, replicated to peer disks (SECRETS_POLICY.md §6).
- Every data backup carries a **SHA256 manifest** (sibling of the mirror) so
  restores are verifiable (GOVERNANCE.md §6).
- Backups are **tested by restore** (`infra/scripts/cluster-restore.sh`) — an
  untested backup is not a backup.
- **`analysis/` scope (20260605-03):** the research domain has specific
  include/exclude rules — traverse `/srv/nfs/analysis` once (skip the gpu-01 bind
  view), exclude any dir carrying a `.regenerable` marker (SIFs, installed pipeline
  payloads, reference data, caches), include project source/results + manifests; each
  project is its own git repo with a GitHub remote. See **ANALYSIS_ARCHITECTURE.md
  §7.2**. (Applied to `cluster-backup.sh` when `analysis/` is deployed at M2-1.)

## 4. Recovery procedure

**Single-node loss (e.g. `gpu-01` disk fails) — the case the approved strategy
covers:**
1. Provision/replace the node; record OS/driver/CUDA versions.
2. Restore the infrastructure repo `/home/hha/infra/` from the **GitHub remote**.
   - Reinstall git hooks (not version-controlled by git):
     `cp hooks/pre-commit .git/hooks/pre-commit && chmod +x .git/hooks/pre-commit`.
3. Restore bulk precious data from a **peer mirror**:
   `infra/scripts/cluster-restore.sh data gpu-02` (manifest-verified).
4. Secrets: if `gpu-01` survived, `cluster-restore.sh secrets gpu-02`; if
   `gpu-01` was lost (age identity gone), **regenerate** secrets — all are
   regenerable (SECRETS_POLICY.md §6).
5. Verify against SHA256 manifests; any mismatch is a hard stop.
6. Re-acquire regenerable assets from recorded sources into `resources/`,
   verifying each hash; recreate environments from committed lockfiles
   (GOVERNANCE.md §4); reproduce a known result as the acceptance test.

**Whole-site/IDC loss (all three nodes): NOT recoverable beyond the GitHub
governance repo — accepted risk (§3, §6).**

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

### Accepted risks & scope (operator decision 2026-06-02)

- **Off-site/off-IDC backup is OUT OF SCOPE — accepted risk.** The three nodes
  share one IDC/segment, so the approved strategy protects against **single-disk
  and single-node loss** but **not whole-site/IDC loss** (fire, theft, site
  outage, simultaneous multi-node loss). This is a deliberate, accepted decision;
  it is **not** a pending gap.
- **Secrets recoverability scope:** the age identity
  (`~/.secrets/age/identity.txt`) lives on `gpu-01` only. The secrets backup
  therefore covers **accidental deletion while `gpu-01` is alive** (restore +
  decrypt works). On **total `gpu-01` loss**, old secrets backups are not
  decryptable — accepted, because **all current secrets are regenerable**
  (Grafana admin pw resettable; SSH keys regenerable + re-authorizable). Recovery
  path on `gpu-01` loss = **regenerate**, not restore.
- **Push model** (`gpu-01` → peers) and **no RAID** — accepted at this scale;
  redundancy is via cross-node copies. A pull model is a possible future hardening.

With this approved on-cluster backup + tested restore, **precious data may be
stored on NFS** within the accepted whole-site-loss risk above.
