# ENVIRONMENT_MANIFEST — <PROJECT_ID> (e.g. P0001_short_name)

Template (infra/templates/project/). Copy into `analysis/projects/<ID>/` and fill in.
Records the **pinned platform dependencies** a result depends on (reproducibility,
GOVERNANCE §4) and the **Capability Resolution** (Reuse-First, PLATFORM_REUSE_POLICY).
Pin **exact versions** — never `current`. **Reuse before proposing new.**

## Identity
- project_id:        <P/B/I/S####_short_name>
- domain:            <Research|Business|Investment|Surplus>
- owner:             <person>
- primary_node:      <gpu-01|gpu-02|gpu-03>   # also where /data/<ID> raw data lives
- created:           <YYYY-MM-DD>

## Capability dependencies (PINNED — consumed, not redefined)
### Pipelines
- <engine>/<tool>/<version>            # e.g. nextflow/nf-core-rnaseq/3.21   (REUSE)
### Containers
- apptainer/<env>/<version>  sha256:<…>  # e.g. apptainer/bioconductor/<ver>  (REUSE)
### References
- <category>/<name>/<version>          # e.g. genome/homo_sapiens-GRCh38/gencode-v50  (REUSE)
- <category>/<name>/<version>          # e.g. index/star-GRCh38-gencode-v50/2.7.11b-sjdb100
### Models
- model/<name>/<version>               # e.g. model/<dorado-model>/<ver>   (REUSE) — if any

## Capability Resolution (Reuse-First — PLATFORM_REUSE_POLICY §2)
- searched:   `analysis-install list pipeline|container|reference` + PLATFORM_ARCHITECTURE catalog on <date>
- reused:     <list the existing capabilities pinned above>
- extended:   <existing capability → new version, if any> — justification: <gap>
- new:        <proposed new platform capability, if any> — justification: <why reuse/extend insufficient>
              (NB: a NEW capability is a platform addition — proposed + built project-agnostically, then pinned here)

## Reproducibility tuple (GOVERNANCE §4)
- code_commit:   <git sha of analysis/projects/<ID>>
- seeds:         <RNG seeds>
- gpu/vram:      <e.g. 1× RTX 6000 Ada / 48 GB>  | accel: <cpu|gpu>
- data:          /data/<ID>/  (raw inputs; content hashes/source recorded)
