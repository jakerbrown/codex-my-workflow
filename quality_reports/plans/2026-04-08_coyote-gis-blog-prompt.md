# Plan: coyote gis blog prompt

- **Date:** 2026-04-08
- **Status:** COMPLETED
- **Owner:** Codex
- **Quality target:** 90

## Goal

Create a detailed, repo-native master prompt that instructs Codex to conduct a
serious GIS and spatial-statistics project, then draft a blog post analyzing
coyote sighting clustering in Belmont and possibly other Massachusetts towns.

## Scope

- In scope:
  - Draft a prompt centered on empirical spatial analysis rather than anecdote.
  - Encode workflow expectations for data acquisition, geospatial cleaning,
    robustness checks, specialist review, and adversarial critique.
  - Include a secondary exploratory component on unusual or fun municipal GIS
    datasets in other Massachusetts towns.
  - Save the prompt and lightweight exploration scaffolding on disk.
- Out of scope:
  - Running the full GIS analysis project.
  - Pretending the required shapefiles or metadata are already downloaded.
  - Claiming causal certainty about coyote behavior from point data alone.

## Assumptions and clarifications

- CLEAR: The user wants a detailed prompt for a future autonomous Codex run.
- CLEAR: The main blog-post question is whether observed clustering reflects
  real coyote spatial behavior or reporting behavior such as super-callers.
- ASSUMED: This is exploratory research and belongs under `explorations/`.
- ASSUMED: The prompt should push Codex toward multiple specialist reviews and
  an adversarial critic/fixer cycle.
- BLOCKED: None for the prompt-design task itself.

## Files likely to change

- `quality_reports/plans/2026-04-08_coyote-gis-blog-prompt.md`
- `quality_reports/session_logs/2026-04-08_coyote-gis-blog-prompt.md`
- `explorations/coyote-gis-clustering/README.md`
- `explorations/coyote-gis-clustering/SESSION_LOG.md`
- `explorations/coyote-gis-clustering/CODEX_PROMPT.md`
- `quality_reports/codex_activity/2026-04-08_coyote-gis-blog-prompt.md`

## Implementation approach

1. Review repo workflow guidance and the analysis-oriented skill.
2. Create a self-contained exploration scaffold for the future GIS project.
3. Write a high-detail prompt that specifies:
   - research question and scope
   - spatial-analysis methods and diagnostics
   - super-caller and reporting-bias tests
   - municipal GIS scouting expectations
   - deliverables and artifact paths
   - specialist review and adversarial QA
4. Verify the files exist and reread the prompt for internal consistency.

## Verification plan

- Compile / render: Not applicable.
- Run scripts / tests: Not applicable for this prompt-authoring task.
- Manual checks:
  - Confirm the prompt is specific enough to run autonomously.
  - Confirm it pushes the workflow toward explicit subagents and adversarial
    review.
  - Confirm it is realistic about limits of point data and municipal reporting
    systems.
- Reports to write:
  - Session log update.
  - Codex activity breadcrumb.

## Review plan

- Specialists to spawn: None for this bounded prompt-authoring pass.
- Whether adversarial QA is needed: No.
- Final quality threshold: 90

## Risks

- Risk: The prompt could overclaim what can be inferred from opportunistic
  sighting data.
- Mitigation: Build in strong caution around observational bias and causal
  interpretation.
- Risk: The prompt could encourage shallow "map porn" rather than serious
  analysis.
- Mitigation: Require multiple clustering methods, counterfactual checks, and
  explicit reporting-bias diagnostics.
