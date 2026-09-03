#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
DERIVED_DATA="$(mktemp -d /tmp/permeation-lab-unified-build.XXXXXX)"
BUILT_APP="$DERIVED_DATA/Build/Products/Release/PermeationLab.app"
DIST_APP="$PROJECT_DIR/dist/PermeationLab.app"

cleanup() {
  rm -rf -- "$DERIVED_DATA"
}
trap cleanup EXIT

xcodebuild build -quiet \
  -project "$PROJECT_DIR/PermeationLab.xcodeproj" \
  -scheme PermeationLab \
  -configuration Release \
  -destination 'generic/platform=macOS' \
  -derivedDataPath "$DERIVED_DATA" \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO

if [[ ! -d "$BUILT_APP" ]]; then
  printf 'Expected app bundle was not produced: %s\n' "$BUILT_APP" >&2
  exit 1
fi

mkdir -p -- "$PROJECT_DIR/dist"
if [[ -e "$DIST_APP" ]]; then
  rm -rf -- "$DIST_APP"
fi
ditto "$BUILT_APP" "$DIST_APP"
codesign --force --sign - "$DIST_APP"
codesign --verify --strict --verbose=2 "$DIST_APP"
printf 'Built the single Permeation Lab app: %s\n' "$DIST_APP"
