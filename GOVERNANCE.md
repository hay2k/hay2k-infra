# GOVERNANCE

**Status:** Active from 2026-06-01
**Authority:** Binding on all agents and on the human operator acting in role.
**Change process:** §9.

This document is the single source of truth for *rules and approvals*. Where
another document conflicts with this one, this one wins, and the conflict is a
bug to be fixed.

---

## 0. Core principle (refined 20260601-03)

> **Create what is required. Avoid what is not required.**

**Minimalism first.** The constraint is on *waste and speculation*, not on
*progress*. Specifically, avoid:

- unnecessary directories
- duplicate directory purposes
- speculative future structures
- empty organizational trees
- placeholder projects

**Do not prohibit necessary infrastructure work.** Necessary, in-scope,
reversible infrastructure work should **proceed efficiently** and be
documented (§10) — not wait for approval. Approval is reserved for the
genuinely high-impact actions in §2. Every other section of this document is
read through this principle.

*History: 20260601-01 was intentionally conservative and implied installation,
directory creation, and infrastructure evolution were prohibited outright;
20260601-02 corrected that; 20260601-03 refined the wording above and the
risk-tiered installation policy in §2.*

---

## 1. Domain independence

The four work domains — **Research**, **Business**, **Investment**, **Surplus** —
are governed by a **priority hierarchy** on **shared infrastructure**:

> **Research > Business > Investment > Surplus**

Domain ownership means **primary responsibility, preferred placement, and
accounting/governance grouping — NOT physical isolation or exclusive resource
ownership** (decided M2-2B/M2-2C, 20260605/20260606-01). Higher-priority work
outranks lower for contended resources; lower-priority work **yields idle capacity**;
**Research may consume idle resources on any node** (RESOURCE_POLICY.md §2). The
former `runtime` work-domain is superseded by this four-domain model; persistent
services are treated as **cross-cutting infrastructure**, not a work domain.

**Surplus** is formally **"low-priority utilization of otherwise idle compute
resources."** It is **not** an independent strategic domain; it exists solely to make
productive use of spare capacity after Research, Business, and Investment needs are
met. This definition holds wherever the domain list appears.

**Realization on disk** (DIRECTORY_STANDARD.md §2, ANALYSIS_ARCHITECTURE.md):
Research = **`analysis/`** (`{pipeline,container,reference,projects}`, shared NFS),
Business = `business/`, Investment = `investment/`, Surplus = `surplus/`; `research/`
is not used. By default:

- Code, data, models, and secrets **belong to** exactly one domain (logical
  ownership / accounting), and an agent **writes only its own domain's tree**
  (write-discipline). Shared mounts (e.g. `analysis/` on all nodes, M2-1) are
  expected and do **not** imply cross-domain use or break independence.
- Shared, domain-agnostic assets live in `resources` (DIRECTORY_STANDARD.md §4)
  and are read-only to consumers unless they own them.

The six top-level domains that **may** exist are: `analysis` (the **Research**
domain), `business`, `investment`, `surplus`, `resources`, `infra`. Handoff-worthy
session outputs are stored at **`/data/admin/handoff/`** (physical, backed up;
relocated M3-3D, 20260611; the old `/home/hha/ChatGPT_handoff` transition symlink was
**removed in M3-3F, 2026-06-12**). This is operational storage, not a work domain and not a top-level
namespace entry (§12, DIRECTORY_STANDARD.md §7). **Project directories
inside a domain may only be created after the project is approved** (e.g.
`analysis/projects/project_x`, `business/product_y`, `investment/strategy_z`). The
approval applies to the **project itself** — not to the directory operation;
once a project is approved, creating its directories is routine work
(PROJECT_LIFECYCLE.md).

## 2. Approval matrix

"User approval" means an explicit decision by `hha` (infra_admin). It cannot
be granted by any agent (Domain Orchestrator, Supervisor, Senior Engineer, or
Worker).

| Action | Approver | Why |
|--------|----------|-----|
| **Create a project** | **User** | New scope, new resource claim — always high-impact (PROJECT_LIFECYCLE.md) |
| **Retire / delete a project** | **User** | Irreversible; may destroy data (PROJECT_LIFECYCLE.md) |
| **Cross-domain migration** (move/copy code, data, or models between domains) | **User** | Breaks domain independence by design |
| **Change resource policy / quotas** | **User** | Affects all domains |
| **Install a high-risk component** (§2.3) | **User** | Persistent service, shared surface, security/reproducibility impact |
| **Delete data not regenerable from version control** | **User** | Irreversible |
| **Spend money / incur external cost** | **User** | Financial impact |
| **Install a medium-risk component** (§2.2) | Supervisor | Supervisor judgment + documentation |
| **Approve a medium-risk decision** | Supervisor | §2.2; + Senior Engineer review if it touches §3a |
| **Architecture / reproducibility / shared-lib / reusable-workflow / infra-standard change** | Supervisor approve **+ Senior Engineer review** | Quality gate before implementation (§3a) |
| **Install a low-risk prerequisite** (§2.1) | Worker | Pre-approved — no further approval |
| **Materialize a reserved domain dir** (one of the six) | Domain Orchestrator | Created with its first approved project; the *project* is what was approved |
| **Create a necessary directory within the standard** | Domain Orchestrator/Worker | Routine; unnecessary/duplicate/speculative dirs remain prohibited (§0) |
| Create a file/dir *inside* an existing approved project | Worker | Routine work |
| Resolve ambiguity / set strategy | Supervisor | The Supervisor's purpose (AGENT_ARCHITECTURE.md) |
| Architecture / code-quality / reproducibility review | Senior Engineer | Review gate (§3a) |
| Coordinate work across a domain | Domain Orchestrator | Domain-level coordination |
| Execute a scoped, reversible task | Worker | Routine work |

Anything not listed that is **irreversible, cross-domain, externally visible,
or costs money** defaults to **User approval**. Conversely, work that is
**necessary, in-scope, and reversible proceeds without approval** and is simply
documented (§0, §10).

Installation is tiered by *risk*, not by whether it is an installation at all:

### 2.1 Low-risk prerequisites — pre-approved (no further approval)

`git`, `tmux`, `vim`, `curl`, `wget`, `jq`, `tree`, `htop`, `uv`.

(`uv` ratified into this list 20260601-06: a single static-binary Python
manager — CLI, single-host, no daemon, no listener, easily removable.)

**Foundational runtimes** already present on the base image — **Node.js / npm**
(ratified low-risk 20260601-07) — are treated as foundational, not as project
dependencies; using them needs no approval. Project-level npm packages
(e.g. `pptxgenjs`) are a separate, **project-local medium-risk** matter
(ENVIRONMENT_POLICY.md "Output Automation").

A component qualifies as low-risk (and may be installed without approval) when
it is **all** of:

- a CLI utility,
- single-host,
- no daemon/service,
- no network listener,
- easily removable.

Other tools meeting *all* five characteristics may be installed on the same
footing. The install is still documented (§10). Unnecessary installs are
prohibited (§0).

### 2.2 Medium-risk components — Supervisor judgment + documentation

Shared tooling, reusable services, or anything with multi-user impact that is
**not** a §2.3 high-risk component. A Supervisor exercises judgment, confirms
the work is necessary, and documents the decision (§10). No User approval
required, but the rationale must be recorded.

Examples (ratified 20260601-06): **Conda/Mamba**; and **workflow engines**
themselves (**Nextflow**, **Snakemake**). A workflow engine *binary/runtime* is
medium-risk; the **shared execution backend it submits to is high-risk** (§2.3).

### 2.3 High-risk components — explicit User approval required

Slurm, Docker, Apptainer, Prometheus, Grafana, databases, message queues,
Kubernetes, **shared execution/orchestration backends (e.g. Slurm, Kubernetes,
Seqera/Nextflow Tower)**, and any external SaaS integration. These introduce
persistent services, shared attack surface, or security/reproducibility impact
and require **explicit User approval**. (Note: a workflow engine binary alone is
medium-risk per §2.2; only its shared backend is high-risk.)

## 3. Escalation (summary; full model in AGENT_ARCHITECTURE.md)

Escalation path: **Worker → Supervisor → Domain Orchestrator → User.**

- **Workers (Subagents) must not ask the user directly.** They escalate
  **directly to their Supervisor**.
- **Supervisors resolve ambiguity whenever possible** using policy and context
  (strategy, governance); they approve medium-risk decisions.
- **Domain Orchestrators** coordinate the domain and are the last stop before
  the User.
- **Only high-impact decisions reach the user** — specifically the rows marked
  "User" in §2, and anything matching the default-to-user clause.

The **Senior Engineer is a side review role, not part of this escalation
chain** (§3a, AGENT_ARCHITECTURE.md §3.2).

## 3a. Review requirements (Senior Engineer — side review)

The Senior Engineer is **not in the escalation chain (§3)**; it provides review,
architecture guidance, reproducibility review, and quality assurance.
Medium-risk decisions may be approved by a **Supervisor** (§2.2). In
**addition**, any change affecting **architecture, reproducibility, shared
libraries, reusable workflows, or infrastructure standards** must receive
**Senior Engineer review before implementation**. Routine, local, reversible
work touching none of these needs no such review. See AGENT_ARCHITECTURE.md
§3.2.

## 4. Reproducibility (mandatory)

Every result must be reproducible by another operator on a clean host:

1. **Code** is version-controlled; the exact commit is recorded with results.
2. **Environment** is captured as a manifest (lockfile + container image digest
   + recorded driver/CUDA versions) per **ENVIRONMENT_POLICY.md** —
   containers/workflow engines first, uv for Python, conda only as fallback.
   Every environment must produce a committed lockfile and/or a SHA256-pinned
   image.
3. **Data** is referenced by content hash (§6), not by mutable path alone.
4. **Randomness** is seeded and the seed recorded.
5. **Prompts** that produced AI output are versioned and referenced by ID (§8).
6. **Hardware assumptions** (GPU count, VRAM) are recorded when they affect
   results.

A result that cannot state its code commit, environment manifest, data hashes,
and seed is **not reproducible** and must not be reported as final.

## 5. Hallucination-reduction policy (mandatory, must stay documented)

Applies to every AI-generated factual claim, citation, number, or code path:

1. **Ground or abstain.** Claims of fact must cite a verifiable source or be
   explicitly marked as unverified. "I don't know" is an acceptable answer.
2. **No invented citations.** Citations follow §7 — no citekey, no citation.
3. **No invented APIs, files, flags, or numbers.** Verify against the actual
   file/tool/output before asserting it exists.
4. **Separate retrieved fact from inference.** Mark which is which.
5. **Verify before destructive or irreversible action** — re-read the target.
6. **Adversarial check for high-impact claims.** A claim feeding a User-level
   decision (§2) is independently verified by a second pass/agent before it is
   presented.
7. **Quantify uncertainty** where it matters; do not present a guess as a fact.

This section is itself governed: it may be strengthened by a Supervisor but
weakened only by User approval (§9).

## 6. Download integrity (SHA256)

Every file downloaded onto this host must be SHA256-verified:

- If the source publishes a hash, the download is verified against it before
  use; a mismatch is a hard stop.
- If no hash is published, compute and **record** the SHA256 alongside the
  file (e.g. a `*.sha256` sidecar or a manifest) so future integrity and
  reproducibility checks are possible.
- Unverifiable downloads are quarantined, not used, until a decision is made.

## 6a. Secrets (never committed)

Secrets — API keys, tokens, PATs, passwords, private/TLS keys, `.env` files,
connection strings, cloud and Zotero credentials — are **never** committed,
logged, or placed in prompts or figures. Storage, access, rotation, and backup
follow **SECRETS_POLICY.md**. Reproducibility (§4) is met by *referencing*
secrets (env vars / a non-secret manifest), never by storing their values. A
secret that touches the repo is treated as compromised and rotated immediately.

## 7. Citations

- **Zotero + Better BibTeX is the single source of truth** for references.
- Better BibTeX **citekeys** are the only legal way to cite. **No citekey → no
  citation.** Free-text or model-recalled references are prohibited.
- The exported `.bib` is a generated artifact derived from Zotero; it is not
  hand-edited. (Zotero itself is not yet installed — a deferred decision,
  §10 — but this rule is binding from the moment citations are produced.)

## 8. Prompt management (prompts are first-class assets)

- Significant prompts (anything that changes infrastructure, governance, or a
  project's direction) are archived under `infra/prompts/`.
- Filename format: **`YYYYMMDD-NN_name.md`**
  - `YYYYMMDD` — date the prompt was issued.
  - `NN` — two-digit sequence within that day, starting at `01`.
  - `name` — short kebab/underscore slug.
  - Examples: `20260601-01_bootstrap.md`, `20260601-02_governance.md`.
- Each archived prompt records: the verbatim prompt, the date, the role, and a
  one-line outcome. Keep it that simple — **no prompt framework, no templating
  engine, no tags taxonomy.** A flat, dated, append-only folder is the system.
- Routine, low-impact prompts need not be archived. When in doubt about
  whether something is "significant," a Supervisor decides; structural changes
  always are.

## 9. Output-format rules

- **Figures** are always exported as **both PNG (raster) and vector PDF.** A
  figure that exists only as PNG is incomplete.
- Other generated artifacts state their provenance (code commit, inputs).

## 10. Changing this governance

- **Infrastructure changes must be documented.** No undocumented change to
  structure, policy, or installed software is legitimate.
- Edits to governance documents are themselves changes: record what changed and
  why (commit message or a dated note). Weakening §4 (reproducibility), §5
  (hallucination reduction), §6 (downloads), or §7 (citations) requires **User
  approval**. Clarifying or strengthening them may be done by a Supervisor and
  documented.

## 11. Deferred decisions referenced above

These are open and listed in full in the bootstrap deliverable's "Missing
decisions" section; pointers here so the rules above are honest about their
preconditions:

- ~~Environment/dependency manager~~ — **RESOLVED 20260601-05**
  (ENVIRONMENT_POLICY.md): containers/workflow engines first, uv for Python,
  conda fallback, system packages foundational-only. Tools not yet installed.
- ~~Version-control host and remote~~ — **RESOLVED**: GitHub private repo
  `hay2k/hay2k-infra`, off-host push live since 2026-06-01.
- Zotero install + storage location on a headless host (affects §7).
- ~~Backup target / off-host destination~~ — **RESOLVED 2026-06-02**: approved
  strategy is **3-node on-cluster replication** (data mirrored to peer disks +
  age-encrypted secrets + daily timer + tested restore). **Off-site is out of
  scope by operator decision — whole-site-loss risk accepted**
  (BACKUP_AND_RECOVERY.md §3, §6; SECRETS_POLICY.md §6).
- ~~Secrets management~~ — **RESOLVED 20260601-04** (§6a, SECRETS_POLICY.md):
  file-based + permission-enforced now, encryption required before off-host.
- ~~Presentation automation~~ — **RESOLVED 20260601-07** (ENVIRONMENT_POLICY.md
  "Output Automation"): approved capability via **Node.js** (low-risk
  foundational runtime, already present) + **pptxgenjs** (medium-risk,
  project-local only, `package-lock.json` pinned). **Implementation deferred —
  pptxgenjs not installed, no templates/pipelines created.**
- ~~Node-role strategy~~ — **DESIGNED 20260601-08** (NODE_ARCHITECTURE.md):
  hybrid control-plane (`gpu-01` primary + `gpu-02` backup) with symmetric
  compute across all 3 nodes. Design only; no node dirs/services.
- ~~Shared storage (NFS / cluster FS)~~ — **RATIFIED 20260601-10**
  (STORAGE_ARCHITECTURE.md): **NFS = canonical primary shared filesystem.** MinIO
  object store = deferred second tier; Syncthing/local cache = measured
  optimization only; Ceph/Gluster not justified at 3 nodes. **Deployment
  deferred (no NFS service installed, no shared-storage dirs);** an NFS
  server / MinIO are high-risk (§2.3) to deploy.
- **Node hostname/role realization & cluster networking** — **OPEN; partially
  discovered 20260601-13** (NETWORK_DISCOVERY.md): `gpu-01` = single 1 GbE link
  on a **public IP**, SELinux enforcing, only SSH listening, **no inter-node
  network and no knowledge of `gpu-02`/`gpu-03`**. Inter-node connectivity,
  topology, and the other nodes' inventory remain **partially unknown**.
  **Update 20260601-14:** `gpu-02` (`.31`) and `gpu-03` (`.32`) are **reachable**
  on the shared public `222.231.57.0/24` with **sub-ms latency** (same L2
  segment); inter-node connectivity is **confirmed**. Still **pending**: peer
  inventory + link speeds (**SSH auth not yet available**) and whether the `/24`
  is dedicated or shared. No private network exists. See
  CLUSTER_NETWORK_SUMMARY.md. Realize roles only when services are deployed
  (with approval).
- ~~Monitoring / observability strategy~~ — **DESIGNED 20260601-11**
  (OBSERVABILITY.md): Prometheus + node-exporter + DCGM-exporter + Grafana +
  Alertmanager (Loki optional), singleton-on-control + exporters-on-all-nodes;
  Phase 0 zero-install baseline now; full stack is **high-risk §2.3** to deploy.
  Nothing installed.
- ~~Security & hardening policy~~ — **DESIGNED 20260601-12**
  (SECURITY_AND_HARDENING_POLICY.md): proportionate baseline (mandatory/
  recommended/optional controls) for host, network, filesystem, secrets, supply
  chain, agents, logging, backup, incident response, future services. Nothing
  applied. Its **unresolved sub-decisions** (SSH MFA, commit signing, auditd,
  secrets-encryption tool, service-account model, networking) remain OPEN and
  User-gated (SECURITY_AND_HARDENING_POLICY.md §13).

## 12. Handoff artifacts (operating rule)

**Status:** Active from 2026-06-04 (20260604-01), User-approved.

Substantial, self-contained outputs are **persisted automatically as Markdown
files** so they survive the session and are usable by another operator/tool —
this does not need to be re-requested per task.

- **Scope (save):** assessments, milestone completions, implementation reviews,
  architecture reviews, research/planning documents, and handoff notes.
- **Out of scope (do not save):** routine conversational replies, trivial edits,
  and in-progress scratch (minimalism, §0).
- **Location:** **`/data/admin/handoff/`** (physical, on gpu-01's `/data`, backed up;
  relocated from `/home/hha/ChatGPT_handoff` in M3-3D, 20260611; the old-path
  transition symlink was **removed in M3-3F, 2026-06-12**). Cross-cutting operational storage, **not** a top-level
  namespace entry (§1; structure/front-matter in DIRECTORY_STANDARD.md §7).
  Subdirectories are created **as needed**, never pre-created.
- **Form:** one self-contained Markdown file with YAML front-matter; filename
  `YYYY-MM-DD_<kebab-title>.md`.
- **New files only — `README.md` is static.** Each artifact is added as a **new**
  Markdown file. `ChatGPT_handoff/README.md` is **not** modified and **no index is
  maintained** in it (operator decision 20260604-02).
- **Report:** the saved path is reported at the end of the task.

This is an operating convention, not a reproducibility/citation rule; it may be
refined by a Supervisor and documented (§10). The directory itself (a new
top-level outside the reserved namespace) was the User-gated part (DIRECTORY_STANDARD.md §6).
