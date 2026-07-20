#!/usr/bin/env sh
set -eu

HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
PROJECT_ROOT=$(CDPATH= cd -- "$HERE/../.." && pwd)
RENDER="$PROJECT_ROOT/shared/scripts/render-research-document.sh"

render() {
  source_file=$1
  output_file=${source_file%.md}.html
  title=$(awk '/^# / { sub(/^# /, ""); print; exit }' "$HERE/$source_file")

  case "$source_file" in
    README.md)
      description="Microneedle drug deliveryに関するノートと研究案を、Markdown正本とHTML閲覧版の組で管理する索引。"
      section_label="RESEARCH NOTES"
      ;;
    2026-07-20-microneedle-research-examples.md)
      description="共有文献を起点に、BiG Labで検討できるmicroneedle研究テーマ、最小検証、評価条件を優先順位付きで整理した議論用ノート。"
      section_label="DISCUSSION DRAFT"
      ;;
    *)
      description="Microneedle drug deliveryに関するBiG Labの調査・研究ノート。"
      section_label="RESEARCH NOTE"
      ;;
  esac

  "$RENDER" \
    "$HERE/$source_file" \
    "$HERE/$output_file" \
    "$title" \
    "../../shared/website/assets/research-document.css" \
    "../../shared/website/index.html" \
    "$description" \
    "$section_label"
}

find "$HERE" \
  -maxdepth 1 \
  -type f \
  -name '*.md' \
  -print |
  LC_ALL=C sort |
  while IFS= read -r source_path; do
    render "${source_path##*/}"
  done

printf '%s\n' "Generated HTML files in $HERE"
