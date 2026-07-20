[HTML版を開く](README.html)

# Small-Data ML for Microneedle Drug Permeation — Perspective Paper

更新日: 2026-07-20
状態: 完成ドラフト / PI・指導者レビュー前

## Start here

1. 要件定義: [`requirements.md`](requirements.md)
2. 実行用指示文: [`implementation-prompt.md`](implementation-prompt.md)
3. 論文本文: [`paper.md`](paper.md)
4. 判断記録: [`notes/decision-log.md`](notes/decision-log.md)
5. 根拠資料(データ・コード・文献マップ): [`../research/`](../research/)

## このモジュールの位置づけ

`../research/` は進行中の研究作業ディレクトリ(RESEARCH_PLAN.md, 実測データ, 文献マップ, 記述子計算コード)であり、ここ `small-data-ml-paper/` はそこから**論文を書き上げる**ための成果物置き場である。

論文は **Perspective / Research proposal** として書かれている。RESEARCH_PLAN.md のフェーズ0・1・1.5(文献マップ構築、データ収集、Yuan et al. (2023) データの再現)は完了済みの成果として報告するが、フェーズ2〜6(データキュレーション、モデル構築、transfer learning、SHAP解析、美容成分予測)は**まだ実行していない**ため、論文内では今後の計画として明示的に区別して書かれている。新規の計算結果(R²、RMSE、SHAP値、予測log Kp値など)は一切含まれない。

## 今回の成果物

- paper.md は英語のPerspective / research-proposal本文であり、AbstractからReferencesまでの10章構成を備える。
- 既存の文献マップ図を根拠図として再利用し、Figure 1は8テーマカテゴリ、Figure 2は影響力と手法分布として明記する。
- 美容成分の候補集合については、構造・記述子の準備状況と化学空間のスクリーニングのみを報告する。個別の予測log Kp値や未実行モデルの性能値は掲載しない。
- notes/decision-log.md には、数値allowlist、完了事実と将来計画の仕分け、捏造監査、受入条件の自己採点を記録する。
- paper.html、README.html、notes/decision-log.htmlは生成済みである。リポジトリ全体のリンク検証は、research/CLAUDE.mdに既存のHTML先頭リンクがないため停止しており、詳細はdecision logに記録する。

## 執筆パイプライン

要件定義・指示文を1つの多段パイプラインで仕上げている(`notes/decision-log.md` に詳細記録):

1. Claude Sonnet 5 — `research/` を精読し、`requirements.md` / `implementation-prompt.md` を起草
2. Claude Fable 5 — 起草内容を独立レビューし、直接改善
3. Codex `gpt-5.6-terra`(reasoning effort: max) — `paper.md` 本文、数値allowlist、捏造監査、HTML生成を実施
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

- これは執筆タスクであり計算タスクではない。新規のモデル訓練・交差検証・SHAP計算を行わず、`descriptors.py` を含むモデリング/計算コードもこの論文のために実行しない(`research/` は読んで引用するのみ)。
- 美容成分の予測値を具体的数値として主張しない。特に `cosmetic_ingredients_descriptors.csv` の `logKp_PottsGuy_baseline`(48件分の未検証な式出力)を予測結果として転記しない。
- Yuan (2023) が自ら報告した値(XGBoost R²=0.98 等)は「先行研究の事実」として引用してよいが、本研究の成果と取り違えない。
- 引用は `../research/microneedle_ml_literature.csv` と `../research/CLAUDE.md`「中核となる参考文献」節の中核5文献の範囲に限定し、実在確認できない文献は追加しない。
- 購読論文の本文転載・再配布はしない。
- Markdownを正本とし、各文書は同名HTMLへの先頭リンクを持つ。更新時はリポジトリ標準のshared/scripts/build-website.shでHTMLを再生成・検証する。
