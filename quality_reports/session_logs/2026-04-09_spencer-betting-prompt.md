# Session Log: spencer betting prompt

- **Date:** 2026-04-09
- **Status:** COMPLETED

## Current objective

Design a detailed master prompt that can send Codex into this repository to run
a serious empirical sports-betting project on Spencer's early-season underdog
strategy.

## Timeline

### 10:05 - Reconnaissance
- Summary: Read root workflow guidance, memory, exploration rules, and prompt
  examples.
- Files in play: `AGENTS.md`, `docs/CODEX_WORKFLOW.md`,
  `explorations/AGENTS.md`, `KNOWLEDGE_BASE.md`, `MEMORY.md`, and prior
  prompt-oriented plan and activity files.
- Next step: Confirm the repo's actual specialist-agent inventory and design a
  matching prompt.

### 10:14 - Specialist inventory check
- Decision: Use all ten repo agents explicitly in the prompt:
  `proofreader`, `slide-auditor`, `pedagogy-reviewer`, `r-reviewer`,
  `tikz-reviewer`, `domain-reviewer`, `quarto-critic`, `quarto-fixer`,
  `verifier`, and `beamer-translator`.
- Why: The user explicitly asked for a prompt that names and uses each
  specialist agent plus an adversarial reviewer.
- Impact: The prompt now includes a small supporting Beamer-plus-Quarto
  research brief in addition to the main blog post.

### 10:24 - Prompt structure choice
- Decision: Treat the future analysis as a self-contained exploration package
  with a dedicated replication folder.
- Why: The project is ambitious, data-dependent, and benefits from clear
  separation between exploratory outputs and code-only replication assets.
- Impact: The prompt requires durable outputs, source notes, methods memos,
  review reports, and a replication link embedded in the draft post.

## Open questions / blockers

- None for the prompt-design task.

## End-of-session summary

- What changed:
  - Added a plan and session log for this task.
  - Created a new exploration scaffold for the Spencer betting project.
  - Wrote a detailed `CODEX_PROMPT.md` covering data acquisition, analysis,
    modeling, replication, specialist review, and adversarial critique.
  - Added a replication-folder README so the future run has a concrete target
    path.
- What was verified:
  - Confirmed the prompt aligns with current repo workflow conventions.
  - Confirmed the prompt explicitly names all ten repo agents and a separate
    adversarial-review pass.
- Remaining work:
  - Run the prompt in a fresh Codex task and let the analysis workflow build
    the actual code, data pulls, figures, tables, and post.
