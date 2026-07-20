#!/usr/bin/env sh
set -eu

if [ "$#" -lt 7 ]; then
  printf '%s\n' "Usage: $0 SOURCE OUTPUT TITLE CSS_HREF HOME_HREF DESCRIPTION SECTION_LABEL" >&2
  exit 2
fi

SOURCE_FILE=$1
OUTPUT_FILE=$2
TITLE=$3
CSS_HREF=$4
HOME_HREF=$5
DESCRIPTION=$6
SECTION_LABEL=$7

TITLE_BYTES=$(LC_ALL=C printf '%s' "$TITLE" | wc -c | tr -d ' ')
if [ "$TITLE_BYTES" -gt 80 ]; then
  TITLE_CLASS=extra-long-title
elif [ "$TITLE_BYTES" -gt 50 ]; then
  TITLE_CLASS=long-title
else
  TITLE_CLASS=
fi

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
TEMPLATE="$SCRIPT_DIR/../website/templates/research-document.html"

pandoc "$SOURCE_FILE" \
  --from=markdown+yaml_metadata_block+pipe_tables+header_attributes \
  --to=html5 \
  --standalone \
  --toc \
  --toc-depth=3 \
  --template="$TEMPLATE" \
  --css="$CSS_HREF" \
  --metadata="lang=ja" \
  --metadata="title=$TITLE" \
  --metadata="home-url=$HOME_HREF" \
  --metadata="source-file=$(basename "$SOURCE_FILE")" \
  --metadata="description=$DESCRIPTION" \
  --metadata="section-label=$SECTION_LABEL" \
  --metadata="title-class=$TITLE_CLASS" \
  --output="$OUTPUT_FILE"
