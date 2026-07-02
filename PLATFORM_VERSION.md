# PLATFORM VERSION

## Platform v1.0 — FROZEN 2026-07-02 (20260702-02)

The reusable, project-independent platform is complete and **frozen** at v1.0. The first research
projects (**P0001** Nanopore direct-RNA AI, **P0002** RNA editing, **P0003** TBI scRNA-seq via
knowledge transfer) begin on **this** version. The platform is **not** specialized for any of them.

**Freeze policy.** During active projects, do not change v1.0. New/changed capabilities and
governance land as **v1.1+** (VERSION_GOVERNANCE.md): new capability *versions* register normally
(projects opt in by re-pinning); doc/CLI changes bump the platform minor version and are recorded
here. Emergency fixes are the only in-place exception and must be logged.

**Git tag:** `platform-v1.0` at the commit recording this file.

---

### Frozen components

**Constitution & governance (canonical `infra/*.md`)**
PLATFORM_CONSTITUTION · GOVERNANCE (incl. §3b autonomous execution) · PLATFORM_ARCHITECTURE ·
PLATFORM_REUSE_POLICY (M4 core principle) · PROJECT_LIFECYCLE (incl. §4a import + knowledge
transfer) · DIRECTORY_STANDARD · VERSION_GOVERNANCE · ENVIRONMENT_POLICY · CONTAINER_STANDARDS ·
PIPELINE_STANDARDS · REFERENCE_LAYER · RESOURCE_POLICY (incl. §6a acceleration/aria2) ·
AGENT_ARCHITECTURE · AGENT_WORKFLOW_STANDARD · AGENT_RUNTIME · PROJECT_SPECIFICATION_POLICY ·
PROJECT_ID_POLICY · PROJECT_REGISTRY · DATA_STORAGE_POLICY · SECRETS_POLICY · others per repo.

**Platform CLI (`infra/scripts/`)**
`analysis-install` (version mgmt + **discovery**: catalog/describe/metadata) ·
`project-bootstrap` (create · import · **kt-init**) · `project-run` (execution framework) ·
`expose-runtime-utils.sh` · `cluster-backup.sh` / `cluster-restore.sh`.

**Reusable frameworks (`infra/templates/`)**
`project/` (canonical-file templates) · `knowledge_transfer/` (01–08 + Attachments; project-
independent) · `agents/` (role library: supervisor, knowledge, reference, analysis, figure,
writing, validation + orchestration).

**Runtime foundation**
miniforge `bio` (all nodes) + login-exposed utilities; Apptainer 1.5.0; Nextflow 26.04.3 (JDK 21).

**Platform capabilities (current @ freeze — projects pin exact versions, never `current`)**
```
container/apptainer/pytorch/2.9.1-cuda13.0            accel=both
container/apptainer/ml/2.9.1-cuda13.0                 accel=both
container/apptainer/bioconductor/bioc3.21             accel=cpu
container/apptainer/longread/2026-06-17               accel=cpu
container/apptainer/dorado/2.0.1-cuda13.0             accel=both   (Tier-1 anchor)
container/apptainer/scanpy/2026-06-24                 accel=cpu    (incl. CellTypist)
container/apptainer/scvi-tools/2026-06-18-cuda13.0    accel=both
container/apptainer/seurat/2026-06-18                 accel=cpu
pipeline/nextflow/rnaseq/3.26.0                       accel=cpu
pipeline/nextflow/scrnaseq/4.1.0                      accel=cpu
pipeline/custom/runtime-smoke/0.1                     accel=both
reference/genome/homo_sapiens-GRCh38/gencode-v50
reference/annotation/gencode-human/v50
reference/index/star-GRCh38-gencode-v50/2.7.11b-sjdb100
reference/index/salmon-GRCh38-gencode-v50/2.0.0-k31
reference/variation/clinvar/2026-06-06
reference/variation/dbsnp/b157-GRCh38p14
reference/model/  ·  reference/singlecell/           (scaffolds; populated on first project use)
```
Live source of truth: `ANALYSIS_ROOT=/data/analysis analysis-install catalog`.

### Deferred (post-v1.0, when a project requires — not part of v1.0)
VEP/SnpEff (variant annotation) · Structure-AI (AlphaFold/ESM/Chai/Boltz + DBs) · nf-core/sarek
(somatic) · Dorado/Remora model weights · single-cell reference atlases. Business/Investment/
Surplus domains consume the same platform when activated (no architecture change).

---

## v1.1+ changelog
_(none yet — record post-freeze platform changes here; INFRA_CHANGELOG.md has full detail.)_
