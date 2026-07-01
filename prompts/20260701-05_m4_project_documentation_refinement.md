# 20260701-05 — M4: Project Documentation Refinement

**Date:** 2026-07-01
**Role:** User (operator `hha`) → governance refinement (extend existing docs; no new standard)
**Prompt (verbatim intent):** "Refine the Project Import Policy: (1) Every project shall
contain a standard `docs/` directory; structure consistent across all projects to simplify
automation and agent behavior; may initially contain only `proposal/`; additional subdirs
created only when needed. Recommended: docs/{proposal,handoff,protocol,literature,meeting,
archive}. Fresh projects normally begin with docs/proposal/; imported projects additionally
preserve previous materials under docs/handoff/, docs/protocol/, etc. (2) docs/ is
documentation only, not an execution workspace; current execution is governed only by the
canonical project files (PROJECT_MASTER.md, ENVIRONMENT_MANIFEST.md, TODO.md, project
configs). (3) Agents may read docs/ as reference material only and must never treat imported
documents as canonical execution instructions. (4) Proposals, grant applications, planning
documents → docs/proposal/ whenever applicable. Reuse existing governance; do not create a
new governance standard."

**Outcome:** Extended existing canonical governance (no new doc):
- **DIRECTORY_STANDARD.md §3** — `docs/` promoted from imported-only to **REQUIRED in every
  project**; documented the standard substructure
  `proposal/handoff/protocol/literature/meeting/archive/` (created lazily; fresh projects
  begin with `docs/proposal/`); clarified `docs/archive/` (documentation) vs the project-level
  `archive/` (spec snapshots); rewrote the rule bullet (documentation-only, not an execution
  workspace, not sprawl).
- **PROJECT_LIFECYCLE.md** — §4 (fresh projects create `docs/proposal/`); §4a (imported
  materials mapped into the substructure); §4a status line notes the refinement.

**Nature:** governance/documentation only. Consumed immediately by M4-2 Project Bootstrap.
Handoff folded into the M4-2 milestone handoff (`2026-07-01_m4-2-platform-discovery-and-bootstrap.md`).
