# Experiment feature requirements

Version: 1.4  
Status: implementation complete; publication headless reproduction bundle verified; refreshed UI automation awaits macOS user authentication  
Canonical format: Markdown

## 1. Objective

Add a first-class **Experiment** workspace to the Permeation Lab macOS app. It must let a researcher reconstruct every computational step that is identifiable from Yuan et al. (2023), run a deterministic native experiment on Data S1 or a compatible replacement dataset, inspect leakage and provenance, and export a complete run record for future use.

“Complete” means complete with respect to the public evidence. The product must not claim exact reproduction of the paper's Table 4 until the unpublished original train/test assignments and required model artifacts are supplied.

## 2. Users and primary jobs

- Researcher reproducing the paper: load the canonical data, use the disclosed presets, run both outcomes, and compare reconstructed metrics with reported values.
- Researcher designing a follow-up experiment: replace the compatible dataset, change validation strategy, and retain a reusable run artifact.
- Reviewer/auditor: verify dataset identity, split membership, hyperparameters, engine identity, warnings, and per-row predictions without trusting the UI.

## 3. Functional requirements

### FR-0 Verified Facts / My Research separation

- Provide a persistent, screenshot-style selector at the top of the macOS sidebar with two explicit modes:
  - **Paper Evidence**: immutable bundled Data S1 and source-backed paper content.
  - **My Experiment**: a separate user-provided CSV slot whose scientific validity is unverified.
- Entering My Experiment with no imported CSV must use a zero-row state; it must never fall back silently to Data S1.
- Import, replacement, clearing, or a failed import in My Experiment must never mutate the paper slot.
- Switching modes must update every data-dependent workspace atomically and cancel/invalidate a stale in-flight run.
- My Experiment must expose import/replace/remove actions and continuously display an unverified status bar.
- Schema validation covers shape, types, finite values, and supported codes only. It must not be presented as validation of measurement quality, study design, reproducibility, or scientific conclusions.
- Hide paper-only navigation and the Reported Table 4 toolbar action in My Experiment.

### FR-1 Navigation and state

- Add `Experiment` / `エクスペリメント` to the primary sidebar.
- Use accessibility identifiers `nav.experiment` and `screen.experiment`.
- Give the feature its own observable store and asynchronous run lifecycle.
- An active-slot or mode change must invalidate a stale result and refresh readiness; comparison-only data must not.

### FR-2 Dataset snapshot and readiness

- Display source name, row count, schema status, audit error count, and SHA-256 identity.
- Detect whether the active data match the bundled 191-row paper dataset.
- Show the seven predictor fields and selected target.
- Block execution on invalid or empty data.
- Warn when paper reconstruction is requested on a noncanonical dataset.
- Record mode, scientific status, original file name, import timestamp, and hash basis in new run snapshots/exports.
- Preserve source values above 100% and surface them as quality warnings rather than clipping them.

### FR-3 Protocol configuration

- Outcomes: permeation amount and permeation percentage.
- Validation strategies:
  - published-style deterministic 70:30 row split, default seed `0`
  - leave-one-drug-out, with an explicit held-out drug
- In Paper Evidence, lock the published-style split and seed `0`. Use My Experiment for user-configured or leave-one-drug-out work.
- Preserve exact row IDs in both partitions.
- Prevent an empty training or test partition.
- Expose paper hyperparameters as read-only preset values:
  - MLR: seven predictors, no intercept
  - RF: 500 trees; mtry 5 amount / 6 percentage
  - boosting reconstruction: depth 4, eta 0.4, 100 rounds for amount; depth 3, eta 0.2, 45 rounds for percentage

### FR-4 Native execution

- Run MLR, Random Forest, and gradient-tree boosting locally without a network dependency.
- Keep all random operations seeded and deterministic.
- Use only the seven disclosed predictors; never include the alternate outcome because amount is deterministically derived from loading and percentage in Data S1.
- Execute off the main actor and expose running/success/failure states.
- Calculate test-set RMSE, MAE, and conventional R².
- Show `sqrt(SSE)` only as a separately labelled legacy diagnostic for investigating the paper's internally inconsistent Table 4 values.
- Retain observed and predicted values for every test row and model.
- Record elapsed time and engine version.
- Never label the native boosting implementation as the original `xgboost` 1.5.0.2 booster.

### FR-5 Split and leakage audit

- Show training and test counts and per-drug counts.
- Count exact seven-predictor combinations that occur in both partitions.
- Warn when row-level leakage is present.
- In leave-one-drug-out mode, confirm that the held-out drug has zero training rows.

### FR-6 Results and evidence

- Show reconstructed metrics in a sortable/readable table.
- Show paper-reported metrics adjacent to reconstructed metrics only when every guard holds: Paper Evidence mode, `paperSourceVerified` scientific status, bundled raw Data S1 identity, published-style split, seed `0`, the exact deterministic seed-0 row-ID partition (complete, unique, and disjoint 134/57 sets), and the disclosed preset. Treat them as reported references, never a pass/fail equality target.
- Hide Table 4 comparison in My Experiment even when the imported values are semantically identical to Data S1.
- Re-evaluate saved and legacy run Evidence through the current central policy before display or export; never trust an obsolete stored label to promote a personal run.
- Keep a restored paper run's provenance intact, but hide its Table 4 comparison columns whenever the active workspace is My Experiment.
- Provide observed-versus-predicted visualization and model selection.
- State why equality with Table 4 is not an acceptance criterion.
- Classify completed runs as `published-protocol reconstruction`, `leave-one-drug-out generalization validation`, or `compatible-dataset experiment`, based on dataset and validation strategy.
- Separately show `exact-paper replay unavailable` as the current capability/readiness state until authoritative original artifacts are supplied and reconciled.

### FR-7 Run history and export

- Persist a bounded recent-run history locally.
- Allow restoring a recent run into the result view.
- Export a JSON artifact containing:
  - schema and engine versions
  - run ID and timestamps
  - dataset name, row count, and hash
  - outcome, validation strategy, seed, held-out drug, and hyperparameters
  - train/test row IDs
  - leakage audit
  - metrics and every prediction
  - limitations/warnings
- Export must be deterministic in structure and human-readable.
- Distinguish a bundled raw-file SHA-256 from a normalized parsed-value SHA-256.
- Export `researchMode`, scientific status, Table 4 reference eligibility/status, and `exactPaperReplayAvailable: false`.
- A restored run keeps the mode/evidence captured at execution and is not promoted into the currently selected mode.

### FR-8 Fick method coverage

- Include a Fick-method panel describing the published 2D finite-difference inputs, boundary assumptions, stability constraint, and missing provenance.
- Provide an interactive parameterized numerical preview or an explicit non-runnable status; do not silently substitute the existing fitted exponential reference curve.
- A coarse-grid preview must normalize discrete initial mass, use dimensionally consistent sink flux, report mass-balance error, reject non-finite or excessive work, and never clip the result to the loaded mass.
- The panel must state that a paper-wide Fick metric cannot be recomputed without the unpublished per-experiment physical inputs.

### FR-8a Exploratory Fick R² validation

- In My Experiment, provide a separate Fick-derived finite-planar-slab validation. It must never be presented as the paper's two-dimensional finite-difference model or as exact Table 4 replay.
- Define the target as conventional held-out `R² ≥ 0.85` for cumulative permeation percentage. State that this is explained-variation performance, not 85% of drug permeated and not classification accuracy.
- Use the fixed finite-slab release form `prediction = A × F(k × time)`, truncate the odd-term Fick series at 80 terms, constrain `A` to 0–100%, and calibrate `A` and effective rate `k` from training rows only.
- Define a proxy condition from drug, loading, molecular weight, MN length, skin code, MN type, and MN surface area, excluding time. Define a family from drug, skin code, and MN type.
- Hold out every proxy condition as a complete outer fold. Evaluate only families with at least three proxy conditions so every fold retains at least two training conditions.
- Report pooled out-of-fold conventional R², RMSE, MAE, all row predictions, every fold's fitted parameters and IDs, family metrics, included/excluded scope, and a leave-one-family-out stress result.
- Use deterministic resampling of fixed OOF predictions by condition cluster with a recorded seed and iteration count. Record whether each replicate refits the model and whether sampling is family-stratified; the current implementation does neither.
- Label the resulting 2.5th–97.5th percentiles, fifth percentile, and target-exceedance share as a descriptive fixed-prediction cluster-composition distribution, not a generic confirmatory confidence interval, p-value, posterior probability, or future-success probability.
- Display `point estimate met` and the app's internal lower-percentile criterion as separate outcomes. A point estimate above 0.85 with a fifth percentile below 0.85 is provisional only.
- Persist a bounded local history and export a complete JSON artifact with dataset mode/status/hash, configuration, metrics, folds, predictions, warnings, and limitations.
- Provide a direct headless execution path that accepts explicit absolute input/output paths, invokes the scientific engine without SwiftUI or `UserDefaults`, writes atomically, and refuses to overwrite an existing result.
- Provide a one-command publication harness that records the environment and source/input hashes, runs clean unit tests and a signed Release build, executes two fresh processes, requires byte-identical scientific payloads after removing run-envelope fields, exports all primary/stress rows and folds, verifies leakage assertions, archives the exact source, and emits a SHA-256 manifest.
- Report row-pooled results alongside family metrics and explicitly post-hoc condition-balanced, family-centered, and macro-family aggregation diagnostics so the 0.85 claim cannot depend on one pooled weighting scheme alone.
- Label the proxy grouping as a response to missing run/curve IDs, not a substitute for independent-run or external validation. Keep every such run in My Experiment and scientifically unvalidated even when its values match Data S1.

### FR-9 Bilingual, accessible UX

- Every user-facing string must support English and Japanese.
- Support keyboard access, VoiceOver labels, and the 1050 × 700 compact test window.
- Give the mode selector and both choices stable accessibility identifiers and a non-colour selected-state indicator.
- Use existing `Lab*` design components, native colors, and macOS controls.
- Avoid clinical/dosing language and include a research-only boundary.

## 4. Non-functional requirements

- Determinism: identical dataset, configuration, and engine version produce identical split IDs and predictions.
- Performance: the default 191-row run should complete without blocking navigation; target under 10 seconds on the repository's supported Mac.
- Reliability: failures must preserve the previous successful run and provide a localized message.
- Lifecycle: a run must survive navigation, expose cancellation, and cancel stale work when the training dataset changes.
- Privacy: all computation and recent-run persistence are local.
- Portability: exported JSON must not contain absolute local file paths.
- Maintainability: experiment domain, execution, persistence, and UI are separate Swift files.

## 5. Scientific acceptance criteria

- Data S1 parses to 191 rows and 11 columns with no audit errors.
- The canonical bundled CSV hash is displayed and exported.
- Default row split contains 134 training and 57 test rows.
- Repeating a run with the same seed produces identical row IDs, metrics, and predictions.
- Changing the seed changes at least one row assignment.
- Leave-one-drug-out contains the selected drug only in the test partition.
- All reported metric labels say `reported`, and all local metrics say `reconstructed`.
- The UI and export both name the unavailable artifacts that prevent exact Table 4 replay.
- An imported semantic copy of Data S1 in My Experiment remains user-provided/unvalidated and never receives paper evidence or Table 4 eligibility.
- Switching back to Paper Evidence restores the unchanged 191-row bundled source.
- No existing workspace or dataset flow regresses.
- Fick preview is nonnegative and monotonic, satisfies the explicit stability condition, and conserves discrete mass within tolerance.
- The exploratory Fick proxy run is deterministic, keeps every proxy condition disjoint between calibration and evaluation, and records a conventional metric/CI pair without relabelling either as accuracy.
- The Data S1 exploratory fixture reaches the row-pooled 0.85 point target while failing the app's fixed-prediction fifth-percentile criterion and every family-specific 0.85 target; these distinct states are visible and exported.

## 6. Out of scope for this version

- Clinical decision support, dosing recommendations, or patient-specific prediction.
- Claiming independent validation of the paper's reported performance.
- Bundling a full R 4.1.2 runtime, RStudio, Microsoft Visual Studio, or the original unreleased models.
- Inventing the original train/test split or undocumented Fick parameters.
- Claiming that proxy-condition validation is leave-one-run-out, external validation, or confirmation of Fick `R² ≥ 0.85`.
- General-purpose ingestion of arbitrary schemas; follow-up data must use the existing compatible schema.
- Arbitrary new drug labels in the Experiment runner; the current typed LODO workflow accepts the six Data S1 drug names.
