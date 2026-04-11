# Feasibility Memo

## Bottom line

This project is **strongly feasible for episode metadata and summaries** and
**partially feasible for large-sample transcript analysis** from lawful public
web sources.

## What is strongly feasible

- Full episode manifest construction from public Podscripts listing pages.
- Multi-year coverage of episode titles, dates, and descriptions.
- Episode-type classification for Oscar, ranking, interview, draft, and
  standard episodes.
- Summary-based sentiment tracking over the last several years.
- A reproducible, code-first transcript pull pipeline that records success and
  failure rather than bluffing completeness.

## What is partially feasible

- Large-sample transcript retrieval from public Podscripts episode pages.
- Movie-level preference inference from repeated transcript mentions.
- Oscar-prediction coding from explicitly Oscar-focused episodes.

These are partially feasible because the public transcript mirror appears
rate-limited rather than open as an unrestricted bulk API. A broad transcript
sample can be accumulated with polite pacing and external caching, but not with
an aggressive one-shot scrape.

## What is blocked or fragile

- Treating the public transcript mirror as a stable bulk-download service.
- Redistributing full transcript dumps inside the repo.
- Claiming complete transcript coverage for every recent episode until the
  large-sample pull and manifest finish.

## Practical consequence

The defensible workflow is:

1. build the full episode manifest and summary corpus
2. attempt the broad transcript pull with caching and explicit failure logging
3. run the deeper movie and Oscar analysis on the successfully retrieved
   transcript subset
4. state the resulting coverage and missingness plainly

## Current feasibility call

- Sentiment over time:
  - **Strongly feasible** with full summary coverage and transcript-backed
    industry subsamples.
- Movie likes and dislikes:
  - **Moderately feasible** if the transcript pull reaches a broad enough
    recent sample; repeated-evidence scoring is possible but must respect the
    observed missingness.
- Oscar prediction model:
  - **Moderately feasible** because Oscar-specific episodes are common, but the
    final usable sample depends on transcript pull success for those episodes.
