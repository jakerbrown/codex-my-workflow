# Plan: twitter integration gap evaluation

- **Date:** 2026-04-08
- **Status:** IN PROGRESS
- **Owner:** Codex
- **Quality target:** 90

## Goal

Evaluate which features of `codex-my-workflow` are not yet well integrated into
the twitter repo and produce a concrete gap analysis grounded in the current
twitter-repo files.

## Scope

- In scope:
  - Inspect the twitter repo's current workflow integration files and folders.
  - Compare them against this repo's workflow features and integration
    expectations.
  - Identify missing, partial, or weakly integrated features.
  - Summarize the highest-value next integration steps.
- Out of scope:
  - Editing the twitter repo in this pass.
  - Running the twitter repo's project code or heavy analyses.
  - Claiming integration gaps that are not supported by inspected files.

## Assumptions and clarifications

- CLEAR:
  - The user asked for evaluation, not immediate implementation.
- ASSUMED:
  - "Well integrated" means present in repo guidance and durable structure, not
    only mentioned loosely in prose.
  - The comparison baseline is this repo's current workflow infrastructure,
    guidance, and reusable templates.
- BLOCKED:
  - None.

## Files likely to read

- `/Users/jacobbrown/Documents/GitHub/twitter/AGENTS.md`
- `/Users/jacobbrown/Documents/GitHub/twitter/KNOWLEDGE_BASE.md`
- `/Users/jacobbrown/Documents/GitHub/twitter/MEMORY.md`
- `/Users/jacobbrown/Documents/GitHub/twitter/README.md`
- `/Users/jacobbrown/Documents/GitHub/twitter/plans/README.md`
- `/Users/jacobbrown/Documents/GitHub/codex-my-workflow/AGENTS.md`
- `/Users/jacobbrown/Documents/GitHub/codex-my-workflow/docs/CODEX_WORKFLOW.md`
- `/Users/jacobbrown/Documents/GitHub/codex-my-workflow/templates/workflow-integration-overlay.md`

## Implementation approach

1. Inventory the twitter repo's existing workflow surfaces and durable state
   locations.
2. Compare them against this repo's workflow features: planning/logging,
   specialist review, scoped adversarial review, durable reporting, hooks,
   skills/plugins, and verification conventions.
3. Distinguish full, partial, and missing integrations.
4. Deliver a concise gap analysis with file-backed evidence.

## Verification plan

- Compile / render:
  - Not applicable.
- Run scripts / tests:
  - None; this is an inspection task.
- Manual checks:
  - Re-read the twitter repo guidance after inspection to avoid overstating
    gaps.
  - Confirm each claimed gap corresponds to a missing file, folder, or absent
    guidance element.
- Reports to write:
  - This plan
  - Matching session log

## Review plan

- Specialists to spawn:
  - None; this is a bounded repo-audit task.
- Whether adversarial QA is needed:
  - No.
- Final quality threshold:
  - 90
