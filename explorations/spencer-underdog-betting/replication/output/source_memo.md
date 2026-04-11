# Source Memo

## Accepted primary source

### `flancast90/sportsbookreview-scraper` GitHub repository

- Coverage used here:
  - NFL `2011-2021`
  - NBA `2011-2021`
  - NHL `2011-2021`
  - MLB `2011-2021`
- Access method:
  - Direct download of public JSON archives from raw GitHub URLs.
- Odds fields:
  - Closing moneyline for all four leagues.
  - Some opening-line fields for MLB and NHL plus spread / total fields in the
    raw archives.
- Why accepted:
  - It is the cleanest public cross-league moneyline snapshot found in a single
    documented repository, and the raw files are reproducibly downloadable.
- Important limitation:
  - The live sportsbook archive endpoints referenced by the scraper are partly
    degraded in 2026, so the GitHub-hosted snapshots function as a historical
    archive rather than a guaranteed live rebuild path.

## Supplementary source checks

### SportsbookReview archive mirror

- Status:
  - Partially usable only.
- What happened:
  - MLB xlsx archive endpoints still responded during this session, but the NFL,
    NBA, and NHL HTML archive endpoints tested here returned `404`.
- Decision:
  - Rejected as the core live source for this project.

### Official league schedule / results APIs

- Status:
  - Considered as supplementary metadata sources only.
- Decision:
  - Not required for headline early-season inference because the odds archive
    already carries game dates, teams, and final scores.
- Limitation:
  - Cross-league season-type tagging remains imperfect without a harmonized
    public schedule source, so the analysis uses a conservative
    archive-derived `likely_regular_season` flag for full-season sensitivity
    checks.

## Rejected source categories

- Paid historical odds APIs:
  - Rejected because the project specification preferred public and legally
    accessible data and the current repo should remain publicly reproducible.
- Undocumented scraping targets with unclear provenance:
  - Rejected to avoid a fragile pipeline and unverifiable line history claims.
