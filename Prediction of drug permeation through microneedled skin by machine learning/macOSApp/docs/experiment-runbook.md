# Experiment execution runbook

## Purpose

Use this runbook to execute, audit, and hand off a Yuan et al. published-protocol reconstruction in Permeation Lab. It also defines what to do if the authors' original split or model artifacts become available.

## Mode selection

Use the selector at the top of the sidebar before reading or running data:

- **Paper Evidence** uses the immutable bundled Data S1 and source-backed paper material. A green source-backed status remains visible.
- **My Experiment** uses only the separately imported personal CSV. An orange unverified status remains visible. With no CSV, the mode contains zero rows and cannot run; it never borrows Data S1.

The mode choice is part of each new run's provenance. A schema-valid My Experiment CSV is still scientifically unverified. Switching modes preserves the personal slot for the current app session but does not persist the source CSV itself; retain the original CSV and re-import it after relaunch. Saved run history and JSON do not replace the source dataset.

## A. Canonical reconstruction

1. Launch Permeation Lab, select **Paper Evidence**, then select **Experiment**.
2. Confirm the dataset card shows:
   - `Yuan 2023 · Data S1`
   - 191 observations
   - valid schema/audit
   - canonical SHA-256 identity
3. Choose an outcome:
   - permeation amount, or
   - permeation percentage.
4. Confirm **Published-style 70:30 row split** and seed `0` are locked in this mode.
5. Review the read-only model preset:
   - MLR without intercept
   - RF with 500 trees and target-specific mtry; note the exported native depth/node-size settings
   - native boosting reconstruction with the disclosed depth, eta, and rounds
6. Select **Run published protocol** and wait for completion.
7. Verify the result shows 134 training rows and 57 test rows.
8. Review:
   - reconstructed RMSE, MAE, and R²
   - paper-reported comparison values
   - observed-versus-predicted plot
   - per-drug split counts
   - identical-condition overlap warning
   - engine/evidence label
9. Export the run JSON. Store that file beside the dataset and any lab protocol used for the follow-up study.
10. Repeat for the other outcome. Do not combine metrics from different run IDs without retaining both manifests.

## B. Generalization check

1. Switch to **My Experiment** and import the compatible CSV to be evaluated.
2. Select **Leave one drug out** and choose the drug that represents the intended unseen candidate.
3. Run the experiment.
4. Confirm the selected drug has zero training rows and all of its rows are in test.
5. Confirm Table 4 values are hidden because the evaluation scope is not comparable.
6. Treat negative R² or physically impossible predictions as evidence of poor generalization, not as data to clip silently.
7. Compare with the row-split run. Prefer the leave-one-drug-out result when the scientific question concerns a genuinely unseen drug.

## C. Follow-up dataset

1. Switch to **My Experiment**. Confirm the status says paper data are not in use.
2. Select **Import experiment CSV** and load a compatible 11-column file.
3. Confirm the displayed file name, row count, unverified badge, import provenance, and normalized-value hash.
4. Resolve every schema/audit error before running. Remember that passing these checks does not validate the science.
5. Choose a validation strategy that matches the intended claim:
   - row split for interpolation within represented experimental conditions
   - leave-one-drug-out for an unseen-drug claim
6. Run and export. Confirm JSON records `myExperiment`, `userProvidedUnvalidated`, Table 4 unavailable outside Paper Evidence, and exact replay unavailable.
7. Switch back to Paper Evidence and confirm the original 191-row Data S1 returns unchanged.

The Experiment parser currently uses the six Data S1 drug labels for typed grouping and LODO: `BSA`, `copper ions`, `GHK peptide`, `Rhodamine B`, `lidocaine`, and `caffeine`. Use skin codes 1/2 and MN type codes 1/2. The separate study-comparison importer may accept other labels, but that does not make them active Experiment training data.

## D. Fick R² 85% exploratory proxy validation

Use this workflow only in **My Experiment**. It measures held-out explained variation; it does not mean that 85% of loaded drug permeated.

1. Import a schema-compatible CSV, or reproduce the documented Data S1 exploratory copy with the developer launch command below.
2. Confirm the dataset remains labelled My Experiment / scientifically unvalidated. A Data S1 value copy must not show Paper Evidence or Table 4 references.
3. In **Fick 85% proxy validation**, confirm the fixed target is conventional pooled OOF `R² ≥ 0.85`.
4. Run the validation. The engine holds out every exact predictor condition, excluding time, and fits the Fick finite-slab parameters from other conditions in the same drug/skin/MN family only.
5. Check all three decisions together:
   - point-estimate target;
   - the app's internal fifth-percentile criterion;
   - leave-one-family-out stress result.
6. Inspect included/excluded families, family metrics, proxy-condition count, fixed-prediction resampling seed/iterations, and limitations.
7. Export JSON and retain it with the source CSV and this runbook.

Expected 2026-08-30 exploratory Data S1-copy result is approximately:

- eligible scope: 3 families, 12 proxy conditions, 112 observations;
- pooled OOF R²: 0.895;
- RMSE: 9.599 percentage points;
- MAE: 6.718 percentage points;
- fixed-OOF condition-cluster 2.5th–97.5th percentiles: about 0.739–0.947;
- fixed-OOF condition-cluster fifth percentile: about 0.780;
- resampled composition share with R² ≥ 0.85: 0.7736;
- condition-balanced R²: about 0.862;
- family-centered pooled R²: about 0.593;
- macro-family R²: about 0.338;
- leave-one-family-out stress R²: about -0.136.

This is a **post-hoc row-pooled point-estimate pass only**. All three family R² values are below 0.85. The resampling reuses already-fixed OOF predictions, does not refit the model, is not stratified by family, and must not be called a generic confirmatory 95% confidence interval or future-success probability. The protocol was selected exploratorily after examining Data S1, and the source lacks true run/curve IDs. Do not report it as confirmed 85% performance, external validation, or improvement over the paper's unpublished split.

Canonical publication reproduction from `macOSApp/` uses a new absolute output path:

```bash
./scripts/reproduce-fick-r2-85.sh \
  '/absolute/path/to/fick-r2-85-publication-bundle'

./scripts/verify-fick-r2-85.sh \
  '/absolute/path/to/fick-r2-85-publication-bundle'
```

This path runs unit tests, builds/signs Release, invokes the direct headless engine in two fresh processes, compares scientific JSON byte-for-byte, exports every prediction/fold and diagnostic, archives the exact source, and verifies a SHA-256 artifact manifest. It does not use SwiftUI visibility or `UserDefaults`.

The direct headless executable interface is:

```bash
dist/PermeationLab.app/Contents/MacOS/PermeationLab \
  -fick-85-headless-input '/absolute/path/to/input.csv' \
  -fick-85-headless-output '/absolute/path/to/new-result.json'
```

For visual/manual UX inspection only, launch after packaging with:

```bash
open -na dist/PermeationLab.app --args \
  -fick-85-my-experiment \
  -fick-85-auto-run
```

The first flag creates a personal/unvalidated in-memory copy of bundled Data S1; the second runs the proxy protocol once. Neither flag changes the Paper Evidence slot. This GUI route is not the canonical publication reproduction path.

## E. Fick 2D numerical method

1. Open the Fick section in Experiment.
2. Use **Reset to Data S2 example** to restore D = 700 µm²/min, 64 MNs, length = 1,000 µm, mass = 1,637 µg, and 50 h. Record that 50 h conflicts with the paper's stated 48 h upper range.
3. Record diffusivity, MN count, needle/skin geometry, loaded mass, grid size, stability-selected time step, and duration from the actual protocol.
4. Confirm the result reports a near-zero mass-balance error. The preview does not clip values to 100%.
5. Treat the 25 µm coarse-grid run as a mass-consistent numerical preview, not literal output from the 2 µm SI2 listing. The 25 µm spacing exactly divides the 1,000 µm depth, 250 µm half-domain, and 75 µm needle half-width in the source example.
6. For a publication-grade run, preserve the exact spatial/time resolution and the complete parameter source. Do not infer a missing per-drug parameter from Table 4.

## F. If authoritative original artifacts arrive

Required minimum:

- original `train set.csv` and `test set.csv`, or a one-based Data S1 row-to-partition manifest
- exact preprocessing/column naming used before Data S2
- fitted MLR coefficients, RF object, and XGBoost booster or a reproducible environment lock
- per-row test predictions
- per-experiment Fick diffusivity and geometry settings

Procedure:

1. Hash and archive every received source artifact unchanged.
2. Map split rows to Data S1 and require a one-to-one match; do not resolve duplicate rows by guesswork.
3. Run the original R 4.1.2 package versions in an isolated environment.
4. Compare per-row predictions before comparing aggregate metrics.
5. Import the authoritative row manifest into the app once supported.
6. Change the evidence label to exact-paper replay only after row membership, predictions, and metrics independently reconcile.

## G. Verification commands for developers

From `macOSApp/`:

```bash
xcodebuild build -quiet \
  -project PermeationLab.xcodeproj \
  -scheme PermeationLab \
  -configuration Debug \
  -destination 'platform=macOS' \
  -derivedDataPath /tmp/permeation-lab-derived \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO

xcodebuild test -quiet \
  -project PermeationLab.xcodeproj \
  -scheme PermeationLab \
  -destination 'platform=macOS,arch=arm64' \
  -derivedDataPath /tmp/permeation-lab-derived

./scripts/build-app.sh

./scripts/reproduce-fick-r2-85.sh \
  '/absolute/path/to/new-fick-reproduction-bundle'

./scripts/verify-fick-r2-85.sh \
  '/absolute/path/to/new-fick-reproduction-bundle'
```

The shared scheme includes `PermeationLabTests` and `PermeationLabUITests`. The packaging command replaces `dist/PermeationLab.app` and ad-hoc signs the result.

Expected dedicated checks:

- 191 rows, 11 columns, zero audit errors, six published drug counts
- complete, unique, disjoint 134/57 seed-0 IDs matching the fixed reference partition, and a different split for seed 1
- identical split, metrics, and 171 predictions across repeated seed-0 runs
- caffeine leave-one-drug-out = 173/18, zero caffeine in training
- `sqrt(SSE) = RMSE × sqrt(n)`
- Fick stability, monotonicity, nonnegativity, mass conservation, and work-limit rejection
- UI navigation and an end-to-end Experiment run showing results, split audit, chart, and export
- Paper/My selector changes the available navigation and hides Reported Table 4 in My Experiment
- My Experiment starts with dedicated no-data import screens, keeps its CSV separate, and never promotes a semantic Data S1 copy or a restored Paper run to visible paper comparison

macOS UI tests require Automation Mode. If `xcrun automationmodetool` reports that it is disabled, a user must enable it with local authentication before rerunning UI automation; do not treat a pre-launch authentication timeout as an app test failure.

## Interpretation boundary

This workflow supports computational research and experimental planning. It is not validated for diagnosis, dosing, therapeutic efficacy, toxicity, or patient-safety decisions.
