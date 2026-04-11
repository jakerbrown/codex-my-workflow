# References

## Data and source material

- Finn Lancaster, `flancast90/sportsbookreview-scraper`
  - GitHub repository:
    [https://github.com/flancast90/sportsbookreview-scraper](https://github.com/flancast90/sportsbookreview-scraper)
- Raw archive files used in this project:
  - NFL:
    [https://raw.githubusercontent.com/flancast90/sportsbookreview-scraper/main/data/nfl_archive_10Y.json](https://raw.githubusercontent.com/flancast90/sportsbookreview-scraper/main/data/nfl_archive_10Y.json)
  - NBA:
    [https://raw.githubusercontent.com/flancast90/sportsbookreview-scraper/main/data/nba_archive_10Y.json](https://raw.githubusercontent.com/flancast90/sportsbookreview-scraper/main/data/nba_archive_10Y.json)
  - NHL:
    [https://raw.githubusercontent.com/flancast90/sportsbookreview-scraper/main/data/nhl_archive_10Y.json](https://raw.githubusercontent.com/flancast90/sportsbookreview-scraper/main/data/nhl_archive_10Y.json)
  - MLB:
    [https://raw.githubusercontent.com/flancast90/sportsbookreview-scraper/main/data/mlb_archive_10Y.json](https://raw.githubusercontent.com/flancast90/sportsbookreview-scraper/main/data/mlb_archive_10Y.json)
- Team-name translation file:
  - [https://raw.githubusercontent.com/flancast90/sportsbookreview-scraper/main/config/translated.json](https://raw.githubusercontent.com/flancast90/sportsbookreview-scraper/main/config/translated.json)

## Methods references

- American odds conversion and no-vig normalization are standard sportsbook
  transformations applied directly to the two-sided moneyline prices in each
  game.
- Random-effects shrinkage in the R robustness script uses a simple
  DerSimonian-Laird style between-league variance estimate.

## Replication materials

- Code-only replication folder in this repo:
  - [`../replication/`](../replication/)
