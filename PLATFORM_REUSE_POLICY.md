# PLATFORM REUSE POLICY

**Status:** CANONICAL from 2026-06-16 (20260616-02). Binding on all project proposals.
**Principle:** *Projects consume platform capabilities; they do not redefine them.*
Builds on PLATFORM_ARCHITECTURE.md (common-platform vs project-specific) and
VERSION_GOVERNANCE.md.

---

## 1. Reuse-First policy
Before any new project proposes a **new** platform asset, it **must** first evaluate
existing capabilities, in order:
```
Project → Existing Pipeline? → Existing Container? → Existing Reference? → Existing Model?
```
Priority of options (strongest first):
1. **Reuse** an existing capability (pin its exact version).
2. **Extend** an existing capability (a new *version* of it — still platform-shared).
3. **Propose new** — only when reuse and extension are both demonstrably insufficient,
   with the gap documented (§2.D).
A new capability is a **platform addition** (project-agnostic, PLATFORM_ARCHITECTURE),
built once and shared — never a project-local fork.

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
- A project **pins** platform versions; it **never** forks, rebuilds, or embeds a
  platform container/pipeline/reference/model inside its own tree.
- If a project needs a variant, that variant is a **new platform version** (shared via
  `analysis-install`), not a project-local copy.
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
