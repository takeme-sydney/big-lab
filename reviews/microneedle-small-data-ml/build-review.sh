#!/usr/bin/env bash
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
cd "$here"

pandoc README.md \
  --from=markdown+yaml_metadata_block+pipe_tables+header_attributes \
  --to=html5 \
  --standalone \
  --toc \
  --toc-depth=2 \
  --template=../../website/templates/microneedle-small-data-ml.html \
  --css=../../reviews/photopolymer-biomaterials/assets/styles.css \
  --output=../../website/pages/microneedle-small-data-ml-review.html

echo "Built $here/../../website/pages/microneedle-small-data-ml-review.html"
