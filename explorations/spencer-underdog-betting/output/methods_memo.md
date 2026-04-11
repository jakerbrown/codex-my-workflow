# Methods Memo: Spencer underdog betting

## Research question

Did a simple rule of betting every early-season underdog at closing moneyline
odds historically make money in the NFL, NBA, NHL, and MLB once bookmaker hold,
sampling noise, and league heterogeneity are taken seriously?

## Data source and coverage

The observed-data core of this project uses the public JSON archives in
`flancast90/sportsbookreview-scraper`, a GitHub repository containing
game-level sportsbook snapshots for all four leagues. The usable common window
is `2011-2021`.

Coverage in the final harmonized panel:

- 44 league-seasons
- 53,453 games in the cleaned archive
- 50,416 games marked as part of a conservative archive-derived regular-season
  proxy

The source carries game date, teams, final score, and closing moneylines for
both sides. It does not carry a reliable official season-type flag across all
leagues, so the package uses a conservative archive-derived regular-season
proxy for full-season comparisons. In the code this appears as
`likely_regular_season`. This choice does not affect the main early-season
windows because those bets occur before any playoff boundary.

## Scope choices

- Universe:
  - NFL, NBA, NHL, MLB only.
- Bet type:
  - Moneyline only in the headline analysis.
- Price:
  - Closing moneyline is the primary price object.
- Staking:
  - Flat `$100` stakes for the main analysis.
- Window translation:
  - First 2 calendar weeks.
  - First 3 calendar weeks.
  - First 5 games for the betting team.
  - First 10 percent of the team-season proxy.
- Season boundary handling:
  - Main early-window results use all qualifying archive games because the
    windows are at season start.
  - Full-season benchmarks use the conservative archive-derived regular-season
    proxy.

## Cleaning and harmonization

The public snapshots contained a small number of malformed aliases and blank
team rows. The pipeline:

- standardized team aliases within league
- dropped rows with missing teams, missing dates, or zero closing moneylines
- dropped non-NFL tied-score rows, which appear to be incomplete or suspended
  baseball / hockey records rather than real resolved bets
- kept NFL pushes as zero-profit outcomes

The cleaned panel saved to
`output/game_level_panel.parquet` contains harmonized league, season, date,
teams, scores, closing moneylines, implied probabilities, underdog / favorite
flags, and early-season indicators.

## Core strategy definitions

The baseline selection rule is:

- choose the underdog side in each qualifying game
- stake `$100`
- settle winnings at closing moneyline odds

The main headline strategies are:

- `underdog_2w`
- `underdog_3w`
- `underdog_first5`
- `underdog_first10pct`

Secondary refined variants include:

- road underdogs in the first 3 weeks
- bigger-payout underdogs in the first 3 weeks
- lower-payout underdogs in the first 3 weeks

## Benchmarks

The package compares Spencer's rule against:

- all underdogs across the season proxy
- early-season favorites
- later-season underdogs
- a random-team benchmark within the same early windows
- a random-underdog-timing benchmark created by permuting underdog dates within
  league-season
- half-Kelly staking using out-of-sample predicted win probabilities from a
  leave-one-season-out logistic model

## Probability and calibration handling

Raw implied probabilities are computed directly from American odds. The two
sides of a game are then renormalized to no-vig probabilities:

- `p_home_novig = p_home_raw / (p_home_raw + p_away_raw)`
- `p_away_novig = p_away_raw / (p_home_raw + p_away_raw)`

The main calibration diagnostic is the average residual:

- `win - implied_prob_novig`

Positive values indicate underdogs won more often than the no-vig market price
implied.

## Uncertainty and modeling

Three layers of uncertainty handling are used:

- cluster bootstrap confidence intervals for ROI
  - pooled across league-season clusters
  - league-specific across seasons
- regression models on the side-level panel
  - logistic model for outright win probability
  - OLS model for profit per $100 stake
- partial-pooling summary across leagues
  - league-specific average profit per early 3-week underdog bet
  - normal-normal shrinkage toward a pooled mean

## Limitations

- The public cross-league closing-moneyline archive stops in 2021 for the
  cleanest common sample found here.
- The season-type proxy is conservative rather than official.
- Variant screening can create false positives, so positive sub-strategies are
  treated as exploratory unless they survive shrinkage and benchmarking.
- The market-learning simulation is interpretive only. It is not used as direct
  evidence that a betting edge existed.
