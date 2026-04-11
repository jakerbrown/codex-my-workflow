# Plan: big picture podcast prompt

- **Date:** 2026-04-09
- **Status:** COMPLETED
- **Owner:** Codex
- **Quality target:** 90

## Goal

Create a detailed, repo-native master prompt that instructs Codex to conduct an
autonomous statistical analysis of *The Big Picture* podcast transcripts and
draft a publication-quality blog post.

## Scope

- In scope:
  - Draft a prompt for a future autonomous Codex run.
  - Encode the user's three research questions: sentiment over time, movie-level
    likes/dislikes and commonalities, and an Oscar-prediction model.
  - Require a code-only replication folder that includes data-pulling code.
  - Explicitly instruct Codex to use the full specialist-agent set and the
    adversarial reviewer loop.
- Out of scope:
  - Running the podcast-analysis project itself in this prompt-design task.
  - Claiming that podcast transcripts or APIs are definitely accessible.
  - Producing the final empirical post during this turn.

## Assumptions and clarifications

- CLEAR: The user wants a ready-to-paste Codex prompt, not the analysis itself.
- ASSUMED: This project belongs under `explorations/` until the workflow and
  data pipeline stabilize.
- ASSUMED: The final post will likely be authored in Quarto so the repo's
  Quarto review loop can be used directly.
- ASSUMED: Some repo specialists are slide-oriented; the prompt should instruct
  Codex to use them on the closest relevant artifacts and document any limited
  relevance.
- BLOCKED: None for prompt authoring.

## Files likely to change

- `quality_reports/plans/2026-04-09_big-picture-podcast-prompt.md`
- `quality_reports/session_logs/2026-04-09_big-picture-podcast-prompt.md`
- `explorations/big-picture-podcast-analysis/README.md`
- `explorations/big-picture-podcast-analysis/SESSION_LOG.md`
- `explorations/big-picture-podcast-analysis/CODEX_PROMPT.md`
- `quality_reports/codex_activity/2026-04-09_big-picture-podcast-prompt.md`

## Implementation approach

1. Review repo workflow guidance and prompt examples.
2. Create a self-contained exploration scaffold for the podcast project.
3. Write a high-detail master prompt specifying:
   - research questions and empirical scope
   - realistic transcript/data acquisition behavior
   - deliverables and artifact paths
   - modeling expectations, tables, figures, and post-writing standards
   - explicit use of all 10 specialist agents plus adversarial QA
4. Verify that the files exist and reread the prompt for internal consistency.

## Verification plan

- Compile / render: Not applicable.
- Run scripts / tests: Not applicable for this prompt-authoring task.
- Manual checks:
  - Confirm the prompt is autonomous and concrete.
  - Confirm the prompt does not overclaim access to transcripts or APIs.
  - Confirm the prompt matches repo expectations around plans, logs, and durable
    outputs.
- Reports to write:
  - Session log update.
  - Codex activity breadcrumb.

## Review plan

- Specialists to spawn: None for the prompt-design task itself.
- Whether adversarial QA is needed: No.
- Final quality threshold: 90

## Risks

- Risk: Over-specifying specialist usage could force awkward applications of
  slide-centric reviewers.
- Mitigation: The prompt tells Codex to use all 10 agents but to document which
  findings were materially useful versus lightly applicable.
- Risk: The future project may be blocked by transcript access or sparse Oscar
  prediction history.
- Mitigation: The prompt includes feasibility gates, fallback paths, and
  explicit honesty requirements.
