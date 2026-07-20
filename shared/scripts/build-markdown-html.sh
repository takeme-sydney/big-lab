#!/bin/sh
set -eu

PROJECT_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
RENDER="$PROJECT_ROOT/shared/scripts/render-research-document.sh"

is_custom_render() {
  case "$1" in
    shared/docs/lab-overview.md \
      | shared/docs/contribution-strategy.md \
      | shared/docs/learning-roadmap.md \
      | shared/docs/meeting-preparation.md \
      | shared/docs/yunong-yuan-research-guide.md \
      | shared/docs/contribution-map.md \
      | microneedle-drug-delivery/review/README.md \
      | photopolymer-biomaterials/review/README.md \
      | microneedle-drug-delivery/Notes/* \
      | microneedle-drug-delivery/references/papers/README.md \
      | microneedle-drug-delivery/references/papers/other-references/README.md \
      | microneedle-drug-delivery/references/correspondence/README.md \
      | microneedle-drug-delivery/references/correspondence/2026-07-17-yunong-yuan-microneedle-references-email.md \
      | microneedle-drug-delivery/references/translated\ \ papers/01-yuan-2023-drug-permeation-microneedled-skin-ml-ja.md)
      return 0
      ;;
  esac

  return 1
}

render() {
  source_file=$1
  output_file=${source_file%.md}.html
  source_dir=${source_file%/*}

  if [ "$source_dir" = "$source_file" ]; then
    source_dir=.
    prefix=
  else
    prefix=$(printf '%s\n' "$source_dir" | awk -F/ '{
      for (i = 1; i <= NF; i += 1) {
        printf "../"
      }
    }')
  fi

  title=$(awk '/^# / { sub(/^# /, ""); print; exit }' "$PROJECT_ROOT/$source_file")
  if [ -z "$title" ]; then
    title=${source_file##*/}
    title=${title%.md}
  fi

  case "$source_file" in
    README.md)
      section_label="WORKSPACE INDEX"
      ;;
    */requirements.md)
      section_label="PROJECT REQUIREMENTS"
      ;;
    */implementation-prompt.md)
      section_label="IMPLEMENTATION BRIEF"
      ;;
    */templates/*)
      section_label="WORKING TEMPLATE"
      ;;
    */notes/*)
      section_label="RESEARCH NOTE"
      ;;
    */references/*)
      section_label="EVIDENCE RECORD"
      ;;
    */pilot-charter.md)
      section_label="PILOT CHARTER"
      ;;
    */README.md)
      section_label="DOCUMENT INDEX"
      ;;
    *)
      section_label="RESEARCH DOCUMENT"
      ;;
  esac

  if [ "$source_file" = "README.md" ]; then
    description="調査資料、文献レビュー、研究参加案、ポートフォリオ、閲覧用Webサイトを研究分野ごとに案内するワークスペース索引。"
  else
    description="BiG Labの「${title}」に関するMarkdown正本のHTML閲覧版。"
  fi

  "$RENDER" \
    "$PROJECT_ROOT/$source_file" \
    "$PROJECT_ROOT/$output_file" \
    "$title" \
    "${prefix}shared/website/assets/research-document.css" \
    "${prefix}shared/website/index.html" \
    "$description" \
    "$section_label"

  printf '%s\n' "Built $output_file"
}

find "$PROJECT_ROOT" \
  -type f \
  -name '*.md' \
  -not -path "$PROJECT_ROOT/.git/*" \
  -not -path "$PROJECT_ROOT/node_modules/*" \
  -not -path "$PROJECT_ROOT/vendor/*" \
  -print |
  LC_ALL=C sort |
  while IFS= read -r source_path; do
    source_file=${source_path#"$PROJECT_ROOT"/}

    if [ "$source_file" = "AGENTS.md" ] || is_custom_render "$source_file"; then
      continue
    fi

    render "$source_file"
  done
