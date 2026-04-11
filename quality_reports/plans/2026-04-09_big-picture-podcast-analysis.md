# Plan: Big Picture podcast analysis

- **Date:** 2026-04-09
- **Status:** IN PROGRESS
- **Owner:** Codex
- **Quality target:** 90

## Goal

Build a transparent, blog-ready empirical analysis of *The Big Picture*
podcast that uses lawful public transcript access to study sentiment over time,
movie-level likes and dislikes, and Oscar-prediction behavior, then package the
work with a code-only replication folder.

## Scope

- In scope:
  - Publicly accessible episode metadata and transcript pages.
  - A feasibility-first audit with explicit coverage and missingness.
  - Episode-level sentiment, movie-level preference, and Oscar-prediction
    datasets backed by saved artifacts.
  - A Quarto draft plus blog-ready markdown derivative.
  - Explicit specialist review and at least one real adversarial QA loop.
- Out of scope:
  - Claiming access to private feeds, paid transcript products, or subscriber
    materials.
  - Redistributing copyrighted full transcripts inside the replication bundle.
  - Treating lexicon sentiment or heuristic extraction as ground truth without
    validation and caveats.

## Feasibility questions

1. Can lawful public transcript sources support a multi-year sample with enough
   coverage to answer the three research questions?
2. Can the transcript pull be made reproducible in this environment, given that
   Python network calls are blocked but `curl` works?
3. Which parts of the movie-preference and Oscar-prediction tasks can be
   automated cleanly, and where do we need bounded coder judgment?

## Working design

- Primary transcript source candidate:
  - `podscripts.co` episode transcript pages.
- Metadata supplements:
  - `theringer.com` show and episode pages.
  - Public RSS / podcast listings if needed for backfilling or validation.
- Analysis sample:
  - Prefer the last several years with actual transcript coverage, likely
    centered on `2023-2026` unless the audit supports a broader window.
- Method stance:
  - Triangulate with layered measures and explicit robustness checks rather than
    a single NLP score.

## Files expected to change

- `quality_reports/plans/2026-04-09_big-picture-podcast-analysis.md`
- `quality_reports/session_logs/2026-04-09_big-picture-podcast-analysis.md`
- `explorations/big-picture-podcast-analysis/README.md`
- `explorations/big-picture-podcast-analysis/SESSION_LOG.md`
- `explorations/big-picture-podcast-analysis/output/*`
- `explorations/big-picture-podcast-analysis/replication/*`
- `quality_reports/review_*big-picture-podcast-analysis*.md`
- `quality_reports/adversarial_big-picture-podcast-analysis_round*.md`
- `quality_reports/codex_activity/2026-04-09_big-picture-podcast-analysis.md`

## Implementation plan

1. Audit transcript and metadata sources, then write feasibility and source
   memos before deep analysis.
2. Build a reproducible pull pipeline that creates episode and transcript
   manifests without committing copyrighted full transcript dumps.
3. Construct processed analytic datasets for episode sentiment, movie mention
   scoring, and Oscar-prediction events.
4. Estimate the main descriptive and statistical models, plus robustness and
   uncertainty summaries.
5. Draft the Quarto blog post and site-ready markdown with linked replication
   instructions.
6. Run all 10 requested specialist agents, fix material findings, re-verify,
   and score the package.

## Verification plan

- Confirm the pull pipeline writes episode and transcript manifests with success
  and failure states.
- Run the main analysis entry point and verify required figures, tables, and
  memo outputs exist.
- Render the Quarto post if feasible in the current environment.
- Re-read the narrative against the actual artifacts and review findings.

## Review plan

- Specialists to use explicitly:
  - `proofreader`
  - `slide-auditor`
  - `pedagogy-reviewer`
  - `r-reviewer`
  - `tikz-reviewer`
  - `beamer-translator`
  - `quarto-critic`
  - `quarto-fixer`
  - `verifier`
  - `domain-reviewer`
- Adversarial loop:
  - Minimum one real critic/fixer round, continuing if findings remain
    productive.

## Review checkpoint

- 2026-04-09 16:45:
  - Completed a `slide-auditor` pass on
    `explorations/big-picture-podcast-analysis/output/blog_post_draft.qmd`
    and the generated figure assets.
  - Main findings:
    - rendered HTML uses broken non-portable `./Users/...` asset paths
    - key tables are exposed only as raw CSV links rather than readable inline
      presentation
    - the movie-preference scatter is too dense for article-width display
  - Follow-up artifact:
    - `quality_reports/review_2026-04-09_big-picture-slide-audit.md`
- 2026-04-09 17:40:
  - Completed an Oscar-only audit pass on the refreshed extractor, Oscar CSV
    outputs, and rewritten Quarto section.
  - Main findings:
    - the prior Oscar prose was stale and still described placeholders
    - the Oscar accuracy figure title overstated the horizon pattern
    - one part of the evidence interpretation needed more caution because the
      `star_power` pattern is intentionally broad
    - parallel HTML and GFM renders raced on the same intermediate file, so
      final verification should render them sequentially
  - Follow-up:
    - rewrote the Oscar methods and results section, regenerated the Oscar
      outputs, and rerendered the draft sequentially
- 2026-04-09 17:30:
  - Re-scoped the final push so Oscar completion is the sole remaining
    objective.
  - Main actions:
    - rebuilt the Oscar prediction outputs from cached transcripts
    - corrected a misleading figure title that had implied late-horizon
      improvement not supported by the data
    - rewrote the Quarto Oscar methods/results section to reflect the now-real
      evaluation sample
    - queued a focused read-only domain and verification review on the Oscar
      layer after rerendering
  - Expected closeout:
    - durable Oscar review notes under `quality_reports/`
    - refreshed `blog_post_draft.qmd`, `blog_post_draft.md`,
      `blog_post_for_site.md`, and `blog_post_draft.html`

## Risks

- Risk: public transcript coverage may be incomplete or uneven over time.
- Mitigation: quantify missingness, restrict the analytic window if necessary,
  and state the resulting inference limits.
- Risk: automated movie-title extraction may be noisy.
- Mitigation: require repeated evidence, use conservative matching, and surface
  ambiguous cases in methods materials.
- Risk: Oscar-prediction coding may mix banter, consensus narration, and actual
  picks.
- Mitigation: define prediction classes explicitly and save coder rules in the
  methods memo.
