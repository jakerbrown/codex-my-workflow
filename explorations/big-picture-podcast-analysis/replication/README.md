# Replication Package

This folder is the code-first replication bundle for the Big Picture podcast
analysis.

## Current design

- `src/run_analysis.R`
  - convenience wrapper that runs both the fetch and analysis stages
- `src/fetch_transcripts.R`
  - builds the episode manifest if needed
  - attempts the broad recent transcript crawl
  - writes progress checkpoints to `transcript_manifest_progress.csv`
  - writes the final `transcript_manifest.csv` only after the crawl completes
  - caches transcript HTML outside the repo when a writable volume is present
- `src/analyze_cached.R`
  - analyzes whatever transcript cache has already been harvested
  - writes derived outputs, figures, and tables without committing copyrighted
    transcript dumps into this folder
- `src/refresh_cached_outputs_fast.R`
  - fallback cache-refresh script for rebuilding the transcript manifest and
    conservative seeded-title movie outputs directly from the local cache
- `run_all.sh`
  - one-command entry point for the R pipeline
- `requirements.txt`
  - lightweight environment notes

## Data policy

- The replication package is code-only on purpose.
- Full transcript text is not committed here.
- The pipeline pulls public episode pages at runtime and stores only derived
  artifacts in repo outputs.
- If transcript pulls are rate-limited, the pipeline records failures in the
  manifest instead of pretending the missing pages succeeded.

## Rebuild

From this folder:

```bash
bash run_all.sh
```

The script writes outputs into both:

- `../output/`
- `./output/`

When the external volume `/Volumes/Jake EH` is mounted, transcript cache files
are stored there to support a larger crawl without bloating the workspace.

## Notes on large-sample runs

- The public transcript mirror is rate-limited, so the fetch stage can take a
  long time on a broad crawl.
- If a crawl is interrupted, use the progress manifest for monitoring and rerun
  the pipeline rather than trusting a half-written final manifest.
- The package now separates crawling from cache-based rebuilding so the
  downstream analysis can be refreshed from already-downloaded transcript HTML.
