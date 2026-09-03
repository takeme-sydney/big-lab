#!/bin/bash

set -euo pipefail

export LC_ALL=C
export LANG=C
export TZ=UTC
umask 022

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
INPUT_SOURCE_CSV="$PROJECT_DIR/Sources/PermeationLab/Resources/yuan2023_training_data.csv"
PROTOCOL_SOURCE="$PROJECT_DIR/docs/fick-r2-85-publication-reproduction-protocol.md"
SUPPLEMENT_SOURCE="$PROJECT_DIR/../study/FickモデルR2-85-論文提示用再現Supplement.md"
AUDIT_TRAIL_SOURCE="$PROJECT_DIR/../study/FickモデルR2-85-再現試行監査ログ.md"
EXPECTED_RAW_SHA256="03ff02276f333d06747efb7a625e9de1b4055b94b8736873f5e7cc389315b0f5"
EXPECTED_NORMALIZED_SHA256="a0f8cd81f2369e08d0155a8644ff8ee1cb9128b16ee1bcea72c4df7e91848a07"

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 /absolute/path/to/nonexistent-output-directory" >&2
  exit 2
fi

OUTPUT_DIR="$1"
if [[ "$OUTPUT_DIR" != /* ]]; then
  echo "Output directory must be an absolute path: $OUTPUT_DIR" >&2
  exit 2
fi
if [[ -e "$OUTPUT_DIR" ]]; then
  echo "Refusing to overwrite an existing output path: $OUTPUT_DIR" >&2
  exit 2
fi
if [[ ! -f "$INPUT_SOURCE_CSV" ]]; then
  echo "Frozen input CSV is missing: $INPUT_SOURCE_CSV" >&2
  exit 2
fi
if [[ ! -f "$PROTOCOL_SOURCE" || ! -f "$SUPPLEMENT_SOURCE" || ! -f "$AUDIT_TRAIL_SOURCE" ]]; then
  echo "Canonical Markdown protocol, manuscript supplement, or audit trail is missing" >&2
  exit 2
fi

mkdir -p -- "$OUTPUT_DIR"
COMMAND_LOG="$OUTPUT_DIR/commands.log"
exec 3>&1 4>&2
exec > >(tee "$COMMAND_LOG") 2>&1

DERIVED_DATA="$(mktemp -d /tmp/permeation-lab-fick-reproduction.XXXXXX)"
cleanup() {
  if [[ -n "${DERIVED_DATA:-}" && -d "$DERIVED_DATA" ]]; then
    find "$DERIVED_DATA" -depth -delete
  fi
}
trap cleanup EXIT

source_hashes() {
  (
    cd "$PROJECT_DIR"
    find .gitignore Sources Tests docs scripts PermeationLab.xcodeproj -type f -print0 \
      | sort -z \
      | xargs -0 shasum -a 256
  )
}

echo "Fick R2 0.85 publication reproduction"
echo "Output: $OUTPUT_DIR"
echo "Started UTC: $(date -u '+%Y-%m-%dT%H:%M:%SZ')"
echo "Locale: $LC_ALL; timezone: $TZ"

{
  echo "capturedAtUTC=$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
  echo "workingDirectory=<PROJECT_DIR>"
  echo "shellVersion=$BASH_VERSION"
  echo "locale=$LC_ALL"
  echo "timezone=$TZ"
  sw_vers
  echo "architecture=$(uname -m)"
  xcodebuild -version
  swift --version
  jq --version
  echo "automationMode=$(xcrun automationmodetool status 2>&1 | tr '\n' ' ')"
  echo "gitCommit=$(git -C "$PROJECT_DIR" rev-parse HEAD 2>/dev/null || echo unavailable)"
  echo "gitTopLevelDetected=$(git -C "$PROJECT_DIR" rev-parse --show-toplevel >/dev/null 2>&1 && echo yes || echo no)"
  echo "targetTrackedByGit=$(git -C "$PROJECT_DIR" ls-files --error-unmatch Sources/PermeationLab/FickValidationExperiment.swift >/dev/null 2>&1 && echo yes || echo no)"
} > "$OUTPUT_DIR/environment.txt"

source_hashes > "$OUTPUT_DIR/source-files.before.sha256"
(
  cd "$PROJECT_DIR"
  env COPYFILE_DISABLE=1 tar -czf "$OUTPUT_DIR/source-snapshot.tar.gz" \
    .gitignore Sources Tests docs scripts PermeationLab.xcodeproj
)
cp "$PROTOCOL_SOURCE" "$OUTPUT_DIR/README.md"
cp "$SUPPLEMENT_SOURCE" "$OUTPUT_DIR/MANUSCRIPT-SUPPLEMENT.md"
cp "$AUDIT_TRAIL_SOURCE" "$OUTPUT_DIR/REPRODUCTION-AUDIT-TRAIL.md"
if ! cmp -s "$PROTOCOL_SOURCE" "$OUTPUT_DIR/README.md" \
  || ! cmp -s "$SUPPLEMENT_SOURCE" "$OUTPUT_DIR/MANUSCRIPT-SUPPLEMENT.md" \
  || ! cmp -s "$AUDIT_TRAIL_SOURCE" "$OUTPUT_DIR/REPRODUCTION-AUDIT-TRAIL.md"; then
  echo "Failed to copy canonical Markdown documentation into the bundle" >&2
  exit 1
fi
(
  cd "$(dirname "$SUPPLEMENT_SOURCE")"
  shasum -a 256 "$(basename "$SUPPLEMENT_SOURCE")"
) > "$OUTPUT_DIR/manuscript-supplement-source.sha256"
(
  cd "$(dirname "$AUDIT_TRAIL_SOURCE")"
  shasum -a 256 "$(basename "$AUDIT_TRAIL_SOURCE")"
) > "$OUTPUT_DIR/reproduction-audit-trail-source.sha256"

RAW_SHA256="$(shasum -a 256 "$INPUT_SOURCE_CSV" | awk '{print $1}')"
if [[ "$RAW_SHA256" != "$EXPECTED_RAW_SHA256" ]]; then
  echo "Input CSV SHA-256 mismatch: expected $EXPECTED_RAW_SHA256, got $RAW_SHA256" >&2
  exit 1
fi
(
  cd "$(dirname "$INPUT_SOURCE_CSV")"
  shasum -a 256 "$(basename "$INPUT_SOURCE_CSV")"
) > "$OUTPUT_DIR/input-source-csv.sha256"

echo "Running the complete unit-test target"
set +e
xcodebuild test -quiet \
  -project "$PROJECT_DIR/PermeationLab.xcodeproj" \
  -scheme PermeationLab \
  -configuration Debug \
  -destination 'platform=macOS,arch=arm64' \
  -derivedDataPath "$DERIVED_DATA" \
  -resultBundlePath "$DERIVED_DATA/FickReproductionTests.xcresult" \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  -only-testing:PermeationLabTests \
  2>&1 | tee "$OUTPUT_DIR/test.log"
TEST_EXIT_CODE=${PIPESTATUS[0]}
set -e
echo "$TEST_EXIT_CODE" > "$OUTPUT_DIR/test.exit-code"
if [[ $TEST_EXIT_CODE -ne 0 ]]; then
  echo "Unit tests failed with exit code $TEST_EXIT_CODE" >&2
  exit "$TEST_EXIT_CODE"
fi

xcrun xcresulttool get test-results summary \
  --path "$DERIVED_DATA/FickReproductionTests.xcresult" \
  --format json > "$OUTPUT_DIR/test-summary.json"
jq -e '
  .result == "Passed"
  and .failedTests == 0
  and .skippedTests == 0
  and .passedTests == 15
' "$OUTPUT_DIR/test-summary.json" >/dev/null

find "$DERIVED_DATA" -depth -delete
DERIVED_DATA=""

echo "Building and ad-hoc signing the Release application"
set +e
"$PROJECT_DIR/scripts/build-app.sh" 2>&1 | tee "$OUTPUT_DIR/build.log"
BUILD_EXIT_CODE=${PIPESTATUS[0]}
set -e
echo "$BUILD_EXIT_CODE" > "$OUTPUT_DIR/build.exit-code"
if [[ $BUILD_EXIT_CODE -ne 0 ]]; then
  echo "Release build failed with exit code $BUILD_EXIT_CODE" >&2
  exit "$BUILD_EXIT_CODE"
fi

APP_BUNDLE="$PROJECT_DIR/dist/PermeationLab.app"
APP_EXECUTABLE="$APP_BUNDLE/Contents/MacOS/PermeationLab"
PACKAGED_INPUT_CSV="$APP_BUNDLE/Contents/Resources/yuan2023_training_data.csv"
codesign --verify --deep --strict --verbose=2 "$APP_BUNDLE"
file "$APP_EXECUTABLE" > "$OUTPUT_DIR/binary-format.txt"
(
  cd "$(dirname "$APP_EXECUTABLE")"
  shasum -a 256 "$(basename "$APP_EXECUTABLE")"
) > "$OUTPUT_DIR/app-executable.sha256"
(
  cd "$(dirname "$PACKAGED_INPUT_CSV")"
  shasum -a 256 "$(basename "$PACKAGED_INPUT_CSV")"
) > "$OUTPUT_DIR/input-packaged-csv.sha256"
if ! cmp -s "$INPUT_SOURCE_CSV" "$PACKAGED_INPUT_CSV"; then
  echo "Packaged CSV differs from the frozen source CSV" >&2
  exit 1
fi

run_headless_export() {
  local run_number="$1"
  local result_path="$OUTPUT_DIR/run-${run_number}.json"
  local stdout_path="$OUTPUT_DIR/run-${run_number}.stdout.log"

  echo "Starting fresh-process repeat run $run_number"
  set +e
  "$APP_EXECUTABLE" \
    -fick-85-headless-input "$INPUT_SOURCE_CSV" \
    -fick-85-headless-output "$result_path" \
    > "$stdout_path" 2>&1
  local application_exit_code=$?
  set -e
  echo "$application_exit_code" > "$OUTPUT_DIR/run-${run_number}.exit-code"
  if [[ $application_exit_code -ne 0 ]]; then
    echo "Headless run $run_number exited with $application_exit_code" >&2
    sed -n '1,200p' "$stdout_path" >&2
    exit "$application_exit_code"
  fi
  if [[ ! -s "$result_path" ]]; then
    echo "Headless run $run_number did not produce its JSON" >&2
    exit 1
  fi

  jq -e \
    --arg normalized "$EXPECTED_NORMALIZED_SHA256" '
    .schemaVersion == "1.1"
    and .modelVersion == "fick-finite-slab-release-proxy-v1"
    and .evidenceLevel == "exploratoryProxyConditionCrossValidation"
    and .dataset.displayName == "yuan2023_training_data.csv"
    and .dataset.researchMode == "myExperiment"
    and .dataset.scientificStatus == "userProvidedUnvalidated"
    and .dataset.isBundledSource == false
    and .dataset.rowCount == 191
    and .dataset.columnCount == 11
    and .dataset.schemaIsValid == true
    and .dataset.sha256 == $normalized
    and .dataset.normalizedSHA256 == $normalized
    and .dataset.sha256Basis == "normalized parsed values"
    and .dataset.isCanonicalPaperDataset == true
    and .configuration.targetRSquared == 0.85
    and .configuration.seriesTermCount == 80
    and .configuration.minimumRate == 1e-8
    and .configuration.maximumRate == 100
    and .configuration.logKGridCount == 401
    and .configuration.goldenSectionIterations == 80
    and .configuration.bootstrapIterations == 20000
    and .configuration.bootstrapSeed == 20260830
    and .eligibleFamilyCount == 3
    and .eligibleConditionCount == 12
    and .eligibleObservationCount == 112
    and .excludedFamilyCount == 6
    and .excludedConditionCount == 6
    and .excludedObservationCount == 79
    and (.folds | length) == 12
    and (.predictions | length) == 112
    and .pooledMetric.rSquared == 0.8951421556980397
    and .pooledMetric.rmse == 9.598790998288257
    and .pooledMetric.mae == 6.718231271867532
    and .confidenceInterval.twoSidedLower == 0.7391961375054618
    and .confidenceInterval.twoSidedUpper == 0.9469124716928526
    and .confidenceInterval.oneSidedLower == 0.7804721110215499
    and .confidenceInterval.probabilityAtOrAboveTarget == 0.7736
    and .confidenceInterval.requestedReplicateCount == 20000
    and .confidenceInterval.validReplicateCount == 20000
    and .confidenceInterval.clusterCount == 12
    and .leaveOneFamilyOutStress.familyCount == 9
    and .leaveOneFamilyOutStress.observationCount == 191
    and .leaveOneFamilyOutStress.metric.rSquared == -0.13586687519274854
    and .leaveOneFamilyOutStress.metric.rmse == 26.90496149487069
    and .leaveOneFamilyOutStress.metric.mae == 18.881413853866437
    and .pointPass == true
    and .confidencePass == false
    and .exactPaperReplayAvailable == false
    and ([.folds[] | ([.trainingRowIDs[], .testRowIDs[]] | length) == ([.trainingRowIDs[], .testRowIDs[]] | unique | length)] | all)
  ' "$result_path" >/dev/null

  jq -S 'del(.id, .startedAt, .completedAt, .elapsedSeconds)' \
    "$result_path" > "$OUTPUT_DIR/run-${run_number}.scientific.json"
}

run_headless_export "01"
run_headless_export "02"

if ! cmp -s "$OUTPUT_DIR/run-01.scientific.json" "$OUTPUT_DIR/run-02.scientific.json"; then
  echo "The two fresh-process scientific payloads differ" >&2
  diff -u "$OUTPUT_DIR/run-01.scientific.json" "$OUTPUT_DIR/run-02.scientific.json" || true
  exit 1
fi

SCIENTIFIC_SHA256="$(shasum -a 256 "$OUTPUT_DIR/run-01.scientific.json" | awk '{print $1}')"
echo "$SCIENTIFIC_SHA256  run-01.scientific.json" > "$OUTPUT_DIR/scientific-payload.sha256"

jq '{
  schemaVersion,
  modelVersion,
  evidenceLevel,
  dataset,
  configuration,
  eligibleFamilyCount,
  eligibleConditionCount,
  eligibleObservationCount,
  excludedFamilyCount,
  excludedConditionCount,
  excludedObservationCount,
  pooledMetric,
  familyMetrics,
  confidenceInterval,
  leaveOneFamilyOutStress: {
    familyCount: .leaveOneFamilyOutStress.familyCount,
    observationCount: .leaveOneFamilyOutStress.observationCount,
    metric: .leaveOneFamilyOutStress.metric
  },
  pointPass,
  confidencePass,
  exactPaperReplayAvailable,
  warnings,
  limitations
}' "$OUTPUT_DIR/run-01.json" > "$OUTPUT_DIR/results-summary.json"

jq -r '
  ["row_id","fold_id","drug","skin_code","mn_type_code","loading_ug","molecular_weight_da","mn_length_mm","surface_area_mm2","time_h","observed_percentage","predicted_percentage","residual_pp"],
  (.predictions[] | [
    .rowID,
    .foldID,
    .family.drugName,
    .family.skinCode,
    .family.needleTypeCode,
    .condition.loading,
    .condition.molecularWeight,
    .condition.needleLength,
    .condition.surfaceArea,
    .timeHours,
    .observedPercentage,
    .predictedPercentage,
    (.observedPercentage - .predictedPercentage)
  ]) | @csv
' "$OUTPUT_DIR/run-01.json" > "$OUTPUT_DIR/predictions.csv"

jq -r '
  . as $run |
  ["fold_id","drug","skin_code","mn_type_code","loading_ug","molecular_weight_da","mn_length_mm","surface_area_mm2","fitted_A_percentage","A_at_upper_boundary","fitted_k_per_h","training_sse","training_row_count","test_row_count","training_condition_ids_json","training_row_ids_json","test_row_ids_json"],
  ($run.folds[] as $fold |
    ($run.predictions | map(select(.rowID == $fold.testRowIDs[0])) | .[0].foldID) as $foldID |
    [
      $foldID,
      $fold.heldOutCondition.family.drugName,
      $fold.heldOutCondition.family.skinCode,
      $fold.heldOutCondition.family.needleTypeCode,
      $fold.heldOutCondition.loading,
      $fold.heldOutCondition.molecularWeight,
      $fold.heldOutCondition.needleLength,
      $fold.heldOutCondition.surfaceArea,
      $fold.fittedAmplitude,
      ($fold.fittedAmplitude == 100),
      $fold.fittedRate,
      $fold.trainingSSE,
      ($fold.trainingRowIDs | length),
      ($fold.testRowIDs | length),
      ($fold.trainingConditionIDs | tojson),
      ($fold.trainingRowIDs | tojson),
      ($fold.testRowIDs | tojson)
    ]) | @csv
' "$OUTPUT_DIR/run-01.json" > "$OUTPUT_DIR/folds.csv"

jq -r '
  ["drug","skin_code","mn_type_code","n","r_squared","rmse_pp","mae_pp"],
  (.familyMetrics[] | [
    .family.drugName,
    .family.skinCode,
    .family.needleTypeCode,
    .metric.observationCount,
    .metric.rSquared,
    .metric.rmse,
    .metric.mae
  ]) | @csv
' "$OUTPUT_DIR/run-01.json" > "$OUTPUT_DIR/family-metrics.csv"

jq -r '
  def mean: add / length;
  ["fold_id","drug","skin_code","mn_type_code","n","observed_mean","predicted_mean","r_squared","rmse_pp","mae_pp"],
  (.predictions | group_by(.foldID)[] |
    . as $rows |
    ($rows | map(.observedPercentage) | mean) as $observedMean |
    ($rows | map((.observedPercentage - $observedMean) * (.observedPercentage - $observedMean)) | add) as $tss |
    ($rows | map((.observedPercentage - .predictedPercentage) * (.observedPercentage - .predictedPercentage)) | add) as $sse |
    [
      $rows[0].foldID,
      $rows[0].family.drugName,
      $rows[0].family.skinCode,
      $rows[0].family.needleTypeCode,
      ($rows | length),
      $observedMean,
      ($rows | map(.predictedPercentage) | mean),
      (if $tss > 1e-20 then 1 - $sse / $tss else null end),
      (($sse / ($rows | length)) | sqrt),
      ($rows | map((.observedPercentage - .predictedPercentage) | fabs) | mean)
    ]) | @csv
' "$OUTPUT_DIR/run-01.json" > "$OUTPUT_DIR/condition-metrics.csv"

jq -r '
  ["row_id","fold_id","drug","skin_code","mn_type_code","loading_ug","molecular_weight_da","mn_length_mm","surface_area_mm2","time_h","observed_percentage","predicted_percentage","residual_pp"],
  (.leaveOneFamilyOutStress.predictions[] | [
    .rowID,
    .foldID,
    .family.drugName,
    .family.skinCode,
    .family.needleTypeCode,
    .condition.loading,
    .condition.molecularWeight,
    .condition.needleLength,
    .condition.surfaceArea,
    .timeHours,
    .observedPercentage,
    .predictedPercentage,
    (.observedPercentage - .predictedPercentage)
  ]) | @csv
' "$OUTPUT_DIR/run-01.json" > "$OUTPUT_DIR/stress-predictions.csv"

jq -r '
  ["fold_id","held_out_drug","held_out_skin_code","held_out_mn_type_code","fitted_A_percentage","A_at_upper_boundary","fitted_k_per_h","training_sse","training_family_ids_json","training_row_count","test_row_count","training_row_ids_json","test_row_ids_json"],
  (.leaveOneFamilyOutStress.folds[] | [
    ("family-holdout|" + .heldOutFamily.drugName + "|skin=" + (.heldOutFamily.skinCode|tostring) + "|mn=" + (.heldOutFamily.needleTypeCode|tostring)),
    .heldOutFamily.drugName,
    .heldOutFamily.skinCode,
    .heldOutFamily.needleTypeCode,
    .fittedAmplitude,
    (.fittedAmplitude == 100),
    .fittedRate,
    .trainingSSE,
    (.trainingFamilyIDs | tojson),
    (.trainingRowIDs | length),
    (.testRowIDs | length),
    (.trainingRowIDs | tojson),
    (.testRowIDs | tojson)
  ]) | @csv
' "$OUTPUT_DIR/run-01.json" > "$OUTPUT_DIR/stress-folds.csv"

jq '
  def mean: add / length;
  . as $run |
  ($run.predictions | map((.observedPercentage - .predictedPercentage) * (.observedPercentage - .predictedPercentage)) | add) as $sse |
  ($run.predictions
    | group_by([.family.drugName, .family.skinCode, .family.needleTypeCode])
    | map((map(.observedPercentage) | mean) as $familyMean
      | map((.observedPercentage - $familyMean) * (.observedPercentage - $familyMean)) | add)
    | add) as $withinFamilyTSS |
  ($run.familyMetrics | map(.metric.rSquared) | mean) as $macroFamilyR2 |
  ($run.predictions | group_by(.foldID)) as $conditions |
  ($conditions | map(map(.observedPercentage) | mean) | mean) as $conditionWeightedObservedMean |
  ($conditions | map(map((.observedPercentage - .predictedPercentage) * (.observedPercentage - .predictedPercentage)) | mean) | add) as $conditionSSEComponents |
  ($conditions | map(map((.observedPercentage - $conditionWeightedObservedMean) * (.observedPercentage - $conditionWeightedObservedMean)) | mean) | add) as $conditionTSSComponents |
  ($conditions | map(map((.observedPercentage - .predictedPercentage) | fabs) | mean) | mean) as $conditionMAE |
  ($run.predictions | map(.predictedPercentage) | mean) as $predictionMean |
  ($run.predictions | map(.observedPercentage) | mean) as $observationMean |
  ($run.predictions | map((.predictedPercentage - $predictionMean) * (.predictedPercentage - $predictionMean)) | add) as $predictionTSS |
  ($run.predictions | map((.predictedPercentage - $predictionMean) * (.observedPercentage - $observationMean)) | add) as $predictionObservedCrossProduct |
  ($predictionObservedCrossProduct / $predictionTSS) as $calibrationSlope |
  {
    status: "post-hoc descriptive sensitivity audit; not a preregistered endpoint",
    rowPooled: $run.pooledMetric,
    familyCenteredPooled: {
      definition: "1 - pooled SSE / sum_f sum_i (y_fi - mean(y_f))^2; predictions are not centered",
      squaredError: $sse,
      withinFamilyTotalSumSquares: $withinFamilyTSS,
      rSquared: (1 - $sse / $withinFamilyTSS)
    },
    macroFamily: {
      definition: "unweighted arithmetic mean of the three exported family R-squared values",
      familyCount: ($run.familyMetrics | length),
      rSquared: $macroFamilyR2
    },
    conditionBalanced: {
      definition: "each of 12 conditions has weight 1/12; rows have equal weight within condition",
      conditionCount: ($conditions | length),
      weightedObservedMean: $conditionWeightedObservedMean,
      sumConditionMeanSquaredError: $conditionSSEComponents,
      sumConditionWeightedTSSComponent: $conditionTSSComponents,
      rSquared: (1 - $conditionSSEComponents / $conditionTSSComponents),
      rmsePercentagePoints: (($conditionSSEComponents / ($conditions | length)) | sqrt),
      maePercentagePoints: $conditionMAE
    },
    calibration: {
      definition: "ordinary least-squares calibration of observed percentage on OOF predicted percentage across 112 rows; descriptive only",
      intercept: ($observationMean - $calibrationSlope * $predictionMean),
      slope: $calibrationSlope
    },
    structuralDiagnostics: {
      minimumFoldTestRows: ($run.folds | map(.testRowIDs | length) | min),
      maximumFoldTestRows: ($run.folds | map(.testRowIDs | length) | max),
      primaryAmplitudeAt100Count: ($run.folds | map(select(.fittedAmplitude == 100)) | length),
      primaryFoldCount: ($run.folds | length),
      stressAmplitudeAt100Count: ($run.leaveOneFamilyOutStress.folds | map(select(.fittedAmplitude == 100)) | length),
      stressFoldCount: ($run.leaveOneFamilyOutStress.folds | length)
    },
    bootstrapInterpretation: {
      label: "fixed-OOF-prediction condition-cluster composition percentile distribution",
      modelRefitWithinReplicate: false,
      familyStratified: false,
      overlappingTrainingFoldCovarianceModeled: false,
      independentUnitClaimed: false
    }
  }
' "$OUTPUT_DIR/run-01.json" > "$OUTPUT_DIR/publication-diagnostics.json"

jq -e '
  def close($actual; $expected; $tolerance): (($actual - $expected) | fabs) <= $tolerance;
  close(.familyCenteredPooled.squaredError; 10319.3203264278; 1e-9)
  and close(.familyCenteredPooled.withinFamilyTotalSumSquares; 25341.65172378823; 1e-9)
  and close(.familyCenteredPooled.rSquared; 0.5927921179367703; 1e-12)
  and close(.macroFamily.rSquared; 0.3383464746508844; 1e-12)
  and close(.conditionBalanced.weightedObservedMean; 34.53172965946778; 1e-12)
  and close(.conditionBalanced.sumConditionMeanSquaredError; 1713.2665392540864; 1e-9)
  and close(.conditionBalanced.sumConditionWeightedTSSComponent; 12379.842503717962; 1e-9)
  and close(.conditionBalanced.rSquared; 0.8616083735524461; 1e-12)
  and close(.conditionBalanced.rmsePercentagePoints; 11.948732635911943; 1e-12)
  and close(.conditionBalanced.maePercentagePoints; 8.455595071422747; 1e-12)
  and .structuralDiagnostics.primaryAmplitudeAt100Count == 1
  and .structuralDiagnostics.stressAmplitudeAt100Count == 8
' "$OUTPUT_DIR/publication-diagnostics.json" >/dev/null

jq '
  . as $run |
  {
    allPrimaryTrainingTestRowSetsDisjoint: ([
      $run.folds[] |
      ([.trainingRowIDs[], .testRowIDs[]] | length) == ([.trainingRowIDs[], .testRowIDs[]] | unique | length)
    ] | all),
    noHeldOutConditionInTrainingConditionIDs: ([
      $run.folds[] as $fold |
      ($run.predictions | map(select(.rowID == $fold.testRowIDs[0])) | .[0].foldID) as $foldID |
      ($fold.trainingConditionIDs | all(. != $foldID))
    ] | all),
    uniquePrimaryTestRowCount: ([$run.folds[].testRowIDs[]] | unique | length),
    exportedPrimaryPredictionRowCount: ($run.predictions | length),
    allStressTrainingTestRowSetsDisjoint: ([
      $run.leaveOneFamilyOutStress.folds[] |
      ([.trainingRowIDs[], .testRowIDs[]] | length) == ([.trainingRowIDs[], .testRowIDs[]] | unique | length)
    ] | all),
    uniqueStressTestRowCount: ([$run.leaveOneFamilyOutStress.folds[].testRowIDs[]] | unique | length),
    exportedStressPredictionRowCount: ($run.leaveOneFamilyOutStress.predictions | length)
  }
' "$OUTPUT_DIR/run-01.json" > "$OUTPUT_DIR/fold-integrity.json"
jq -e '
  .allPrimaryTrainingTestRowSetsDisjoint == true
  and .noHeldOutConditionInTrainingConditionIDs == true
  and .uniquePrimaryTestRowCount == 112
  and .exportedPrimaryPredictionRowCount == 112
  and .allStressTrainingTestRowSetsDisjoint == true
  and .uniqueStressTestRowCount == 191
  and .exportedStressPredictionRowCount == 191
' "$OUTPUT_DIR/fold-integrity.json" >/dev/null

jq -n \
  --arg rawCSVSHA256 "$RAW_SHA256" \
  --arg normalizedValueSHA256 "$EXPECTED_NORMALIZED_SHA256" \
  --arg scientificPayloadSHA256 "$SCIENTIFIC_SHA256" \
  --arg completedAtUTC "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" \
  '{
    reproductionStatus: "passed",
    freshProcessRepeatRuns: 2,
    scientificPayloadsByteIdentical: true,
    rawCSVSHA256: $rawCSVSHA256,
    normalizedValueSHA256: $normalizedValueSHA256,
    scientificPayloadSHA256: $scientificPayloadSHA256,
    completedAtUTC: $completedAtUTC,
    interpretation: "Computational repeatability on the recorded binary/environment; not independent external validation"
  }' > "$OUTPUT_DIR/reproduction-verification.json"

source_hashes > "$OUTPUT_DIR/source-files.after.sha256"
if ! cmp -s "$OUTPUT_DIR/source-files.before.sha256" "$OUTPUT_DIR/source-files.after.sha256"; then
  echo "Source files changed during the reproduction run" >&2
  diff -u "$OUTPUT_DIR/source-files.before.sha256" "$OUTPUT_DIR/source-files.after.sha256" || true
  exit 1
fi
if ! cmp -s "$PROTOCOL_SOURCE" "$OUTPUT_DIR/README.md" \
  || ! cmp -s "$SUPPLEMENT_SOURCE" "$OUTPUT_DIR/MANUSCRIPT-SUPPLEMENT.md" \
  || ! cmp -s "$AUDIT_TRAIL_SOURCE" "$OUTPUT_DIR/REPRODUCTION-AUDIT-TRAIL.md"; then
  echo "Canonical Markdown documentation changed during the reproduction run" >&2
  exit 1
fi

echo "Completed UTC: $(date -u '+%Y-%m-%dT%H:%M:%SZ')"
echo "Scientific payload SHA-256: $SCIENTIFIC_SHA256"
echo "REPRODUCTION PASSED"

# Close the tee before hashing the logs so every logged byte is included.
exec 1>&3 2>&4
wait
sed -E \
  -e 's#/Users/[^/]+#<USER_HOME>#g' \
  -e 's#/tmp/permeation-lab-fick-reproduction\.[A-Za-z0-9]+#<DERIVED_DATA>#g' \
  "$COMMAND_LOG" > "$OUTPUT_DIR/commands.public.log"
for raw_log in test.log build.log; do
  sed -E \
    -e 's#/Users/[^/]+#<USER_HOME>#g' \
    -e 's#/tmp/permeation-lab-fick-reproduction\.[A-Za-z0-9]+#<DERIVED_DATA>#g' \
    "$OUTPUT_DIR/$raw_log" > "$OUTPUT_DIR/${raw_log%.log}.public.log"
done
sed -E \
  -e 's#/Users/[^/]+#<USER_HOME>#g' \
  "$OUTPUT_DIR/binary-format.txt" > "$OUTPUT_DIR/binary-format.public.txt"
jq '
  (.devicesAndConfigurations[]?.device.deviceId) = "<REDACTED>"
  | (.devicesAndConfigurations[]?.device.deviceName) = "<REDACTED>"
' "$OUTPUT_DIR/test-summary.json" > "$OUTPUT_DIR/test-summary.public.json"

(
  cd "$OUTPUT_DIR"
  find . -type f ! -name artifact-manifest.sha256 -print0 \
    | sort -z \
    | xargs -0 shasum -a 256 \
    > artifact-manifest.sha256
  shasum -a 256 -c artifact-manifest.sha256 >/dev/null
)

echo "Artifact manifest verified: $OUTPUT_DIR/artifact-manifest.sha256"
