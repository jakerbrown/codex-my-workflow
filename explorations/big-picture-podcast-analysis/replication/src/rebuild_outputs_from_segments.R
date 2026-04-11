#!/usr/bin/env Rscript

script_file_arg <- commandArgs(trailingOnly = FALSE)
script_file_arg <- script_file_arg[grepl("^--file=", script_file_arg)]
script_dir <- if (length(script_file_arg) == 0) getwd() else dirname(normalizePath(sub("^--file=", "", script_file_arg[[1]])))
source(file.path(script_dir, "big_picture_lib.R"))

paths <- get_project_paths()
ensure_dirs(paths)

episode_manifest <- read_csv(file.path(paths$exploration_output, "episode_manifest.csv"), show_col_types = FALSE)
analysis_sample <- episode_manifest |>
  filter(episode_date >= as.Date("2023-01-01")) |>
  mutate(cache_path = cache_path_for(paths$cache_dir, paste0("transcript_", slug)))

segments <- read_csv(file.path(paths$exploration_processed, "transcript_segments_derived.csv"), show_col_types = FALSE)
segment_counts <- segments |>
  group_by(slug) |>
  summarise(usable_segments = n(), .groups = "drop")

existing_manifest_path <- file.path(paths$exploration_output, "transcript_manifest.csv")
existing_manifest <- if (file.exists(existing_manifest_path)) {
  read_csv(existing_manifest_path, show_col_types = FALSE)
} else {
  tibble()
}

if (nrow(existing_manifest) > 0 && "fetch_status" %in% names(existing_manifest)) {
  existing_manifest <- existing_manifest |>
    mutate(
      fetch_status = if_else(
        str_detect(coalesce(fetch_status, ""), "does not exist in current working directory"),
        "cached_unparsed",
        fetch_status
      )
    )
}

rebuilt_manifest <- analysis_sample |>
  left_join(segment_counts, by = "slug") |>
  left_join(existing_manifest |>
              select(slug, raw_segments, page_title, fetch_status) |>
              distinct(slug, .keep_all = TRUE),
            by = "slug") |>
  mutate(
    transcript_available = coalesce(usable_segments, 0) > 0 | file.exists(cache_path),
    fetch_status = case_when(
      coalesce(usable_segments, 0) > 0 ~ "ok_cached",
      file.exists(cache_path) ~ coalesce(fetch_status, "cached_unparsed"),
      TRUE ~ "missing"
    )
  ) |>
  select(
    slug, title, episode_date, episode_type, transcript_url,
    transcript_available, raw_segments, usable_segments, page_title,
    fetch_status, cache_path
  ) |>
  arrange(desc(episode_date))
write_dual_csv(rebuilt_manifest, "transcript_manifest.csv", paths)

candidate_pool <- tibble(movie = extract_seed_titles_from_episode_titles(episode_manifest$title)) |>
  mutate(
    movie = clean_candidate_titles(movie),
    movie_lower = str_to_lower(movie)
  ) |>
  filter(!str_detect(movie, non_movie_candidate_regex)) |>
  distinct(movie_lower, .keep_all = TRUE)

movie_mentions <- map_dfr(seq_len(nrow(candidate_pool)), function(i) {
  title_i <- candidate_pool$movie[i]
  patt <- regex(paste0("(^|[^a-z0-9])", str_replace_all(str_to_lower(title_i), "([\\W])", "\\\\\\1"), "([^a-z0-9]|$)"))
  hits <- segments |> filter(str_detect(lower_text, patt))
  if (nrow(hits) == 0) return(tibble())
  hits |>
    transmute(
      movie = title_i, slug, episode_date, episode_type, segment_id, text,
      has_positive_phrase, has_negative_phrase, is_industry
    )
})

bing <- get_sentiments("bing") |>
  distinct(word, .keep_all = TRUE) |>
  mutate(score = if_else(sentiment == "positive", 1, -1)) |>
  select(word, score)

movie_segment_sentiment <- movie_mentions |>
  select(movie, slug, segment_id, text) |>
  unnest_tokens(word, text) |>
  left_join(bing, by = "word") |>
  group_by(movie, slug, segment_id) |>
  summarise(
    matched_words = sum(!is.na(score)),
    bing = if_else(matched_words > 0, mean(score, na.rm = TRUE), 0),
    .groups = "drop"
  )

movie_mentions <- movie_mentions |>
  left_join(movie_segment_sentiment, by = c("movie", "slug", "segment_id")) |>
  mutate(
    bing = replace_na(bing, 0),
    sentiment_combo = bing +
      if_else(has_positive_phrase, 0.8, 0) -
      if_else(has_negative_phrase, 0.8, 0)
  )
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
      title = "Seeded movie titles cluster by repeated praise, canon context, and franchise distance",
      subtitle = "Current large transcript cache, conservative title list",
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
  movie_commonalities <- tibble(note = "Insufficient seeded-title movie sample for commonality table.")
}

write_dual_csv(movie_commonalities, "tab_movie_commonalities.csv", paths)

results_memo <- c(
  "# Results memo",
  "",
  sprintf("- Episode manifest coverage: %s episodes from %s through %s.", nrow(episode_manifest), min(episode_manifest$episode_date), max(episode_manifest$episode_date)),
  sprintf("- Summary-level analysis sample: %s episodes from %s through %s.", nrow(analysis_sample), min(analysis_sample$episode_date), max(analysis_sample$episode_date)),
  sprintf("- Cached transcript pages available: %s of %s target episodes.", sum(rebuilt_manifest$transcript_available, na.rm = TRUE), nrow(rebuilt_manifest)),
  sprintf("- Usable cached transcript segments: %s.", nrow(segments)),
  sprintf("- Seeded-title movie preference sample currently scored: %s movies.", nrow(movie_scores))
)
write_dual_text(results_memo, "results_memo.md", paths)

run_summary <- tibble(
  metric = c("episodes_total", "episodes_summary_sample", "episodes_cached_transcript_sample", "usable_transcript_segments", "movies_scored"),
  value = c(
    nrow(episode_manifest),
    nrow(analysis_sample),
    sum(rebuilt_manifest$transcript_available, na.rm = TRUE),
    nrow(segments),
    nrow(movie_scores)
  )
)
write_csv(run_summary, file.path(paths$exploration_processed, "run_summary.csv"))
write_csv(run_summary, file.path(paths$replication_output, "run_summary.csv"))
