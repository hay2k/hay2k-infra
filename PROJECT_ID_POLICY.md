# PROJECT ID POLICY

**Status:** CANONICAL from 2026-06-06 (promoted M3-0, 20260606-01). Supersedes the
M2-2 draft in `ChatGPT_handoff/`.
**Scope:** The master project identifier used across all artifacts.

---

## 1. Rationale
A stable **master identifier per project** gives end-to-end traceability: the same
ID ties together code, data, manuscripts, meeting notes, research notes, Claude Code
logs, and ChatGPT handoffs. IDs are short, sortable, collision-free, and independent
of the human-readable name.

## 2. Frozen decisions
- **Main IDs are domain-prefixed:** `P####` Research · `B####` Business · `I####`
  Investment · `S####` Surplus — 4-digit zero-padded, **per-domain sequential** —
  plus `_short_name` (lowercase `snake_case`). The directory name is the full `<ID>`.
- **Subprojects keep the `-S##` suffix** (human-readable, clearly a subproject):
  `P0001-S01`, `B0001-S01`, `I0001-S01`, `S0001-S01`. (`-S##` is retained; **not**
  replaced by `-NN`.)
- **Disambiguation rule:** the **leading letter = DOMAIN**; the **`-S##` suffix =
  SUBPROJECT**. They never conflict (distinct by position): `S0001` is a Surplus
  project; `P0001-S01` is subproject 01 of P0001; `S0001-S01` is subproject 01 of
  Surplus project S0001.
- **Priority is derivable from the prefix:** Research > Business > Investment >
  Surplus (GOVERNANCE.md §1).
- **The ID is the master key**, reused verbatim across manuscripts, meeting notes,
  research notes, Claude Code logs, and ChatGPT handoffs.
- **Binding:** code = `<domain-tree>/projects/<ID>/` (research = `analysis/`);
  data = `/data/<ID>/`. **Numbers are never reused** (permanent for provenance).
- **Every project is recorded in PROJECT_REGISTRY.md** (mandatory).

## 3. Examples
```
P0001_nanopore_modification_ai     # Research, Tier 1 (anchor)
P0002_a_to_i_editing               # Research, Tier 2
B0001_<name>                       # Business
I0001_<name>                       # Investment
S0001_<name>                       # Surplus (idle-capacity utilization)

# Subprojects
P0001-S01_mod_calling   P0001-S02_ai_prediction   P0001-S03_validation
S0001-S01_<name>        # Surplus project S0001, subproject 01

# Cross-artifact reuse (same ID)
/data/P0001_nanopore_modification_ai/                  # data
P0001_modification_ai_manuscript_v1.docx               # manuscript
ChatGPT_handoff/2026-07-01_P0001-S02_ai_prediction_review.md   # handoff
```

## 4. Future scalability
- Capacity: `####` mains per domain, `S01`–`S99` subprojects each.
- **PROJECT_REGISTRY.md** is the authority for the next free number and the
  never-reuse rule.
- Retirement keeps the ID reserved (PROJECT_LIFECYCLE.md); records persist.
- Future artifact tooling consumes the ID as its primary key — no new identifier
  scheme (GOVERNANCE §0).
