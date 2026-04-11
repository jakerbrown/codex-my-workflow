# Session Log: Spencer underdog betting

- **Date:** 2026-04-09
- **Status:** COMPLETED

## Current objective

Build a blog-ready empirical analysis and replication package on whether
early-season underdog betting historically paid off in the major U.S.
professional leagues.

## Timeline

### 13:20 - Repo guidance and exploration audit
- Summary: Read the root `AGENTS.md`, `explorations/AGENTS.md`, `MEMORY.md`,
  and `KNOWLEDGE_BASE.md`. Checked the existing exploration scaffold from the
  earlier prompt-writing task.
- Decision: Treat this as a fully durable, self-contained empirical project
  under `explorations/spencer-underdog-betting/` with on-disk plans, memos, and
  review artifacts.
- Next step: Audit real public odds sources before writing the main pipeline.

### 13:33 - Source feasibility discovery
- Summary: Identified `flancast90/sportsbookreview-scraper` as a promising
  public cross-league source. Inspected the scraper logic and GitHub file tree.
- Decision: Use the repo's public JSON snapshots as the leading candidate data
  source for all four leagues.
- Why: The repository provides direct downloadable archives for NFL, NBA, NHL,
  and MLB and documents the field structure well enough to build a harmonized
  game-level panel.

### 13:35 - Upstream source limitation
- Summary: Direct requests to the sportsbook HTML archive endpoints for NFL,
  NBA, and NHL returned `404` in the current environment, while the MLB xlsx
  endpoint still responded.
- Decision: Do not rely on live re-scraping of the upstream site for the core
  package.
- Impact: The main observed-data analysis will likely rest on the public GitHub
  snapshots covering `2011-2021`, with explicit discussion of the resulting
  coverage limit.

### 13:38 - Execution environment check
- Summary: Verified that Python 3.12, R 4.3, `pandas`, `numpy`,
  `matplotlib`, `seaborn`, `statsmodels`, `pyarrow`, `scipy`, and `sklearn`
  are available locally.
- Decision: Main pipeline can run in Python with at least one meaningful R
  robustness script for specialist review.
- Caveat: Python's own network resolution is blocked in the sandbox, while
  `curl` works. The pipeline should therefore use explicit download commands or
  local raw files during this session.

## Open questions / blockers

- Need to confirm exact field coverage, parseability, and league-season
  completeness inside each JSON archive.
- Need to decide whether any reproducible secondary source can extend the common
  window beyond 2021 without creating a lopsided cross-league sample.

## Working assumptions

- Baseline early-window analysis uses opening-season games directly; full-season
  benchmarks use a conservative archive-derived regular-season proxy.
- Primary price object will be closing moneyline odds.
- Headline sample will likely be the common `2011-2021` window across leagues.

### 14:05 - First full pipeline pass
- Summary: Downloaded the public archive snapshots, cleaned aliases, built the
  harmonized game panel, ran the benchmark and modeling pipeline, and generated
  the required figures and CSV outputs.
- Key empirical result: pooled early 3-week underdogs came in near breakeven at
  roughly `-0.4%` ROI with a wide interval that still includes both modest
  gains and meaningful losses.
- Interpretation: Spencer's theory looks more like a weak relative improvement
  over generic underdog betting than a robust profit machine.

### 14:18 - Replication and slide verification
- Summary: Added the code-only replication package, ran the R robustness script,
  compiled the Beamer brief, rendered the Quarto brief, and exercised the
  replication rebuild script end to end.
- Important note: the replication rebuild required unrestricted network access
  to verify the public data downloads from GitHub raw URLs.

### 14:28 - Specialist review loop started
- Summary: Spawned explicit reviewers for writing, domain logic, verification,
  slides, pedagogy, TikZ, parity, and adversarial critique.
- Findings already incorporated:
  - softened wording around precommitment and mechanism claims
  - made the season-proxy caveat more explicit
  - improved the slide deck with an intuition slide, an evidence-reading slide,
    and a calibration slide
  - recompiled the Beamer brief after structural edits

### 14:05 - First end-to-end empirical run
- Summary: Implemented the download, cleaning, harmonization, strategy, benchmark,
  modeling, and figure-generation pipeline in Python and ran it end to end.
- Key result: The pooled first-3-weeks underdog strategy came in near breakeven
  rather than clearly positive.
- Impact: The package narrative shifted from "test whether this made money" to
  "test whether this beats benchmarks and whether any apparent edge survives
  uncertainty."

### 14:18 - R robustness pass added
- Summary: Added an R script that reconstructs the early 3-week underdog result,
  computes a random-effects league summary, and checks parity against the Python
  output.
- Decision: Use the R layer as a targeted robustness and reproducibility check,
  not as a full second implementation of every benchmark.
- Impact: The `r-reviewer` artifact now has real code to audit.

### 14:27 - Slide and replication verification
- Summary: Created a Beamer brief, translated it to Quarto, compiled the PDF,
  rendered the RevealJS version, and verified the code-only replication entry
  point with network-enabled execution.
- Decision: Keep the slide brief short and use it mainly as a paired review
  object for the slide and Quarto QA reports.
- Impact: The package now includes verified replication and paired slide
  artifacts rather than just the blog post and tables.

### 14:34 - Reviewer-style report pass
- Summary: Wrote the required review and adversarial reports into
  `quality_reports/`.
- Important note: Runtime subagents were used for the specialist and
  adversarial review passes, and their outputs were saved as durable on-disk
  reports.
- Impact: The repo still has durable reviewer artifacts for R, domain, writing,
  verification, slides, TikZ, Beamer-to-Quarto parity, and adversarial critique.

## End-of-session summary

- What changed:
  - Built the empirical project under `explorations/spencer-underdog-betting/`.
  - Added public data pulls, harmonized panel construction, analysis outputs,
    figures, blog drafts, slide briefs, replication materials, and review
    artifacts.
- What was verified:
  - Main Python pipeline ran successfully.
  - R robustness script ran successfully.
  - Beamer brief compiled.
  - Quarto brief rendered.
  - Replication entrypoint rebuilt successfully with network-enabled
    verification.
- Current conclusion:
  - Evidence weakly supports a small early informational effect, strongest in
    MLB and maybe NFL, but does not support a robust cross-league profitable
    betting edge.
- Current quality score:
  - 90/100
