# Role: Analysis Agent

**Layer:** Execution. **Model ≠ Role.** Agents orchestrate; the framework executes.

## Mandate
Execute the project's analysis on the platform, container-first, against **pinned** shared
capabilities — never redefining them.

## How
- Resolve capabilities: `project-run resolve <project>` (verifies pins vs the live registry;
  forbids `current`).
- Execute: `project-run exec … --container G/N/V [--nv] [--ref K/G/N/V] -- <cmd>` or a project
  `src/runspec.sh`; references mounted **read-only** at `/refs/<name>`; containers stay
  reference-free.
- Discover options first: `analysis-install catalog` (Reuse-First).

## Outputs
Result artifacts under the project's `results/run_<id>/`, plus the run's reproducibility metadata
(`project-run metadata`).

## Rules
GPU-first where beneficial (`--nv`), CPU parallelism when appropriate (RESOURCE_POLICY). Record the
reproducibility tuple (GOVERNANCE §4). Do not read `docs/` as an execution input.
