# DIRECTORY STANDARD

**Status:** Active from 2026-06-01 (refined 20260601-03)
**Principle (GOVERNANCE.md §0):** *Create what is required. Avoid what is not
required.* Minimalism first. Prohibited: **unnecessary directories**,
**duplicate directory purposes**, **speculative future structures**, **empty
organizational trees**, and **placeholder projects**. But a **necessary**
directory (one with a clear, current purpose) is created when needed and simply
documented — it does **not** require approval.

---

## 1. Workspace root

```
/home/hha/                  # workspace root; the six domains are direct children
```

The **version-controlled infrastructure root** is `/home/hha/infra` (a git
repo). Work domains, when created, are siblings of `infra/` and carry their own
version control rather than sharing infra's history.

## 2. What exists today vs. what is reserved

Only directories with a present purpose are created. At bootstrap, the only
present purpose is governance, so only `infra/` exists.

```
/home/hha/
└── infra/                  # EXISTS — governance + prompts (git repo)
    ├── *.md                # the six governance documents
    ├── .gitignore          # conservative ignore (secrets, caches, data, weights, ...)
    └── prompts/            # versioned prompt archive (YYYYMMDD-NN_name.md)
```

**Reserved (NOT created yet):** `research/`, `business/`, `investment/`,
`runtime/`, `resources/`.

These five names are the approved namespace. They are reserved so nothing else
claims them, but they are **not materialized as empty directories**. Creating
an empty domain dir before it has content is the exact speculative structure
this standard forbids. Each is created at the moment its first approved content
arrives (a domain dir is created together with its first approved project;
`resources/` is created with its first genuinely shared asset).

> **Why not pre-create all six?** Empty scaffolding invites cargo-cult
> placement ("a folder exists, so put something in it") and is speculative
> structure (prohibited, GOVERNANCE.md §0). A reserved domain dir is
> materialized by its Supervisor together with its first **approved** project
> — the approval lives at the *project* level (PROJECT_LIFECYCLE.md), not on
> the act of making the directory.

## 3. Domain-internal layout (the standard project shape)

When the User approves the first project in a domain, the domain dir is created
and projects live one level down. Every project uses the **same minimal shape**
so the structure is predictable across all domains:

```
<domain>/
└── <project>/
    ├── README.md           # what it is, owner, status, created date
    ├── src/                # code (version-controlled)
    ├── data/               # project-local inputs/outputs (see §4 for shared)
    ├── results/            # generated artifacts; figures as PNG + PDF
    └── prompts/            # project-significant prompts (same naming as infra)
```

Rules:

- **Do not** add `notes/`, `tmp/`, `misc/`, `old/`, `scratch/`, `final/`,
  `final_v2/` and similar. Use version control for history; use `results/` for
  outputs. These catch-all dirs are the most common sprawl and are prohibited.
- A subdirectory is added only when a project clearly needs it now (e.g. a
  `models/` cache that is genuinely project-local). Adding a directory is a
  documented decision (GOVERNANCE.md §10).
- The shape above is a *standard*, not a mandate to create every folder: omit
  any of `src/`/`data/`/`results/`/`prompts/` that a given project does not
  yet need.

## 4. `resources` vs. domain-local data (avoiding duplicated purpose)

There is a real risk of two directories meaning the same thing. The rule:

- **`resources/`** holds assets that are *domain-agnostic and shared by 2+
  domains*: base model weights, public datasets, citation library exports,
  fonts, license files, and **shared container images (`*.sif`) / image caches**
  (ENVIRONMENT_POLICY.md §4). It is created only when such a genuinely shared
  asset first exists. Environment *definitions* and *lockfiles* (`*.def`,
  `uv.lock`, etc.) stay project-local and version-controlled, not here.
- **`<domain>/<project>/data/`** holds assets *specific to one project*.

Test: *"Would deleting this break more than one domain?"* If yes → `resources`.
If no → it is project-local. An asset is never stored in both places; consumers
reference the `resources` copy read-only. Large shared model/dataset caches are
covered by RESOURCE_POLICY.md.

## 5. Naming

- Lowercase, hyphen-separated for project and directory names
  (`protein-folding`, not `Protein_Folding`).
- Prompt files only: `YYYYMMDD-NN_name.md` (GOVERNANCE.md §8).
- No spaces, no dates-as-versions in directory names (`v2`, `final` → use VCS).

## 6. Directories within vs. outside this standard

- **Within the standard** (the project shape in §3, a reserved domain dir, a
  clearly-needed subdirectory): create it when **necessary** and document it.
  No approval overhead (GOVERNANCE.md §0). Unnecessary or speculative
  directories remain prohibited.
- **Outside the standard** (a *new top-level* directory, or a special-purpose
  structure that changes the namespace): requires **User approval**
  (GOVERNANCE.md §2). Try to fit the need into the standard shape first; escalate
  only if it genuinely does not fit.
