# ENVIRONMENT POLICY

**Status:** Active from 2026-06-01 (created by 20260601-05)
**Scope:** How software environments are built, pinned, stored, and chosen,
so every result is reproducible (GOVERNANCE.md §4) on a clean host.
**Implementation status (20260601-15):** **uv** (SHA256-verified) + managed
**CPython 3.12.13** + **Snakemake 9.22.0** + **Nextflow 26.04.3** (on a verified
**Temurin JDK 21**) are now **installed on `gpu-01`** (user-space; see
IMPLEMENTATION_LOG.md). Apptainer and execution backends (Slurm) remain **not
installed** (root/approval required). Nextflow needs `JAVA_HOME=~/.local/jdk-21`.

---

## 0. Operating principle (given)

> **Containers first. Workflow engines first. Conda only as fallback.
> System packages only for foundational utilities or approved infrastructure.**

The layered default, in order of preference:

1. **Container** (Apptainer/SIF) for a reproducible, shareable, GPU/system-level
   environment — the unit of archival reproducibility.
2. **Workflow engine** (Snakemake default; Nextflow for nf-core/scale) for any
   multi-step pipeline — it orchestrates *containerized* steps.
3. **uv** for project-local Python dependencies with a committed lockfile — the
   everyday Python default (used standalone or layered inside a container).
4. **Conda/Mamba** only as a fallback for conda-only packages that cannot be
   containerized cleanly, and then with a committed lock.
5. **System packages** only for foundational utilities or approved
   infrastructure — never for project dependencies.

## 1. Tool evaluation

| Tool | Role | Verdict | Install risk (GOVERNANCE.md §2) |
|------|------|---------|---------------------------------|
| **Apptainer / SIF** | Rootless, daemonless container runtime; single-file immutable `.sif` images; HPC/multi-user friendly; GPU via `--nv` | **Primary container runtime.** Single-file images are trivially SHA256-checksummed and archived; no root daemon. | **High-risk §2.3 → User approval** (listed) |
| **Docker** | Daemon-based containers (root daemon), large ecosystem | **Not default.** Root daemon = shared attack surface, poor multi-user fit. Apptainer can pull/convert Docker images, so Docker is rarely needed. Use only for a specific need (e.g. `compose` services). | **High-risk §2.3 → User approval** (listed) |
| **Conda / Mamba** | Cross-language package/env manager | **Fallback only.** Solver drift hurts reproducibility unless `conda-lock` is used; heavyweight base env with multi-user impact. | **Medium-risk → Supervisor judgment + documentation** (ratified 20260601-06) |
| **uv** | Fast Python project/dependency manager; `uv.lock`; single static binary | **Default Python env tool.** Reproducible locked venvs; meets all five §2.1 low-risk characteristics (CLI / single-host / no daemon / no listener / easily removable). | **Low-risk §2.1 → pre-approved** (ratified into the canonical §2.1 list 20260601-06) |
| **System packages** (dnf/rpm) | OS-level libraries/tools | **Foundational only.** Needs root, affects all domains, hurts reproducibility. Not for project deps. | Foundational set pre-approved; anything else system-level → **User approval** |
| **Nextflow** | Dataflow workflow engine (JVM); nf-core ecosystem; scheduler/cloud integration | **Secondary workflow engine.** Choose when you need nf-core or heavy scaling. | **Medium-risk → Supervisor judgment** (ratified 20260601-06). The engine itself is not high-risk; its **shared execution backend** (Slurm, Kubernetes, Seqera/Nextflow Tower) **remains High-risk §2.3 → User approval**. |
| **Snakemake** | Python-native workflow engine (`Snakefile`); integrates with conda/containers | **Default workflow engine.** Lighter, Pythonic, pairs with uv/containers; usually installed *project-local* as a pip/uv dependency. | Project-local dependency → **none**; global install → **medium-risk (Supervisor)**. Shared backends remain high-risk §2.3. |

## 2. What is installed GLOBALLY (shared, minimal, version-logged)

Global means a *tool* shared across domains — never a project's dependencies.

- Foundational utilities (GOVERNANCE.md §2.1) and toolchain (compilers/build
  tools) as needed; the NVIDIA driver + CUDA userspace at system level (it
  underpins all GPU work).
- The chosen **container runtime (Apptainer)** — global, once User-approved.
- **uv** — global, low-risk; the standard Python env tool.
- Optionally a **workflow engine** if used across projects; otherwise prefer
  project-local Snakemake.

Each global install is version-logged (§6) and recorded in INFRA_CHANGELOG.md.

## 3. What is PROJECT-LOCAL

A project's actual environment **definitions and lockfiles** (all text,
version-controlled in the project):

- `*.def` (Apptainer definition) and/or the pinned image reference + its SHA256.
- `pyproject.toml` + **`uv.lock`** (Python deps).
- `environment.yml` + `conda-lock.yml` (only if conda fallback is used).
- `Snakefile` / `main.nf` (workflow definition).
- A per-project environment manifest (§6) recording tool/image versions and
  hardware assumptions.

Project-local = reproducible *recipe*, committed. The built artifacts (images,
materialized venvs) are NOT committed (§4, §5).

## 4. What belongs in `/home/hha/resources`

Large, shared, domain-agnostic **binary** environment artifacts (regenerable
from their committed definitions, so excluded from git — `.gitignore`):

- Built **container images** (`*.sif`) shared by ≥2 projects/domains, each with
  a recorded SHA256 sidecar/manifest.
- A shared **image/layer cache** and shared base images.
- Shared base model weights / public datasets (as already governed,
  DIRECTORY_STANDARD.md §4).

`resources/` is created when the **first** genuinely shared asset exists
(likely the first shared `.sif`) — not pre-created (GOVERNANCE.md §0).
Single-project images stay project-local or, if large, are treated as
regenerable build output.

## 5. What belongs in PROJECT DIRECTORIES

- All of §3 (the committed definitions, lockfiles, manifests).
- Small project-specific inputs/outputs per DIRECTORY_STANDARD.md §3.
- **Not** built images, materialized venvs, conda pkg caches, or datasets —
  those are regenerable (`.gitignore`) or shared (`resources/`). A project
  references a `resources/` image read-only by path + SHA256.

## 6. SHA256 & version logging (reproducibility)

- **Images:** pin by digest, not mutable tag (e.g. `docker://repo/img@sha256:…`).
  Record the `.sif` SHA256 in a sidecar/manifest (GOVERNANCE.md §6). A mismatch
  is a hard stop.
- **Lockfiles:** `uv.lock` / `conda-lock.yml` pin exact versions + hashes; they
  are committed and are the source of truth for rebuilds.
- **Tool/host versions:** record `apptainer --version`, `uv --version`, engine
  version, and CUDA/driver versions in the project environment manifest, plus
  GPU count/VRAM assumptions (GOVERNANCE.md §4.6).
- **Downloads:** any base image/installer pulled onto the host is SHA256-verified
  or hash-recorded before use (GOVERNANCE.md §6).
- A result is reproducible only if it can state: code commit, image digest +
  SHA256, lockfile, seed, and hardware assumptions (GOVERNANCE.md §4).

## 7. How Claude Code chooses: container vs. conda vs. system package

Apply this decision procedure (stop at the first match):

1. **Is it a foundational OS utility, driver, or approved infrastructure?**
   → system package, only from the pre-approved set; anything else system-level
   needs **User approval**. Never use system packages for project deps.
2. **Is it a multi-step pipeline?** → define it in a **workflow engine**
   (Snakemake default) whose steps run in containers; then continue at step 3
   for the steps' environments.
3. **Does it need full/system/GPU reproducibility, or will it be archived or
   run by others?** → **container (Apptainer)**: write a committed `*.def`,
   build the `.sif`, log its SHA256.
4. **Is it pure-Python project dependencies?** → **uv** venv + committed
   `uv.lock` (standalone when a full container is overkill, or layered inside
   the container from step 3).
5. **Is a required package conda-only and impractical to containerize?**
   → **conda/mamba** + committed `conda-lock.yml` (fallback; document why).
6. **Installing a high-risk component** (Apptainer, Docker, or a shared
   execution backend — Slurm, Kubernetes, Seqera/Nextflow Tower)? → it is a
   §2.3 decision: **escalate for User approval**. A workflow-engine binary
   itself (Nextflow, Snakemake) and Conda/Mamba are **medium-risk** — a
   **Supervisor** decides and documents (§2.2). `uv` is low-risk (§2.1).
   No agent (Worker through Domain Orchestrator) self-approves a high-risk
   component — it is a User decision (AGENT_ARCHITECTURE.md).

Default bias: prefer the highest applicable tier (container/workflow) for
anything that will be kept or shared; drop to uv for lightweight Python work;
use conda/system packages only when the tiers above genuinely cannot serve.

## 8. Output Automation framework

Generation of deliverable artifacts from code is a supported, reproducible
capability. The framework is deliberately small now and grows by adding output
types, not by adding tools speculatively (GOVERNANCE.md §0).

**Principle:** the **source artifacts are the source of truth**; generated
outputs are reproducible build products, never hand-edited and never the
canonical copy. Outputs are regenerable (excluded from backups as such) and are
rebuilt from committed source + pinned dependencies.

**Supported output types** (capability documented; only PPTX has a chosen
implementation today): **PPTX, PDF, HTML, PNG, SVG**. Figures additionally
follow the PNG **and** vector (PDF/SVG) rule (GOVERNANCE.md §9).

### 8.1 Presentation Automation (approved capability — implementation deferred)

- **Output:** PPTX.
- **Preferred implementation:** **Node.js** + **pptxgenjs**.
- **Node.js / npm:** low-risk **foundational runtime**, already present on the
  base image (GOVERNANCE.md §2.1). Not a project dependency; needs no approval.
- **pptxgenjs:** **medium-risk, project-local dependency.** Installed **only
  within project scope** (a project's own `node_modules`), **never globally**.
  Dependencies must be **pinned**, and **`package-lock.json` is required** and
  committed.
- **Source artifacts (the source of truth, version-controlled):** the
  JavaScript source, `package.json`, and `package-lock.json`.
- **Generated `.pptx` files are outputs, not source** — regenerable from the
  above; they live in the project's `results/` and are not the canonical record.
- **Reproducibility:** `package-lock.json` pins exact versions + integrity
  hashes (npm's `integrity` field) — this satisfies GOVERNANCE.md §4 for the
  Node toolchain, analogous to `uv.lock` for Python. Record the Node/npm
  versions in the project environment manifest (§6).

**Deferred:** `pptxgenjs` is **not installed**; **no templates and no automation
pipelines** are created yet. This section documents the policy only. When
implemented, it follows the §7 decision procedure (project-local npm deps;
containerize only if the deck build must be archived/shared as a unit).
