# SYSTEM OVERVIEW

**Status:** Bootstrap (no projects exist yet)
**Established:** 2026-06-01
**Maintainer:** `hha` (role: infra_admin — sole human operator)
**Governs:** AI Research Infrastructure on a single GPU node

---

## 1. Purpose

This node is a shared compute substrate intended to support, over time, four
independent kinds of work — **research**, **business**, **investment**, and
**runtime** workloads — backed by shared **resources** and governed by a
documented **infra** layer.

At bootstrap time **none of these projects exist**. This repository of
documents defines *how* work will be organized and governed *before* any work
begins. It does not create the work.

## 2. Hardware (3-node cluster; corrected 20260601-08)

The cluster is **three nodes** — `gpu-01`, `gpu-02`, `gpu-03` — each:

| Per-node resource | Detail |
|----------|--------|
| OS | Rocky Linux 10 |
| GPU | 2 × NVIDIA RTX 6000 Ada Generation (48 GB VRAM each, 96 GB/node) |
| CPU | 48 logical cores (as measured on the bootstrap node) |
| Memory | 188 GiB RAM (as measured on the bootstrap node) |
| Storage | Single ~1.8 TB volume at `/` per node (no separate data mount, no redundancy) |

**Cluster totals: 6 GPUs, 288 GB VRAM.** Node roles (a hybrid control-plane
with symmetric compute) are designed in **NODE_ARCHITECTURE.md**. There is **no
shared storage and no scheduler yet** — both are open decisions
(RESOURCE_POLICY.md, GOVERNANCE.md §11). The earlier "single host" assumption is
superseded; capacity, backup, and migration planning now span three nodes.
**Networking caveat (NETWORK_DISCOVERY.md):** as of 2026-06-01, `gpu-01` has a
single 1 GbE link on a public IP and **no verified inter-node network** to
`gpu-02`/`gpu-03`; cluster connectivity must be established before NFS/Slurm/
cross-node monitoring can be deployed.

## 3. Domains

Six top-level workspaces are the *approved namespace*. They are not all
created yet — see DIRECTORY_STANDARD.md for what exists today versus what is
reserved.

| Domain | Purpose | Created? |
|--------|---------|----------|
| `research` | Scientific / experimental projects, papers, datasets | reserved |
| `business` | Revenue-bearing or operational projects | reserved |
| `investment` | Investment analysis and portfolio work | reserved |
| `runtime` | Long-lived background workloads and services | reserved |
| `resources` | Shared, domain-agnostic assets (models, datasets, citations, fonts) | reserved (created on first real shared asset) |
| `infra` | Governance, prompts, configuration, operational tooling | **exists now** |

The four work domains are **independent**: code, data, and configuration do
not flow between them without explicit user approval (GOVERNANCE.md).

## 4. Workspace root and the version-controlled infrastructure root

- **Workspace root:** `/home/hha` — the six domains are direct children.
- **Version-controlled infrastructure root:** `/home/hha/infra` — this is the
  git repository (governance + prompts). Decided 2026-06-01; work domains, when
  created, get their own version control rather than sharing infra's history.

```
/home/hha/                  # workspace root ($HOME; domains are direct children)
└── infra/                  # the only domain instantiated at bootstrap — a git repo
    ├── SYSTEM_OVERVIEW.md
    ├── GOVERNANCE.md
    ├── PROJECT_LIFECYCLE.md
    ├── DIRECTORY_STANDARD.md
    ├── AGENT_ARCHITECTURE.md
    ├── AGENT_RUNTIME.md
    ├── RESOURCE_POLICY.md
    ├── BACKUP_AND_RECOVERY.md
    ├── SECRETS_POLICY.md
    ├── ENVIRONMENT_POLICY.md
    ├── NODE_ARCHITECTURE.md
    ├── STORAGE_ARCHITECTURE.md
    ├── OBSERVABILITY.md
    ├── SECURITY_AND_HARDENING_POLICY.md
    ├── NETWORK_DISCOVERY.md
    ├── NETWORK_DISCOVERY_gpu02.md   # blocked (unreachable)
    ├── NETWORK_DISCOVERY_gpu03.md   # blocked (unreachable)
    ├── CLUSTER_NETWORK_SUMMARY.md
    ├── IMPLEMENTATION_LOG.md
    ├── CLUSTER_STATUS.md
    ├── CLUSTER_READINESS_REVIEW.md
    ├── HARDENING_IMPACT_REVIEW.md
    ├── CLUSTER_SSH_AUDIT.md
    ├── INFRA_CHANGELOG.md
    ├── .gitignore
    ├── hooks/              # tracked git hooks (install into .git/hooks)
    │   └── pre-commit      # secret-scan (SECRETS_POLICY.md §8)
    └── prompts/            # 20260601-{01..15}; secrets live OUTSIDE the repo (~/.secrets/)
```

`infra/` being its own git repo means the most critical, smallest tier
(governance, prompts) migrates as one versioned unit, independent of bulk
domain data (see "Future migration" in BACKUP_AND_RECOVERY.md).

## 5. Operating model in one paragraph

The User sets policy and approves high-impact, irreversible, or cross-domain
decisions. **Domain Orchestrator** agents coordinate a domain; **Supervisor**
agents own its strategy, governance, and ambiguity resolution; and **Worker**
agents (a.k.a. Subagents) implement scoped tasks. The primary escalation chain
is **Worker → Supervisor → Domain Orchestrator → User**, never directly to the
User. **Senior Engineer** agents sit *beside* this chain as a side review role —
architecture guidance, reproducibility review, and quality assurance — not in
the escalation path (AGENT_ARCHITECTURE.md). Every infrastructure change is
documented; every prompt is versioned; every download is hash-verified; every
citation has a
citekey or it does not exist.

## 6. Document map

| Document | Answers |
|----------|---------|
| SYSTEM_OVERVIEW.md | What is this and what hardware backs it? |
| GOVERNANCE.md | What are the rules and who approves what? |
| PROJECT_LIFECYCLE.md | How do projects get created, migrated, and retired (the remaining User gates)? |
| SECRETS_POLICY.md | How are credentials stored, accessed, rotated, and kept out of git? |
| ENVIRONMENT_POLICY.md | How are software environments built/pinned, and when is it a container vs. conda vs. system package? |
| NODE_ARCHITECTURE.md | What is each cluster node's role, and where do services and agents run? |
| STORAGE_ARCHITECTURE.md | Which shared-storage approach (NFS/Gluster/Ceph/Syncthing/object), and why? |
| OBSERVABILITY.md | How are the cluster, GPUs, jobs, and agents monitored (metrics/logs/alerts)? |
| SECURITY_AND_HARDENING_POLICY.md | How is the cluster secured/hardened (host/network/fs/secrets/supply-chain/agents/incident)? |
| NETWORK_DISCOVERY.md | Observed networking state of `gpu-01` (point-in-time): interfaces, IPs, exposure, unknowns |
| NETWORK_DISCOVERY_gpu02/03.md | Per-node discovery (currently **blocked** — `gpu-02`/`gpu-03` unreachable from `gpu-01`) |
| CLUSTER_NETWORK_SUMMARY.md | Cross-node comparison + NFS/Slurm feasibility (partial; inter-node path unverified) |
| IMPLEMENTATION_LOG.md | Implementation phases: what's installed/validated, issues, rollback notes, blockers |
| CLUSTER_STATUS.md | Current operational state of the 3-node cluster (components, versions, monitoring, NFS, blockers) |
| CLUSTER_READINESS_REVIEW.md | Readiness assessment: capabilities, gaps, risks, workload/domain readiness, backup + first-project recommendations |
| HARDENING_IMPACT_REVIEW.md | Per-control impact analysis + classification + phased plan, before applying any hardening |
| CLUSTER_SSH_AUDIT.md | SSH topology audit (resolution, keys, authorized_keys, path matrix) + remediation plan; H1 prerequisite |
| DIRECTORY_STANDARD.md | Where does anything go, and when is a directory allowed to exist? |
| AGENT_ARCHITECTURE.md | Who (worker/supervisor/human) decides what, and how do escalations flow? |
| AGENT_RUNTIME.md | How do agents actually run (Claude Code + tmux→Slurm), and what are their lifecycles? |
| RESOURCE_POLICY.md | How are GPU, CPU, RAM, and disk shared across domains? |
| BACKUP_AND_RECOVERY.md | What is backed up, how is it restored, how do we migrate servers? |
| INFRA_CHANGELOG.md | What changed in the infrastructure, when, and why? |

## 7. Scope of work at bootstrap (and the corrected operating principle)

At bootstrap, only governance was *necessary*, so only governance was done. The
following were intentionally **not yet needed** — not prohibited:

- No software was installed *because none was needed yet*. Low-risk
  prerequisites (`git`, `tmux`, `vim`, `curl`, `wget`, `jq`, `tree`, `htop`)
  may be installed as needed without further approval; medium-risk components
  need Supervisor judgment, and high-risk components need explicit User
  approval (GOVERNANCE.md §2.1–§2.3).
- No project directories, templates, or example projects were created (project
  creation is a User decision — PROJECT_LIFECYCLE.md).
- No empty domain directories were materialized **speculatively**. Speculative
  future structures remain prohibited; necessary directories are created when
  needed (DIRECTORY_STANDARD.md, GOVERNANCE.md §0).

The governing rule (GOVERNANCE.md §0): *unnecessary* installations, *unnecessary*
directories, and *speculative* structures are prohibited — but necessary
infrastructure work proceeds without unnecessary approval overhead.

Prompts of record: `20260601-01_bootstrap.md` (archived);
`-02_bootstrap_revision.md`, `-03_governance_refinement.md`,
`-04_secrets_policy.md`, `-05_environment_policy.md`,
`-06_risk_ratification.md`, `-07_presentation_and_agent_tiers.md`,
`-08_node_role_design.md`, `-09_storage_evaluation.md`,
`-10_agent_runtime.md`, `-11_observability.md`,
`-12_security_hardening.md`, `-13_network_discovery.md`,
`-14_network_discovery_peers.md` (kept milestones); and
`20260601-15_implementation.md` (current).
