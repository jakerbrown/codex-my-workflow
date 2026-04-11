# Plan: Spencer underdog betting

- **Date:** 2026-04-09
- **Status:** COMPLETED
- **Owner:** Codex
- **Quality target:** 90

## Goal

Build a serious, reproducible empirical analysis of whether betting every
early-season underdog at closing moneyline odds would have made money across
the NFL, NBA, NHL, and MLB, then turn the results into a blog-ready research
post plus a small Beamer/Quarto research brief.

## Scope

- In scope:
  - Public, reproducible historical odds and outcomes for the big four leagues.
  - Baseline and benchmark strategy analysis with uncertainty.
  - Calibration analysis and league-level partial-pooling evidence.
  - A clearly labeled simulation extension if needed for market-learning logic.
  - A code-only replication folder that rebuilds artifacts from public sources.
  - Explicit specialist review plus adversarial critique.
- Out of scope:
  - Claiming post-2021 coverage if public cross-league moneyline data cannot be
    reproduced cleanly.
  - Using proprietary sportsbook feeds or undocumented paid endpoints.
  - Treating noisy positive ROI as proof of a genuine betting edge.

## Feasibility snapshot

- Strongest current public cross-league source identified:
  - `flancast90/sportsbookreview-scraper` GitHub repository with pre-scraped
    JSON archives for NFL, NBA, NHL, and MLB.
- Current verified coverage:
  - All four leagues have downloadable public JSON archives for seasons
    `2011` through `2021`.
- Source limitation already discovered:
  - The upstream sportsbook archive pages used by the scraper appear partly
    degraded in 2026, so the GitHub-hosted snapshots are likely the most
    defensible cross-league public source for this run.
- Implication:
  - The main observed-data analysis will likely use the common `2011-2021`
    window unless another equally reproducible public source extends coverage
    without introducing uneven seams.

## Early scope choices

- Regular season only:
  - Yes. Playoffs are out of scope because Spencer's premise is about market
    learning at season start.
- Primary price:
  - Closing moneyline.
- Secondary price:
  - Opening moneyline where available for supplementary checks only.
- Bet type:
  - Moneyline only for the core design. Spread/puckline/runline will not be
    pooled into the headline strategy because the economic object differs.
- Early-season definitions to test:
  - First 2 calendar weeks from league opening day.
  - First 3 calendar weeks from league opening day.
  - First 5 games per team.
  - First 10 percent of team games.
- Minimum completeness rule:
  - Include league-seasons only when both team moneylines and final scores are
    present and parseable for at least 95 percent of regular-season games.

## Files expected to change

- `quality_reports/plans/2026-04-09_spencer-underdog-betting.md`
- `quality_reports/session_logs/2026-04-09_spencer-underdog-betting.md`
- `explorations/spencer-underdog-betting/README.md`
- `explorations/spencer-underdog-betting/SESSION_LOG.md`
- `explorations/spencer-underdog-betting/src/*`
- `explorations/spencer-underdog-betting/output/*`
- `explorations/spencer-underdog-betting/replication/*`
- `quality_reports/review_*.md`
- `quality_reports/qa_*.md`
- `quality_reports/adversarial_spencer-underdog-betting_round*.md`
- `quality_reports/codex_activity/2026-04-09_spencer-underdog-betting.md`

## Implementation plan

1. Finalize the source memo and coverage audit with accepted and rejected
   sources.
2. Download the public odds archives and inspect schemas, date ranges, and data
   quality by league-season.
3. Build a harmonized game-level panel with underdog flags, implied
   probabilities, regular-season filters, and early-season windows.
4. Estimate baseline strategy results, benchmark comparisons, calibration
   diagnostics, and partial-pooling evidence.
5. Add a stylized market-learning simulation if it sharpens interpretation or
   addresses identification limits.
6. Draft results, methods, blog copy, figures, tables, and a paired Beamer plus
   Quarto research brief.
7. Run verification, specialist review, fixes, re-verification, adversarial
   critique, and final scoring.

## Verification plan

- Data pull:
  - Confirm all public source files download successfully and hashes / sizes are
    recorded.
- Analysis:
  - Run the full pipeline end to end and confirm required CSV, parquet, figure,
    and markdown outputs exist.
- Slides:
  - Compile the Beamer brief if created.
  - Render the Quarto brief and compare parity against Beamer.
- Text:
  - Re-read the blog draft against the actual tables and figures.

## Review plan

- Specialists to use explicitly:
  - `r-reviewer`
  - `domain-reviewer`
  - `proofreader`
  - `verifier`
  - `slide-auditor`
  - `pedagogy-reviewer`
  - `tikz-reviewer`
  - `beamer-translator`
  - `quarto-critic`
  - `quarto-fixer`
- Additional review:
  - Fresh-context adversarial reviewer, minimum two rounds if material issues
    are found.

## Risks

- Risk: Public cross-league odds data after 2021 may not be reproducible.
- Mitigation: Use the strongest common 2011-2021 source, document the gap, and
  separate observed evidence from simulation-based extensions.
- Risk: Many window variants could create p-hacking pressure.
- Mitigation: Predeclare headline windows in methods materials and treat
  exploratory variants as secondary with caution.
- Risk: ROI can look impressive while remaining statistically weak.
- Mitigation: Emphasize uncertainty, pooled evidence, calibration, and
  benchmark comparisons rather than raw return rankings.

## Outcome

- Completed the empirical package, blog drafts, slide brief, and replication
  folder.
- Verified the main pipeline, R robustness script, Beamer compile, Quarto
  render, and replication rebuild entrypoint.
- Completed specialist review across the requested reviewer set and two rounds
  of adversarial critique.
- Final quality call: 90/100.
