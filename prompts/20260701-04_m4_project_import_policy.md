# 20260701-04 — M4: Project Import Policy

**Date:** 2026-07-01
**Role:** User (operator `hha`) → governance codification
**Prompt (verbatim intent):** "Project Import Policy. A project may originate either from a
newly approved research project, or an existing research project migrated from another
server or environment. Imported projects should preserve previous documentation, handoff
records, protocols, and planning materials under `analysis/projects/<PROJECT_ID>/docs/`. The
imported project should then be reconstructed on the current platform using the shared
platform capabilities. Previous outputs are reference material. The current platform remains
the authoritative execution environment. The goal of import is reproducible reconstruction,
not simple file migration."

**Outcome:** Codified by **extending** existing canonical governance (Reuse-First on
governance — no new doc):
- **PROJECT_LIFECYCLE.md** — §2 states the two origins (newly approved / imported), both
  through the same User-approval gate and standard tree; new **§4a Import / migration
  procedure**: (1) approve as a project with a Capability Resolution mapping the legacy
  environment onto **shared platform capabilities** (pinned in ENVIRONMENT_MANIFEST); (2)
  preserve prior docs/handoff/protocols/planning **read-only** in
  `analysis/projects/<PROJECT_ID>/docs/` — reference only, not an execution input; (3)
  reconstruct the current canonical files and execute on-platform (the reconstruction is the
  authoritative reproducible result); (4) record origin/provenance in README; re-derive
  results before reporting as final.
- **DIRECTORY_STANDARD.md §3** — added `docs/` to the standard project shape, **sanctioned
  for imported projects only** (reference-only, explicitly not catch-all sprawl); fresh
  projects don't create it.

**Key stance:** *reproducible reconstruction, not simple file migration* — the current
platform is the authoritative execution environment; previous outputs are reference. Ties to
PLATFORM_REUSE_POLICY (Reuse-First), GOVERNANCE §4/§6 (reproducibility/integrity), and
AGENT_WORKFLOW_STANDARD §2 (execution reads only current canonical files).

**Nature:** governance/documentation only; no approval gate added or relaxed; no project
imported yet (policy is ready for first use). Handoff:
`2026-07-01_m4-project-import-policy.md`.
