[HTML版を開く](README.html)

# Retrospective Active Learning for Microneedle Drug Permeation — Research Note

更新日: 2026-07-21
状態: 下書き完成・数値検証パイプライン実行中(sonnet段階)

## Start here

1. 要件定義: [`requirements.md`](requirements.md)
2. 実行用指示文: [`implementation-prompt.md`](implementation-prompt.md)
3. 論文本文: [`paper.md`](paper.md)
4. 判断記録: [`notes/decision-log.md`](notes/decision-log.md)
5. 根拠資料(コード・結果CSV・図・文献マップ): [`../research/`](../research/)

## このモジュールの位置づけ

`../research/` は進行中の研究作業ディレクトリであり、ここ `active-learning-paper/` はそこから**research noteを書き上げる**ための成果物置き場である。

[`../small-data-ml-paper/`](../small-data-ml-paper/)(ブランチ `microneedle-small-data-ml-paper`)とは性格が異なる: あちらは新規計算結果を含まない Perspective/proposal 論文だが、こちらは **`../research/active_learning.py` を用いて既に実行済みの後ろ向き能動学習(retrospective active learning)シミュレーションの実在する数値結果を報告する research note** である。Yuan et al. (2023) の191点・6薬剤データセットを未実験プールとみなし、Random / Gaussian Process uncertainty sampling / Random Forest query-by-committee の3つの獲得戦略を、(1) 分布内学習曲線、(2) leave-one-drug-out外挿、の2設定で比較している。新規のデータ収集・wet-lab実験は行っていない。

## 今回の成果物

- `paper.md` は英語のresearch note本文であり、Abstract・Introduction・Data and Methods・Results・Discussion・Conclusion・Data and Code Availability・Referencesで構成される(既存草稿の章立てを維持)。
- Figure 1(`../research/fig_active_learning_curves.png`)は分布内学習曲線と目標精度到達に必要な実験数、Figure 2(`../research/fig_lodo_comparison.png`)はleave-one-drug-out設定でのRMSE比較を示す。
- 主要な結果: GP-Uncertaintyサンプリングは中程度の精度目標(R²≥0.85)にRandomサンプリングより18%少ない実験数で到達するが、高精度域や新規薬剤クラスへの外挿では優位性がない。
- `notes/decision-log.md` には、数値allowlist、パイプライン各段階の判断、監査結果を記録する。

## 執筆パイプライン

要件定義・指示文を1つの多段パイプラインで仕上げている(`notes/decision-log.md` に詳細記録):

1. Claude Sonnet 5 — `research/` の既存下書き・結果CSV・図を精読し、`requirements.md` / `implementation-prompt.md` を起草
2. Claude Fable 5 — 起草内容を独立レビューし、直接改善
3. Codex `gpt-5.6-terra`(reasoning effort: max) — 図の修復、`paper.md` の完成、数値allowlistの照合、HTML生成
4. Codex `gpt-5.6-sol`(reasoning effort: ultra) — 指示文をそのまま実行し、残りを仕上げ・独立検証

## フォルダ構成

```text
active-learning-paper/
├── README.md
├── requirements.md
├── implementation-prompt.md
├── paper.md              # 論文本文(英語)
└── notes/
    └── decision-log.md   # 研究判断・パイプライン実行記録
```
