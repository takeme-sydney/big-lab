#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
BASENAME="01-yuan-2023-drug-permeation-microneedled-skin-ml-ja"
MARKDOWN_PATH="$SCRIPT_DIR/$BASENAME.md"
HTML_PATH="$SCRIPT_DIR/$BASENAME.html"
PDF_PATH="$SCRIPT_DIR/$BASENAME.pdf"
ASSET_DIR="$BASENAME-assets"
CHROME_BIN="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"

cd "$SCRIPT_DIR"

pandoc "$MARKDOWN_PATH" \
  --from="markdown+fenced_divs+raw_html" \
  --to=html5 \
  --standalone \
  --mathml \
  --embed-resources \
  --resource-path="$SCRIPT_DIR" \
  --css="$ASSET_DIR/article.css" \
  --metadata="pagetitle:機械学習によるマイクロニードル処理皮膚を介した薬物透過の予測" \
  --output="$HTML_PATH"

if [[ ! -x "$CHROME_BIN" ]]; then
  echo "Google Chrome was not found at: $CHROME_BIN" >&2
  exit 1
fi

HTML_URI="$(
  python3 - "$HTML_PATH" <<'PY'
from pathlib import Path
import sys
print(Path(sys.argv[1]).resolve().as_uri())
PY
)"

"$CHROME_BIN" \
  --headless=new \
  --disable-gpu \
  --allow-file-access-from-files \
  --run-all-compositor-stages-before-draw \
  --virtual-time-budget=1500 \
  --no-pdf-header-footer \
  --print-to-pdf="$PDF_PATH" \
  "$HTML_URI"

echo "Built:"
echo "  $HTML_PATH"
echo "  $PDF_PATH"
