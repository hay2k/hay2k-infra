# RECONSTRUCTION — {{PROJECT_ID}} ({{PROJECT_NAME}})

Import reconstruction checklist (PROJECT_LIFECYCLE.md §4a). **Goal: reproducible
reconstruction on the current platform, not file migration.** Prior materials in `docs/` are
**reference only**; the authoritative result is what is re-derived here on-platform.

- **Source environment:** {{SOURCE}}
- **Imported:** {{DATE}}   **Approving prompt:** {{PROMPT_ID}}

## Step 1 — Inventory preserved materials (reference only)
- [ ] docs/proposal/   — proposal / grant / planning
- [ ] docs/handoff/    — prior handoff records
- [ ] docs/protocol/   — prior protocols / SOPs / methods
- [ ] docs/literature/ — references (re-enter into Zotero; citekeys only, GOVERNANCE §7)
- [ ] docs/meeting/    — prior decisions

## Step 2 — Capability Resolution (Reuse-First → ENVIRONMENT_MANIFEST.md)
Map the legacy environment onto **shared platform capabilities** — do NOT rehost legacy tooling verbatim.
- [ ] `ANALYSIS_ROOT=/data/analysis analysis-install catalog` — find existing pipelines/containers/references
- [ ] Pin exact versions in ENVIRONMENT_MANIFEST.md (containers by sha256)
- [ ] Gaps → extend (new version) or propose a new shared capability (User-approved), never a project fork

## Step 3 — Author current canonical files (from docs/ as source input)
- [ ] PROJECT_MASTER.md (objective, method = reconstruction plan)
- [ ] TODO.md
- [ ] project configs under src/

## Step 4 — Reconstruct & execute on-platform (container-first, pipeline-driven)
- [ ] Stage raw data → /data/{{PROJECT_ID}}/ (content hashes recorded, GOVERNANCE §6)
- [ ] Run via pinned pipeline/containers
- [ ] Re-derive prior key results (do not report legacy outputs as final until re-derived)

## Step 5 — Validate (GOVERNANCE §4)
- [ ] Reproducibility tuple: code commit, env manifest, data hashes, seeds
- [ ] Compare reconstructed vs prior results; document differences
