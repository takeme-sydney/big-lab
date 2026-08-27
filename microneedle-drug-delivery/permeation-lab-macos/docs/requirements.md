[HTML版を開く](requirements.html)

# Permeation Lab macOS アプリ要件定義

文書版: 1.1
作成・更新日: 2026-08-27
対象: Yuan et al. (2023), PMID 38023708

## 1. Product definition

Permeation Lab は、Yuan et al. が報告したマイクロニードル処理皮膚の薬物透過予測研究を、本文、補足資料、実測データ、式、表、図、コード、再現限界まで一つの native macOS アプリで照合するオフライン研究リーダーである。

本アプリは新規条件の予測器ではない。公開されていない学習済みモデル、係数、train/test 行割当を推測せず、原著が報告した値と Data S1 の観測値だけを扱う。

## 2. Scientific source boundary

### 2.1 許可する情報源

科学的内容は次の同一論文一式だけに限定する。

1. 原著15ページの本文、図表、末尾情報、参考文献一覧
2. Data S1 の単一 worksheet、191観測、11列
3. Data S2 の R コードと C コード
4. SI3 の Figure S1 と Figure S2
5. 上記から機械的に確認できる行数、列数、カテゴリ件数、最小値、最大値、ファイルサイズ、SHA-256
6. 同じ原著の日本語翻訳版と、原著から抽出した図

macOS、SwiftUI、Charts、AppKitのHTML読込、CSV 読込、テスト、アクセシビリティは実装手段であり、新しい科学的主張の情報源にはしない。

### 2.2 禁止事項

- 論文外の医学、薬学、機械学習、製品、ガイドライン、市場情報の追加
- 独自の物理係数、回帰係数、決定木、閾値、補正式、予測曲線
- `educational surrogate` を含む未出典の数値予測
- Table 4 をアプリが再学習・再計算した結果と表現すること
- Data S1 の 108.3982246% を100%へ制限、丸め、除外すること
- source 間の単位・表記差を無言で統一すること
- 診断、治療、投与量、安全性、有効性、患者転帰の判断機能

## 3. Information architecture

sidebar は次の8画面を持つ。

1. 研究概要
2. 方法・数式
3. 実測データ
4. 皮膚透過
5. 結果・比較
6. 原著図
7. 全文
8. 研究情報

式と Tables 1–3、Data S2 は「方法・数式」へ、Table 4 は「結果・比較」へ統合する。front matter、本文全節、end matter、参考文献1–51は「全文」で原著順に読めるようにする。

## 4. Functional requirements

### FR-01 研究概要

- title、authors、journal、year、DOI、PMID、研究目的、4手法、2 outcomes を示す。
- 原著の7:3無作為分割と、Table 4 の主要結果を「原著報告値」として示す。
- Data S2 に `set.seed(0)` はあるが、無作為分割処理自体は掲載されず、既成のtrain/test CSVを読むだけなので固定行割当を再構成しないことを明記する。
- 学習済みモデルを同梱せず、新しい予測値を生成しないことを常時明示する。

### FR-02 方法・数式

- データ収集、Fick、MLR、RF、XGBoost、学習・評価手順を原著記載の範囲で説明する。
- Fick モデルの5仮定をすべて収録する。
- 番号付き式 (1)–(11) を番号、式、原著由来の記号説明、source locator とともに表示する。
- 式 (11) 後の2つの数値代入は、原著どおり「番号なし計算例」として別表示する。
- Tables 1–3 の全パラメータ、特徴量、ハイパーパラメータを表示する。
- Data S2 から抽出した R/C コード全体を、実行機能のない選択可能な monospaced text として表示する。
- 欠落する `train set.csv` / `test set.csv`、学習済みモデル、掲載Cコードの構文欠落を明記し、推測補完しない。

### FR-03 実測データ

- Data S1 由来CSVの191観測・11 source fieldsを読取専用で保持する。
- drug、skin type、MN type で絞り込み、amount / percentage を切り替える。
- フィルタ件数、選択 outcome の最小値・最大値を `Data S1 集計` として示す。
- time 対 outcome を `PointMark` だけで表示し、線、回帰、補間、外挿、平均を加えない。
- 全観測を1ページ20件の paged table で閲覧できる。skin と MN は同一表示列内でも両値を明示し、11 source fields の内容を失わない。
- 数値は source precision を保持できる最大10桁の小数表示を用いる。
- amount は Data S1 header に従い `µg/cm²`、percentage は `%` とする。
- 108.3982246%を原値のまま表示する。

### FR-04 皮膚透過

- Data S1 の191観測と、原著が説明する hydrogel / plastic MN の実験工程を同一画面で照合する。
- 観測点を空間座標、粒子、連続時系列として扱わず、非連結散布図として表示する。
- drug、skin、MN、outcome のfilter、全解除、前後観測、観測pickerを提供する。
- 選択観測について11 source fieldsを縦に表示し、空 reference は `blank in Data S1` と示す。
- 概念図の要素は原著にある donor / patch、角質層、皮膚膜、Franz receptor 液に限定する。
- hydrogel の留置工程と plastic の抜去後工程を区別する。
- 概念図は常に `非定量・縮尺外` と表示し、glyph 数・速度・深さ・位置を観測値へ対応させない。
- animation は停止状態で開始し、再生、一時停止、一段送り、リセットを提供する。Reduce Motion 時は移動を停止する。
- Figure 4 は Fick model の濃度mapであり、Data S1 の空間測定ではないことを明記し、新しい中間frameを生成しない。

### FR-05 結果・比較

- Table 4 の4モデル×2 outcomesの RMSE / R²を全値表示する。
- 値は原著報告値であり再計算値ではないことを明記する。
- XGBoostが両 outcome で最良、amount の次点が Fick、percentage の次点が RF、MLRが最低という原著の順位を表示する。
- Figures 4–8 に対応する Fick の挙動、モデル比較、特徴量重要度を原著記載の範囲で整理する。
- 原著が XGBoost をさらに検証した `a drug purposely removed` の新規薬物検証を、各薬物で反復したと断定せず提示する。

### FR-06 原著図

- Figures 1–8 と Figures S1–S2 の10画像を選択して閲覧できる。
- 画像は aspect-fit で表示し、縦横比を変えない。
- 各図に source label、原著由来caption要約、読み方を付ける。
- 原著そのものの完全なcaptionは「全文」で図と同じ位置から確認できる。
- 画像から独自数値を読み取ったり、Figure 4 の補間mapを生成したりしない。

### FR-07 全文

- 自己完結した日本語HTMLを bundle から AppKit の読取専用rich-textへ読み込み、選択可能な全文として表示する。
- front matter、authors、affiliations、correspondence、abstract、sections 1–5、式 (1)–(11)と番号なし計算例、Tables 1–4、Figures 1–8、end matter、references 1–51、how to cite を収録する。
- 原著の表記上の不一致を翻訳側で黙って訂正しない。
- 同梱した原著PDFを開ける。
- import後のlink属性を除去し、JavaScript実行・外部navigation・ネットワーク通信を持たせない。

### FR-08 研究情報・完全性

- 書誌、著者、所属、連絡先、研究資金、謝辞、利益相反、データ可用性、倫理、ORCID、著者貢献を表示する。
- 原著PDF、Data S1 XLSX/CSV、Data S2 DOCX、SI3 DOCXのSHA-256を実行時に計算し、baselineと照合する。
- Data S2からのtext転記と日本語全文HTMLも同梱sourceとして列挙する。
- train/test 行割当、split生成code、最終MLR係数、RF forest、XGBoost boosterなど、公開されていないartifactを明記する。
- 原著本文、Tables、Data S1、Data S2 間の表記差を別項目として示す。

## 5. Source discrepancies to preserve

- 原著本文は BSA / GHK / copper を `33% / 24% / 24%`、Rhodamine B / caffeine を各10%と記す一方、Data S1 の件数は33 / 24 / 24 / 19 / 18である。
- Data S1 amount header は `µg/cm²`、Table 4 の amount RMSE は `µg` である。
- BSA MW は本文と Data S1 で66,000 Da、Table 2で66,430 Daである。
- MN type は Methods / Data S1 で hydrogel / plastic、Table 2で hydrogel / solid と記される。
- MLR 式 (4) は切片 `b` を含むが、Data S2 の式は `Results ~ . - 1` で切片を除外する。

## 6. Non-functional requirements

- macOS 14+、Swift 6、native SwiftUI / Charts / AppKit。
- App Sandbox と Hardened Runtime を有効にする。
- network entitlement、analytics、account、remote databaseを持たない。
- scientific resourcesはbundle内のimmutable fileとし、missing resourceをdemo dataで埋めない。
- sidebarとdetailの2領域がwindow resizeに追従する。
- text selection、system control、caption、symbol、accessibility identifierを用い、色だけに意味を持たせない。
- privacy manifest は tracking false とし、収集データを宣言しない。

## 7. Verification requirements

unit testsは少なくとも次を検証する。

- 191行、6薬物、drug / skin / MN counts
- 全数値範囲と108.3982246%
- 全191行で `amount = loading × percentage / 100`
- Table 4 全16値
- 番号付き式 (1)–(11)、番号なし計算例2件、図10点
- 皮膚透過scatterが非連結観測点だけを使うこと
- hydrogel / plastic の工程が異なること
- filter後の選択順が決定的であること

UI test targetは起動、8画面navigation、皮膚透過の境界・図・観測detail・controlsをコンパイル可能な形で持つ。自動UI runnerを実行できない環境では、その事実を記録し、実appの全画面目視確認で代替した範囲を明記する。

完成判定には、warning-free build、unit tests、static analyze、Release build、ad-hoc signing、source hash、実app目視、Markdown/HTML同期を要求する。未実行項目を成功と記録しない。
