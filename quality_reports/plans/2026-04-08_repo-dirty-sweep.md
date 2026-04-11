## Goal

Identify which GitHub repositories accessible to Codex also have local clones with uncommitted work.

## Plan

1. List all repositories available through the connected GitHub app.
2. Scan local git repositories under `/Users/jacobbrown/Documents/GitHub/`.
3. Match local clones to accessible GitHub repos by remote URL.
4. Record which matched repos are dirty and note any ambiguous local clones.
5. Save a durable report and summarize results in chat.

## Quality Target

80 = reliable inventory with clear matching rules and explicit caveats.
