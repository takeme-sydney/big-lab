#!/usr/bin/env bash
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
cd "$here"

pandoc README.md \
  --from=gfm+yaml_metadata_block \
  --to=html5 \
  --standalone \
  --toc \
  --toc-depth=2 \
  --template=../../website/templates/photopolymer-biomaterials.html \
  --lua-filter=../../scripts/filters/photopolymer-html-filter.lua \
  --css=../../reviews/photopolymer-biomaterials/assets/styles.css \
  --output=../../website/pages/photopolymer-biomaterials-review.html

echo "Built $here/../../website/pages/photopolymer-biomaterials-review.html"
