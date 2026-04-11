# Methods Memo

## Design philosophy

This project uses a layered design instead of pretending one noisy NLP score can
answer all three questions.

## Measurement layers

### Episode-level sentiment

- Full recent archive:
  - sentiment from public episode summaries
- Transcript-backed subset:
  - segment-level sentiment from a cleaned transcript corpus
  - custom industry-topic filtering for box office, streaming, studios,
    theaters, and awards-ecosystem talk

### Movie preference inference

- Unit:
  - movie-by-episode mention context
- Evidence:
  - repeated transcript mentions
  - positive and negative evaluative phrase rates
  - episode context such as Oscar coverage, rankings, or retrospective canon
    talk
- Rule:
  - movies need repeated evidence before entering the scored sample

### Oscar prediction coding

- Focus:
  - explicitly Oscar-focused episodes
- Working object:
  - inferred Best Picture frontrunner / pick at the episode level
- Signals:
  - contender mention counts
  - explicit pick phrases
  - tentative-lean phrases
  - evidence-type counts for guilds, festivals, narrative, box office, and
    campaign logic
- Current extraction rule:
  - score contenders within either a whole-episode ranking format or a
    Best-Picture-only transcript window extracted from broader Oscar episodes
- Revision definition:
  - the inferred pick changes relative to the prior sampled pre-ceremony
    episode in the same Oscar season
- Accuracy definition:
  - inferred pick matches the realized Best Picture winner
- Interpretation rule:
  - evidence counts are descriptive features of the discussion, not causal
    regression weights

## Current caveats

- Transcript coverage is operationally limited by public-web rate limiting.
- Speaker attribution is not currently available in the public mirror.
- Movie-title extraction is conservative and should be treated as a lower bound
  on recoverable preference evidence.
- Oscar extraction is rule-based and should be hand-validated on a sampled set
  before making stronger claims about host-specific prediction theory.
