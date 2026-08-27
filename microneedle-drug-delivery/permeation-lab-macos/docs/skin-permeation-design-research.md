[HTML版を開く](skin-permeation-design-research.html)

# 医療系データビジュアライゼーションと皮膚透過図のデザイン調査

調査日: 2026-08-27
適用範囲: Permeation Lab「皮膚透過」destinationの情報設計・視覚表現・アクセシビリティ

## 1. 調査方法

原著とData S1を科学的truth sourceとし、Web調査は「どう見せるか」の判断に限定した。外部の皮膚解剖資料は一般的な読解補助として監査したが、原著にない層厚、到達深度、濃度、臨床効果をアプリへ追加していない。

## 2. Evidence ledger

| Source | 確認した設計原則 | 実装判断 |
| --- | --- | --- |
| [Yuan et al. PubMed](https://pubmed.ncbi.nlm.nih.gov/38023708/) / [PMC全文](https://pmc.ncbi.nlm.nih.gov/articles/PMC10658566/) | Data S1は累積amount / percentage、Franz cellはreceptor液を複数時点で測定。hydrogelとplasticの工程が異なる。Figure 4はFick model | 実測点、原著model、概念工程を混同しない |
| [Apple HIG: Charts](https://developer.apple.com/design/human-interface-guidelines/charts) | mark、axis、unit、legend、annotationで意味を明示し、chart以外の文脈も与える | `PointMark`、軸・単位、直接annotation、全11列detail |
| [Apple HIG: Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility) | 色以外の手掛かり、明快なlabel、Reduce Motion等のsystem settingへの応答 | 固定symbol、工程番号、VoiceOver label、paused-first motion |
| [W3C: Use of Color](https://www.w3.org/WAI/WCAG22/Understanding/use-of-color) | 色を情報伝達の唯一の手段にしない | drugをcolorとsymbolの二重encodingで示す |
| [W3C: Contrast Minimum](https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum) / [Non-text Contrast](https://www.w3.org/WAI/WCAG22/Understanding/non-text-contrast) | 通常text 4.5:1、大textと重要なnon-text 3:1を基準にする | system colorsを中心にし、label・outline・状態textを併用 |
| [W3C: Animation from Interactions](https://www.w3.org/WAI/WCAG22/Understanding/animation-from-interactions) | interaction起点の不要なmotionを無効化できるようにする | 初期paused、明示的Play、Reduce Motion時は静止 |
| [Health Infobase: Visualization types](https://health-infobase.canada.ca/design-manual/dataviz/dataviz/types.html) | taskに合うchartを選び、説明と探索を分ける | 工程説明とraw observation探索を同一画面内の別cardにする |
| [Health Infobase: Design](https://health-infobase.canada.ca/design-manual/dataviz/dataviz/design.html) | 色数を抑え、direct label、読みやすい軸、軽いgridを使う | restrained palette、選択点の直接label、水平grid |
| [Health Infobase: Accessibility](https://health-infobase.canada.ca/design-manual/dataviz/dataviz/accessibility.html) | visualizationに文章summaryとdata accessを併設する | chartのAX summary、選択観測の全11列、科学的境界note |
| [NCBI Bookshelf / WHO: normal skin](https://www.ncbi.nlm.nih.gov/books/NBK144027/) | 角質層が経皮移行のbarrierである一般文脈 | 外部画像は複製せず、原著allowlist内の「角質層／皮膚膜」だけをoriginal vectorで描く |
| [Crameri et al., The misuse of colour in science communication](https://www.nature.com/articles/s41467-020-19160-7) | rainbow色など知覚的に不均一なcolor mapはデータ解釈を歪め得る | Data S1に空間濃度がないためheatmapを作らず、categorical paletteを固定する |

## 3. 採用した画面構造

```text
皮膚透過
├── provenance banner: 191行は累積時点観測
├── adaptive filters: drug / skin / MN / outcome / reset
├── conceptual Franz-cell illustration
│   ├── mechanism: hydrogel / plastic
│   ├── donor / patch → 角質層 → 皮膚膜 → receptor液
│   ├── selected rowのtime / receptor到達値をtext照合
│   └── Play / Pause / Step / Reset + numbered steps
├── selected observation: 11 source fields
├── unconnected raw scatter: PointMark only
└── observation / Fick model / concept boundary note
```

## 4. Visual encoding

### 実測点

- x軸はpermeation time、y軸はpercentageまたはamount。
- raw Data S1 observationはpointだけで表し、線を用いない。
- 6 drugは固定colorと固定shapeを併用する。
- 選択点は大きさ、orange outline、直接annotationで示す。
- 108.3982246%を含むため、percentageを100%上限のgaugeへ変換しない。

### 皮膚・Franz cell図

- donor / patchを上、角質層と皮膚膜を中央、receptor液を下に置き、in vitro装置である方向を明瞭にする。
- hydrogelは針を留置し、膨潤・放出を示す。
- plasticは工程1だけ針を挿入し、工程2以降はpatchを外して点線のpassageを示す。
- glyphは固定数とし、観測値へmapしない。
- `概念図・非定量・縮尺外` を常時表示する。

### Provenance

- `Data S1` は観測。
- `原著Fick model` はFigure 4の数値model。
- `概念図` はアプリが描く説明用vector。
- source種類をcolorだけで区別せず、常時textで明示する。

## 5. 却下した案

- 191個の粒子を皮膚内へ飛ばす: 191行は粒子IDを持たない。
- time順に全点を接続する: series / replicate関係が未提供。
- percentageに応じてglyph数、速度、到達深度を変える: 空間・速度・深度データがない。
- Data S1から皮膚内heatmapを補間する: Figure 4とは異なる未観測値を発明する。
- Figure 4の5 frameをmorphする: 原著にない中間濃度場を作る。
- percentageを100%上限のprogress ringにする: 108.3982246%を誤表示する。
- Data S1 `µg/cm²` とpaper `µg`を同一axisに無言で載せる: source unitが異なる。
- plastic針を全透過工程で留置する: 原著の前処置・除去工程と矛盾する。
- 血管や全身循環を描く: 本データはFranz receptor液のin vitro測定。
- 外部の皮膚解剖図をbundleする: source boundaryと権利確認を超える。

## 6. 実装への影響

この調査により、皮膚断面を派手な濃度heatmapではなくoriginal vectorの工程図とし、定量値は非連結散布図とtextへ分離した。アニメーションはデータencodingではなく、hydrogel / plasticの工程順を理解する補助に限定した。
