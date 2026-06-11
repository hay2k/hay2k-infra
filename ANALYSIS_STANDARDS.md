# ANALYSIS STANDARDS (research domain)

**Status:** CANONICAL from 2026-06-06 (promoted M3-0, 20260606-01). Supersedes the
M2-2 draft in `ChatGPT_handoff/`.
**Scope:** Umbrella standard for the **Research** domain (the `analysis/` tree).
Indexes the companion canonical policies: PROJECT_ID_POLICY, DATA_STORAGE_POLICY,
VERSION_GOVERNANCE, PROJECT_REGISTRY. Builds on the frozen ANALYSIS_ARCHITECTURE.md.

---

## 1. Domain context (priority model)
The cluster is **shared infrastructure** governed by a **priority hierarchy**:
**Research > Business > Investment > Surplus** (GOVERNANCE.md §1). Domains denote
**primary responsibility / preferred placement / accounting grouping — not physical
isolation and not exclusive ownership.** Research is the **highest-priority** domain;
its **primary node is gpu-01** but placement is **non-exclusive** — research may
consume idle resources on any node and is never capped to gpu-01.

This document governs **Research** (`analysis/`). Business/Investment/Surplus have
their own domain trees and the same structural conventions.

## 2. Frozen decisions
- **Namespace:** Research is realized as `analysis/` (shared NFS, M2-1, all nodes):
  `analysis/{pipeline, container, reference, projects}`.
- **Entry point:** `<name>/current` for every versioned pipeline/container/reference
  (VERSION_GOVERNANCE).
- **Containers:** Docker image = canonical source; Apptainer `.sif` = derived
  runtime; no Docker daemon. First family = **pytorch**.
- **Project-centric storage:** code/assets in `analysis/projects/<ID>/` (shared NFS);
  large data in `/data/<ID>/` (per-node local on the project's Primary Node);
  access via `analysis/projects/<ID>/data -> /data/<ID>` (DATA_STORAGE_POLICY).
- **Identifiers:** domain-prefixed master ID — Research = `P####_name`, subprojects
  `P####-S##` (PROJECT_ID_POLICY).
- **Registry:** every project is recorded in **PROJECT_REGISTRY.md** (mandatory).
- **Tiers:** research-internal **T1** (Nanopore direct-RNA modification AI) > **T2**
  (pan-cancer A-to-I editing), nested **under** the domain priority.

## 3. Standard project shape
```
analysis/projects/P0001_nanopore_modification_ai/
├── README.md                  # ID, domain, tier, owner, status, created
├── ENVIRONMENT_MANIFEST.md     # pinned pipeline+container+reference versions, Primary Node, seeds, GPU/VRAM
├── src/  results/  prompts/
├── data -> /data/P0001_nanopore_modification_ai   # → node-local large data
└── (own git repo + GitHub remote; .gitignore data/ + regenerables)
```

## 4. Examples
- T1: `analysis/projects/P0001_nanopore_modification_ai/` + `/data/P0001_nanopore_modification_ai/`.
- T2: `analysis/projects/P0002_a_to_i_editing/` + `/data/P0002_a_to_i_editing/`.
- A result cites: code commit · `pipeline=<engine>/<tool>/<ver>` ·
  `container=apptainer/pytorch/<ver>`+SHA256 · `reference=<...>/<ver>` · Primary Node
  · seed (GOVERNANCE §4).

## 5. Future scalability
- Projects scale by ID; PROJECT_REGISTRY is the index of record.
- Code stays on shared NFS; data scales on local `/data` (DATA_STORAGE_POLICY) with
  node-affinity managed via Primary Node.
- New domains/programs are introduced explicitly by the operator (GOVERNANCE §0); no
  speculative tiers or domains.
