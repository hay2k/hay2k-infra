# AGENT WORKFLOW STANDARD

**Status:** CANONICAL from 2026-06-16 (promoted M3-4C.6, 20260616-04; authored M3-1A).
Documentation/governance only. **Vendor-, model-, and project-neutral.**
**Scope:** A reusable, vendor-neutral workflow model for AI-assisted (and human) project
work. Complements the **role** hierarchy in AGENT_ARCHITECTURE.md, the approval gates in
GOVERNANCE.md / PROJECT_LIFECYCLE.md, the capability rules in PLATFORM_REUSE_POLICY.md
(incl. §7 Agent Capability Resolution), and PLATFORM_ARCHITECTURE.md §8 (Automation
Readiness). Pairs with PROJECT_SPECIFICATION_POLICY.md.

---

## 1. Rationale
AI-assisted projects move through repeatable **phases of work**. Naming those phases
vendor-neutrally lets any AI system (current or future) plug into a defined slot, keeps
responsibilities clear, and — critically — keeps a **mandatory human decision layer** at
the end. This model describes *what work happens in what order*; it does not name or
assume any specific tool, vendor, or model.

## 2. The four-layer workflow model
```
┌─ PLANNING LAYER ──────────────┐   Knowledge Collection
│  (may update the canonical    │   Knowledge Organization
│   project documents)          │   Project Design + Capability Resolution
└───────────────────────────────┘
┌─ EXECUTION LAYER ─────────────┐   Analysis
│  (reads CURRENT canonical     │   Implementation
│   files only; PROJECT_MASTER  │   Manuscript Assembly
│   primary; consumes pinned    │
│   platform capabilities)      │
└───────────────────────────────┘
┌─ VALIDATION LAYER ────────────┐   Quality Control
│  (checks outputs against      │   Reviewer Simulation
│   PROJECT_MASTER.md)          │
└───────────────────────────────┘
┌─ DECISION LAYER (MANDATORY) ──┐   Human Review
│  Humans retain final authority │   Human Approval
└───────────────────────────────┘
```

### Layer responsibilities
- **Planning** — Knowledge Collection, Knowledge Organization, Project Design. May
  create/update `PROJECT_MASTER.md`/`FIGURE_PLAN.md`/`MANUSCRIPT_PLAN.md`/`TODO.md`
  (PROJECT_SPECIFICATION_POLICY.md) and perform **Capability Resolution** (Reuse-First),
  recording pinned platform deps in `ENVIRONMENT_MANIFEST.md` (PLATFORM_REUSE_POLICY §2/§7).
- **Execution** — Analysis, Implementation, Manuscript Assembly. Reads **only current
  canonical files** (PROJECT_MASTER primary); **consumes** the pinned platform
  capabilities (containers/pipelines/references/models) — never redefines them; never
  uses archived versions as default inputs.
- **Validation** — Quality Control, Reviewer Simulation. Verifies outputs against the
  authoritative spec; does not self-approve.
- **Decision** — **Human Review + Human Approval. Mandatory.** AI provides
  **recommendations**; **humans retain final authority.**

## 3. Human decision authority (non-negotiable)
The Decision Layer is required for every project-significant outcome. It maps onto the
existing gates: **User-approved actions** (GOVERNANCE.md §2) and the escalation terminus
**…→ User** (GOVERNANCE.md §3). No AI layer self-approves a project-significant change;
revisions to `PROJECT_MASTER.md`, **new platform capabilities** (PLATFORM_REUSE_POLICY
§2), and lifecycle events (PROJECT_LIFECYCLE.md §3/§4) require human approval.

## 4. Relationship to existing governance (orthogonal; no model change)
- **AGENT_ARCHITECTURE.md** defines *roles* (Domain Orchestrator / Supervisor / Senior
  Engineer / Worker) + escalation. **This standard defines *workflow phases*.** They are
  orthogonal: a role performs work *within* a layer (a Worker executes; a Supervisor /
  Senior Engineer validate; the User decides).
- **PLATFORM_REUSE_POLICY.md** governs how the Planning/Execution layers select and pin
  capabilities (Reuse-First; agents and humans use the identical workflow, §7). **Agent
  components are themselves shared assets** (PLATFORM_REUSE_POLICY §8): shared agent logic
  and reusable prompts live in the platform layer (versioned, consumed by pinning);
  project-specific instructions live in `PROJECT_MASTER.md` / `TODO.md` / project configs
  — never by forking shared agent logic into the project.
- **GOVERNANCE.md / PROJECT_LIFECYCLE.md** provide the approval gates the Decision Layer
  enacts. This standard **adds no new infrastructure** and does not change the M2/M3
  governance model — it formalizes the work lifecycle on top of it.

## 5. Vendor neutrality
Layers and stages are **capabilities, not products.** Any AI system may fill any slot;
no vendor or model is named or assumed. Swapping the underlying AI changes nothing about
the model, the canonical documents, the capability metadata, or the human authority.

## 6. Example flow (vendor-neutral)
1. *Planning:* an agent drafts/updates `PROJECT_MASTER.md` (+ `TODO.md`) and performs
   Capability Resolution → pins reused capabilities in `ENVIRONMENT_MANIFEST.md`.
2. *Decision:* a human reviews + **approves** the spec (+ any new-capability proposal),
   archiving a milestone snapshot if warranted.
3. *Execution:* agents run Analysis/Implementation/Manuscript Assembly against the
   current canonical files, consuming the pinned capabilities.
4. *Validation:* Quality Control + Reviewer Simulation against `PROJECT_MASTER.md`.
5. *Decision:* a human reviews validation output and **approves** the result.
