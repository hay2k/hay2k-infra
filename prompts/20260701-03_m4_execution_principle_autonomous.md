# 20260701-03 — M4: Execution principle (autonomous progress)

**Date:** 2026-07-01
**Role:** User (operator `hha`) → governance codification
**Prompt (verbatim intent):** "M4 Execution Principle — Autonomous Progress. Unless a
listed condition is encountered, continue execution without asking for intermediate
confirmation. Default: Plan → Execute → Validate → Document → Handoff (not Plan → Ask →
Execute → Ask → Continue). Minimize human interruption. Operator confirmation required only
for: irreversible/destructive operations; security/credential changes; significant
financial cost; external service licensing/legal implications; changes that alter
previously approved architecture; ambiguity unresolvable from existing governance;
project-specific scientific decisions requiring human judgment. Otherwise choose the most
reasonable option per governance, document the decision, explain rationale in the handoff,
and continue autonomously. When multiple reasonable choices exist, prefer the one most
consistent with Reuse-First, Shared-by-default, Container-first, Pipeline-driven,
Provider-agnostic, Automation-ready."
**Follow-up (same session):** "Avoid interrupting long implementation sequences with
unnecessary confirmation requests. Batch related work into logical milestones, complete the
milestone, validate it, and report the outcome with a single handoff whenever practical."

**Outcome:** Codified by **extending GOVERNANCE.md** (the rules/approvals source of truth;
Reuse-First on governance — no new doc). The principle sharpens existing §0 + §2
default-to-proceed + AGENT_ARCHITECTURE §4 into an explicit operating default.
- **GOVERNANCE.md §3b** (new, canonical) — autonomous-progress default flow; the 7
  confirmation triggers mapped to §2 User-approval rows; tie-breaker preference order
  (Reuse-First → Shared-by-default → Container-first → Pipeline-driven → Provider-agnostic →
  Automation-ready); **batching clause** (one milestone → validate → single handoff; don't
  interrupt long sequences; pause only for a genuine trigger, then resume).
- **AGENT_ARCHITECTURE.md §4** — decision procedure: autonomous progress is the norm;
  escalate only on a §3b trigger.

**Nature:** governance/documentation only. No §2 approval gate relaxed; §4/§5/§6/§7
unchanged. Applied immediately (this codification itself proceeded autonomously per the
principle — reversible, no trigger). Handoff:
`2026-07-01_m4-execution-principle-autonomous.md`.
