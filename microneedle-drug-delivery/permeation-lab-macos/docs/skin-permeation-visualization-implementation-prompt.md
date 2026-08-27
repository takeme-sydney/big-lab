[HTML版を開く](skin-permeation-visualization-implementation-prompt.html)

# 皮膚透過データビジュアライゼーション実装指示文

以下は、この機能の要件定義後に確定し、実装・監査で実際に使用したcanonical instructionである。

## Prompt

```text
あなたはscientific integrity、native macOS interaction、accessibilityを担当する
senior SwiftUI engineerです。

最初にrepository rootのAGENTS.mdと、permeation-lab-macosのREADME、
requirements、design、paper-content-matrix、audit-report、
skin-permeation-visualization-requirements、skin-permeation-design-researchを読み、
source boundaryと現行app構造を監査してください。

目的:
既存の「実測データ」と別のsidebar destination「皮膚透過」を追加し、
Data S1の191累積時点観測と、原著が説明するhydrogel / plastic MN、
摘出皮膚膜、Franz receptor液への到達工程を一画面で照合可能にする。

絶対制約:
- 191行を191個の粒子、位置、皮膚内軌跡、連続seriesとして扱わない。
- raw Data S1 pointを線で結ばない。
- 未公開のseries / replicate関係を推測しない。
- glyph数、速度、深さ、opacity、位置をData S1値へmapしない。
- 新しいFick濃度map、中間frame、予測curveを生成しない。
- 108.3982246%をclamp、除外、100へ丸めない。
- Data S1 µg/cm²とpaper/tableのµgを統一しない。
- MN lengthを挿入深度としてscale描画しない。
- in vitro Franz receptorを人体血流や臨床送達として描かない。
- missing resourceをdemo / synthetic dataで埋めない。

Navigation:
AppSectionへskinPermeation caseを追加し、「実測データ」とpeerになる
8番目のsidebar destinationとして統合する。accessibility identifierと
UI test destinationも追加する。

Observed data:
- StudyRepositoryの191 PermeationRecordを使う。
- drug、skin、MN、outcomeのfilterとresetを設ける。
- Swift ChartsではPointMarkだけを使う。
- 6 drugのcolor / symbol domainを固定する。
- filter後件数を表示する。
- 前後buttonとpickerで観測を選択し、11 source fieldsを原値で表示する。
- chart modelにunconnectedPoints topologyを持たせ、viewもそのmodelを使う。
- source load error時は明示的なerror stateへ分岐する。

Conceptual illustration:
- SwiftUI Shape / Canvasでoriginal vectorを描く。
- labelはdonor / patch、角質層、皮膚膜、Franz receptor液に限定する。
- 常時「概念図・非定量・縮尺外」を表示する。
- 選択行番号、time、receptor到達値をtextとして図の直下に表示し、
  glyphの数・位置・速度・深さへ反映しないと明記する。

Hydrogel:
1. 薬物を含浸したMNを皮膚膜へ挿入したままにする。
2. MNが膨潤し、有限reservoirから隣接皮膚組織へ放出する。
3. 皮膚膜内をreceptor側へ移行する。
4. receptor液中濃度から累積値を算出する。

Plastic:
1. solid plastic MNで皮膚膜を前処置し、この段階だけ針を挿入して描く。
2. patchを除去し、micron-sized passageだけを残す。
3. donor側薬物水溶液を添加し、passageを満たす。
4. receptor液中濃度から累積値を算出する。

Motion:
- 初期状態はpaused。
- Play / Pause / Step / Resetを実装する。
- animation phaseへData S1数値を渡さない。
- accessibilityReduceMotionがtrueなら反復移動を止める。
- view非表示時はtimerを停止する。

Science boundary copy:
- Data S1はreceptorへ到達した累積時点観測で、皮膚内位置測定ではない。
- Figure 4の15 min、1、3、6、24 hはFick modelの濃度mapである。
- 概念図は方向と工程だけを示す。
- amount = loading × percentage / 100が全191行で数値的に一致しても、
  導出方向は断定しない。
- MN lengthは幾何学値で、実挿入深度ではない。

Accessibility / layout:
- colorに加えてshape、line pattern、icon、textを使う。
- chart、concept、controls、selectionに安定したidentifierを付ける。
- chart summaryに件数、軸、選択行、原値を含める。
- filter barはadaptive layoutにし、window幅に応じて折り返す。
- OSのReduce Motionを尊重する。

最低限のunit tests:
- 191 rows、6 drugs、drug / skin / MN counts。
- numeric rangesと108.3982246%。
- 全rowのamount数値関係。
- Table 4全16値、equations / examples / figures inventory。
- observed topologyがunconnectedPointsである。
- hydrogel / plastic copyと工程が異なる。
- filter後selection orderがdeterministicである。

最低限のUI target coverage:
- 8 destinationsが別々に存在する。
- 皮膚透過のboundary、illustration、observation detail、motion controlsが存在する。
- UI runnerを完走できない環境ではcompile成功とmanual QAを分けて記録し、
  automated PASSと表現しない。

品質loop:
1. source files、hash、191 rows、privacy、sandbox、network absenceを検査する。
2. repository外DerivedDataでbuild-for-testingする。
3. unit tests 8件を実行する。
4. static analyzeを実行する。
5. 実appを起動し、hydrogel / plastic、Play / Pause / Step / Reset、
   filter件数、selected row、108.3982246%、非連結plotを目視する。
6. Release appをbuildし、PrivacyInfoとad-hoc signingを検証する。
7. audit-reportへ実測結果と未完走項目を記録する。
8. repository rootからshared/scripts/build-website.shを実行する。

Repository safety:
- 既存のpermeation-lab-macos 1 appへ統合し、別appを増やさない。
- dirty worktreeと他projectの変更を保持する。
- app directoryだけをfocused commitにする。
- 未監査branchやopen PRを一括mergeしない。
- Markdownを正本とし、対応HTMLを同一taskで生成する。
```

## 実施記録

- 要件定義とデザイン調査を先に確定した。
- branch / PR、既存macOS候補、論文・Data S1を別agentで並行監査した。
- 上記promptに従って既存 `permeation-lab-macos` へ実装し、第二agent reviewの指摘を修正した。
- 自動品質check、実macOS app操作、文書生成、focused Git integrationの順で検証した。
