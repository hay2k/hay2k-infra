# 20260601-02 — Bootstrap Revision (Governance Correction)

> **STATUS: KEPT (milestone) — superseded by `20260601-03_governance_refinement.md`.**
> Retained per operator instruction (20260601-03 §7): not deleted, remains a
> valid record of the 01→02 correction. Current policy lives in 20260601-03.

**Prompt ID:** 20260601-02
**Date:** 2026-06-01
**Role:** infra_admin
**Type:** Governance correction (not merely a prompt update).
**Outcome:** Synchronized all governance documents to the corrected operating
model, created PROJECT_LIFECYCLE.md and INFRA_CHANGELOG.md, archived 01, and
installed git + initialized the repo at `/home/hha/infra` with a first commit.

---

## Correction summary

The original bootstrap was intentionally conservative. On review, several
governance interpretations were too restrictive and did not reflect the
intended operating model. Statements implying that **installation**,
**directory creation**, or **infrastructure evolution** were prohibited were
replaced with the four canonical principles (now GOVERNANCE.md §0):

- Unnecessary installations are prohibited.
- Unnecessary directories are prohibited.
- Speculative future structures are prohibited.
- Necessary infrastructure work should proceed without unnecessary approval
  overhead.

## Operational clarifications recorded

- **Pre-approved prerequisites (no further approval):** `git`, `tmux`, `vim`,
  `curl`, `wget`, `jq`, `tree`, `htop`. (GOVERNANCE.md §2.1)
- **High-impact services (still require User approval):** Slurm, Docker,
  Apptainer, Prometheus, Grafana, databases, message queues, Kubernetes,
  external SaaS integrations. (GOVERNANCE.md §2.2)
- **Lifecycle gates retained (User-only):** project create/retire,
  non-regenerable data deletion, cross-domain migration. (PROJECT_LIFECYCLE.md)

## Verbatim prompt of record

> Prompt ID: 20260601-02 — Governance correction and document synchronization.
>
> The original bootstrap prompt was intentionally conservative. After review,
> several governance interpretations are too restrictive and no longer reflect
> the intended operating model. This is a governance correction, not merely a
> prompt update.
>
> Tasks: (1) Review all generated documents (SYSTEM_OVERVIEW, GOVERNANCE,
> PROJECT_LIFECYCLE, DIRECTORY_STANDARD, AGENT_ARCHITECTURE, RESOURCE_POLICY,
> BACKUP_AND_RECOVERY). (2) Identify every statement implying installation is
> prohibited / directory creation is prohibited / infrastructure evolution is
> prohibited. (3) Replace with: "Unnecessary installations are prohibited."
> "Unnecessary directories are prohibited." "Speculative future structures are
> prohibited." "Necessary infrastructure work should proceed without
> unnecessary approval overhead." (4) Update all affected documents. (5) Record
> every modification in INFRA_CHANGELOG.md. (6) Archive the original bootstrap
> prompt (20260601-01 → archived) and create a revised version
> (20260601-02_bootstrap_revision.md → current).
>
> Pre-approved infrastructure prerequisites (no additional approval): git,
> tmux, vim, curl, wget, jq, tree, htop.
> High-impact services still require approval: Slurm, Docker, Apptainer,
> Prometheus, Grafana, Databases, Message queues, Kubernetes, External SaaS
> integrations.
>
> After documentation synchronization: (1) Install git. (2) Initialize git in
> /home/hha/infra. (3) Configure repository-local git identity only. (4) Show
> git status and tracked files. (5) Create the first local commit.
>
> Before completion provide: documents modified, rationale for each
> modification, remaining governance ambiguities.
