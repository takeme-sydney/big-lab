---
title: Fick R2 0.85 publication reproduction protocol
version: 1.0
date: 2026-08-30
status: frozen-post-hoc-computational-protocol
canonical-format: Markdown
---

# Fick R² 0.85 publication reproduction protocol

## Scope and status

This protocol reproduces the **post-hoc exploratory computation** implemented as `fick-finite-slab-release-proxy-v1`. It was frozen after model and endpoint development on the Data S1 values, so it is not a preregistered confirmatory protocol. It establishes computational repeatability of this implementation; it does not establish independent replication, external validation, physical diffusivity, or exact replay of Yuan et al.'s two-dimensional Fick calculation or Table 4.

The canonical scientific mode is **My Research** (stored enum: `myExperiment`) / user-provided unvalidated. A value-identical Data S1 CSV must not be promoted to Verified Facts.

## Frozen input

| Field | Required value |
| --- | --- |
| CSV path in source tree | `Sources/PermeationLab/Resources/yuan2023_training_data.csv` |
| Raw CSV SHA-256 | `03ff02276f333d06747efb7a625e9de1b4055b94b8736873f5e7cc389315b0f5` |
| Parsed-value SHA-256 | `a0f8cd81f2369e08d0155a8644ff8ee1cb9128b16ee1bcea72c4df7e91848a07` |
| Shape | 191 rows × 11 columns |
| Schema errors permitted | 0 |
| Observations above 100% | retained, not clipped |

The raw-byte hash and parsed-value hash deliberately differ. The headless My Research result records the parsed-value hash because the imported file is treated as user-provided; the reproduction harness separately verifies the raw CSV bytes.

## One-command execution

From `macOSApp/`, choose a new absolute output path that does not already exist:

```bash
./scripts/reproduce-fick-r2-85.sh \
  '/absolute/path/to/fick-r2-85-publication-bundle'
```

Then verify the immutable artifact manifest and scientific assertions:

```bash
./scripts/verify-fick-r2-85.sh \
  '/absolute/path/to/fick-r2-85-publication-bundle'
```

The reproduction script refuses to overwrite an existing output path. This prevents a rerun from silently mixing with or replacing an earlier record.

## What the command executes

1. Sets `LC_ALL=C`, `LANG=C`, `TZ=UTC`, and a fixed file-creation mask.
2. Records macOS, architecture, Xcode, Swift, jq, Git-state, and Automation Mode metadata without publishing the user name or host name in `environment.txt`.
3. Hashes every source, test, documentation, script, and Xcode-project file and archives an exact source snapshot.
4. Requires the frozen raw CSV hash before any calculation.
5. Runs the complete `PermeationLabTests` target in clean temporary DerivedData and requires 15/15 passed, zero failed, and zero skipped.
6. Builds and ad-hoc signs the Release application; verifies the signature and requires the packaged CSV to be byte-identical to the source CSV.
7. Starts the application executable twice as separate processes using the direct headless entry point. The computation does not instantiate the SwiftUI workspace, read or write `UserDefaults`, or depend on window visibility.
8. Requires exact schema, configuration, dataset, scope, primary metric, resampling, and stress-test values from both runs.
9. Removes only run-envelope fields (`id`, start/completion timestamps, elapsed seconds) and requires the remaining scientific JSON files to be byte-identical.
10. Exports row predictions, condition/family metrics, outer folds, stress predictions/folds, leakage checks, and post-hoc aggregation diagnostics.
11. Re-hashes the source tree and requires it to be unchanged during execution.
12. Closes the run log, creates a path-sanitized public log, hashes every output artifact, and verifies the manifest.

The direct executable interface is:

```bash
dist/PermeationLab.app/Contents/MacOS/PermeationLab \
  -fick-85-headless-input '/absolute/path/to/input.csv' \
  -fick-85-headless-output '/absolute/path/to/new-result.json'
```

Both arguments are mandatory and absolute. The output file must not already exist.

## Frozen model and fitting algorithm

For time `t` in hours, the implemented two-parameter time-only release proxy is:

```text
F(x) = 1 - (8 / π²) Σ[n=0...79] exp(-(2n+1)²x) / (2n+1)²
ŷ(t) = A F(k t)
```

`F(0)` is explicitly set to zero. `A` is constrained to `[0, 100]` percentage points and `k` to `[10⁻⁸, 100] h⁻¹`. Loading, molecular weight, MN length, surface area, skin code, and MN type are grouping fields only; they are not numerical covariates in `ŷ(t)`.

For every outer fold, the engine evaluates 401 log-spaced `k` values, refines the best interval for 80 golden-section iterations, and computes the training-only closed-form amplitude

```text
A = clamp(Σ fᵢyᵢ / Σ fᵢ², 0, 100), where fᵢ = F(k tᵢ).
```

The objective is unweighted training-row SSE. Equal SSE is resolved in favor of the lower `k`. No tolerance-based condition matching or per-run weighting is applied.

## Grouping and validation

`family = drug name × skin code × MN type code`.

`condition proxy = family × loading × molecular weight × MN length × MN surface area`; time and outcome are excluded. Floating-point components use exact parsed bit patterns. A family is eligible when it has at least three proxy conditions.

The primary internal evaluation leaves one proxy condition out within each eligible family, fits `A` and `k` using all remaining rows in that family, and predicts every time-point row of the held-out condition. It yields 12 folds and 112 OOF rows from three eligible families. Six families, six proxy conditions, and 79 rows are excluded from the primary endpoint by the eligibility rule.

The row-pooled predictive metrics are:

```text
R² = 1 - Σ(yᵢ - ŷᵢ)² / Σ(yᵢ - ȳ)²
RMSE = √[Σ(yᵢ - ŷᵢ)² / n]
MAE = Σ|yᵢ - ŷᵢ| / n
```

The bundle also reports three explicitly post-hoc aggregation sensitivities:

- family-centered pooled R², using within-family observed TSS;
- macro-family R², the unweighted mean of three family R² values;
- condition-balanced R²/RMSE/MAE, assigning each of 12 conditions weight `1/12` and equal weight to rows within each condition.

## Resampling interpretation

The exported `confidenceInterval` object is a deterministic **fixed-OOF-prediction condition-cluster composition percentile distribution**:

- 20,000 replicates;
- SplitMix64 seed `20260830`;
- 12 condition proxies sampled with replacement per replicate;
- all rows of a sampled proxy retained together;
- R² recomputed from the sampled, already-fixed OOF prediction pairs;
- linear-interpolated empirical quantiles.

The model is not refitted inside a replicate, families are not stratified, and covariance from overlapping training folds is not modeled. Consequently, the 2.5th–97.5th percentiles, fifth percentile, and exceedance share are descriptive exploratory quantities, not a generic confirmatory confidence interval, p-value, posterior probability, or estimated probability that a future experiment succeeds.

## Required expected values

| Quantity | Frozen expectation |
| --- | ---: |
| Row-pooled OOF R² | `0.8951421556980397` |
| Row-pooled RMSE | `9.598790998288257 pp` |
| Row-pooled MAE | `6.718231271867532 pp` |
| Fixed-prediction 2.5th–97.5th percentiles | `0.7391961375054618–0.9469124716928526` |
| Fixed-prediction fifth percentile | `0.7804721110215499` |
| Fixed-prediction share with R² ≥ 0.85 | `0.7736` |
| Family-centered pooled R² | `0.5927921179367703` within `1e-12` |
| Macro-family R² | `0.3383464746508844` within `1e-12` |
| Condition-balanced R² | `0.8616083735524461` within `1e-12` |
| Leave-one-family-out stress R² | `-0.13586687519274854` |
| Point threshold | met |
| Internal lower-percentile criterion | not met |
| Exact paper replay | unavailable |

Exact equality is required for engine-exported scientific JSON on the recorded binary/environment. Derived jq aggregation checks use `1e-12` for R² and `1e-9` for sums of squares because summation order can differ across tools. Cross-toolchain or cross-architecture reproducibility must declare a tolerance before comparison.

## Bundle contents

| Artifact | Purpose |
| --- | --- |
| `README.md` | exact copy of this canonical execution protocol |
| `MANUSCRIPT-SUPPLEMENT.md` | manuscript-ready Methods, Results, limitations, and reporting map |
| `REPRODUCTION-AUDIT-TRAIL.md` | failed/superseded attempts, causes, corrections, and adoption decision |
| `run-01.json`, `run-02.json` | complete run envelopes and scientific results |
| `run-*.scientific.json` | dynamic envelope removed for byte comparison |
| `predictions.csv` | all 112 primary OOF rows |
| `folds.csv` | all 12 outer folds, fit parameters, and row IDs |
| `condition-metrics.csv` | every eligible condition result |
| `family-metrics.csv` | every eligible family result |
| `stress-predictions.csv`, `stress-folds.csv` | all-family stress evaluation |
| `publication-diagnostics.json` | post-hoc weighting, calibration, and boundary diagnostics |
| `fold-integrity.json` | training/test separation assertions |
| `test-summary.json`, `test.log`, `build.log`, `binary-format.txt` | complete local QA evidence; may contain device ID or workstation paths |
| `test-summary.public.json`, `test.public.log`, `build.public.log`, `binary-format.public.txt` | device/path-sanitized QA evidence for external sharing |
| `environment.txt` | software and platform record |
| `source-snapshot.tar.gz` | exact source because the enclosing Git commit does not track this app directory |
| `source-files.before.sha256`, `source-files.after.sha256` | source stability check |
| `commands.log`, `commands.public.log` | local full log and path-sanitized public log |
| `artifact-manifest.sha256` | checksum of every bundle file except the manifest itself |

The local `commands.log`, raw test/build logs, raw test summary, and raw binary-format record can contain workstation paths or a device identifier. For sharing, use `commands.public.log`, `test.public.log`, `build.public.log`, `test-summary.public.json`, and `binary-format.public.txt`. Raw versions remain in the local integrity manifest for auditability.

## Failure handling

- Raw-input hash mismatch: stop; do not relabel a different dataset as this reproduction.
- Any test/build/signature failure: retain the failed bundle as a failed attempt under a distinct path; do not merge it with a passing run.
- Scientific JSON mismatch: compare dataset identity, configuration, fold order, source hash, toolchain, and architecture before considering numerical tolerance.
- Source before/after mismatch: discard the run as non-frozen and rerun from an unchanged snapshot.
- Manifest failure: treat the bundle as altered or incomplete.

## Confirmation boundary

The next confirmatory study requires prospective protocol registration, true `experiment_run_id` and `permeation_curve_id`, donor/batch/site identifiers, a frozen model, and independent new experiments. Its uncertainty procedure must be designed around the actual sampling hierarchy and refit the complete pipeline where appropriate. The current 3-family/12-proxy dataset is not sufficient to claim generalization to unseen families or a confirmatory lower bound of R² ≥ 0.85.
