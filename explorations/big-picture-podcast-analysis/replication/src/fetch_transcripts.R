#!/usr/bin/env Rscript

script_file_arg <- commandArgs(trailingOnly = FALSE)
script_file_arg <- script_file_arg[grepl("^--file=", script_file_arg)]
script_dir <- if (length(script_file_arg) == 0) getwd() else dirname(normalizePath(sub("^--file=", "", script_file_arg[[1]])))
source(file.path(script_dir, "big_picture_lib.R"))

paths <- get_project_paths()
ensure_dirs(paths)

episode_manifest_path <- file.path(paths$exploration_output, "episode_manifest.csv")
episode_manifest <- if (file.exists(episode_manifest_path)) {
  read_csv(episode_manifest_path, show_col_types = FALSE)
} else {
  build_episode_manifest(paths)
}

analysis_sample <- episode_manifest |>
  filter(episode_date >= as.Date("2023-01-01"))

manifest_path <- file.path(paths$exploration_output, "transcript_manifest.csv")
progress_manifest_path <- file.path(paths$exploration_output, "transcript_manifest_progress.csv")
existing_manifest <- if (file.exists(manifest_path)) {
  read_csv(manifest_path, show_col_types = FALSE)
} else {
  tibble()
}

rows <- vector("list", nrow(analysis_sample))

for (i in seq_len(nrow(analysis_sample))) {
  ep <- analysis_sample[i, ]
  cache_file <- cache_path_for(paths$cache_dir, paste0("transcript_", ep$slug))
  if (nrow(existing_manifest) > 0 && ep$slug %in% existing_manifest$slug && file.exists(cache_file)) {
    rows[[i]] <- existing_manifest |> filter(slug == ep$slug) |> slice(1)
    next
  }
  parsed <- tryCatch(
    parse_transcript_segments(ep$transcript_url, ep$slug, cache_dir = paths$cache_dir, use_cache = TRUE),
    error = function(e) list(error = conditionMessage(e))
  )
  if (!is.null(parsed$error)) {
    rows[[i]] <- tibble(
      slug = ep$slug,
      title = ep$title,
      episode_date = ep$episode_date,
      episode_type = ep$episode_type,
      transcript_url = ep$transcript_url,
      transcript_available = FALSE,
      raw_segments = NA_integer_,
      usable_segments = NA_integer_,
      page_title = NA_character_,
      fetch_status = parsed$error,
      cache_path = cache_file
    )
  } else {
    usable_segments <- parsed$segments |>
      mutate(is_ad = str_detect(text, ad_regex)) |>
      filter(!is_ad)
    rows[[i]] <- tibble(
      slug = ep$slug,
      title = ep$title,
      episode_date = ep$episode_date,
      episode_type = ep$episode_type,
      transcript_url = ep$transcript_url,
      transcript_available = nrow(parsed$segments) > 0,
      raw_segments = nrow(parsed$segments),
      usable_segments = nrow(usable_segments),
      page_title = parsed$page_title,
      fetch_status = "ok",
      cache_path = cache_file
    )
  }
  if (i %% 10 == 0 || i == nrow(analysis_sample)) {
    interim <- bind_rows(rows[!vapply(rows, is.null, logical(1))]) |>
      arrange(desc(episode_date))
    write_csv(interim, progress_manifest_path)
    write_csv(interim, file.path(paths$replication_output, "transcript_manifest_progress.csv"))
  }
}

transcript_manifest <- bind_rows(rows) |>
  arrange(desc(episode_date))

write_dual_csv(transcript_manifest, "transcript_manifest.csv", paths)

summary_text <- c(
  "# Transcript Fetch Summary",
  "",
  sprintf("- Analysis target episodes: %s", nrow(analysis_sample)),
  sprintf("- Cached transcript successes: %s", sum(transcript_manifest$transcript_available, na.rm = TRUE)),
  sprintf("- Failed or missing transcript pulls: %s", sum(!transcript_manifest$transcript_available, na.rm = TRUE)),
  sprintf("- Cache directory: `%s`", paths$cache_dir)
)

write_dual_text(summary_text, "transcript_fetch_summary.md", paths)
