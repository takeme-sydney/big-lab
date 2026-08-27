[HTML版を開く](implementation-prompt.html)

# Permeation Lab 実装・監査用指示文

以下を、このアプリを再実装・修正・監査するときのcanonical promptとする。

## Prompt

```text
あなたはscientific integrityを最優先するsenior macOS / SwiftUI engineerです。
Yuan et al. (2023) “Prediction of drug permeation through microneedled skin
by machine learning”, PMID 38023708 の本文とSupporting Informationを
漏れなく照合できるnative macOS app「Permeation Lab」を実装してください。

最初にrepository rootのAGENTS.mdと、permeation-lab-macos内のREADME.md、
docs/requirements.md、docs/design.md、docs/paper-content-matrix.md、
docs/audit-report.mdを読み、Markdown/HTML規則とsource boundaryを固定してください。

科学的source allowlist:
1. shared/references/papers/yunong-yuan/microneedle/
   03-yuan-2023-machine-learning-microneedled-skin-permeation.pdf
2. microneedle-drug-delivery/drug-release-profile/references/supplementary/
   06-yuan-2023-data-s1.xlsx
3. 同 directory の 07-yuan-2023-code-si2.docx
4. 同 directory の 08-yuan-2023-new-drug-figures-si3.docx
5. Data S1から転記したrepository内CSV
6. 同じ原著のrepository内日本語翻訳と原著抽出画像

このallowlist以外から、医学、薬学、機械学習、皮膚解剖、臨床、製品、
ガイドライン、市場に関する説明・数値・推奨を追加してはいけません。
SwiftUI、Charts、AppKitのHTML読込、CSV parse、test、accessibilityは実装技術として使えますが、
新しいscientific claimの根拠にしないでください。

Product outcome:
- macOS 14+、Swift 6、native SwiftUI app bundle。
- sidebar + detailで8画面を提供する。
  1. 研究概要
  2. 方法・数式
  3. 実測データ
  4. 皮膚透過
  5. 結果・比較
  6. 原著図
  7. 全文
  8. 研究情報
- 原著front matter、abstract、sections 1–5、end matter、references 1–51を読む。
- Data S1の191行・11 fieldsをfilter、散布図、paged table、観測detailで確認する。
- Fick、MLR、RF、XGBoostを原著の記述だけで比較する。
- 番号付き式 (1)–(11) を表示する。
- 式 (11) 後の2つの数値代入は、原著どおり番号なし計算例として表示する。
- Tables 1–4の全値を表示する。
- Figures 1–8とFigures S1–S2の10画像をaspect-fitで表示する。
- Data S2のR/C codeを単一のread-only text viewで表示する。
- 5つの一次source hash、原著内の表記差、再現に不足するartifactを表示する。

Absolute truth constraints:
- 独自のpredict function、係数、threshold、tree、correction、curveを作らない。
- educational surrogateであっても論文にない数値予測を生成しない。
- Table 4を再学習・再計算した結果と表現しない。
- 7:3 random splitを未知薬物への性能保証と表現しない。
- Data S1 108.3982246%をclamp、丸め、除外しない。
- Data S1 µg/cm²とpaper/tableのµgを無言で統一しない。
- original proseとData S1 countの不一致を黙って修正しない。
- missing resourceをdemo / synthetic dataで埋めない。
- 診断、治療、投与、安全性、有効性、患者転帰の推奨をしない。

Source fidelity details:
- 原著本文のdrug構成表現はBSA 33%、GHK 24%、copper 24%、
  Rhodamine B / caffeineは各10%。
- Data S1実件数はlidocaine 73、BSA 33、GHK 24、copper 24、
  Rhodamine B 19、caffeine 18、total 191。両者を別labelで示す。
- BSA MWは本文/Data S1で66,000 Da、Table 2で66,430 Da。
- MN typeはMethods/Data S1でhydrogel/plastic、Table 2でhydrogel/solid。
- MLRの式 (4) はintercept bを含む一方、Data S2はResults ~ . - 1。
- Figure S1/S2は、本文4.2が XGBoost をさらに検証した “a drug purposely removed” の結果として扱う。
  各薬物に対して反復したと断定しない。
- Figure 6 discussionはRhodamine Bとcaffeineの各薬物が20点未満で、
  それぞれ全dataの約10%という意味を保持する。

Missing-artifact contract:
- paperは191点を7:3でrandom splitしたと述べる。
- Data S2にはset.seed(0)があり、その後に既成train set.csv / test set.csvを読む。
- ただしsplit generation codeとそのCSV自体、row assignmentは掲載されない。
- final MLR coefficients、RF forest、XGBoost boosterも掲載されない。
- Data S2のR pathはpercentage用のRF mtry=6、XGBoost depth=3、eta=0.2、
  nround=45を示す。Table 3はamount用の別設定も報告するが、対応する独立R pathはない。
- exact Table 4 reproductionをclaimせず、欠けたものは「未公開」と表示する。

Observed-data contract:
- CSV parserで191 observationsをtyped PermeationRecordへ読む。
- drug / skin / MN filterとamount / percentage pickerを提供する。
- min/max以外の新しい統計量を追加しない。
- chartはPointMarkだけを使い、line、mean、regression、interpolation、
  extrapolationを作らない。
- tableは全191 observationsへ到達できるよう20件ずつpageする。
- source numeric precisionを最大10小数桁まで保持する。
- 皮膚透過画面では選択観測の11 fieldsを表示する。

Conceptual-process contract:
- Data S1のrowsを粒子位置、空間軌跡、連続seriesとして扱わない。
- 概念図のlabelは原著にあるdonor/patch、角質層、皮膚膜、
  Franz receptor液だけに限定する。
- hydrogel留置とplastic抜去後の工程を区別する。
- 「概念図・非定量・縮尺外」を常時表示する。
- glyph数、速度、深さ、位置をData S1 valuesへmapしない。
- animationはpausedで開始し、Play/Pause/Step/Resetを提供する。
- Reduce Motion時はglyph位置の移動を停止する。
- Figure 4はFick modelの濃度mapであってData S1の空間測定ではない。
  新しい濃度mapや中間frameを生成しない。

Architecture and privacy:
- scientific resourcesはbundle内のimmutable filesとする。
- network、training、prediction serviceを作らない。
- 全文HTMLはAppKitのNSAttributedStringへin-processでimportし、読取専用NSTextViewへ表示する。link属性を除去し、JavaScript・外部navigation・network entitlementを持たせない。
- App SandboxとHardened Runtimeを有効にする。
- network entitlement、analytics、account、remote databaseを持たない。
- PrivacyInfo.xcprivacyはtracking falseとする。

Required tests:
- Data S1 191 rows、6 drugs、drug/skin/MN counts。
- full numeric rangesと108.3982246%。
- 全rowでamount = loading × percentage / 100。
- Table 4全16 values。
- equations 1–11、unnumbered examples 2件、figures 10点。
- raw-point topology、hydrogel/plastic process差、deterministic filter ordering。
- UI targetにlaunch、8 destinations、皮膚透過の境界・図・観測detail・controls。

Quality loop:
1. source assets、bytes、hashを確認する。
2. build-for-testingでapp、unit tests、UI testsをcompileする。
3. 8 unit testsを実行する。
4. static analyzeを実行する。
5. UI runnerが安定して利用できる場合だけautomated UI testsを実行する。
   実行不能なら理由を記録し、PASSとは書かない。
6. 実appを起動し、8画面、図、全文、data filters、units、hash、window resizeを目視する。
7. Release buildを作り、PrivacyInfo、ad-hoc signing、entitlementsを検証する。
8. audit-report.mdへ実測command/result/known limitationを記録する。
9. repository rootからshared/scripts/build-website.shを実行する。

Repository safety:
- app pathはmicroneedle-drug-delivery/permeation-lab-macos/。
- DerivedDataは/tmpへ出す。
- .build、DerivedData、xcuserdata、distをversion-control対象にしない。
- dirty worktreeと他projectの変更を保持する。
- Markdownを正本とし、最初の本文行に対応HTMLへのlinkを置く。

Definition of done:
- PermeationLab.xcodeprojとshared schemeが実在する。
- SDKROOT=macosx、MACOSX_DEPLOYMENT_TARGET=14.0。
- warning-free build、8 unit tests、analyze、Release build、signingが成功する。
- UI test targetがcompileし、manual UI QA結果が記録される。
- invented science、network path、secret、synthetic fallbackがない。
- 5 source hashesと191-row checkが成功する。
- content matrixの各項目へappまたはfull paperから到達できる。
- READMEとdocs 8点のMarkdown/HTMLが同期する。
```

## Review checklist

- [ ] allowlist外の科学情報がない。
- [ ] predictor、surrogate、独自係数、擬似curveがない。
- [ ] full paperとend matter、references 1–51を省略していない。
- [ ] Data S1 191×11と全source fieldsを確認した。
- [ ] 番号付き式 (1)–(11) と番号なし計算例2件を区別した。
- [ ] Tables 1–4、Figures 1–8 / S1–S2を確認した。
- [ ] Data S2 codeとmissing artifactsを明記した。
- [ ] source discrepanciesをlabel付きで保持した。
- [ ] native macOS target、unit/UI test targets、shared schemeが実在する。
- [ ] quality check、Release build、manual UI QAを実測した。
- [ ] Markdown/HTML buildとlink validationが成功した。
