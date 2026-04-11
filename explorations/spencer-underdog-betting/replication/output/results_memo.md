# Results Memo

## Coverage

- Common observed-data window: `2011-2021`.
- Leagues covered: NFL, NBA, NHL, MLB.
- League-season rows in the coverage audit: 44.

## Headline results

- Betting every likely-regular-season underdog in the first 2 calendar weeks
  produced pooled ROI of `-0.012` across `3845`
  bets.
- Extending the window to the first 3 calendar weeks produced pooled ROI of
  `-0.004` across `5901` bets.
- By comparison, betting all underdogs over the archive-wide season proxy
  produced ROI of `-0.018`.
- Early favorites in the first 3 weeks produced ROI of `-0.041`.

## Interpretation

- The key empirical question is whether early underdogs outperform their own
  implied probabilities, not simply whether underdog payouts are large.
- The model outputs and calibration diagnostics should be treated as more
  informative than a single realized ROI number because variance is large and
  the early-season sample is modest in the NFL.

## Simulation extension

- In the stylized market-learning simulation, the strongest early-underdog ROI
  arose in scenario `bias_0.015_speed_0.15` with mean simulated ROI
  `0.858`.
- The simulation is explicitly interpretive, not observed evidence.

## Remaining caveats

- Public cross-league closing-moneyline coverage beyond 2021 was not recovered
  reproducibly in this run.
- Full-season comparisons rely on a conservative archive-derived regular-season
  proxy rather than an official season-type flag.
- Any positive in-sample variant should be treated cautiously because many
  sensible windows and sub-strategies can be tested.
