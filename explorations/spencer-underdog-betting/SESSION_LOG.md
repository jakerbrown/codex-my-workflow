# Session Log: Spencer early-season underdog betting exploration

## 2026-04-09

- Earlier in the day, this folder was created as a scaffold for the later
  autonomous run.
- Read the repo workflow guidance, memory, and exploration rules before doing
  substantial work.
- Created the durable plan and session log under `quality_reports/`.
- Audited public historical odds sources and chose the public GitHub sportsbook
  archive as the common observed-data source.
- Confirmed that:
  - public JSON snapshots exist for NFL, NBA, NHL, and MLB
  - the common reproducible window is `2011-2021`
  - some upstream archive endpoints now fail, so the GitHub-hosted snapshots
    are the practical archival source
- Built the first end-to-end Python analysis pipeline:
  - cleaned malformed team aliases
  - created a harmonized game-level panel
  - created side-level betting data internally
  - estimated naive strategy results, benchmarks, calibration, and simple model
    summaries
  - generated figures and CSV outputs
- Added a meaningful R robustness / meta-analysis script and ran it.
- Drafted the methods memo, results memo, and blog-post drafts using the actual
  generated outputs rather than speculative prose.
- Current substantive conclusion:
  - early underdogs look better than generic underdog betting
  - pooled naive ROI remains near zero after vig
  - MLB and maybe NFL show weak positive hints
  - NHL looks clearly negative
