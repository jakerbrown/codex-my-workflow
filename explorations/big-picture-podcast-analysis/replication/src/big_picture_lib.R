suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(stringr)
  library(purrr)
  library(tidyr)
  library(tibble)
  library(lubridate)
  library(rvest)
  library(xml2)
  library(tidytext)
  library(ggplot2)
  library(forcats)
  library(scales)
  library(ggrepel)
  library(glmnet)
  library(broom)
})

`%||%` <- function(x, y) if (is.null(x) || length(x) == 0 || all(is.na(x))) y else x

get_script_path <- function() {
  file_arg <- commandArgs(trailingOnly = FALSE)
  file_arg <- file_arg[grepl("^--file=", file_arg)]
  if (length(file_arg) == 0) {
    return(file.path(getwd(), "interactive_session.R"))
  }
  normalizePath(sub("^--file=", "", file_arg[[1]]))
}

get_project_paths <- function() {
  script_path <- get_script_path()
  replication_root <- normalizePath(file.path(dirname(script_path), ".."))
  exploration_root <- normalizePath(file.path(replication_root, ".."))
  cache_dir <- if (dir.exists("/Volumes/Jake EH")) {
    file.path("/Volumes/Jake EH", "big_picture_podcast_analysis_cache")
  } else {
    file.path(replication_root, "data", "raw", "cache")
  }
  list(
    script_path = script_path,
    replication_root = replication_root,
    exploration_root = exploration_root,
    replication_data_raw = file.path(replication_root, "data", "raw"),
    replication_output = file.path(replication_root, "output"),
    exploration_output = file.path(exploration_root, "output"),
    exploration_processed = file.path(exploration_root, "data", "processed"),
    cache_dir = cache_dir
  )
}

ensure_dirs <- function(paths) {
  dir.create(paths$replication_data_raw, recursive = TRUE, showWarnings = FALSE)
  dir.create(paths$replication_output, recursive = TRUE, showWarnings = FALSE)
  dir.create(paths$exploration_output, recursive = TRUE, showWarnings = FALSE)
  dir.create(paths$exploration_processed, recursive = TRUE, showWarnings = FALSE)
  dir.create(paths$cache_dir, recursive = TRUE, showWarnings = FALSE)
}

write_dual_csv <- function(df, name, paths) {
  write_csv(df, file.path(paths$exploration_output, name))
  write_csv(df, file.path(paths$replication_output, name))
}

save_dual_plot <- function(plot_obj, name, paths, width = 11, height = 7, dpi = 300) {
  ggsave(file.path(paths$exploration_output, name), plot = plot_obj, width = width, height = height, dpi = dpi)
  ggsave(file.path(paths$replication_output, name), plot = plot_obj, width = width, height = height, dpi = dpi)
}

write_dual_text <- function(text, name, paths) {
  writeLines(text, file.path(paths$exploration_output, name))
  writeLines(text, file.path(paths$replication_output, name))
}

cache_path_for <- function(cache_dir, cache_key) {
  file.path(cache_dir, paste0(cache_key, ".html"))
}

curl_read <- function(url, cache_dir, cache_key = NULL, pause = 1.1, tries = 4, use_cache = TRUE) {
  cache_path <- if (!is.null(cache_key)) cache_path_for(cache_dir, cache_key) else NULL
  if (use_cache && !is.null(cache_path) && file.exists(cache_path)) {
    return(paste(readLines(cache_path, warn = FALSE), collapse = "\n"))
  }
  attempt <- 1
  while (attempt <= tries) {
    if (pause > 0) Sys.sleep(pause)
    out <- system2(
      "curl",
      c("-f", "-L", "--silent", "--show-error", "--max-time", "30", "-A", "CodexResearchBot/1.0", url),
      stdout = TRUE,
      stderr = FALSE
    )
    status <- attr(out, "status") %||% 0
    text <- paste(out, collapse = "\n")
    if (status == 0 &&
        nzchar(text) &&
        str_detect(text, "<html") &&
        !str_detect(text, "429 - Too Many Requests|<title>404|<title>500")) {
      if (!is.null(cache_path)) writeLines(text, cache_path)
      return(text)
    }
    Sys.sleep(8 * attempt)
    attempt <- attempt + 1
  }
  stop(sprintf("Failed to retrieve %s after rate-limit retries.", url))
}

read_cached_html <- function(cache_dir, cache_key) {
  path <- cache_path_for(cache_dir, cache_key)
  if (!file.exists(path)) {
    return(NULL)
  }
  paste(readLines(path, warn = FALSE), collapse = "\n")
}

parse_listing_page <- function(page_num, cache_dir) {
  url <- if (page_num == 1) {
    "https://podscripts.co/podcasts/the-big-picture/"
  } else {
    sprintf("https://podscripts.co/podcasts/the-big-picture/?page=%s", page_num)
  }
  html <- curl_read(url, cache_dir = cache_dir, cache_key = sprintf("listing_page_%02d", page_num), pause = 0)
  doc <- read_html(html)
  articles <- html_elements(doc, "article")
  if (length(articles) == 0) {
    return(tibble())
  }
  map_dfr(seq_along(articles), function(i) {
    article <- articles[[i]]
    hrefs <- html_elements(article, "a") |> html_attr("href")
    href <- hrefs[grepl("^/podcasts/the-big-picture/", hrefs)][1] %||% NA_character_
    tibble(
      page = page_num,
      row_on_page = i,
      title = html_text2(html_element(article, "h3")) %||% NA_character_,
      episode_date = html_text2(html_element(article, ".episode_date")) %||% NA_character_,
      summary = html_text2(html_element(article, "p")) %||% NA_character_,
      transcript_url = ifelse(is.na(href), NA_character_, paste0("https://podscripts.co", href))
    )
  })
}

discover_page_count <- function(cache_dir) {
  html <- curl_read(
    "https://podscripts.co/podcasts/the-big-picture/",
    cache_dir = cache_dir,
    cache_key = "listing_page_01",
    pause = 0
  )
  nums <- str_extract_all(html, "page=[0-9]+")[[1]] |>
    str_remove("page=") |>
    as.integer()
  max(nums, na.rm = TRUE)
}

clean_listing_manifest <- function(df) {
  df |>
    mutate(
      episode_date = str_remove(episode_date, "^Episode Date:\\s*"),
      episode_date = suppressWarnings(mdy(episode_date)),
      slug = transcript_url |>
        str_remove("^https://podscripts.co/podcasts/the-big-picture/") |>
        str_remove("/$")
    ) |>
    distinct(slug, .keep_all = TRUE) |>
    arrange(desc(episode_date))
}

classify_episode_type <- function(title, summary) {
  x <- str_to_lower(paste(title, summary))
  case_when(
    str_detect(x, "oscar|academy awards|best picture power rankings|noms|nomination|awards season|big picks") ~ "oscar",
    str_detect(x, "draft") ~ "draft",
    str_detect(x, "mailbag|ask us anything|advice hour") ~ "mailbag",
    str_detect(x, "ranking|top 10|top five|top 5|hall of fame|best movies of the year|movie star rankings") ~ "ranking",
    str_detect(x, "conversation|interview|with ") & !str_detect(x, "plus") ~ "interview",
    str_detect(x, "year so far|year-end|year end|best of the year|garbage") ~ "retrospective",
    TRUE ~ "standard"
  )
}

parse_transcript_segments_from_html <- function(html) {
  doc <- read_html(html)
  groups <- html_elements(doc, ".single-sentence")
  segments <- map_dfr(seq_along(groups), function(i) {
    group <- groups[[i]]
    seg_text <- html_elements(group, ".transcript-text") |> html_text2()
    if (length(seg_text) == 0) seg_text <- ""
    data.frame(
      segment_id = i,
      timestamp = as.character(html_text2(html_element(group, ".pod_timestamp_indicator")) %||% NA_character_),
      text = as.character(str_squish(paste(seg_text, collapse = " "))),
      stringsAsFactors = FALSE
    )
  }) |>
    as_tibble() |>
    filter(text != "")
  list(
    episode_date = html_text2(html_element(doc, ".episode_date")) |> str_remove("^Episode Date:\\s*") |> mdy(),
    page_title = html_text2(html_element(doc, "h1")) %||% NA_character_,
    page_summary = html_text2(html_element(doc, "p")) %||% NA_character_,
    segments = segments
  )
}

parse_transcript_segments <- function(url, slug, cache_dir, use_cache = TRUE) {
  html <- curl_read(url, cache_dir = cache_dir, cache_key = paste0("transcript_", slug), pause = 1.5, use_cache = use_cache)
  parse_transcript_segments_from_html(html)
}

ad_regex <- regex(paste(
  c(
    "learn more about your ad choices",
    "visit podcastchoices\\.com/adchoices",
    "this episode is brought to you by",
    "talk to a state farm agent",
    "drivers wanted",
    "at vw\\.com",
    "hulu on disney plus",
    "terms apply",
    "at participating",
    "sponsored by"
  ),
  collapse = "|"
), ignore_case = TRUE)

positive_regex <- regex(paste(
  c("love", "great", "excellent", "masterpiece", "favorite", "best", "amazing",
    "incredible", "wonderful", "fantastic", "special", "electric", "rules",
    "beautiful", "terrific", "awesome", "rewatchable"),
  collapse = "|"
), ignore_case = TRUE)

negative_regex <- regex(paste(
  c("hate", "bad", "terrible", "awful", "boring", "stinks", "mess", "disaster",
    "garbage", "worst", "mediocre", "dull", "misfire", "frustrating",
    "disappoint", "ugly"),
  collapse = "|"
), ignore_case = TRUE)

industry_regex <- regex(paste(
  c("movie business", "hollywood", "industry", "box office", "streaming",
    "theater", "theatre", "studios?", "franchise", "superhero", "marvel",
    "dc ", "release calendar", "budget", "adult drama", "\\bip\\b", "exhibition",
    "campaign", "academy", "oscars?", "guild", "festival", "awards season"),
  collapse = "|"
), ignore_case = TRUE)

extract_candidates <- function(text_vec) {
  quoted <- str_extract_all(text_vec, "[\"'‘’“”]([^\"'‘’“”]{2,80})[\"'‘’“”]") |>
    unlist() |>
    str_remove_all("^[\"'‘’“”]|[\"'‘’“”]$") |>
    str_squish()
  titlecase <- str_extract_all(
    text_vec,
    "(?<![A-Za-z0-9])(?:[A-Z][A-Za-z0-9'’:-]+(?:\\s+|$)){1,6}"
  ) |>
    unlist() |>
    str_squish()
  candidates <- unique(c(quoted, titlecase))
  stop_patterns <- c(
    "^The Big Picture$", "^Sean$", "^Amanda$", "^Chris Ryan$", "^Bill Simmons$",
    "^Hollywood$", "^Oscars?$", "^Academy Awards$", "^Mailbag$", "^Movie Draft$",
    "^The Steven Spielberg Conversation$", "^TV & Film$", "^Producers?$",
    "^Hosts?$", "^Production Support$", "^Top$", "^Best Movies$", "^The Best Movies$",
    "^Episode Date$", "^Plus$", "^Were$", "^The$", "^And$",
    "^Best Picture$", "^Best Director$", "^Best Actor$", "^Best Actress$",
    "^Blank Check$", "^Mission Accomplished$", "^The Oscars$", "^Golden Globes$",
    "^Oscar Contender$", "^TIFF$", "^SAG$", "^PGA$", "^DGA$", "^WGA$"
  )
  keep <- !Reduce(`|`, lapply(stop_patterns, function(p) str_detect(candidates, regex(p, ignore_case = TRUE))))
  candidates <- candidates[keep]
  candidates <- candidates[str_detect(candidates, "[A-Za-z]")]
  candidates <- candidates[nchar(candidates) >= 3]
  unique(candidates)
}

clean_candidate_titles <- function(candidates) {
  candidates |>
    str_replace_all("\\s+", " ") |>
    str_replace_all("^[\"'‘’“”]+|[\"'‘’“”]+$", "") |>
    str_replace_all("[,:;.!?]+$", "") |>
    str_replace_all("'s$", "") |>
    str_squish()
}

prune_nested_candidates <- function(candidates) {
  candidates <- unique(candidates[nzchar(candidates)])
  if (length(candidates) <= 1) {
    return(candidates)
  }
  lower_candidates <- str_to_lower(candidates)
  keep <- map_lgl(seq_along(candidates), function(i) {
    this <- lower_candidates[[i]]
    this_words <- str_count(this, "\\S+")
    !any(
      seq_along(candidates) != i &
        str_detect(lower_candidates, fixed(paste0(this, " "))) &
        str_count(lower_candidates, "\\S+") > this_words
    )
  })
  candidates[keep]
}

non_movie_candidate_regex <- regex(
  paste(
    c(
      "andy greenwald", "richard linklater", "david sims", "sean fennessey",
      "amanda dobbins", "chris ryan", "bill simmons", "barry jenkins",
      "sidney lumet", "ryan gosling", "harrison ford", "ridley scott",
      "eddie murphy", "joanna robinson", "tracy letts", "michael bay",
      "sydney sweeney", "jordan peele", "francis ford coppola", "ethan hawke",
      "jafar panahi", "griffin newman", "bobby wagner", "denis villeneuve",
      "wes anderson", "alex garland", "werner herzog", "guy ritchie",
      "paul thomas", "jack sanders", "criterion channel", "criterion closet",
      "amazon prime", "golden globe", "golden globe nominations", "movie history",
      "book club", "art house", "action star", "our top", "top five",
      "our favorite films", "and tv", "how does it", "the most exciting",
      "the electric", "year so", "year so far", "best horror movies",
      "good will", "the art", "the woman", "the wolf", "the hunt",
      "inner workings", "sinners is", "die my", "night shyamalan"
    ),
    collapse = "|"
  ),
  ignore_case = TRUE
)

extract_seed_titles_from_episode_titles <- function(title_vec) {
  title_vec <- coalesce(title_vec, "")
  direct_chunks <- str_match_all(
    title_vec,
    "(Everything Everywhere All at Once|All Quiet on the Western Front|Avatar: The Way of Water|The Banshees of Inisherin|Elvis|The Fabelmans|Tar|Top Gun: Maverick|Triangle of Sadness|Women Talking|Oppenheimer|American Fiction|Anatomy of a Fall|Barbie|The Holdovers|Killers of the Flower Moon|Maestro|Past Lives|Poor Things|The Zone of Interest|Anora|The Brutalist|A Complete Unknown|Conclave|Dune: Part Two|Emilia Perez|I'm Still Here|Nickel Boys|The Substance|Wicked|In the Mood for Love|Inglourious Basterds|Lady Bird|Mulholland Drive|Train Dreams|Project Hail Mary|Jay Kelly|Sinners|Scream|The Bride|Secret Agent|Hoppers|The Godfather Coda|Wonder Woman 1984|On the Rocks|The Lovebirds|Trolls World Tour|Uncut Gems|Little Women|Richard Jewell|The Irishman|Doctor Sleep|Marriage Story|Gemini Man|Downton Abbey|Ad Astra|The Goldfinch|Jojo Rabbit|Toy Story 4|Dark Phoenix|The Last Black Man in San Francisco|Wind River|Get Out|A Cure for Wellness|Hidden Figures|Citizen Kane|Spirited Away|Scott Pilgrim|The Master|Black Panther|Happy Gilmore)"
  ) |>
    map(\(x) x[, 2]) |>
    unlist()

  raw_titles <- c(direct_chunks, unique(oscar_lookup$contender))
  raw_titles |>
    clean_candidate_titles() |>
    str_split("\\s+and\\s+") |>
    unlist() |>
    str_squish() |>
    (\(x) x[nzchar(x)])() |>
    unique()
}

oscar_lookup <- tribble(
  ~season, ~ceremony_date, ~winner, ~contender,
  2023, as.Date("2023-03-12"), "Everything Everywhere All at Once", "Everything Everywhere All at Once",
  2023, as.Date("2023-03-12"), "Everything Everywhere All at Once", "All Quiet on the Western Front",
  2023, as.Date("2023-03-12"), "Everything Everywhere All at Once", "Avatar: The Way of Water",
  2023, as.Date("2023-03-12"), "Everything Everywhere All at Once", "The Banshees of Inisherin",
  2023, as.Date("2023-03-12"), "Everything Everywhere All at Once", "Elvis",
  2023, as.Date("2023-03-12"), "Everything Everywhere All at Once", "The Fabelmans",
  2023, as.Date("2023-03-12"), "Everything Everywhere All at Once", "Tar",
  2023, as.Date("2023-03-12"), "Everything Everywhere All at Once", "Top Gun: Maverick",
  2023, as.Date("2023-03-12"), "Everything Everywhere All at Once", "Triangle of Sadness",
  2023, as.Date("2023-03-12"), "Everything Everywhere All at Once", "Women Talking",
  2024, as.Date("2024-03-10"), "Oppenheimer", "Oppenheimer",
  2024, as.Date("2024-03-10"), "Oppenheimer", "American Fiction",
  2024, as.Date("2024-03-10"), "Oppenheimer", "Anatomy of a Fall",
  2024, as.Date("2024-03-10"), "Oppenheimer", "Barbie",
  2024, as.Date("2024-03-10"), "Oppenheimer", "The Holdovers",
  2024, as.Date("2024-03-10"), "Oppenheimer", "Killers of the Flower Moon",
  2024, as.Date("2024-03-10"), "Oppenheimer", "Maestro",
  2024, as.Date("2024-03-10"), "Oppenheimer", "Past Lives",
  2024, as.Date("2024-03-10"), "Oppenheimer", "Poor Things",
  2024, as.Date("2024-03-10"), "Oppenheimer", "The Zone of Interest",
  2025, as.Date("2025-03-02"), "Anora", "Anora",
  2025, as.Date("2025-03-02"), "Anora", "The Brutalist",
  2025, as.Date("2025-03-02"), "Anora", "A Complete Unknown",
  2025, as.Date("2025-03-02"), "Anora", "Conclave",
  2025, as.Date("2025-03-02"), "Anora", "Dune: Part Two",
  2025, as.Date("2025-03-02"), "Anora", "Emilia Perez",
  2025, as.Date("2025-03-02"), "Anora", "I'm Still Here",
  2025, as.Date("2025-03-02"), "Anora", "Nickel Boys",
  2025, as.Date("2025-03-02"), "Anora", "The Substance",
  2025, as.Date("2025-03-02"), "Anora", "Wicked"
)

build_episode_manifest <- function(paths) {
  all_pages <- map_dfr(seq_len(discover_page_count(paths$cache_dir)), parse_listing_page, cache_dir = paths$cache_dir)
  episode_manifest <- clean_listing_manifest(all_pages) |>
    mutate(
      episode_type = classify_episode_type(title, summary),
      year = year(episode_date)
    )
  write_dual_csv(episode_manifest, "episode_manifest.csv", paths)
  write_csv(episode_manifest, file.path(paths$exploration_processed, "episode_manifest_full.csv"))
  episode_manifest
}
