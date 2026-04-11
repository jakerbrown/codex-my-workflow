# Plan: Deborah Brown Lexington moderator analysis

- **Date:** 2026-04-09
- **Status:** IN PROGRESS
- **Owner:** Codex
- **Quality target:** 90

## Goal

Produce a rigorous, blog-ready Mother's Day appreciation post about Deborah
Brown's tenure as Lexington, Massachusetts Town Moderator, using all lawfully
accessible LocalView data during her verified tenure, merged where feasible
with official Lexington Town Meeting minutes and other reputable public context.

## Scope

- In scope:
  - Verifying Deborah Brown's actual tenure dates from primary public sources.
  - Building a meeting-level panel covering all Town Meetings during that
    verified tenure for which public materials are available.
  - Pulling and processing LocalView meeting metadata and moderator-attributed
    speech using lawful public access only.
  - Collecting official Lexington Town Meeting minutes or vote records for the
    same meetings when publicly available.
  - Writing a polished blog draft, a code-only replication package, a source
    inventory, and a data memo.
  - Running the required specialist-review and adversarial-review loop.
- Out of scope:
  - Redistributing copyrighted full transcripts when the source terms do not
    permit it.
  - Inflating causal claims beyond descriptive or exploratory evidence.
  - Using private, paywalled, or access-controlled civic records.

## Core questions

1. What are Deborah Brown's exact tenure bounds as Lexington Town Moderator?
2. Which Town Meetings during that tenure are covered by LocalView, and with
   what metadata and transcript quality?
3. Which official minutes or vote records are publicly available for those
   meetings, and how cleanly can they be merged to LocalView?
4. What descriptive patterns best characterize Brown's moderation style over
   time without overstating what the text can identify?

## Working design

- Primary meeting-text source:
  - LocalView public data downloads plus any lawful public meeting-level access
    needed for verification.
- Official-town supplement:
  - Lexington Town Meeting pages, official minutes, legal postings, and vote
    records from `lexingtonma.gov` and `records.lexingtonma.gov`.
- Positive contextual sources:
  - Official town pages, election results, Massachusetts Municipal Association
    coverage, and other reputable local reporting or civic profiles.
- Replication stance:
  - Code-only package in the exploration folder.
  - Derived analytic datasets may be saved when lawful and lightweight.
  - Raw copyrighted transcripts should be referenced, not republished, unless
    the source clearly permits redistribution.

## Expected files

- `quality_reports/plans/2026-04-09_deborah-brown-lexington-moderator.md`
- `quality_reports/session_logs/2026-04-09_deborah-brown-lexington-moderator.md`
- `explorations/deborah-brown-lexington-moderator/README.md`
- `explorations/deborah-brown-lexington-moderator/SESSION_LOG.md`
- `explorations/deborah-brown-lexington-moderator/output/*`
- `explorations/deborah-brown-lexington-moderator/replication/*`
- `quality_reports/review_*deborah-brown-lexington-moderator*.md`
- `quality_reports/adversarial_deborah-brown-lexington-moderator_round*.md`
- `quality_reports/codex_activity/2026-04-09_deborah-brown-lexington-moderator.md`

## Implementation plan

1. Verify tenure bounds and build a public source inventory.
2. Audit LocalView coverage and official Lexington Town Meeting records across
   the verified tenure.
3. Build reproducible acquisition, cleaning, merge, and analysis scripts.
4. Generate meeting-level datasets, publication-quality figures, and tables.
5. Draft the blog post and supporting data memo.
6. Run the required specialist agents in parallel where possible, fix material
   findings, re-verify, score, and summarize.

## Verification plan

- Confirm tenure bounds from at least one official Lexington source and
  supporting public corroboration if needed.
- Run the data-acquisition scripts and confirm the meeting manifest, source
  inventory, and processed analytic files are created.
- Run the main analysis script and confirm expected figures, tables, and memo
  outputs exist.
- Run the replication entry point and record pass/fail status.
- Re-read the narrative against the final outputs and review findings.

## Review plan

- Required specialists:
  - `r-reviewer`
  - `domain-reviewer`
  - `proofreader`
  - `verifier`
  - `slide-auditor`
  - `pedagogy-reviewer`
  - `quarto-critic`
  - `quarto-fixer`
- Adversarial loop:
  - At least one real `quarto-critic` pass followed by a `quarto-fixer` pass
    if the critic finds material issues, then a re-check.

## Risks

- LocalView coverage may not fully span the entire tenure.
- Official minutes may vary in format or be missing for some meetings.
- Moderator speech attribution may be noisy in transcript data.
- Some public links may require browser navigation or legacy records access.

## Success threshold

The project is done only if the artifacts, verification, and reviews clear a
quality score of at least 90, or if a concrete blocker is documented with exact
missing pieces and their consequences.
