# Quarto Critic Report: Big Picture Podcast Analysis

## Verdict
- Status: NOT APPROVED
- Hard-gate status: failed
- Quality score: 68/100

## Scope
- Reviewed `explorations/big-picture-podcast-analysis/output/blog_post_draft.qmd`
- Reviewed rendered `explorations/big-picture-podcast-analysis/output/blog_post_draft.html`
- Cross-checked supporting outputs in the same `output/` directory

## Prioritized findings

### 1. The lead sentiment result overstates what the shipped model supports
- The draft says the transcript-backed industry series "slopes down" and that later episodes "tend to sound a bit darker" over time.
- The linked regression table does show a negative calendar-time coefficient, but it is small and statistically weak (`p = 0.3769`), while the stronger supported result is that `industry_share` is associated with lower sentiment.
- This is a factual/methodological overclaim in the centerpiece result.

### 2. The published sample sizes are stale relative to the current supporting outputs
- The draft and rendered HTML still report 337 recent episodes, 54 transcript pages, and 13,747 usable segments.
- The current `results_memo.md` reports 357 recent episodes, 93 cached transcript pages, 23,622 usable segments, and 532 scored movies.
- During audit, `results_memo.md` had a later modification time than the QMD/HTML, so the published post appears stale against newer outputs.

### 3. The movie commonality table in the prose does not match the current CSV
- The QMD table reports `Total mentions = 15.4 vs 5.6` and `Industry share = 0.32 vs 0.22`.
- The current `tab_movie_commonalities.csv` reports materially different values, including `total_mentions = 23.3158 vs 7.9023` and `industry_share = 0.2258 vs 0.1833`.
- This is a direct source-to-output mismatch, not just a rounding issue.

### 4. The movie-preference pipeline is still labeling non-movies as movies
- The scored movie table contains people and fragments such as `Andy Greenwald`, `Richard Linklater`, `David Sims`, `Sean Fennessey`, `Jafar Panahi`, `Jack Sanders`, `Die My`, `Year So`, and `The Most Exciting`.
- The figure labels inherit this contamination.
- The draft does disclose that title extraction is exploratory, but the current output quality is below what the narrative framing implies.

### 5. The Oscar section claims visible reasoning infrastructure, but the shipped artifacts are still pure placeholders
- The section says the project can already identify Oscar-focused episodes and build the skeleton of a prediction dataset.
- Yet all three linked Oscar outputs contain only a one-line note saying there is no cached sample yet.
- That makes the title-level Oscar framing materially ahead of the evidence currently shipped with the post.

## Secondary presentation issues
- Figure captions are generic and do not explain axes, smoothing choices, or sample definitions.
- The rendered HTML links directly to raw CSV artifacts and a local replication README, which is acceptable for a draft but not yet publication-quality blog presentation.
- The sentiment figure is visually noisy relative to the confidence of the prose.

## Recommended next action
- Reject this draft for publication.
- Refresh the QMD against the current output artifacts, then downgrade unsupported claims.
- Do not present movie-level preference findings as substantive until the title extractor stops surfacing obvious people/fragments as films.
