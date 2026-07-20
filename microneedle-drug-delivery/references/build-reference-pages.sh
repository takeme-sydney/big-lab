#!/usr/bin/env sh
set -eu

HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
PROJECT_ROOT=$(CDPATH= cd -- "$HERE/../.." && pwd)
RENDER="$PROJECT_ROOT/shared/scripts/render-research-document.sh"

"$RENDER" \
  "$HERE/papers/README.md" \
  "$HERE/papers/README.html" \
  "Microneedle × Small-data ML — PDF index" \
  "../../../shared/website/assets/research-document.css" \
  "../../../shared/website/index.html" \
  "Yunong Yuan氏のメールで共有されたmicroneedle・small-data ML文献の取得状況、出典、利用条件、整合性をまとめた索引。" \
  "EVIDENCE INDEX"

"$RENDER" \
  "$HERE/papers/other-references/README.md" \
  "$HERE/papers/other-references/README.html" \
  "Other references" \
  "../../../../shared/website/assets/research-document.css" \
  "../../../../shared/website/index.html" \
  "共有メールに記載されていない、microneedle drug deliveryとsmall-data MLの追加文献を管理する索引。" \
  "EVIDENCE INDEX"

"$RENDER" \
  "$HERE/correspondence/README.md" \
  "$HERE/correspondence/README.html" \
  "Correspondence" \
  "../../../shared/website/assets/research-document.css" \
  "../../../shared/website/index.html" \
  "研究関連の通信原本と、Markdownを正本とする文字起こしを案内する索引。" \
  "SOURCE RECORDS"

"$RENDER" \
  "$HERE/correspondence/2026-07-17-yunong-yuan-microneedle-references-email.md" \
  "$HERE/correspondence/2026-07-17-yunong-yuan-microneedle-references-email.html" \
  "Yunong Yuan氏からのmicroneedle関連文献メール（2026-07-17）" \
  "../../../shared/website/assets/research-document.css" \
  "../../../shared/website/index.html" \
  "microneedle薬物送達予測とsmall-data machine learningに関する共有文献メールの文字起こし。" \
  "CORRESPONDENCE"

printf '%s\n' "Generated reference HTML pages in $HERE"
