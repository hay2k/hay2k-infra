# Knowledge Acquisition package — {{PROJECT_ID}} ({{PROJECT_NAME}})

**Research Knowledge Acquisition Framework** (platform-wide, project-independent; M5-1). Acquires
the **research knowledge** needed to **reconstruct** a legacy/previous project on **Platform v1.0**
— *not* to migrate code, results, or execution environments. This package is the **input to
`PROJECT_MASTER.md` generation** (and seeds `TODO.md` + `ENVIRONMENT_MANIFEST.md`). It is
reference/input only — never an execution input (`project-run` reads only the canonical files).

- **Source environment:** {{SOURCE}}
- **Prepared:** {{DATE}}   **Prepared by:** {{PREPARED_BY}}

## Contents
```
knowledge/
  01_project_overview.md    biological question, objective, datasets, scope, expected outputs
  02_analysis_strategy.md   the WHY (not only what); decisions + why alternatives rejected
  03_trial_and_error.md     attempt → problem → reason → solution → final decision  (★ high priority)
  04_refactoring.md         reusable improvements (avoid non-reusable implementation detail)
  05_ai_knowledge.md        reusable knowledge by origin (Claude / ChatGPT / other LLMs)
  06_literature.md          important papers/concepts/landmark methods/future directions (no dup bibliography)
  07_open_questions.md      completed knowledge vs remaining unknowns
  08_reconstruction_plan.md how to rebuild on Platform v1.0 (never the legacy env as target)
  attachments/              figures, tables, exported notes referenced above
```

## Rules (binding)
- **No fabrication (GOVERNANCE §5).** Ground every statement in a real source; mark **[unverified]**
  when uncertain. An empty section beats invented content.
- **Knowledge, not files/code/results.** Summaries + reasoning; large exported artifacts go under
  `attachments/` and are referenced.
- **No duplication.** Do not restate the bibliography (Zotero, §7) or copy PROJECT_MASTER/TODO/
  ENVIRONMENT_MANIFEST content — this package **feeds** them.
- **Reconstruct on Platform v1.0** (§08) — Reuse-First over shared capabilities
  (`analysis-install catalog`); never target the legacy environment.

## Platform integration (how it is consumed)
```
Legacy Research → Knowledge Acquisition (this package) → PROJECT_MASTER → Capability Resolution
                → Execution → Validation → Figures → Publication
```
- **`project-bootstrap`** scaffolds this package (`kt-init`) and the project tree.
- `08` + `01`/`02` → `PROJECT_MASTER.md`; open items in `03`/`07` → `TODO.md`; recommended
  capabilities → pinned `ENVIRONMENT_MANIFEST.md` (Capability Resolution, Reuse-First).
- **`project-run`** then executes from those canonical files (this package is not read at run time).

Reusable for **any** legacy project (P0001/P0002/P0003 will all use this exact framework).
