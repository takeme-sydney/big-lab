#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
PROJECT_FILE="$PROJECT_DIR/PermeationLab.xcodeproj"
SCHEME="PermeationLab"
DERIVED_DATA="$(mktemp -d /tmp/permeation-lab-build.XXXXXX)"
BUILT_APP="$DERIVED_DATA/Build/Products/Release/PermeationLab.app"
DIST_DIR="$PROJECT_DIR/dist"
DIST_APP="$DIST_DIR/PermeationLab.app"
ENTITLEMENTS="$PROJECT_DIR/PermeationLab/PermeationLab.entitlements"

cleanup() {
  rm -rf -- "$DERIVED_DATA"
}
trap cleanup EXIT

plutil -lint "$ENTITLEMENTS"

xcodebuild build \
  -project "$PROJECT_FILE" \
  -scheme "$SCHEME" \
  -configuration Release \
  -destination 'generic/platform=macOS' \
  -derivedDataPath "$DERIVED_DATA" \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO

if [[ ! -d "$BUILT_APP" ]]; then
  printf 'Expected app bundle was not produced: %s\n' "$BUILT_APP" >&2
  exit 1
fi

mkdir -p -- "$DIST_DIR"
if [[ -e "$DIST_APP" ]]; then
  case "$DIST_APP" in
    "$PROJECT_DIR/dist/PermeationLab.app") rm -rf -- "$DIST_APP" ;;
    *)
      printf 'Refusing to replace unexpected path: %s\n' "$DIST_APP" >&2
      exit 1
      ;;
  esac
fi

ditto "$BUILT_APP" "$DIST_APP"
if [[ ! -f "$DIST_APP/Contents/Resources/PrivacyInfo.xcprivacy" ]]; then
  printf '%s\n' 'Privacy manifest is missing from the built app.' >&2
  exit 1
fi
codesign \
  --force \
  --sign - \
  --timestamp=none \
  --options runtime \
  --entitlements "$ENTITLEMENTS" \
  "$DIST_APP"
codesign --verify --deep --strict --verbose=2 "$DIST_APP"

printf 'Built app: %s\n' "$DIST_APP"
