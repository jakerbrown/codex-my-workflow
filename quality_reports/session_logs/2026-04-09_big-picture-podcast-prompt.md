# Session Log: big picture podcast prompt

- **Date:** 2026-04-09
- **Status:** COMPLETED

## Current objective

Design a detailed master prompt that can send Codex into this repository to run
an autonomous, high-rigor transcript-analysis project on *The Big Picture*
podcast and draft a blog post with replication materials.

## Timeline

### 13:05 - Workflow reconnaissance
- Summary: Read repo workflow guidance, exploration guidance, and prompt/design
  examples.
- Files in play: `AGENTS.md`, `docs/CODEX_WORKFLOW.md`, `explorations/AGENTS.md`,
  `.agents/skills/data-analysis/SKILL.md`, and existing prompt scaffolds.
- Next step: Draft a new exploration prompt using the same durable-output
  structure.

### 13:14 - Specialist-agent mapping
- Decision: Explicitly encode all 10 repo specialist agents in the prompt,
  including the adversarial critic/fixer loop.
- Why: The user specifically asked for each specialist agent to be invoked.
- Impact: The prompt instructs Codex to use the slide-centric reviewers on the
  closest relevant artifacts and to document their contribution honestly.

### 13:22 - Deliverable structure
- Decision: Treat the future project as an `explorations/` package with a
  Quarto blog post, figures/tables, and a code-only replication folder.
- Why: That structure fits the repo's conventions and supports transparent
  autonomous work.
- Impact: The prompt names artifact paths, quality thresholds, and reporting
  expectations up front.

## Open questions / blockers

- None for the prompt-design task.

## End-of-session summary

- What changed:
  - Added a plan and session log for this task.
  - Created a new exploration scaffold for the Big Picture transcript project.
  - Wrote a detailed `CODEX_PROMPT.md` covering data acquisition, empirical
    methods, deliverables, and explicit specialist review.
- What was verified:
  - Confirmed the new files exist and match repo workflow conventions.
  - Re-read the prompt to ensure it is ambitious, autonomous, and realistic
    about data-access constraints.
- Remaining work:
  - Run the prompt in a fresh Codex task so the actual project can begin.
