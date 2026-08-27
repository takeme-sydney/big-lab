[HTML版を開く](audit-report.html)

# Permeation Lab 品質・科学的完全性監査

監査日: 2026-08-27（Australia/Sydney）
監査対象: source inventory / native macOS app / 皮膚透過visualization / documentation
現在の判定: **PASS FOR DELIVERY — automated UI runnerのみ環境制約で未完走**

## 1. Executive verdict

Yuan et al. (2023) の原著、Data S1、Data S2、SI3を収録する1つのnative macOS appを完成させ、既存7画面へ独立した「皮膚透過」を追加した。Data S1の191行を粒子軌跡へ変換せず、非連結散布図、選択観測11列、hydrogel / plastic別のFranz-cell概念工程として表示する。

source hash、191-row integrity、privacy / sandbox / network absence、build、8 unit tests、static analyze、Release bundle、ad-hoc signing、実macOS GUIは合格した。UI test targetはcompileしたが、`xcodebuild test-without-building` はこのローカルXcode test managerでworker materialization待ちのまま終了しないため、自動UI testをPASSとは記録しない。皮膚透過機能は実appをComputer Useで操作し、該当範囲を手動検証した。

## 2. Audited sources

| Source | Status | Evidence |
| --- | --- | --- |
| Original PDF | verified / bundled | 15-page article、3,800,340 bytes |
| Data S1 XLSX | verified / bundled | single worksheet、header row 4、191×11、no formulas |
| Data S1 CSV | verified / bundled | 191 data rows、11 columns、source-derived copy |
| Data S2 DOCX / extracted text | verified / bundled | R code + C code |
| SI3 DOCX | verified / bundled | Figure S1 / S2 |
| Figure 1–8 / S1–S2 | verified / bundled | 10 figure assets |

Code SI2のvisual DOCX renderingはLibreOffice不在のため行わず、plain-text extractionと原DOCX hashで監査した。アプリは抽出textと原sourceを両方収録する。

## 3. Integrity baseline

| Source | SHA-256 | Result |
| --- | --- | --- |
| PDF | `4641e97362f3cc545586879f2da3735e5487a50fe3cc6149076c87151e47c820` | verified |
| Data S1 XLSX | `a22cc32b4d461b1e65c2b29623186a0d0c1f984fc1935d8bd3b35ec0bc3c3a24` | verified |
| Data S2 DOCX | `9d6fe3da0127ba26469b7a1fe61a98f723a5547d8a666c92670bf30f31820c81` | verified |
| SI3 DOCX | `49f953203a33dd6c781e2761011c8124a6bac891e07ceedf61de6c1289626031` | verified |
| Data S1 CSV | `03ff02276f333d06747efb7a625e9de1b4055b94b8736873f5e7cc389315b0f5` | verified |

## 4. Scientific integrity findings

### 4.1 191の意味

191はData S1の観測行数であり、191個の分子、粒子、穿刺点、連続軌跡ではない。Data S1には空間座標、皮膚内深さ、粒子ID、series / replicate IDがないため、アプリはraw `PointMark`だけを表示し、点間を接続しない。

Data S1集計はlidocaine 73、BSA 33、GHK peptide 24、copper ions 24、Rhodamine B 19、caffeine 18、hydrogel 131 / plastic 60、rat 137 / human 54である。

### 4.2 実験装置と機序

表示値は摘出皮膚膜を介してFranz receptor液へ到達した累積amount / percentageであり、皮膚内濃度や全身吸収ではない。hydrogel MNは留置して膨潤・放出する工程、plastic MNは前処置後にpatchを除去して残ったmicron-sized passageへdonor溶液を加える工程として分けた。

### 4.3 値と単位

- `108.3982246%` を原値で保持し、100%へclampしない。
- Data S1 amount headerの `µg/cm²` とpaper table / figureの `µg` をsource別に保持する。
- 全191行でamountは数値上 `loading × percentage / 100` と一致するが、生成方向や独立測定性は断定しない。
- MN lengthは幾何学値であり、実挿入深度として描かない。

### 4.4 観測・model・概念図

Figure 4の15 min、1、3、6、24 h concentration mapはFick数値modelであり、Data S1の空間測定ではない。アプリは選択行のsimulationや新しい中間frameを生成しない。original vectorの概念図は工程と方向だけを示し、固定glyphを数・速度・深さ・濃度へ対応させない。

## 5. Reproducibility audit

### Verified as present

- 191-row Data S1
- paper記載の7:3 random split
- Table 3 hyperparameters
- Table 4 reported metrics
- Data S2のMLR / RF / XGBoost R code
- Data S2のFick C code
- R code中の `set.seed(0)`

### Not provided

- `train set.csv` / `test set.csv`
- 191行のtrain/test assignmentとsplit生成code
- final MLR coefficients
- trained RF forest / XGBoost booster
- Table 4に用いた全prediction output
- amount向けTable 3設定を実行する独立R path

`set.seed(0)` は既成CSVを読むcodeにあり、分割生成code自体は公開されていない。従ってexact Table 4 reproductionはclaimせず、surrogate predictorも実装していない。

## 6. Software verification

実行日はいずれも2026-08-27、repository外DerivedDataを使用した。

| Check | Result | Evidence |
| --- | --- | --- |
| project / shared scheme | PASS | app、unit test、UI test targetを列挙 |
| resources / bytes / 5 SHA-256 | PASS | `scripts/quality-check.sh` |
| CSV | PASS | 192 lines = header + 191 rows |
| entitlements / privacy | PASS | App Sandbox、network entitlementなし、tracking false |
| prohibited source patterns | PASS | network / predictor / secret patternなし |
| raw chart guard | PASS | `SkinPermeationView.swift` に `LineMark` なし |
| build-for-testing | PASS | app、8 unit tests、UI test targetをcompile |
| unit tests | PASS | 8 executed、0 failures、direct `xcrun xctest` |
| static analyze | PASS | `xcodebuild analyze` exit 0 |
| Release build | PASS | arm64 + x86_64 universal app |
| PrivacyInfo in bundle | PASS | Release bundleで存在確認 |
| ad-hoc signing | PASS | `codesign --verify --deep --strict` |

Release artifact:

```text
microneedle-drug-delivery/permeation-lab-macos/dist/PermeationLab.app
```

`dist/` は生成物のため `.gitignore` 対象である。再生成は `./scripts/build-app.sh` を使う。

### Xcode UI runner limitation

signed / unsignedの双方で `xcodebuild test-without-building` を試したが、この環境ではtest managerが `waiting for workers to materialize` 相当の状態で停止した。test failureではないが完走していないため、automated UI testsは未合格とする。UI test sourceはSwift 6 warningなしでcompileしている。

## 7. 実macOS app manual verification

最終Debug appを起動し、accessibility treeとscreenshotで次を確認した。

- sidebarに8つのdestinationがあり、「実測データ」と「皮膚透過」が別項目。
- 初期hydrogel表示は191 / 191点、Data S1転記行 #1、1 h、17.6958866%。
- Plastic filterは60 / 191点へ変わり、転記行 #132、1 h、0.8453793%を表示。
- Plastic工程1はsolid needlesを挿入状態で表示し、工程2はpatchを除去して点線passageだけを表示。
- Stepで現在工程が1から2へ変化。
- PlayでPause表示へ変化し、停止できる。
- BSA転記行 #31、48 h、`108.3982246%` をchart、detail、accessibility labelで確認。
- 選択観測の全11 fields、source unit、MN length≠insertion depth noteを確認。
- 観測値は図直下のtextで照合し、glyph mappingではないことを確認。

Reduce Motionのcode path、Data S1読込error state、adaptive filter layoutはsource / unit levelで監査した。OS設定を切り替えたGUI、dark mode、Full Keyboard Access、200%相当text scaleの全組合せは未実施である。

## 8. Branch / application audit

- canonical appは `microneedle-drug-delivery/permeation-lab-macos/` の1つに限定した。
- old SwiftPM版、synthetic `mn-next-ios`、interactive SLM web、P2BRD系appは統合対象から除外した。
- open PR #1–#5は個別にはmergeableでも研究文書がpairwise conflictするため、一括mergeしない。
- PRのない `microneedle-active-learning-paper-revision` と `p2brd-platform-macos` に、監査対象tipを越える固有commitはなかった。
- 本機能はfocused app commitだけをlocal `main`へcherry-pickする。

## 9. Documentation gate

Markdown 8点を正本とし、それぞれ先頭link先のHTMLを同じ内容で生成する。repository rootから次を実行し、全Markdown-to-HTML linkを検証する。

```sh
./shared/scripts/build-website.sh
```

結果: **PASS**。このアプリのREADMEとdocs 8点を含むsame-basename HTMLを生成し、repository-wide Markdown-to-HTML link validationが成功した。

## 10. Final disposition

- [x] native macOS target / shared scheme
- [x] 191×11 source data / 5 hashes
- [x] unit tests 8 / 8
- [x] build-for-testing / UI target compile
- [x] static analyze
- [x] Release universal app / PrivacyInfo / ad-hoc signing
- [x] no invented prediction / no network / no synthetic fallback
- [x] focused skin-permeation manual GUI verification
- [ ] automated UI runner完走（環境制約を上記に記録）
- [x] Markdown / HTML synchronization and link validation

自動UI runnerと未実施のaccessibility組合せを除き、依頼された皮膚透過visualizationと1つのmacOS appへの統合はdelivery可能な状態である。
