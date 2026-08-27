#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
PROJECT_FILE="$PROJECT_DIR/PermeationLab.xcodeproj"
SCHEME="PermeationLab"
DESTINATION="${PERMEATION_LAB_DESTINATION:-platform=macOS,arch=$(uname -m)}"
DERIVED_DATA="$(mktemp -d /tmp/permeation-lab-quality.XXXXXX)"
ENTITLEMENTS="$PROJECT_DIR/PermeationLab/PermeationLab.entitlements"
PRIVACY_MANIFEST="$PROJECT_DIR/PermeationLab/Resources/PrivacyInfo.xcprivacy"
RESOURCE_DIR="$PROJECT_DIR/PermeationLab/Resources"

cleanup() {
  rm -rf -- "$DERIVED_DATA"
}
trap cleanup EXIT

for required_path in \
  "$PROJECT_FILE/project.pbxproj" \
  "$PROJECT_FILE/xcshareddata/xcschemes/PermeationLab.xcscheme" \
  "$PROJECT_DIR/PermeationLab" \
  "$PROJECT_DIR/PermeationLabTests" \
  "$PROJECT_DIR/PermeationLabUITests" \
  "$ENTITLEMENTS" \
  "$PRIVACY_MANIFEST" \
  "$RESOURCE_DIR/yuan2023-training-data.csv" \
  "$RESOURCE_DIR/yuan2023-paper-ja.html" \
  "$RESOURCE_DIR/Supplements/yuan2023-paper.pdf" \
  "$RESOURCE_DIR/Supplements/yuan2023-data-s1.xlsx" \
  "$RESOURCE_DIR/Supplements/yuan2023-code-si2.docx" \
  "$RESOURCE_DIR/Supplements/yuan2023-new-drug-figures-si3.docx" \
  "$RESOURCE_DIR/Supplements/yuan2023-supplementary-code.txt"
do
  if [[ ! -e "$required_path" ]]; then
    printf 'Required path is missing: %s\n' "$required_path" >&2
    exit 1
  fi
done

for figure_number in 1 2 3 4 5 6 7 8; do
  figure_path="$RESOURCE_DIR/Figures/figure-$figure_number.jpg"
  if [[ ! -f "$figure_path" ]]; then
    printf 'Required paper figure is missing: %s\n' "$figure_path" >&2
    exit 1
  fi
done

for supplement_number in 1 2; do
  figure_path="$RESOURCE_DIR/Figures/figure-s$supplement_number.png"
  if [[ ! -f "$figure_path" ]]; then
    printf 'Required supplementary figure is missing: %s\n' "$figure_path" >&2
    exit 1
  fi
done

verify_hash() {
  local expected="$1"
  local source_path="$2"
  local actual
  actual="$(shasum -a 256 "$source_path" | awk '{print $1}')"
  if [[ "$actual" != "$expected" ]]; then
    printf 'Source hash mismatch: %s\nexpected %s\nactual   %s\n' "$source_path" "$expected" "$actual" >&2
    exit 1
  fi
}

verify_hash \
  '4641e97362f3cc545586879f2da3735e5487a50fe3cc6149076c87151e47c820' \
  "$RESOURCE_DIR/Supplements/yuan2023-paper.pdf"
verify_hash \
  'a22cc32b4d461b1e65c2b29623186a0d0c1f984fc1935d8bd3b35ec0bc3c3a24' \
  "$RESOURCE_DIR/Supplements/yuan2023-data-s1.xlsx"
verify_hash \
  '9d6fe3da0127ba26469b7a1fe61a98f723a5547d8a666c92670bf30f31820c81' \
  "$RESOURCE_DIR/Supplements/yuan2023-code-si2.docx"
verify_hash \
  '49f953203a33dd6c781e2761011c8124a6bac891e07ceedf61de6c1289626031' \
  "$RESOURCE_DIR/Supplements/yuan2023-new-drug-figures-si3.docx"
verify_hash \
  '03ff02276f333d06747efb7a625e9de1b4055b94b8736873f5e7cc389315b0f5' \
  "$RESOURCE_DIR/yuan2023-training-data.csv"

if [[ "$(wc -l < "$RESOURCE_DIR/yuan2023-training-data.csv" | tr -d ' ')" != "192" ]]; then
  printf '%s\n' 'Data S1 CSV must contain one header plus 191 observations.' >&2
  exit 1
fi

plutil -lint "$ENTITLEMENTS" "$PRIVACY_MANIFEST"

if [[ "$(/usr/libexec/PlistBuddy -c 'Print :com.apple.security.app-sandbox' "$ENTITLEMENTS")" != "true" ]]; then
  printf '%s\n' 'App Sandbox must remain enabled.' >&2
  exit 1
fi

for entitlement_key in \
  com.apple.security.network.client \
  com.apple.security.network.server
do
  if /usr/libexec/PlistBuddy -c "Print :$entitlement_key" "$ENTITLEMENTS" >/dev/null 2>&1; then
    printf 'Network entitlement is not allowed: %s\n' "$entitlement_key" >&2
    exit 1
  fi
done

if [[ "$(/usr/libexec/PlistBuddy -c 'Print :NSPrivacyTracking' "$PRIVACY_MANIFEST")" != "false" ]]; then
  printf '%s\n' 'Privacy manifest must declare tracking as disabled.' >&2
  exit 1
fi

if rg -n '(URLSession|NWConnection|Network\.framework|https?://)' PermeationLab --glob '*.swift'; then
  printf '%s\n' 'Swift sources must not contain a network path.' >&2
  exit 1
fi

if rg -n '(func[[:space:]]+predict|class[[:space:]]+[^ ]*Predict|struct[[:space:]]+[^ ]*Predict|surrogate)' \
  PermeationLab --glob '*.swift' --ignore-case
then
  printf '%s\n' 'An unsupported prediction implementation may have been introduced.' >&2
  exit 1
fi

if rg -n 'LineMark' PermeationLab/Views/SkinPermeationView.swift; then
  printf '%s\n' 'The Data S1 skin-permeation chart must remain an unconnected PointMark visualization.' >&2
  exit 1
fi

cd -- "$PROJECT_DIR"

xcodebuild -list -project "$PROJECT_FILE"
xcodebuild build-for-testing -quiet \
  -project "$PROJECT_FILE" \
  -scheme "$SCHEME" \
  -destination "$DESTINATION" \
  -derivedDataPath "$DERIVED_DATA"
UNIT_TEST_BUNDLE="$DERIVED_DATA/Build/Products/Debug/PermeationLab.app/Contents/PlugIns/PermeationLabTests.xctest"
UNIT_TEST_FRAMEWORKS="$UNIT_TEST_BUNDLE/Contents/Frameworks"
APP_DEBUG_LIBRARY="$DERIVED_DATA/Build/Products/Debug/PermeationLab.app/Contents/MacOS/PermeationLab.debug.dylib"
mkdir -p -- "$UNIT_TEST_FRAMEWORKS"
cp -- "$APP_DEBUG_LIBRARY" "$UNIT_TEST_FRAMEWORKS/"
xcrun xctest "$UNIT_TEST_BUNDLE"

if [[ "${PERMEATION_LAB_RUN_UI_TESTS:-0}" == "1" ]]; then
  xcodebuild test-without-building -quiet \
    -project "$PROJECT_FILE" \
    -scheme "$SCHEME" \
    -destination "$DESTINATION" \
    -derivedDataPath "$DERIVED_DATA" \
    -only-testing:PermeationLabUITests
else
  printf '%s\n' 'UI tests were compiled. Set PERMEATION_LAB_RUN_UI_TESTS=1 to execute them; manual UI QA remains required.'
fi
xcodebuild analyze -quiet \
  -project "$PROJECT_FILE" \
  -scheme "$SCHEME" \
  -destination "$DESTINATION" \
  -derivedDataPath "$DERIVED_DATA"

if rg -n \
  '(AKIA[0-9A-Z]{16}|sk-[A-Za-z0-9_-]{20,}|BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY)' \
  PermeationLab PermeationLabTests PermeationLabUITests
then
  printf '%s\n' 'Potential secret detected.' >&2
  exit 1
fi

printf '%s\n' 'Permeation Lab quality checks passed.'
