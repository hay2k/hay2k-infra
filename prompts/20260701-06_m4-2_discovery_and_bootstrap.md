# 20260701-06 — M4-2: Platform Discovery Layer + Project Bootstrap

**Date:** 2026-07-01
**Role:** User (operator `hha`) → implementation (M4-2; "priority is implementation, not governance")
**Prompt (verbatim intent):** "Proceed with M4-2. Objectives: (1) Build the Platform Discovery
Layer — a reusable capability catalog for humans and future agents, discoverable by category,
accelerator, pipeline compatibility, reference requirements. (2) Extend analysis-install with
discovery-oriented commands (describe existing capabilities); do not redesign, extend. (3)
Build Project Bootstrap supporting create and import; imported projects automatically prepare
the standard project directory including docs/ and required canonical files. (4) Prepare for
the first imported project — P0003 (TBI scRNA-seq) will be the first import; do not import it
yet, prepare the reusable framework any future import will use. Follow existing governance;
Reuse-First; Shared-by-default; Container-first; Pipeline-driven; Provider-agnostic; autonomous
execution; batch into one milestone; validate; one handoff."

**Outcome (all validated):**
- **Discovery Layer** — extended `analysis-install` (read-only, live registry as single source
  of truth): `catalog [--kind|--accel|--category] [--json]`, `describe <kind> <group> <name>
  [version]`; optional additive install metadata `--category/--provides/--requires/--compat`
  (MANIFEST append, verify-safe); category inference; backfilled current capabilities; fixed a
  field-parse bug. `--json` validated as the agent interface.
- **Project Bootstrap** — `scripts/project-bootstrap create|import` + `templates/project/`
  (README, PROJECT_MASTER, TODO, RECONSTRUCTION; reuses ENVIRONMENT_MANIFEST). Materializes the
  standard tree incl. `docs/` (create → proposal/; import → full substructure +
  RECONSTRUCTION.md + `--from` staging, reference-only) + per-project git; presupposes User
  approval; `--dry-run`. Both modes validated in a temp dir — **no real project created**.
- **P0003 framework prepared, not imported:** `import` mode + docs/ substructure + reconstruction
  checklist are the reusable framework; PROJECT_REGISTRY §4 records P0003 as the anticipated
  first import (not approved/registered/materialized).
- Docs: PLATFORM_ARCHITECTURE §8a.

**Foundation:** consumes the 20260701-05 standard `docs/`. Handoff:
`2026-07-01_m4-2-platform-discovery-and-bootstrap.md`.
