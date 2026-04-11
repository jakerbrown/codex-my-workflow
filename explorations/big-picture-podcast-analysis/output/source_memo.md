# Source Memo

## Primary sources in use

### 1. Podscripts podcast listing pages

- URL pattern:
  - `https://podscripts.co/podcasts/the-big-picture/`
  - paginated with `?page=2`, `?page=3`, and so on
- What they provide:
  - episode title
  - episode date
  - short summary / description
  - transcript-page URL
- Why they matter:
  - they support a full episode manifest without private access

### 2. Podscripts episode transcript pages

- URL pattern:
  - `https://podscripts.co/podcasts/the-big-picture/<episode-slug>`
- What they provide:
  - episode date
  - summary text
  - timestamped transcript spans grouped into segments
- Constraint:
  - the site appears rate-limited for large batch retrieval

### 3. The Ringer show page and public podcast directories

- Purpose:
  - sanity-check show identity, episode framing, and external metadata
- Status:
  - useful as validation and context, not currently the core transcript source

## Lawful-access stance

- The analysis uses public web pages that are openly accessible in this
  environment.
- The repo does not commit full transcript dumps as durable project artifacts.
- The replication workflow records transcript pull outcomes and writes derived
  analytic outputs instead.

## Coverage expectations

- Episode listings appear to span the full show history back to January 13,
  2017.
- The recent-analysis window is centered on 2023-2025 for the current run.
- Transcript completeness for that window depends on the paced pull and will be
  reported in `transcript_manifest.csv`.

## Missingness risk

- Missingness is likely to be operational, not purely random:
  - rate limits may make transcript success depend on pull timing
  - older or especially large transcript pages may fail more often
- This could bias transcript-backed analyses toward whichever pages are easiest
  to retrieve reliably.

## Mitigation

- Keep the full episode manifest even when transcript pulls fail.
- Separate summary-backed analyses from transcript-backed analyses.
- Record transcript success/failure directly in the final manifest.
