# Workflow Integration Overlay Template

Use this template when a repository already has its own specialized agents,
planning documents, and domain workflows, but you want to layer this workflow's
methods on top without replacing what already works.

## Integration principle

Treat this workflow as an **overlay**, not a rewrite.

Preserve:

- existing specialized agents
- existing plan documents and folders
- existing domain-specific review and verification steps
- existing project structure that already works

Add:

- root orchestration guidance
- durable memory files if missing
- a clearer completion standard
- explicit verification and review expectations
- a durable session-log habit if the repo lacks one

## Minimal files to add

If missing, add only these first:

- `AGENTS.md`
- `KNOWLEDGE_BASE.md`
- `MEMORY.md`
- one durable place for plans
- one durable place for session logs or equivalent progress notes

You do not need to force the repo into `quality_reports/` if it already has a
good durable location for plans and logs.

## Root `AGENTS.md` overlay

Copy and adapt:

```md
# Workflow Guidance

This repository uses an overlay workflow layer. Preserve the repo's existing
agents, plans, and domain-specific procedures unless this file explicitly says
otherwise.

## Core operating mode

- For any non-trivial task, start with or refresh a plan in `[EXISTING PLAN PATH]`.
- Before substantial edits, read `KNOWLEDGE_BASE.md`, `MEMORY.md`, and any
  relevant domain guidance already used by this repo.
- After plan approval, use:

  `implement -> verify -> review -> fix -> re-verify -> summarize`

- Save important reasoning to disk rather than leaving it only in chat.
- Update `[EXISTING SESSION LOG PATH OR EQUIVALENT]` after plan approval, major
  decisions, and wrap-up.

## Existing infrastructure is authoritative

- Existing specialized agents remain the default specialists for this repo.
- Existing plan documents remain the default planning surface for this repo.
- Existing verification commands remain the default technical checks for this
  repo unless they are explicitly amended.

## Review expectations

- Use the repo's existing specialists when the task maps cleanly onto them.
- If multiple specialists apply, prefer parallel review when the task is large
  enough to justify it.
- If specialist review is skipped, say why in the final summary.

## Verification expectations

- Match verification to the change:
  - code changes: run the narrowest relevant tests, linters, or scripts
  - docs changes: re-read the edited docs and verify referenced paths/commands
  - generated outputs: confirm artifacts exist and are current
- Record what was verified and what was not.

## Completion standard

Before declaring a task done, be explicit about:

- what changed
- what was verified
- what review agents or review steps were used
- what durable artifacts were updated
- any remaining blockers, drift, or open questions
```

## Existing-agent mapping table

Add a section like this to `AGENTS.md` or a local workflow doc:

```md
## Specialist mapping

| Workflow role | Existing repo agent / reviewer | When to use |
|---|---|---|
| Implementation specialist | `[agent-name]` | `[task types]` |
| Code reviewer | `[agent-name]` | `[task types]` |
| Domain reviewer | `[agent-name]` | `[task types]` |
| Verifier | `[agent-name or command suite]` | `[task types]` |
| Release / packaging reviewer | `[agent-name]` | `[task types]` |
```

This lets the methodology transfer even if agent names differ from this repo.

## Existing-plan integration block

Document the repo's actual durable planning surfaces:

```md
## Durable state locations

- Plans live in: `[path]`
- Session logs live in: `[path]`
- Review reports live in: `[path]`
- Verification notes live in: `[path or "same as above"]`
```

If the repo already has ADRs, issue templates, runbooks, or milestone docs, use
them rather than creating duplicate planning systems.

## `KNOWLEDGE_BASE.md` starter

Use this for stable repo truth:

```md
# Knowledge Base

## Canonical conventions

| Area | Convention | Example | Anti-pattern |
|---|---|---|---|
| Architecture | Fill in | Fill in | Fill in |
| Naming | Fill in | Fill in | Fill in |
| Verification | Fill in | Fill in | Fill in |

## Important artifacts

| Artifact | Purpose | Location | Notes |
|---|---|---|---|
| Fill in | Fill in | Fill in | Fill in |

## Known pitfalls

| Pitfall | Impact | Fix |
|---|---|---|
| Fill in | Fill in | Fill in |
```

## `MEMORY.md` starter

Use this for workflow lessons:

```md
# Workflow Memory

[LEARN] YYYY-MM-DD — short title
Context:
Lesson:
Action:
```

Good early entries:

- where Codex tends to stumble in this repo
- which existing specialists are most reliable for which tasks
- which verification steps are easy to forget
- what should always be written to disk during longer tasks

## Integration checklist

Use this when adopting the overlay in a repo:

- Keep the repo's existing agents and planning docs.
- Add or update a root `AGENTS.md` with overlay orchestration rules.
- Document where plans, logs, and reports already live.
- Map existing agents to workflow roles.
- Add `KNOWLEDGE_BASE.md` and `MEMORY.md` if missing.
- Make verification and completion standards explicit.
- Do one pilot task and refine the overlay from what you learn.

## Anti-patterns to avoid

- Replacing good existing agents just to match another repo's names.
- Introducing a second planning system when the repo already has one.
- Copying slide- or domain-specific rules into unrelated repos.
- Making the overlay so broad that it overrides useful local conventions.
- Treating verification or review as optional once implementation is done.
