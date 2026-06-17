# 20260617-01 — M3-4D: Wave 1 platform deployment + runtime tooling

**Date:** 2026-06-17
**Role:** User (operator `hha`) → execution (Wave 1)
**Outcome:** Installed host tools (bat/eza/fd/fzf/btop/tree/pv) into `bio` on all 3 nodes;
created RUNTIME_TOOLS.md; built+registered+validated 3 reference-free platform containers
(ml GPU, longread CPU, bioconductor CPU) via analysis-install with pinned-digest bases +
.def recipes. Evaluated somatic (→ nf-core/sarek pipeline-first, not a mega-container due
to Py2/3 conflicts) and Dorado (→ separate GPU container + models, deferred to Wave 2).
Deferred: AlphaFold/ESM/Chai/Boltz, gnomAD/VEP caches, single-cell stack. Cross-node
validated. Container store 8 GB.

(Full verbatim brief in the M3-4D task message: Part A runtime tooling; Part B RUNTIME_TOOLS;
Part C containers bioconductor/longread/somatic/ml; defers; validation; deliverable.)
