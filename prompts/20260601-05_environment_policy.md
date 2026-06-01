# 20260601-05 — Environment Management Policy

> **STATUS: CURRENT.** Supersedes `20260601-04_secrets_policy.md` (kept).

**Prompt ID:** 20260601-05
**Date:** 2026-06-01
**Role:** infra_admin
**Type:** New governance document (policy + recommendation). **No installs.**
**Outcome:** Created ENVIRONMENT_POLICY.md and cross-references; resolved the
environment-manager deferred decision. Apptainer, Docker, Conda/Mamba,
Nextflow, and Snakemake remain uninstalled.

---

## Decision recorded

Operating principle adopted: **containers first, workflow engines first, conda
only as fallback, system packages only for foundational utilities or approved
infrastructure.** Recommendation: Apptainer/SIF as primary container runtime;
uv as the default Python env tool (low-risk); Snakemake as default workflow
engine (Nextflow for nf-core/scale); conda/mamba as fallback only.

## Recommendations forwarded to the operator (for ratification)

- Add **uv** to the canonical §2.1 low-risk list (it meets all five
  characteristics).
- Add **Nextflow** to the canonical §2.3 high-risk list.
- Classify **Conda/Mamba** as medium-risk (Supervisor judgment + documentation).

These are interpretive classifications in ENVIRONMENT_POLICY.md until ratified
into GOVERNANCE.md §2's canonical (operator-authored) lists.

## Verbatim prompt of record

> Proceed with the environment manager decision. Do not install a full
> environment stack yet. First produce an environment management policy and
> recommendation. Evaluate: Apptainer/SIF, Docker, Conda/Mamba, uv, system
> packages, Nextflow, Snakemake. Use the current operating principle:
> Containers first. Workflow engines first. Conda only as fallback. System
> packages only for foundational utilities or approved infrastructure.
>
> The policy must explain: (1) what is installed globally, (2) what is
> project-local, (3) what belongs in /home/hha/resources, (4) what belongs in
> project directories, (5) what requires approval, (6) how SHA256/version
> logging is handled, (7) how Claude Code should decide between container,
> conda, and system package.
>
> Update the relevant governance docs and INFRA_CHANGELOG.md. Do not install
> Apptainer, Docker, Conda/Mamba, Nextflow, or Snakemake yet.
