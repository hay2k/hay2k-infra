# PROJECT REGISTRY

**Status:** CANONICAL from 2026-06-06 (created M3-0, 20260606-01).
**Purpose:** The single cross-domain authority for project identity, priority/
accounting grouping, and primary placement on the shared cluster. Mandatory: every
project is recorded here, and an entry is created/updated at each PROJECT_LIFECYCLE.md
§3 event (create / activate / archive / retire).

---

## 1. Rules
- **Mandatory** for every project and subproject (PROJECT_ID_POLICY.md).
- This file is the **authority for ID assignment** (next free per-domain number) and
  the **never-reuse-a-number** rule.
- **Domain implies priority:** Research > Business > Investment > Surplus.
- **Primary Node** is the project's organizational home and where its `/data/<ID>`
  lives — **non-exclusive** (work may run elsewhere by priority; DATA_STORAGE_POLICY).
- No project is added without User approval (GOVERNANCE.md §2, PROJECT_LIFECYCLE.md).

## 2. Fields
| Field | Required | Notes |
|-------|----------|-------|
| **ID** | yes | `P/B/I/S####` (+ `-S##` subproject) |
| **Domain** | yes | Research / Business / Investment / Surplus |
| **Owner** | yes | responsible person |
| **Primary Node** | yes | gpu-01 / gpu-02 / gpu-03 (non-exclusive; also the `/data` node) |
| **Status** | yes | proposed / active / archived / retired |
| **Created** | yes | YYYY-MM-DD |
| **Description** | yes | one-line purpose |

(No `Data-Node` field — Primary Node is where the data lives and is sufficient.)

## 3. Registry
*No projects are registered yet (none created — M3-0 is governance promotion only).*
Add rows below as projects are approved. Example format (illustrative only, not an
active project):

```
| ID                              | Domain   | Owner | Primary Node | Status   | Created    | Description |
|---------------------------------|----------|-------|--------------|----------|------------|-------------|
| P0001_nanopore_modification_ai  | Research | hha   | gpu-01       | proposed | YYYY-MM-DD | Nanopore direct-RNA modification AI (Tier 1 anchor) |
```

| ID | Domain | Owner | Primary Node | Status | Created | Description |
|----|--------|-------|--------------|--------|---------|-------------|
| _(none yet)_ | | | | | | |

## 4. Notes
- Research-internal **Tier** (T1/T2) is tracked in the project's `README.md` /
  `ENVIRONMENT_MANIFEST.md`, not as a registry column (optional, research-only).
- Subprojects (`<ID>-S##`) may be listed as their own rows or noted under the parent.
- **Anticipated first import (M4-2, 20260701-06):** `P0003` (TBI scRNA-seq) is expected to be
  the **first imported project** (PROJECT_LIFECYCLE §4a). The reusable import framework is
  **ready** (`scripts/project-bootstrap import`). **Not yet approved, registered, or
  materialized** — no row is added until the User approves the import (§1; GOVERNANCE §2).
