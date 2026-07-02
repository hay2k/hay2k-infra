# Knowledge Transfer package — {{PROJECT_ID}} ({{PROJECT_NAME}})

**Purpose.** Transfer the **research knowledge** needed to **reconstruct** a project from
scratch on the GPU platform — *not* to migrate files (PROJECT_LIFECYCLE §4a). This package is
the **input** the platform later consumes to generate `PROJECT_MASTER.md`, `TODO.md`, and an
execution plan. It is **not** part of project execution and is **never** an execution input
(`project-run` reads only the canonical files; docs/ is reference-only).

- **Source environment:** {{SOURCE}}
- **Prepared:** {{DATE}}   **Prepared by:** {{PREPARED_BY}}

## Contents
```
knowledge_transfer/
  01_project_overview.md      objective, biological question, datasets, design, scope
  02_analysis_strategy.md     why each method; why alternatives rejected; assumptions
  03_trial_and_error.md       attempt → problem → solution → final decision (HIGH priority)
  04_refactoring_summary.md   original → refactoring → improvements → remaining limitations
  05_claude_summary.md        reusable design decisions from prior Claude Code work
  06_chatgpt_summary.md       ideas / literature / rejected ideas / future directions
  07_open_questions.md        unresolved issues (separated from completed work)
  08_reconstruction_plan.md   recommended NEW implementation on the GPU platform
  Attachments/                figures, tables, exported notes referenced above
```

## Rules (binding)
- **No fabrication (GOVERNANCE §5).** Every statement is grounded in a real source (legacy
  project file, prior Claude/ChatGPT record, paper). Mark anything uncertain as **[unverified]**.
  An empty section is preferable to invented content.
- **Cite sources.** Reference the originating artifact (path/file, chat date, DOI). Literature
  citations follow GOVERNANCE §7 (Zotero citekeys) once materialized.
- **Knowledge, not files.** Summaries + reasoning, not raw dumps. Put large exported artifacts
  under `Attachments/` and reference them.
- **Recommend the NEW implementation** (§08), not the legacy one — reconstruct on shared
  platform capabilities (Reuse-First; `analysis-install catalog`).

## How the platform consumes this
`08_reconstruction_plan` + `01`/`02` → seed `PROJECT_MASTER.md`; open items in `03`/`07` → seed
`TODO.md`; the recommended capabilities → the pinned `ENVIRONMENT_MANIFEST.md`
(Capability Resolution). Then `project-run` executes.
