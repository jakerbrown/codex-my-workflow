# Plan: roth blog prompt

- **Date:** 2026-04-08
- **Status:** COMPLETED
- **Owner:** Codex
- **Quality target:** 90

## Goal

Create a detailed, repo-native master prompt that instructs Codex to conduct an
empirical research project and draft a blog post answering: "Which modern
authors write the most like Philip Roth?"

## Scope

- In scope:
  - Draft a prompt that emphasizes reproducible text analysis over common
    wisdom.
  - Encode realistic workflow expectations for data acquisition, verification,
    uncertainty, and deliverables.
  - Include a path for incorporating the user's Goodreads reading history into
    the final analysis.
  - Save the prompt and lightweight exploration scaffolding on disk.
- Out of scope:
  - Running the full literary-analysis project.
  - Logging into external accounts during this prompt-design task.
  - Claiming that copyrighted full-text corpora or private Goodreads data are
    automatically accessible.

## Assumptions and clarifications

- CLEAR: The user wants a very detailed prompt for a future autonomous Codex run.
- ASSUMED: This project is exploratory research and belongs under
  `explorations/`.
- ASSUMED: The prompt should be realistic about blocked data access and should
  instruct Codex to stop and request specific inputs only when necessary.
- BLOCKED: None for the prompt-design task itself.

## Files likely to change

- `quality_reports/plans/2026-04-08_roth-blog-prompt.md`
- `quality_reports/session_logs/2026-04-08_roth-blog-prompt.md`
- `explorations/philip-roth-author-similarity/README.md`
- `explorations/philip-roth-author-similarity/SESSION_LOG.md`
- `explorations/philip-roth-author-similarity/CODEX_PROMPT.md`
- `quality_reports/codex_activity/2026-04-08_roth-blog-prompt.md`

## Implementation approach

1. Review repo workflow guidance and exploration conventions.
2. Create a self-contained exploration scaffold for the future literary project.
3. Write a high-detail prompt that specifies:
   - research question and scope
   - deliverables and artifact paths
   - empirical methods and robustness checks
   - corpus-access constraints and fallback behavior
   - Goodreads integration strategy
   - writing and review expectations
4. Verify the files exist and reread the prompt for internal consistency.

## Verification plan

- Compile / render: Not applicable.
- Run scripts / tests: Not applicable for this prompt-authoring task.
- Manual checks:
  - Confirm the prompt is specific enough to run autonomously.
  - Confirm it does not assume unauthorized access to private or copyrighted
    corpora.
  - Confirm it matches repo expectations around plans, logs, and durable output.
- Reports to write:
  - Session log update.
  - Codex activity breadcrumb.

## Review plan

- Specialists to spawn: None. This task is a bounded prompt-design pass rather
  than the research project itself.
- Whether adversarial QA is needed: No.
- Final quality threshold: 90

## Risks

- Risk: Over-specifying the prompt could make it brittle if the accessible data
  differ from expectations.
- Mitigation: Include feasibility gates, fallback paths, and explicit honesty
  requirements.
- Risk: Under-specifying the prompt could yield shallow or generic analysis.
- Mitigation: Require multiple measurement families, robustness checks, and
  durable outputs.
