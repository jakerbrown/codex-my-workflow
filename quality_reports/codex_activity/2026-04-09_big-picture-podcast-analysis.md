Worked on the Oscar completion push for the Big Picture podcast project.

I rebuilt the Oscar prediction outputs from cached transcript pages, corrected a
misleading figure title, and rewrote the draft post so the Oscar section now
uses real artifact-backed results instead of placeholder language.

This mattered because Oscars were the last major unfinished part of the
analysis. The package can now answer the third core question in a bounded but
serious way: 17 pre-ceremony forecast episodes, 4 revisions, and strong
season-to-season variation in accuracy.

Verified:
- reran `rebuild_oscar_outputs.R`
- rerendered the Quarto draft to HTML and GFM
- refreshed `blog_post_for_site.md`
- ran two explicit read-only review agents on the Oscar layer

Left unresolved:
- the Oscar extractor is still heuristic rather than hand-coded
- speaker-level disagreement is still unavailable from the public transcript
  structure

Follow-up later the same day:
- restarted the broad transcript fetcher after spotting a stale 337-row
  transcript manifest against a 357-episode recent manifest
- the catch-up pass finished cleanly and brought recent transcript coverage to
  357/357
- next step is an hourly refresh/report cadence rather than another manual
  one-off fetch
