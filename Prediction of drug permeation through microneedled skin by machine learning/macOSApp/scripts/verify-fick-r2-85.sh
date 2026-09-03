#!/bin/bash

set -euo pipefail

export LC_ALL=C
export LANG=C
export TZ=UTC

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 /absolute/path/to/reproduction-bundle" >&2
  exit 2
fi

BUNDLE_DIR="$1"
if [[ "$BUNDLE_DIR" != /* || ! -d "$BUNDLE_DIR" ]]; then
  echo "Bundle must be an existing absolute directory: $BUNDLE_DIR" >&2
  exit 2
fi

for required in \
  artifact-manifest.sha256 \
  README.md \
  MANUSCRIPT-SUPPLEMENT.md \
  REPRODUCTION-AUDIT-TRAIL.md \
  manuscript-supplement-source.sha256 \
  reproduction-audit-trail-source.sha256 \
  binary-format.public.txt \
  build.public.log \
  commands.public.log \
  test.public.log \
  test-summary.public.json \
  source-files.before.sha256 \
  source-files.after.sha256 \
  run-01.json \
  run-01.scientific.json \
  run-02.json \
  run-02.scientific.json \
  publication-diagnostics.json \
  fold-integrity.json \
  reproduction-verification.json; do
  if [[ ! -f "$BUNDLE_DIR/$required" ]]; then
    echo "Missing required artifact: $required" >&2
    exit 1
  fi
done

(
  cd "$BUNDLE_DIR"
  shasum -a 256 -c artifact-manifest.sha256
)

cmp -s "$BUNDLE_DIR/source-files.before.sha256" "$BUNDLE_DIR/source-files.after.sha256"
cmp -s "$BUNDLE_DIR/run-01.scientific.json" "$BUNDLE_DIR/run-02.scientific.json"
if grep -E '/Users/[^/]+' \
  "$BUNDLE_DIR/commands.public.log" \
  "$BUNDLE_DIR/test.public.log" \
  "$BUNDLE_DIR/build.public.log" \
  "$BUNDLE_DIR/binary-format.public.txt" >/dev/null; then
  echo "A public log still contains a macOS user path" >&2
  exit 1
fi
jq -e '
  [.devicesAndConfigurations[]?.device |
    .deviceId == "<REDACTED>" and .deviceName == "<REDACTED>"] | all
' "$BUNDLE_DIR/test-summary.public.json" >/dev/null

jq -e '
  .reproductionStatus == "passed"
  and .freshProcessRepeatRuns == 2
  and .scientificPayloadsByteIdentical == true
  and .rawCSVSHA256 == "03ff02276f333d06747efb7a625e9de1b4055b94b8736873f5e7cc389315b0f5"
  and .normalizedValueSHA256 == "a0f8cd81f2369e08d0155a8644ff8ee1cb9128b16ee1bcea72c4df7e91848a07"
' "$BUNDLE_DIR/reproduction-verification.json" >/dev/null

jq -e '
  .allPrimaryTrainingTestRowSetsDisjoint == true
  and .noHeldOutConditionInTrainingConditionIDs == true
  and .uniquePrimaryTestRowCount == 112
  and .exportedPrimaryPredictionRowCount == 112
  and .allStressTrainingTestRowSetsDisjoint == true
  and .uniqueStressTestRowCount == 191
  and .exportedStressPredictionRowCount == 191
' "$BUNDLE_DIR/fold-integrity.json" >/dev/null

jq -e '
  .pooledMetric.rSquared == 0.8951421556980397
  and .familyMetrics[0].metric.rSquared == 0.6889248170843701
  and .familyMetrics[1].metric.rSquared == -0.10133157952745053
  and .familyMetrics[2].metric.rSquared == 0.4274461863957335
  and .confidenceInterval.oneSidedLower == 0.7804721110215499
  and .leaveOneFamilyOutStress.metric.rSquared == -0.13586687519274854
  and .pointPass == true
  and .confidencePass == false
' "$BUNDLE_DIR/run-01.json" >/dev/null

jq -e '
  def close($actual; $expected; $tolerance): (($actual - $expected) | fabs) <= $tolerance;
  close(.familyCenteredPooled.rSquared; 0.5927921179367703; 1e-12)
  and close(.macroFamily.rSquared; 0.3383464746508844; 1e-12)
  and close(.conditionBalanced.rSquared; 0.8616083735524461; 1e-12)
  and .bootstrapInterpretation.modelRefitWithinReplicate == false
' "$BUNDLE_DIR/publication-diagnostics.json" >/dev/null

echo "VERIFICATION PASSED"
