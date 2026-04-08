# Minimal Workflow Overlay Kit

Use this kit when you want the same default Codex workflow across many repos
without forcing each repo to adopt a full starter pack.

## The five fields

Customize only these per repo:

1. `PLAN_PATH`
2. `SESSION_LOG_PATH`
3. `SPECIALIST_MAP`
4. `VERIFY_COMMANDS`
5. `QUALITY_THRESHOLD`

## What each field means

- `PLAN_PATH`
  - Where non-trivial task plans already live in the repo.
- `SESSION_LOG_PATH`
  - Where durable progress notes, session logs, or equivalent state updates
    should be written.
- `SPECIALIST_MAP`
  - The repo's default specialist agents, reviewers, or command suites by task
    type.
- `VERIFY_COMMANDS`
  - The narrowest standard verification commands for the repo.
- `QUALITY_THRESHOLD`
  - The score or readiness threshold that counts as done for normal work.

## Copy-ready root `AGENTS.md`

Replace the bracketed values:

```md
# Workflow Guidance

This repository uses a lightweight workflow overlay. Preserve the repo's
existing agents, plan documents, and domain-specific procedures unless this
file explicitly says otherwise.

## Repo fields

- `PLAN_PATH`: [PLAN_PATH]
- `SESSION_LOG_PATH`: [SESSION_LOG_PATH]
- `VERIFY_COMMANDS`: [VERIFY_COMMANDS]
- `QUALITY_THRESHOLD`: [QUALITY_THRESHOLD]

## Core operating mode

- For any non-trivial task, start with or refresh a plan in `PLAN_PATH`.
- Before substantial edits, read `KNOWLEDGE_BASE.md`, `MEMORY.md`, and any
  existing domain guidance used by this repo.
- After plan approval, use:

  `implement -> verify -> review -> fix -> re-verify -> summarize`

- Save important reasoning to disk rather than leaving it only in chat.
- Update `SESSION_LOG_PATH` after plan approval, major decisions, and wrap-up.

## Existing infrastructure is authoritative

- Existing specialized agents remain the default specialists for this repo.
- Existing plan documents remain the default planning surface for this repo.
- Existing verification commands remain the default technical checks for this
  repo unless they are explicitly amended.

## Specialist defaults

[SPECIALIST_MAP]

## Verification defaults

- Run the narrowest relevant checks from:
  - `[VERIFY_COMMANDS]`
- If a task changes docs, guidance, or other non-runtime files, re-read the
  edited files and verify referenced paths and commands.
- Record what was verified and what was not.

## Quality gate

- Default completion threshold: `[QUALITY_THRESHOLD]`
- Below threshold, keep iterating or clearly report what remains.

## Completion standard

Before declaring a task done, be explicit about:

- what changed
- what was verified
- what review agents or review steps were used
- what durable artifacts were updated
- current quality level
- any remaining blockers, drift, or open questions
```

## `SPECIALIST_MAP` snippet

Use a small block like this:

```md
- Backend/code changes: use `[agent/reviewer names]`
- Data or analysis changes: use `[agent/reviewer names]`
- Docs or writing changes: use `[agent/reviewer names]`
- Final verification: use `[agent name or command suite]`
```

## Optional supporting files

If missing, add these lightweight files:

- `KNOWLEDGE_BASE.md`
- `MEMORY.md`

You do not need more than that to start.

## Good defaults

If you want standard semantics across repos, reuse:

- `80` = production-ready baseline
- `90` = PR-ready
- `95` = excellence

## Anti-patterns

- Adding a second planning system when the repo already has one.
- Replacing good local agents with generic names from another repo.
- Using broad verification commands when a narrower repo-standard check exists.
- Making the overlay so detailed that it competes with the repo's own docs.
