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

## 2. Hardware (as measured 2026-06-01)

| Resource | Detail |
|----------|--------|
| GPU | 2 × NVIDIA RTX 6000 Ada Generation (48 GB VRAM each, 96 GB total) |
| CPU | 48 logical cores |
| Memory | 188 GiB RAM |
| Storage | Single 1.8 TB volume mounted at `/` (no separate data mount, no redundancy) |
| Host topology | Single node — no cluster scheduler, no second machine |

The "GPU cluster" today is **one host**. This is the single most important
fact for capacity, backup, and migration planning (see RESOURCE_POLICY.md and
BACKUP_AND_RECOVERY.md).

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
    ├── RESOURCE_POLICY.md
    ├── BACKUP_AND_RECOVERY.md
    ├── SECRETS_POLICY.md
    ├── INFRA_CHANGELOG.md
    ├── .gitignore
    ├── hooks/              # tracked git hooks (install into .git/hooks)
    │   └── pre-commit      # secret-scan (SECRETS_POLICY.md §8)
    └── prompts/            # 20260601-0{1..4}; secrets live OUTSIDE the repo (~/.secrets/)
```

`infra/` being its own git repo means the most critical, smallest tier
(governance, prompts) migrates as one versioned unit, independent of bulk
domain data (see "Future migration" in BACKUP_AND_RECOVERY.md).

## 5. Operating model in one paragraph

Humans set policy and approve high-impact, irreversible, or cross-domain
decisions. **Supervisor** agents own a domain's strategy, governance, and
quality. **Orchestrator** agents coordinate work within an approved project.
**Worker** agents (a.k.a. Subagents) do scoped tasks and escalate upward —
Worker → Orchestrator → Supervisor → human, never directly to the human
(AGENT_ARCHITECTURE.md). Every infrastructure change is documented; every
prompt is versioned; every download is hash-verified; every citation has a
citekey or it does not exist.

## 6. Document map

| Document | Answers |
|----------|---------|
| SYSTEM_OVERVIEW.md | What is this and what hardware backs it? |
| GOVERNANCE.md | What are the rules and who approves what? |
| PROJECT_LIFECYCLE.md | How do projects get created, migrated, and retired (the remaining User gates)? |
| SECRETS_POLICY.md | How are credentials stored, accessed, rotated, and kept out of git? |
| DIRECTORY_STANDARD.md | Where does anything go, and when is a directory allowed to exist? |
| AGENT_ARCHITECTURE.md | Who (worker/supervisor/human) decides what, and how do escalations flow? |
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

Prompts of record: `20260601-01_bootstrap.md` (archived),
`20260601-02_bootstrap_revision.md` and `20260601-03_governance_refinement.md`
(kept milestones), and `20260601-04_secrets_policy.md` (current).
