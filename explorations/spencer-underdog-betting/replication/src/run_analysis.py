from __future__ import annotations

import json
import math
import os
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
RAW_DIR = ROOT / "data" / "raw"
OUTPUT_DIR = ROOT / "output"
MPL_DIR = ROOT / ".mplconfig"
os.environ.setdefault("MPLCONFIGDIR", str(MPL_DIR))
os.environ.setdefault("OMP_NUM_THREADS", "1")
os.environ.setdefault("OPENBLAS_NUM_THREADS", "1")
os.environ.setdefault("MKL_NUM_THREADS", "1")
os.environ.setdefault("VECLIB_MAXIMUM_THREADS", "1")
os.environ.setdefault("NUMEXPR_NUM_THREADS", "1")
os.environ.setdefault("KMP_INIT_AT_FORK", "FALSE")

import numpy as np
import pandas as pd
import seaborn as sns
import statsmodels.api as sm
from matplotlib import pyplot as plt


MPL_DIR.mkdir(parents=True, exist_ok=True)

sns.set_theme(style="whitegrid", context="talk")
plt.switch_backend("Agg")


SOURCE_URLS = {
    "nfl": "https://raw.githubusercontent.com/flancast90/sportsbookreview-scraper/main/data/nfl_archive_10Y.json",
    "nba": "https://raw.githubusercontent.com/flancast90/sportsbookreview-scraper/main/data/nba_archive_10Y.json",
    "nhl": "https://raw.githubusercontent.com/flancast90/sportsbookreview-scraper/main/data/nhl_archive_10Y.json",
    "mlb": "https://raw.githubusercontent.com/flancast90/sportsbookreview-scraper/main/data/mlb_archive_10Y.json",
}


TEAM_ALIASES = {
    "nfl": {
        "BuffaloBills": "Bills",
        "KCChiefs": "Chiefs",
        "Kansas": "Chiefs",
        "LVRaiders": "Raiders",
        "LosAngeles": "Rams",
        "NewYork": "Giants",
        "Oakland": "Raiders",
        "SanDiego": "Chargers",
        "St.Louis": "Rams",
        "Tampa": "Buccaneers",
        "Washingtom": "Commanders",
        "Fortyniners": "49ers",
    },
    "nba": {
        "Golden State": "Warriors",
        "LA Clippers": "Clippers",
        "NewJersey": "Nets",
        "Oklahoma City": "Thunder",
        "Seventysixers": "76ers",
        "Trailblazers": "Trail Blazers",
    },
    "nhl": {
        "Arizonas": "Coyotes",
        "NY Islanders": "Islanders",
        "Phoenix": "Coyotes",
        "SeattleKraken": "Kraken",
        "St.Louis": "Blues",
        "Tampa": "Lightning",
        "Tampa Bay": "Lightning",
        "WinnipegJets": "Jets",
    },
    "mlb": {
        "BRS": "Brewers",
        "CUB": "Cubs",
        "KAN": "Royals",
        "LOS": "Dodgers",
        "SDG": "Padres",
        "SFG": "Giants",
        "SFO": "Giants",
        "TAM": "Rays",
    },
}


SIDE_LABELS = {"home": ("home_team", "home_final", "home_close_ml"), "away": ("away_team", "away_final", "away_close_ml")}


def american_to_implied_prob(odds: pd.Series) -> pd.Series:
    odds = odds.astype(float)
    pos = odds > 0
    neg = odds < 0
    out = pd.Series(np.nan, index=odds.index, dtype=float)
    out.loc[pos] = 100.0 / (odds.loc[pos] + 100.0)
    out.loc[neg] = (-odds.loc[neg]) / ((-odds.loc[neg]) + 100.0)
    return out


def american_profit(odds: pd.Series, stake: float = 100.0) -> pd.Series:
    odds = odds.astype(float)
    pos = odds > 0
    neg = odds < 0
    out = pd.Series(np.nan, index=odds.index, dtype=float)
    out.loc[pos] = stake * odds.loc[pos] / 100.0
    out.loc[neg] = stake * 100.0 / (-odds.loc[neg])
    return out


def download_if_missing() -> None:
    RAW_DIR.mkdir(parents=True, exist_ok=True)
    for league, url in SOURCE_URLS.items():
        path = RAW_DIR / f"{league}_archive_10Y.json"
        if path.exists():
            continue
        subprocess.run(
            ["curl", "-L", "--fail", "--max-time", "120", url, "-o", str(path)],
            check=True,
        )


def clean_team_name(name: object, league: str) -> str | None:
    if pd.isna(name):
        return None
    text = str(name).strip()
    if text in {"", "0", "None"}:
        return None
    return TEAM_ALIASES.get(league, {}).get(text, text)


def load_clean_games(league: str) -> pd.DataFrame:
    df = pd.read_json(RAW_DIR / f"{league}_archive_10Y.json")
    df["league"] = league.upper()
    df["season"] = df["season"].astype(int)
    df["date_str"] = df["date"].astype(str).str.replace(".0", "", regex=False)
    df["date"] = pd.to_datetime(df["date_str"], format="%Y%m%d", errors="coerce")

    for side in ("home", "away"):
        team_col, score_col, ml_col = SIDE_LABELS[side]
        df[team_col] = df[team_col].map(lambda x: clean_team_name(x, league))
        df[score_col] = pd.to_numeric(df[score_col], errors="coerce")
        df[ml_col] = pd.to_numeric(df[ml_col], errors="coerce")

    df = df.dropna(subset=["date", "home_team", "away_team", "home_final", "away_final", "home_close_ml", "away_close_ml"]).copy()
    df = df[(df["home_close_ml"] != 0) & (df["away_close_ml"] != 0)].copy()
    df = df[df["home_team"] != df["away_team"]].copy()

    if league != "nfl":
        df = df[df["home_final"] != df["away_final"]].copy()

    df = df.sort_values(["season", "date", "home_team", "away_team"]).reset_index(drop=True)
    df["game_id"] = (
        df["league"]
        + "_"
        + df["season"].astype(str)
        + "_"
        + df["date"].dt.strftime("%Y%m%d")
        + "_"
        + df["away_team"].str.replace(" ", "", regex=False)
        + "_"
        + df["home_team"].str.replace(" ", "", regex=False)
    )
    return df


def add_team_game_numbers(games: pd.DataFrame) -> pd.DataFrame:
    long_parts = []
    for side in ("home", "away"):
        team_col, score_col, ml_col = SIDE_LABELS[side]
        part = games[["game_id", "league", "season", "date", team_col]].rename(columns={team_col: "team"})
        part["side"] = side
        long_parts.append(part)
    long_df = pd.concat(long_parts, ignore_index=True)
    long_df = long_df.sort_values(["league", "season", "team", "date", "game_id"]).reset_index(drop=True)
    long_df["team_game_no"] = long_df.groupby(["league", "season", "team"]).cumcount() + 1

    counts = long_df.groupby(["league", "season", "team"]).size().reset_index(name="team_total_games")
    mode_games = (
        counts.groupby(["league", "season"])["team_total_games"]
        .agg(lambda s: int(s.mode().iloc[0]))
        .rename("season_mode_games")
        .reset_index()
    )
    long_df = long_df.merge(counts, on=["league", "season", "team"], how="left")
    long_df = long_df.merge(mode_games, on=["league", "season"], how="left")

    home_nums = long_df[long_df["side"] == "home"][["game_id", "team_game_no", "team_total_games", "season_mode_games"]].rename(
        columns={
            "team_game_no": "home_team_game_no",
            "team_total_games": "home_team_total_games",
            "season_mode_games": "season_mode_games",
        }
    )
    away_nums = long_df[long_df["side"] == "away"][["game_id", "team_game_no", "team_total_games"]].rename(
        columns={"team_game_no": "away_team_game_no", "team_total_games": "away_team_total_games"}
    )
    out = games.merge(home_nums, on="game_id", how="left").merge(away_nums, on="game_id", how="left")
    out["likely_regular_season"] = (
        (out["home_team_game_no"] <= out["season_mode_games"]) & (out["away_team_game_no"] <= out["season_mode_games"])
    )
    return out


def build_game_panel() -> pd.DataFrame:
    games = pd.concat([load_clean_games(league) for league in SOURCE_URLS], ignore_index=True)
    games = add_team_game_numbers(games)

    season_starts = games.groupby(["league", "season"])["date"].min().rename("season_start").reset_index()
    games = games.merge(season_starts, on=["league", "season"], how="left")
    games["days_since_open"] = (games["date"] - games["season_start"]).dt.days
    games["home_implied_prob_raw"] = american_to_implied_prob(games["home_close_ml"])
    games["away_implied_prob_raw"] = american_to_implied_prob(games["away_close_ml"])
    games["hold_raw"] = games["home_implied_prob_raw"] + games["away_implied_prob_raw"] - 1.0
    games["home_implied_prob_novig"] = games["home_implied_prob_raw"] / (
        games["home_implied_prob_raw"] + games["away_implied_prob_raw"]
    )
    games["away_implied_prob_novig"] = games["away_implied_prob_raw"] / (
        games["home_implied_prob_raw"] + games["away_implied_prob_raw"]
    )

    games["home_win"] = (games["home_final"] > games["away_final"]).astype(int)
    games["away_win"] = (games["away_final"] > games["home_final"]).astype(int)
    games["push"] = (games["home_final"] == games["away_final"]).astype(int)

    games["home_is_underdog"] = games["home_implied_prob_novig"] < games["away_implied_prob_novig"]
    games["away_is_underdog"] = games["away_implied_prob_novig"] < games["home_implied_prob_novig"]
    games["home_is_favorite"] = games["home_implied_prob_novig"] > games["away_implied_prob_novig"]
    games["away_is_favorite"] = games["away_implied_prob_novig"] > games["home_implied_prob_novig"]

    games["opening_window_2w"] = games["days_since_open"] < 14
    games["opening_window_3w"] = games["days_since_open"] < 21
    keep_cols = [
        "game_id",
        "league",
        "season",
        "date",
        "season_start",
        "days_since_open",
        "season_mode_games",
        "likely_regular_season",
        "home_team",
        "away_team",
        "home_final",
        "away_final",
        "home_close_ml",
        "away_close_ml",
        "home_implied_prob_raw",
        "away_implied_prob_raw",
        "home_implied_prob_novig",
        "away_implied_prob_novig",
        "hold_raw",
        "home_team_game_no",
        "away_team_game_no",
        "home_team_total_games",
        "away_team_total_games",
        "home_win",
        "away_win",
        "push",
        "home_is_underdog",
        "away_is_underdog",
        "home_is_favorite",
        "away_is_favorite",
        "opening_window_2w",
        "opening_window_3w",
    ]
    return games[keep_cols].copy()


def build_side_panel(games: pd.DataFrame) -> pd.DataFrame:
    rows = []
    for side in ("home", "away"):
        opp = "away" if side == "home" else "home"
        rows.append(
            pd.DataFrame(
                {
                    "game_id": games["game_id"],
                    "league": games["league"],
                    "season": games["season"],
                    "date": games["date"],
                    "days_since_open": games["days_since_open"],
                    "season_start": games["season_start"],
                    "season_mode_games": games["season_mode_games"],
                    "likely_regular_season": games["likely_regular_season"],
                    "team": games[f"{side}_team"],
                    "opponent": games[f"{opp}_team"],
                    "is_home": int(side == "home"),
                    "team_game_no": games[f"{side}_team_game_no"],
                    "team_total_games": games[f"{side}_team_total_games"],
                    "closing_ml": games[f"{side}_close_ml"],
                    "win": games[f"{side}_win"],
                    "push": games["push"],
                    "score_for": games[f"{side}_final"],
                    "score_against": games[f"{opp}_final"],
                    "implied_prob_raw": games[f"{side}_implied_prob_raw"],
                    "implied_prob_novig": games[f"{side}_implied_prob_novig"],
                    "opponent_implied_prob_novig": games[f"{opp}_implied_prob_novig"],
                    "is_underdog": games[f"{side}_is_underdog"],
                    "is_favorite": games[f"{side}_is_favorite"],
                    "opening_window_2w": games["opening_window_2w"],
                    "opening_window_3w": games["opening_window_3w"],
                }
            )
        )
    bets = pd.concat(rows, ignore_index=True).sort_values(["league", "season", "date", "game_id", "is_home"]).reset_index(drop=True)
    bets["profit_if_win"] = american_profit(bets["closing_ml"])
    bets["profit"] = np.where(bets["push"] == 1, 0.0, np.where(bets["win"] == 1, bets["profit_if_win"], -100.0))
    bets["season_team_games_proxy"] = bets.groupby(["league", "season"])["team_total_games"].transform(lambda s: int(s.mode().iloc[0]))
    bets["opening_first5"] = bets["team_game_no"] <= 5
    bets["opening_first10pct"] = bets["team_game_no"] <= np.ceil(0.10 * bets["season_team_games_proxy"])
    bets["road_underdog"] = bets["is_underdog"] & (bets["is_home"] == 0)
    bets["big_dog"] = bets["is_underdog"] & (bets["closing_ml"] >= 150)
    bets["modest_dog"] = bets["is_underdog"] & (bets["closing_ml"] < 150)
    bets["middle_of_season"] = (bets["days_since_open"] >= 60) & (bets["days_since_open"] < 81)
    bets["late_season"] = bets["days_since_open"] >= 120
    bets["calibration_residual"] = bets["win"] - bets["implied_prob_novig"]
    return bets


def strategy_mask(bets: pd.DataFrame, strategy: str) -> pd.Series:
    if strategy == "underdog_2w":
        return bets["is_underdog"] & bets["opening_window_2w"]
    if strategy == "underdog_3w":
        return bets["is_underdog"] & bets["opening_window_3w"]
    if strategy == "underdog_first5":
        return bets["is_underdog"] & bets["opening_first5"]
    if strategy == "underdog_first10pct":
        return bets["is_underdog"] & bets["opening_first10pct"]
    if strategy == "road_dog_3w":
        return bets["road_underdog"] & bets["opening_window_3w"]
    if strategy == "big_dog_3w":
        return bets["big_dog"] & bets["opening_window_3w"]
    if strategy == "modest_dog_3w":
        return bets["modest_dog"] & bets["opening_window_3w"]
    if strategy == "all_underdogs":
        return bets["is_underdog"]
    if strategy == "favorites_2w":
        return bets["is_favorite"] & bets["opening_window_2w"]
    if strategy == "favorites_3w":
        return bets["is_favorite"] & bets["opening_window_3w"]
    if strategy == "later_underdogs_mid":
        return bets["is_underdog"] & bets["middle_of_season"]
    if strategy == "later_underdogs_late":
        return bets["is_underdog"] & bets["late_season"]
    raise KeyError(strategy)


def summarize_strategy(sample: pd.DataFrame) -> dict[str, float]:
    sample = sample.sort_values("date")
    n = len(sample)
    if n == 0:
        return {
            "bets": 0,
            "win_rate": np.nan,
            "avg_odds": np.nan,
            "profit": 0.0,
            "roi": np.nan,
            "avg_profit": np.nan,
            "volatility": np.nan,
            "max_drawdown": np.nan,
            "avg_implied_prob": np.nan,
            "calibration_gap": np.nan,
        }
    cumulative = sample["profit"].cumsum()
    running_max = cumulative.cummax()
    drawdown = cumulative - running_max
    return {
        "bets": n,
        "win_rate": sample["win"].mean(),
        "avg_odds": sample["closing_ml"].mean(),
        "profit": sample["profit"].sum(),
        "roi": sample["profit"].sum() / (100.0 * n),
        "avg_profit": sample["profit"].mean(),
        "volatility": sample["profit"].std(ddof=1),
        "max_drawdown": drawdown.min(),
        "avg_implied_prob": sample["implied_prob_novig"].mean(),
        "calibration_gap": sample["calibration_residual"].mean(),
    }


def bootstrap_roi(sample: pd.DataFrame, cluster_cols: list[str], draws: int = 400, seed: int = 42) -> tuple[float, float]:
    if sample.empty:
        return (np.nan, np.nan)
    rng = np.random.default_rng(seed)
    clusters = list(sample.groupby(cluster_cols).groups.keys())
    cluster_frames = {key: sample.loc[idx] for key, idx in sample.groupby(cluster_cols).groups.items()}
    vals = []
    for _ in range(draws):
        picked = rng.choice(len(clusters), size=len(clusters), replace=True)
        boot = pd.concat([cluster_frames[clusters[i]] for i in picked], ignore_index=True)
        vals.append(boot["profit"].sum() / (100.0 * len(boot)))
    return tuple(np.percentile(vals, [2.5, 97.5]))


def compute_strategy_results(bets: pd.DataFrame) -> pd.DataFrame:
    strategies = [
        "underdog_2w",
        "underdog_3w",
        "underdog_first5",
        "underdog_first10pct",
        "road_dog_3w",
        "big_dog_3w",
        "modest_dog_3w",
    ]
    rows = []
    base = bets[bets["likely_regular_season"]].copy()
    for strategy in strategies:
        mask = strategy_mask(base, strategy)
        pooled = base.loc[mask]
        pooled_summary = summarize_strategy(pooled)
        low, high = bootstrap_roi(pooled, ["league", "season"])
        rows.append({"league": "POOLED", "strategy": strategy, **pooled_summary, "roi_ci_low": low, "roi_ci_high": high})
        for league, group in base.groupby("league"):
            sample = group.loc[strategy_mask(group, strategy)]
            summary = summarize_strategy(sample)
            low, high = bootstrap_roi(sample, ["season"])
            rows.append({"league": league, "strategy": strategy, **summary, "roi_ci_low": low, "roi_ci_high": high})
    return pd.DataFrame(rows)


def random_team_benchmark(games: pd.DataFrame, early_col: str, draws: int = 300, seed: int = 7) -> tuple[float, float]:
    rng = np.random.default_rng(seed)
    early_games = games.loc[games[early_col] & games["likely_regular_season"]].copy()
    if early_games.empty:
        return (np.nan, np.nan)
    profits = []
    for _ in range(draws):
        choose_home = rng.integers(0, 2, size=len(early_games)).astype(bool)
        sample = pd.DataFrame(
            {
                "profit": np.where(choose_home, np.where(early_games["home_win"], american_profit(early_games["home_close_ml"]), -100.0), np.where(early_games["away_win"], american_profit(early_games["away_close_ml"]), -100.0)),
            }
        )
        profits.append(sample["profit"].sum() / (100.0 * len(sample)))
    return float(np.mean(profits)), float(np.std(profits, ddof=1))


def permuted_timing_benchmark(bets: pd.DataFrame, early_days: int, draws: int = 300, seed: int = 11) -> tuple[float, float]:
    rng = np.random.default_rng(seed)
    dogs = bets.loc[bets["is_underdog"] & bets["likely_regular_season"]].copy()
    if dogs.empty:
        return (np.nan, np.nan)
    rois = []
    for _ in range(draws):
        pieces = []
        for _, group in dogs.groupby(["league", "season"]):
            group = group.copy()
            group["perm_days"] = rng.permutation(group["days_since_open"].to_numpy())
            pieces.append(group.loc[group["perm_days"] < early_days])
        sample = pd.concat(pieces, ignore_index=True)
        rois.append(sample["profit"].sum() / (100.0 * len(sample)))
    return float(np.mean(rois)), float(np.std(rois, ddof=1))


def fit_leave_one_season_probs(bets: pd.DataFrame) -> pd.Series:
    sample = bets.loc[bets["likely_regular_season"] & bets["is_underdog"]].copy()
    design = pd.get_dummies(sample[["league"]], drop_first=False).astype(float)
    design["implied_prob_novig"] = sample["implied_prob_novig"].to_numpy()
    design["days_since_open"] = sample["days_since_open"].to_numpy()
    design["is_home"] = sample["is_home"].to_numpy()
    design["opening_window_2w"] = sample["opening_window_2w"].astype(int).to_numpy()
    design["opening_window_3w"] = sample["opening_window_3w"].astype(int).to_numpy()
    preds = pd.Series(index=sample.index, dtype=float)
    for season_key, idx in sample.groupby(["league", "season"]).groups.items():
        train_idx = sample.index.difference(idx)
        train_X = sm.add_constant(design.loc[train_idx], has_constant="add")
        test_X = sm.add_constant(design.loc[idx], has_constant="add")
        model = sm.GLM(sample.loc[train_idx, "win"], train_X, family=sm.families.Binomial()).fit()
        preds.loc[idx] = model.predict(test_X)
    out = pd.Series(np.nan, index=bets.index, dtype=float)
    out.loc[preds.index] = preds
    return out


def kelly_profit(sample: pd.DataFrame, pred_prob: pd.Series, frac: float = 0.5) -> pd.Series:
    decimal_net = np.where(sample["closing_ml"] > 0, sample["closing_ml"] / 100.0, 100.0 / (-sample["closing_ml"]))
    b = pd.Series(decimal_net, index=sample.index, dtype=float)
    p = pred_prob.loc[sample.index].clip(lower=1e-6, upper=1 - 1e-6)
    q = 1.0 - p
    stake_frac = ((b * p) - q) / b
    stake_frac = frac * stake_frac.clip(lower=0.0)
    stakes = 100.0 * stake_frac
    win_profit = stakes * b
    return np.where(sample["push"] == 1, 0.0, np.where(sample["win"] == 1, win_profit, -stakes))


def compute_benchmark_results(games: pd.DataFrame, bets: pd.DataFrame) -> pd.DataFrame:
    base = bets[bets["likely_regular_season"]].copy()
    pred_prob = fit_leave_one_season_probs(bets)
    rows = []
    benchmarks = {
        "spencer_2w": strategy_mask(base, "underdog_2w"),
        "spencer_3w": strategy_mask(base, "underdog_3w"),
        "all_underdogs": strategy_mask(base, "all_underdogs"),
        "favorites_2w": strategy_mask(base, "favorites_2w"),
        "favorites_3w": strategy_mask(base, "favorites_3w"),
        "later_underdogs_mid": strategy_mask(base, "later_underdogs_mid"),
        "later_underdogs_late": strategy_mask(base, "later_underdogs_late"),
    }
    for label, mask in benchmarks.items():
        rows.append({"benchmark": label, **summarize_strategy(base.loc[mask])})

    mean_roi, sd_roi = random_team_benchmark(games, "opening_window_2w")
    rows.append({"benchmark": "random_team_2w_sim_mean", "bets": np.nan, "win_rate": np.nan, "avg_odds": np.nan, "profit": np.nan, "roi": mean_roi, "avg_profit": np.nan, "volatility": sd_roi, "max_drawdown": np.nan, "avg_implied_prob": np.nan, "calibration_gap": np.nan})
    mean_roi, sd_roi = random_team_benchmark(games, "opening_window_3w")
    rows.append({"benchmark": "random_team_3w_sim_mean", "bets": np.nan, "win_rate": np.nan, "avg_odds": np.nan, "profit": np.nan, "roi": mean_roi, "avg_profit": np.nan, "volatility": sd_roi, "max_drawdown": np.nan, "avg_implied_prob": np.nan, "calibration_gap": np.nan})

    mean_roi, sd_roi = permuted_timing_benchmark(base, 14)
    rows.append({"benchmark": "permuted_timing_2w_sim_mean", "bets": np.nan, "win_rate": np.nan, "avg_odds": np.nan, "profit": np.nan, "roi": mean_roi, "avg_profit": np.nan, "volatility": sd_roi, "max_drawdown": np.nan, "avg_implied_prob": np.nan, "calibration_gap": np.nan})
    mean_roi, sd_roi = permuted_timing_benchmark(base, 21)
    rows.append({"benchmark": "permuted_timing_3w_sim_mean", "bets": np.nan, "win_rate": np.nan, "avg_odds": np.nan, "profit": np.nan, "roi": mean_roi, "avg_profit": np.nan, "volatility": sd_roi, "max_drawdown": np.nan, "avg_implied_prob": np.nan, "calibration_gap": np.nan})

    for label, strategy in {"half_kelly_2w": "underdog_2w", "half_kelly_3w": "underdog_3w"}.items():
        sample = base.loc[strategy_mask(base, strategy) & pred_prob.notna()].copy()
        sample["profit"] = kelly_profit(sample, pred_prob)
        rows.append({"benchmark": label, **summarize_strategy(sample)})
    return pd.DataFrame(rows)


def partial_pooling(mean: pd.Series, se: pd.Series) -> pd.DataFrame:
    var = se**2
    weights = 1.0 / var
    pooled_mean = np.sum(weights * mean) / np.sum(weights)
    q = np.sum(weights * (mean - pooled_mean) ** 2)
    c = np.sum(weights) - (np.sum(weights**2) / np.sum(weights))
    tau2 = max(0.0, (q - (len(mean) - 1)) / c) if len(mean) > 1 else 0.0
    if tau2 > 0:
        shrunk = ((mean / var) + (pooled_mean / tau2)) / ((1.0 / var) + (1.0 / tau2))
    else:
        shrunk = pd.Series(np.repeat(pooled_mean, len(mean)), index=mean.index, dtype=float)
    return pd.DataFrame({"raw_mean": mean, "se": se, "shrunk_mean": shrunk, "tau2": tau2, "pooled_mean": pooled_mean})


def compute_model_results(bets: pd.DataFrame) -> pd.DataFrame:
    base = bets[bets["likely_regular_season"]].copy()
    regression_sample = base.copy()
    regression_sample["profit_unit"] = regression_sample["profit"] / 100.0
    regression_sample["opening_2w_x_dog"] = regression_sample["opening_window_2w"].astype(int) * regression_sample["is_underdog"].astype(int)
    regression_sample["opening_3w_x_dog"] = regression_sample["opening_window_3w"].astype(int) * regression_sample["is_underdog"].astype(int)

    X = pd.get_dummies(regression_sample[["league", "season"]].astype({"season": str}), drop_first=True).astype(float)
    X["is_underdog"] = regression_sample["is_underdog"].astype(int).to_numpy()
    X["opening_window_2w"] = regression_sample["opening_window_2w"].astype(int).to_numpy()
    X["opening_window_3w"] = regression_sample["opening_window_3w"].astype(int).to_numpy()
    X["opening_2w_x_dog"] = regression_sample["opening_2w_x_dog"].to_numpy()
    X["opening_3w_x_dog"] = regression_sample["opening_3w_x_dog"].to_numpy()
    X = sm.add_constant(X, has_constant="add")

    logit_model = sm.GLM(regression_sample["win"], X, family=sm.families.Binomial()).fit()
    ols_model = sm.OLS(regression_sample["profit_unit"], X).fit()

    underdog_3w = base.loc[strategy_mask(base, "underdog_3w")].copy()
    by_league = (
        underdog_3w.groupby("league")
        .agg(avg_profit=("profit", "mean"), profit_sd=("profit", "std"), bets=("profit", "size"))
        .reset_index()
    )
    by_league["se_profit"] = by_league["profit_sd"] / np.sqrt(by_league["bets"])
    pooled = partial_pooling(by_league["avg_profit"], by_league["se_profit"])
    pool_rows = pd.concat([by_league[["league", "avg_profit", "se_profit"]], pooled[["shrunk_mean", "tau2", "pooled_mean"]]], axis=1)
    pool_rows["model_family"] = "partial_pooling_profit_3w"

    coef_rows = []
    for model_name, fit in {"logit_win": logit_model, "ols_profit": ols_model}.items():
        coef = pd.DataFrame({"term": fit.params.index, "estimate": fit.params.values, "std_error": fit.bse.values, "p_value": fit.pvalues.values})
        coef["model_family"] = model_name
        coef_rows.append(coef)

    sim_rows = []
    for public_bias in [0.0, 0.015, 0.03]:
        for update_speed in [0.15, 0.3, 0.6]:
            roi = run_market_learning_sim(public_bias=public_bias, update_speed=update_speed)
            sim_rows.append({"model_family": "market_learning_sim", "term": f"bias_{public_bias:.3f}_speed_{update_speed:.2f}", "estimate": roi, "std_error": np.nan, "p_value": np.nan})
    sim_df = pd.DataFrame(sim_rows)

    model_df = pd.concat(coef_rows + [pool_rows.rename(columns={"league": "term", "avg_profit": "estimate", "se_profit": "std_error"})[["model_family", "term", "estimate", "std_error", "shrunk_mean", "tau2", "pooled_mean"]], sim_df], ignore_index=True, sort=False)
    return model_df


def run_market_learning_sim(public_bias: float, update_speed: float, seed: int = 123) -> float:
    rng = np.random.default_rng(seed + int(public_bias * 1000) + int(update_speed * 100))
    n_teams = 30
    n_games = 600
    true_strength = rng.normal(0, 1.0, size=n_teams)
    market_prior = true_strength + rng.normal(0, 0.75, size=n_teams)
    profits = []
    for g in range(n_games):
        i, j = rng.choice(n_teams, size=2, replace=False)
        p_true = 1.0 / (1.0 + np.exp(-(true_strength[i] - true_strength[j])))
        p_market = 1.0 / (1.0 + np.exp(-(market_prior[i] - market_prior[j] + public_bias)))
        hold = 0.03
        p_market = min(max(p_market, 0.02), 0.98)
        p_i = p_market * (1 + hold / 2)
        p_j = (1 - p_market) * (1 + hold / 2)
        p_i /= (p_i + p_j)
        p_j = 1 - p_i
        odds_i = 100 * (1 - p_i) / p_i if p_i < 0.5 else -100 * p_i / (1 - p_i)
        odds_j = 100 * (1 - p_j) / p_j if p_j < 0.5 else -100 * p_j / (1 - p_j)
        underdog_i = p_i < 0.5
        win_i = rng.random() < p_true
        if g < 60:
            if underdog_i:
                profits.append(american_profit(pd.Series([odds_i])).iloc[0] if win_i else -100.0)
            else:
                profits.append(american_profit(pd.Series([odds_j])).iloc[0] if not win_i else -100.0)
        signal = (1 if win_i else 0) - p_market
        market_prior[i] += update_speed * signal
        market_prior[j] -= update_speed * signal
    return float(np.mean(profits) / 100.0)


def calibration_plot(bets: pd.DataFrame) -> None:
    sample = bets.loc[bets["is_underdog"] & bets["likely_regular_season"]].copy()
    sample["window"] = np.where(sample["opening_window_3w"], "First 3 Weeks", "Rest of Season")
    sample["bin"] = pd.qcut(sample["implied_prob_novig"], q=10, duplicates="drop")
    cal = (
        sample.groupby(["window", "bin"])
        .agg(implied_prob=("implied_prob_novig", "mean"), win_rate=("win", "mean"), bets=("win", "size"))
        .reset_index()
    )
    fig, ax = plt.subplots(figsize=(10, 7))
    for window, grp in cal.groupby("window"):
        ax.plot(grp["implied_prob"], grp["win_rate"], marker="o", label=window)
    ax.plot([0, 1], [0, 1], linestyle="--", color="black", linewidth=1)
    ax.set_xlabel("No-vig implied win probability")
    ax.set_ylabel("Realized win rate")
    ax.set_title("Underdog Calibration: Implied vs Realized Win Rate")
    ax.legend(frameon=True)
    fig.tight_layout()
    fig.savefig(OUTPUT_DIR / "fig_calibration.png", dpi=200)
    plt.close(fig)


def roi_plot(strategy_results: pd.DataFrame) -> None:
    plot_df = strategy_results.loc[strategy_results["league"] != "POOLED"].copy()
    mapping = {
        "underdog_2w": "Underdog, 2 weeks",
        "underdog_3w": "Underdog, 3 weeks",
        "underdog_first5": "Underdog, first 5 games",
        "underdog_first10pct": "Underdog, first 10%",
    }
    plot_df = plot_df[plot_df["strategy"].isin(mapping)].copy()
    plot_df["strategy_label"] = plot_df["strategy"].map(mapping)
    fig, ax = plt.subplots(figsize=(12, 8))
    sns.barplot(data=plot_df, x="strategy_label", y="roi", hue="league", ax=ax)
    ax.axhline(0, color="black", linewidth=1)
    ax.set_xlabel("")
    ax.set_ylabel("ROI")
    ax.set_title("ROI by League and Early-Season Window")
    ax.tick_params(axis="x", rotation=15)
    fig.tight_layout()
    fig.savefig(OUTPUT_DIR / "fig_roi_by_window.png", dpi=200)
    plt.close(fig)


def cumulative_profit_plot(bets: pd.DataFrame) -> None:
    sample = bets.loc[bets["is_underdog"] & bets["opening_window_3w"] & bets["likely_regular_season"]].copy()
    sample = sample.sort_values(["date", "league", "season"])
    sample["cumulative_profit"] = sample["profit"].cumsum()
    fig, ax = plt.subplots(figsize=(12, 8))
    sns.lineplot(data=sample, x="date", y="cumulative_profit", hue="league", estimator=None, ax=ax)
    ax.set_xlabel("")
    ax.set_ylabel("Cumulative profit ($100 stakes)")
    ax.set_title("Cumulative Profit from Early-Season Underdogs")
    fig.tight_layout()
    fig.savefig(OUTPUT_DIR / "fig_cumulative_profit.png", dpi=200)
    plt.close(fig)


def forest_plot(model_results: pd.DataFrame) -> None:
    plot_df = model_results.loc[model_results["model_family"] == "partial_pooling_profit_3w"].copy()
    fig, ax = plt.subplots(figsize=(10, 7))
    ax.errorbar(plot_df["estimate"], plot_df["term"], xerr=1.96 * plot_df["std_error"], fmt="o", label="Raw")
    ax.scatter(plot_df["shrunk_mean"], plot_df["term"], marker="s", label="Shrunk")
    ax.axvline(0, color="black", linewidth=1)
    ax.set_xlabel("Average profit per bet ($)")
    ax.set_ylabel("")
    ax.set_title("League-Specific Early-Season Underdog Estimates")
    ax.legend(frameon=True)
    fig.tight_layout()
    fig.savefig(OUTPUT_DIR / "fig_forest_plot.png", dpi=200)
    plt.close(fig)


def write_source_memo() -> None:
    content = """# Source Memo

## Accepted primary source

### `flancast90/sportsbookreview-scraper` GitHub repository

- Coverage used here:
  - NFL `2011-2021`
  - NBA `2011-2021`
  - NHL `2011-2021`
  - MLB `2011-2021`
- Access method:
  - Direct download of public JSON archives from raw GitHub URLs.
- Odds fields:
  - Closing moneyline for all four leagues.
  - Some opening-line fields for MLB and NHL plus spread / total fields in the
    raw archives.
- Why accepted:
  - It is the cleanest public cross-league moneyline snapshot found in a single
    documented repository, and the raw files are reproducibly downloadable.
- Important limitation:
  - The live sportsbook archive endpoints referenced by the scraper are partly
    degraded in 2026, so the GitHub-hosted snapshots function as a historical
    archive rather than a guaranteed live rebuild path.

## Supplementary source checks

### SportsbookReview archive mirror

- Status:
  - Partially usable only.
- What happened:
  - MLB xlsx archive endpoints still responded during this session, but the NFL,
    NBA, and NHL HTML archive endpoints tested here returned `404`.
- Decision:
  - Rejected as the core live source for this project.

### Official league schedule / results APIs

- Status:
  - Considered as supplementary metadata sources only.
- Decision:
  - Not required for headline early-season inference because the odds archive
    already carries game dates, teams, and final scores.
- Limitation:
  - Cross-league season-type tagging remains imperfect without a harmonized
    public schedule source, so the analysis uses a conservative
    archive-derived `likely_regular_season` flag for full-season sensitivity
    checks.

## Rejected source categories

- Paid historical odds APIs:
  - Rejected because the project specification preferred public and legally
    accessible data and the current repo should remain publicly reproducible.
- Undocumented scraping targets with unclear provenance:
  - Rejected to avoid a fragile pipeline and unverifiable line history claims.
"""
    (OUTPUT_DIR / "source_memo.md").write_text(content)


def write_results_memo(strategy_results: pd.DataFrame, benchmark_results: pd.DataFrame, model_results: pd.DataFrame, coverage: pd.DataFrame) -> None:
    pooled = strategy_results[(strategy_results["league"] == "POOLED") & (strategy_results["strategy"] == "underdog_3w")].iloc[0]
    pooled_2w = strategy_results[(strategy_results["league"] == "POOLED") & (strategy_results["strategy"] == "underdog_2w")].iloc[0]
    fave_3w = benchmark_results[benchmark_results["benchmark"] == "favorites_3w"].iloc[0]
    all_dogs = benchmark_results[benchmark_results["benchmark"] == "all_underdogs"].iloc[0]
    sim_best = model_results[model_results["model_family"] == "market_learning_sim"].sort_values("estimate", ascending=False).iloc[0]
    content = f"""# Results Memo

## Coverage

- Common observed-data window: `2011-2021`.
- Leagues covered: NFL, NBA, NHL, MLB.
- League-season rows in the coverage audit: {len(coverage)}.

## Headline results

- Betting every likely-regular-season underdog in the first 2 calendar weeks
  produced pooled ROI of `{pooled_2w['roi']:.3f}` across `{int(pooled_2w['bets'])}`
  bets.
- Extending the window to the first 3 calendar weeks produced pooled ROI of
  `{pooled['roi']:.3f}` across `{int(pooled['bets'])}` bets.
- By comparison, betting all underdogs over the archive-wide season proxy
  produced ROI of `{all_dogs['roi']:.3f}`.
- Early favorites in the first 3 weeks produced ROI of `{fave_3w['roi']:.3f}`.

## Interpretation

- The key empirical question is whether early underdogs outperform their own
  implied probabilities, not simply whether underdog payouts are large.
- The model outputs and calibration diagnostics should be treated as more
  informative than a single realized ROI number because variance is large and
  the early-season sample is modest in the NFL.

## Simulation extension

- In the stylized market-learning simulation, the strongest early-underdog ROI
  arose in scenario `{sim_best['term']}` with mean simulated ROI
  `{sim_best['estimate']:.3f}`.
- The simulation is explicitly interpretive, not observed evidence.

## Remaining caveats

- Public cross-league closing-moneyline coverage beyond 2021 was not recovered
  reproducibly in this run.
- Full-season comparisons rely on a conservative archive-derived regular-season
  proxy rather than an official season-type flag.
- Any positive in-sample variant should be treated cautiously because many
  sensible windows and sub-strategies can be tested.
"""
    (OUTPUT_DIR / "results_memo.md").write_text(content)


def write_data_coverage(games: pd.DataFrame) -> pd.DataFrame:
    coverage = (
        games.groupby(["league", "season"])
        .agg(
            games=("game_id", "size"),
            start_date=("date", "min"),
            end_date=("date", "max"),
            avg_hold=("hold_raw", "mean"),
            season_mode_games=("season_mode_games", "first"),
            likely_regular_games=("likely_regular_season", "sum"),
        )
        .reset_index()
    )
    coverage["start_date"] = coverage["start_date"].dt.strftime("%Y-%m-%d")
    coverage["end_date"] = coverage["end_date"].dt.strftime("%Y-%m-%d")
    coverage.to_csv(OUTPUT_DIR / "data_coverage_table.csv", index=False)
    return coverage


def main() -> None:
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    download_if_missing()
    games = build_game_panel()
    bets = build_side_panel(games)

    games.to_parquet(OUTPUT_DIR / "game_level_panel.parquet", index=False)
    coverage = write_data_coverage(games)
    write_source_memo()

    strategy_results = compute_strategy_results(bets)
    strategy_results.to_csv(OUTPUT_DIR / "strategy_results.csv", index=False)

    benchmark_results = compute_benchmark_results(games, bets)
    benchmark_results.to_csv(OUTPUT_DIR / "benchmark_results.csv", index=False)

    model_results = compute_model_results(bets)
    model_results.to_csv(OUTPUT_DIR / "model_results.csv", index=False)

    roi_plot(strategy_results)
    cumulative_profit_plot(bets)
    calibration_plot(bets)
    forest_plot(model_results)
    write_results_memo(strategy_results, benchmark_results, model_results, coverage)

    summary = {
        "games": int(len(games)),
        "bets": int(len(bets)),
        "coverage_rows": int(len(coverage)),
    }
    (OUTPUT_DIR / "run_summary.json").write_text(json.dumps(summary, indent=2))


if __name__ == "__main__":
    main()
