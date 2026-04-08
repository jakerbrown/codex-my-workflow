# ============================================================
# Neighborhood Splitting Across Districts
# Author: Codex
# Purpose: Download neighborhood and district boundary data, compute
#   containment/splitting metrics, and write tables, figures, and RDS outputs.
# Inputs:
#   - Harvard Dataverse neighborhood release
#   - Census/TIGER state legislative district boundaries via tigris
#   - Official city council district boundary files for matched cities
# Outputs:
#   - output/neighborhood_district_splitting/**
# ============================================================

# 0. Setup ----
suppressPackageStartupMessages({
  library(sf)
  library(dplyr)
  library(purrr)
  library(stringr)
  library(readr)
  library(tidyr)
  library(ggplot2)
  library(jsonlite)
  library(httr2)
  library(tigris)
  library(scales)
})

set.seed(42)
options(tigris_use_cache = TRUE)
sf::sf_use_s2(FALSE)

`%||%` <- function(x, y) {
  if (is.null(x) || length(x) == 0) y else x
}

root_dir <- "."
project_slug <- "neighborhood_district_splitting"
output_dir <- file.path(root_dir, "output", project_slug)
raw_dir <- file.path(output_dir, "raw")
raw_nbhd_dir <- file.path(raw_dir, "neighborhoods")
raw_council_dir <- file.path(raw_dir, "city_council")
processed_dir <- file.path(output_dir, "processed")
figure_dir <- file.path(output_dir, "figures")
table_dir <- file.path(output_dir, "tables")
paper_dir <- file.path(output_dir, "paper")

walk(
  c(output_dir, raw_dir, raw_nbhd_dir, raw_council_dir, processed_dir, figure_dir, table_dir, paper_dir),
  dir.create,
  recursive = TRUE,
  showWarnings = FALSE
)

dataverse_metadata_url <- "https://dataverse.harvard.edu/api/datasets/:persistentId/?persistentId=doi:10.7910/DVN/02NP1O"
dataverse_metadata_path <- file.path(raw_dir, "dataverse_metadata.json")

city_council_sources <- tibble::tribble(
  ~city_key,       ~city_label,         ~state_abbr, ~district_source,        ~url,
  "AustinTX",      "Austin, TX",        "TX",        "official_arcgis_rest",  "https://maps.austintexas.gov/gis/rest/Shared/CouncilDistrictsFill/MapServer/0/query?where=1%3D1&outFields=*&f=geojson",
  "ChicagoIL",     "Chicago, IL",       "IL",        "official_socrata",      "https://data.cityofchicago.org/api/geospatial/p293-wvbd?method=export&format=GeoJSON",
  "MinneapolisMN", "Minneapolis, MN",   "MN",        "official_arcgis_hub",   "https://opendata.arcgis.com/datasets/eca44c33fc5744478e285d957f9c5a0d_0.geojson",
  "SeattleWA",     "Seattle, WA",       "WA",        "official_arcgis_hub",   "https://opendata.arcgis.com/datasets/3fc6669fc05f473894dda3e6c7c36943_0.geojson"
)

city_key_to_state <- function(city_key) {
  str_sub(city_key, -2, -1)
}

utm_epsg_for_geometry <- function(geom) {
  bbox <- st_bbox(st_transform(geom, 4326))
  lon <- mean(c(bbox[["xmin"]], bbox[["xmax"]]))
  lat <- mean(c(bbox[["ymin"]], bbox[["ymax"]]))
  zone <- floor((lon + 180) / 6) + 1
  if (lat >= 0) {
    32600 + zone
  } else {
    32700 + zone
  }
}

download_if_needed <- function(url, dest) {
  if (!file.exists(dest)) {
    resp <- request(url) |>
      req_retry(max_tries = 3) |>
      req_perform()
    writeBin(resp_body_raw(resp), dest)
  }
  dest
}

fetch_dataverse_metadata <- function() {
  if (!file.exists(dataverse_metadata_path)) {
    resp <- request(dataverse_metadata_url) |>
      req_retry(max_tries = 3) |>
      req_perform()
    writeLines(resp_body_string(resp), dataverse_metadata_path)
  }
  fromJSON(dataverse_metadata_path, simplifyDataFrame = FALSE)
}

extract_dataverse_files <- function(metadata) {
  files <- metadata$data$latestVersion$files
  tibble(
    label = map_chr(files, "label"),
    directory_label = map_chr(files, ~ .x$directoryLabel %||% NA_character_),
    file_id = map_int(files, ~ .x$dataFile$id),
    filename = map_chr(files, ~ .x$dataFile$filename),
    filesize = map_dbl(files, ~ .x$dataFile$filesize)
  ) |>
    mutate(
      city_key = if_else(
        !is.na(directory_label),
        str_split_fixed(directory_label, "/", 3)[, 2],
        NA_character_
      )
    )
}

choose_neighborhood_files <- function(file_index) {
  file_index |>
    filter(str_detect(label, "_cleaned\\.zip$"), !is.na(city_key), city_key != "") |>
    arrange(city_key, desc(str_detect(label, "nha_cleaned")), desc(str_detect(label, "onm_cleaned")), label) |>
    group_by(city_key) |>
    slice(1) |>
    ungroup()
}

load_or_download_neighborhood_zip <- function(file_id, city_key, label) {
  dest <- file.path(raw_nbhd_dir, paste0(city_key, "__", label))
  if (!file.exists(dest)) {
    download_if_needed(sprintf("https://dataverse.harvard.edu/api/access/datafile/%s", file_id), dest)
  }
  dest
}

read_neighborhood_layer <- function(zip_path, city_key) {
  zip_listing <- tryCatch(utils::unzip(zip_path, list = TRUE), error = function(e) NULL)
  shp_member <- zip_listing$Name[str_detect(zip_listing$Name, "\\.shp$")][1]

  if (is.null(shp_member) || is.na(shp_member)) {
    stop(sprintf("No shapefile layer found in %s", zip_path))
  }

  vsi_path <- sprintf("/vsizip/%s/%s", normalizePath(zip_path), shp_member)
  nbhd <- st_read(vsi_path, quiet = TRUE)
  nbhd <- st_make_valid(nbhd)
  nbhd <- st_transform(nbhd, 4326)

  names_lower <- tolower(names(nbhd))
  id_field <- names(nbhd)[match(TRUE, names_lower %in% c("nbhd_id", "neighborhood_id", "id", "objectid", "fid"), nomatch = 0)]
  name_field <- names(nbhd)[match(TRUE, names_lower %in% c("nbhd_name", "name", "neighborhood", "label"), nomatch = 0)]

  if (length(id_field) == 0 || id_field == "") {
    nbhd$nbhd_id_std <- as.character(seq_len(nrow(nbhd)))
  } else {
    nbhd$nbhd_id_std <- as.character(nbhd[[id_field]])
  }

  if (length(name_field) == 0 || name_field == "") {
    nbhd$nbhd_name_std <- as.character(nbhd$nbhd_id_std)
  } else {
    nbhd$nbhd_name_std <- as.character(nbhd[[name_field]])
  }

  nbhd |>
    transmute(
      city_key = city_key,
      state_abbr = city_key_to_state(city_key),
      nbhd_id = paste(city_key, nbhd_id_std, sep = "::"),
      nbhd_name = nbhd_name_std,
      geometry = geometry
    ) |>
    filter(!st_is_empty(geometry))
}

load_or_download_city_council <- function(city_key, url) {
  dest <- file.path(raw_council_dir, paste0(city_key, ".geojson"))
  if (!file.exists(dest)) {
    download_if_needed(url, dest)
  }
  st_read(dest, quiet = TRUE) |>
    st_make_valid() |>
    st_transform(4326)
}

pick_district_id_field <- function(x) {
  candidate <- names(x)[match(TRUE, tolower(names(x)) %in% c("district", "districtno", "council_dist", "ward", "ward_id", "name", "namelsad"), nomatch = 0)]
  if (length(candidate) == 0 || candidate == "") {
    if ("NAME" %in% names(x)) "NAME" else names(x)[1]
  } else {
    candidate
  }
}

summarize_intersections <- function(neighborhoods, districts, system_name, district_type, district_id_field) {
  if (nrow(neighborhoods) == 0 || nrow(districts) == 0) {
    return(tibble())
  }

  crs_out <- utm_epsg_for_geometry(neighborhoods)
  nbhd_proj <- neighborhoods |>
    st_transform(crs_out) |>
    mutate(neighborhood_area = as.numeric(st_area(geometry)))

  districts_proj <- districts |>
    st_make_valid() |>
    st_transform(crs_out) |>
    transmute(district_id = as.character(.data[[district_id_field]]), geometry = geometry)

  district_join <- st_intersection(
    nbhd_proj |> select(city_key, state_abbr, nbhd_id, nbhd_name, neighborhood_area),
    districts_proj
  )

  if (nrow(district_join) == 0) {
    return(tibble())
  }

  district_join |>
    mutate(intersection_area = as.numeric(st_area(geometry))) |>
    st_drop_geometry() |>
    filter(intersection_area > 1) |>
    group_by(city_key, state_abbr, nbhd_id, nbhd_name, neighborhood_area) |>
    summarize(
      district_count = n_distinct(district_id),
      largest_area = max(intersection_area, na.rm = TRUE),
      total_intersection_area = sum(intersection_area, na.rm = TRUE),
      .groups = "drop"
    ) |>
    mutate(
      containment = district_count == 1,
      largest_area_share = pmin(1, largest_area / neighborhood_area),
      uncovered_area_share = pmax(0, 1 - (total_intersection_area / neighborhood_area)),
      system_name = system_name,
      district_type = district_type
    )
}

compute_weighted_summaries <- function(metrics) {
  if (nrow(metrics) == 0) {
    return(tibble())
  }

  neighborhood_weighted <- metrics |>
    group_by(sample_scope, system_name, district_type) |>
    summarize(
      weighting = "Neighborhood-weighted",
      n_cities = n_distinct(city_key),
      n_neighborhoods = n(),
      containment_rate = mean(containment, na.rm = TRUE),
      mean_district_count = mean(district_count, na.rm = TRUE),
      median_district_count = median(district_count, na.rm = TRUE),
      mean_largest_area_share = mean(largest_area_share, na.rm = TRUE),
      median_largest_area_share = median(largest_area_share, na.rm = TRUE),
      p10_largest_area_share = quantile(largest_area_share, 0.10, na.rm = TRUE),
      p90_largest_area_share = quantile(largest_area_share, 0.90, na.rm = TRUE),
      .groups = "drop"
    )

  city_weighted <- metrics |>
    group_by(sample_scope, system_name, district_type, city_key) |>
    summarize(
      containment_rate = mean(containment, na.rm = TRUE),
      mean_district_count = mean(district_count, na.rm = TRUE),
      mean_largest_area_share = mean(largest_area_share, na.rm = TRUE),
      n_neighborhoods_city = n(),
      .groups = "drop"
    ) |>
    group_by(sample_scope, system_name, district_type) |>
    summarize(
      weighting = "City-weighted",
      n_cities = n(),
      n_neighborhoods = sum(n_neighborhoods_city),
      containment_rate = mean(containment_rate, na.rm = TRUE),
      mean_district_count = mean(mean_district_count, na.rm = TRUE),
      median_district_count = median(mean_district_count, na.rm = TRUE),
      mean_largest_area_share = mean(mean_largest_area_share, na.rm = TRUE),
      median_largest_area_share = median(mean_largest_area_share, na.rm = TRUE),
      p10_largest_area_share = quantile(mean_largest_area_share, 0.10, na.rm = TRUE),
      p90_largest_area_share = quantile(mean_largest_area_share, 0.90, na.rm = TRUE),
      .groups = "drop"
    )

  bind_rows(city_weighted, neighborhood_weighted)
}

write_markdown_table <- function(df, path, digits = 3) {
  formatted <- df |>
    mutate(across(where(is.numeric), ~ round(.x, digits)))
  lines <- c(
    paste(names(formatted), collapse = " | "),
    paste(rep("---", ncol(formatted)), collapse = " | ")
  )
  rows <- apply(formatted, 1, function(x) paste(x, collapse = " | "))
  writeLines(c(lines, rows), path)
}

# 1. Metadata and source index ----
message("Fetching Dataverse metadata...")
dataverse_metadata <- fetch_dataverse_metadata()
file_index <- extract_dataverse_files(dataverse_metadata)
neighborhood_file_index <- choose_neighborhood_files(file_index)

write_csv(neighborhood_file_index, file.path(processed_dir, "neighborhood_file_index.csv"))
write_csv(city_council_sources, file.path(processed_dir, "city_council_source_index.csv"))

# 2. Download and read neighborhood boundaries ----
message("Downloading neighborhood boundary files...")
neighborhood_zips <- neighborhood_file_index |>
  mutate(zip_path = pmap_chr(list(file_id, city_key, label), load_or_download_neighborhood_zip))

message("Reading neighborhood boundaries...")
neighborhoods_all <- pmap_dfr(
  list(neighborhood_zips$zip_path, neighborhood_zips$city_key),
  read_neighborhood_layer
)

saveRDS(neighborhoods_all, file.path(processed_dir, "neighborhoods_all.rds"))

# 3. State legislative analysis ----
message("Running state legislative analysis...")
states_in_sample <- neighborhoods_all |>
  st_drop_geometry() |>
  distinct(state_abbr) |>
  arrange(state_abbr) |>
  pull(state_abbr)

state_metrics_list <- list()

for (state_abbr in states_in_sample) {
  message(sprintf("Processing state legislative districts for %s", state_abbr))
  state_neighborhoods <- neighborhoods_all |>
    filter(state_abbr == !!state_abbr)

  for (house in c("lower", "upper")) {
    district_sf <- tryCatch(
      tigris::state_legislative_districts(state = state_abbr, house = house, year = 2024, cb = TRUE, progress_bar = FALSE),
      error = function(e) NULL
    )

    if (is.null(district_sf) || nrow(district_sf) == 0) {
      next
    }

    district_id_field <- pick_district_id_field(district_sf)
    system_name <- if (house == "lower") "State House / Assembly" else "State Senate"
    district_type <- if (house == "lower") "state_lower" else "state_upper"

    state_metrics_list[[paste(state_abbr, house, sep = "_")]] <- summarize_intersections(
      neighborhoods = state_neighborhoods,
      districts = district_sf,
      system_name = system_name,
      district_type = district_type,
      district_id_field = district_id_field
    )
  }
}

state_metrics <- bind_rows(state_metrics_list)
saveRDS(state_metrics, file.path(processed_dir, "state_legislative_metrics.rds"))
write_csv(state_metrics, file.path(table_dir, "state_legislative_metrics.csv"))

# 4. City council sample analysis ----
message("Running city council sample analysis...")
council_metrics_list <- list()

for (i in seq_len(nrow(city_council_sources))) {
  city_key <- city_council_sources$city_key[[i]]
  message(sprintf("Processing city council districts for %s", city_key))

  city_neighborhoods <- neighborhoods_all |>
    filter(city_key == !!city_key)

  council_sf <- load_or_download_city_council(city_key, city_council_sources$url[[i]])
  district_id_field <- pick_district_id_field(council_sf)

  council_metrics_list[[city_key]] <- summarize_intersections(
    neighborhoods = city_neighborhoods,
    districts = council_sf,
    system_name = "City Council",
    district_type = "city_council",
    district_id_field = district_id_field
  )
}

city_council_metrics <- bind_rows(council_metrics_list)
saveRDS(city_council_metrics, file.path(processed_dir, "city_council_metrics.rds"))
write_csv(city_council_metrics, file.path(table_dir, "city_council_metrics.csv"))

# 5. Optional population-weighted branch ----
message("Computing matched-sample population weights where feasible...")
matched_city_keys <- city_council_sources$city_key
population_metrics <- list()

for (city_key in matched_city_keys) {
  rds_row <- file_index |>
    filter(label == paste0(city_key, ".rds")) |>
    slice(1)

  if (nrow(rds_row) == 0) {
    next
  }

  rds_dest <- file.path(raw_nbhd_dir, paste0(city_key, ".rds"))
  download_if_needed(sprintf("https://dataverse.harvard.edu/api/access/datafile/%s", rds_row$file_id[[1]]), rds_dest)

  city_blocks <- readRDS(rds_dest) |>
    st_as_sf() |>
    st_make_valid() |>
    st_transform(4326)

  if (!all(c("nbhd_id", "nbhd_name", "pop") %in% names(city_blocks))) {
    next
  }

  city_blocks <- city_blocks |>
    transmute(
      city_key = city_key,
      nbhd_id = paste(city_key, as.character(nbhd_id), sep = "::"),
      nbhd_name = as.character(nbhd_name),
      population = as.numeric(pop),
      geometry = geometry
    ) |>
    filter(!is.na(population), population > 0)

  council_url <- city_council_sources |>
    filter(city_key == !!city_key) |>
    pull(url)

  systems <- list(
    city_council = load_or_download_city_council(city_key, council_url),
    state_lower = tryCatch(tigris::state_legislative_districts(state = city_key_to_state(city_key), house = "lower", year = 2024, cb = TRUE, progress_bar = FALSE), error = function(e) NULL),
    state_upper = tryCatch(tigris::state_legislative_districts(state = city_key_to_state(city_key), house = "upper", year = 2024, cb = TRUE, progress_bar = FALSE), error = function(e) NULL)
  )

  system_names <- c(
    city_council = "City Council",
    state_lower = "State House / Assembly",
    state_upper = "State Senate"
  )

  for (system_key in names(systems)) {
    district_sf <- systems[[system_key]]
    if (is.null(district_sf) || nrow(district_sf) == 0) {
      next
    }

    district_id_field <- pick_district_id_field(district_sf)
    crs_out <- utm_epsg_for_geometry(city_blocks)

    blocks_proj <- city_blocks |>
      st_transform(crs_out) |>
      mutate(block_area = as.numeric(st_area(geometry)))

    districts_proj <- district_sf |>
      st_make_valid() |>
      st_transform(crs_out) |>
      transmute(district_id = as.character(.data[[district_id_field]]), geometry = geometry)

    block_int <- st_intersection(
      blocks_proj |> select(city_key, nbhd_id, nbhd_name, population, block_area),
      districts_proj
    )

    if (nrow(block_int) == 0) {
      next
    }

    pop_by_district <- block_int |>
      mutate(intersection_area = as.numeric(st_area(geometry))) |>
      st_drop_geometry() |>
      filter(intersection_area > 0, block_area > 0) |>
      mutate(pop_alloc = population * (intersection_area / block_area)) |>
      group_by(city_key, nbhd_id, nbhd_name, district_id) |>
      summarize(pop_alloc = sum(pop_alloc, na.rm = TRUE), .groups = "drop")

    pop_metrics <- pop_by_district |>
      group_by(city_key, nbhd_id, nbhd_name) |>
      summarize(
        district_count_pop = n_distinct(district_id),
        neighborhood_population = sum(pop_alloc, na.rm = TRUE),
        largest_pop = max(pop_alloc, na.rm = TRUE),
        .groups = "drop"
      ) |>
      mutate(
        system_name = system_names[[system_key]],
        district_type = system_key,
        largest_pop_share = pmin(1, largest_pop / neighborhood_population)
      )

    population_metrics[[paste(city_key, system_key, sep = "_")]] <- pop_metrics
  }
}

population_metrics <- bind_rows(population_metrics)
saveRDS(population_metrics, file.path(processed_dir, "population_weighted_metrics.rds"))
write_csv(population_metrics, file.path(table_dir, "population_weighted_metrics.csv"))

# 6. Summary tables ----
matched_state_metrics <- state_metrics |>
  filter(city_key %in% matched_city_keys)

state_summary <- compute_weighted_summaries(
  state_metrics |>
    mutate(sample_scope = "All neighborhood-source cities")
)

matched_summary <- compute_weighted_summaries(
  bind_rows(matched_state_metrics, city_council_metrics) |>
    mutate(sample_scope = "Matched city sample")
)

summary_table <- bind_rows(state_summary, matched_summary) |>
  arrange(sample_scope, weighting, district_type)

if (
  nrow(population_metrics) > 0 &&
  dplyr::n_distinct(population_metrics$city_key) >= 2 &&
  any(population_metrics$district_type == "city_council")
) {
  population_summary <- population_metrics |>
    mutate(sample_scope = "Matched city sample") |>
    group_by(sample_scope, system_name, district_type) |>
    summarize(
      weighting = "Population-weighted neighborhood population",
      n_cities = n_distinct(city_key),
      n_neighborhoods = n(),
      containment_rate = NA_real_,
      mean_district_count = mean(district_count_pop, na.rm = TRUE),
      median_district_count = median(district_count_pop, na.rm = TRUE),
      mean_largest_area_share = mean(largest_pop_share, na.rm = TRUE),
      median_largest_area_share = median(largest_pop_share, na.rm = TRUE),
      p10_largest_area_share = quantile(largest_pop_share, 0.10, na.rm = TRUE),
      p90_largest_area_share = quantile(largest_pop_share, 0.90, na.rm = TRUE),
      .groups = "drop"
    )

  summary_table <- bind_rows(summary_table, population_summary)
} else {
  writeLines(
    c(
      "# Population-weighted note",
      "",
      "Population-weighted metrics were attempted using the Census-block-linked files in the Dataverse release.",
      "In this run, that branch did not yield broad enough multi-city coverage to report as a main result.",
      "Area-weighted and city-weighted summaries remain the primary reported estimands."
    ),
    file.path(paper_dir, "population_weighting_note.md")
  )
}

write_csv(summary_table, file.path(table_dir, "summary_table.csv"))
write_markdown_table(summary_table, file.path(table_dir, "summary_table.md"))
saveRDS(summary_table, file.path(processed_dir, "summary_table.rds"))

coverage_table <- tibble(
  analysis_component = c(
    "Neighborhood source cities",
    "State legislative analysis cities",
    "City council sample cities"
  ),
  city_count = c(
    n_distinct(neighborhood_file_index$city_key),
    n_distinct(state_metrics$city_key),
    n_distinct(city_council_metrics$city_key)
  ),
  notes = c(
    "Cities with one cleaned neighborhood boundary file selected from the Dataverse release.",
    "Cities successfully matched to 2024 state legislative district boundaries through tigris/Census.",
    "Cities with official municipal city council boundary downloads configured in this script."
  )
)

write_csv(coverage_table, file.path(table_dir, "coverage_table.csv"))
write_markdown_table(coverage_table, file.path(table_dir, "coverage_table.md"))

# 7. Figures ----
plot_summary <- summary_table |>
  filter(
    sample_scope == "Matched city sample",
    weighting %in% c("Neighborhood-weighted", "City-weighted"),
    district_type %in% c("state_lower", "state_upper", "city_council")
  )

containment_plot <- ggplot(plot_summary, aes(x = system_name, y = containment_rate, fill = weighting)) +
  geom_col(position = position_dodge(width = 0.7), width = 0.6) +
  scale_y_continuous(labels = percent_format(accuracy = 1)) +
  labs(
    x = NULL,
    y = "Neighborhoods fully contained in one district",
    fill = NULL,
    title = "Containment Rates by District System",
    subtitle = "Matched-city sample"
  ) +
  theme_minimal(base_size = 12) +
  theme(legend.position = "top")

ggsave(
  filename = file.path(figure_dir, "containment_rates_matched_sample.png"),
  plot = containment_plot,
  width = 9,
  height = 5,
  dpi = 300,
  bg = "white"
)

district_count_plot <- bind_rows(matched_state_metrics, city_council_metrics) |>
  filter(district_count <= 6) |>
  mutate(system_name = factor(system_name, levels = c("City Council", "State House / Assembly", "State Senate"))) |>
  ggplot(aes(x = district_count, fill = system_name)) +
  geom_histogram(binwidth = 1, position = "dodge", boundary = 0.5) +
  scale_x_continuous(breaks = 1:6) +
  labs(
    x = "Number of districts intersecting a neighborhood",
    y = "Neighborhood count",
    fill = NULL,
    title = "How Many Districts Intersect Each Neighborhood?",
    subtitle = "Matched-city sample"
  ) +
  theme_minimal(base_size = 12) +
  theme(legend.position = "top")

ggsave(
  filename = file.path(figure_dir, "district_count_distribution_matched_sample.png"),
  plot = district_count_plot,
  width = 9,
  height = 5,
  dpi = 300,
  bg = "white"
)

largest_share_plot <- bind_rows(matched_state_metrics, city_council_metrics) |>
  ggplot(aes(x = system_name, y = largest_area_share, fill = system_name)) +
  geom_boxplot(outlier.alpha = 0.15) +
  scale_y_continuous(labels = percent_format(accuracy = 1)) +
  labs(
    x = NULL,
    y = "Largest intersecting district share of neighborhood area",
    fill = NULL,
    title = "Largest-Area Share by District System",
    subtitle = "Matched-city sample"
  ) +
  theme_minimal(base_size = 12) +
  theme(legend.position = "none")

ggsave(
  filename = file.path(figure_dir, "largest_area_share_boxplot_matched_sample.png"),
  plot = largest_share_plot,
  width = 9,
  height = 5,
  dpi = 300,
  bg = "white"
)

# 8. Example map ----
map_candidates <- city_council_metrics |>
  arrange(largest_area_share, desc(district_count))

if (nrow(map_candidates) > 0) {
  example_city <- map_candidates$city_key[[1]]
  example_nbhd_id <- map_candidates$nbhd_id[[1]]

  example_neighborhoods <- neighborhoods_all |>
    filter(city_key == !!example_city)

  example_districts <- load_or_download_city_council(
    example_city,
    city_council_sources |>
      filter(city_key == !!example_city) |>
      pull(url)
  )

  example_plot <- ggplot() +
    geom_sf(data = example_districts, fill = NA, color = "#1f78b4", linewidth = 0.6) +
    geom_sf(data = example_neighborhoods, fill = "grey85", color = "white", linewidth = 0.15) +
    geom_sf(data = example_neighborhoods |> filter(nbhd_id == !!example_nbhd_id), fill = "#e31a1c", color = "black", linewidth = 0.5) +
    labs(
      title = sprintf("Example of neighborhood splitting: %s", example_city),
      subtitle = "Highlighted neighborhood shown against city council district boundaries"
    ) +
    theme_void(base_size = 12)

  ggsave(
    filename = file.path(figure_dir, "example_city_council_split_map.png"),
    plot = example_plot,
    width = 8,
    height = 8,
    dpi = 300,
    bg = "white"
  )
}

# 9. Paper-side notes ----
analysis_notes <- c(
  "# Analysis notes",
  "",
  sprintf("- Neighborhood source cities loaded: %s", n_distinct(neighborhood_file_index$city_key)),
  sprintf("- State legislative metric rows: %s", nrow(state_metrics)),
  sprintf("- City council metric rows: %s", nrow(city_council_metrics)),
  sprintf("- Matched city-council sample: %s", paste(city_council_sources$city_label, collapse = ", "))
)

writeLines(analysis_notes, file.path(paper_dir, "analysis_notes.md"))

message("Completed neighborhood district splitting pipeline.")
