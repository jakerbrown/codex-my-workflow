# Big Picture Podcast Analysis

This exploration is a staging area for a transcript-based empirical analysis of
*The Big Picture* podcast.

The target deliverable is a blog post that analyzes:

- sentiment over time in how the hosts discuss movies and the movie industry
- which movies they like and dislike, plus common patterns in those judgments
- how they make Oscar predictions, how those predictions evolve, and how
  accurate they are

The master prompt for an autonomous Codex run lives in
`explorations/big-picture-podcast-analysis/CODEX_PROMPT.md`.

The live implementation for this run is being built under:

- `data/raw/`
- `data/processed/`
- `output/`
- `replication/`

The project is being executed with a feasibility-first workflow. Public
transcript coverage and lawful source limits are documented in
`output/feasibility_memo.md` and `output/source_memo.md` before the main
results are finalized.

## Current status

- Broad episode-manifest construction is working.
- Large-sample transcript harvesting is working with external caching under
  `/Volumes/Jake EH` when available.
- Cache-only analysis already produces first-pass sentiment, movie, and Oscar
  artifacts from the harvested subset.
- The Oscar layer now supports a bounded completed-season audit; the main
  remaining exploratory pieces are movie-title extraction and speaker-level
  disagreement inside Oscar episodes.
