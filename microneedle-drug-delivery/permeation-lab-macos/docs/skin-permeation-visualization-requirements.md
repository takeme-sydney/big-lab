[HTML版を開く](skin-permeation-visualization-requirements.html)

# 皮膚透過データビジュアライゼーション要件定義

文書版: 1.0
作成・更新日: 2026-08-27
対象: Yuan et al. (2023), PMID 38023708 / Data S1

## 1. 目的

既存の「実測データ」とは別のmacOS sidebar destination「皮膚透過」を設け、Data S1の191行と、原著が説明するhydrogel / plasticマイクロニードル処理、摘出皮膚膜、Franz receptor液への累積到達を一画面で照合できるようにする。

この機能は「191個の粒子が皮膚内を移動した軌跡」を再現しない。Data S1に空間座標、深さ、粒子ID、series ID、replicate IDがないため、191行は累積amount / percentageの**時点観測**として扱う。

## 2. 要件確定時のsource boundary

科学的主張は原著、Data S1、Data S2、SI3、およびData S1から機械的に検証できる集計だけを根拠とする。Webで調べたApple、W3C、Health Canada等は表示設計・アクセシビリティ判断にだけ用い、論文の実験事実を補完しない。

皮膚断面はアプリ内で描くoriginal vectorとし、科学ラベルは原著で確認できるdonor / patch、角質層、皮膚膜、Franz receptor液に限定する。一般解剖の外部画像や、原著にない皮膚厚・到達深度・濃度を取り込まない。

## 3. Data S1 truth contract

- 191行、11 source fieldsを原値のまま扱う。
- drug件数はlidocaine 73、BSA 33、GHK peptide 24、copper ions 24、Rhodamine B 19、caffeine 18。
- MN type件数はhydrogel 131、plastic 60。skin件数はrat 137、human 54。
- permeation time範囲は0.083333333–48 h、MN length範囲は0.7–1.25 mm。
- percentage最大値 `108.3982246%` を100%へclamp、丸め、除外しない。
- Data S1 amount列はheaderどおり `µg/cm²` と表示する。本文・Table 4・Figure 6の `µg` と無言で統一しない。
- 全191行でamountが数値上 `loading × percentage / 100` と一致することは注記してよいが、補足表だけから導出方向や独立測定性を断定しない。
- 同一条件・同一時点の複数観測を含み、行間のseries関係がないため、raw pointsを線で結ばない。
- `MN length` は針の幾何学値であり、実挿入深度や特定の皮膚層への到達を意味しない。

## 4. 機能要件

### SPV-FR-01 独立destination

「実測データ」とpeerになるsidebar item「皮膚透過」を追加する。既存データ画面内のsubtabだけで済ませない。

### SPV-FR-02 観測フィルタ

drug、skin、MN type、outcome（percentage / amount）で絞り込み、全解除、filter後件数を提供する。filterはraw recordを書き換えず、選択順は決定的であること。

### SPV-FR-03 非連結散布図

Swift Chartsの `PointMark` だけでtime対outcomeを表示する。`LineMark`、補間、回帰、平均曲線、外挿を禁止する。drugは固定colorに加えて固定symbolでも区別し、filter後もencodingを変えない。

### SPV-FR-04 選択観測

前後buttonとpickerで任意のfilter済み観測へ移動し、11 source fields、Data S1転記行番号、原値、source unitを表示する。概念図の直下にも選択行番号、time、receptor到達値をtextとして照合表示し、glyphの数・位置・速度・深さには反映しないと明記する。

### SPV-FR-05 hydrogel工程

薬物を含浸したhydrogel MNを皮膚膜へ挿入したままにし、膨潤・放出、皮膚膜内の移行、receptor液中濃度からの累積値算出を番号付き工程で示す。

### SPV-FR-06 plastic工程

plastic MNによる前処置、patch除去、残存するmicron-sized passage、donor側薬物溶液の添加、receptor側測定をhydrogelと別工程で示す。工程1では針を挿入状態、工程2以降では針を除去した微小孔として描く。

### SPV-FR-07 Franz cellの境界

表示値はin vitro Franz receptor液への累積到達結果であり、皮膚内濃度、体内吸収、血流、治療効果ではないと常時説明する。

### SPV-FR-08 概念motion

初期状態はpausedとし、Play / Pause / Step / Resetを提供する。固定数glyphと矢印は工程と方向だけを示し、粒子数・速度・深さ・濃度をencodeしない。`accessibilityReduceMotion` が有効なら反復移動を止め、静止工程へ置換する。

### SPV-FR-09 evidence境界

同じ画面で次の3層を明確に分ける。

1. Data S1: 191行の累積時点観測
2. 原著Figure 4: Fick数値modelの15 min、1、3、6、24 h濃度map
3. アプリの概念図: 非定量・縮尺外の工程説明

Figure 4を選択中Data S1行のsimulationと表現せず、新しい濃度mapや中間frameを生成しない。

### SPV-FR-10 source failure

Data S1の読込に失敗した場合は明示的なerror stateを表示する。空データを191件と表現せず、demo / synthetic fallbackを使わない。

## 5. macOS・アクセシビリティ要件

- native SwiftUI / Charts、macOS 14+、offline、deterministic。
- `NavigationSplitView` の既存8画面構成へ統合する。
- filter群はadaptive layoutとし、window幅に応じて折り返す。
- sidebar、filters、mechanism、motion controls、selection controlsに安定したaccessibility identifierを付ける。
- chart summaryには件数、軸、選択行、正確な値を含める。
- 概念図のVoiceOver labelにはmechanism、現在工程、非定量・縮尺外であることを含める。
- colorだけに依存せず、symbol、線種、label、番号付き工程を併用する。
- OSのReduce Motionを尊重する。

## 6. 受入条件

- [x] 「実測データ」と「皮膚透過」が別destinationとして存在する。
- [x] 191 raw pointsを表示対象とし、raw point間に接続線がない。
- [x] `108.3982246%`を原値で保持し、選択・読上げできる。
- [x] hydrogel留置とplastic前処置・抜去後を別工程として描く。
- [x] Franz receptor到達をin vitro測定として表現する。
- [x] 選択観測の11 fieldsとsource-specific unitを表示する。
- [x] 実測、Fick model、概念図の境界を表示する。
- [x] amountとpercentageの数値関係と断定できない導出方向を注記する。
- [x] source failure時にsynthetic fallbackを返さない。
- [x] unit tests 8件、build-for-testing、static analyzeが成功する。
- [x] UI test targetがcompileする。
- [x] 実macOS appでhydrogel / plastic、step、play、191 / 60件filter、108.3982246%を目視確認する。
- [ ] Xcode UI test runner完走。ローカルtest managerがworker materialization待ちで停止するため未達で、手動GUI検証で代替した範囲を監査報告に記録する。
- [x] Markdown / HTML同期とrepository-wide link validation。
