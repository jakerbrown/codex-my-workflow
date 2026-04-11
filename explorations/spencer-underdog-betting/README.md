# Spencer Early-Season Underdog Betting

- **Date started:** 2026-04-09
- **Status:** active
- **Target quality floor:** 90

## Question

Did betting every early-season underdog at closing moneyline odds historically
make money in the NFL, NBA, NHL, and MLB?

## Current answer

The first full empirical pass says "probably not in a robust cross-league
sense." Early underdogs outperform generic underdog betting, but the pooled
strategy remains close to breakeven after vig and uncertainty.

## Package contents

- `src/`
  - Python download and analysis pipeline.
  - R robustness / meta-analysis script.
- `data/raw/`
  - Public sportsbook archive snapshots downloaded from GitHub.
- `output/`
  - Harmonized panel, figures, tables, memos, and blog drafts.
- `replication/`
  - Code-only rebuild package for the public-facing post.

## Main observed-data sample

- Leagues: NFL, NBA, NHL, MLB
- Seasons: `2011-2021`
- Cleaned games: `53,453`
- Common public cross-league source:
  - `flancast90/sportsbookreview-scraper`

## Headline finding

The best naive pooled rule in the first pass is betting every underdog in the
first 3 calendar weeks. That strategy still lands slightly negative:

- ROI `-0.4%`
- 95% bootstrap CI `[-4.0%, 3.4%]`

So the evidence currently points to a weak hint of early underdog
underpricing, not a stable cross-league betting edge.
