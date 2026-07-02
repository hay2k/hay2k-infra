# PLATFORM CONSTITUTION

**Read this first.** This is the architectural north star for the shared research-compute
platform — for humans and for any future AI agent. It is **not governance** (rules/approvals
live in GOVERNANCE.md); it is the *why* behind the platform. When a detailed rule and this
document seem to disagree, follow the rule and fix the drift. Concise on purpose.

Status: v1.0 (2026-07-02, 20260702-02). Principles change slowly; mechanisms evolve.

---

## Purpose
One durable, reproducible, project-independent platform that many research projects (and later
Business/Investment/Surplus work) **consume** — not a collection of per-project setups. The
platform is built once and shared; projects pin what they need and run.

## The principles (in force everywhere)

1. **Reuse-First.** Reuse → Extend → New shared → Project-specific (justified). Always evaluate
   existing shared assets before making new ones. (PLATFORM_REUSE_POLICY)
2. **Shared-by-default.** Infrastructure, agents, pipelines, containers, references, models, and
   reusable scripts are shared platform assets by default; projects **consume** by pinning exact
   versions and do not fork them into project trees without a documented reason.
3. **Container-first.** Scientific software lives in versioned, SHA-pinned, **reference-free**
   containers. References/models are mounted read-only. (ENVIRONMENT_POLICY, CONTAINER_STANDARDS)
4. **Pipeline-driven.** Prefer versioned pipelines (nf-core/Nextflow, Snakemake) over ad-hoc
   scripts; pipelines consume the shared containers + references. (PIPELINE_STANDARDS)
5. **Provider-agnostic.** Nothing is hard-wired to one AI vendor or model. **Model ≠ Role** and
   **Model ≠ Execution Framework**: agents (any provider) orchestrate; the framework executes.
6. **Automation-ready.** Humans and future agents use the **same** discovery, pins, metadata, and
   execution path — no agent-specific fork. (PLATFORM_ARCHITECTURE §8)
7. **Reproducibility is non-negotiable.** Every result states code commit, environment manifest
   (lockfile + image digest), data hashes, and seed. (GOVERNANCE §4)
8. **Human Decision Layer is mandatory.** AI recommends; humans approve project creation/
   retirement, new capabilities, and scientific decisions. Autonomous progress is the default in
   between; confirm only on real triggers. (GOVERNANCE §2/§3b)
9. **Knowledge, not files.** Migrations transfer distilled research knowledge and reconstruct on
   the platform; they do not rehost legacy environments. (PROJECT_LIFECYCLE §4a)
10. **Minimalism.** Create what is required; avoid speculation, duplication, and empty structure.
    Extend existing assets before adding new ones. (GOVERNANCE §0)

## How the platform is shaped
- **Discover** capabilities (`analysis-install catalog`/`describe`) → **pin** them in a project's
  `ENVIRONMENT_MANIFEST.md` → **execute** with `project-run` (Capability Resolution → Execution →
  Validation → Figure Generation → Result Packaging → Handoff).
- **Figures** always ship as Figure (PNG+PDF) + Source-Data Table + Metadata.
- **Agents** are defined by **role**, not model (`templates/agents/`): Knowledge, Reference,
  Analysis, Figure, Writing, Validation, Supervisor. The Supervisor orchestrates; the execution
  framework executes.

## Domains (shared infrastructure, one priority order)
**Research > Business > Investment > Surplus.** All domains consume the *same* platform; none
redefines it. Surplus uses idle capacity and always yields to higher-priority work.

## Acceleration
GPU-first where beneficial; CPU parallelism when appropriate; distributed (MPI) only when
justified. (RESOURCE_POLICY)

## What this enables
The same frozen platform runs P0001 (Nanopore direct-RNA AI), P0002 (RNA editing), and P0003
(TBI scRNA-seq, reconstructed via knowledge transfer) — identically, reproducibly, and without
being specialized for any one of them.

> Detailed rules: GOVERNANCE · PLATFORM_ARCHITECTURE · PLATFORM_REUSE_POLICY · PROJECT_LIFECYCLE ·
> AGENT_ARCHITECTURE / AGENT_WORKFLOW_STANDARD · ENVIRONMENT_POLICY · PIPELINE_STANDARDS ·
> VERSION_GOVERNANCE. Frozen component set: PLATFORM_VERSION.md.
