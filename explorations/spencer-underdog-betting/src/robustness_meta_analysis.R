suppressPackageStartupMessages({
  library(arrow)
  library(dplyr)
  library(readr)
})

script_arg <- commandArgs(trailingOnly = FALSE)[grep("^--file=", commandArgs(trailingOnly = FALSE))]
script_path <- normalizePath(sub("^--file=", "", script_arg[1]))
root <- normalizePath(file.path(dirname(script_path), ".."))
output_dir <- file.path(root, "output")

games <- read_parquet(file.path(output_dir, "game_level_panel.parquet"))
python_strategy <- read_csv(file.path(output_dir, "strategy_results.csv"), show_col_types = FALSE)

build_side <- function(df, side) {
  opp <- if (side == "home") "away" else "home"
  tibble(
    league = df$league,
    season = df$season,
    date = as.Date(df$date),
    days_since_open = df$days_since_open,
    likely_regular_season = df$likely_regular_season,
    team = df[[paste0(side, "_team")]],
    closing_ml = df[[paste0(side, "_close_ml")]],
    win = df[[paste0(side, "_win")]],
    push = df$push,
    implied_prob_novig = df[[paste0(side, "_implied_prob_novig")]],
    is_underdog = df[[paste0(side, "_is_underdog")]]
  )
}

american_profit <- function(odds, stake = 100) {
  ifelse(odds > 0, stake * odds / 100, stake * 100 / abs(odds))
}

sides <- bind_rows(build_side(games, "home"), build_side(games, "away")) %>%
  mutate(
    profit = ifelse(push == 1, 0, ifelse(win == 1, american_profit(closing_ml), -100)),
    opening_window_3w = days_since_open < 21
  )

early_dogs <- sides %>%
  filter(likely_regular_season, is_underdog, opening_window_3w)

league_summary <- early_dogs %>%
  group_by(league) %>%
  summarise(
    bets = n(),
    mean_profit = mean(profit),
    roi = mean(profit) / 100,
    profit_sd = sd(profit),
    se_profit = profit_sd / sqrt(bets),
    calibration_gap = mean(win - implied_prob_novig),
    .groups = "drop"
  )

python_3w <- python_strategy %>%
  filter(strategy == "underdog_3w", league != "POOLED") %>%
  select(league, python_roi = roi, python_bets = bets)

league_summary <- league_summary %>%
  left_join(python_3w, by = "league") %>%
  mutate(roi_gap_vs_python = roi - python_roi)

if (any(abs(league_summary$roi_gap_vs_python) > 1e-10, na.rm = TRUE)) {
  stop("R robustness script does not match Python underdog_3w ROI by league.")
}

tau2_dl <- function(y, se) {
  v <- se^2
  w <- 1 / v
  mu_hat <- sum(w * y) / sum(w)
  q <- sum(w * (y - mu_hat)^2)
  c_val <- sum(w) - sum(w^2) / sum(w)
  max(0, (q - (length(y) - 1)) / c_val)
}

tau2 <- tau2_dl(league_summary$mean_profit, league_summary$se_profit)
weights <- 1 / (league_summary$se_profit^2 + tau2)
pooled_mean <- sum(weights * league_summary$mean_profit) / sum(weights)
league_summary <- league_summary %>%
  mutate(
    shrunk_mean_profit = ifelse(
      tau2 > 0,
      ((mean_profit / (se_profit^2)) + (pooled_mean / tau2)) /
        ((1 / (se_profit^2)) + (1 / tau2)),
      mean_profit
    )
  )

write_csv(league_summary, file.path(output_dir, "r_meta_results.csv"))

summary_lines <- c(
  "# R Meta-Analysis Summary",
  "",
  sprintf("- Random-effects tau^2 on mean profit per bet: %.3f", tau2),
  sprintf("- Pooled mean profit per bet: %.3f", pooled_mean),
  "",
  "## League summaries",
  ""
)

for (i in seq_len(nrow(league_summary))) {
  row <- league_summary[i, ]
  summary_lines <- c(
    summary_lines,
    sprintf(
      "- %s: ROI %.3f across %d bets, calibration gap %.3f, shrunk mean profit %.3f",
      row$league,
      row$roi,
      row$bets,
      row$calibration_gap,
      row$shrunk_mean_profit
    )
  )
}

writeLines(summary_lines, file.path(output_dir, "r_meta_summary.md"))
