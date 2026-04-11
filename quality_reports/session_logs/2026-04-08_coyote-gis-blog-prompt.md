# Session Log: coyote gis blog prompt

- **Date:** 2026-04-08
- **Status:** COMPLETED

## Current objective

Design a detailed master prompt for a future Codex run that will analyze coyote
sighting clustering in Belmont and related Massachusetts municipal GIS data, and
turn that work into a strong blog post.

## Timeline

### 12:32 - Reconnaissance
- Summary: Reviewed exploration guidance and the repo's analysis-oriented skill
  to make sure the prompt pushes toward reproducible empirical work.
- Files in play: `explorations/AGENTS.md`, the `data-analysis` skill, and prior
  prompt-packaging artifacts.
- Next step: Create the new exploration scaffold and write the master prompt.

### 12:39 - Design choice
- Decision: Frame the project around the distinction between ecological
  clustering and reporting clustering.
- Why: That is the interesting empirical question, and it naturally forces a
  stronger design than simply making hotspot maps.
- Impact: The prompt now emphasizes super-caller diagnostics, basemap/context
  layers, and cautious interpretation.

### 12:45 - Workflow hardening
- Decision: Explicitly require specialist review, durable review reports, and
  an adversarial critic/fixer cycle in the future run.
- Why: Without those constraints, Codex is more likely to stop after a
  competent first-pass spatial analysis.
- Impact: The prompt now more strongly activates the repo's full workflow.

## Open questions / blockers

- None for the prompt-design task.

## End-of-session summary

- What changed:
  - Added a plan and session log for this task.
  - Created a new exploration scaffold for the coyote GIS blog project.
  - Wrote a detailed `CODEX_PROMPT.md` covering data scouting, spatial methods,
    reporting-bias diagnostics, deliverables, and review workflow.
- What was verified:
  - Confirmed the files exist and the prompt explicitly names specialist and
    adversarial review expectations.
- Remaining work:
  - Run the prompt in a fresh Codex task so the actual GIS analysis can begin.
