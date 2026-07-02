# 20260702-01 — M4-4: Research Knowledge Transfer Framework

**Date:** 2026-07-02
**Role:** User (operator `hha`) → knowledge-transfer framework + P0003 knowledge acquisition
**Prompt (verbatim intent):** "M4-4 — Research Knowledge Transfer Framework. Not project
execution; knowledge acquisition from an existing research project (future P0003, TBI scRNA-seq).
NOT migration — extract the research knowledge required to reconstruct the project from scratch on
the new GPU platform. Collect/organize: (1) project overview; (2) analysis strategy (why chosen,
why alternatives rejected, assumptions); (3) trial-and-error history [high priority] (attempt →
problem → solution → final decision; don't hide failures); (4) refactoring knowledge (locate the
refactored project; original → refactoring → improvements → limitations); (5) Claude Code
knowledge (reusable design decisions); (6) ChatGPT knowledge (ideas/literature/rejected/future,
avoid noise); (7) open questions; (8) recommended reconstruction strategy (the NEW implementation,
not legacy). Output a structured knowledge_transfer/ package (01…08 + Attachments/). This package
is the INPUT for a future imported project; the platform later consumes it to generate
PROJECT_MASTER/TODO/execution plan. Transfer knowledge, not files. One handoff."

**Outcome:**
- **Reusable framework built** (the deliverable that could be produced without fabricating):
  `templates/knowledge_transfer/` (README + 01_project_overview … 08_reconstruction_plan +
  Attachments/), each encoding the required structure + anti-fabrication/citation rules;
  `project-bootstrap kt-init` scaffolds it; PROJECT_LIFECYCLE §4a integrates it as the preferred
  distilled input for imports (platform consumes → PROJECT_MASTER/TODO/execution plan).
- **P0003 knowledge NOT extracted — BLOCKED (deliberate, governance-compliant):** an exhaustive
  filesystem + content search found **no P0003/TBI scRNA-seq source materials on this platform**
  (no legacy project, no refactored version, no prior Claude Code work beyond this infra
  transcript, no ChatGPT exports). P0003 is migrated *from another environment*; its materials are
  there, not here. Filling 01–08 with invented TBI content would violate GOVERNANCE §5
  (no fabrication) and poison the reconstruction. **Decision request to operator:** provide the
  source materials (legacy/refactored project export, ChatGPT export, prior Claude work) so the
  package can be populated from real content.

**Nature:** framework = implementation (validated in temp; no real project created). Extraction =
blocked pending inputs. Handoff: `2026-07-02_m4-4-knowledge-transfer-framework.md`.
