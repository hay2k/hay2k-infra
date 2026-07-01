# PLATFORM REUSE POLICY

**Status:** CANONICAL from 2026-06-16 (20260616-02); **M4 core principle adopted
2026-07-01 (20260701-02).** Binding on all project proposals.
**Principle:** *Projects consume platform capabilities; they do not redefine them.*
Builds on PLATFORM_ARCHITECTURE.md (common-platform vs project-specific) and
VERSION_GOVERNANCE.md.

## 0. M4 core principle (shared-by-default)
Infrastructure, **agents**, pipelines, containers, references, models, and **reusable
scripts** are **shared platform assets by default**. They must be easy to **update,
version, deprecate, and reuse** across multiple projects (VERSION_GOVERNANCE.md;
lifecycle §3). Projects **consume** them by **pinning exact versions** in
`ENVIRONMENT_MANIFEST.md` (§5) — they **do not copy or fork** a shared asset into a
project directory **unless there is a documented project-specific reason** (§4). This
principle governs **all** asset classes above, not only the four `analysis-install`
kinds; it applies equally to humans and automation agents (§7–§8).

---

## 1. Reuse-First policy
**Asset classes in scope (shared by default):** infrastructure, agents (logic + reusable
prompts, §8), pipelines, containers, references, models, and reusable scripts.
Before any new project proposes a **new** asset, it **must** first evaluate existing
shared assets, in order:
```
Project → Existing Pipeline? → Existing Container? → Existing Reference? → Existing Model?
        → Existing shared Script / Agent asset?
```
Priority of options (strongest first) — the **default order**:
1. **Reuse** an existing shared asset (pin its exact version).
2. **Extend** a shared asset with a **new version** of it — still platform-shared.
3. **Create a new shared platform asset** — only when reuse and extension are both
   demonstrably insufficient, with the gap documented (§2.D). Project-agnostic
   (PLATFORM_ARCHITECTURE), built once and shared.
4. **Create a project-specific asset** — the last resort, **only if justified** with a
   **documented project-specific reason** recorded in the project's Capability Resolution
   (§2.D / §4). Everything above rung 4 stays in the platform layer.
```
Reuse  >  Extend  >  New shared  >  Project-specific (justified)
```

## 2. Project Capability Resolution (workflow — required at proposal)
For each needed pipeline / container / reference / model:
- **A. Search** existing capabilities: `analysis-install list pipeline|container|reference`
  + the PLATFORM_ARCHITECTURE capability catalog.
- **B. Reuse** if suitable → record the exact pinned version in the project manifest.
- **C. Gap?** Prefer **extend** (new version of an existing capability) over a brand-new
  one; propose a **new** capability only if neither fits.
- **D. Document justification** in the project's **Capability Resolution** record
  (in `ENVIRONMENT_MANIFEST.md`): what was searched, what is reused (versions), what is
  new/extended and **why** (the gap).
Reusing is routine (no extra gate). **Proposing a NEW platform capability is a platform
decision** (Supervisor/operator, medium-risk per GOVERNANCE §2.2) — separate from, and
usually preceding, the project approval; the capability is then built project-agnostically
(M3-4D pattern) and the project consumes it.

## 3. Platform Capability Lifecycle
Every capability (container / pipeline / reference / model) moves through:
```
proposed → built → active → deprecated → retired
```
- **proposed** — reuse-insufficiency justified; reusable across ≥2 (potential) projects.
- **built** — installed via `analysis-install` (versioned, pinned, SHA256, MANIFEST).
- **active** — `current`; consumed by projects (which pin exact versions).
- **deprecated** — superseded by a newer version; retained for reproducibility; new
  projects use the successor (no silent upgrade of existing pins).
- **retired** — removed only when **no** project manifest references it (VERSION_GOVERNANCE
  §retire); the `VERSIONS.md` record persists.
Capabilities are **platform-owned and project-agnostic** at every state.

## 4. Projects consume, do not redefine
- A project **pins** platform versions; by default it **does not** fork, rebuild, copy,
  or embed a shared asset (container/pipeline/reference/model/script/agent asset) inside
  its own tree.
- If a project needs a variant, that variant is a **new platform version** (shared via
  `analysis-install` / the platform layer), **not** a project-local copy.
- **Documented exception (rung 4).** A project-specific copy/fork is permitted **only when
  there is a genuine project-specific reason** that reuse/extend/new-shared cannot serve
  (e.g. a throwaway experiment, a license constraint, a hard incompatibility). It **must**
  be justified in the project's **Capability Resolution** record (§2.D, in
  `ENVIRONMENT_MANIFEST.md`): what shared asset it diverges from, why sharing is
  infeasible, and whether it should later be promoted back to the platform. Undocumented
  forks are non-conformant.
- Containers stay **reference-free** (software only); references/models are mounted
  read-only (PLATFORM_ARCHITECTURE §3).

## 5. Project capability declaration (standards)
Every project **must declare, pinned**, its platform dependencies in
`ENVIRONMENT_MANIFEST.md` (template: `infra/templates/project/ENVIRONMENT_MANIFEST.md`):
- **pipeline dependencies** — `<engine>/<tool>/<version>`
- **container dependencies** — `apptainer/<env>/<version>` + SHA256
- **reference dependencies** — `<category>/<name>/<version>`
- **model dependencies** — `model/<name>/<version>`
- **Capability Resolution record** — the §2 search/reuse/new justification.
This satisfies reproducibility (GOVERNANCE §4) and makes reuse auditable (retirement
checks grep these declarations).

## 6. Where this is enforced
- **PROJECT_LIFECYCLE.md §4** — the creation/proposal step requires a completed
  Capability Resolution before approval.
- **DIRECTORY_STANDARD.md §3** — the project shape requires the declaring
  `ENVIRONMENT_MANIFEST.md`.
- **PLATFORM_ARCHITECTURE.md** — defines the capabilities being reused.

## 7. Agent Capability Resolution (automation = same rules) (20260616-03)
Future **automation agents follow the identical Reuse-First / Project Capability
Resolution** of §1–§2 — there is **no separate agent process**. The only difference is
the input form: an agent reads the capability set **programmatically** (`analysis-install
list pipeline|container|reference` + per-version `MANIFEST.md` + the PLATFORM_ARCHITECTURE
catalog; lifecycle derived from `current`) and **writes its resolution into the project's
`ENVIRONMENT_MANIFEST.md`** (§5).
- **Reuse-First applies equally to humans and agents.** Reuse/extend is routine; a **new
  platform capability** an agent proposes is still a **human/Supervisor decision** (§2),
  built project-agnostically (PLATFORM_ARCHITECTURE) before consumption.
- **Human Decision Layer is mandatory** for project creation/retirement and capability
  approval (GOVERNANCE §2, PROJECT_LIFECYCLE §3/§4). Agents recommend; humans decide.
- No agent-specific infrastructure or metadata is introduced — automation reuses existing
  manifests/metadata (PLATFORM_ARCHITECTURE §8).

## 8. Agent components are shared assets (same rule)
Agent components follow the identical shared-by-default rule (§0–§1):
- **Shared agent logic and reusable prompts live in the platform layer** — versioned,
  reusable across projects, and consumed by pinning, exactly like any other shared asset
  (Reuse > Extend > New shared > project-specific). The role/operating model is defined in
  **AGENT_ARCHITECTURE.md**; the vendor-neutral workflow in **AGENT_WORKFLOW_STANDARD.md**.
- **Project-specific instructions live with the project** — `PROJECT_MASTER.md`,
  `TODO.md`, and project configs (PROJECT_SPECIFICATION_POLICY.md) — **never** by forking
  shared agent logic/prompts into the project (§4 documented-exception applies if genuinely
  needed).
- **Model ≠ Role.** The provider/model backing an agent is interchangeable
  (AGENT_WORKFLOW_STANDARD §5); shared prompts/logic are written vendor-neutrally so
  swapping the model changes nothing about the asset or its pins.
- **No premature materialization.** A dedicated shared-prompt/agent-asset store is created
  **on first real use** (there are no runtime agents at bootstrap — AGENT_ARCHITECTURE §2),
  registered like any other shared asset when it exists. Until then this section states the
  placement rule; it does not mandate an empty directory.
