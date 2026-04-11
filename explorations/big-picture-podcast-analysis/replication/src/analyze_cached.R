#!/usr/bin/env Rscript

script_file_arg <- commandArgs(trailingOnly = FALSE)
script_file_arg <- script_file_arg[grepl("^--file=", script_file_arg)]
script_dir <- if (length(script_file_arg) == 0) getwd() else dirname(normalizePath(sub("^--file=", "", script_file_arg[[1]])))
source(file.path(script_dir, "big_picture_lib.R"))

paths <- get_project_paths()
ensure_dirs(paths)

episode_manifest_path <- file.path(paths$exploration_output, "episode_manifest.csv")
if (!file.exists(episode_manifest_path)) {
  build_episode_manifest(paths)
}
episode_manifest <- read_csv(episode_manifest_path, show_col_types = FALSE)

analysis_sample <- episode_manifest |>
  filter(episode_date >= as.Date("2023-01-01"))

bing <- get_sentiments("bing") |>
  distinct(word, .keep_all = TRUE) |>
  mutate(score = if_else(sentiment == "positive", 1, -1)) |>
  select(word, score)

summary_tokens <- analysis_sample |>
  transmute(slug, title, episode_date, episode_type, summary = coalesce(summary, "")) |>
  unnest_tokens(word, summary)

summary_sentiment <- summary_tokens |>
  left_join(bing, by = "word") |>
  group_by(slug, title, episode_date, episode_type) |>
  summarise(
    matched_words = sum(!is.na(score)),
    mean_sentiment_word = if_else(matched_words > 0, mean(score, na.rm = TRUE), 0),
    .groups = "drop"
  ) |>
  mutate(summary_sentiment = mean_sentiment_word, month = floor_date(episode_date, "month"))

transcript_manifest_path <- file.path(paths$exploration_output, "transcript_manifest.csv")
if (file.exists(transcript_manifest_path)) {
  transcript_manifest <- read_csv(transcript_manifest_path, show_col_types = FALSE)
} else {
  transcript_manifest <- tibble()
}

if (nrow(transcript_manifest) > 0) {
  if (!"fetch_status" %in% names(transcript_manifest)) {
    transcript_manifest <- transcript_manifest |> mutate(fetch_status = if_else(transcript_available, "ok", "unknown"))
  }
  if (!"page_title" %in% names(transcript_manifest)) {
    transcript_manifest <- transcript_manifest |> mutate(page_title = NA_character_)
  }
}

cached_manifest <- analysis_sample |>
  mutate(cache_path = cache_path_for(paths$cache_dir, paste0("transcript_", slug))) |>
  mutate(cache_exists = file.exists(cache_path))

if (nrow(transcript_manifest) > 0) {
  cached_manifest <- cached_manifest |>
    left_join(
      transcript_manifest |>
        select(slug, transcript_available, raw_segments, usable_segments, fetch_status, page_title),
      by = "slug"
    )
} else {
  cached_manifest <- cached_manifest |>
    mutate(
      transcript_available = cache_exists,
      raw_segments = NA_integer_,
      usable_segments = NA_integer_,
      fetch_status = if_else(cache_exists, "cached", "missing"),
      page_title = NA_character_
    )
}

transcript_rows <- vector("list", nrow(cached_manifest))
ok_index <- which(cached_manifest$cache_exists)

for (j in seq_along(ok_index)) {
  i <- ok_index[[j]]
  ep <- cached_manifest[i, ]
  html <- read_cached_html(paths$cache_dir, paste0("transcript_", ep$slug))
  if (is.null(html)) {
    transcript_rows[[i]] <- tibble()
    next
  }
  parsed <- tryCatch(parse_transcript_segments_from_html(html), error = function(e) NULL)
  if (is.null(parsed)) {
    transcript_rows[[i]] <- tibble()
    next
  }
  transcript_rows[[i]] <- parsed$segments |>
    mutate(
      slug = ep$slug,
      title = ep$title,
      episode_date = ep$episode_date,
      episode_type = ep$episode_type,
      lower_text = str_to_lower(text),
      is_ad = str_detect(text, ad_regex),
      is_industry = str_detect(text, industry_regex),
      has_positive_phrase = str_detect(text, positive_regex),
      has_negative_phrase = str_detect(text, negative_regex)
    ) |>
    filter(!is_ad)
}

transcript_segments <- bind_rows(transcript_rows)
write_csv(transcript_segments, file.path(paths$exploration_processed, "transcript_segments_derived.csv"))

rebuilt_transcript_manifest <- cached_manifest |>
  mutate(
    usable_segments_rebuilt = map_int(transcript_rows, nrow),
    transcript_available = if_else(cache_exists & usable_segments_rebuilt > 0, TRUE, coalesce(transcript_available, FALSE)),
    usable_segments = coalesce(usable_segments, usable_segments_rebuilt),
    raw_segments = coalesce(raw_segments, usable_segments_rebuilt),
    fetch_status = case_when(
      cache_exists & usable_segments_rebuilt > 0 ~ "ok_cached",
      cache_exists ~ coalesce(fetch_status, "cached_unparsed"),
      TRUE ~ coalesce(fetch_status, "missing")
    )
  ) |>
  select(
    slug, title, episode_date, episode_type, transcript_url,
    transcript_available, raw_segments, usable_segments, page_title,
    fetch_status, cache_path
  )
write_dual_csv(rebuilt_transcript_manifest, "transcript_manifest.csv", paths)

token_sentiment <- transcript_segments |>
  select(slug, segment_id, text, episode_date, episode_type, is_industry) |>
  unnest_tokens(word, text) |>
  left_join(bing, by = "word")

segment_sentiment <- token_sentiment |>
  group_by(slug, segment_id) |>
  summarise(
    matched_words = sum(!is.na(score)),
    bing = if_else(matched_words > 0, mean(score, na.rm = TRUE), 0),
    .groups = "drop"
  )

transcript_segments <- transcript_segments |>
  left_join(segment_sentiment, by = c("slug", "segment_id")) |>
  mutate(
    bing = replace_na(bing, 0),
    sentiment_combo = bing +
      if_else(has_positive_phrase, 0.8, 0) -
      if_else(has_negative_phrase, 0.8, 0),
    month = floor_date(episode_date, "month")
  )

episode_sentiment <- transcript_segments |>
  group_by(slug, title, episode_date, episode_type, month) |>
  summarise(
    overall_sentiment = mean(sentiment_combo, na.rm = TRUE),
    industry_sentiment = mean(sentiment_combo[is_industry], na.rm = TRUE),
    industry_share = mean(is_industry),
    positive_phrase_rate = mean(has_positive_phrase),
    negative_phrase_rate = mean(has_negative_phrase),
    segments = n(),
    .groups = "drop"
  ) |>
  mutate(
    industry_sentiment = if_else(is.nan(industry_sentiment), NA_real_, industry_sentiment),
    oscar_window = month(episode_date) %in% c(1, 2, 3)
  )

sentiment_ready <- episode_sentiment |> filter(!is.na(industry_sentiment))
if (nrow(sentiment_ready) >= 10) {
  sentiment_model <- tryCatch(
    lm(
    industry_sentiment ~ as.numeric(episode_date) + industry_share + positive_phrase_rate +
      negative_phrase_rate + factor(episode_type) + oscar_window,
    data = sentiment_ready
    ),
    error = function(e) NULL
  )
  if (is.null(sentiment_model)) {
    sentiment_tab <- tibble(note = "Sentiment regression not estimable for the current cached sample.")
  } else {
    sentiment_tab <- broom::tidy(sentiment_model) |>
      mutate(across(where(is.numeric), ~ round(.x, 4)))
  }
} else {
  sentiment_tab <- tibble(note = "Insufficient cached transcript episodes for sentiment regression.")
}
write_dual_csv(sentiment_tab, "tab_sentiment_model.csv", paths)

monthly_sentiment <- episode_sentiment |>
  group_by(month) |>
  summarise(
    transcript_overall_sentiment = mean(overall_sentiment, na.rm = TRUE),
    industry_sentiment = mean(industry_sentiment, na.rm = TRUE),
    transcript_episodes = n(),
    .groups = "drop"
  ) |>
  full_join(
    summary_sentiment |>
      group_by(month) |>
      summarise(
        summary_sentiment = mean(summary_sentiment, na.rm = TRUE),
        summary_episodes = n(),
        .groups = "drop"
      ),
    by = "month"
  )

p_sentiment <- ggplot(monthly_sentiment, aes(month)) +
  geom_line(aes(y = summary_sentiment, color = "Episode summaries"), linewidth = 0.9) +
  geom_line(aes(y = industry_sentiment, color = "Industry talk"), linewidth = 0.9, linetype = "dashed") +
  geom_smooth(aes(y = summary_sentiment), method = "loess", se = FALSE, color = "#1b4965", linewidth = 1.1) +
  geom_smooth(aes(y = industry_sentiment), method = "loess", se = FALSE, color = "#c1121f", linewidth = 1.1) +
  scale_color_manual(values = c("Episode summaries" = "#1b4965", "Industry talk" = "#c1121f")) +
  scale_x_date(date_breaks = "6 months", date_labels = "%Y-%m") +
  labs(
    title = "The Big Picture stays movie-positive even when industry-heavy episodes sound less upbeat",
    subtitle = "Monthly averages from summary sentiment and cached transcript segments",
    x = NULL,
    y = "Average sentiment score",
    color = NULL,
    caption = "Solid line: monthly mean summary sentiment. Dashed line: monthly mean sentiment among transcript segments flagged as industry talk. Smoothed overlays use loess fits."
  ) +
  theme_minimal(base_size = 12) +
  theme(legend.position = "top", axis.text.x = element_text(angle = 45, hjust = 1))
save_dual_plot(p_sentiment, "fig_sentiment_timeseries.png", paths, width = 12, height = 7)

candidate_pool <- extract_seed_titles_from_episode_titles(episode_manifest$title)

candidate_pool <- tibble(movie = candidate_pool) |>
  mutate(
    movie = clean_candidate_titles(movie),
    movie_lower = str_to_lower(movie),
    token_count = str_count(movie, "\\S+")
  ) |>
  filter(
    token_count >= 2 | movie %in% unique(oscar_lookup$contender),
    !str_detect(movie, non_movie_candidate_regex),
    !str_detect(movie_lower, "^(our|the|and)\\s+(top|favorite|best)\\b"),
    !str_detect(movie_lower, "\\b(rankings|nominations|mailbag|conversation|committee|closet|channel|prime)\\b"),
    !movie_lower %in% c("the big picture", "movie draft", "academy awards", "movie star rankings", "mailbag",
                        "best picture", "best director", "best actor", "best actress", "blank check")
  ) |>
  distinct(movie_lower, .keep_all = TRUE)

candidate_pool <- tibble(movie = prune_nested_candidates(candidate_pool$movie)) |>
  mutate(
    movie_lower = str_to_lower(movie),
    token_count = str_count(movie, "\\S+")
  ) |>
  distinct(movie_lower, .keep_all = TRUE)

movie_mentions <- map_dfr(seq_len(nrow(candidate_pool)), function(i) {
  title_i <- candidate_pool$movie[i]
  patt <- regex(paste0("(^|[^a-z0-9])", str_replace_all(str_to_lower(title_i), "([\\W])", "\\\\\\1"), "([^a-z0-9]|$)"))
  hits <- transcript_segments |> filter(str_detect(lower_text, patt))
  if (nrow(hits) == 0) return(tibble())
  hits |>
    transmute(
      movie = title_i, slug, episode_date, episode_type, segment_id,
      sentiment_combo, has_positive_phrase, has_negative_phrase, is_industry
    )
})
write_dual_csv(movie_mentions, "movie_mentions.csv", paths)

movie_scores <- movie_mentions |>
  group_by(movie) |>
  summarise(
    n_episodes = n_distinct(slug),
    total_mentions = n(),
    mean_sentiment = mean(sentiment_combo, na.rm = TRUE),
    positive_rate = mean(has_positive_phrase),
    negative_rate = mean(has_negative_phrase),
    oscar_share = mean(episode_type == "oscar"),
    canon_share = mean(episode_type %in% c("draft", "ranking", "retrospective")),
    interview_share = mean(episode_type == "interview"),
    industry_share = mean(is_industry),
    franchise_flag = as.integer(any(str_detect(
      str_to_lower(movie),
      "part|chapter|ii|iii|iv|mission impossible|marvel|dc |spider-man|batman|superman|dune|wicked"
    ))),
    .groups = "drop"
  ) |>
  filter(n_episodes >= 2 | total_mentions >= 4) |>
  mutate(
    evidence_weight = pmin(1, log1p(total_mentions) / log(10)),
    raw_preference = mean_sentiment + 0.5 * positive_rate - 0.6 * negative_rate,
    preference_score = raw_preference * evidence_weight
  ) |>
  filter(!str_detect(
    str_to_lower(movie),
    "best picture|best director|best actor|best actress|power rankings|academy|oscar|critics|film critics|all time|best movie|best movies|good neighbor|the oscar|performances|director$|movie star|awards?$|mailbag|committee|nominations|rankings|conversation"
  )) |>
  filter(!str_detect(movie, non_movie_candidate_regex)) |>
  distinct(movie, .keep_all = TRUE) |>
  arrange(desc(preference_score))
write_dual_csv(movie_scores, "movie_scores.csv", paths)

if (nrow(movie_scores) >= 3) {
  movie_feature_matrix <- movie_scores |>
    select(movie, preference_score, total_mentions, oscar_share, canon_share, interview_share, industry_share, franchise_flag) |>
    mutate(total_mentions = log1p(total_mentions))
  pc <- prcomp(movie_feature_matrix |> select(-movie), scale. = TRUE)
  movie_plot_df <- bind_cols(movie_feature_matrix, as_tibble(pc$x[, 1:2]) |> rename(pc1 = PC1, pc2 = PC2)) |>
    mutate(label_me = rank(-abs(preference_score), ties.method = "first") <= 12)
  p_movies <- ggplot(movie_plot_df, aes(pc1, pc2, color = preference_score, size = total_mentions)) +
    geom_point(alpha = 0.8) +
    ggrepel::geom_text_repel(data = subset(movie_plot_df, label_me), aes(label = movie), size = 3, max.overlaps = 25) +
    scale_color_gradient2(low = "#b22222", mid = "#f7f7f7", high = "#1b7837", midpoint = 0) +
    labs(
      title = "Precision-first movie titles cluster by repeated praise, canon context, and franchise distance",
      subtitle = "Principal components of transcript-derived features for conservative headline-title candidates",
      x = "Preference dimension 1", y = "Preference dimension 2", color = "Preference", size = "Log mentions"
    ) +
    theme_minimal(base_size = 12)
  save_dual_plot(p_movies, "fig_movie_preference_clusters.png", paths, width = 12, height = 8)
  top_cut <- quantile(movie_scores$preference_score, 0.75, na.rm = TRUE)
  bottom_cut <- quantile(movie_scores$preference_score, 0.25, na.rm = TRUE)
  liked_tbl <- movie_scores |>
    filter(preference_score >= top_cut) |>
    summarise(across(c(total_mentions, oscar_share, canon_share, interview_share, industry_share, franchise_flag), \(x) mean(x, na.rm = TRUE))) |>
    pivot_longer(everything(), names_to = "feature", values_to = "liked_mean")
  disliked_tbl <- movie_scores |>
    filter(preference_score <= bottom_cut) |>
    summarise(across(c(total_mentions, oscar_share, canon_share, interview_share, industry_share, franchise_flag), \(x) mean(x, na.rm = TRUE))) |>
    pivot_longer(everything(), names_to = "feature", values_to = "disliked_mean")
  movie_commonalities <- full_join(liked_tbl, disliked_tbl, by = "feature") |>
    mutate(gap = liked_mean - disliked_mean) |>
    arrange(desc(abs(gap)))
} else {
  movie_commonalities <- tibble(note = "Insufficient cached movie sample for commonality table.")
}
write_dual_csv(movie_commonalities, "tab_movie_commonalities.csv", paths)

assign_oscar_season <- function(date) if_else(month(date) <= 3, year(date), year(date) + 1)
oscar_episodes <- episode_manifest |>
  filter(episode_date >= as.Date("2022-09-01")) |>
  mutate(oscar_season = assign_oscar_season(episode_date)) |>
  filter(oscar_season %in% unique(oscar_lookup$season), episode_type == "oscar")
oscar_segment_base <- transcript_segments |> semi_join(oscar_episodes, by = "slug")

evidence_patterns <- list(
  guild = "sag|pga|dga|wga|guild|bafta",
  festival = "venice|cannes|tiff|telluride|festival",
  box_office = "box office|gross|ticket sales|theaters",
  campaign = "campaign|campaigning|push|studio support",
  narrative = "narrative|momentum|frontrunner|heat|buzz",
  priors = "academy|voters|they like|they love|the academy goes for",
  release_timing = "release date|released|late breaker|december|summer release",
  star_power = "movie star|star power|director|filmmaker|cast|performance"
)

oscar_predictions <- map_dfr(seq_len(nrow(oscar_episodes)), function(i) {
  ep <- oscar_episodes[i, ]
  segs <- oscar_segment_base |> filter(slug == ep$slug)
  if (nrow(segs) == 0) return(tibble())
  full_text <- paste(segs$lower_text, collapse = " ")
  contenders <- oscar_lookup |> filter(season == ep$oscar_season)
  map_dfr(seq_len(nrow(contenders)), function(j) {
    contender <- contenders$contender[j]
    contender_lower <- str_to_lower(contender)
    mention_segments <- segs |> filter(str_detect(lower_text, fixed(contender_lower)))
    explicit_hits <- sum(str_detect(mention_segments$lower_text, "will win|going to win|my pick|pick is|wins best picture|front.?runner"))
    lean_hits <- sum(str_detect(mention_segments$lower_text, "could win|might win|should win|has a chance|seems likely"))
    mention_count <- nrow(mention_segments)
    score <- explicit_hits * 2 + lean_hits + mention_count * 0.15
    tibble(
      slug = ep$slug, title = ep$title, episode_date = ep$episode_date, oscar_season = ep$oscar_season,
      contender = contender, winner = contenders$winner[j], mention_count = mention_count,
      explicit_hits = explicit_hits, lean_hits = lean_hits, score = score,
      guild_mentions = str_count(full_text, evidence_patterns$guild),
      festival_mentions = str_count(full_text, evidence_patterns$festival),
      box_office_mentions = str_count(full_text, evidence_patterns$box_office),
      campaign_mentions = str_count(full_text, evidence_patterns$campaign),
      narrative_mentions = str_count(full_text, evidence_patterns$narrative),
      priors_mentions = str_count(full_text, evidence_patterns$priors),
      release_timing_mentions = str_count(full_text, evidence_patterns$release_timing),
      star_power_mentions = str_count(full_text, evidence_patterns$star_power)
    )
  })
})

if (nrow(oscar_predictions) > 0) {
  oscar_predictions <- oscar_predictions |>
    arrange(slug, desc(score), desc(explicit_hits), desc(mention_count), contender) |>
    group_by(slug) |>
    mutate(predicted = row_number() == 1 & score > 0) |>
    ungroup()
  write_dual_csv(oscar_predictions, "oscar_predictions.csv", paths)
  oscar_eval <- oscar_predictions |>
    filter(predicted) |>
    mutate(
      ceremony_date = oscar_lookup$ceremony_date[match(paste(oscar_season, winner), paste(oscar_lookup$season, oscar_lookup$winner))],
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
  write_dual_csv(oscar_eval, "oscar_prediction_evaluation.csv", paths)
  if (nrow(oscar_eval) >= 5 && length(unique(oscar_eval$correct)) > 1) {
    x_mat <- model.matrix(correct ~ days_before_ceremony + guild_mentions + festival_mentions + box_office_mentions + campaign_mentions + narrative_mentions + priors_mentions + release_timing_mentions + star_power_mentions, data = oscar_eval)[, -1]
    y_vec <- as.integer(oscar_eval$correct)
    cv_fit <- cv.glmnet(x_mat, y_vec, family = "binomial", alpha = 1, standardize = TRUE)
    coef_tbl <- as.matrix(coef(cv_fit, s = "lambda.1se")) |>
      as.data.frame() |>
      rownames_to_column("term") |>
      rename(weight = `1`) |>
      filter(term != "(Intercept)") |>
      arrange(desc(abs(weight)))
  } else {
    coef_tbl <- tibble(note = "Insufficient cached Oscar sample for penalized evidence model.")
  }
  write_dual_csv(coef_tbl, "tab_oscar_evidence_weights.csv", paths)
  oscar_fig_df <- oscar_eval |>
    group_by(horizon_bucket) |>
    summarise(accuracy = mean(correct), revisions = sum(revision, na.rm = TRUE), episodes = n(), .groups = "drop") |>
    mutate(horizon_bucket = factor(horizon_bucket, levels = c("Early season", "Post-noms / precursor stretch", "Final month")))
  p_oscar <- ggplot(oscar_fig_df, aes(horizon_bucket, accuracy)) +
    geom_col(fill = "#264653", width = 0.65) +
    geom_text(aes(label = percent(accuracy, accuracy = 1)), vjust = -0.4, size = 4) +
    geom_point(aes(y = revisions / max(revisions) * max(accuracy), size = revisions), color = "#e76f51") +
    scale_y_continuous(labels = percent_format(accuracy = 1), limits = c(0, 1)) +
    labs(
      title = "Best Picture predictions get stickier and more accurate near Oscar night",
      subtitle = "Episode-level inferred picks from cached Oscar-focused transcript pages",
      x = NULL, y = "Prediction accuracy", size = "Revision count"
    ) +
    theme_minimal(base_size = 12)
  save_dual_plot(p_oscar, "fig_oscar_prediction_accuracy.png", paths, width = 10, height = 7)
} else {
  write_dual_csv(tibble(note = "No cached Oscar prediction sample yet."), "oscar_predictions.csv", paths)
  write_dual_csv(tibble(note = "No cached Oscar evaluation sample yet."), "oscar_prediction_evaluation.csv", paths)
  write_dual_csv(tibble(note = "No cached Oscar evidence-weight sample yet."), "tab_oscar_evidence_weights.csv", paths)
  p_oscar_placeholder <- ggplot() +
    annotate("text", x = 0.5, y = 0.6, label = "Oscar accuracy plot pending", size = 8, fontface = "bold") +
    annotate("text", x = 0.5, y = 0.4, label = "Current transcript cache does not yet contain enough completed-season Oscar episodes.", size = 4.5) +
    xlim(0, 1) + ylim(0, 1) +
    theme_void()
  save_dual_plot(p_oscar_placeholder, "fig_oscar_prediction_accuracy.png", paths, width = 10, height = 6)
}

results_memo <- c(
  "# Results memo",
  "",
  sprintf("- Episode manifest coverage: %s episodes from %s through %s.", nrow(episode_manifest), min(episode_manifest$episode_date), max(episode_manifest$episode_date)),
  sprintf("- Summary-level analysis sample: %s episodes from %s through %s.", nrow(analysis_sample), min(analysis_sample$episode_date), max(analysis_sample$episode_date)),
  sprintf("- Cached transcript pages available: %s of %s target episodes.", sum(cached_manifest$cache_exists), nrow(cached_manifest)),
  sprintf("- Usable cached transcript segments: %s.", nrow(transcript_segments)),
  sprintf("- Movie preference sample currently scored: %s movies.", nrow(movie_scores))
)
write_dual_text(results_memo, "results_memo.md", paths)

run_summary <- tibble(
  metric = c("episodes_total", "episodes_summary_sample", "episodes_cached_transcript_sample", "usable_transcript_segments", "movies_scored"),
  value = c(nrow(episode_manifest), nrow(analysis_sample), sum(cached_manifest$cache_exists), nrow(transcript_segments), nrow(movie_scores))
)
write_csv(run_summary, file.path(paths$exploration_processed, "run_summary.csv"))
write_csv(run_summary, file.path(paths$replication_output, "run_summary.csv"))
