# SECURITY AND HARDENING POLICY

**Status:** Design (2026-06-01, 20260601-12). **Document only — no hardening,
config, firewall, account, or service change is applied. This is the intended
security posture.**
**Scope:** Host, network, filesystem, secrets, supply chain, agents, logging,
backup, incident response, and future-service security for the 3-node cluster.

---

## 0. Executive summary

The cluster is a **self-managed, single-primary-operator, 3-node research GPU
cluster**. The posture is **proportionate, not enterprise**: a small set of
**mandatory** controls that close the high-value risks (SSH/key hygiene,
no public service exposure, secrets off-repo, integrity verification, human
approval for high-risk change), a layer of **recommended** controls that
ratchet up safety cheaply (MFA on GitHub, auditd, commit signing), and
**optional** controls reserved for scale (SSH MFA, Kerberos NFS, egress
filtering). No SIEM, no enterprise PAM/vault, no full CIS automation — those are
overengineering at this scale (§6 principle alignment).

The **single highest-value target is the control node `gpu-01`** (orchestration
+ monitoring + future NFS server + secrets access concentrate there), and the
**single highest-impact asset is the secrets directory + GitHub deploy key**
(loss/leak compromises the off-host backup and any integration). Security
spending is weighted accordingly.

## 1. Principles & scope

This policy is read through the existing principles:
- **Minimalism first** (GOVERNANCE.md §0): fewest accounts, services, open
  ports, and privileges that meet the need. Hardening that isn't needed isn't
  added.
- **Continuous improvement:** this is a baseline to ratchet up; controls are
  revisited as the cluster grows. Earlier choices are not immutable.
- **Human authority:** high-risk/irreversible security actions require **User
  approval** (GOVERNANCE.md §2); agents never self-approve.
- **Domain separation:** research/business/investment/runtime are isolated by
  ownership/permissions and (future) accounts; cross-domain = User approval.
- **Research-first resource policy:** security must not cripple research —
  outbound model/package pulls are allowed but integrity-verified, not blocked.

**Control classification** used throughout: **[M] Mandatory** (must hold),
**[R] Recommended** (adopt unless a reason not to), **[O] Optional** (scale/
future, not required now).

## 2. Host security

- **[M]** Keep Rocky Linux 10 patched on a regular cadence; security updates
  promptly. **[R]** A CIS-aligned *subset* baseline (not full automated CIS).
- **[M]** Keep **SELinux enforcing** (Rocky default) — never set permissive to
  "make something work"; fix the policy instead.
- **[M] Service minimization:** run only required services; no desktop/GUI; no
  public-facing daemons. Every listening service is justified and internal.
- **SSH policy:** **[M]** key-only auth (`PasswordAuthentication no`), **[M]**
  `PermitRootLogin no`, **[M]** ed25519 keys, **[R]** `AllowUsers hha` (+ future
  operators explicitly), **[R]** restrict SSH to the management network,
  **[R]** rate-limit/lockout (e.g. `fail2ban`), **[M]** verified `known_hosts`
  (as done for GitHub).
- **Root access policy:** **[M]** root is **emergency/bootstrap only** — no
  routine root login, no root over SSH; **[M]** strong root password held as a
  **break-glass** secret (SECRETS_POLICY.md); all admin via `sudo` as `hha`.
- **sudo policy:** **[M]** `hha` uses password-protected sudo (no broad
  `NOPASSWD`); **[R]** sudo events logged (journald/auditd); **[O]** command-
  scoped sudoers if more operators are added.
- **Password policy:** **[M]** strong passwords for `hha` and root; **[R]**
  `pwquality` minimums; **[M]** no shared accounts. (Passwords mainly guard
  sudo/console since SSH is key-only.)
- **MFA:** **[R]** MFA on the **GitHub account** (protects the off-host backup);
  **[O]** SSH MFA (TOTP via PAM) — reserved for scale/more operators.
- **Account lifecycle:** **[M]** only necessary accounts (`hha`, root, system);
  **[M]** future service identities (slurm, prometheus, nfs) are **non-login
  system accounts**; **[M]** revoke keys/access promptly when an operator
  departs; **[R]** periodic account review.

## 3. Network security

- **[M] Firewall (firewalld) default-deny inbound:** allow only SSH (from the
  management network) and required intra-cluster ports; **[M] no service exposed
  to the public internet.**
- **[R] Cluster-internal trust boundary:** the 3 nodes form a trusted internal
  segment, but still least-privilege; inter-node services bind the **internal
  interface only**, never `0.0.0.0` reachable from outside.
- **[R] Management-plane separation:** separate management from data/compute
  traffic where hardware allows; **[O]** dedicated management VLAN. (Depends on
  the open **cluster-networking** decision — RESOURCE_POLICY.md §7.)
- **Outbound philosophy:** **[M]** allow the outbound the research needs
  (package/model/image pulls) but **integrity-verify everything** (SHA256/
  digests, GOVERNANCE.md §6); **[R]** prefer known registries/mirrors; **[O]**
  egress filtering/allowlist. Philosophy: *pragmatic + verified*, not locked
  shut (research-first).
- **Future NFS:** **[M]** NFSv4, **`root_squash`**, export **only to cluster
  node addresses** on the internal network, never beyond the cluster; **[R]**
  `sec=krb5` is **[O]** (heavy for one operator).
- **Future Slurm comms:** **[M]** the **munge key is a secret** (600, dedicated
  account), Slurm traffic on the internal network only, **[R]** restrict
  `slurmctld`/`slurmd` ports to cluster hosts.

## 4. Filesystem security

- **[M] Ownership:** files owned by `hha` or the appropriate (future) service
  account; domain trees owned per domain; **no world-writable files/dirs.**
- **[M] Permissions:** least-permissive — no `0777`; repo files `644`/dirs
  `755`; **secrets dir `700`, secret files `600`**; **[R]** operator `umask 027`.
- **Shared-storage model (future NFS):** **[M]** `root_squash` + per-domain
  directory ownership/permissions enforce **soft domain separation**
  (STORAGE_ARCHITECTURE.md); **[R]** NFSv4 ACLs for finer control; **[M]**
  **secrets never on shared storage unencrypted.**
- **Secrets directory:** **[M]** `~/.secrets` `700`, files `600`, **outside any
  repo** (SECRETS_POLICY.md §3).
- **Temporary files:** **[M]** no secrets in `/tmp`; **[R]** per-job scratch
  with correct perms, cleaned on completion; **[R]** `PrivateTmp` for future
  services.
- **Artifact integrity:** **[M]** SHA256 / pinned digests for downloads and
  images (GOVERNANCE.md §6, ENVIRONMENT_POLICY.md §6); **[O]** signature
  verification (cosign) for images.

## 5. Secrets management (security view; full policy = SECRETS_POLICY.md)

- **[M] Location:** `~/.secrets`, `700`/`600`, off-repo, per-domain.
- **[M] Backup:** secrets backed up **only encrypted, off-host, never to git**
  (SECRETS_POLICY.md §6). *Currently single-copy on-host — a known gap.*
- **Rotation:** **[M]** rotate **immediately on exposure**; **[R]** periodic
  rotation for long-lived tokens.
- **Emergency recovery:** **[R]** a **break-glass** encrypted copy of critical
  secrets (root password, GitHub deploy key) stored off-host, so node loss does
  not lock the operator out of the remote; **[M]** the recovery path is
  documented.
- **API keys / SSH keys / GitHub creds:** **[M]** dedicated, least-scope keys
  (per-repo deploy key, no PAT — already decided), ed25519, key-only; **[R]**
  GitHub MFA; **[M]** never in a repo (pre-commit hook enforces, SECRETS_POLICY
  §8).

## 6. Supply-chain security

- **[M] Packages** from official Rocky repos / trusted sources with
  `gpgcheck` on; installs are risk-tiered and gated (GOVERNANCE.md §2).
- **[R] Third-party repos** minimized; **[M]** added only with GPG verification
  and **User approval** (adding a repo is an infra change).
- **[M] Container provenance:** pull from trusted registries, **pin by digest**,
  record the `.sif` SHA256; **[O]** verify signatures (cosign).
- **[M] Image verification** before run (digest/SHA256; mismatch = hard stop).
- **[M] Workflow provenance:** Snakemake/Nextflow definitions version-controlled
  and pinned (ENVIRONMENT_POLICY.md).
- **[M] Reproducibility** per GOVERNANCE.md §4 (lockfiles, image digests, seeds).

## 7. Agent security

- **[M] Identity:** agents currently run as `hha`; **[R/future]** per-domain
  **service accounts** for stronger separation once domains are active.
- **[M] Least privilege:** a Worker gets only its task's scope; **no ambient
  credentials** — secrets are injected via env **only when the task needs them**.
- **[M] Execution boundaries:** Workers are task-scoped; cross-project/cross-
  domain reach is an escalation, not a default (AGENT_ARCHITECTURE.md §5);
  **[R]** run heavy/untrusted code inside a container (Apptainer, when
  available) as a sandbox.
- **[M] Cross-domain restrictions:** domain independence (GOVERNANCE.md §1);
  cross-domain movement = **User approval**; enforced by ownership/permissions.
- **[M] Approval gates:** high-risk/irreversible actions = **User** (GOVERNANCE.md
  §2); agents never self-approve; surfaced as **approval-required** alerts
  (OBSERVABILITY.md §6.1).
- **[M] Auditability:** every agent decision/action is logged (AGENT_RUNTIME.md
  §5, GOVERNANCE.md §10) with reproducibility fields.

## 8. Logging and auditing

- **[M] Audit scope:** authentication (sshd), privilege use (sudo), and agent
  actions are logged; **[R]** `auditd` for security-relevant file/syscall events
  (e.g. changes under `~/.secrets`, sudoers).
- **[R] Security-event retention:** ~90 days for auth/audit logs, bounded by
  disk; **[M]** security logs are not deleted prematurely.
- **[M] Change tracking:** git history + INFRA_CHANGELOG.md; all infra changes
  documented (GOVERNANCE.md §10).
- **GitHub traceability:** **[R]** commit signing (SSH/GPG) and **[R]** branch
  protection on the private repo; the commit history is the integrity trail.
- **[M] Incident reconstruction:** logs + git history + changelog must suffice
  to reconstruct what happened; **[R]** centralized logs (Loki) aid this.

## 9. Backup security

- **[M] Encryption:** secrets backups encrypted (age/sops) **before** leaving
  the host (SECRETS_POLICY.md §5); **[R]** encrypt bulk backups at rest off-host;
  **[M]** the GitHub repo is **private**.
- **[M] Restore validation:** test restores — *an untested backup is not a
  backup* (BACKUP_AND_RECOVERY.md §3); **[R]** periodic restore drills.
- **[M] Access controls:** backup targets use least-privilege credentials
  (per-repo deploy key; future MinIO per-bucket keys); access is restricted and
  auditable.

## 10. Incident response

Severity uses the observability alert levels (OBSERVABILITY.md §6.1):
**warning** (review), **critical** (immediate action), **approval-required** (a
User decision is waiting). Workflows are deliberately simple for one operator:

- **Credential leak:** **[M]** (1) revoke/rotate at the provider **first**,
  (2) scrub from git history (`git filter-repo`), (3) rotate the affected key
  (e.g. GitHub deploy key), (4) document in INFRA_CHANGELOG.md. Assume exposure
  the moment a secret touches the tree (SECRETS_POLICY.md §7).
- **Host compromise:** **[M]** (1) isolate the node from the network,
  (2) preserve logs/evidence, (3) rotate **all** secrets that touched it,
  (4) rebuild from known-good (reproducible infra + lockfiles/images),
  (5) restore data from backup and re-verify host keys. If `gpu-01` (control)
  is affected, **fail over to `gpu-02`** (NODE_ARCHITECTURE.md §4).
- **Compromise (general):** **[M]** contain → eradicate → recover → document;
  **[R]** a short written post-incident note for continuous improvement.
- **[M]** Anything irreversible in response (wipe/rebuild, mass rotation) that
  exceeds routine is **approval-required**.

## 11. Future-service security requirements (not assuming installed)

| Service | Mandatory when deployed |
|---------|--------------------------|
| **Slurm** | munge key as a `600` secret on a dedicated account; internal-net only; ports restricted to cluster hosts; jobs run unprivileged with cgroup isolation |
| **Apptainer** | prefer **unprivileged/rootless** mode; verify SIF digests; controlled bind mounts (no broad host binds); no privileged containers |
| **Docker** | **discouraged** (root daemon = effective root via the `docker` group); if ever required, **rootless Docker**, internal-only, group tightly restricted — Apptainer preferred |
| **NFS** | NFSv4, `root_squash`, export to cluster node IPs on the internal network only; secrets never unencrypted on it; `sec=krb5` optional |
| **Prometheus** | bind internal-only; never public; read-only data; auth on any remote-write; exporters expose **no secrets** |
| **Grafana** | strong admin creds (secret); disable anonymous; internal-only or behind an auth proxy; HTTPS; never public |
| **MinIO** | per-bucket keys/IAM (secrets); TLS; **not public**; versioning; treat keys like any credential |

All of the above are **high-risk components (§2.3) → User approval** to deploy.

## 12. Highest-risk register

- **Highest-risk attack surfaces:** (1) **control node `gpu-01`** — value
  concentration; (2) **secrets dir + GitHub deploy key** — off-host backup
  access; (3) **SSH** if ever reachable from untrusted networks; (4) **future
  NFS export** (squash/scope mistakes); (5) **outbound supply chain** (malicious
  package/model/image); (6) **future exposed services** (Grafana/MinIO/Docker).
- **Highest-risk operational mistakes:** committing a secret (hook is
  bypassable); **disabling SELinux**; broad `NOPASSWD` sudo; binding a service
  to `0.0.0.0`/public; **`no_root_squash`** on NFS; running untrusted model code
  outside a container; deleting non-regenerable data; **untested backups**;
  stale/over-scoped credentials.
- **Highest-risk future deployments:** **Docker** (root daemon); **NFS**
  (over-broad export); **MinIO/Grafana** if exposed; **Slurm munge-key** leakage.

## 13. Unresolved decisions requiring future approval

- **Cluster networking / management-plane separation** (gates §3; tied to the
  open networking decision).
- **SSH MFA** (TOTP) — adopt or not.
- **Commit signing + branch protection** on the GitHub repo.
- **`auditd` enablement + retention sizing.**
- **Secrets-encryption tool** (age vs sops) — overlaps SECRETS_POLICY.md §5.
- **Per-domain service-account model** for stronger agent separation.
- **Break-glass recovery copy** location for critical secrets.
- **Egress filtering** policy (allowlist vs pragmatic-verified).

These are documented, not decided; each is a **User decision** before
implementation. Nothing in this document is implemented.
