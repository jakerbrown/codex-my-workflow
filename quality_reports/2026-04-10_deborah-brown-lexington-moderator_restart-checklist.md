# Restart Checklist: Deborah Brown Lexington moderator analysis

- **Created:** 2026-04-10
- **Purpose:** Resume the interrupted Mother's Day Deborah Brown analysis
  without rethinking the whole project from scratch.

## What already exists

- Plan:
  - `quality_reports/plans/2026-04-09_deborah-brown-lexington-moderator.md`
- Session log:
  - `quality_reports/session_logs/2026-04-09_deborah-brown-lexington-moderator.md`
- Exploration scaffold:
  - `explorations/deborah-brown-lexington-moderator/README.md`
  - `explorations/deborah-brown-lexington-moderator/SESSION_LOG.md`

## What was learned but not yet saved as final artifacts

- Lexington's official Town Meeting page links meeting pages for `2016-2026`
  and a prior-years archive.
- Lexington's official election-results page links annual town-election PDFs
  from `2014-2026`.
- A live shell pass found Deborah Brown listed as the moderator winner in each
  checked annual election PDF from `2014` through `2026`.
- Public web leads suggested her tenure likely begins in `2009`, but that has
  not yet been written into a durable source memo and should be re-verified.
- The LocalView public dataset is exposed through Harvard Dataverse with yearly
  parquet files from `2006-2023`.
- The LocalView codebook confirms the main fields needed for filtering and text
  analysis, including `meeting_date`, `place_name`, `place_govt`,
  `vid_title`, `caption_text`, and `caption_text_clean`.
- The user approved using the external volume for storage if large LocalView
  pulls or caches make that helpful.

## Immediate resume steps

1. Append a fresh timestamped note to both session logs before more work.
2. Re-run tenure verification and save it immediately to disk:
   - official Lexington election PDFs
   - any corroborating public source for the first year of service
3. Create a source inventory file with:
   - URL
   - source type
   - access date
   - what it verifies
   - whether it is official or contextual
4. Create a data memo stub early so coverage and caveats can be filled in as
   the pull proceeds.

## Data-collection tasks to resume

1. Build a Lexington meeting manifest from official Town Meeting pages.
2. Recover all public meeting minutes, vote records, or legal-posting records
   for meetings during Brown's verified tenure.
3. Build a LocalView extraction script that:
   - pulls only the necessary yearly parquet files
   - filters to Lexington meetings
   - writes a compact local manifest and derived text data
4. Decide and document cache locations:
   - repo for lightweight derived outputs
   - external volume for bulky raw parquet or temporary caches if needed

## Analysis build tasks

1. Create replication scripts for:
   - acquisition
   - cleaning
   - merge
   - analysis
   - figures/tables
2. Build the meeting-level panel over the verified tenure.
3. Generate the core outputs requested by the prompt:
   - meetings by year
   - speech volume over time
   - intervention counts over time
   - lexical diversity
   - sentiment / tone
   - procedural vs deliberative language
   - annual vs special meeting comparisons
   - duration or article-volume proxies when available
4. Write the blog draft, replication README, source inventory, and data memo.

## Review and verification tasks

1. Run the replication workflow end to end and save a verifier report.
2. Spawn the required specialists:
   - `r-reviewer`
   - `domain-reviewer`
   - `proofreader`
   - `verifier`
   - `slide-auditor`
   - `pedagogy-reviewer`
   - `quarto-critic`
   - `quarto-fixer`
3. Write a synthesized specialist-review report in `quality_reports/`.
4. Re-run verification after fixes.
5. Write the breadcrumb in `quality_reports/codex_activity/` before wrap-up.

## Key unresolved questions

- What is the cleanest official evidence for the first year of Deborah Brown's
  tenure if the older Lexington election PDFs are harder to access directly?
- How complete is LocalView coverage for Lexington across the full tenure?
- Which official meeting records are minutes versus vote summaries only?
- How reliable is moderator speech attribution in the LocalView text for this
  specific municipality?

## Minimal success condition for restart

Do not treat the job as resumed successfully until the following exist on disk:

- source inventory
- tenure verification note
- meeting manifest
- at least one working acquisition script
- at least one working analysis script
- updated session logs

## Helpful reminder

The interrupted run did **not** produce substantive code or data artifacts yet.
The main value preserved so far is the workflow setup plus reconnaissance about
where the public records and LocalView surfaces live.
