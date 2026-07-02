# Agent Layer — reusable role library

**Shared agent logic lives in the platform layer** (PLATFORM_REUSE_POLICY §8). These are the
platform's **reusable, provider-agnostic agent role specs** — the durable "who does what,"
independent of any model. Project-specific instructions stay in the project's `PROJECT_MASTER.md`
/ `TODO.md`, never by forking these.

## Principles
- **Model ≠ Role.** A role is a responsibility, not a vendor. Any provider (Claude / GPT / Kimi /
  Gemini / DeepSeek / local) can fill any role; swapping the model changes nothing here.
- **Agents orchestrate; the execution framework executes.** Roles decide *what/why*; `project-run`
  performs the *how* (Capability Resolution → Execution → Validation → Figure → Package → Handoff).
- **Human Decision Layer is mandatory** (GOVERNANCE §2/§3b): agents recommend; humans approve
  project creation/retirement, new capabilities, and scientific decisions.
- **Reuse-First + reproducibility** apply to every role (discover via `analysis-install catalog`;
  pin in `ENVIRONMENT_MANIFEST.md`; ground every claim, GOVERNANCE §5).

## Roles (this directory)
| Role | Workflow layer (AGENT_WORKFLOW_STANDARD §2) | Primary platform tools |
|------|----------------------------------------------|------------------------|
| `supervisor` | across all (orchestration, ambiguity, escalation) | all; enforces §3b triggers |
| `knowledge`  | Planning | `knowledge_transfer/` (kt-init), literature synthesis |
| `reference`  | Planning / Validation | PubMed/CrossRef/EuropePMC → Zotero citekeys (GOVERNANCE §7) |
| `analysis`   | Execution | `project-run` (container-first, pinned capabilities) |
| `figure`     | Figure Generation | `project-run figure` (Figure+SourceData+Metadata) |
| `writing`    | Execution (Manuscript Assembly) | PROJECT_MASTER + results; citekeys only |
| `validation` | Validation | reproducibility tuple, QC, reviewer simulation |

## Mapping to the AGENT_ARCHITECTURE hierarchy
These **functional** roles are orthogonal to the **authority** tiers (Domain Orchestrator /
Supervisor / Senior Engineer / Worker, AGENT_ARCHITECTURE.md). A Worker *performs* a functional
role within a workflow layer; the Supervisor role here corresponds to the Supervisor authority
tier. No runtime is deployed (AGENT_ARCHITECTURE §2) — these specs are consumed when agents run.

Orchestration across roles: `orchestration.md`.
