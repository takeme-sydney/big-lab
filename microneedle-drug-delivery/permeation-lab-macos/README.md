[HTML版を開く](README.html)

# Permeation Lab for macOS

更新日: 2026-08-27
対象論文: Yuan Y, Han Y, Yap CW, et al. *Prediction of drug permeation through microneedled skin by machine learning*. *Bioengineering & Translational Medicine*. 2023;8(6):e10512. DOI: 10.1002/btm2.10512

## 目的

Permeation Lab は、Yuan et al. (2023) の本文と同論文の Supporting Information だけを、macOS 上で体系的に読解・照合する研究教育用アプリである。論文の要約だけでなく、本文全節、191行の Data S1、式、表、図、Data S2 のコード、原著メタデータ、再現上の不足情報を一つの閲覧環境に収める。

本アプリは新しい予測器を発明しない。原著が公開していない係数、決定木、booster、train/test 行番号、未記載の前処理や乱数条件を補完せず、根拠のない予測曲線も生成しない。

## 最初に読む文書

1. [要件定義](docs/requirements.md)
2. [設計書](docs/design.md)
3. [実装指示文](docs/implementation-prompt.md)
4. [論文内容カバレッジ表](docs/paper-content-matrix.md)
5. [品質・科学的完全性監査](docs/audit-report.md)
6. [皮膚透過ビジュアライゼーション要件](docs/skin-permeation-visualization-requirements.md)
7. [医療系データビジュアライゼーション調査](docs/skin-permeation-design-research.md)
8. [皮膚透過機能の実装指示文](docs/skin-permeation-visualization-implementation-prompt.md)

## アプリに収録する内容

- 書誌情報、要旨、キーワード、著者・所属、連絡先、研究資金
- Introduction、Methods、Results、Discussion、Conclusion の全文リーダー
- 著者貢献、謝辞、利益相反、査読、データ可用性、倫理声明、ORCID、参考文献1–51、引用方法
- Data S1 の191観測・11列を原値のまま閲覧するデータブラウザ
- 独立した「皮膚透過」画面で、191累積時点観測の非連結散布図とhydrogel / plastic別のFranz-cell概念工程を照合
- Fick、MLR、RF、XGBoost の説明と、番号付き式（1）–（11）
- 式（11）に続く、原著では式番号のない2つの数値代入例
- Table 1–4 の全値
- Figure 1–8 と Supporting Information の Figure S1–S2
- Data S2 に掲載された R コードと C コードの読取専用ビュー
- 原著 PDF、Data S1、Data S2、SI3、CSV の SHA-256 照合
- 原著内の表記差、再現に不足する成果物、モデル利用上の限界

## 科学的境界

表示を許可する数値は、本文、表、図、Data S1、Data S2、SI3 に存在する値、または Data S1 から決定論的に求めた件数・最小値・最大値に限る。Data S1 から計算した値には「Data S1 集計」と表示し、原著本文に記載された値と混同しない。

次の機能は実装しない。

- 独自係数や経験則による Fick・MLR・RF・XGBoost の擬似予測
- 学習済みモデルであるかのように見せる対話曲線
- Data S1 の範囲外を含む新規条件の数値予測
- 診断、治療、投与量、安全性、有効性、患者転帰に関する推奨
- 論文外の研究、製品、ガイドライン、市場情報による説明の追加

## 原著で公開されたもの／されていないもの

原著は、191点を7:3で無作為に分けたこと、Table 3 のハイパーパラメータ、Table 4 の性能、Data S2 のコードを公開している。Data S2 の R コードには `set.seed(0)` があるが、既に作成済みの `train set.csv` と `test set.csv` を読み込む構造であり、分割そのものを作るコードではない。

次は同梱資料に存在しないため、アプリは復元済みと主張しない。

- train/test のCSV、各行の割当、分割を生成した処理
- MLR の確定係数・切片
- RF の学習済み forest
- XGBoost の学習済み booster
- 4モデルの全予測行と完全な評価中間出力
- Table 3 の透過量用設定を実行する独立した R コード経路

## 一次資料

- [原著PDF](../../shared/references/papers/yunong-yuan/microneedle/03-yuan-2023-machine-learning-microneedled-skin-permeation.pdf)
- [Data S1](../drug-release-profile/references/supplementary/06-yuan-2023-data-s1.xlsx)
- [Data S2 / Code SI2](../drug-release-profile/references/supplementary/07-yuan-2023-code-si2.docx)
- [Figure S1–S2 / SI3](../drug-release-profile/references/supplementary/08-yuan-2023-new-drug-figures-si3.docx)
- [Data S1由来CSV](../research/data/raw/yuan2023_training_data.csv)
- [原著日本語閲覧版](<../references/translated  papers/01-yuan-2023-drug-permeation-microneedled-skin-ml-ja.md>)

## 文書生成

このディレクトリの Markdown が正本である。対応HTMLは、リポジトリ直下から次を実行して生成・検証する。

```sh
./shared/scripts/build-website.sh
```

アプリの検証は `scripts/quality-check.sh`、Release app生成は `scripts/build-app.sh` を使う。実測したbuild・unit test・analyze・GUI・署名結果と、自動UI runnerの環境制約は[監査報告](docs/audit-report.md)に記録する。
