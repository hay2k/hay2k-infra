# 20260617-02 — M3-4D follow-up: Runtime Utility Exposure Layer

**Date:** 2026-06-17
**Role:** User (operator `hha`) → execution
**Goal:** General-purpose runtime utilities should behave like normal Linux commands
immediately after login — operator must NOT need `conda activate bio` to use
bat/eza/fd/rg/fzf/btop/jq/yq/tree/pv/parallel.

**Requirements:** keep `bio` the single source of truth (no duplicate installs, no parallel
package management; still managed via bio-environment.yml); build a clean exposure layer
(~/.local/bin symlinks / managed PATH / equivalent); expose ONLY the 11 general-purpose
utilities; do NOT expose bioinformatics tools (samtools/bcftools/bedtools/seqkit/csvtk —
remain bio/container/pipeline only); verify on gpu-01/02/03; update RUNTIME_TOOLS.md +
RUNTIME_FOUNDATION.md + affected docs; document the operator-vs-scientific distinction
explicitly; deliver A) implementation details B) exposure mechanism C) PATH strategy
D) validation E) rollback; also review further operator-utility additions.

**Outcome:** per-node `~/.local/bin` symlinks to the `bio` env via new
`scripts/expose-runtime-utils.sh` (idempotent, allow/deny lists, `--remove`). All 3 nodes
validated PASS from a fresh login shell. Docs updated. Candidate additions
(ncdu/dust/duf/tmux/delta/glow) reviewed as a recommendation (not installed).
