# Experiment implementation execution record

Date: 2026-08-31  
Scope: Permeation Lab macOS Experiment workspace  
Canonical documentation: Markdown

## Delivered implementation

- Added an Experiment workspace to the existing bilingual SwiftUI navigation.
- Added a persistent experiment store with run, cancel, failure, success, restore, history, stale-result, and dataset-invalidation behavior.
- Added deterministic published-style 70:30 and leave-one-drug-out partitions with exact row-ID provenance and matching-condition leakage audit.
- Added no-intercept OLS, a seeded 500-tree native Random Forest reconstruction, and a native gradient-tree boosting reconstruction with outcome-specific paper presets.
- Added conventional RMSE, MAE, optional R², diagnostic `sqrt(SSE)`, per-row predictions, paper comparison gating, and JSON export.
- Added raw-byte versus normalized-value SHA-256 labelling.
- Added a grid-consistent Fick 2D preview with a 25 µm grid that exactly divides the source example geometry, source-example reset, stability-selected time step, cancellation, work cap, mass normalization, dimensionally consistent sink flux, and mass-balance reporting.
- Added a shared Xcode scheme, a dedicated unit-test target, and Experiment UI coverage.
- Added an always-visible `Verified Facts / My Research` selector (internal enum: `paperEvidence / myExperiment`), an immutable paper-data slot, and a separate optional personal-data slot with no paper fallback.
- Added persistent mode context, localized scientific-status labels, dedicated no-data import states, mode-specific navigation, and hidden paper-only Table 4 controls in My Experiment.
- Added central Evidence/Table 4 policy checks for mode, scientific status, raw canonical identity, exact deterministic split IDs, seed, and preset; current policy is also applied to legacy history on display/export.
- Added export schema 2.0 provenance for mode, scientific status, Table 4 eligibility, import time, hash basis, and the explicit `exactPaperReplayAvailable: false` state.
- Added a My Experiment-only finite-planar-slab Fick proxy validator with training-only `A`/`k` fitting, 12 leave-one-proxy-condition-out folds, deterministic condition-cluster bootstrap, family metrics, and a nine-family transfer stress test.
- Added a top-positioned Fick decision panel with separate point and internal-bootstrap criteria, included/excluded scope, local history, complete JSON export, cancellation, dataset mismatch protection, and explicit separation from Paper/Table 4 and the Fick 2D mass-fraction preview.
- Added the reproducibility launch pair `-fick-85-my-experiment -fick-85-auto-run`; it creates an unvalidated personal Data S1 value copy, opens Experiment, executes once, and stores schema 1.1 output without changing Paper Evidence.
- Added a direct headless entry point, `-fick-85-headless-input` plus `-fick-85-headless-output`, which invokes the tested engine before SwiftUI creation and bypasses `UserDefaults`.
- Added `scripts/reproduce-fick-r2-85.sh` and `scripts/verify-fick-r2-85.sh` for clean tests/build, two fresh-process repeats, full prediction/fold exports, source snapshot, environment and command logs, leakage assertions, post-hoc weighting diagnostics, and a verified SHA-256 artifact manifest.
- Added eight bilingual decision-reason cards to My Research and the active Fick audit, with values generated from replay-audited diagnostics, beginner and reviewer explanations, stable accessibility identifiers, and regression checks tying each explanation to its source metric.
- Corrected the old “only row-pooled exceeded 0.85” wording: row-pooled `0.895142` and condition-balanced `0.861608` are both post-hoc aggregation points above the numerical threshold; family-centered, macro-family, all family-specific results, lower sensitivity, unseen-family transport, and external confirmation remain below or unavailable.

## Verification evidence

### Fick R² 0.85 My Experiment execution

The canonical publication computation was run with:

```bash
./scripts/reproduce-fick-r2-85.sh \
  '/absolute/path/to/fick-r2-85-publication-bundle-v6'

./scripts/verify-fick-r2-85.sh \
  '/absolute/path/to/fick-r2-85-publication-bundle-v6'
```

The latest harness passed all 15 unit tests, built and verified the ad-hoc signed Release app, required exact raw and normalized dataset hashes, executed two separate headless processes, and produced byte-identical scientific payloads after removing only UUID/timestamp/elapsed envelope fields. Fold-integrity checks found disjoint training/test row sets, no held-out proxy condition in its fold's training-condition IDs, 112 unique primary test rows, and 191 unique stress-test rows. The exact machine-readable evidence is in `study/reproducibility/fick-r2-85-publication-bundle-v6/`; v1–v5 are superseded history artifacts and were not modified.

| Aggregation audit | R² | RMSE (pp) | MAE (pp) |
| --- | ---: | ---: | ---: |
| Row-pooled OOF | **0.8951421556980397** | 9.598790998288257 | 6.718231271867532 |
| Condition-balanced, 12 conditions equal weight | 0.8616083735524461 | 11.948732635911943 | 8.455595071422747 |
| Family-centered pooled | 0.5927921179367703 | — | — |
| Macro-family | 0.3383464746508844 | — | — |

The last three values are explicitly post-hoc descriptive sensitivities, not preregistered endpoints. Every family-specific R² was below 0.85. One of 12 primary fits and eight of nine stress fits reached the `A=100` boundary.

The deterministic 20,000-replicate output is a **fixed-OOF-prediction condition-cluster composition percentile distribution**: it resamples 12 already-predicted conditions, does not refit the model inside a replicate, is not family-stratified, and does not model covariance from overlapping training folds. Its 2.5th–97.5th percentiles (`0.7391961375054618–0.9469124716928526`), fifth percentile (`0.7804721110215499`), and threshold exceedance share (`0.7736`) are descriptive; they are not a generic confirmatory confidence interval, p-value, or future-success probability.

The enclosing Git commit does not track the macOSApp directory, so it does not identify this source. The bundle therefore contains an exact `source-snapshot.tar.gz` and source-file hashes captured before and after execution; the two lists were identical.

### Historical visual auto-run

The packaged Release app was launched with:

```bash
open -na dist/PermeationLab.app --args \
  -fick-85-my-experiment \
  -fick-85-auto-run
```

Latest persisted run ID: `D0D9E0FC-EFBC-439C-B384-FC5CC244FEFF`  
Schema/model: `1.1` / `fick-finite-slab-release-proxy-v1`  
Release elapsed time recorded by the final app: `0.2704374583 s`

| Output | Persisted value |
| --- | ---: |
| Eligible scope | 3 families / 12 proxy conditions / 112 rows |
| Excluded scope | 6 families / 79 rows |
| Pooled OOF R² | **0.8951421556980397** |
| RMSE | 9.598790998288257 pp |
| MAE | 6.718231271867532 pp |
| Fixed-OOF condition-cluster 2.5th–97.5th percentiles | 0.7391961375054618–0.9469124716928526 |
| Fixed-OOF condition-cluster fifth percentile | 0.7804721110215499 |
| Resampled composition share with R² ≥ 0.85 | 0.7736 |
| Leave-one-family-out stress R² | -0.13586687519274854 |

The persisted Evidence state is `exploratoryProxyConditionCrossValidation`; dataset mode/status are `myExperiment` / `userProvidedUnvalidated`; `isBundledSource` and `exactPaperReplayAvailable` are both false. The app therefore stores `pointPass: true` and `confidencePass: false` and displays **point estimate met; confirmation not met**. The result is not paper Evidence, independent validation, or a replay of the original 2D Fick/Table 4 calculation.

The auto-run history value was read back from `UserDefaults` and decoded as JSON. It includes configuration, dataset identity, every prediction with time, fold membership/fitted parameters, fixed-prediction resampling output, warnings, limitations, and the full nine-family/191-row stress result. This visual route is historical UX evidence; the direct headless bundle above is the canonical scientific reproduction path.

### Unit tests

Command:

```bash
xcodebuild test \
  -project PermeationLab.xcodeproj \
  -scheme PermeationLab \
  -configuration Debug \
  -destination 'platform=macOS' \
  -derivedDataPath .build/DerivedData \
  CODE_SIGNING_ALLOWED=NO \
  -only-testing:PermeationLabTests
```

Original Experiment baseline result: 7 tests executed, 0 failures.

The deterministic amount run produced 134 training and 57 test rows, 171 predictions across three models, and 28 predictor-condition combinations shared across the row split. Repeating the fixed configuration produced identical split, metrics, and predictions. Caffeine leave-one-drug-out produced 173 training and 18 test rows, with zero caffeine rows in training and zero shared predictor conditions.

### Current integrated unit verification

The current source was tested through the shared Xcode scheme in a clean temporary DerivedData directory.

Final result: **15 tests executed, 15 passed, 0 failures, 0 skipped**. The `xcresult` summary reported `Passed`.

The added cases verify that:

- a My Experiment copy of canonical values cannot claim paper Evidence or Table 4 eligibility;
- inconsistent scientific status and normalized imports are rejected by the Table 4 policy;
- overlapping, incomplete, or different 134/57 split IDs are rejected, including a seed-1 partition presented with a seed-0 configuration;
- old personal-history JSON carrying a stale `published-protocol reconstruction` label is reclassified before display/export;
- paper and personal dataset slots remain separate through import, switch, and clear operations;
- Verified Facts and My Research navigation allowlists remain mutually exclusive;
- the bundled literature library loads exactly 30 complete, ID/DOI-unique papers from RFC 4180 CRLF CSV;
- history persistence, restore, and clear actions are mode-scoped, and cross-mode restore is rejected without changing state.
- the Fick proxy is deterministic, keeps every held-out condition disjoint, preserves `A`/`k` constraints, emits the exact 20,000-replicate SplitMix64 interval, exports/decodes schema 1.1, keeps oversized-save failures from erasing existing history, rejects Paper Evidence execution, and defines the physical time-zero boundary as zero release.

### Previously completed end-to-end UI run

Command: the focused `PermeationLabUITests/testExperimentCanRunEndToEnd` test in a clean temporary DerivedData directory.

Result: passed. Automation navigated to Experiment, invoked the keyboard-accessible run action, and observed reconstructed results, split audit, prediction chart, and JSON export controls.

### Previously completed baseline full suite

Command:

```bash
xcodebuild test \
  -project PermeationLab.xcodeproj \
  -scheme PermeationLab \
  -configuration Debug \
  -destination 'platform=macOS' \
  -derivedDataPath <clean-temporary-directory>
```

Result: 14 tests executed, 14 passed, 0 failures, 0 skipped. This historical baseline includes the original seven unit tests and seven signed macOS UI tests before the mode-separation additions.

### Refreshed UI automation status

Three separation-focused current-source UI tests passed, with 0 failures and 0 skipped. They verified the Verified Facts navigation and 30-paper screen, exclusion of paper-only destinations from My Research, and the always-visible mode tabs while switching Facts → My Research → Facts without dataset crossover. An earlier run hung before the runner connected; the clean rerun completed in 109.5 seconds, so the pre-connection hang is retained as infrastructure history rather than counted as an app failure.

### Build

Debug `build-for-testing` result: succeeded with no Swift compiler errors, including the updated unit and UI targets.

Release packaging result: `scripts/build-app.sh` succeeded and produced a universal arm64/x86_64 `dist/PermeationLab.app`. `codesign --verify --deep --strict` reported the app valid on disk and satisfying its designated requirement. The executable SHA-256 is recorded in the latest bundle's `app-executable.sha256` rather than copied here. The packaged `yuan2023_training_data.csv` SHA-256 exactly matched the canonical source hash `03ff02276f333d06747efb7a625e9de1b4055b94b8736873f5e7cc389315b0f5`; `latest_30_papers.csv` contained 30 unique IDs and DOI values.

## Scientific completion boundary

The implementation completely records and reruns the workflow that can be reconstructed from public evidence. It does not label Table 4 as exactly reproduced because the original train/test row assignments, preprocessing mapping, fitted R model objects, per-row predictions, and complete per-experiment Fick inputs were not published. Exact-paper replay remains unavailable until authoritative artifacts are supplied and reconciled row by row.

## Documentation set

- `experiment-platform-research.md`: source and system research
- `experiment-requirements.md`: requirements definition
- `experiment-implementation-prompt.md`: implementation instruction
- `experiment-runbook.md`: operating and developer runbook
- `experiment-execution-record.md`: completed execution evidence
- `fick-r2-85-publication-reproduction-protocol.md`: frozen headless protocol, acceptance values, bundle map, and interpretation boundary
- `study/FickモデルR2-85-論文提示用再現Supplement.md`: manuscript-ready Methods, Results, limitations, and reporting-standard mapping
