"""Run the transfer-learning paper analyses with traceable, fixed-seed outputs.

This script implements the completed portions of RESEARCH_PLAN.md phases 2--5.
It deliberately keeps the three datasets separate:

* the 214-compound dataset supports general skin-permeability QSAR (4A);
* the 191-observation Yuan dataset supports microneedle permeation analyses (4B);
* the 48 cosmetic ingredients receive only 4A general-skin predictions.

All generated CSV and PNG files are written next to this script so that the
paper can cite reproducible, saved outputs rather than values in memory.
"""

from __future__ import annotations

import itertools
import sys
import warnings
from pathlib import Path

import matplotlib

matplotlib.use("Agg")

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import seaborn as sns
import shap
from scipy.special import erfc
from sklearn.ensemble import RandomForestRegressor
from sklearn.gaussian_process import GaussianProcessRegressor
from sklearn.gaussian_process.kernels import ConstantKernel, RBF, WhiteKernel
from sklearn.linear_model import LinearRegression
from sklearn.metrics import mean_absolute_error, mean_squared_error, r2_score
from sklearn.model_selection import KFold, train_test_split
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import StandardScaler
from xgboost import XGBRegressor


RANDOM_STATE = 42
SCRIPT_DIR = Path(__file__).resolve().parent

# Importing this module, rather than reimplementing its functions, is required
# for the Potts--Guy baseline and descriptor handling in this project.
sys.path.insert(0, str(SCRIPT_DIR))
from descriptors import canon_smiles, compute_descriptors, potts_guy_baseline  # noqa: E402


SKIN_DATA = SCRIPT_DIR / "skin_permeability_training_set.csv"
YUAN_DATA = SCRIPT_DIR / "yuan2023_dataset_with_descriptors.csv"
COSMETIC_DATA = SCRIPT_DIR / "cosmetic_ingredients_descriptors.csv"

DESCRIPTOR_FEATURES = [
    "MW",
    "LogP",
    "TPSA",
    "HBD",
    "HBA",
    "RotB",
    "NumRings",
    "NumAromaticRings",
    "FractionCSP3",
    "MolarRefractivity",
    "NumHeteroatoms",
]

COSMETIC_DESCRIPTOR_COLUMNS = {
    "MW": "MW_rdkit",
    "LogP": "LogP_rdkit",
    "TPSA": "TPSA_rdkit",
    "HBD": "HBD_rdkit",
    "HBA": "HBA_rdkit",
    "RotB": "RotB_rdkit",
    "NumRings": "NumRings",
    "NumAromaticRings": "NumAromaticRings",
    "FractionCSP3": "FractionCSP3",
    "MolarRefractivity": "MolarRefractivity",
    "NumHeteroatoms": "NumHeteroatoms",
}

YUAN_FEATURES = [
    "Drug loading in MN patch (µg)",
    "Drug MW (Dalton)",
    "MN Length (mm)",
    "Skin type (rat =1; human = 2)",
    "MN type (hydrogel =1; plastic = 2)",
    "MN surface area (mm2)",
    "Permeation time (hour)",
]

YUAN_TARGETS = {
    "permeation_percentage": "Drug permeation percentage",
    "permeation_amount_ug_cm2": "Drug permeation amounts (µg/cm2)",
}

YUAN_SMALL_MOLECULE_DESCRIPTOR_COLUMNS = {
    "MW": "Drug MW (Dalton)",
    "LogP": "LogP",
    "TPSA": "TPSA",
    "HBD": "HBD",
    "HBA": "HBA",
    "RotB": "RotB",
    "NumRings": "NumRings",
    "NumAromaticRings": "NumAromaticRings",
    "FractionCSP3": "FractionCSP3",
    "MolarRefractivity": "MolarRefractivity",
    "NumHeteroatoms": "NumHeteroatoms",
}

PALETTE = {
    "purple": "#440154",
    "violet": "#482878",
    "blue": "#3b528b",
    "teal": "#21918c",
    "green": "#5ec962",
    "lime": "#a0da39",
    "yellow": "#fde725",
    "grey": "#6c757d",
    "red": "#d95f02",
}


def write_csv(frame: pd.DataFrame, filename: str) -> Path:
    """Write a result table with a stable output location."""
    destination = SCRIPT_DIR / filename
    frame.to_csv(destination, index=False)
    return destination


def set_figure_style() -> None:
    """Use the clean white-background styling used by existing research figures."""
    sns.set_theme(style="white", context="talk")
    plt.rcParams.update(
        {
            "font.family": "DejaVu Sans",
            "axes.titleweight": "regular",
            "axes.labelcolor": "#202020",
            "axes.edgecolor": "#222222",
            "xtick.color": "#222222",
            "ytick.color": "#222222",
            "figure.facecolor": "white",
            "axes.facecolor": "white",
        }
    )


def save_figure(figure: plt.Figure, filename: str) -> None:
    figure.savefig(SCRIPT_DIR / filename, dpi=300, bbox_inches="tight")
    plt.close(figure)


def metrics(y_true: np.ndarray | pd.Series, y_pred: np.ndarray | pd.Series) -> dict[str, float]:
    """Return regression metrics after excluding any non-finite pair."""
    observed = np.asarray(y_true, dtype=float)
    predicted = np.asarray(y_pred, dtype=float)
    valid = np.isfinite(observed) & np.isfinite(predicted)
    observed = observed[valid]
    predicted = predicted[valid]
    if len(observed) == 0:
        return {"n": 0, "r2": np.nan, "rmse": np.nan, "mae": np.nan}
    return {
        "n": int(len(observed)),
        "r2": float(r2_score(observed, predicted)) if len(observed) > 1 else np.nan,
        "rmse": float(np.sqrt(mean_squared_error(observed, predicted))),
        "mae": float(mean_absolute_error(observed, predicted)),
    }


def metric_rows_from_predictions(
    predictions: pd.DataFrame,
    group_columns: list[str],
    fold_column: str | None = None,
) -> pd.DataFrame:
    """Summarize saved prediction rows without using any unsaved in-memory metric."""
    rows: list[dict[str, object]] = []
    for group_key, group in predictions.groupby(group_columns, dropna=False):
        if not isinstance(group_key, tuple):
            group_key = (group_key,)
        record = dict(zip(group_columns, group_key))
        overall = metrics(group["observed"], group["predicted"])
        record.update(
            {
                "n_observations": overall["n"],
                "pooled_r2": overall["r2"],
                "pooled_rmse": overall["rmse"],
                "pooled_mae": overall["mae"],
            }
        )
        if fold_column is not None:
            fold_values = [
                metrics(fold["observed"], fold["predicted"])
                for _, fold in group.groupby(fold_column, dropna=False)
            ]
            for name in ("r2", "rmse", "mae"):
                values = np.array([value[name] for value in fold_values], dtype=float)
                record[f"mean_fold_{name}"] = float(np.nanmean(values))
                record[f"sd_fold_{name}"] = float(np.nanstd(values, ddof=1))
            record["n_folds"] = int(len(fold_values))
        rows.append(record)
    return pd.DataFrame(rows)


def cosmetics_as_descriptor_frame(cosmetics: pd.DataFrame) -> pd.DataFrame:
    """Map the established cosmetic descriptor names to the 4A feature schema."""
    return pd.DataFrame(
        {feature: cosmetics[source].astype(float) for feature, source in COSMETIC_DESCRIPTOR_COLUMNS.items()}
    )


def yuan_small_molecules_as_descriptor_frame(yuan: pd.DataFrame) -> pd.DataFrame:
    """Map Yuan's RDKit columns to the independently trained 4A descriptor schema."""
    subset = yuan.loc[yuan["is_small_molecule"]].copy()
    missing = [
        source
        for source in YUAN_SMALL_MOLECULE_DESCRIPTOR_COLUMNS.values()
        if subset[source].isna().any()
    ]
    if missing:
        raise ValueError(f"Small-molecule Yuan rows unexpectedly lack descriptor values: {missing}")
    return pd.DataFrame(
        {
            feature: subset[source].astype(float)
            for feature, source in YUAN_SMALL_MOLECULE_DESCRIPTOR_COLUMNS.items()
        },
        index=subset.index,
    )


def leverage_values(reference: np.ndarray, query: np.ndarray) -> tuple[np.ndarray, np.ndarray, float]:
    """Calculate Williams-plot leverage on standardized descriptors with an intercept."""
    scaler = StandardScaler().fit(reference)
    reference_scaled = scaler.transform(reference)
    query_scaled = scaler.transform(query)
    reference_design = np.column_stack([np.ones(len(reference_scaled)), reference_scaled])
    query_design = np.column_stack([np.ones(len(query_scaled)), query_scaled])
    inverse_xtx = np.linalg.pinv(reference_design.T @ reference_design)
    reference_leverage = np.einsum(
        "ij,jk,ik->i", reference_design, inverse_xtx, reference_design
    )
    query_leverage = np.einsum("ij,jk,ik->i", query_design, inverse_xtx, query_design)
    threshold = 3 * (reference.shape[1] + 1) / len(reference)
    return reference_leverage, query_leverage, float(threshold)


def run_phase_2_curation(skin: pd.DataFrame) -> None:
    """Check input integrity, descriptor consistency, duplicates, and statistical flags."""
    target = skin["logKp_cm_h"].astype(float)
    q1, q3 = target.quantile([0.25, 0.75])
    iqr = q3 - q1
    iqr_low = q1 - 1.5 * iqr
    iqr_high = q3 + 1.5 * iqr
    z_scores = (target - target.mean()) / target.std(ddof=0)
    leverage, _, leverage_threshold = leverage_values(
        skin[DESCRIPTOR_FEATURES].to_numpy(dtype=float),
        skin[DESCRIPTOR_FEATURES].to_numpy(dtype=float),
    )

    check_rows: list[dict[str, object]] = []
    for row_index, row in skin.iterrows():
        canonical = canon_smiles(row["canon_smiles"])
        calculated = compute_descriptors(row["canon_smiles"])
        if calculated is None:
            descriptor_difference = np.nan
            descriptor_matches = False
        else:
            descriptor_difference = max(
                abs(float(row[feature]) - float(calculated[feature]))
                for feature in DESCRIPTOR_FEATURES
            )
            descriptor_matches = bool(descriptor_difference <= 1e-6)
        check_rows.append(
            {
                "row_index": int(row_index),
                "canon_smiles": row["canon_smiles"],
                "logKp_cm_h": float(row["logKp_cm_h"]),
                "canonical_smiles_reparsed": canonical,
                "canonical_smiles_matches": bool(canonical == row["canon_smiles"]),
                "descriptor_max_abs_difference": descriptor_difference,
                "descriptor_values_match": descriptor_matches,
                "target_iqr_outlier": bool(
                    row["logKp_cm_h"] < iqr_low or row["logKp_cm_h"] > iqr_high
                ),
                "target_zscore": float(z_scores.loc[row_index]),
                "target_abs_zscore_gt_3": bool(abs(z_scores.loc[row_index]) > 3),
                "descriptor_leverage": float(leverage[row_index]),
                "descriptor_leverage_outlier": bool(leverage[row_index] > leverage_threshold),
            }
        )
    checks = pd.DataFrame(check_rows)
    checks["any_statistical_flag"] = (
        checks["target_iqr_outlier"]
        | checks["target_abs_zscore_gt_3"]
        | checks["descriptor_leverage_outlier"]
    )
    write_csv(checks, "phase2_curation_checks.csv")

    duplicate_summary = (
        skin.groupby("canon_smiles", as_index=False)
        .agg(
            n_rows=("logKp_cm_h", "size"),
            min_logKp_cm_h=("logKp_cm_h", "min"),
            max_logKp_cm_h=("logKp_cm_h", "max"),
            mean_logKp_cm_h=("logKp_cm_h", "mean"),
        )
        .query("n_rows > 1")
    )
    if duplicate_summary.empty:
        duplicate_summary = pd.DataFrame(
            columns=[
                "canon_smiles",
                "n_rows",
                "min_logKp_cm_h",
                "max_logKp_cm_h",
                "mean_logKp_cm_h",
                "outcome_range_logKp_cm_h",
                "conflicting_outcomes",
            ]
        )
    else:
        duplicate_summary["outcome_range_logKp_cm_h"] = (
            duplicate_summary["max_logKp_cm_h"] - duplicate_summary["min_logKp_cm_h"]
        )
        duplicate_summary["conflicting_outcomes"] = (
            duplicate_summary["outcome_range_logKp_cm_h"] > 1e-6
        )
    write_csv(duplicate_summary, "phase2_duplicate_smiles.csv")

    raw_candidates = [
        path.name
        for path in SCRIPT_DIR.rglob("*")
        if path.is_file()
        and path.name != SKIN_DATA.name
        and any(token in path.name.lower() for token in ("huskindb", "skinpix", "inrs"))
    ]
    summary = pd.DataFrame(
        [
            ("n_experimental_compounds", len(skin), "Input dataset row count."),
            ("n_missing_values", int(skin.isna().sum().sum()), "All input columns."),
            ("n_duplicate_canon_smiles", int(skin["canon_smiles"].duplicated().sum()), "Exact canonical SMILES."),
            ("n_duplicate_groups", len(duplicate_summary), "Groups with more than one row."),
            ("n_iqr_target_outliers", int(checks["target_iqr_outlier"].sum()), "1.5×IQR rule."),
            ("n_abs_zscore_gt_3", int(checks["target_abs_zscore_gt_3"].sum()), "Population z-score threshold."),
            ("n_descriptor_leverage_outliers", int(checks["descriptor_leverage_outlier"].sum()), "Williams threshold."),
            ("n_any_statistical_flag", int(checks["any_statistical_flag"].sum()), "Union of the three flags."),
            ("n_smiles_reparse_mismatches", int((~checks["canonical_smiles_matches"]).sum()), "RDKit canonicalization check."),
            ("n_descriptor_mismatches", int((~checks["descriptor_values_match"]).sum()), "Maximum absolute difference > 1e-6."),
            ("target_iqr_lower", float(iqr_low), "logKp_cm_h."),
            ("target_iqr_upper", float(iqr_high), "logKp_cm_h."),
            ("leverage_threshold", leverage_threshold, "3(p+1)/n with p=11 descriptors."),
            ("raw_huskindb_skinpix_files_found", len(raw_candidates), "; ".join(raw_candidates) or "None under research/."),
        ],
        columns=["metric", "value", "details"],
    )
    write_csv(summary, "phase2_curation_summary.csv")


def calculate_vif(frame: pd.DataFrame) -> pd.DataFrame:
    """Calculate VIF without adding an undeclared statsmodels dependency."""
    values = frame.to_numpy(dtype=float)
    records = []
    for index, feature in enumerate(frame.columns):
        response = values[:, index]
        predictors = np.delete(values, index, axis=1)
        model = LinearRegression().fit(predictors, response)
        r_squared = float(model.score(predictors, response))
        vif = np.inf if np.isclose(1 - r_squared, 0) else 1 / (1 - r_squared)
        records.append(
            {
                "descriptor": feature,
                "r2_from_other_descriptors": r_squared,
                "vif": float(vif),
            }
        )
    return pd.DataFrame(records).sort_values("vif", ascending=False, ignore_index=True)


def run_phase_3_eda(skin: pd.DataFrame, cosmetics: pd.DataFrame) -> None:
    """Write distribution, correlation/VIF, and explicitly heuristic cosmetic EDA."""
    target_summary = skin["logKp_cm_h"].describe().rename_axis("statistic").reset_index(name="value")
    target_summary.insert(0, "analysis", "experimental_skin_logKp_distribution")
    write_csv(target_summary, "phase3_eda_summary.csv")

    correlation = skin[DESCRIPTOR_FEATURES].corr()
    correlation_out = correlation.reset_index().rename(columns={"index": "descriptor"})
    write_csv(correlation_out, "phase3_descriptor_correlation.csv")
    vif = calculate_vif(skin[DESCRIPTOR_FEATURES])
    write_csv(vif, "phase3_vif.csv")

    cosmetic_eda = cosmetics[
        ["ingredient", "category", "MW_rdkit", "LogP_rdkit", "logKp_PottsGuy_baseline"]
    ].copy()
    cosmetic_eda["potts_guy_recomputed"] = [
        potts_guy_baseline(logp, mw)
        for logp, mw in zip(cosmetic_eda["LogP_rdkit"], cosmetic_eda["MW_rdkit"])
    ]
    cosmetic_eda["potts_guy_existing_minus_recomputed"] = (
        cosmetic_eda["logKp_PottsGuy_baseline"] - cosmetic_eda["potts_guy_recomputed"]
    )
    median_logp = float(cosmetic_eda["LogP_rdkit"].median())
    cosmetic_eda["logp_group_by_dataset_median"] = np.where(
        cosmetic_eda["LogP_rdkit"] <= median_logp,
        "lower_LogP_half",
        "higher_LogP_half",
    )
    cosmetic_eda["logp_group_threshold"] = median_logp
    write_csv(cosmetic_eda, "phase3_cosmetic_eda.csv")

    set_figure_style()
    figure, axes = plt.subplots(1, 3, figsize=(22, 6.5), gridspec_kw={"width_ratios": [1, 1.35, 0.8]})
    sns.histplot(
        data=skin,
        x="logKp_cm_h",
        bins=18,
        kde=True,
        color=PALETTE["purple"],
        ax=axes[0],
    )
    axes[0].axvline(skin["logKp_cm_h"].median(), color=PALETTE["yellow"], lw=2, label="median")
    axes[0].set_title("Experimental skin-permeability distribution")
    axes[0].set_xlabel("log Kp (cm/h)")
    axes[0].set_ylabel("Compounds (n)")
    axes[0].legend(frameon=False)
    sns.heatmap(
        correlation,
        cmap="vlag",
        center=0,
        vmin=-1,
        vmax=1,
        square=True,
        cbar_kws={"label": "Pearson r"},
        ax=axes[1],
    )
    axes[1].set_title("Descriptor correlation matrix")
    axes[1].tick_params(axis="x", rotation=55, labelsize=8)
    axes[1].tick_params(axis="y", rotation=0, labelsize=8)
    vif_plot = vif.sort_values("vif", ascending=True)
    axes[2].barh(vif_plot["descriptor"], vif_plot["vif"], color=PALETTE["teal"])
    axes[2].axvline(5, color=PALETTE["red"], lw=1.5, ls="--", label="VIF = 5")
    axes[2].set_title("Multicollinearity diagnostic")
    axes[2].set_xlabel("VIF")
    axes[2].legend(frameon=False, fontsize=10)
    sns.despine(fig=figure)
    figure.tight_layout()
    save_figure(figure, "fig_transfer_phase3_eda.png")

    set_figure_style()
    ordered_categories = (
        cosmetic_eda.groupby("category")["potts_guy_recomputed"].median().sort_values().index.tolist()
    )
    figure, axes = plt.subplots(1, 2, figsize=(21, 8), gridspec_kw={"width_ratios": [1.35, 0.8]})
    sns.stripplot(
        data=cosmetic_eda,
        x="potts_guy_recomputed",
        y="category",
        hue="logp_group_by_dataset_median",
        order=ordered_categories,
        palette={"lower_LogP_half": PALETTE["blue"], "higher_LogP_half": PALETTE["yellow"]},
        size=8,
        jitter=0.16,
        ax=axes[0],
    )
    axes[0].set_title("Cosmetic ingredients: Potts–Guy heuristic by category")
    axes[0].set_xlabel("Potts–Guy log Kp estimate (cm/h)")
    axes[0].set_ylabel("")
    axes[0].legend(title=f"LogP group (median = {median_logp:.2f})", frameon=False)
    sns.boxplot(
        data=cosmetic_eda,
        x="logp_group_by_dataset_median",
        y="potts_guy_recomputed",
        palette={"lower_LogP_half": PALETTE["blue"], "higher_LogP_half": PALETTE["yellow"]},
        ax=axes[1],
    )
    sns.stripplot(
        data=cosmetic_eda,
        x="logp_group_by_dataset_median",
        y="potts_guy_recomputed",
        color="#202020",
        size=5,
        jitter=0.08,
        ax=axes[1],
    )
    axes[1].set_title("Lower vs higher LogP halves")
    axes[1].set_xlabel("")
    axes[1].set_ylabel("Potts–Guy log Kp estimate (cm/h)")
    sns.despine(fig=figure)
    figure.tight_layout()
    save_figure(figure, "fig_transfer_phase3_cosmetic_eda.png")


def make_4a_model(model_name: str):
    """Instantiate one non-baseline 4A model with fixed, documented settings."""
    if model_name == "MLR":
        return Pipeline([("scaler", StandardScaler()), ("model", LinearRegression())])
    if model_name == "RandomForest":
        return RandomForestRegressor(
            n_estimators=500,
            max_features=1.0,
            min_samples_leaf=1,
            random_state=RANDOM_STATE,
            n_jobs=1,
        )
    if model_name == "XGBoost":
        return XGBRegressor(
            objective="reg:squarederror",
            n_estimators=400,
            learning_rate=0.03,
            max_depth=3,
            min_child_weight=2,
            subsample=0.9,
            colsample_bytree=0.9,
            reg_lambda=1.0,
            random_state=RANDOM_STATE,
            n_jobs=1,
            tree_method="hist",
        )
    if model_name == "GaussianProcess":
        kernel = ConstantKernel(1.0, (1e-3, 1e3)) * RBF(
            length_scale=np.ones(len(DESCRIPTOR_FEATURES)), length_scale_bounds=(1e-2, 1e3)
        ) + WhiteKernel(noise_level=0.1, noise_level_bounds=(1e-8, 1e2))
        return Pipeline(
            [
                ("scaler", StandardScaler()),
                (
                    "model",
                    GaussianProcessRegressor(
                        kernel=kernel,
                        alpha=0.0,
                        normalize_y=True,
                        n_restarts_optimizer=3,
                        random_state=RANDOM_STATE,
                    ),
                ),
            ]
        )
    raise ValueError(f"Unknown 4A model: {model_name}")


def run_phase_4a(skin: pd.DataFrame, cosmetics: pd.DataFrame):
    """Fit 5-fold QSAR models and calculate both simple and leverage AD flags."""
    X = skin[DESCRIPTOR_FEATURES].copy()
    y = skin["logKp_cm_h"].astype(float).to_numpy()
    kfold = KFold(n_splits=5, shuffle=True, random_state=RANDOM_STATE)
    folds = list(kfold.split(X))
    fitted_names = ["MLR", "RandomForest", "XGBoost", "GaussianProcess"]
    prediction_rows: list[dict[str, object]] = []

    for fold, (_, test_indices) in enumerate(folds, start=1):
        test = skin.iloc[test_indices]
        for row_index, row in test.iterrows():
            prediction_rows.append(
                {
                    "row_index": int(row_index),
                    "fold": fold,
                    "model": "Potts-Guy",
                    "observed": float(row["logKp_cm_h"]),
                    "predicted": float(potts_guy_baseline(row["LogP"], row["MW"])),
                }
            )

    for model_name in fitted_names:
        for fold, (train_indices, test_indices) in enumerate(folds, start=1):
            model = make_4a_model(model_name)
            model.fit(X.iloc[train_indices], y[train_indices])
            predicted = model.predict(X.iloc[test_indices])
            for row_index, value in zip(test_indices, predicted):
                prediction_rows.append(
                    {
                        "row_index": int(row_index),
                        "fold": fold,
                        "model": model_name,
                        "observed": float(y[row_index]),
                        "predicted": float(value),
                    }
                )

    cv_predictions = pd.DataFrame(prediction_rows).sort_values(["model", "row_index"], ignore_index=True)
    write_csv(cv_predictions, "phase4a_cv_predictions.csv")
    performance = metric_rows_from_predictions(cv_predictions, ["model"], fold_column="fold")
    performance.insert(0, "dataset", "214 experimental skin-permeability compounds")
    performance.insert(1, "validation", "5-fold shuffled cross-validation")
    write_csv(performance, "phase4a_model_performance.csv")

    learned_performance = performance.loc[performance["model"].isin(fitted_names)].copy()
    best_model_name = learned_performance.sort_values(
        ["pooled_rmse", "pooled_r2"], ascending=[True, False]
    ).iloc[0]["model"]
    final_selection = pd.DataFrame(
        [
            {
                "selected_fitted_model": best_model_name,
                "selection_rule": "Lowest pooled 5-fold OOF RMSE among fitted ML models; R2 breaks ties.",
                "random_state": RANDOM_STATE,
            }
        ]
    )
    write_csv(final_selection, "phase4a_final_model_selection.csv")
    final_model = make_4a_model(str(best_model_name))
    final_model.fit(X, y)

    X_cosmetic = cosmetics_as_descriptor_frame(cosmetics)
    train_leverage, cosmetic_leverage, leverage_threshold = leverage_values(
        X.to_numpy(dtype=float), X_cosmetic.to_numpy(dtype=float)
    )
    training_ad = pd.DataFrame(
        {
            "record_set": "experimental_training_214",
            "record_id": skin.index.astype(int),
            "name": skin["canon_smiles"].to_numpy(),
            "MW": skin["MW"].to_numpy(),
            "LogP": skin["LogP"].to_numpy(),
            "leverage": train_leverage,
            "leverage_threshold": leverage_threshold,
            "in_leverage_domain": train_leverage <= leverage_threshold,
            "in_simple_MW_LogP_range": True,
        }
    )
    cosmetics_ad = pd.DataFrame(
        {
            "record_set": "cosmetic_48",
            "record_id": cosmetics.index.astype(int),
            "name": cosmetics["ingredient"].to_numpy(),
            "MW": cosmetics["MW_rdkit"].to_numpy(),
            "LogP": cosmetics["LogP_rdkit"].to_numpy(),
            "leverage": cosmetic_leverage,
            "leverage_threshold": leverage_threshold,
            "in_leverage_domain": cosmetic_leverage <= leverage_threshold,
            "in_simple_MW_LogP_range": (
                cosmetics["in_MW_domain"].astype(bool).to_numpy()
                & cosmetics["in_LogP_domain"].astype(bool).to_numpy()
            ),
        }
    )
    applicability = pd.concat([training_ad, cosmetics_ad], ignore_index=True)
    write_csv(applicability, "phase4a_applicability_domain.csv")
    comparison = cosmetics_ad.copy()
    comparison["existing_in_MW_domain"] = cosmetics["in_MW_domain"].astype(bool).to_numpy()
    comparison["existing_in_LogP_domain"] = cosmetics["in_LogP_domain"].astype(bool).to_numpy()
    comparison["domain_flags_agree"] = (
        comparison["in_leverage_domain"] == comparison["in_simple_MW_LogP_range"]
    )
    comparison["range_inside_but_leverage_outside"] = (
        comparison["in_simple_MW_LogP_range"] & ~comparison["in_leverage_domain"]
    )
    comparison["range_outside_but_leverage_inside"] = (
        ~comparison["in_simple_MW_LogP_range"] & comparison["in_leverage_domain"]
    )
    write_csv(comparison, "phase4a_ad_comparison.csv")

    set_figure_style()
    figure, axes = plt.subplots(1, 2, figsize=(18, 7))
    plot_performance = performance.sort_values("pooled_r2", ascending=True)
    colors = [
        PALETTE["purple"] if name == "Potts-Guy" else PALETTE["blue"]
        for name in plot_performance["model"]
    ]
    axes[0].barh(plot_performance["model"], plot_performance["pooled_r2"], color=colors)
    axes[0].axvline(0, color="#222222", lw=1)
    axes[0].set_title("4A: 5-fold out-of-fold performance")
    axes[0].set_xlabel("Pooled out-of-fold R²")
    selected_predictions = cv_predictions.loc[cv_predictions["model"] == best_model_name]
    axes[1].scatter(
        selected_predictions["observed"],
        selected_predictions["predicted"],
        s=45,
        alpha=0.78,
        color=PALETTE["teal"],
        edgecolor="white",
        linewidth=0.4,
    )
    lower = min(selected_predictions["observed"].min(), selected_predictions["predicted"].min())
    upper = max(selected_predictions["observed"].max(), selected_predictions["predicted"].max())
    axes[1].plot([lower, upper], [lower, upper], color=PALETTE["red"], lw=1.5, ls="--")
    selected_metrics = performance.loc[performance["model"] == best_model_name].iloc[0]
    axes[1].text(
        0.03,
        0.97,
        f"Selected fitted model: {best_model_name}\nR² = {selected_metrics['pooled_r2']:.3f}\nRMSE = {selected_metrics['pooled_rmse']:.3f}",
        transform=axes[1].transAxes,
        va="top",
        fontsize=12,
        bbox={"facecolor": "white", "edgecolor": "none", "alpha": 0.85},
    )
    axes[1].set_title("Selected 4A model: out-of-fold predictions")
    axes[1].set_xlabel("Observed log Kp (cm/h)")
    axes[1].set_ylabel("Out-of-fold predicted log Kp (cm/h)")
    sns.despine(fig=figure)
    figure.tight_layout()
    save_figure(figure, "fig_transfer_phase4a_performance.png")

    return final_model, str(best_model_name), X, y, X_cosmetic, cv_predictions, performance, cosmetics_ad


def fixed_fick_proxy(frame: pd.DataFrame) -> pd.DataFrame:
    """Return an explicit Fick-second-law proxy for Yuan data.

    SI2 supplies a finite-difference Fick solver but does not provide the
    drug-specific diffusion coefficients or complete per-row geometries needed
    to re-run it for all 191 rows.  This no-fit analytical proxy therefore uses
    the original article's 1 mm skin-thickness assumption and a transparent
    MW-scaled diffusion coefficient.  It is retained as a physical baseline,
    not represented as an exact rerun of Yuan et al.'s C solver.
    """
    mw = frame["Drug MW (Dalton)"].to_numpy(dtype=float)
    # 700 µm²/min is the illustrative SI2 coefficient. The MW^(-1/3) scaling
    # is a Stokes--Einstein-inspired molecular-size proxy and the published
    # 50--1000 µm²/min range bounds the values.
    diffusion_um2_min = np.clip(700.0 * (234.34 / mw) ** (1 / 3), 50.0, 1000.0)
    diffusion_mm2_h = diffusion_um2_min * 60.0e-6
    residual_skin_mm = np.maximum(1.0 - frame["MN Length (mm)"].to_numpy(dtype=float), 0.05)
    time_h = np.maximum(frame["Permeation time (hour)"].to_numpy(dtype=float), 1e-8)
    fraction = erfc(residual_skin_mm / (2 * np.sqrt(diffusion_mm2_h * time_h)))
    fraction = np.clip(fraction, 0.0, 1.0)
    percentage = 100.0 * fraction
    amount = frame["Drug loading in MN patch (µg)"].to_numpy(dtype=float) * fraction
    return pd.DataFrame(
        {
            "fick_proxy_diffusion_um2_min": diffusion_um2_min,
            "fick_proxy_residual_skin_mm": residual_skin_mm,
            "fick_proxy_fraction": fraction,
            "predicted_permeation_percentage": percentage,
            "predicted_permeation_amount_ug_cm2": amount,
        },
        index=frame.index,
    )


def make_yuan_model(model_name: str, target_key: str):
    """Instantiate models using the Yuan paper's stated split-model settings."""
    if model_name == "MLR":
        # Yuan's Data S2 uses Results ~ . - 1, i.e. no fitted intercept.
        return LinearRegression(fit_intercept=False)
    if model_name == "RandomForest":
        max_features = 5 if target_key == "permeation_amount_ug_cm2" else 6
        return RandomForestRegressor(
            n_estimators=500,
            max_features=max_features,
            random_state=RANDOM_STATE,
            n_jobs=1,
        )
    if model_name == "XGBoost":
        if target_key == "permeation_amount_ug_cm2":
            parameters = {"max_depth": 4, "learning_rate": 0.4, "n_estimators": 100}
        else:
            parameters = {"max_depth": 3, "learning_rate": 0.2, "n_estimators": 45}
        return XGBRegressor(
            objective="reg:squarederror",
            random_state=RANDOM_STATE,
            n_jobs=1,
            tree_method="hist",
            **parameters,
        )
    raise ValueError(f"Unknown Yuan fitted model: {model_name}")


def yuan_model_hyperparameters() -> pd.DataFrame:
    """Save settings used for every Yuan model so the random-split difference is explicit."""
    return pd.DataFrame(
        [
            {
                "model": "Fick_diffusion_proxy",
                "target": "both",
                "parameters": "Analytical erfc proxy; 1 mm skin; MW^(-1/3) D; D clipped 50--1000 µm²/min; no fitted parameters.",
            },
            {
                "model": "MLR",
                "target": "both",
                "parameters": "LinearRegression(fit_intercept=False), matching SI2 Results ~ . - 1.",
            },
            {
                "model": "RandomForest",
                "target": "amount",
                "parameters": "n_estimators=500, max_features=5, random_state=42.",
            },
            {
                "model": "RandomForest",
                "target": "percentage",
                "parameters": "n_estimators=500, max_features=6, random_state=42.",
            },
            {
                "model": "XGBoost",
                "target": "amount",
                "parameters": "max_depth=4, learning_rate=0.4, n_estimators=100, random_state=42.",
            },
            {
                "model": "XGBoost",
                "target": "percentage",
                "parameters": "max_depth=3, learning_rate=0.2, n_estimators=45, random_state=42.",
            },
        ]
    )


def run_yuan_random_split(yuan: pd.DataFrame) -> tuple[pd.DataFrame, pd.DataFrame]:
    """Reproduce Yuan's published 70:30 random-split evaluation as closely as data permit."""
    indices = np.arange(len(yuan))
    train_indices, test_indices = train_test_split(
        indices, test_size=0.30, random_state=RANDOM_STATE, shuffle=True
    )
    prediction_rows: list[dict[str, object]] = []
    fick_all = fixed_fick_proxy(yuan)
    for target_key, target_column in YUAN_TARGETS.items():
        for model_name in ("Fick_diffusion_proxy", "MLR", "RandomForest", "XGBoost"):
            if model_name == "Fick_diffusion_proxy":
                prediction = fick_all[
                    "predicted_permeation_percentage"
                    if target_key == "permeation_percentage"
                    else "predicted_permeation_amount_ug_cm2"
                ].iloc[test_indices].to_numpy()
            else:
                model = make_yuan_model(model_name, target_key)
                model.fit(yuan.iloc[train_indices][YUAN_FEATURES], yuan.iloc[train_indices][target_column])
                prediction = model.predict(yuan.iloc[test_indices][YUAN_FEATURES])
            for row_index, value in zip(test_indices, prediction):
                prediction_rows.append(
                    {
                        "row_index": int(row_index),
                        "drug_name": yuan.iloc[row_index]["Drug name"],
                        "target": target_key,
                        "model": model_name,
                        "validation": "random_70_30_test",
                        "observed": float(yuan.iloc[row_index][target_column]),
                        "predicted": float(value),
                    }
                )
    predictions = pd.DataFrame(prediction_rows)
    write_csv(predictions, "phase4b_random_split_predictions.csv")
    performance = metric_rows_from_predictions(predictions, ["target", "model"])
    performance.insert(0, "dataset", "Yuan 2023 reconstructed 191 observations")
    performance.insert(1, "validation", "70:30 random split, random_state=42")
    performance["n_train_experimental"] = len(train_indices)
    performance["n_test_experimental"] = len(test_indices)
    write_csv(performance, "phase4b_random_split_performance.csv")

    fick_parameters = pd.concat(
        [
            yuan[["Drug name", "Drug MW (Dalton)", "MN Length (mm)", "Permeation time (hour)"]],
            fick_all,
        ],
        axis=1,
    )
    fick_parameters.insert(0, "row_index", yuan.index.astype(int))
    write_csv(fick_parameters, "phase4b_fick_proxy_parameters.csv")
    write_csv(yuan_model_hyperparameters(), "phase4b_model_hyperparameters.csv")
    return predictions, performance


def lodo_prediction_rows(
    frame: pd.DataFrame,
    feature_columns: list[str],
    model_names: list[str],
    variant: str,
    include_fick_proxy: bool = False,
) -> pd.DataFrame:
    """Run honest leave-one-drug-out folds using all other rows for each training fold."""
    rows: list[dict[str, object]] = []
    fick_all = fixed_fick_proxy(frame) if include_fick_proxy else None
    for held_out_drug in sorted(frame["Drug name"].unique()):
        test_mask = frame["Drug name"] == held_out_drug
        training = frame.loc[~test_mask]
        test = frame.loc[test_mask]
        for target_key, target_column in YUAN_TARGETS.items():
            for model_name in model_names:
                if model_name == "Fick_diffusion_proxy":
                    if fick_all is None:
                        raise ValueError("Fick proxy requested without precomputation")
                    prediction = fick_all.loc[test.index, [
                        "predicted_permeation_percentage"
                        if target_key == "permeation_percentage"
                        else "predicted_permeation_amount_ug_cm2"
                    ]].to_numpy().ravel()
                else:
                    model = make_yuan_model(model_name, target_key)
                    model.fit(training[feature_columns], training[target_column])
                    prediction = model.predict(test[feature_columns])
                for row_index, observed, predicted in zip(test.index, test[target_column], prediction):
                    rows.append(
                        {
                            "row_index": int(row_index),
                            "variant": variant,
                            "held_out_drug": held_out_drug,
                            "model": model_name,
                            "target": target_key,
                            "n_train_experimental": int(len(training)),
                            "n_test_experimental": int(len(test)),
                            "observed": float(observed),
                            "predicted": float(predicted),
                        }
                    )
    return pd.DataFrame(rows)


def run_yuan_lodo(yuan: pd.DataFrame) -> tuple[pd.DataFrame, pd.DataFrame, pd.DataFrame]:
    """Run the required six-drug LODO evaluation for all four reproduction methods."""
    predictions = lodo_prediction_rows(
        yuan,
        YUAN_FEATURES,
        ["Fick_diffusion_proxy", "MLR", "RandomForest", "XGBoost"],
        variant="seven_feature_all_six_drugs",
        include_fick_proxy=True,
    )
    write_csv(predictions, "phase4b_lodo_predictions.csv")
    aggregate = metric_rows_from_predictions(
        predictions, ["variant", "target", "model"], fold_column="held_out_drug"
    )
    aggregate.insert(0, "dataset", "Yuan 2023 reconstructed 191 observations")
    aggregate.insert(1, "validation", "leave-one-drug-out")
    write_csv(aggregate, "phase4b_lodo_performance.csv")
    fold_metrics = metric_rows_from_predictions(
        predictions,
        ["variant", "target", "model", "held_out_drug"],
        fold_column=None,
    )
    fold_metrics.insert(0, "validation", "leave-one-drug-out fold")
    write_csv(fold_metrics, "phase4b_lodo_fold_metrics.csv")
    return predictions, aggregate, fold_metrics


def run_transfer_learning(
    yuan: pd.DataFrame,
    final_4a_model,
) -> tuple[pd.DataFrame, pd.DataFrame, pd.DataFrame]:
    """Add the source-domain general-skin prediction for only the four valid molecules."""
    small = yuan.loc[yuan["is_small_molecule"]].copy()
    small_descriptor_frame = yuan_small_molecules_as_descriptor_frame(yuan)
    general_prediction = final_4a_model.predict(small_descriptor_frame[DESCRIPTOR_FEATURES])
    small["predicted_general_skin_logKp"] = general_prediction
    transfer_features = small[
        [
            "Drug name",
            "is_small_molecule",
            "Drug loading in MN patch (µg)",
            "Drug MW (Dalton)",
            "MN Length (mm)",
            "Skin type (rat =1; human = 2)",
            "MN type (hydrogel =1; plastic = 2)",
            "MN surface area (mm2)",
            "Permeation time (hour)",
            "predicted_general_skin_logKp",
        ]
    ].copy()
    transfer_features.insert(0, "row_index", small.index.astype(int))
    transfer_features["exclusion_note"] = "BSA and copper ions are not in this table because RDKit descriptors are structurally inapplicable."
    write_csv(transfer_features, "phase4b_transfer_features.csv")

    baseline_predictions = lodo_prediction_rows(
        small,
        YUAN_FEATURES,
        ["MLR", "RandomForest", "XGBoost"],
        variant="seven_feature_small_molecules_only",
        include_fick_proxy=False,
    )
    transfer_feature_columns = [*YUAN_FEATURES, "predicted_general_skin_logKp"]
    transfer_predictions = lodo_prediction_rows(
        small,
        transfer_feature_columns,
        ["MLR", "RandomForest", "XGBoost"],
        variant="eight_feature_transfer_small_molecules_only",
        include_fick_proxy=False,
    )
    predictions = pd.concat([baseline_predictions, transfer_predictions], ignore_index=True)
    write_csv(predictions, "phase4b_transfer_lodo_predictions.csv")
    performance = metric_rows_from_predictions(
        predictions, ["variant", "target", "model"], fold_column="held_out_drug"
    )
    performance.insert(0, "dataset", "Yuan small-molecule subset (four drugs only)")
    performance.insert(1, "validation", "leave-one-drug-out")
    performance["n_drugs"] = 4
    performance["excluded_drugs"] = "BSA; copper ions"
    write_csv(performance, "phase4b_transfer_lodo_performance.csv")
    return transfer_features, predictions, performance


def run_bias_mitigation(yuan: pd.DataFrame, baseline_lodo_predictions: pd.DataFrame) -> tuple[pd.DataFrame, pd.DataFrame]:
    """Quantify loading reliance and test a percentage-first model without loading as a learned input."""
    amount_target = YUAN_TARGETS["permeation_amount_ug_cm2"]
    percentage_target = YUAN_TARGETS["permeation_percentage"]
    full_baseline = make_yuan_model("XGBoost", "permeation_amount_ug_cm2")
    full_baseline.fit(yuan[YUAN_FEATURES], yuan[amount_target])
    baseline_importance = np.asarray(full_baseline.feature_importances_, dtype=float)
    baseline_importance = baseline_importance / baseline_importance.sum()

    no_loading_features = [feature for feature in YUAN_FEATURES if feature != "Drug loading in MN patch (µg)"]
    mitigation_model = XGBRegressor(
        objective="reg:squarederror",
        n_estimators=100,
        learning_rate=0.2,
        max_depth=2,
        min_child_weight=2,
        reg_lambda=5.0,
        subsample=0.9,
        colsample_bytree=0.9,
        random_state=RANDOM_STATE,
        n_jobs=1,
        tree_method="hist",
    )
    mitigation_model.fit(yuan[no_loading_features], yuan[percentage_target])
    mitigation_importance = np.asarray(mitigation_model.feature_importances_, dtype=float)
    mitigation_importance = mitigation_importance / mitigation_importance.sum()
    importance_rows: list[dict[str, object]] = []
    for feature, importance in zip(YUAN_FEATURES, baseline_importance):
        importance_rows.append(
            {
                "variant": "baseline_7feature_amount_XGBoost",
                "feature": feature,
                "importance_fraction": float(importance),
                "included_in_learned_component": True,
            }
        )
    for feature in YUAN_FEATURES:
        if feature in no_loading_features:
            importance = float(mitigation_importance[no_loading_features.index(feature)])
            included = True
        else:
            importance = 0.0
            included = False
        importance_rows.append(
            {
                "variant": "percentage_first_no_loading_XGBoost",
                "feature": feature,
                "importance_fraction": importance,
                "included_in_learned_component": included,
            }
        )
    importance = pd.DataFrame(importance_rows)
    importance["rank_within_variant"] = importance.groupby("variant")["importance_fraction"].rank(
        method="min", ascending=False
    )
    write_csv(importance, "phase4b_bias_mitigation_feature_importance.csv")

    prediction_rows: list[dict[str, object]] = []
    for held_out_drug in sorted(yuan["Drug name"].unique()):
        test_mask = yuan["Drug name"] == held_out_drug
        training = yuan.loc[~test_mask]
        test = yuan.loc[test_mask]
        fold_model = XGBRegressor(
            objective="reg:squarederror",
            n_estimators=100,
            learning_rate=0.2,
            max_depth=2,
            min_child_weight=2,
            reg_lambda=5.0,
            subsample=0.9,
            colsample_bytree=0.9,
            random_state=RANDOM_STATE,
            n_jobs=1,
            tree_method="hist",
        )
        fold_model.fit(training[no_loading_features], training[percentage_target])
        predicted_percentage = np.clip(fold_model.predict(test[no_loading_features]), 0.0, 100.0)
        predicted_amount = (
            test["Drug loading in MN patch (µg)"].to_numpy(dtype=float) * predicted_percentage / 100.0
        )
        for row_index, observed, predicted, fraction_prediction in zip(
            test.index, test[amount_target], predicted_amount, predicted_percentage
        ):
            prediction_rows.append(
                {
                    "row_index": int(row_index),
                    "held_out_drug": held_out_drug,
                    "variant": "percentage_first_no_loading_XGBoost",
                    "target": "permeation_amount_ug_cm2",
                    "n_train_experimental": int(len(training)),
                    "n_test_experimental": int(len(test)),
                    "observed": float(observed),
                    "predicted": float(predicted),
                    "predicted_permeation_percentage_for_reconstruction": float(fraction_prediction),
                }
            )
    mitigation_predictions = pd.DataFrame(prediction_rows)
    baseline_amount = baseline_lodo_predictions.loc[
        (baseline_lodo_predictions["model"] == "XGBoost")
        & (baseline_lodo_predictions["target"] == "permeation_amount_ug_cm2")
    ].copy()
    baseline_amount = baseline_amount.rename(columns={"variant": "baseline_variant"})
    baseline_amount["variant"] = "baseline_7feature_amount_XGBoost"
    baseline_amount = baseline_amount[
        [
            "row_index",
            "held_out_drug",
            "variant",
            "target",
            "n_train_experimental",
            "n_test_experimental",
            "observed",
            "predicted",
        ]
    ]
    all_predictions = pd.concat([baseline_amount, mitigation_predictions], ignore_index=True)
    write_csv(all_predictions, "phase4b_bias_mitigation_lodo_predictions.csv")
    performance = metric_rows_from_predictions(all_predictions, ["variant", "target"], fold_column="held_out_drug")
    loading_importance = importance.loc[
        importance["feature"] == "Drug loading in MN patch (µg)", ["variant", "importance_fraction"]
    ].rename(columns={"importance_fraction": "learned_component_loading_importance"})
    performance = performance.merge(loading_importance, on="variant", how="left")
    performance.insert(0, "dataset", "Yuan 2023 reconstructed 191 observations")
    performance.insert(1, "validation", "leave-one-drug-out")
    performance["mitigation_description"] = np.where(
        performance["variant"] == "percentage_first_no_loading_XGBoost",
        "XGBoost learns percentage without loading; amount is then reconstructed by mass balance.",
        "Original seven-feature amount XGBoost.",
    )
    write_csv(performance, "phase4b_bias_mitigation_performance.csv")
    return importance, performance


def run_physics_augmentation(skin: pd.DataFrame) -> tuple[pd.DataFrame, pd.DataFrame]:
    """Augment a two-descriptor auxiliary model with explicitly flagged Potts--Guy data."""
    mw_grid = np.linspace(skin["MW"].quantile(0.05), skin["MW"].quantile(0.95), 10)
    logp_grid = np.linspace(skin["LogP"].quantile(0.05), skin["LogP"].quantile(0.95), 10)
    synthetic_rows = []
    for mw_index, logp_index in itertools.product(range(len(mw_grid)), range(len(logp_grid))):
        mw = float(mw_grid[mw_index])
        logp = float(logp_grid[logp_index])
        synthetic_rows.append(
            {
                "grid_mw_index": mw_index,
                "grid_logp_index": logp_index,
                "MW": mw,
                "LogP": logp,
                "logKp_cm_h": float(potts_guy_baseline(logp, mw)),
                "is_synthetic_physics_augmented": True,
                "physics_source": "descriptors.py::potts_guy_baseline",
            }
        )
    synthetic = pd.DataFrame(synthetic_rows)
    write_csv(synthetic, "phase4b_physics_augmented_points.csv")

    X = skin[["MW", "LogP"]].to_numpy(dtype=float)
    y = skin["logKp_cm_h"].to_numpy(dtype=float)
    synthetic_X = synthetic[["MW", "LogP"]].to_numpy(dtype=float)
    synthetic_y = synthetic["logKp_cm_h"].to_numpy(dtype=float)
    kfold = KFold(n_splits=5, shuffle=True, random_state=RANDOM_STATE)
    prediction_rows: list[dict[str, object]] = []
    for fold, (train_indices, test_indices) in enumerate(kfold.split(X), start=1):
        for variant in ("experimental_only_two_descriptor", "physics_augmented_two_descriptor"):
            model = XGBRegressor(
                objective="reg:squarederror",
                n_estimators=250,
                learning_rate=0.04,
                max_depth=3,
                min_child_weight=2,
                subsample=0.9,
                colsample_bytree=1.0,
                random_state=RANDOM_STATE,
                n_jobs=1,
                tree_method="hist",
            )
            if variant == "experimental_only_two_descriptor":
                train_X = X[train_indices]
                train_y = y[train_indices]
                synthetic_count = 0
            else:
                train_X = np.vstack([X[train_indices], synthetic_X])
                train_y = np.concatenate([y[train_indices], synthetic_y])
                synthetic_count = len(synthetic)
            model.fit(train_X, train_y)
            prediction = model.predict(X[test_indices])
            for row_index, observed, predicted in zip(test_indices, y[test_indices], prediction):
                prediction_rows.append(
                    {
                        "row_index": int(row_index),
                        "fold": fold,
                        "variant": variant,
                        "test_is_experimental": True,
                        "n_train_experimental": int(len(train_indices)),
                        "n_train_synthetic": synthetic_count,
                        "observed": float(observed),
                        "predicted": float(predicted),
                    }
                )
    predictions = pd.DataFrame(prediction_rows)
    write_csv(predictions, "phase4b_physics_augmentation_cv_predictions.csv")
    performance = metric_rows_from_predictions(predictions, ["variant"], fold_column="fold")
    performance.insert(0, "dataset", "214 experimental skin-permeability compounds")
    performance.insert(1, "validation", "5-fold test sets contain experimental observations only")
    performance["n_synthetic_points_available_per_training_fold"] = np.where(
        performance["variant"] == "physics_augmented_two_descriptor", len(synthetic), 0
    )
    performance["synthetic_flag_file"] = "phase4b_physics_augmented_points.csv"
    write_csv(performance, "phase4b_physics_augmentation_metrics.csv")
    return synthetic, performance


def run_phase_4b(
    skin: pd.DataFrame,
    yuan: pd.DataFrame,
    final_4a_model,
) -> dict[str, object]:
    """Run reproduction, LODO, transfer, bias mitigation, and physics augmentation."""
    random_predictions, random_performance = run_yuan_random_split(yuan)
    lodo_predictions, lodo_performance, lodo_fold_metrics = run_yuan_lodo(yuan)
    transfer_features, transfer_predictions, transfer_performance = run_transfer_learning(
        yuan, final_4a_model
    )
    mitigation_importance, mitigation_performance = run_bias_mitigation(yuan, lodo_predictions)
    synthetic_points, augmentation_performance = run_physics_augmentation(skin)

    set_figure_style()
    amount_lodo = lodo_performance.loc[
        lodo_performance["target"] == "permeation_amount_ug_cm2"
    ].sort_values("pooled_r2", ascending=True)
    fick_amount_lodo = amount_lodo.loc[
        amount_lodo["model"] == "Fick_diffusion_proxy"
    ].iloc[0]
    learned_amount_lodo = amount_lodo.loc[
        amount_lodo["model"] != "Fick_diffusion_proxy"
    ]
    transfer_amount = transfer_performance.loc[
        transfer_performance["target"] == "permeation_amount_ug_cm2"
    ].copy()
    figure, axes = plt.subplots(1, 2, figsize=(21, 7), gridspec_kw={"width_ratios": [1.15, 1]})
    model_colors = {
        "Fick_diffusion_proxy": PALETTE["grey"],
        "MLR": PALETTE["violet"],
        "RandomForest": PALETTE["teal"],
        "XGBoost": PALETTE["purple"],
    }
    axes[0].barh(
        learned_amount_lodo["model"],
        learned_amount_lodo["pooled_r2"],
        color=[model_colors[name] for name in learned_amount_lodo["model"]],
    )
    axes[0].axvline(0, color="#222222", lw=1)
    axes[0].set_title("Six-drug LODO: learned amount models")
    axes[0].set_xlabel("Pooled leave-one-drug-out R²")
    axes[0].text(
        0.02,
        0.04,
        f"Fick diffusion proxy: R² = {fick_amount_lodo['pooled_r2']:.2f}\n(not shown on this scale; reported in CSV)",
        transform=axes[0].transAxes,
        va="bottom",
        fontsize=11,
        bbox={"facecolor": "white", "edgecolor": "none", "alpha": 0.9},
    )
    pivot = transfer_amount.pivot(index="model", columns="variant", values="pooled_r2").sort_values(
        "seven_feature_small_molecules_only"
    )
    plot_x = np.arange(len(pivot))
    width = 0.36
    axes[1].bar(
        plot_x - width / 2,
        pivot["seven_feature_small_molecules_only"],
        width,
        label="7 feature",
        color=PALETTE["blue"],
    )
    axes[1].bar(
        plot_x + width / 2,
        pivot["eight_feature_transfer_small_molecules_only"],
        width,
        label="8 feature + general-skin log Kp",
        color=PALETTE["green"],
    )
    axes[1].axhline(0, color="#222222", lw=1)
    axes[1].set_xticks(plot_x, pivot.index)
    axes[1].set_title("Four-small-molecule LODO: transfer comparison")
    axes[1].set_ylabel("Pooled leave-one-drug-out R²")
    axes[1].legend(frameon=False, fontsize=10)
    sns.despine(fig=figure)
    figure.tight_layout()
    save_figure(figure, "fig_transfer_phase4b_lodo.png")

    return {
        "random_predictions": random_predictions,
        "random_performance": random_performance,
        "lodo_predictions": lodo_predictions,
        "lodo_performance": lodo_performance,
        "lodo_fold_metrics": lodo_fold_metrics,
        "transfer_features": transfer_features,
        "transfer_predictions": transfer_predictions,
        "transfer_performance": transfer_performance,
        "mitigation_importance": mitigation_importance,
        "mitigation_performance": mitigation_performance,
        "synthetic_points": synthetic_points,
        "augmentation_performance": augmentation_performance,
    }


def tree_shap_values(model, features: pd.DataFrame) -> np.ndarray:
    """Calculate TreeSHAP consistently across the two fitted XGBoost models."""
    explainer = shap.TreeExplainer(model)
    values = explainer.shap_values(features)
    if isinstance(values, list):
        values = values[0]
    return np.asarray(values, dtype=float)


def run_phase_5(
    skin: pd.DataFrame,
    cosmetics: pd.DataFrame,
    final_4a_model,
    selected_4a_name: str,
    X_skin: pd.DataFrame,
    y_skin: np.ndarray,
    X_cosmetic: pd.DataFrame,
    cosmetics_ad: pd.DataFrame,
    phase4a_performance: pd.DataFrame,
    yuan: pd.DataFrame,
    phase4b: dict[str, object],
) -> None:
    """Run SHAP, scope-aware accuracy summaries, and 4A-only cosmetic screening."""
    # A tree model is selected specifically for transparent TreeSHAP in 4A;
    # deployment/transfer remains governed by the independently selected 4A model.
    shap_4a_model = make_4a_model("XGBoost")
    shap_4a_model.fit(X_skin, y_skin)
    shap_4a_values = tree_shap_values(shap_4a_model, X_skin)
    shap_4a_table = pd.DataFrame(shap_4a_values, columns=DESCRIPTOR_FEATURES)
    shap_4a_table.insert(0, "row_index", skin.index.astype(int))
    shap_4a_table.insert(1, "observed_logKp_cm_h", y_skin)
    write_csv(shap_4a_table, "phase5_shap_4a_values.csv")
    shap_4a_importance = pd.DataFrame(
        {
            "model": "4A_XGBoost",
            "feature": DESCRIPTOR_FEATURES,
            "mean_abs_shap": np.mean(np.abs(shap_4a_values), axis=0),
        }
    ).sort_values("mean_abs_shap", ascending=False, ignore_index=True)
    shap_4a_importance["rank"] = np.arange(1, len(shap_4a_importance) + 1)
    write_csv(shap_4a_importance, "phase5_shap_4a_feature_importance.csv")

    amount_target = YUAN_TARGETS["permeation_amount_ug_cm2"]
    shap_4b_model = make_yuan_model("XGBoost", "permeation_amount_ug_cm2")
    shap_4b_model.fit(yuan[YUAN_FEATURES], yuan[amount_target])
    shap_4b_values = tree_shap_values(shap_4b_model, yuan[YUAN_FEATURES])
    shap_4b_table = pd.DataFrame(shap_4b_values, columns=YUAN_FEATURES)
    shap_4b_table.insert(0, "row_index", yuan.index.astype(int))
    shap_4b_table.insert(1, "drug_name", yuan["Drug name"].to_numpy())
    shap_4b_table.insert(2, "observed_permeation_amount_ug_cm2", yuan[amount_target].to_numpy())
    write_csv(shap_4b_table, "phase5_shap_4b_values.csv")
    shap_4b_importance = pd.DataFrame(
        {
            "model": "4B_XGBoost_amount",
            "feature": YUAN_FEATURES,
            "mean_abs_shap": np.mean(np.abs(shap_4b_values), axis=0),
        }
    ).sort_values("mean_abs_shap", ascending=False, ignore_index=True)
    shap_4b_importance["rank"] = np.arange(1, len(shap_4b_importance) + 1)
    write_csv(shap_4b_importance, "phase5_shap_4b_feature_importance.csv")

    set_figure_style()
    figure, axes = plt.subplots(1, 2, figsize=(21, 7), gridspec_kw={"width_ratios": [1.1, 1]})
    left = shap_4a_importance.sort_values("mean_abs_shap", ascending=True)
    right = shap_4b_importance.sort_values("mean_abs_shap", ascending=True)
    axes[0].barh(left["feature"], left["mean_abs_shap"], color=PALETTE["teal"])
    axes[0].set_title("4A XGBoost: descriptor contribution")
    axes[0].set_xlabel("Mean |SHAP value| (log Kp scale)")
    axes[1].barh(right["feature"], right["mean_abs_shap"], color=PALETTE["purple"])
    axes[1].set_title("4B XGBoost: amount-model contribution")
    axes[1].set_xlabel("Mean |SHAP value| (µg/cm² scale)")
    sns.despine(fig=figure)
    figure.tight_layout()
    save_figure(figure, "fig_transfer_phase5_shap.png")

    predicted_general_skin_logkp = final_4a_model.predict(X_cosmetic[DESCRIPTOR_FEATURES])
    cosmetic_output = cosmetics[
        [
            "ingredient",
            "category",
            "MW_rdkit",
            "LogP_rdkit",
            "logKp_PottsGuy_baseline",
            "in_MW_domain",
            "in_LogP_domain",
            "large_molecule_flag",
            "highly_polar_flag",
        ]
    ].copy()
    cosmetic_output["selected_4a_model"] = selected_4a_name
    cosmetic_output["predicted_general_skin_logKp_cm_h"] = predicted_general_skin_logkp
    cosmetic_output["leverage"] = cosmetics_ad["leverage"].to_numpy()
    cosmetic_output["leverage_threshold"] = cosmetics_ad["leverage_threshold"].to_numpy()
    cosmetic_output["in_leverage_domain"] = cosmetics_ad["in_leverage_domain"].to_numpy()
    cosmetic_output["in_simple_MW_LogP_range"] = cosmetics_ad["in_simple_MW_LogP_range"].to_numpy()
    cosmetic_output["is_microneedle_prediction"] = False
    cosmetic_output["scope_note"] = (
        "General skin-permeability QSAR prediction only; no microneedle experiment parameters were assumed."
    )
    write_csv(cosmetic_output, "phase5_cosmetic_4a_predictions.csv")

    category_summary = (
        cosmetic_output.groupby("category", as_index=False)
        .agg(
            n_ingredients=("ingredient", "size"),
            mean_predicted_general_skin_logKp_cm_h=("predicted_general_skin_logKp_cm_h", "mean"),
            median_predicted_general_skin_logKp_cm_h=("predicted_general_skin_logKp_cm_h", "median"),
            sd_predicted_general_skin_logKp_cm_h=("predicted_general_skin_logKp_cm_h", "std"),
            n_in_leverage_domain=("in_leverage_domain", "sum"),
            n_in_simple_MW_LogP_range=("in_simple_MW_LogP_range", "sum"),
        )
        .sort_values("median_predicted_general_skin_logKp_cm_h", ascending=False, ignore_index=True)
    )
    write_csv(category_summary, "phase5_cosmetic_category_summary.csv")

    # Ingredient labels are not canonical SMILES, so use the structural key.
    overlap = cosmetics[["ingredient", "canon_smiles"]].merge(
        skin[["canon_smiles", "logKp_cm_h", "n_measurements", "sources"]],
        on="canon_smiles",
        how="inner",
    )
    overlap["interpretation"] = "In-training-set structural overlap; not an external validation set."
    write_csv(overlap, "phase5_cosmetic_training_overlap.csv")

    selected_4a_performance = phase4a_performance.loc[
        phase4a_performance["model"] == selected_4a_name
    ].copy()
    selected_4a_performance = selected_4a_performance.assign(
        analysis="4A general skin QSAR",
        endpoint="log Kp (cm/h)",
        data_scope="214 compound experimental skin-permeability dataset",
    )
    yuan_random = phase4b["random_performance"].loc[
        (phase4b["random_performance"]["model"] == "XGBoost")
        & (phase4b["random_performance"]["target"] == "permeation_amount_ug_cm2")
    ].copy()
    yuan_random = yuan_random.assign(
        analysis="4B Yuan reproduction",
        endpoint="permeation amount (µg/cm²)",
        data_scope="191 microneedle observations; random 70:30 split",
    )
    yuan_lodo = phase4b["lodo_performance"].loc[
        (phase4b["lodo_performance"]["model"] == "XGBoost")
        & (phase4b["lodo_performance"]["target"] == "permeation_amount_ug_cm2")
    ].copy()
    yuan_lodo = yuan_lodo.assign(
        analysis="4B Yuan extrapolation",
        endpoint="permeation amount (µg/cm²)",
        data_scope="191 microneedle observations; six-drug LODO",
    )
    scope_comparison = pd.concat(
        [selected_4a_performance, yuan_random, yuan_lodo],
        ignore_index=True,
        sort=False,
    )
    selected_columns = [
        "analysis",
        "data_scope",
        "endpoint",
        "model",
        "validation",
        "n_observations",
        "pooled_r2",
        "pooled_rmse",
        "pooled_mae",
    ]
    scope_comparison = scope_comparison[[column for column in selected_columns if column in scope_comparison.columns]]
    scope_comparison["comparison_note"] = (
        "Metrics are reported side-by-side only; differing endpoints and datasets make them not directly rankable."
    )
    write_csv(scope_comparison, "phase5_model_scope_comparison.csv")

    set_figure_style()
    category_plot = category_summary.sort_values("median_predicted_general_skin_logKp_cm_h", ascending=True)
    figure, axes = plt.subplots(1, 2, figsize=(22, 9), gridspec_kw={"width_ratios": [1.15, 1]})
    axes[0].barh(
        category_plot["category"],
        category_plot["median_predicted_general_skin_logKp_cm_h"],
        color=PALETTE["purple"],
    )
    axes[0].set_title("4A-predicted general skin permeability by category")
    axes[0].set_xlabel("Median predicted log Kp (cm/h)")
    axes[0].set_ylabel("")
    ad_palette = np.where(cosmetic_output["in_leverage_domain"], PALETTE["teal"], PALETTE["red"])
    axes[1].scatter(
        cosmetic_output["LogP_rdkit"],
        cosmetic_output["predicted_general_skin_logKp_cm_h"],
        s=85,
        c=ad_palette,
        edgecolor="white",
        linewidth=0.6,
        alpha=0.9,
    )
    axes[1].set_title("48 cosmetic ingredients: 4A screening only")
    axes[1].set_xlabel("RDKit LogP")
    axes[1].set_ylabel("Predicted general skin log Kp (cm/h)")
    legend_handles = [
        plt.Line2D([0], [0], marker="o", color="w", label="In leverage domain", markerfacecolor=PALETTE["teal"], markersize=10),
        plt.Line2D([0], [0], marker="o", color="w", label="Outside leverage domain", markerfacecolor=PALETTE["red"], markersize=10),
    ]
    axes[1].legend(handles=legend_handles, frameon=False, loc="best")
    sns.despine(fig=figure)
    figure.tight_layout()
    save_figure(figure, "fig_transfer_phase5_cosmetic_predictions.png")


def write_run_manifest(
    skin: pd.DataFrame,
    yuan: pd.DataFrame,
    cosmetics: pd.DataFrame,
    selected_4a_name: str,
) -> None:
    """Persist high-level run facts for the paper's numerical audit."""
    manifest = pd.DataFrame(
        [
            ("random_state", RANDOM_STATE, "Applied to all stochastic estimators and splitters."),
            ("skin_dataset_rows", len(skin), "Experimental compounds; not synthetic."),
            ("yuan_dataset_rows", len(yuan), "Experimental microneedle observations; not synthetic."),
            ("cosmetic_dataset_rows", len(cosmetics), "Prediction-only ingredients; no MN parameters."),
            ("yuan_small_molecule_rows", int(yuan["is_small_molecule"].sum()), "Rows for four drugs eligible for descriptor transfer."),
            ("yuan_non_small_molecule_rows", int((~yuan["is_small_molecule"]).sum()), "BSA and copper-ion rows excluded from transfer feature."),
            ("selected_4a_fitted_model", selected_4a_name, "Chosen from saved 5-fold OOF results."),
            ("physics_synthetic_file", "phase4b_physics_augmented_points.csv", "Explicitly flagged Potts--Guy grid points; never described as experiments."),
        ],
        columns=["item", "value", "details"],
    )
    write_csv(manifest, "transfer_learning_run_manifest.csv")


def main() -> None:
    """Execute all analyses in the documented phase order."""
    warnings.filterwarnings("ignore", category=UserWarning, module="xgboost")
    skin = pd.read_csv(SKIN_DATA)
    yuan = pd.read_csv(YUAN_DATA)
    cosmetics = pd.read_csv(COSMETIC_DATA)

    if len(skin) != 214 or len(yuan) != 191 or len(cosmetics) != 48:
        raise ValueError("Unexpected input sizes; refusing to write analyses against different datasets.")
    if skin[DESCRIPTOR_FEATURES].isna().any().any():
        raise ValueError("The 214-compound descriptor matrix has missing values.")

    run_phase_2_curation(skin)
    run_phase_3_eda(skin, cosmetics)
    (
        final_4a_model,
        selected_4a_name,
        X_skin,
        y_skin,
        X_cosmetic,
        _cv_predictions,
        phase4a_performance,
        cosmetics_ad,
    ) = run_phase_4a(skin, cosmetics)
    phase4b = run_phase_4b(skin, yuan, final_4a_model)
    run_phase_5(
        skin,
        cosmetics,
        final_4a_model,
        selected_4a_name,
        X_skin,
        y_skin,
        X_cosmetic,
        cosmetics_ad,
        phase4a_performance,
        yuan,
        phase4b,
    )
    write_run_manifest(skin, yuan, cosmetics, selected_4a_name)
    print("Transfer-learning analysis completed. Outputs were written to:", SCRIPT_DIR)


if __name__ == "__main__":
    main()
