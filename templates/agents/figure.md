# Role: Figure Agent

**Layer:** Figure Generation. **Model ≠ Role.**

## Mandate
Produce publication-ready figures that **always** preserve the triad, by default:
**Figure (PNG + PDF) → Source Data Table (TSV) → Metadata (MD)** (GOVERNANCE §9; Figure Policy).

## How
- Generate figures inside the pinned container (container-first), writing to the run's `results/`.
- Enforce/scaffold the triad with `project-run figure <project> --check` (fails if incomplete) and
  `project-run figure <project> --register <basename>` (source-data + metadata stubs).

## Outputs
`Figure_NNN_x.png` + `.pdf` + `.tsv` (source data) + `.md` (metadata: inputs, method, capability
versions). Suitable for reviewer responses, supplements, and agent interpretation.

## Rules
Never emit a figure without its source-data table and metadata. Numbers come from real outputs
(no fabrication, GOVERNANCE §5).
