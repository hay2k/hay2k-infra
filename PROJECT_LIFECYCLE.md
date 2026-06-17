# PROJECT LIFECYCLE

**Status:** Active from 2026-06-01 (created by governance correction 20260601-02)
**Scope:** How projects come into existence, move, and retire. This is where the
*remaining* User-approval gates live after the 20260601-02 correction.

---

## 1. Why these gates remain (and most others were relaxed)

The 20260601-02 correction removed approval overhead from *necessary
infrastructure work* — installing pre-approved tools, creating necessary
directories, evolving the infrastructure (GOVERNANCE.md §0). **Project lifecycle
events are different:** they claim resources, define scope, cross domain
boundaries, or destroy data. Those are genuinely high-impact and stay
**User-approved**. The correction narrowed bureaucracy; it did not open the
project gates.

## 2. Lifecycle states

```
(proposed) ──approve──▶ active ──┬──▶ archived ──┐
                                 │               │
                                 └──▶ retired ───┴──▶ (deleted, only on explicit User approval)
```

- **proposed** — a Supervisor has scoped a project and recommends it. No
  directory exists yet.
- **active** — User-approved; the domain dir (if first) and the project tree
  (DIRECTORY_STANDARD.md §3) are materialized by the Supervisor.
- **archived** — read-only, retained for reproducibility; no further work.
- **retired** — slated for removal; data may still exist.
- **deleted** — irreversible; only on explicit User approval.

## 3. Approval gates (User-only)

| Event | Approver | Notes |
|-------|----------|-------|
| Create a project (proposed → active) | **User** | New scope + resource claim |
| Retire a project (active → retired) | **User** | Stops work; precedes deletion |
| Delete project data not regenerable from VCS | **User** | Irreversible (GOVERNANCE.md §2) |
| Cross-domain migration (move/copy between domains) | **User** | Breaks domain independence (GOVERNANCE.md §1) |

**The approval applies to the project itself, not to the directory operation.**
`research/project_x`, `business/product_y`, and `investment/strategy_z` each
require the *project* to be approved before creation — but once it is, making
the directories is routine work, not a second approval. Conversely, no agent
may create a project directory in anticipation of approval (that is a
placeholder project / empty organizational tree, prohibited by GOVERNANCE.md
§0).

What does **not** need approval (just documented): once a project is approved,
the Domain Orchestrator materializing the project's directories (and the reserved
domain dir for the domain's first project), archiving an inactive project in
place, and routine in-project work.

## 4. Creation procedure

1. A Supervisor scopes the project and escalates a **decision request with a
   recommendation** (AGENT_ARCHITECTURE.md §3) to the User. The scope **must include a
   completed Capability Resolution** (PLATFORM_REUSE_POLICY.md §2): existing platform
   pipelines/containers/references/models are evaluated **first** (Reuse-First); any
   **new** platform capability is justified and proposed/built **separately and
   project-agnostically** before the project consumes it.
2. On approval, the domain's Domain Orchestrator materializes the domain dir if it is
   the domain's first project, then the project tree (DIRECTORY_STANDARD.md §3).
3. The project records `README.md` (name, owner, status, created date, approving
   prompt ID — GOVERNANCE.md §8), **`PROJECT_MASTER.md`** (authoritative spec /
   source of truth) + `TODO.md` (PROJECT_SPECIFICATION_POLICY.md), **and
   `ENVIRONMENT_MANIFEST.md`** declaring its **pinned** capability dependencies
   (pipeline/container/reference/model) + the Capability Resolution record (template:
   `infra/templates/project/ENVIRONMENT_MANIFEST.md`; PLATFORM_REUSE_POLICY.md §5).
4. The creation is recorded in INFRA_CHANGELOG.md if it changes infrastructure
   structure (a new domain dir), otherwise in the project's own record.

## 5. Retirement procedure

1. Supervisor escalates a retirement recommendation to the User.
2. On approval, the project moves to **archived** or **retired**; data is **not
   deleted** by retirement alone.
3. Deletion of non-regenerable data is a **separate** User approval (§3).
4. Reproducibility obligations (GOVERNANCE.md §4) persist for archived
   projects: code commit, environment manifest, data hashes, and prompt IDs
   remain available.

## 6. Cross-domain migration

Moving or copying code, data, or models between domains requires **User
approval** (GOVERNANCE.md §1, §2). It is logged in INFRA_CHANGELOG.md because it
changes which domain owns an asset.
