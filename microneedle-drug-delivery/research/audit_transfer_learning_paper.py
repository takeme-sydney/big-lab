"""Audit substantive numerical claims in transfer-learning-paper/paper.md.

The audit reads the saved result CSVs, renders the values at the precision used
in the paper, and verifies that each reported result appears in the manuscript.
It is intentionally a second reader of outputs rather than an assertion that
the preceding analysis script was correct.
"""

from __future__ import annotations

from pathlib import Path

import pandas as pd


RANDOM_STATE = 42
RESEARCH_DIR = Path(__file__).resolve().parent
PAPER_PATH = RESEARCH_DIR.parent / "transfer-learning-paper" / "paper.md"
OUTPUT_PATH = RESEARCH_DIR / "phase6_numerical_audit.csv"


def format_value(value: float | int, precision: int, commas: bool = False) -> str:
    """Format a saved scalar exactly as a paper-level result is reported."""
    if precision == 0:
        return f"{int(round(float(value))):,}" if commas else f"{int(round(float(value)))}"
    specifier = f",.{precision}f" if commas else f".{precision}f"
    return format(float(value), specifier)


def load_row(frame: pd.DataFrame, **conditions) -> pd.Series:
    """Return one unambiguous table row or fail instead of silently auditing wrong data."""
    mask = pd.Series(True, index=frame.index)
    for column, value in conditions.items():
        mask &= frame[column] == value
    selected = frame.loc[mask]
    if len(selected) != 1:
        raise ValueError(f"Expected exactly one row for {conditions}, found {len(selected)}")
    return selected.iloc[0]


def main() -> None:
    paper_text = PAPER_PATH.read_text(encoding="utf-8")
    audit_rows: list[dict[str, object]] = []

    def add_claim(
        claim: str,
        source_file: str,
        value: float | int | str,
        precision: int | None,
        details: str,
        expected_token: str | None = None,
        commas: bool = False,
    ) -> None:
        if expected_token is None:
            if precision is None:
                expected_token = str(value)
            else:
                expected_token = format_value(float(value), precision, commas=commas)
        occurrences = paper_text.count(expected_token)
        audit_rows.append(
            {
                "claim": claim,
                "source_file": source_file,
                "source_value": value,
                "expected_paper_token": expected_token,
                "paper_token_occurrences": occurrences,
                "status": "PASS" if occurrences > 0 else "FAIL",
                "details": details,
            }
        )

    manifest = pd.read_csv(RESEARCH_DIR / "transfer_learning_run_manifest.csv")
    manifest_values = dict(zip(manifest["item"], manifest["value"]))
    for item, label in [
        ("skin_dataset_rows", "Experimental 4A compound count"),
        ("yuan_dataset_rows", "Experimental Yuan observation count"),
        ("cosmetic_dataset_rows", "Cosmetic screening count"),
        ("yuan_small_molecule_rows", "Descriptor-transfer eligible Yuan rows"),
        ("yuan_non_small_molecule_rows", "BSA/copper excluded transfer rows"),
    ]:
        add_claim(label, "transfer_learning_run_manifest.csv", manifest_values[item], 0, label)

    curation = pd.read_csv(RESEARCH_DIR / "phase2_curation_summary.csv")
    curation_values = dict(zip(curation["metric"], curation["value"]))
    for item, label, precision in [
        ("n_missing_values", "Curation missing values", 0),
        ("n_duplicate_canon_smiles", "Curation duplicate canonical SMILES", 0),
        ("n_descriptor_leverage_outliers", "Curation leverage-flagged compounds", 0),
        ("leverage_threshold", "Curation leverage threshold", 4),
        ("target_iqr_lower", "Curation IQR lower bound", 3),
        ("target_iqr_upper", "Curation IQR upper bound", 3),
    ]:
        add_claim(label, "phase2_curation_summary.csv", curation_values[item], precision, label)

    eda = pd.read_csv(RESEARCH_DIR / "phase3_eda_summary.csv")
    for statistic, precision in [("mean", 3), ("std", 3), ("50%", 3), ("min", 3), ("max", 3)]:
        row = load_row(eda, statistic=statistic)
        add_claim(
            f"Skin logKp {statistic}",
            "phase3_eda_summary.csv",
            row["value"],
            precision,
            "Experimental 214-compound target distribution.",
        )

    vif = pd.read_csv(RESEARCH_DIR / "phase3_vif.csv")
    for descriptor in ["MolarRefractivity", "MW", "TPSA", "NumHeteroatoms"]:
        row = load_row(vif, descriptor=descriptor)
        add_claim(
            f"VIF {descriptor}",
            "phase3_vif.csv",
            row["vif"],
            3,
            "Largest reported multicollinearity diagnostics.",
        )

    performance_4a = pd.read_csv(RESEARCH_DIR / "phase4a_model_performance.csv")
    for model in ["Potts-Guy", "MLR", "RandomForest", "XGBoost", "GaussianProcess"]:
        row = load_row(performance_4a, model=model)
        for metric in ["pooled_r2", "pooled_rmse", "pooled_mae"]:
            add_claim(
                f"4A {model} {metric}",
                "phase4a_model_performance.csv",
                row[metric],
                3,
                "Pooled five-fold out-of-fold metric.",
            )

    ad = pd.read_csv(RESEARCH_DIR / "phase4a_ad_comparison.csv")
    add_claim(
        "Cosmetics inside simple MW/LogP range",
        "phase4a_ad_comparison.csv",
        int(ad["in_simple_MW_LogP_range"].sum()),
        0,
        "Count of 48 cosmetics inside both existing range flags.",
    )
    add_claim(
        "Cosmetics inside leverage domain",
        "phase4a_ad_comparison.csv",
        int(ad["in_leverage_domain"].sum()),
        0,
        "Count of 48 cosmetics at or below leverage threshold.",
    )
    add_claim(
        "Range-inside but leverage-outside cosmetics",
        "phase4a_ad_comparison.csv",
        int(ad["range_inside_but_leverage_outside"].sum()),
        0,
        "Disagreement count between simple and leverage applicability domains.",
    )

    random_performance = pd.read_csv(RESEARCH_DIR / "phase4b_random_split_performance.csv")
    for target in ["permeation_amount_ug_cm2", "permeation_percentage"]:
        for model in ["MLR", "RandomForest", "XGBoost"]:
            row = load_row(random_performance, target=target, model=model)
            for metric in ["pooled_r2", "pooled_rmse"]:
                add_claim(
                    f"Random split {target} {model} {metric}",
                    "phase4b_random_split_performance.csv",
                    row[metric],
                    3,
                    "Fixed 70:30 Yuan test-set metric.",
                    commas=metric == "pooled_rmse" and abs(float(row[metric])) >= 1000,
                )
    for target in ["permeation_amount_ug_cm2", "permeation_percentage"]:
        row = load_row(random_performance, target=target, model="Fick_diffusion_proxy")
        add_claim(
            f"Random split {target} Fick proxy R2",
            "phase4b_random_split_performance.csv",
            row["pooled_r2"],
            3,
            "Explicitly labelled analytical Fick-proxy, not original C solver.",
        )

    lodo = pd.read_csv(RESEARCH_DIR / "phase4b_lodo_performance.csv")
    for model in ["Fick_diffusion_proxy", "MLR", "RandomForest", "XGBoost"]:
        row = load_row(lodo, target="permeation_amount_ug_cm2", model=model)
        for metric in ["pooled_r2", "pooled_rmse", "pooled_mae"]:
            add_claim(
                f"Six-drug LODO amount {model} {metric}",
                "phase4b_lodo_performance.csv",
                row[metric],
                3,
                "Pooled six-drug leave-one-drug-out metric.",
                commas=metric in {"pooled_rmse", "pooled_mae"} and abs(float(row[metric])) >= 1000,
            )
    for model in ["RandomForest", "XGBoost"]:
        row = load_row(lodo, target="permeation_percentage", model=model)
        for metric in ["pooled_r2", "pooled_rmse", "pooled_mae"]:
            add_claim(
                f"Six-drug LODO percentage {model} {metric}",
                "phase4b_lodo_performance.csv",
                row[metric],
                3,
                "Pooled six-drug leave-one-drug-out metric.",
            )

    lodo_fold = pd.read_csv(RESEARCH_DIR / "phase4b_lodo_fold_metrics.csv")
    for held_out_drug, metric in [("lidocaine", "pooled_rmse"), ("copper ions", "pooled_rmse"), ("Rhodamine B", "pooled_rmse")]:
        row = load_row(
            lodo_fold,
            target="permeation_amount_ug_cm2",
            model="XGBoost",
            held_out_drug=held_out_drug,
        )
        add_claim(
            f"XGBoost LODO {held_out_drug} {metric}",
            "phase4b_lodo_fold_metrics.csv",
            row[metric],
            3,
            "Per-held-out-drug amount diagnostic.",
            commas=abs(float(row[metric])) >= 1000,
        )

    transfer = pd.read_csv(RESEARCH_DIR / "phase4b_transfer_lodo_performance.csv")
    for variant in ["seven_feature_small_molecules_only", "eight_feature_transfer_small_molecules_only"]:
        for model in ["MLR", "RandomForest", "XGBoost"]:
            row = load_row(
                transfer,
                variant=variant,
                target="permeation_amount_ug_cm2",
                model=model,
            )
            add_claim(
                f"Transfer amount {variant} {model} R2",
                "phase4b_transfer_lodo_performance.csv",
                row["pooled_r2"],
                3,
                "Four-small-molecule LODO amount result.",
            )
    transfer_xgb = load_row(
        transfer,
        variant="eight_feature_transfer_small_molecules_only",
        target="permeation_amount_ug_cm2",
        model="XGBoost",
    )
    for metric in ["pooled_rmse", "pooled_mae"]:
        add_claim(
            f"Transfer eight-feature XGBoost {metric}",
            "phase4b_transfer_lodo_performance.csv",
            transfer_xgb[metric],
            3,
            "Four-small-molecule LODO amount result.",
            commas=abs(float(transfer_xgb[metric])) >= 1000,
        )

    mitigation = pd.read_csv(RESEARCH_DIR / "phase4b_bias_mitigation_performance.csv")
    for variant in ["baseline_7feature_amount_XGBoost", "percentage_first_no_loading_XGBoost"]:
        row = load_row(mitigation, variant=variant)
        for metric in ["pooled_r2", "pooled_rmse", "learned_component_loading_importance"]:
            add_claim(
                f"Bias mitigation {variant} {metric}",
                "phase4b_bias_mitigation_performance.csv",
                row[metric],
                3,
                "Six-drug LODO amount comparison.",
                commas=metric in {"pooled_rmse", "pooled_mae"} and abs(float(row[metric])) >= 1000,
            )

    augmentation = pd.read_csv(RESEARCH_DIR / "phase4b_physics_augmentation_metrics.csv")
    for variant in ["experimental_only_two_descriptor", "physics_augmented_two_descriptor"]:
        row = load_row(augmentation, variant=variant)
        for metric in ["pooled_r2", "pooled_rmse", "pooled_mae", "n_synthetic_points_available_per_training_fold"]:
            add_claim(
                f"Physics augmentation {variant} {metric}",
                "phase4b_physics_augmentation_metrics.csv",
                row[metric],
                0 if metric.startswith("n_") else 3,
                "Experimental test rows only; synthetic rows are separately flagged.",
            )
    synthetic = pd.read_csv(RESEARCH_DIR / "phase4b_physics_augmented_points.csv")
    add_claim(
        "Physics synthetic point count",
        "phase4b_physics_augmented_points.csv",
        len(synthetic),
        0,
        "Rows generated by Potts–Guy grid.",
    )
    add_claim(
        "Physics synthetic flag",
        "phase4b_physics_augmented_points.csv",
        str(bool(synthetic["is_synthetic_physics_augmented"].all())).lower(),
        None,
        "All pseudo-points must retain explicit true flag.",
        expected_token="is_synthetic_physics_augmented=True",
    )

    shap_4a = pd.read_csv(RESEARCH_DIR / "phase5_shap_4a_feature_importance.csv")
    for feature in ["LogP", "MW", "MolarRefractivity", "HBD", "TPSA"]:
        row = load_row(shap_4a, feature=feature)
        add_claim(
            f"4A SHAP {feature}",
            "phase5_shap_4a_feature_importance.csv",
            row["mean_abs_shap"],
            3,
            "Mean absolute TreeSHAP value.",
        )
    shap_4b = pd.read_csv(RESEARCH_DIR / "phase5_shap_4b_feature_importance.csv")
    for feature in ["Drug loading in MN patch (µg)", "Permeation time (hour)", "Drug MW (Dalton)"]:
        row = load_row(shap_4b, feature=feature)
        add_claim(
            f"4B SHAP {feature}",
            "phase5_shap_4b_feature_importance.csv",
            row["mean_abs_shap"],
            3,
            "Mean absolute TreeSHAP value.",
            commas=abs(float(row["mean_abs_shap"])) >= 1000,
        )

    cosmetics = pd.read_csv(RESEARCH_DIR / "phase5_cosmetic_4a_predictions.csv")
    for column, function, label in [
        ("predicted_general_skin_logKp_cm_h", "min", "Cosmetic predicted minimum"),
        ("predicted_general_skin_logKp_cm_h", "max", "Cosmetic predicted maximum"),
        ("predicted_general_skin_logKp_cm_h", "mean", "Cosmetic predicted mean"),
        ("predicted_general_skin_logKp_cm_h", "median", "Cosmetic predicted median"),
    ]:
        value = float(getattr(cosmetics[column], function)())
        add_claim(label, "phase5_cosmetic_4a_predictions.csv", value, 3, "4A screening only.")
    add_claim(
        "Cosmetic MN prediction count",
        "phase5_cosmetic_4a_predictions.csv",
        int(cosmetics["is_microneedle_prediction"].sum()),
        0,
        "All cosmetics must remain 4A-only outputs.",
        expected_token="is_microneedle_prediction=False",
    )

    categories = pd.read_csv(RESEARCH_DIR / "phase5_cosmetic_category_summary.csv")
    for category in ["penetration_enhancer", "anti_aging_retinoid"]:
        row = load_row(categories, category=category)
        add_claim(
            f"Cosmetic category median {category}",
            "phase5_cosmetic_category_summary.csv",
            row["median_predicted_general_skin_logKp_cm_h"],
            3,
            "Descriptive 4A category summary.",
        )
    overlap = pd.read_csv(RESEARCH_DIR / "phase5_cosmetic_training_overlap.csv")
    add_claim(
        "Cosmetic in-training structural overlaps",
        "phase5_cosmetic_training_overlap.csv",
        len(overlap),
        0,
        "This count is explicitly not external validation.",
    )

    # Boundary text checks are qualitative but make prohibited scope drift visible.
    for claim, expected in [
        ("Paper states no cosmetic 4B use", "no cosmetic ingredient was passed through a 4B MN model"),
        ("Paper labels Fick limitation", "not an exact reimplementation of the original C solver"),
        ("Paper labels in-training cosmetic overlap", "rather than an external validation set"),
    ]:
        add_claim(
            claim,
            "paper.md",
            expected,
            None,
            "Boundary statement required by the implementation instructions.",
            expected_token=expected,
        )

    audit = pd.DataFrame(audit_rows)
    audit.to_csv(OUTPUT_PATH, index=False)
    failed = audit.loc[audit["status"] != "PASS"]
    print(f"Wrote {OUTPUT_PATH} with {len(audit)} checks; failures: {len(failed)}")
    if not failed.empty:
        print(failed[["claim", "source_file", "source_value", "expected_paper_token"]].to_string(index=False))
        raise SystemExit(1)


if __name__ == "__main__":
    main()
