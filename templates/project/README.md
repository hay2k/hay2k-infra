# {{PROJECT_ID}} — {{PROJECT_NAME}}

- **Domain:** {{DOMAIN}}
- **Status:** proposed → active ({{DATE}})
- **Owner:** {{OWNER}}
- **Origin:** {{ORIGIN}}            <!-- created | imported -->
- **Source (if imported):** {{SOURCE}}
- **Approving prompt:** {{PROMPT_ID}}
- **Created:** {{DATE}}

## What this is
{{PROJECT_NAME}} — one-line description.

## Canonical files (source of truth for execution)
- `PROJECT_MASTER.md` — authoritative spec (PROJECT_SPECIFICATION_POLICY.md)
- `ENVIRONMENT_MANIFEST.md` — pinned platform dependencies + Capability Resolution (PLATFORM_REUSE_POLICY.md)
- `TODO.md` — actionable work queue
- project configs (in `src/`)

## docs/ (documentation only — reference, NOT executed)
See `docs/` for proposal / handoff / protocol / literature / meeting materials
(DIRECTORY_STANDARD.md §3; PROJECT_LIFECYCLE.md §4/§4a). Imported prior materials are
**reference only** and never treated as canonical execution instructions.

## Platform consumption (Reuse-First)
This project **consumes** shared platform capabilities by pinning exact versions in
`ENVIRONMENT_MANIFEST.md` — it does not fork/redefine them (PLATFORM_REUSE_POLICY.md).
Discover capabilities: `ANALYSIS_ROOT=/data/analysis analysis-install catalog`.
