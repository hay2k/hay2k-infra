# 20260615-01 — M3-4B: reference layer — human references + RNA indexes

**Date:** 2026-06-15
**Role:** User (operator `hha`) → reference priority directive + M3-4B execution
**Decisions captured (via AskUserQuestion):** execute M3-4B now; source = GENCODE +
GRCh38 primary.
**Outcome:** Registered (version-governed, pinned, checksummed, --regenerable) under
`/data/analysis/reference`: genome `homo_sapiens-GRCh38/gencode-v50`,
`annotation/gencode-human/v50`, `variation/clinvar/2026-06-06`,
`variation/dbsnp/b157-GRCh38p14`, `index/star-GRCh38-gencode-v50/2.7.11b-sjdb100`,
`index/salmon-GRCh38-gencode-v50/2.0.0-k31`. Created REFERENCE_LAYER.md +
rnaseq-buildenv.yml; fixed cluster-backup.sh reference excludes. Nanopore model assets
deferred (need P0001). ~68 GB footprint.

---

## Verbatim prompt

> Human references are the default priority.
>
> Install and version: GRCh38, GENCODE, dbSNP, ClinVar before any Nanopore model assets.
>
> STAR and Salmon indexes should be treated as near-term assets rather than future
> assets due to planned RNA workflows.
