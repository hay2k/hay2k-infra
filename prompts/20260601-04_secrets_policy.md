# 20260601-04 — Secrets Management Policy (Phase 2)

> **STATUS: CURRENT.** Supersedes `20260601-03_governance_refinement.md` (kept).

**Prompt ID:** 20260601-04
**Date:** 2026-06-01
**Role:** infra_admin
**Type:** Phase 2 — new governance document + cross-references + pre-commit hook.
**Outcome:** Created SECRETS_POLICY.md and a tracked format-based pre-commit
secret-scan hook (installed + tested), added GOVERNANCE §6a, updated the
document map, backup tiers, and changelog. No secret values exist on the host;
the policy is preventive.

---

## Decisions recorded (operator-approved)

- **Storage model:** file-based, permission-enforced (`~/.secrets/`, dir 700,
  files 600, env-var access). Encryption-at-rest (age/sops) becomes required
  before any secret is copied off-host or shared.
- **Pre-commit hook:** yes — a plain grep-based hook matching credential
  *formats* (not the words "password"/"token"), tracked at `hooks/pre-commit`
  and installed into `.git/hooks/`.
- **Email-in-metadata:** confirmed intentional git identity, not a secret;
  retained as-is.

## Verbatim instruction of record

> No changes needed. Keep the email as-is — it is intentional git identity
> metadata, not a secret. Proceed to Phase 2: secrets management policy. Present
> proposed document changes before committing.

(Issued after the 20260601-03 security review passed and the bootstrap commit
`a84133e` was confirmed secret-free. Proposed document changes were presented
and the two pivotal decisions above were approved before any file was written
or committed.)
