# REFERENCE LAYER

**Status:** CANONICAL from 2026-06-15 (M3-4B, 20260615-01). Realizes M3-4A under
`/data/analysis/reference` (shared NFS) via `analysis-install` + VERSION_GOVERNANCE.
**Default priority: human references** (operator directive 2026-06-15).

---

## 1. Layout (category-first; `analysis-install` kind=reference, group=category)
```
analysis/reference/
├── genome/      <organism>-<assembly>/<release>/        + current
├── annotation/  <db>/<release>/                          + current
├── variation/   <db>/<version>/                          + current
├── index/       <aligner>-<genome>-<annot>/<tool-ver>/   + current   (derived, regenerable)
├── singlecell/  single-cell reference atlases / annotation resources (Azimuth refs, markers)
├── structure/   protein-structure DBs (AlphaFold genetic DBs ~TB-scale) + reference structures
├── model/       foundation/ML model WEIGHTS (AlphaFold, ESM, scVI, CellTypist, Dorado/Remora)
├── nanopore/    Nanopore-specific resources (signal/k-mer models, modification ground-truth)
└── resource/    (misc shared)
```
Read by containerized tools over the shared mount at `/home/hha/analysis/reference`.
The reference layer is a **Common Platform Capability** (project-agnostic, reusable);
see **PLATFORM_ARCHITECTURE.md** for the platform-vs-project model + capability catalog.
`singlecell/`, `structure/`, `model/`, `nanopore/` are materialized on first use
(GOVERNANCE §0); `model/` (e.g. Dorado/Remora) is platform-reusable and **not**
P0001-gated (only study-specific training/ground-truth data is project-bound).

## 2. Deployed assets (M3-4B, 2026-06-15)
| Asset | Path | Version | SHA256 (payload) | Source |
|-------|------|---------|------------------|--------|
| Human genome | `genome/homo_sapiens-GRCh38/` | `gencode-v50` | `b760d18d…f05ca` | GENCODE v50 `GRCh38.primary_assembly.genome.fa.gz` |
| Annotation | `annotation/gencode-human/` | `v50` | `dd6d33ba…396b7` | GENCODE v50 GTF + transcripts FASTA |
| ClinVar | `variation/clinvar/` | `2026-06-06` | `2ef1a453…b50ba` | NCBI ClinVar GRCh38 VCF (+tbi) |
| dbSNP | `variation/dbsnp/` | `b157-GRCh38p14` | `329da439…ccb3d` | NCBI dbSNP build 157, GRCh38.p14 VCF (+tbi) |
| STAR index | `index/star-GRCh38-gencode-v50/` | `2.7.11b-sjdb100` | `49cc0fac…d2a4e` | STAR 2.7.11b genomeGenerate, sjdbOverhang 100 (29 GB) |
| Salmon index | `index/salmon-GRCh38-gencode-v50/` | `2.0.0-k31` | `8dcf267b…df71ae` | salmon 2.0.0 decoy-aware, k=31 (11 GB) |

All registered `--regenerable` (re-downloadable / re-buildable); each version dir has a
`MANIFEST.md` (source + payload SHA256) and a tool `VERSIONS.md`.

## 3. Chromosome-naming caveat (IMPORTANT for downstream use)
The sources use **different contig conventions** — reconcile before intersecting:
- **GENCODE genome + GTF + transcripts:** `chr`-prefixed (`chr1`, `chr2`, …) — internally
  consistent; correct for STAR/Salmon RNA workflows.
- **ClinVar VCF:** `1`, `2`, … (no `chr`).
- **dbSNP VCF:** RefSeq accessions (`NC_000001.11`, …).
When combining a variation DB with the GENCODE-coordinate genome (e.g. A-to-I editing
filtering), **rename contigs** (`bcftools annotate --rename-chrs`) to the `chr`-prefixed
scheme first. Recorded in each variation asset's MANIFEST.

## 4. Versioning & reproducibility
- Version = the source's own release (GENCODE v50, dbSNP build 157, ClinVar fileDate);
  `current` = active default; **projects pin exact versions** in `ENVIRONMENT_MANIFEST.md`
  (never `current`).
- **Index provenance (I4):** each `index/` MANIFEST records the **builder tool+version**
  AND the **source genome+annotation versions** (e.g. STAR 2.7.11b on GRCh38+GENCODE-v50).
- Index build-env pinned: **`infra/rnaseq-buildenv.yml`** (STAR 2.7.11b, salmon 2.0.0).
  *(Build-env is host conda tooling for index generation; RNA pipelines themselves use
  containers per PIPELINE/CONTAINER_STANDARDS.)*

## 5. Backup classification (cluster-backup.sh, updated M3-4B)
`reference/` is **excluded from backup** (bulk is re-downloadable/re-buildable) — the
backup mirrors only small provenance (`MANIFEST.md`/`VERSIONS.md`/`CHECKSUMS.md`).
Excluded (category-first layout, validated): `reference/index/**`, `reference/model/**`,
`reference/**/*.gz` (all genome/transcript/GTF/VCF payloads incl. the bare-`.gz` dbSNP),
`reference/**/*.tbi` — with **`--delete-excluded`** so the destination mirrors only the
precious set (peer `analysis` backup is ~192 KB / 29 files, no bulk). Anything
non-re-downloadable (license-gated, curated, trained custom models) is flagged precious
and backed up explicitly when added.

## 6. Priority / GPU
- Human references serve **both** Tier-1 (Nanopore dRNA — transcriptome/genome) and
  Tier-2 (A-to-I editing — genome + variation DBs). CPU assets.
- **Deferred (need P0001 scoping):** Tier-1 GPU model assets — Dorado basecalling +
  Remora modification models + modification ground-truth (`model/`, `nanopore/`).
- **Not assumed:** other species/DBs (added only when an approved project needs them).
