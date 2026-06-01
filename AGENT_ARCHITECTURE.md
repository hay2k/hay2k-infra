# AGENT ARCHITECTURE

**Status:** Active from 2026-06-01 (hierarchy extended 20260601-07)
**Purpose:** Define who decides what, how decisions and ambiguity flow, and what
must be reviewed before implementation.

---

## 1. Terminology (use these terms consistently)

| Term | Meaning |
|------|---------|
| **Agent** | Umbrella term for any autonomous actor below the User (Domain Orchestrator, Supervisor, Senior Engineer, or Worker). |
| **Domain Orchestrator** | **Domain-level coordination.** Top agent within a domain: sequences work across the domain's projects, coordinates resources, materializes approved projects, escalates high-impact decisions to the User. |
| **Supervisor Agent** | **Strategy, governance, ambiguity resolution.** Owns policy interpretation for the domain; resolves ambiguity; approves medium-risk decisions. |
| **Senior Engineer Agent** | **Side review (not in the escalation chain).** Provides review, architecture guidance, reproducibility review, and quality assurance. Engaged as the quality gate before implementation for §3.2 changes; does not relay escalations. |
| **Worker Agent** | **Implementation and execution.** Performs one scoped, reversible task. |
| **Subagent** | Synonym of **Worker Agent**. |

Do not mix these terms (e.g. do not call a Worker a "Supervisor", or use
"agent" where a specific tier is meant).

## 2. Canonical hierarchy

Primary authority / escalation order, highest to lowest. The **Senior Engineer
is a side review role**, attached to the chain rather than part of it:

```
User                  → final authority (high-impact approvals)
  ▲
Domain Orchestrator   → domain-level coordination
  ▲
Supervisor Agent      → strategy, governance, ambiguity resolution
  ▲                        ◀───  Senior Engineer Agent  (SIDE: review, architecture
Worker Agent                          guidance, reproducibility review, QA —
  (Subagent = Worker)                 NOT in the escalation chain)
  → implementation and execution
```

| Role | Who | Decides / does | Never does |
|------|-----|----------------|------------|
| **User** | `hha` (infra_admin) | High-impact, irreversible, cross-domain, spending decisions (GOVERNANCE.md §2) | Micromanage routine work |
| **Domain Orchestrator** | One per active domain | Coordinates work across the domain; materializes approved projects; escalates high-impact to User | Approve high-impact items itself; set cross-domain policy |
| **Supervisor Agent** | One per active domain | Strategy, governance, ambiguity resolution; approves **medium-risk** decisions (GOVERNANCE.md §2.2); **receives Worker escalations directly** | Approve project lifecycle / cross-domain / high-risk (those are the User's) |
| **Senior Engineer Agent** | As needed per domain/project | **Side review:** architecture guidance, code-quality and reproducibility review, QA; the quality gate for §3.2 changes | Sit in the escalation chain; set governance/strategy; grant approvals reserved for Supervisor/User |
| **Worker Agent / Subagent** | Many, ephemeral, task-scoped | Implements one scoped, reversible task; **escalates to its Supervisor** | **Contact the User directly**; act outside its task scope |

These tiers exist only where there is active work. At bootstrap there are **no
agents** — only the User and these documents.

## 3. Two flows: escalation and review

### 3.1 Escalation chain (blocked / ambiguous / needs approval)

```
Worker → Supervisor → Domain Orchestrator → User
```

- **Workers never contact the User.** A blocked or uncertain Worker **escalates
  directly to its Supervisor**. (The Senior Engineer is not in this chain.)
- **Supervisor resolves ambiguity whenever possible** using policy
  (GOVERNANCE.md), precedent, and standards, and approves medium-risk decisions.
  Most ambiguity dies here.
- **Domain Orchestrator** handles domain-level coordination and is the last stop
  before the User; it escalates only genuinely high-impact items.
- **Only high-impact decisions reach the User** — the rows marked "User" in
  GOVERNANCE.md §2, plus anything irreversible, cross-domain, externally
  visible, or costing money.

### 3.2 Review gate (side review — Senior Engineer)

The Senior Engineer is a **side review role, not part of the escalation chain
(§3.1).** It provides review, **architecture guidance**, **reproducibility
review**, and **quality assurance**. A **Senior Engineer review is required
before implementation** for any change affecting (GOVERNANCE.md §3a):

- architecture,
- reproducibility,
- shared libraries,
- reusable workflows,
- infrastructure standards.

This review is **in addition to** any approval: a medium-risk decision the
Supervisor approves still gets Senior Engineer review if it touches the list
above. Routine, local, reversible work that touches none of these needs no
Senior Engineer review. Escalations still flow Worker → Supervisor regardless;
the Senior Engineer advises and reviews but does not relay decisions.

## 4. How a Supervisor resolves ambiguity (decision procedure)

1. **Check policy.** Does GOVERNANCE.md or a standard already answer it? Apply it.
2. **Check precedent.** Has a similar case been decided in this domain? Follow it.
3. **Choose the reversible, minimal option.** If the action is cheap to undo and
   stays in-domain, decide and proceed (documenting the decision).
4. **Escalate only if** the resolution would be irreversible, cross-domain,
   external, costly, or would change policy/structure. Escalate via the Domain
   Orchestrator to the User with: the question, the options, a recommendation,
   and why it cannot be resolved locally.

A good escalation is a *decision request with a recommendation*, not an open
question.

## 5. Scope boundaries

- A **Worker** operates inside **one task** and touches only that task's scope.
- A **Senior Engineer** reviews within its domain/project; it does not set
  policy.
- A **Supervisor** owns governance for **one domain**.
- A **Domain Orchestrator** coordinates **one domain**; cross-domain
  coordination is, by definition, a User-level decision (GOVERNANCE.md §1).
- The agent topology (Worker ⊂ project ⊂ domain) mirrors the directory topology
  on purpose.

## 6. Anti-hallucination duties by role

(Full policy: GOVERNANCE.md §5.)

- **Workers** ground every factual claim, verify files/APIs/numbers before
  asserting them, mark unverified output, and escalate rather than guess.
- **Senior Engineers** reject ungrounded or unreproducible work at the review
  gate instead of passing it upward; reproducibility review includes checking
  that lockfiles/image digests/seeds are recorded (GOVERNANCE.md §4).
- **Supervisors** apply the adversarial check (GOVERNANCE.md §5.6) before any
  claim feeds a User-level decision.
- **The User** is the final backstop, never the first line of fact-checking.

## 7. Accountability

- Every escalation to the User, every Supervisor approval that changes structure
  or policy, and every Senior Engineer review of a §3.2 change is documented
  (GOVERNANCE.md §10).
- Significant instructions are archived as versioned prompts (GOVERNANCE.md §8).

## 8. Implementation note (deferred)

This document defines the *operating model*, not a specific multi-agent
framework. The mechanism that implements these tiers (a framework, a queue, or
manual operator discipline) is a deferred decision. Implementing it may use
low-risk prerequisites freely (GOVERNANCE.md §2.1) and other necessary tooling
per the medium-risk policy (§2.2); a high-risk component (e.g. a message queue
or a shared execution backend) requires explicit User approval (§2.3). The
model holds regardless of mechanism.
