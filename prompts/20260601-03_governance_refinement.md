# 20260601-03 — Governance Refinement, Synchronization & Git Bootstrap

> **STATUS: CURRENT.** Supersedes `20260601-02_bootstrap_revision.md` (kept) and
> `20260601-01_bootstrap.md` (archived).

**Prompt ID:** 20260601-03
**Date:** 2026-06-01
**Role:** infra_admin
**Type:** Governance refinement + document synchronization + git bootstrap.
**Outcome:** Adopted the refined core principle, the three-tier installation
risk model, the project-creation clarification, and the standardized agent
terminology; synchronized all docs; updated INFRA_CHANGELOG.md; archived/kept
prompts; installed git and made the first local commit at `/home/hha/infra`.

---

## Rationale for the prompt transition (01 → 02 → 03)

- **20260601-01 (archived):** intentionally conservative bootstrap. Implied
  installation / directory creation / infrastructure evolution were prohibited.
- **20260601-02 (kept):** corrected that over-restriction; introduced the
  necessary-vs-unnecessary framing and a two-tier install policy. Retained as a
  milestone record per the operator's instruction, not deleted.
- **20260601-03 (current):** refined the wording to the core principle below,
  made installation an explicit three-tier risk model, clarified project
  creation, and standardized agent terminology. This is now the operative
  policy of record.

Why a new file rather than only "keeping 02": this prompt materially changed
principles (terminology and install tiers). Prompt versioning (GOVERNANCE.md
§8) requires significant infrastructure-changing prompts to be archived, so the
prompt set stays consistent with current policy.

## Operative principles recorded by this prompt

**Core principle:** *Create what is required. Avoid what is not required.*
Minimalism first; avoid unnecessary directories, duplicate directory purposes,
speculative future structures, empty organizational trees, and placeholder
projects. Do not prohibit necessary infrastructure work — it should proceed
efficiently.

**Installation risk tiers (GOVERNANCE.md §2.1–§2.3):**
- Low-risk, pre-approved: `git`, `tmux`, `vim`, `curl`, `wget`, `jq`, `tree`,
  `htop` (CLI / single-host / no daemon / no listener / easily removable).
- Medium-risk: shared tooling, reusable services, multi-user impact →
  Supervisor judgment + documentation.
- High-risk: Slurm, Docker, Apptainer, Prometheus, Grafana, databases, message
  queues, Kubernetes, external SaaS → explicit User approval.

**Project creation:** the six domains may exist; project directories may only be
created after the *project* is approved — the approval applies to the project,
not the directory operation.

**Agent terminology:** Agent (umbrella) · Orchestrator (project coordination) ·
Supervisor (strategy, governance, quality control) · Worker (execution unit) ·
Subagent (= Worker). Escalation: Worker → Orchestrator → Supervisor → User.

## Verbatim prompt of record

> Prompt ID: 20260601-03 — Governance refinement, document synchronization, and
> Git bootstrap. Review and update all infrastructure documents and synchronize
> with the latest operating principles (not a prompt-only update).
>
> Core principle: "Create what is required. Avoid what is not required."
> Minimalism first. Avoid: unnecessary directories, duplicate directory
> purposes, speculative future structures, empty organizational trees,
> placeholder projects. Do not prohibit necessary infrastructure work; it
> should proceed efficiently.
>
> Installation policy — low-risk pre-approved (git, tmux, vim, curl, wget, jq,
> tree, htop; CLI / single-host / no daemon / no network listener / easily
> removable) install without approval; medium-risk (shared tooling, reusable
> services, multi-user impact) require Supervisor judgment + documentation;
> high-risk (Slurm, Docker, Apptainer, Prometheus, Grafana, databases, message
> queues, Kubernetes, external SaaS) require explicit user approval.
>
> Project creation — domains research/business/investment/runtime/resources/
> infra may exist; project directories may only be created after project
> approval (research/project_x, business/product_y, investment/strategy_z);
> approval applies to the project, not the directory operation.
>
> Agent terminology — Agent = umbrella; Orchestrator = project coordination;
> Supervisor = strategy, governance, quality control; Worker = execution unit;
> Subagent = synonym of Worker. Avoid mixing these terms.
>
> Update INFRA_CHANGELOG.md (governance corrections, installation policy
> changes, directory policy changes, terminology standardization). Prompt
> management: archive 20260601-01, keep 20260601-02, record rationale for the
> transition.
>
> Git bootstrap: install git if needed; initialize git in /home/hha/infra;
> repository-local config only; user.name=hay2k, user.email=
> emperorhay2k@gmail.com; first commit "infra bootstrap: governance
> synchronization and git initialization"; no remote, no push, no GitHub auth.
>
> Final report: modified files, governance changes, unresolved ambiguities, git
> status, tracked file list, recommended Phase 2 activities.
>
> Objective: a maintainable infrastructure. Prefer simplicity over flexibility,
> clarity over completeness, current needs over hypothetical future needs.
