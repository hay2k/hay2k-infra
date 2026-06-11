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

**Reserved (NOT created yet):** `analysis/` (**Research**), `business/`
(**Business**), `investment/` (**Investment**), `surplus/` (**Surplus**),
`resources/`. Domains are priority/accounting groupings under **Research > Business >
Investment > Surplus** on shared infrastructure (GOVERNANCE.md §1); **Surplus** =
low-priority use of idle capacity. Primary nodes (non-exclusive): Research→gpu-01,
Business→gpu-02, Investment/Surplus→gpu-03. (The former `runtime` domain is
superseded — see GOVERNANCE.md §1.)

These five names are the approved namespace. They are reserved so nothing else
claims them, but they are **not materialized as empty directories**. Creating
an empty domain dir before it has content is the exact speculative structure
this standard forbids. Each is created at the moment its first approved content
arrives (a domain dir is created together with its first approved project;
`resources/` is created with its first genuinely shared asset).

**Research domain layout — `analysis/` (operator decisions 20260604-02/-03).** The
research domain is realized as `analysis/` — **not** `research/`, which is not
used — with a fixed four-part internal structure (full architecture, including the
pipeline/container sub-hierarchies and the version policy, in
**ANALYSIS_ARCHITECTURE.md**):

```
analysis/
├── pipeline/    # reusable workflows, versioned: {nextflow,snakemake,custom}/<tool>/<version>/ + current symlink
├── container/   # execution environments, versioned: {apptainer,docker}/<env>/<version>/ + current symlink
├── reference/   # reference assets shared across research projects (genomes, indices, annotations)
└── projects/    # individual research projects; each a standard project tree (§3): analysis/projects/<project>/
```

- `analysis/projects/<project>/` follows the standard project shape (§3).
- `pipeline/`, `container/`, and `reference/` are **research-domain-shared**, not
  cross-domain. An asset shared by ≥2 *domains* still belongs in `resources/` (§4);
  research-only shared assets stay here (avoid duplicated purpose, §4). This
  **overrides** the prior expectation (ENVIRONMENT_POLICY.md §4) that research
  `.sif` images live in `resources/` — research containers live in
  `analysis/container/`.
- Installed pipelines/containers are **version-managed** (version-named dirs +
  `current` symlink, projects pin exact versions, no silent upgrades); see the §5
  exception and ANALYSIS_ARCHITECTURE.md.
- Like every domain dir, `analysis/` and its subdirs materialize **when their
  first content arrives**, never as empty scaffolding (GOVERNANCE.md §0).
- **Storage placement (decided 20260604-04):** the **entire** `analysis/`
  hierarchy (`pipeline/`, `container/`, `reference/`, `projects/`) lives on
  **shared NFS storage**, presented at `/home/hha/analysis` on every node
  (`/home/hha` itself is per-node). Deployed in M2 (ANALYSIS_ARCHITECTURE.md §5).

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
- **Per-project version control (20260605-03).** Each project is its **own git
  repo with an off-host remote** (GitHub, mirroring `infra`), satisfying the
  code-in-VCS + off-host-durability requirement (GOVERNANCE.md §4) — the on-cluster
  backup is not off-site. `.gitignore` the NFS-resident regenerables and large data
  (built `.sif`, materialized venvs, datasets, caches). For research projects under
  `analysis/projects/<project>/` see ANALYSIS_ARCHITECTURE.md §7.2.

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
- No spaces, no dates-as-versions in directory names (`v2`, `final` → use VCS)
  for **first-party source code and projects**.
- **Exception — installed external pipelines/containers/references**
  (`analysis/pipeline/`, `analysis/container/`, `analysis/reference/`):
  version-named directories (e.g. `3.21/`, `2.9-cuda13/`, `ensembl-110/`) are
  **required**, each with a `current` symlink to the active version. These are
  installed/fetched third-party artifacts that must coexist in multiple versions and
  be pinned per project — not first-party code under VCS — so the prohibition above
  does not apply (ANALYSIS_ARCHITECTURE.md; operator decisions 20260604-03,
  20260605-03 added `reference/`).

## 6. Directories within vs. outside this standard

- **Within the standard** (the project shape in §3, a reserved domain dir, a
  clearly-needed subdirectory): create it when **necessary** and document it.
  No approval overhead (GOVERNANCE.md §0). Unnecessary or speculative
  directories remain prohibited.
- **Outside the standard** (a *new top-level* directory, or a special-purpose
  structure that changes the namespace): requires **User approval**
  (GOVERNANCE.md §2). Try to fit the need into the standard shape first; escalate
  only if it genuinely does not fit.

## 7. `ChatGPT_handoff/` — handoff artifacts (User-approved exception)

A single **non-domain** top-level directory, approved by the User on 2026-06-04
(20260604-01), for persisting handoff-worthy session outputs (the operating rule
is GOVERNANCE.md §12).

```
/home/hha/
└── ChatGPT_handoff/           # operational output store (NOT a work domain)
    ├── README.md              # static convention doc — NOT modified on save; no artifact index
    └── YYYY-MM-DD_<title>.md  # one self-contained Markdown file per artifact
```

- **Not a domain.** It holds no project code and is exempt from the project
  shape (§3) and domain rules (GOVERNANCE.md §1). It is an operational sink for
  documents, not a place to develop work.
- **Contents:** assessments, milestone completions, implementation/architecture
  reviews, research/planning docs, handoff notes — each a self-contained Markdown
  file with YAML front-matter (`title`, `type`, `status`, `date`, `author`,
  `source_prompt`, `governance_refs`).
- **Subdirectories** are created **as needed** (e.g. by topic or month) when
  volume warrants — never pre-created as empty trees (GOVERNANCE.md §0).
- **`README.md` is static.** New artifacts are added **only as new files**; the
  README is not edited on save and maintains **no index** (GOVERNANCE.md §12;
  operator decision 20260604-02).
- **Naming exception:** the literal name `ChatGPT_handoff` (mixed-case +
  underscore) was set by the operator and is an explicit, documented exception to
  the lowercase-hyphen rule (§5); honored as-is. New artifact *files* still follow
  the `YYYY-MM-DD_<kebab-title>.md` convention.
