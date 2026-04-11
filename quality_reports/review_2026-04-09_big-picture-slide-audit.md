# Review: Big Picture slide-auditor pass

- **Date:** 2026-04-09
- **Reviewer role:** `slide-auditor`
- **Artifact reviewed:**
  - `explorations/big-picture-podcast-analysis/output/blog_post_draft.qmd`
  - `explorations/big-picture-podcast-analysis/output/blog_post_draft.html`
  - `explorations/big-picture-podcast-analysis/output/fig_sentiment_timeseries.png`
  - `explorations/big-picture-podcast-analysis/output/fig_movie_preference_clusters.png`
- **Review scope:** visual presentation, figure readability, table usability,
  and layout density
- **Quality score:** 68 / 100
- **Threshold read:** clears exploration quality, does not clear blog-ready
  presentation quality

## Prioritized findings

### 1. Critical: Rendered asset paths are not portable, so figures and support links will break outside the local filesystem

- Evidence:
  - Source draft uses absolute filesystem paths for the replication link, both
    figures, and all CSV references at
    `explorations/big-picture-podcast-analysis/output/blog_post_draft.qmd:50`,
    `explorations/big-picture-podcast-analysis/output/blog_post_draft.qmd:112`,
    `explorations/big-picture-podcast-analysis/output/blog_post_draft.qmd:116`,
    `explorations/big-picture-podcast-analysis/output/blog_post_draft.qmd:155`,
    `explorations/big-picture-podcast-analysis/output/blog_post_draft.qmd:166`,
    `explorations/big-picture-podcast-analysis/output/blog_post_draft.qmd:177`,
    `explorations/big-picture-podcast-analysis/output/blog_post_draft.qmd:178`,
    `explorations/big-picture-podcast-analysis/output/blog_post_draft.qmd:179`.
  - Quarto rendered these into broken relative URLs like `./Users/...` in
    `explorations/big-picture-podcast-analysis/output/blog_post_draft.html:114`,
    `explorations/big-picture-podcast-analysis/output/blog_post_draft.html:151`,
    `explorations/big-picture-podcast-analysis/output/blog_post_draft.html:155`,
    `explorations/big-picture-podcast-analysis/output/blog_post_draft.html:181`,
    `explorations/big-picture-podcast-analysis/output/blog_post_draft.html:186`,
    `explorations/big-picture-podcast-analysis/output/blog_post_draft.html:196`,
    `explorations/big-picture-podcast-analysis/output/blog_post_draft.html:197`,
    `explorations/big-picture-podcast-analysis/output/blog_post_draft.html:198`.
- Why it matters:
  - This is a presentation blocker, not a minor polish issue. A reader viewing
    the rendered post outside this exact machine will lose the figures and the
    evidence links.
- Specific fix:
  - Use paths relative to the `.qmd` location or the eventual site post
    directory.
  - If this is destined for a blog post folder, co-locate the figures and table
    assets there and reference them with short local paths such as
    `fig_sentiment_timeseries.png`.
  - Re-render and confirm the HTML emits normal relative URLs rather than
    `./Users/...`.

### 2. High: The post links to raw CSVs instead of presenting usable tables inline

- Evidence:
  - The sentiment result cites `tab_sentiment_model.csv` as a naked link rather
    than a rendered table at
    `explorations/big-picture-podcast-analysis/output/blog_post_draft.qmd:115`.
  - The movie-preference section does the same for
    `tab_movie_commonalities.csv` at
    `explorations/big-picture-podcast-analysis/output/blog_post_draft.qmd:153`.
  - The Oscar section lists three raw artifact files instead of presenting a
    reader-facing summary at
    `explorations/big-picture-podcast-analysis/output/blog_post_draft.qmd:174`.
  - The current table files are not article-ready on their own. One is a wide
    coefficient dump, one is a plain four-row numeric CSV, and one is only a
    placeholder note:
    `explorations/big-picture-podcast-analysis/output/tab_oscar_evidence_weights.csv`.
- Why it matters:
  - A blog reader should not have to open CSV files to understand the argument.
    Right now the prose carries the burden while the evidence remains visually
    inaccessible.
- Specific fix:
  - Render compact HTML tables inline for the one or two statistics each section
    actually needs.
  - Round values, rename columns to reader-facing labels, and use a short
    caption with the interpretive takeaway.
  - Keep the CSV downloads as secondary links below the rendered table if the
    raw files still need to be available.
  - Suppress placeholder Oscar tables from the main narrative until they contain
    real content; use a one-line callout instead.

### 3. High: The movie-preference scatterplot is too dense for article-width reading

- Evidence:
  - `explorations/big-picture-podcast-analysis/output/fig_movie_preference_clusters.png`
    contains a very large point cloud, mixed bubble sizes, a diverging color
    scale, and a limited set of direct labels.
  - At normal article width, the labels are visually small, several compete with
    nearby marks, and the legend sits far from the data region.
- Why it matters:
  - The figure asks readers to decode too many channels at once: x-position,
    y-position, color, size, and selective labeling. That works as an
    exploratory analyst plot, but not as a polished explanatory graphic.
- Specific fix:
  - Reduce the visual task. Keep only the top 8 to 12 labeled titles and fade
    the rest harder.
  - Convert the current single panel into either:
    - a quadrant plot with explicit annotations for each quadrant, or
    - a two-panel layout separating positive exemplars from the full cloud.
  - Move the legend directly under the plotting area and state the encodings in
    the subtitle so the reader does not have to infer them from the scale alone.
  - Increase label contrast and add label halos or repelling so named titles are
    actually readable after the image is scaled down in HTML.

### 4. Medium: The sentiment figure is directionally clear but still too annotation-light for fast reading

- Evidence:
  - `explorations/big-picture-podcast-analysis/output/fig_sentiment_timeseries.png`
    overlays a jagged series and smoother trends with a legend lookup.
  - The blue series is relatively low-contrast and thin compared with the red
    series, and the rotated time labels are doing substantial work.
- Why it matters:
  - Readers can see that the red series falls, but the figure still takes
    effort to parse. The visual takeaway should be nearly instant because this
    is the strongest result in the piece.
- Specific fix:
  - Direct-label the lines near their endpoints instead of relying on a top
    legend.
  - Thicken the blue line and reduce x-axis tick frequency to a few anchor
    dates.
  - Add a subtitle or caption sentence that names the key contrast:
    summary sentiment stays positive while industry-coded transcript sentiment
    trends down.
  - If keeping both raw and smoothed series, make the raw series lighter and the
    smooth dominant.

### 5. Medium: The draft is text-dense around the figures and does not give visuals enough explanatory framing

- Evidence:
  - Both results sections place long paragraphs before and after each figure at
    `explorations/big-picture-podcast-analysis/output/blog_post_draft.qmd:108`
    through
    `explorations/big-picture-podcast-analysis/output/blog_post_draft.qmd:130`
    and
    `explorations/big-picture-podcast-analysis/output/blog_post_draft.qmd:134`
    through
    `explorations/big-picture-podcast-analysis/output/blog_post_draft.qmd:164`.
  - The inserted figures have only minimal captions: "Sentiment over time" and
    "Movie preference clusters."
- Why it matters:
  - Minimal captions force the surrounding prose to do all the explanatory work,
    which increases scan cost and makes the article feel denser than necessary.
- Specific fix:
  - Add a one-sentence result takeaway immediately before each figure and a real
    caption immediately below it.
  - Use captions to define the sample, the metric, and the one thing the reader
    should notice.
  - Trim repeated caveat language in the surrounding paragraphs once the figure
    captions carry more interpretive weight.

### 6. Medium: The draft and rendered HTML appear out of sync for the workflow map section

- Evidence:
  - The source `.qmd` includes a `## Workflow map` section with a mermaid block
    at
    `explorations/big-picture-podcast-analysis/output/blog_post_draft.qmd:54`
    through
    `explorations/big-picture-podcast-analysis/output/blog_post_draft.qmd:66`.
  - A direct search of the rendered HTML found no `Workflow map`, `mermaid`, or
    `flowchart LR` content.
- Why it matters:
  - If the rendered artifact is stale or the mermaid block is being dropped,
    the review surface and the shipped surface are no longer the same thing.
- Specific fix:
  - Re-render from the current `.qmd` and verify the map actually appears.
  - If mermaid support is unreliable for the destination, replace it with a
    static image or drop it entirely rather than carrying hidden drift.

## Presentation fixes to prioritize first

1. Fix all asset references to use portable relative paths and re-render.
2. Replace raw CSV links in the main narrative with one inline sentiment table
   and one inline movie-commonality table.
3. Rework the movie-preference figure into a simpler explanatory graphic.
4. Add substantive figure captions and direct labeling to the sentiment chart.
5. Confirm the workflow map is either rendered correctly or intentionally
   removed.

## Verification completed

- Read the source draft and the rendered HTML.
- Inspected both exported PNG figures directly.
- Checked the current CSV artifacts to judge whether they are reader-facing or
  raw-analysis outputs.

## Verification not completed

- Did not open the rendered post in a browser viewport, so this review is based
  on source, rendered HTML structure, and direct figure inspection rather than a
  full in-browser responsive audit.
