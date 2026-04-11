# Replication Package

This folder is the code-only replication bundle for the Spencer underdog
betting analysis.

## What is inside

- `src/download_data.py`
  - pulls the public sportsbook archive snapshots from GitHub raw URLs
- `src/run_analysis.py`
  - cleans the source data, builds the harmonized panel, estimates the strategy
    and benchmark results, and writes figures and tables
- `src/robustness_meta_analysis.R`
  - runs an R-side meta-analytic robustness summary
- `requirements.txt`
  - Python dependency list
- `run_all.sh`
  - one-command rebuild script

## How to rebuild

From this folder:

```bash
bash run_all.sh
```

The script will:

1. create `data/raw/` under the replication folder if needed
2. download the public JSON archives
3. write analysis outputs to `output/`
4. run the R robustness script

## Data policy

- This folder intentionally contains code, manifests, and instructions only.
- Public raw data are downloaded at build time.
- No proprietary sportsbook feeds are committed here.
