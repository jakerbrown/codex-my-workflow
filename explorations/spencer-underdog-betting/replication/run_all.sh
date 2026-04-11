#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"

cd "${REPO_ROOT}"
python3 explorations/spencer-underdog-betting/replication/src/download_data.py
python3 explorations/spencer-underdog-betting/replication/src/run_analysis.py
Rscript explorations/spencer-underdog-betting/replication/src/robustness_meta_analysis.R
