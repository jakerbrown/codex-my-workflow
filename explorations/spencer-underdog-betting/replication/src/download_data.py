from __future__ import annotations

import subprocess
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
RAW_DIR = ROOT / "data" / "raw"

SOURCE_URLS = {
    "nfl": "https://raw.githubusercontent.com/flancast90/sportsbookreview-scraper/main/data/nfl_archive_10Y.json",
    "nba": "https://raw.githubusercontent.com/flancast90/sportsbookreview-scraper/main/data/nba_archive_10Y.json",
    "nhl": "https://raw.githubusercontent.com/flancast90/sportsbookreview-scraper/main/data/nhl_archive_10Y.json",
    "mlb": "https://raw.githubusercontent.com/flancast90/sportsbookreview-scraper/main/data/mlb_archive_10Y.json",
}


def main() -> None:
    RAW_DIR.mkdir(parents=True, exist_ok=True)
    for league, url in SOURCE_URLS.items():
        out = RAW_DIR / f"{league}_archive_10Y.json"
        subprocess.run(["curl", "-L", "--fail", "--max-time", "120", url, "-o", str(out)], check=True)


if __name__ == "__main__":
    main()
