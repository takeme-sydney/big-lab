# Experiment feature implementation prompt

Implement the requirements in `docs/experiment-requirements.md` in the native SwiftUI macOS app.

## Product intent

Build a researcher-facing Experiment workspace that reconstructs the disclosed Yuan et al. workflow, makes every replacement assumption visible, and emits a durable provenance artifact. Scientific honesty is a product requirement: do not turn missing original split/model artifacts into an “exact reproduction” claim.

## Required implementation

1. Add an always-visible sidebar-top Verified Facts / My Research selector with title, explanation, selected state, stable accessibility identifiers, and a persistent context/status bar. Keep `paperEvidence / myExperiment` only as internal enum names.
   - Keep bundled Data S1 in an immutable paper slot.
   - Keep the user CSV in a separate optional personal slot; use a zero-row state before import and never fall back to paper data.
   - My Experiment exposes only experiment/data/integrity workspaces and hides Reported Table 4.
   - Import failure, personal clear, and comparison-only CSV changes cannot mutate or invalidate the paper slot.
2. Add the Experiment destination to `ContentView.Workspace` with bilingual title, SF Symbol, destination switch, and stable accessibility identifiers.
3. Create dedicated experiment domain types for configuration, model kind, metric, split, prediction, run result, and export manifest. Persist mode, scientific status, import timestamp, and evidence eligibility; keep old history decodable.
4. Create a deterministic runner using the seven published numeric predictors.
   - 70:30 split: seeded Fisher–Yates shuffle, 134 train / 57 test for 191 rows.
   - Leave-one-drug-out: selected drug entirely in test.
   - MLR: ordinary least squares, no intercept.
   - RF: seeded bagging, regression trees, 500 trees, target-specific mtry.
   - Boosting: deterministic regression-tree boosting using the published depth/eta/round count. Name it a native reconstruction, not XGBoost.
5. Compute RMSE, MAE, conventional R², train/test drug counts, and cross-partition identical-condition overlap.
6. Centralize evidence policy. Only Paper Evidence + `paperSourceVerified` + bundled raw canonical Data S1 + row split + seed 0 + complete/unique/disjoint 134/57 IDs matching the deterministic seed-0 partition + disclosed preset may show Table 4 as a reported reference. My Experiment never inherits this status from matching values. Reclassify legacy stored Evidence through this policy before display or export.
7. Run computation away from the main actor. Publish progress/status safely, retain state across workspace navigation, propagate cancellation to workers, and allow another run after completion or failure.
8. Persist a bounded list of recent successful runs in `UserDefaults` or Application Support. Treat corrupt history as recoverable and do not block the feature.
9. Add JSON export through a native macOS save workflow. Export exact split IDs, configuration, mode/status, Table 4 eligibility, hash, metrics, predictions, warnings, and engine/schema versions.
10. Build the UI with the existing Lab design system:
   - evidence/readiness notice
   - dataset snapshot
   - protocol configuration
   - paper preset summary
   - one primary run action with progress
   - reconstructed versus reported results only when dataset and validation scope are comparable
   - observed-versus-predicted chart
   - split/leakage audit
   - recent runs and export
   - mass-consistent Fick-method preview and public-evidence boundary
   - My Experiment-only Fick R² proxy validation with distinct point-estimate and internal fixed-prediction percentile decisions
   - local Fick validation history and complete JSON export
11. Add/update tests for mode/data-slot isolation, canonical-copy non-promotion, Table 4 guards, navigation, deterministic execution, split sizes, leave-one-drug-out, persistence/export encoding, and compact-window reachability.
12. Update only Markdown documentation. Do not generate HTML.

For the Fick R² proxy validation, freeze the following exploratory protocol in code and export it with every run:

- finite planar-slab odd-term solution with 80 terms;
- `prediction(t) = A × F(k × t)`, `0 ≤ A ≤ 100`, and `1e-8 ≤ k ≤ 100 h⁻¹`;
- family = drug + skin + MN type;
- proxy condition = family + loading + molecular weight + MN length + surface area, excluding time;
- outer leave-one-proxy-condition-out fitting, limited to families with at least three conditions;
- pooled OOF conventional R²/RMSE/MAE;
- 20,000 condition-cluster resamples of already-fixed OOF predictions with seed `20260830`; record that replicates do not refit and are not family-stratified;
- leave-one-family-out stress evaluation;
- default target `R² = 0.85`.

Add a direct headless entry point that requires explicit absolute input/output paths, bypasses SwiftUI and `UserDefaults`, writes atomically, and refuses overwrite. Add a one-command publication harness that runs clean unit tests and a signed Release build, verifies raw/normalized input hashes, executes two fresh processes, compares scientific payloads after removing only dynamic envelope fields, exports all rows/folds and weighting diagnostics, archives exact source/environment/logs, and emits a verified SHA-256 artifact manifest.

## Guardrails

- Preserve all existing user changes and flows.
- Do not add network, R, Python, XGBoost, or other runtime dependencies to the shipped app.
- Do not reuse the exploratory fitted exponential curve as a Fick finite-difference result.
- Do not clip Fick output or hide mass-balance defects; reject non-finite and excessive configurations before integer conversion or allocation.
- Do not call the finite-slab proxy the paper's 2D model. Do not call proxy conditions experiment runs. Do not call the fixed-prediction resampling percentiles a generic confidence interval, and do not turn an R² point-estimate pass into a confirmed result when the fifth percentile and every family-specific R² fail the target.
- Do not compare local values to Table 4 as a pass/fail equality test.
- Do not treat a user-provided CSV as paper evidence solely because its normalized values match Data S1.
- Do not call schema-valid personal data scientifically verified.
- Do not hide the fact that the original split files and fitted models are unavailable.
- Do not use absolute paths in persisted or exported experiment data.
- Keep English as the app's existing default language and supply Japanese for every new string.

## Definition of done

- Debug build, Release build, and test suite pass.
- The packaged `.app` contains the Experiment workspace.
- Default run succeeds on bundled Data S1, produces a deterministic result, persists it, and exports valid JSON.
- UI remains usable at 1050 × 700 and exposes all primary controls to accessibility automation.
- Documentation, implementation labels, and output artifacts agree on the evidence boundary.
