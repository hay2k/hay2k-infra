# SECRETS POLICY

**Status:** Active from 2026-06-01 (created by 20260601-04)
**Scope:** How credentials are stored, accessed, backed up, rotated, and kept
out of version control. No secrets exist on this host yet; this policy governs
them from the moment the first one does (the imminent case is the GitHub
credential for the eventual push; later, the Zotero/Better BibTeX API key).

---

## 1. Principles

- A secret never enters version control, a prompt, a log, a figure, or any
  committed file. Reproducibility (GOVERNANCE.md §4) is satisfied by
  *referencing* secrets, never by storing them in the repo.
- **Least privilege.** A secret is scoped to the one domain that needs it
  (GOVERNANCE.md §1). No shared "god" credentials.
- **One home.** Every secret lives in exactly one place on disk (§3).
- **Rotate on exposure.** A secret that may have leaked is treated as
  compromised (§7).

## 2. What counts as a secret

API keys, access tokens, GitHub PATs, OAuth client secrets, passwords,
SSH/private keys, TLS private keys, `.env` files, database connection strings,
cloud credentials, and the Zotero/Better BibTeX API key.

## 3. Storage — file-based, permission-enforced (current model)

Decided 20260601-04: plaintext files protected by filesystem permissions. On a
single-user host this is adequate while secrets remain on-host; it adds no
tooling and matches "current needs over hypothetical" (GOVERNANCE.md §0).

- Secrets live **outside any git repo**, under `~/.secrets/` —
  `chmod 700 ~/.secrets`, `chmod 600` on each file. Per-domain subdirectories:
  `~/.secrets/<domain>/`.
- This path is outside `/home/hha/infra`, so a secret cannot be committed even
  by accident; `.gitignore` additionally blocks `.env`, `*.key`, `*.pem`,
  `*.token`, `*credential*`, `.ssh/`, `.aws/`, etc. as defense in depth.
- Code reads secrets from **environment variables** (loaded at runtime from the
  file), never hard-coded. Naming convention: `<DOMAIN>_<SERVICE>_<PURPOSE>`
  (e.g. `INFRA_GITHUB_TOKEN`).

## 4. Non-secret manifest (may be tracked in the repo)

The repo MAY track a `secrets.manifest.md` listing, for each secret, its
name / env-var, purpose, owning domain, and storage location — but **never the
value** (the `.env.example` pattern). This preserves reproducibility (you know
what is required to run something) without leaking anything.

## 5. Encryption & upgrade trigger

Filesystem permissions protect a single-user, on-host secret adequately.
**Encryption-at-rest becomes REQUIRED before any secret leaves this host** —
i.e. before it is copied into a backup or shared. At that point use `age` or
`sops` (both are low-risk CLI tools, GOVERNANCE.md §2.1). A secrets *service*
(e.g. HashiCorp Vault) is a high-risk component (§2.3) requiring User approval
and is not justified at the current single-host scale.

## 6. Backup of secrets

Secrets are precious but **must never go to the git remote**
(BACKUP_AND_RECOVERY.md). They are backed up only through a **separate,
encrypted, off-host** channel (§5) — a deferred decision tied to the bulk
off-host backup target. Until that exists, the few secrets on this host are
single-copy; keep that surface small.

## 7. Rotation & incident response

- Rotate long-lived tokens on a fixed cadence and **immediately on suspected
  exposure**.
- If a secret is ever committed: (1) revoke/rotate it at the provider first,
  (2) scrub history (`git filter-repo`), (3) record the incident in
  INFRA_CHANGELOG.md. Assume exposure the moment it touched the tree.

## 8. Prevention

- `.gitignore` blocks the common secret file types (verified at bootstrap).
- A **pre-commit secret-scan hook** is provided at `hooks/pre-commit` and
  blocks any commit whose staged content matches a known credential *format*
  (private-key blocks, `AKIA…`, `ghp_…`/`github_pat_…`, `xox…`, `AIza…`,
  `sk-…`, or a quoted long value assigned to a secret-named field). It matches
  credential *shapes*, not the words "password"/"token", so policy text is not
  flagged.
- Git hooks are per-clone and not version-controlled by `git` itself, so the
  canonical copy is tracked at `hooks/pre-commit` and installed with:
  `cp hooks/pre-commit .git/hooks/pre-commit && chmod +x .git/hooks/pre-commit`
  (re-run after every fresh clone — part of recovery/migration,
  BACKUP_AND_RECOVERY.md).
- Never paste a secret into a prompt or into a terminal whose output is logged.

## 9. Applying this to the imminent GitHub push

Preferred: an **SSH key** (`ed25519`) whose private key lives in `~/.ssh`
(outside the repo, perms 600), public key registered on GitHub. Alternative: a
PAT stored via the git credential store (`~/.git-credentials`, 600). Either is
created and stored under §3 and decided when the remote is set up — not here.
