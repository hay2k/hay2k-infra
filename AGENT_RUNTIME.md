# AGENT RUNTIME

**Status:** Design (2026-06-01, 20260601-10). **Document only — no runtime,
service, or install exists. This is how agents are *intended* to run.**
**Scope:** The mechanism that realizes the agent hierarchy
(AGENT_ARCHITECTURE.md) on the cluster (NODE_ARCHITECTURE.md): how each tier is
executed, lives, communicates, logs, escalates, and fails.

---

## 1. Principle

Agents are spawned **only for active work** and **retired promptly** (GOVERNANCE
.md §0 — create what is required). Two concerns are separated:

- **Cognition** — reasoning, coordination, review, code authoring, decisions.
- **Persistence / execution** — long-running and background processes (GPU
  jobs, servers, watch loops) that must outlive a reasoning session.

The runtime maps cognition onto **Claude Code** and persistence/execution onto
**tmux** (later **Slurm** for scheduled compute). Both use only pre-approved
tooling: tmux is low-risk §2.1; Claude Code is the operating tool itself.

## 2. Runtime model evaluation

| Criterion | tmux-centric | Claude-Code-centric | **Hybrid (recommended)** |
|-----------|--------------|---------------------|--------------------------|
| Persistence / survives disconnect | ✅ | 🔴 (session-bound) | ✅ (tmux/Slurm layer) |
| Structured agent spawning | 🔴 (manual) | ✅ (Agent tool / subagents) | ✅ |
| Reasoning / code / review | 🔴 | ✅ | ✅ (Claude Code layer) |
| Long-running GPU jobs | 🟢 (process in a pane) | 🔴 (not a job runner) | ✅ (jobs in tmux→Slurm) |
| Operator transparency (attach/watch) | ✅ | 🟡 | ✅ |
| Multi-node execution | 🟢 (one tmux server/node + ssh) | 🟡 (runs where invoked) | 🟢 |
| New tooling/approvals needed | none (§2.1) | none (the tool itself) | none now |
| Complexity | low | low | low–moderate |

- **tmux-centric:** durable, transparent, scriptable, no new installs — but not a
  scheduler and has no structured reasoning or agent model. Good muscle, no brain.
- **Claude-Code-centric:** native structured agents (Subagent = Worker via the
  Agent tool), strong reasoning/code/review — but session-bound and not a runner
  of multi-hour GPU jobs across nodes. Good brain, no persistence.
- **Hybrid:** Claude Code = cognition/orchestration/review/Workers; tmux (→Slurm)
  = persistence and long-running execution. Matches reality and needs no new
  approvals to realize.

## 3. Recommended runtime

**Hybrid.** Claude Code provides Domain Orchestrator, Supervisor, Senior
Engineer, and Worker *cognition* (Workers spawned as Claude Code subagents for
scoped reasoning/code tasks). When a Worker must run something long or
background (training, a server, a sweep), it **launches that job into a tmux
session** on a compute node (now) or **submits it to Slurm** (later), and
monitors it via logs on shared storage (NFS, once deployed). The control surface
(persistent coordination sessions) lives in tmux on the control node `gpu-01`.

## 4. Per-tier execution & lifecycle

Placement follows NODE_ARCHITECTURE.md: Orchestrator/Supervisor on the control
node; Senior Engineer anywhere; Workers node-agnostic.

### Domain Orchestrator
- **Lifespan:** long-lived, one per *active* domain; persistent on `gpu-01`
  (fails over to `gpu-02`).
- **Spawning:** instantiated when a domain gains its first **User-approved**
  project (PROJECT_LIFECYCLE.md); realized as a Claude Code orchestration role
  with a persistent tmux control session.
- **Retirement:** when the domain has no active work / is retired (User
  decision); wind down subordinates, flush state to shared storage first.
- **Communication:** receives objectives from the User; tasks Supervisor(s); is
  the last stop before the User.
- **Logging:** append-only domain coordination log (dispatched work, decisions,
  escalations) on shared storage.
- **Escalation:** receives high-impact items from Supervisor; escalates to User.
- **Failure:** state persisted (never in-memory only) so a restarted/failed-over
  orchestrator resumes from the log.

### Supervisor
- **Lifespan:** long-lived, one per active domain, alongside the Orchestrator.
- **Spawning:** by the Domain Orchestrator when domain work begins; Claude Code
  role on the control node.
- **Retirement:** when the domain is inactive/retired; graceful.
- **Communication:** **receives Worker escalations directly** (Worker →
  Supervisor); interprets policy; approves medium-risk (§2.2); requests Senior
  Engineer review for §3a changes; routes high-impact to the Orchestrator.
- **Logging:** governance/decision log with rationale (GOVERNANCE.md §10) —
  ambiguity resolutions, medium-risk approvals, escalations.
- **Escalation:** up to Domain Orchestrator (high-impact); sideways to Senior
  Engineer (review).
- **Failure:** decisions logged → recoverable; in-flight escalations re-driven
  from the log on failover.

### Senior Engineer (side review — not in the escalation chain)
- **Lifespan:** on-demand / ephemeral per review.
- **Spawning:** invoked by a Supervisor when a change touches architecture,
  reproducibility, shared libraries, reusable workflows, or infrastructure
  standards (§3.2); realized as a Claude Code review subagent.
- **Retirement:** after delivering its verdict.
- **Communication:** receives the change + context; returns a verdict
  (approve / needs-changes) with findings to the requesting Supervisor; does not
  relay escalations.
- **Logging:** review record (scope, verdict, findings) on shared storage,
  linked to the commit/change.
- **Escalation:** none; governance concerns are flagged to the Supervisor.
- **Failure:** review is re-runnable; **a §3.2 change must not proceed to
  implementation without a completed review (fail-closed).**

### Worker / Subagent
- **Lifespan:** ephemeral, one scoped reversible task. Distinguish the *Worker*
  (reasoning agent) from any *job* it launches — a long job in tmux/Slurm
  outlives the Worker and is tracked separately.
- **Spawning:** by the Orchestrator/Supervisor (Claude Code Agent tool →
  subagent) for a specific task; node-agnostic. Compute jobs are launched into
  tmux (now) / Slurm (later) on a compute node.
- **Retirement:** on task completion (success or failure) — return result, then
  terminate. Launched jobs retire when the job ends.
- **Communication:** receives a scoped task spec; returns result + artifact
  paths; escalates blockers/ambiguity **to its Supervisor** (never the User).
- **Logging:** per-task log — inputs, commands, exit status, artifact paths +
  SHA256, seed/env (reproducibility, GOVERNANCE.md §4) — on shared storage.
- **Escalation:** directly to Supervisor (§3 chain).
- **Failure:** reversible by design (no irreversible action without approval);
  report failure with logs, then retry or escalate. Prefer idempotent tasks.
  Orphaned launched jobs are reclaimable because jobs are tracked centrally.

## 5. Cross-cutting

- **Communication substrate:** the **shared filesystem (NFS, once deployed)**
  carries task specs, results, logs, and state as files (structured
  JSON/markdown); tmux carries live sessions; ssh reaches other nodes. **No
  hidden in-memory-only state** — anything needed for recovery is on shared
  storage. Until NFS is deployed, this is control-node-local + ssh.
- **Logging standard:** append-only, timestamped, per-agent and per-task, on
  shared storage; decisions carry rationale (§10); Workers carry reproducibility
  fields (§4); **secrets are never logged** (SECRETS_POLICY.md §8).
- **Spawning authority:** mirrors the approval matrix — the User approves a
  project (→ Orchestrator instantiated); Orchestrator/Supervisor spawn
  subordinate agents within approved scope; **no agent self-approves high-impact
  or high-risk items** (GOVERNANCE.md §2).
- **Failure handling principle:** **fail-closed** for irreversible/high-impact
  actions and the §3.2 review gate; **fail-safe and re-runnable** for reversible
  tasks; **persist state** so control-node failover (`gpu-01`→`gpu-02`) resumes;
  reclaim orphaned jobs.
- **Tooling risk:** tmux = low-risk §2.1; Claude Code = the operating tool; a
  heavier orchestration backend (message queue, Slurm, Kubernetes) is high-risk
  §2.3 and a separate User decision. The hybrid needs **no new approvals** to
  realize at small scale.

## 6. Migration / deferred

- **Now:** manual operation — Claude Code for cognition, tmux on `gpu-01` for the
  control surface and background jobs, ssh for other nodes. No scheduler, no
  shared FS deployed yet.
- **After NFS is deployed:** logs/state/specs move onto the shared filesystem;
  Workers on any node share one namespace.
- **After Slurm (high-risk, User approval):** Worker compute jobs migrate from
  tmux to Slurm submission; lifecycle/logging contracts above are unchanged.
- **Deferred:** all of the above is design. No runtime, agent process, service,
  or scheduler is created by this document.
