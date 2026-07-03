# 20260702-04 — M5-2: Project Knowledge Lifecycle

**Date:** 2026-07-02
**Role:** User (operator `hha`) → platform utilization (knowledge as a living asset)
**Prompt (verbatim intent):** "M5-2 — implement the complete Project Knowledge Lifecycle. Knowledge
is a continuously evolving project asset, not a static document. Extend (do not redesign) the
existing framework; reuse CLI/templates/governance. Lifecycle: Initialize → Ingestion →
Classification → Curation → Update → Reuse → Project Completion. Source location always specified by
the operator (no fixed temp dir); source-agnostic (folders, md, pdf, txt, Word, spreadsheets,
Claude handoffs, ChatGPT conversations, notes, protocols, literature, scripts, configs, figures,
tables). Processing: incoming → read → classify → deduplicate → determine destination → update the
corresponding knowledge docs → preserve provenance → archive processed (optional). Update only
relevant sections; merge; avoid duplication; never rewrite the whole base. Preserve source
provenance (extract reusable knowledge only, don't copy whole conversations). AI conversations are
supporting material (extract reusable decisions/reasoning/recommendations/ideas; discard filler/
superseded). Literature: summarize reusable knowledge, don't duplicate bibliography. Knowledge feeds
PROJECT_MASTER/TODO/execution planning/reconstruction but is never an execution input; PROJECT_MASTER
is the execution entry point. Extend the CLI for incremental updates + arbitrary source dirs.
Validate in temp only; demonstrate repeated updates to the same knowledge; don't modify any real
project. One handoff."

**Outcome:** New CLI **`scripts/project-knowledge`** (extends M5-1; provider-agnostic, no LLM —
agents supply judgment, the tool records/merges): `init · ingest · classify · add · provenance ·
status · archive · derive`.
- **ingest** `--from <PATH>` (operator-specified, source-agnostic) → `attachments/_inbox/` + sha256
  + provenance ledger (`PROVENANCE.tsv`) + classification hint.
- **add** `--section NN --source "PROV"` → incremental, provenance-stamped, **deduplicated** append
  (never a full rewrite); knowledge grows more organized over time.
- **derive** `--out` → PROJECT_MASTER/TODO **drafts** from the sections (Reuse). Knowledge never an
  execution input.
- PROJECT_LIFECYCLE §4a + PLATFORM_VERSION v1.2 changelog updated.

**Validated (temp only):** init → ingest (md + pdf) → classify → add(03,05) → dedup(skip) →
repeated update (2nd item into 03) → status → provenance (6 records) → archive → derive drafts. No
real project modified. **Freeze-compliant platform v1.2.** Handoff:
`2026-07-02_m5-2-project-knowledge-lifecycle.md`.
