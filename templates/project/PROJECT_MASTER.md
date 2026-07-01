# PROJECT_MASTER — {{PROJECT_ID}} ({{PROJECT_NAME}})

**Authoritative spec / source of truth** (PROJECT_SPECIFICATION_POLICY.md). Execution reads
this file (+ ENVIRONMENT_MANIFEST.md / TODO.md / configs) — not `docs/`
(AGENT_WORKFLOW_STANDARD.md §2).

- **Project ID:** {{PROJECT_ID}}
- **Domain:** {{DOMAIN}}
- **Origin:** {{ORIGIN}}   (source: {{SOURCE}})
- **Created:** {{DATE}}    **Approving prompt:** {{PROMPT_ID}}

## 1. Objective
<what this project produces; the scientific/technical question>

## 2. Scope & deliverables
<in-scope outputs; explicit out-of-scope>

## 3. Inputs & data
<raw data location `/data/{{PROJECT_ID}}/`, provenance, content hashes>

## 4. Method / plan
<analysis/implementation plan; for imports: the reconstruction plan — see docs/RECONSTRUCTION.md>

## 5. Platform capabilities (pinned — see ENVIRONMENT_MANIFEST.md)
<pipelines / containers / references / models reused, exact versions>

## 6. Validation
<how results are checked; reproducibility tuple GOVERNANCE §4>

## 7. Status / milestones
<current milestone; decisions log>
