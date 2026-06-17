# PROJECT SPECIFICATION POLICY

**Status:** CANONICAL from 2026-06-16 (promoted M3-4C.6, 20260616-04; authored M3-1A).
Documentation/governance only. Vendor-, model-, and project-neutral.
**Scope:** A lightweight, reusable, human- and agent-friendly specification system for
**any** project in **any** domain. Complements DIRECTORY_STANDARD.md §3 (project shape),
AGENT_WORKFLOW_STANDARD.md (workflow), and PLATFORM_REUSE_POLICY.md (capability deps).

---

## 1. Rationale
Every project needs one authoritative, machine-and-human-readable specification that
planning agents can update and execution agents can rely on, without ambiguity about
which document wins. The system is deliberately small (four spec/plan files + an archive
dir, plus the separate `ENVIRONMENT_MANIFEST.md`), reusable across projects, and
independent of any tool or vendor.

## 2. Canonical project documents (per project)
Live at the project root (`<domain-tree>/projects/<ID>/`):

| File | Required | Purpose |
|------|----------|---------|
| **PROJECT_MASTER.md** | **yes** | Authoritative project specification (the source of truth) |
| **FIGURE_PLAN.md** | optional | Figure / presentation planning |
| **MANUSCRIPT_PLAN.md** | optional | Manuscript / report structure planning |
| **TODO.md** | yes | Actionable work queue |
| **ENVIRONMENT_MANIFEST.md** | **yes** | Pinned platform-capability dependencies + Capability Resolution — **separate** governance (PLATFORM_REUSE_POLICY.md §5); **not** part of the §3 spec hierarchy |

Current files **always keep these fixed names** (no version suffix on the live file).

## 3. Source-of-truth hierarchy (specification documents)
When the **specification/plan** documents conflict, precedence is:

> **PROJECT_MASTER.md  >  FIGURE_PLAN.md  >  MANUSCRIPT_PLAN.md  >  TODO.md**

**Execution agents and operators must always treat `PROJECT_MASTER.md` as the primary
reference.** A lower-precedence document never overrides a higher one; conflicts are
resolved by updating the lower document to match (or by a human revising
`PROJECT_MASTER.md`). `ENVIRONMENT_MANIFEST.md` is the authority for *capability
dependencies* (PLATFORM_REUSE_POLICY), orthogonal to this spec hierarchy.

## 4. Versioning & archive policy
- The **current** file always keeps its fixed canonical name (§2).
- **Historical versions** go under the project's **`archive/`** directory with
  **sequential numbering** + a short reason:
  ```
  <ID>/archive/PROJECT_MASTER_01_initial_structure.md
              /PROJECT_MASTER_02_figure_reorganization.md
              /PROJECT_MASTER_03_analysis_scope_expansion.md
  ```
  Each archived filename **clearly indicates the major reason for the revision**.
- **Prohibited** as primary identifiers: `final`, `final2`, `latest`, `vFinal`, and
  **date-only** naming. Sequential `NN_reason` is the rule (DIRECTORY_STANDARD.md §5
  exception). Git history remains the full record; `archive/` captures human-meaningful
  milestone snapshots.
- The same convention applies to `FIGURE_PLAN.md` / `MANUSCRIPT_PLAN.md` / `TODO.md`
  when a milestone snapshot is worth keeping.

## 5. Human + agent workflow compatibility
- **Planning agents/operators** may create/update the current canonical spec files and
  the `ENVIRONMENT_MANIFEST.md` (recording the Reuse-First Capability Resolution,
  PLATFORM_REUSE_POLICY §2/§7).
- **Execution agents/operators** read **only the current canonical files** (treating
  `PROJECT_MASTER.md` as primary); they consume platform capabilities pinned in
  `ENVIRONMENT_MANIFEST.md` (never redefine them).
- **Archived versions are historical references only** — never default execution inputs.
- **Human decision authority is mandatory** (AGENT_WORKFLOW_STANDARD.md Decision Layer):
  AI proposes; humans approve revisions to `PROJECT_MASTER.md` and lifecycle events
  (GOVERNANCE §2, PROJECT_LIFECYCLE §3/§4).

## 6. Example
```
<domain-tree>/projects/<ID>/
├── PROJECT_MASTER.md          # authoritative spec (current)
├── FIGURE_PLAN.md             # optional
├── MANUSCRIPT_PLAN.md         # optional
├── TODO.md                    # work queue (current)
├── ENVIRONMENT_MANIFEST.md    # pinned capability deps + Capability Resolution
└── archive/
    ├── PROJECT_MASTER_01_initial_structure.md
    └── PROJECT_MASTER_02_scope_expansion.md
```

## 7. Future scalability
- Reusable verbatim across all domains and any number of projects; no per-project
  customization required.
- Tooling/agents may read `PROJECT_MASTER.md` as a structured input; keep it
  human-readable Markdown with clear headings so both humans and agents parse it
  (automation readiness, PLATFORM_ARCHITECTURE §8).
- An `archive/` index (optional) can summarize the revision history if it grows long.
