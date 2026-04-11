# Review: Big Picture R pipeline

- **Date:** 2026-04-09
- **Reviewer role:** `r-reviewer`
- **Artifacts reviewed:**
  - `explorations/big-picture-podcast-analysis/replication/src/big_picture_lib.R`
  - `explorations/big-picture-podcast-analysis/replication/src/fetch_transcripts.R`
  - `explorations/big-picture-podcast-analysis/replication/src/analyze_cached.R`

## Material findings

1. `industry_regex` was overbroad because bare `ip` matched unrelated words.
2. Sentiment scores were length-confounded because they used raw lexicon sums.
3. Zero-hit summary episodes were dropped silently from the trend series.
4. Oscar tie handling could produce multiple predicted winners per episode.
5. The cache layer could treat failed HTTP fetches as valid cached pages.
6. The fallback cache lived in `tempdir()`, which is not reproducible.
7. The analysis window excluded all 2026 episodes.
8. The regression path was brittle on homogeneous cached samples.

## Fixes applied

- Added word boundaries around `ip`.
- Switched summary and segment sentiment to normalized mean token scores.
- Retained zero-hit summary episodes with neutral score `0`.
- Made Oscar picks deterministic under ties.
- Hardened `curl` fetch behavior and cache validation.
- Moved the fallback cache to a persistent folder under replication data.
- Removed the hard-coded pre-2026 cutoff.
- Wrapped the regression path in an estimability check.

## Remaining risk

- Movie-title extraction remains the weakest statistical layer and still needs a
  more conservative title-recognition pass.
