[HTML版を開く](README.html)

# Small-Data ML for Microneedle Drug Permeation — Perspective Paper

更新日: 2026-07-20
状態: 論文ドラフト作成中 / PI・指導者レビュー前

## Start here

1. 要件定義: [`requirements.md`](requirements.md)
2. 実行用指示文: [`implementation-prompt.md`](implementation-prompt.md)
3. 論文本文: [`paper.md`](paper.md)
4. 判断記録: [`notes/decision-log.md`](notes/decision-log.md)
5. 根拠資料(データ・コード・文献マップ): [`../research/`](../research/)

## このモジュールの位置づけ

`../research/` は進行中の研究作業ディレクトリ(RESEARCH_PLAN.md, 実測データ, 文献マップ, 記述子計算コード)であり、ここ `small-data-ml-paper/` はそこから**論文を書き上げる**ための成果物置き場である。

論文は **Perspective / Research proposal** として書かれている。RESEARCH_PLAN.md のフェーズ0・1・1.5(文献マップ構築、データ収集、Yuan et al. (2023) データの再現)は完了済みの成果として報告するが、フェーズ2〜6(データキュレーション、モデル構築、transfer learning、SHAP解析、美容成分予測)は**まだ実行していない**ため、論文内では今後の計画として明示的に区別して書かれている。新規の計算結果(R²、RMSE、SHAP値、予測log Kp値など)は一切含まれない。

## 執筆パイプライン

要件定義・指示文を1つの多段パイプラインで仕上げている(`notes/decision-log.md` に詳細記録):

1. Claude Sonnet 5 — `research/` を精読し、`requirements.md` / `implementation-prompt.md` を起草
2. Claude Fable 5 — 起草内容を独立レビューし、直接改善
3. Codex `gpt-5.6-terra`(reasoning effort: max) — `paper.md` 本文を可能な限り作成
4. Codex `gpt-5.6-sol`(reasoning effort: ultra) — 指示文をそのまま実行し、残りを仕上げ・検証

## フォルダ構成

```text
small-data-ml-paper/
├── README.md
├── requirements.md
├── implementation-prompt.md
├── paper.md              # 論文本文(英語)
└── notes/
    └── decision-log.md   # 研究判断・パイプライン実行記録
```

## 利用上の境界

- 新規のモデル訓練・交差検証・SHAP計算は行わない(別タスク)。
- 美容成分の予測値を具体的数値として主張しない。
- 引用は `../research/microneedle_ml_literature.csv` と RESEARCH_PLAN.md 記載の中核5文献の範囲に限定し、実在確認できない文献は追加しない。
- 購読論文の本文転載・再配布はしない。
