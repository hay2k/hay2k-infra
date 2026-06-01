# BACKUP AND RECOVERY

**Status:** Policy active from 2026-06-01. **Mechanism not yet implemented** —
there is no backup target on this host (see §6, a top risk).
**Scope:** What to protect, how to restore, and how to migrate to a future
server.

---

## 1. Threat model

- **Single non-redundant 1.8 TB disk.** Disk failure loses everything. This is
  the dominant risk.
- **Single host.** Host loss = total loss until a backup exists elsewhere.
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

## 6. Current gaps (must be closed in the next implementation phase)

- **Off-host destination — DECIDED 2026-06-01:** a **GitHub remote** under
  account `https://github.com/hay2k` is the off-host home for the
  precious-but-small tier. The version-controlled root is the git repo at
  `/home/hha/infra`. Bulk precious-data backup remains TBD.
  **Tooling:** `git` is a **pre-approved prerequisite** (GOVERNANCE.md §2.1) —
  no special approval. `gh` is **not** installed (operator deferred it).
  **Status:** repo initialized locally with a first commit; the **private
  remote is not yet created and no push has occurred** — pending a repo URL
  from the operator. Until the first push, this host still has *zero* off-host
  recovery.
- **No snapshot mechanism** for bulk precious data.
- **No restore test** has been performed (none can be, yet).

Until §6 is closed, treat all data on this host as **at risk**, and weight the
GOVERNANCE.md §2 deletion-approval gate accordingly.
