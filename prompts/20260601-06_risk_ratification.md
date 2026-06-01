# 20260601-06 — Risk-Tier Ratification + Presentation Automation Deferral

> **STATUS: CURRENT.** Supersedes `20260601-05_environment_policy.md` (kept).

**Prompt ID:** 20260601-06
**Date:** 2026-06-01
**Role:** infra_admin
**Type:** Governance ratification + new deferred decision. **No installs.**
**Outcome:** Ratified install-risk tiers into GOVERNANCE.md §2; reclassified
Nextflow High→Medium (engine vs. backend split); opened the presentation-
automation deferred decision.

---

## Decisions ratified

1. **uv** — low-risk, pre-approved (added to canonical §2.1 list).
2. **Conda/Mamba** — medium-risk, Supervisor judgment.
3. **Nextflow** — reclassified High→**Medium**. The workflow engine itself is
   not high-risk. **Slurm, Kubernetes, Tower, and shared execution backends
   remain High-risk** (User approval).

## New deferred decision (document only)

**Presentation automation** — reproducible PPTX generation via **Node.js** +
**pptxgenjs**. Open questions: risk tier for the Node.js runtime + npm
dependency surface; global vs project-local placement of the Node/npm
toolchain; how `package-lock.json` + SHA256 satisfy reproducibility
(GOVERNANCE.md §4); deck artifacts vs the figure PNG+vector rule (§9).
**Nothing installed.**

## Verbatim prompt of record

> Ratify the following revisions. (1) uv: Low-risk, pre-approved. (2)
> Conda/Mamba: Medium-risk, Supervisor judgment. (3) Nextflow: Reclassify from
> High-risk to Medium-risk. The workflow engine itself is not high-risk. Slurm,
> Kubernetes, Tower, and shared execution backends remain High-risk. Update
> GOVERNANCE.md, ENVIRONMENT_POLICY.md, and INFRA_CHANGELOG.md accordingly.
>
> Also create a deferred decision entry for Presentation Automation: Node.js,
> pptxgenjs, reproducible PPTX generation. Do not install anything yet.
> Document only.
