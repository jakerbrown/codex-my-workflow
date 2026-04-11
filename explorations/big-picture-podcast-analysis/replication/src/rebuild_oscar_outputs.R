#!/usr/bin/env Rscript

script_file_arg <- commandArgs(trailingOnly = FALSE)
script_file_arg <- script_file_arg[grepl("^--file=", script_file_arg)]
script_dir <- if (length(script_file_arg) == 0) getwd() else dirname(normalizePath(sub("^--file=", "", script_file_arg[[1]])))
source(file.path(script_dir, "big_picture_lib.R"))

paths <- get_project_paths()
ensure_dirs(paths)

episode_manifest <- read_csv(file.path(paths$exploration_output, "episode_manifest.csv"), show_col_types = FALSE)
transcript_manifest <- read_csv(file.path(paths$exploration_output, "transcript_manifest.csv"), show_col_types = FALSE)
transcript_segments <- read_csv(file.path(paths$exploration_processed, "transcript_segments_derived.csv"), show_col_types = FALSE)

assign_oscar_season <- function(date) if_else(month(date) <= 3, year(date), year(date) + 1)

prediction_title_regex <- regex(
  paste(
    c(
      "best picture power rankings",
      "oscar predictions",
      "big oscar bet",
      "way-too-early oscar predictions",
      "how oscar voting really works",
      "our oscar nomination predictions",
      "oscar nominations: snubs, surprises, and wtfs",
      "2025 oscar nominations: snubs, surprises, and wtfs",
      "2024 oscar nominations: snubs, surprises, and wtfs",
      "the 2023 oscar nominations: snubs, surprises, and wtfs",
      "golden globe nominations",
      "the return of the big oscar bet"
    ),
    collapse = "|"
  ),
  ignore_case = TRUE
)

exclude_title_regex <- regex(
  paste(
    c(
      "alternative oscars",
      "big picks",
      "hangover",
      "mailbag",
      "movie draft",
      "^the 202[345] oscars:",
      "^the 2026 academy awards:",
      "summer movie preview",
      "25 most anticipated movies",
      "top 10 underseen movies",
      "best movies at sundance",
      "horror oscars",
      "top five war movies",
      "movie auction",
      "^m3gan",
      "^julia roberts",
      "^the power of godzilla",
      "^the barbie freak-out",
      "^the loss of david lynch",
      "^the brutalist, the best movies at the new york film festival",
      "^is weapons a classic",
      "^the truth about netflix buying warner bros",
      "^the top 10 best movies at sundance",
      "^the 10 best movies at sundance"
    ),
    collapse = "|"
  ),
  ignore_case = TRUE
)

prediction_cue_regex <- regex(
  paste(
    c(
      "will win",
      "going to win",
      "gonna win",
      "should win",
      "my pick",
      "pick is",
      "i pick",
      "i picked",
      "i'm going with",
      "i am going with",
      "i have .* winning",
      "number one",
      "no\\. 1",
      "front runner",
      "frontrunner",
      "has the edge",
      "comes down to"
    ),
    collapse = "|"
  ),
  ignore_case = TRUE
)

strong_prediction_regex <- regex(
  paste(
    c(
      "will win",
      "going to win",
      "gonna win",
      "my pick",
      "pick is",
      "i pick",
      "i picked",
      "i'm going with",
      "i am going with",
      "i have .* winning",
      "number one",
      "no\\. 1"
    ),
    collapse = "|"
  ),
  ignore_case = TRUE
)

best_picture_cue_regex <- regex(
  paste(
    c(
      "best picture",
      "the nominees in this category",
      "preferential ballot",
      "wins best picture",
      "for picture",
      "academy awards",
      "the race comes down to"
    ),
    collapse = "|"
  ),
  ignore_case = TRUE
)

evidence_patterns <- list(
  guild = "sag|pga|dga|wga|guild|bafta",
  festival = "venice|cannes|tiff|telluride|festival|nyff|sundance",
  box_office = "box office|gross|ticket sales|theaters",
  campaign = "campaign|campaigning|push|studio support|netflix|searchlight|universal|a24",
  narrative = "narrative|momentum|front.?runner|heat|buzz|surge",
  priors = "academy|voters|they like|they love|the academy goes for|preferential ballot",
  release_timing = "release date|released|late breaker|december|summer release|fall festival",
  star_power = "movie star|star power|director|filmmaker|cast|performance|actor|actress"
)

detect_episode_mode <- function(title) {
  case_when(
    str_detect(title, regex("best picture power rankings|big oscar bet|way-too-early oscar predictions", ignore_case = TRUE)) ~ "whole_episode",
    str_detect(title, regex("oscar predictions|academy awards|oscar nominations|golden globe nominations", ignore_case = TRUE)) ~ "best_picture_section",
    TRUE ~ "whole_episode"
  )
}

extract_best_picture_window <- function(df, season) {
  if (nrow(df) == 0) {
    return(df)
  }
  contenders <- oscar_lookup |>
    filter(season == !!season) |>
    pull(contender) |>
    str_to_lower()
  marker_idx <- which(map_lgl(df$lower_text, function(txt) {
    cue_hits <- sum(str_detect(txt, fixed(contenders)))
    (str_detect(txt, regex("best picture", ignore_case = TRUE)) && cue_hits >= 2) ||
      (str_detect(txt, regex("nominees? in this category", ignore_case = TRUE)) && cue_hits >= 3)
  }))
  if (length(marker_idx) == 0) {
    marker_idx <- which(map_lgl(df$lower_text, function(txt) {
      cue_hits <- sum(str_detect(txt, fixed(contenders)))
      str_detect(txt, regex("best picture", ignore_case = TRUE)) && cue_hits >= 1
    }))
  }
  if (length(marker_idx) == 0) {
    return(df)
  }
  start <- marker_idx[[length(marker_idx)]]
  end <- min(nrow(df), start + 40)
  df[start:end, ]
}

score_contender_in_episode <- function(section_df, contender) {
  contender_lower <- str_to_lower(contender)
  mention_flags <- str_detect(section_df$lower_text, fixed(contender_lower))
  if (!any(mention_flags)) {
    return(tibble(
      contender = contender,
      mention_count = 0L,
      explicit_hits = 0L,
      lean_hits = 0L,
      best_picture_hits = 0L,
      support_segments = 0L,
      score = 0
    ))
  }

  idx <- which(mention_flags)
  explicit_hits <- 0L
  lean_hits <- 0L
  bp_hits <- 0L
  support_segments <- 0L

  for (i in idx) {
    lo <- max(1, i - 1)
    hi <- min(nrow(section_df), i + 1)
    window_text <- paste(section_df$lower_text[lo:hi], collapse = " ")
    has_pred <- str_detect(window_text, prediction_cue_regex)
    has_strong <- str_detect(window_text, strong_prediction_regex)
    has_bp <- str_detect(window_text, best_picture_cue_regex)
    if (has_pred || has_bp) {
      support_segments <- support_segments + 1L
    }
    if (has_strong) {
      explicit_hits <- explicit_hits + 1L
    } else if (has_pred) {
      lean_hits <- lean_hits + 1L
    }
    if (has_bp) {
      bp_hits <- bp_hits + 1L
    }
  }

  score <- explicit_hits * 3 + lean_hits * 1.5 + bp_hits * 0.5 + sum(mention_flags) * 0.1

  tibble(
    contender = contender,
    mention_count = sum(mention_flags),
    explicit_hits = explicit_hits,
    lean_hits = lean_hits,
    best_picture_hits = bp_hits,
    support_segments = support_segments,
    score = score
  )
}

oscar_candidates <- episode_manifest |>
  mutate(oscar_season = assign_oscar_season(episode_date)) |>
  left_join(transcript_manifest |>
              select(slug, transcript_available, usable_segments, fetch_status),
            by = "slug") |>
  left_join(oscar_lookup |>
              distinct(season, ceremony_date, winner),
            by = c("oscar_season" = "season")) |>
  filter(
    oscar_season %in% unique(oscar_lookup$season),
    transcript_available %in% TRUE,
    episode_date < ceremony_date,
    str_detect(title, prediction_title_regex),
    !str_detect(title, exclude_title_regex)
  ) |>
  mutate(mode = detect_episode_mode(title)) |>
  arrange(oscar_season, episode_date)

prediction_rows <- map_dfr(seq_len(nrow(oscar_candidates)), function(i) {
  ep <- oscar_candidates[i, ]
  segs <- transcript_segments |>
    filter(slug == ep$slug) |>
    arrange(segment_id)
  if (nrow(segs) == 0) {
    return(tibble())
  }
  section_df <- if (ep$mode[[1]] == "best_picture_section") {
    extract_best_picture_window(segs, ep$oscar_season[[1]])
  } else {
    segs
  }
  if (nrow(section_df) == 0) {
    return(tibble())
  }

  evidence_text <- paste(section_df$lower_text, collapse = " ")
  evidence_counts <- purrr::map_int(evidence_patterns, ~ stringr::str_count(evidence_text, .x))

  contender_scores <- oscar_lookup |>
    filter(season == ep$oscar_season[[1]]) |>
    pull(contender) |>
    map_dfr(~ score_contender_in_episode(section_df, .x)) |>
    mutate(
      slug = ep$slug,
      title = ep$title,
      episode_date = ep$episode_date,
      oscar_season = ep$oscar_season,
      winner = ep$winner,
      ceremony_date = ep$ceremony_date,
      mode = ep$mode,
      guild_mentions = evidence_counts[["guild"]],
      festival_mentions = evidence_counts[["festival"]],
      box_office_mentions = evidence_counts[["box_office"]],
      campaign_mentions = evidence_counts[["campaign"]],
      narrative_mentions = evidence_counts[["narrative"]],
      priors_mentions = evidence_counts[["priors"]],
      release_timing_mentions = evidence_counts[["release_timing"]],
      star_power_mentions = evidence_counts[["star_power"]]
    )
  contender_scores
})

if (nrow(prediction_rows) == 0) {
  write_dual_csv(tibble(note = "No pre-ceremony Oscar prediction episodes available in the current cache."), "oscar_predictions.csv", paths)
  write_dual_csv(tibble(note = "No pre-ceremony Oscar evaluation sample available in the current cache."), "oscar_prediction_evaluation.csv", paths)
  write_dual_csv(tibble(note = "No Oscar evidence-weight sample available in the current cache."), "tab_oscar_evidence_weights.csv", paths)
  quit(save = "no")
}

episode_predictions <- prediction_rows |>
  group_by(slug) |>
  arrange(desc(score), desc(explicit_hits), desc(best_picture_hits), desc(mention_count), contender, .by_group = TRUE) |>
  mutate(predicted = row_number() == 1 & score >= 1.5) |>
  ungroup()

oscar_predictions <- episode_predictions |>
  filter(predicted)

oscar_eval <- oscar_predictions |>
  mutate(
    days_before_ceremony = as.integer(ceremony_date - episode_date),
    horizon_bucket = case_when(
      days_before_ceremony > 120 ~ "Early season",
      days_before_ceremony > 30 ~ "Post-noms / precursor stretch",
      TRUE ~ "Final month"
    ),
    correct = contender == winner
  ) |>
  arrange(oscar_season, episode_date) |>
  group_by(oscar_season) |>
  mutate(revision = contender != lag(contender, default = first(contender))) |>
  ungroup()

write_dual_csv(episode_predictions, "oscar_predictions.csv", paths)
write_dual_csv(oscar_eval, "oscar_prediction_evaluation.csv", paths)

evidence_weights <- oscar_eval |>
  summarise(
    episodes = n(),
    correct_rate = mean(correct),
    revision_rate = mean(revision, na.rm = TRUE),
    guild = mean(guild_mentions),
    festival = mean(festival_mentions),
    box_office = mean(box_office_mentions),
    campaign = mean(campaign_mentions),
    narrative = mean(narrative_mentions),
    priors = mean(priors_mentions),
    release_timing = mean(release_timing_mentions),
    star_power = mean(star_power_mentions)
  ) |>
  pivot_longer(cols = guild:star_power, names_to = "evidence_type", values_to = "mean_mentions") |>
  left_join(
    oscar_eval |>
      summarise(
        guild_revision = mean(guild_mentions[revision], na.rm = TRUE),
        festival_revision = mean(festival_mentions[revision], na.rm = TRUE),
        box_office_revision = mean(box_office_mentions[revision], na.rm = TRUE),
        campaign_revision = mean(campaign_mentions[revision], na.rm = TRUE),
        narrative_revision = mean(narrative_mentions[revision], na.rm = TRUE),
        priors_revision = mean(priors_mentions[revision], na.rm = TRUE),
        release_timing_revision = mean(release_timing_mentions[revision], na.rm = TRUE),
        star_power_revision = mean(star_power_mentions[revision], na.rm = TRUE),
        guild_correct = mean(guild_mentions[correct], na.rm = TRUE),
        festival_correct = mean(festival_mentions[correct], na.rm = TRUE),
        box_office_correct = mean(box_office_mentions[correct], na.rm = TRUE),
        campaign_correct = mean(campaign_mentions[correct], na.rm = TRUE),
        narrative_correct = mean(narrative_mentions[correct], na.rm = TRUE),
        priors_correct = mean(priors_mentions[correct], na.rm = TRUE),
        release_timing_correct = mean(release_timing_mentions[correct], na.rm = TRUE),
        star_power_correct = mean(star_power_mentions[correct], na.rm = TRUE)
      ) |>
      pivot_longer(everything(), names_to = "metric", values_to = "value") |>
      mutate(
        evidence_type = str_remove(metric, "_revision$|_correct$"),
        metric_type = case_when(
          str_detect(metric, "_revision$") ~ "mean_mentions_revision_episodes",
          str_detect(metric, "_correct$") ~ "mean_mentions_correct_episodes",
          TRUE ~ "other"
        )
      ) |>
      select(evidence_type, metric_type, value) |>
      pivot_wider(names_from = metric_type, values_from = value),
    by = "evidence_type"
  ) |>
  arrange(desc(mean_mentions))

write_dual_csv(evidence_weights, "tab_oscar_evidence_weights.csv", paths)

oscar_fig_df <- oscar_eval |>
  group_by(horizon_bucket) |>
  summarise(
    accuracy = mean(correct),
    revisions = sum(revision, na.rm = TRUE),
    episodes = n(),
    .groups = "drop"
  ) |>
  mutate(horizon_bucket = factor(horizon_bucket, levels = c("Early season", "Post-noms / precursor stretch", "Final month")))

p_oscar <- ggplot(oscar_fig_df, aes(horizon_bucket, accuracy)) +
  geom_col(fill = "#264653", width = 0.65) +
  geom_text(aes(label = percent(accuracy, accuracy = 1)), vjust = -0.4, size = 4) +
  geom_point(aes(y = revisions / max(revisions) * max(accuracy), size = revisions), color = "#e76f51") +
  scale_y_continuous(labels = percent_format(accuracy = 1), limits = c(0, 1)) +
  labs(
    title = "Best Picture prediction accuracy varies sharply across horizons",
    subtitle = "Pre-ceremony Big Picture forecast episodes from the current transcript cache",
    x = NULL,
    y = "Prediction accuracy",
    size = "Revision count"
  ) +
  theme_minimal(base_size = 12)

save_dual_plot(p_oscar, "fig_oscar_prediction_accuracy.png", paths, width = 10, height = 7)
