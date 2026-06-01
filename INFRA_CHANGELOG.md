# INFRASTRUCTURE CHANGELOG

Append-only record of infrastructure changes (GOVERNANCE.md §10). Newest first.
Each entry: date, prompt ID, what changed, why.

---

## 2026-06-01 — 20260601-05 — Environment management policy

**Rationale:** Resolve the long-open environment-manager decision with a policy
(no installs). Codifies the operating principle "containers first, workflow
engines first, conda fallback, system packages foundational-only" and gives
Claude Code a decision procedure so environment choices are consistent and
reproducible (GOVERNANCE.md §4).

| # | Document | Change | Rationale |
|---|----------|--------|-----------|
| 1 | **ENVIRONMENT_POLICY.md** | **Created.** Operating principle; evaluation of Apptainer/Docker/Conda-Mamba/uv/system-packages/Nextflow/Snakemake; what is global vs project-local vs `resources/`; install-risk classification; SHA256/version logging; the container-vs-conda-vs-system decision procedure. | New governance document for environments. |
| 2 | GOVERNANCE.md | §4.2 now references ENVIRONMENT_POLICY (lockfile + image digest + driver/CUDA); §11 marks **environment manager RESOLVED** and version-control remote RESOLVED. | Bind reproducibility to the policy; close deferred items. |
| 3 | SYSTEM_OVERVIEW.md | Added ENVIRONMENT_POLICY.md to the §6 map and the file tree; prompts-of-record updated to 05. | Keep map/tree complete. |
| 4 | DIRECTORY_STANDARD.md | §4: shared container images (`*.sif`)/caches belong in `resources/`; env *definitions/lockfiles* stay project-local. | Avoid duplicated purpose; place build artifacts correctly. |
| 5 | RESOURCE_POLICY.md | §4: shared images in `resources/` stored once; containers use `apptainer --nv` for GPUs. | Disk/GPU consistency. |
| 6 | prompts/20260601-05_environment_policy.md | **Created** as current prompt of record; 04 marked kept. | Prompt versioning (GOVERNANCE.md §8). |

**Risk classifications recorded (derived from §2 characteristics):** uv =
low-risk §2.1 (pre-approvable; recommend ratifying into the canonical list);
Conda/Mamba = medium-risk (Supervisor); Apptainer & Docker = high-risk §2.3
(listed); Nextflow = high-risk by characteristics (recommend ratifying into
§2.3); Snakemake = ordinary project-local dependency (global install =
medium-risk). **No tool installed** — Apptainer, Docker, Conda/Mamba, Nextflow,
Snakemake remain uninstalled per instruction.

---

## 2026-06-01 — Operation: GitHub remote + first push (off-host backup established)

**Rationale:** Execute the Phase 2 remote step — give the precious-but-small
tier an off-host home, closing the "zero disaster recovery" gap flagged since
bootstrap (BACKUP_AND_RECOVERY.md §1, §6). Operational execution; no separate
prompt archived.

- **Auth:** dedicated ed25519 key `~/.ssh/hay2k-infra_ed25519` (generated
  20260601-04, no passphrase, perms 600, **outside the repo** per
  SECRETS_POLICY.md §3). Registered on GitHub (account-level, user `hay2k`).
- **Host trust:** GitHub host key verified against the published ed25519
  fingerprint `SHA256:+DiY3wvvV6TuJJhbpZisF/zLDA0zPMSvHdkr4UvCOqU` before being
  added to `~/.ssh/known_hosts` (not blindly accepted).
- **SSH config:** `~/.ssh/config` binds `Host github.com` to the dedicated key
  with `IdentitiesOnly yes` (machine-specific; not in any repo).
- **Connectivity:** `ssh -T git@github.com` → "Hi hay2k! You've successfully
  authenticated" ✅.
- **Remote:** `origin = git@github.com:hay2k/hay2k-infra.git` (private repo).
- **Push:** `main` pushed and tracking `origin/main` at commit `a167c13`.
- **Scratch clone test:** clone succeeded; HEAD matched `a167c13`; working tree
  clean and up to date with `origin/main`; 15 tracked files (9 root governance
  docs, 4 prompts, `hooks/pre-commit`, `.gitignore`); prompt archive present
  (01–04). Scratch dir removed.

**Note:** secrets are NOT in this remote and never will be (SECRETS_POLICY.md
§6); only the precious-but-small governance tier is backed up here. Bulk
precious data and the encrypted secrets-backup channel remain open.

---

## 2026-06-01 — 20260601-04 — Secrets management policy (Phase 2)

**Rationale (overall):** Close the secrets-management gap that was open since
bootstrap, before any credential (the imminent GitHub push, later Zotero) lands
on the host. Decisions taken with the operator: file-based + permission-enforced
storage now, encryption required before anything goes off-host; add a tracked,
format-based pre-commit secret-scan hook.

| # | Document | Change | Rationale |
|---|----------|--------|-----------|
| 1 | **SECRETS_POLICY.md** | **Created.** Principles, what counts as a secret, file storage model (`~/.secrets/`, 700/600, env-var access), non-secret manifest pattern, encryption upgrade-trigger (age/sops before off-host), backup rules, rotation/incident response, prevention (hook), and GitHub-auth guidance. | New governance document for credentials. |
| 2 | **hooks/pre-commit** | **Created** (tracked) + installed to `.git/hooks/`. Blocks staged content matching credential *formats* (private-key blocks, AKIA/ASIA, ghp_/github_pat_/gho_, xox…, AIza…, sk-…, JWT, assigned long secret values). Matches shapes not vocabulary, so governance prose is not flagged. Tested: passes policy docs, blocks planted `AKIA…`/`ghp_…`. | Defense-in-depth against accidental secret commits (SECRETS_POLICY §8). |
| 3 | GOVERNANCE.md | Added **§6a Secrets (never committed)** and marked secrets management **RESOLVED** in the §11 deferred list; annotated remote/secrets-backup as still open. | Bind the never-commit rule and point to the policy. |
| 4 | SYSTEM_OVERVIEW.md | Added SECRETS_POLICY.md to the §6 document map. | Keep the map complete. |
| 5 | BACKUP_AND_RECOVERY.md | Added a **Secrets** tier (precious, never to the git remote, encrypted off-host only) and recovery steps to reinstall the hook and restore secrets from the encrypted channel. | Secrets are precious but must not enter git history. |
| 6 | prompts/20260601-04_secrets_policy.md | **Created** as current prompt of record; 20260601-03 marked kept/superseded. | Prompt versioning (GOVERNANCE.md §8). |

**Note:** `.gitignore` already covered secret file categories at bootstrap; no
change was required. No secret values exist on the host; this policy is
preventive.

---

## 2026-06-01 — 20260601-03 — Governance refinement, terminology standardization, git bootstrap

**Rationale (overall):** Refine the corrected model into its final, maintainable
form: restate the core principle, make the installation policy an explicit
three-tier risk model, standardize agent terminology, and perform the git
bootstrap. Objective: a maintainable infrastructure — simplicity over
flexibility, clarity over completeness, current needs over hypothetical ones.

### Governance corrections
| # | Document | Change | Rationale |
|---|----------|--------|-----------|
| 1 | GOVERNANCE.md | §0 restated to the core principle **"Create what is required. Avoid what is not required."** and an expanded avoid-list (unnecessary dirs, duplicate dir purposes, speculative structures, empty organizational trees, placeholder projects). | Adopt the refined operating principle verbatim. |
| 2 | GOVERNANCE.md | §1 now lists the six permitted top-level domains and states **project directories may only be created after project approval — approval applies to the project, not the directory operation** (with `research/project_x`, `business/product_y`, `investment/strategy_z` examples). | Clarify project creation policy. |
| 3 | SYSTEM_OVERVIEW.md / DIRECTORY_STANDARD.md / PROJECT_LIFECYCLE.md | Synchronized the principle wording, avoid-list, and the project-vs-directory rule; PROJECT_LIFECYCLE adds the explicit examples and the no-anticipatory-directory rule. | Keep all docs consistent with §0/§1. |

### Installation policy changes (three-tier risk model)
| # | Document | Change | Rationale |
|---|----------|--------|-----------|
| 4 | GOVERNANCE.md | Replaced the two-tier model with **§2.1 low-risk (pre-approved, with five characteristics: CLI / single-host / no daemon / no listener / easily removable)**, **§2.2 medium-risk (shared tooling, reusable services, multi-user impact → Supervisor judgment + documentation)**, **§2.3 high-risk (Slurm, Docker, Apptainer, Prometheus, Grafana, databases, message queues, Kubernetes, external SaaS → explicit User approval)**. Updated the matrix rows accordingly. | Make install risk explicit and graduated. |
| 5 | RESOURCE_POLICY.md / AGENT_ARCHITECTURE.md / SYSTEM_OVERVIEW.md | Updated references to the new §2.1/§2.2/§2.3 tiers (e.g. Slurm = high-risk §2.3). | Consistency. |

### Directory policy changes
| # | Document | Change | Rationale |
|---|----------|--------|-----------|
| 6 | DIRECTORY_STANDARD.md | Header principle and avoid-list expanded to include duplicate directory purposes, empty organizational trees, and placeholder projects. | Match §0. |

### Terminology standardization
| # | Document | Change | Rationale |
|---|----------|--------|-----------|
| 7 | AGENT_ARCHITECTURE.md | Introduced the standard terms — **Agent** (umbrella), **Orchestrator** (project coordination), **Supervisor** (strategy/governance/quality), **Worker** (execution unit), **Subagent** (= Worker). Rewrote roles, the escalation chain to **Worker → Orchestrator → Supervisor → User**, scope boundaries, and anti-hallucination duties. | Standardize and stop term-mixing. |
| 8 | GOVERNANCE.md / SYSTEM_OVERVIEW.md / PROJECT_LIFECYCLE.md | Propagated the terminology: §3 escalation path, matrix approver names (Orchestrator materializes approved project dirs), the one-paragraph operating model, and lifecycle procedures. | Consistency across the doc set. |

### Prompt management
| # | Item | Change | Rationale |
|---|------|--------|-----------|
| 9 | prompts/20260601-01_bootstrap.md | Remains **ARCHIVED** (superseded). | Historical record. |
| 10 | prompts/20260601-02_bootstrap_revision.md | **Kept** (retained, not deleted) but marked superseded-by-03. | Operator instruction to keep 02; it remains a valid milestone record. |
| 11 | prompts/20260601-03_governance_refinement.md | **Created** as the current prompt of record. | Prompt versioning policy (GOVERNANCE.md §8): this prompt materially changed principles (terminology, install tiers) and must be archived to keep the prompt set consistent with current policy. |

### Git bootstrap
| # | Item | Change |
|---|------|--------|
| 12 | /home/hha/infra | `git` installed (low-risk prerequisite §2.1); repository initialized; repo-local identity `hay2k <emperorhay2k@gmail.com>`; first commit `infra bootstrap: governance synchronization and git initialization`. No remote, no push, no GitHub auth. |

---

## 2026-06-01 — 20260601-02 — Governance correction & document synchronization

**Rationale (overall):** The 20260601-01 bootstrap was intentionally
conservative and several documents implied that *installation*, *directory
creation*, or *infrastructure evolution* were prohibited outright. The intended
operating model only prohibits the *unnecessary* and the *speculative*.
Necessary infrastructure work should proceed without unnecessary approval
overhead. The following changes bring every document in line with that model.

| # | Document | Change | Rationale |
|---|----------|--------|-----------|
| 1 | GOVERNANCE.md | Added **§0 Core principles** stating the four corrected principles (unnecessary installs / unnecessary dirs / speculative structures prohibited; necessary work proceeds without approval overhead). | Establish the corrected model as the lens for the whole document. |
| 2 | GOVERNANCE.md | Reworked the **§2 approval matrix**: removed the blanket "install/remove software → User" row; added rows for pre-approved prerequisites (Worker/Supervisor), non-listed necessary installs (Supervisor), and high-impact services (User); reclassified directory/domain creation as Supervisor-level routine. | A blanket install gate implied installation was prohibited; the corrected model gates only high-impact services. |
| 3 | GOVERNANCE.md | Added **§2.1 pre-approved prerequisites** (`git, tmux, vim, curl, wget, jq, tree, htop`) and **§2.2 high-impact services** (Slurm, Docker, Apptainer, Prometheus, Grafana, databases, message queues, Kubernetes, external SaaS). | Operational clarification from prompt 20260601-02. |
| 4 | SYSTEM_OVERVIEW.md | Rewrote §7 "What was deliberately NOT done" → "Scope of work at bootstrap": reframes "no software installed / no dirs" as *not yet needed* rather than *prohibited*; cites §0 and the prerequisite list. | Removed an implication that installation/creation were prohibited. |
| 5 | SYSTEM_OVERVIEW.md | §4 already updated to `/home/hha/infra` git root (prior turn); §6 document map gains PROJECT_LIFECYCLE.md and INFRA_CHANGELOG.md. | Keep the map complete after new docs were added. |
| 6 | DIRECTORY_STANDARD.md | Rewrote the header **Principle** and §6: a *necessary* directory is created without approval; only *unnecessary*/*speculative*/*outside-standard* structures are prohibited or gated. | Removed "creation needs approval" / "default answer is no" framing. |
| 7 | DIRECTORY_STANDARD.md | Rewrote the "why not pre-create all six" callout: approval lives at the *project* level (PROJECT_LIFECYCLE.md), not on the act of making a directory. | Directory creation per se is not the gated act. |
| 8 | AGENT_ARCHITECTURE.md | §7 implementation note: replaced "must not pull in installed software before the software-install gate" with the prerequisite/high-impact distinction. | Removed implication that any tooling install was blocked. |
| 9 | RESOURCE_POLICY.md | §2: clarified that adding a scheduler before contention is *speculative* (prohibited), and that a full scheduler (Slurm) is a high-impact service requiring approval while the lightweight card-ownership record needs none. | Align with §0 and §2.2 without implying evolution is forbidden. |
| 10 | BACKUP_AND_RECOVERY.md | §6: `git` reclassified from "first User-approved install" to "pre-approved prerequisite (§2.1)". | git is now pre-approved. |
| 11 | **PROJECT_LIFECYCLE.md** | **Created.** Consolidates the *remaining* User-approval gates (project create/retire, data deletion, cross-domain migration) and the lifecycle state machine. | Was a required review target but did not exist; gives the surviving gates a home and clarifies they were intentionally *not* relaxed. |
| 12 | **INFRA_CHANGELOG.md** | **Created** (this file). | GOVERNANCE.md §10 requires infrastructure changes to be documented. |
| 13 | prompts/20260601-01_bootstrap.md | Marked **ARCHIVED / superseded by 20260601-02**. | Prompt versioning policy (GOVERNANCE.md §8). |
| 14 | **prompts/20260601-02_bootstrap_revision.md** | **Created** as the current prompt of record. | Prompt versioning policy. |

**Tooling action performed in this change:** installed `git` (pre-approved
prerequisite, §2.1); initialized the git repository at `/home/hha/infra` with a
repository-local identity; made the first local commit. No remote configured,
no push (pending operator-provided private repo URL).

> NOTE: if you are reading this before the git steps completed, the install
> required an interactive `sudo` the operator runs in-session; the commit
> follows immediately after.
