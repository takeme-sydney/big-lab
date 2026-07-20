#!/bin/sh
set -eu

PROJECT_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
OUTPUT_DIR="$PROJECT_ROOT/shared/website/pages"
TEMPLATE="$PROJECT_ROOT/shared/website/templates/intern.html"
FILTER="$PROJECT_ROOT/shared/scripts/filters/intern-html-filter.lua"

mkdir -p "$OUTPUT_DIR"

render() {
  source_file=$1
  output_file=$2
  title=$3
  module=$4
  updated=$5
  status=$6
  reading=$7
  lede=$8
  abstract=$9
  nav_key=${10}

  pandoc "$PROJECT_ROOT/shared/docs/$source_file" \
    --from=markdown \
    --to=html5 \
    --standalone \
    --template="$TEMPLATE" \
    --lua-filter="$FILTER" \
    --toc \
    --toc-depth=2 \
    --metadata="title:$title" \
    --variable="module:$module" \
    --variable="updated:$updated" \
    --variable="status:$status" \
    --variable="reading:$reading" \
    --variable="lede:$lede" \
    --variable="abstract:$abstract" \
    --variable="source:docs/$source_file" \
    --variable="$nav_key:true" \
    --output="$OUTPUT_DIR/$output_file"
}

render \
  "lab-overview.md" \
  "intern-overview.html" \
  "BiG Labとは何か" \
  "I-01" \
  "16 Jul 2026" \
  "OVERVIEW" \
  "約8分" \
  "BIGの研究領域、角膜バイオプリンティング、Wet labとDry labの接点を最初に把握する資料。" \
  "面談やプロジェクト案の前提となる、研究室全体の地図です。公開情報と参加提案を分けて記載しています。" \
  "nav_overview"

render \
  "contribution-strategy.md" \
  "intern-contribution-strategy.html" \
  "Takumiの研究貢献戦略" \
  "I-02" \
  "16 Jul 2026" \
  "DISCUSSION DRAFT" \
  "約30分" \
  "強みと未実証領域を分け、最初の4週間で実行するCurved Corneal Construct QC Pilotを具体化した提案書。" \
  "正式な研究計画ではなく、Yunong Yuan氏・Jingjing You先生との面談で検討するための仮説です。" \
  "nav_contribution"

render \
  "learning-roadmap.md" \
  "intern-roadmap.html" \
  "12週間の学習・研究参加ロードマップ" \
  "I-03" \
  "15 Jul 2026" \
  "ACTION PLAN" \
  "約12分" \
  "面談前から研究開始後12週間までを、オンボーディング、基礎、実装、発表の順に進める行動計画。" \
  "各Phaseの目的、タスク、成果物、次へ進む判断基準を確認できます。" \
  "nav_roadmap"

render \
  "meeting-preparation.md" \
  "intern-meeting.html" \
  "研究面談の予習・準備" \
  "I-04" \
  "15 Jul 2026" \
  "MEETING READY" \
  "約6分" \
  "読む論文、最初の貢献案、確認質問、英語スクリプト、返信メールを面談前の順番にまとめた実務メモ。" \
  "面談を技術試験ではなく、研究プロジェクトを一緒に定義する最初の打合せとして準備します。" \
  "nav_meeting"

render \
  "yunong-yuan-research-guide.md" \
  "intern-yunong-yuan.html" \
  "Yunong Yuan氏の研究ガイド" \
  "I-05" \
  "16 Jul 2026" \
  "PUBLIC SOURCE BRIEF" \
  "約25分" \
  "熱・結晶化の物理モデルから、薬物送達、機械学習、角膜バイオプリンティングへ発展した研究を一次資料で整理。" \
  "公開研究成果12本とMPhil thesis、論文別の要点、PDF取得状況、面談で確認する質問をまとめています。" \
  "nav_yuan"

render \
  "contribution-map.md" \
  "intern-contribution-map.html" \
  "BiG LabでTakumiができること" \
  "I-06" \
  "16 Jul 2026" \
  "4-WEEK PILOT MAP" \
  "約12分" \
  "Yuan氏の論文が示すevidence gapを、4週間のCurved Corneal Construct Geometry QCへ落とし込んだ実行案。" \
  "依頼文のPIG表記に関する前提、優先順位、成果物、成功基準、安全境界、英語pitchを一つにまとめています。" \
  "nav_role"

"$PROJECT_ROOT/photopolymer-biomaterials/review/build-review.sh"
"$PROJECT_ROOT/microneedle-drug-delivery/review/build-review.sh"
"$PROJECT_ROOT/microneedle-drug-delivery/Notes/build-notes.sh"
"$PROJECT_ROOT/microneedle-drug-delivery/references/build-reference-pages.sh"
"$PROJECT_ROOT/shared/scripts/build-markdown-html.sh"
"$PROJECT_ROOT/shared/scripts/check-document-html-links.sh"

printf '%s\n' "Generated and validated all Markdown-backed HTML documents."
