[HTML版を開く](design.html)

# Permeation Lab macOS アプリ設計書

## 1. Design intent

Permeation Lab の中心は予測consoleではなく evidence reader である。利用者が「原著が何を問うたか」「どの実測値、式、図表、コードを使ったか」「何が報告され、何が公開されていないか」を、原著と補足資料だけで確認できるようにする。

設計原則は次の5点とする。

1. source before interpretation: 要約から原著の節・表・図・Data S1へ戻れる。
2. reported before computed: 原著報告値とData S1の決定論的集計を区別する。
3. no synthetic science: 欠けたmodel artifactを仮定で埋めない。
4. progressive disclosure: 概要から全文、raw observation、codeへ深掘りする。
5. visible integrity: source hash、不一致、再現限界を独立画面で示す。

## 2. Navigation map

```text
Permeation Lab
├── 研究概要
├── 方法・数式
│   ├── Methods 2.1–2.8
│   ├── Equations 1–11
│   ├── two unnumbered calculation examples
│   ├── Tables 1–3
│   └── Data S2 R/C text
├── 実測データ
│   ├── filters / min-max
│   ├── observed PointMark chart
│   └── 191-row paged table
├── 皮膚透過
│   ├── paper-derived conceptual process
│   ├── selected observation 11 fields
│   └── unconnected observed chart
├── 結果・比較
│   ├── Table 4
│   ├── model ranking
│   └── results / limitations
├── 原著図
│   └── Figures 1–8 / S1–S2
├── 全文
│   ├── Japanese self-contained HTML
│   └── bundled original PDF
└── 研究情報
    ├── metadata / end matter
    ├── hashes
    ├── reproducibility gaps
    └── source discrepancies
```

## 3. Window architecture

main windowは `NavigationSplitView` の2領域で構成する。

- Sidebar: 8つのdestinationと、PMID・offline状態を表示する。
- Detail: destinationごとのscrollable contentまたは全文WebViewを表示する。

3つ目のinspector、横断search、独自shortcut layerは設けない。macOS標準controlとsidebar navigationを用い、window resize時はdetailの読取幅を優先する。

## 4. Screen design

### 4.1 研究概要

title、citation、DOI、PMID、dataset composition、主要結果を上段に置く。続けて研究課題、目的、主要結果、4段階の比較flowを表示する。Table 4の値は報告値であり、固定行割当や学習済みmodelが未公開であるため再計算しないと明示する。

### 4.2 方法・数式

原著のmethodを同じvisual templateのtopic cardで並べる。Fickの5仮定、番号付き式 (1)–(11)、式 (11) 後の番号なし計算例2件、Tables 1–3を同一の長いreaderへ配置する。

Data S2は原DOCXから抽出したR/C textを単一のread-only scroll areaで示す。検索、実行、構文補完は行わない。`train set.csv` / `test set.csv` と学習済みartifactがないこと、C codeに掲載上の欠落があることを直前のnoteで示す。

### 4.3 実測データ

上から次の順に配置する。

1. drug / skin / MN / outcome filters
2. filter後の件数
3. min / max cards
4. time対outcomeの実測散布図
5. 108.3982246%とsource unitのnote
6. 全観測のpaged table

chartは `PointMark` だけを用いる。tableは1ページ20件とし、UI accessibility treeが過大にならないようにしながら、全191件へ前後buttonで到達できるようにする。表示精度は小数最大10桁とする。

### 4.4 皮膚透過

この画面は実測値と概念図を同じものとして扱わない。

- provenance banner: Data S1に空間座標、深さ、粒子ID、series IDがないことを示す。
- filters: drug / skin / MN / outcomeと全解除。
- process card: hydrogelとplasticの原著工程を切り替える。
- observation detail: 選択行の11 fieldsとsource unitを表示する。
- scatter: 同じrepositoryのData S1 observed pointsだけを表示し、前後観測を選択できる。
- boundary card: Data S1 observation、Figure 4 Fick model、非定量概念図を分離する。

概念図は donor / patch、角質層、皮膚膜、Franz receptor液だけをlabelする。hydrogelは留置、plasticは前処置後の抜去を別工程として描く。固定数glyphは方向説明だけに使い、数、速度、位置、深さをData S1値へmapしない。初期状態はpausedとする。

### 4.5 結果・比較

amount / percentage pickerによりTable 4のRMSE / R² chartを切り替える。全16値は常時tableでも読めるようにする。順位、Fick result、Figures 6–7比較、Figure 8重要度、XGBoost の新規薬物予測の限界をsource badge付きで表示する。

### 4.6 原著図

上部のpillsから10図を選択し、main imageをaspect-fitで表示する。下部にcaption要約とreading guide、全図の索引を置く。zoom/panは独自実装しない。詳細なoriginal captionは全文HTML側で提供する。

### 4.7 全文

自己完結HTMLを AppKit の `NSAttributedString` としてin-processで読み込み、読取専用 `NSTextView` に表示する。HTML内のdata URI図もimportし、link属性を除去して外部navigationを持たせない。これによりnetwork entitlementなしのSandboxを維持する。toolbarからbundle内の原著PDFを開ける。

### 4.8 研究情報

citation、authors、affiliations、correspondence、funding、acknowledgments、COI、data availability、ethics、ORCID、contributionsを表示する。source filesは実行時SHA-256を計算し、baselineとの一致・不一致をtextとiconで示す。続けて公開済み/未公開artifactと、source間の不一致を表示する。

## 5. Application architecture

```text
Bundled immutable resources
  ├── yuan2023-training-data.csv
  ├── yuan2023-paper-ja.html
  ├── original PDF / Data S1 / Data S2 / SI3
  ├── Data S2 extracted text
  └── Figures 1–8 / S1–S2
                    │
                    ▼
             StudyRepository
          ┌─────────┴─────────┐
          ▼                   ▼
   typed paper catalog   Data S1 records
          └─────────┬─────────┘
                    ▼
              eight SwiftUI views
```

`StudyRepository` はCSVを厳格にparseし、error時は空のsynthetic datasetへfallbackしない。`PaperContent` は式、table値、topic、figure metadata、end matterをtyped catalogとして保持する。network service、training service、prediction serviceは存在しない。

## 6. Data and provenance model

```text
PermeationRecord
- id
- drug
- loadingMicrograms
- molecularWeightDalton
- needleLengthMillimeters
- skin
- needle
- surfaceAreaSquareMillimeters
- timeHours
- percentage
- amountMicrogramsPerSquareCentimeter
- reference

EvidenceLocator
- paper location
- source-specific note

PaperFigure / EquationItem / ReportedMetric / SupplementaryResource
- source value or resource name
- label and evidence locator
```

source valueはUI stateと分離し、filter、page、selection、animation stepがrecordを書き換えないようにする。amount / percentageのderived predictionは持たない。

## 7. Scientific fidelity rules

- 原著本文の表現とData S1集計は別labelで示す。
- Data S1 `µg/cm²` と paper/table `µg` をsourceごとに保持する。
- BSA MW 66,000 / 66,430、plastic / solid、式 (4) / SI2 intercept差を解消せず注記する。
- Table 4はreported metricとしてimmutableに保持する。
- `set.seed(0)` からsplitを復元したと主張しない。
- Figure S1–S2は原著の singular な薬物除外説明を越えて一般化しない。
- full paper翻訳で原著の誤記・不一致を黙って訂正しない。

## 8. Visual and accessibility system

neutral background上にblue/teal系accentを用い、limitationはamber、integrity failureはredとtext labelで示す。色だけに依存せず、SF Symbols、badge、title、captionを併用する。

主要screen、navigation、chart、table、buttonsには安定したaccessibility identifierを付ける。figureにはcaption由来label、chartには軸・件数・選択値をまとめたaccessibility labelを付ける。Reduce Motionでは概念図の位置変化を止める。

## 9. Failure states

| Failure | UI behaviour |
| --- | --- |
| CSV missing / parse error | 原因を表示し、datasetを完全と表現しない |
| record count != 191 | 研究情報画面で警告する |
| figure missing | resource名付きplaceholderを表示する |
| code text missing | 読込errorを表示し、代替codeを生成しない |
| paper HTML missing | readerにresource名付きerrorを表示する |
| source hash mismatch | 一致/不一致labelをredで表示する |

## 10. Verification design

`scripts/quality-check.sh` はresource existence、5 source hashes、CSV 192 lines、plist、sandbox、network entitlement、tracking、network/predictor/secret source patternsを検査する。その後、repository外の一時DerivedDataで build-for-testing、8 unit tests、static analyzeを実行する。

UI testsは8画面と皮膚透過の主要controlをコンパイルする。Xcode UI runnerが利用できる場合だけ環境変数で実行し、通常の品質checkでは手動visual QAの記録を要求する。Release bundleは `scripts/build-app.sh` で作成し、PrivacyInfoを確認してad-hoc signingを検証する。

## 11. Accepted limitations

- exact Table 4 reproductionは、split assignmentとtrained artifactsがないため行わない。
- original modelを名乗るlive predictorを提供しない。
- atlasはaspect-fit閲覧であり、独自zoom/pan/searchを持たない。
- Data S2は単一read-only text viewであり、実行環境や構文修復を提供しない。
- references 1–51は原著bibliographyとして収録し、各参照論文の内容を追加しない。
- source discrepancyは解消せず、原著と補足資料の記載をlabel付きで提示する。
