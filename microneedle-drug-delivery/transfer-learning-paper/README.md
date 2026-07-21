[HTML版を開く](README.html)

# Transfer Learning for Microneedle Drug Permeation QSAR — Executing RESEARCH_PLAN.md Phases 2–6

更新日: 2026-07-21
状態: 要件定義・指示文作成済み / Codex実行前

## Start here

1. 要件定義: [`requirements.md`](requirements.md)
2. 実行用指示文: [`implementation-prompt.md`](implementation-prompt.md)
3. 論文本文: [`paper.md`](paper.md)(作成予定)
4. 判断記録: [`notes/decision-log.md`](notes/decision-log.md)
5. 根拠資料(データ・コード・研究計画): [`../research/`](../research/)
6. 関連モジュール(別ブランチ、参照のみ): `../active-learning-paper/`(能動学習の補足研究ノート)、`../small-data-ml-paper/`(Perspective論文、新規計算なし)、`../competitive-landscape/`(学術的競合分析)

## このモジュールの位置づけ

`../research/RESEARCH_PLAN.md`はフェーズ0・1・1.5(スコープ定義・データ収集・Yuan 2023データセット再現)のみ完了している。フェーズ2〜6(データキュレーション、EDA、皮膚透過性QSARモデルとYuan 2023マイクロニードルモデルの2系統構築、転移学習、物理モデル併用データ拡張、SHAP解析、美容成分48件への応用)は本モジュールで**実際に計算・実行する**。

`../active-learning-paper/`(既に完了済みの能動学習シミュレーションを書き上げる)や`../small-data-ml-paper/`(新規計算を含まないPerspective論文)とは逆に、本モジュールは新規のPythonコードを書き、実際に実行し、その出力から論文を書く計算タスクである。

## 執筆パイプライン

1. Claude Sonnet 5 — `../research/`の全データ・コード・計画文書を精読し、`requirements.md`・`implementation-prompt.md`をフェーズ別マイルストームとして起草
2. Claude Fable 5 — 起草内容を独立レビュー・改善
3. Codex `gpt-5.6-terra`(reasoning effort: max) — 実際にデータキュレーション・モデル構築・転移学習・物理モデル拡張・SHAP解析・美容成分応用を計算し、`paper.md`を起草
4. Codex `gpt-5.6-sol`(reasoning effort: ultra) — 未完了マイルストームの継続、全数値の独立検証、仕上げ
5. Claude Sonnet 5 — 最終監査(サンプル再実行含む)、PR作成

## フォルダ構成

```text
transfer-learning-paper/
├── README.md
├── requirements.md
├── implementation-prompt.md
├── paper.md              # 論文本文(英語、作成予定)
└── notes/
    └── decision-log.md   # 研究判断・パイプライン実行記録
```

新規スクリプト・生成データ・図表は`../research/`直下に置く(既存モジュールと同じ規約)。

## 利用上の境界

- `../active-learning-paper/`・`../small-data-ml-paper/`・`../competitive-landscape/`(いずれも別ブランチ・別PR)のファイルは編集しない。参照は`git show <branch>:<path>`のみ。
- 214化合物・191点Yuanデータセット・48成分データセットの用途を混同しない。
- 美容成分48件にマイクロニードル実験パラメータを仮定しない。
- 物理モデル併用データ拡張の疑似データは実測データと明確に区別する。
