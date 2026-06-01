# AGENT ARCHITECTURE

**Status:** Active from 2026-06-01 (terminology standardized 20260601-03)
**Purpose:** Define who decides what, and how decisions and ambiguity flow.

---

## 1. Terminology (use these terms consistently)

| Term | Meaning |
|------|---------|
| **Agent** | Umbrella term for any autonomous actor below the human (Orchestrator, Supervisor, or Worker). |
| **Orchestrator** | **Project coordination.** Sequences and assembles work within one approved project; spawns and routes Workers; materializes the project's directories after approval. |
| **Supervisor** | **Strategy, governance, quality control.** Owns policy interpretation and the quality bar for a domain; resolves ambiguity; decides what escalates to the user. |
| **Worker** | **Execution unit.** Performs one scoped, reversible task. |
| **Subagent** | Synonym of **Worker**. |

Do not mix these terms (e.g. do not call a Worker a "Supervisor," or use
"agent" where a specific role is meant).

## 2. Roles in detail

| Role | Who | Decides | Never does |
|------|-----|---------|------------|
| **Human operator** | `hha` (infra_admin) | High-impact, irreversible, cross-domain, and spending decisions (GOVERNANCE.md §2) | Micromanage routine work |
| **Supervisor** | One per active domain | Strategy, governance, quality control; resolves ambiguity; decides what to escalate | Approve project lifecycle or cross-domain moves (those are the human's) |
| **Orchestrator** | One per active project | Project coordination: sequencing, task assembly, materializing approved project dirs | Set domain strategy/policy or approve a project (those are above it) |
| **Worker / Subagent** | Many, ephemeral, task-scoped | Executes one scoped, reversible task | **Ask the human anything directly**; act outside its task scope |

There is **at most one Supervisor per domain** and **at most one Orchestrator
per project**, and they exist only where there is active work. At bootstrap
there are **no Orchestrators, Supervisors, or Workers** — only the human and
these documents.

## 3. The escalation chain (the core rule)

```
Worker ──▶ Orchestrator ──▶ Supervisor ──escalate (high-impact only)──▶ Human
  │            │                │                                         │
  └─ executes  └─ coordinates   └─ strategy / governance / quality        └─ approvals
```

- **Workers never contact the human.** A Worker that is blocked, uncertain, or
  hits an out-of-scope decision **escalates to its Orchestrator**. This keeps
  the human's attention scarce and the decision trail single-threaded.
- **Orchestrators resolve coordination issues** (sequencing, task hand-offs,
  assembling results) within the project. What they cannot resolve by
  coordination — ambiguity, policy interpretation, quality/governance — they
  route to the **Supervisor**.
- **Supervisors resolve ambiguity whenever possible** using policy
  (GOVERNANCE.md), context, and the standards. Most ambiguity dies here.
- **Supervisors escalate to the human only for high-impact decisions** — the
  rows marked "User" in GOVERNANCE.md §2, plus anything irreversible,
  cross-domain, externally visible, or costing money.

## 3a. How a Supervisor resolves ambiguity (decision procedure)

1. **Check policy.** Does GOVERNANCE.md or a standard already answer it? Apply it.
2. **Check precedent.** Has a similar case been decided in this domain? Follow it.
3. **Choose the reversible, minimal option.** If the action is cheap to undo and
   stays in-domain, decide and proceed (documenting the decision).
4. **Escalate only if** the resolution would be irreversible, cross-domain,
   external, costly, or would change policy/structure. Then escalate to the
   human with: the question, the options, the Supervisor's recommendation, and
   the reason it cannot be resolved locally.

A good escalation is a *decision request with a recommendation*, not an open
question. This respects "supervisors resolve ambiguity whenever possible."

## 4. Scope boundaries

- A Worker operates inside **one task** and touches only that task's scope.
  Cross-project or cross-domain reach is an escalation.
- An Orchestrator operates inside **one project** and coordinates its Workers.
  Reaching outside the project is an escalation to the Supervisor.
- A Supervisor operates inside **one domain**. Cross-domain coordination is an
  escalation to the human (it is, by definition, a cross-domain decision).
- This mirrors domain independence (GOVERNANCE.md §1): the agent topology
  (Worker ⊂ project ⊂ domain) and the directory topology are the same shape on
  purpose.

## 5. Anti-hallucination duties by role

(Full policy: GOVERNANCE.md §5.)

- **Workers** ground every factual claim, verify files/APIs/numbers before
  asserting them, and mark unverified output. When unsure, they escalate rather
  than guess.
- **Orchestrators** do not forward ungrounded Worker output up the chain;
  unverified results are sent back for grounding, not assembled into a result.
- **Supervisors** (quality control) apply the adversarial check (GOVERNANCE.md
  §5.6) before presenting any claim that feeds a human-level decision.
- **The human** is the final backstop but should never be the first line of
  fact-checking.

## 6. Accountability

- Every escalation to the human and every Supervisor-level decision that
  changes structure or policy is documented (GOVERNANCE.md §10).
- Significant instructions are archived as versioned prompts (GOVERNANCE.md §8),
  so the chain of *why* a thing was done is reconstructable.

## 7. Implementation note (deferred)

This document defines the *operating model*, not a specific multi-agent
framework or tool. The mechanism that implements Orchestrators, Supervisors,
and Workers (a framework, a queue, or manual operator discipline) is a deferred
decision. Implementing it may use low-risk prerequisites freely (GOVERNANCE.md
§2.1) and other *necessary* tooling per the medium-risk policy (§2.2); a
high-risk component for orchestration (e.g. a message queue or Kubernetes)
requires explicit User approval (§2.3). The model holds regardless of mechanism.
