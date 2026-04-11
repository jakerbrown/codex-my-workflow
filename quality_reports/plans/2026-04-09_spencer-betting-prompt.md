# Plan: spencer betting prompt

- **Date:** 2026-04-09
- **Status:** COMPLETED
- **Owner:** Codex
- **Quality target:** 90

## Goal

Create a detailed, repo-native master prompt that instructs Codex to run a
serious multi-league sports-betting analysis and draft a blog post evaluating
Spencer's proposed strategy of betting early-season underdogs.

## Scope

- In scope:
  - Draft a prompt centered on reproducible empirical analysis across the big 4
    U.S. professional leagues.
  - Encode strong expectations around public odds data acquisition, robustness
    checks, modeling, figures, tables, and cautious interpretation.
  - Explicitly require use of all repo specialist agents plus a fresh-context
    adversarial reviewer.
  - Require a code-only replication folder inside the repo and a blog-post link
    to that replication package.
  - Save the prompt and lightweight exploration scaffold on disk.
- Out of scope:
  - Running the full betting analysis project.
  - Claiming that historical betting odds are trivially available for every
    league-season combination.
  - Writing final substantive conclusions about whether the strategy works.

## Assumptions and clarifications

- CLEAR: The user wants a prompt for a future autonomous Codex run.
- CLEAR: The target deliverable is a blog post with publication-quality figures,
  tables, and a PhD-stats-level empirical write-up.
- ASSUMED: This project is exploratory research and belongs under
  `explorations/`.
- ASSUMED: A supporting slide deck is acceptable if it helps force explicit use
  of the slide-oriented repo agents.
- BLOCKED: None for the prompt-design task itself.

## Files likely to change

- `quality_reports/plans/2026-04-09_spencer-betting-prompt.md`
- `quality_reports/session_logs/2026-04-09_spencer-betting-prompt.md`
- `explorations/spencer-underdog-betting/README.md`
- `explorations/spencer-underdog-betting/SESSION_LOG.md`
- `explorations/spencer-underdog-betting/CODEX_PROMPT.md`
- `explorations/spencer-underdog-betting/replication/README.md`
- `quality_reports/codex_activity/2026-04-09_spencer-betting-prompt.md`

## Implementation approach

1. Review repo workflow guidance, memory, and prior prompt examples.
2. Create a self-contained exploration scaffold for the future betting project.
3. Write a high-detail prompt that specifies:
   - research questions and betting definitions
   - public data acquisition priorities and fallback logic
   - econometric and simulation components
   - artifact paths and replication requirements
   - explicit specialist-agent and adversarial-review workflow
4. Verify the new files exist and re-read the prompt for internal consistency.

## Verification plan

- Compile / render: Not applicable.
- Run scripts / tests: Not applicable for this prompt-authoring task.
- Manual checks:
  - Confirm the prompt is concrete enough for an autonomous run.
  - Confirm it forces explicit subagent use rather than assuming automation.
  - Confirm it is realistic about data-access uncertainty and betting-market
    limitations.
- Reports to write:
  - Session log update.
  - Codex activity breadcrumb.

## Review plan

- Specialists to spawn: None for this bounded prompt-authoring pass.
- Whether adversarial QA is needed: No.
- Final quality threshold: 90

## Risks

- Risk: The prompt could overpromise historical odds coverage.
- Mitigation: Add a feasibility gate, source-priority order, and simulation
  fallback.
- Risk: Forcing all repo agents could feel artificial.
- Mitigation: Use a small supporting Beamer-plus-Quarto research brief so the
  slide-specialist agents have a real object to review.
