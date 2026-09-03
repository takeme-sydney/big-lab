---
title: Permeation Lab macOS E2E・スクリーンショット解説
document_type: e2e-test-report
canonical_format: markdown
checked_at: 2026-09-03 20:12 AEST
status: complete-with-gui-runner-limitation
---

# Permeation Lab macOS E2E・スクリーンショット解説

## 結論

- 現在のReleaseアプリは、**191行の読込 → Drugを保持した5-fold内部CV → 3候補比較 → 191行で最終学習 → JSON artifact厳格再読込 → 191行予測**を終了コード`0`で完走した。
- ローカルMLのworkflow・artifact validationは**20/20 tests PASS**、配布bundleの署名・同梱CSV、Fick再現bundle v6のmanifestと主要数値もPASSした。
- 実画面は起動、Fick evidenceの自動audit、内部CV、最終fit、予測結果まで確認し、6枚を保存した。
- ただし、これは**software E2Eの成功**である。プレゼンの中心結論どおり、未知薬物・独立runに対する外部性能、Fick固有の優位性、外部`R² ≥ 0.85`は確認していない。
- このMacではAutomation Modeが無効で、XCUITest runnerによるクリック完走は実行していない。したがって「XCUITest PASS」とは記録しない。

## 判定の根拠にした実際のプレゼン資料

科学的な説明は次の12-slide資料を基準にした。

- canonical slide content：[[Prediction of drug permeation through microneedled skin by machine learning/student-meeting-2026-09/presentation-content.md]]
- 日本語talk notes：[[Prediction of drug permeation through microneedled skin by machine learning/student-meeting-2026-09/presentation-talk-ja.md]]
- final PDF：[[Prediction of drug permeation through microneedled skin by machine learning/student-meeting-2026-09/Microneedled-Skin-Permeation-Reproducibility-and-External-Validation.pdf]]
- 指定されたHTML hub：[[Prediction of drug permeation through microneedled skin by machine learning/student-meeting-2026-09/Microneedled-Skin-Permeation-Reproducibility-and-External-Validation.html]]

指定HTMLは12 slidesそのものではなく、`Takumi research`、`Yuan paper`、`macOS app`、計算過程へ分岐するhubである。`macos-app.html`の最初のMac画面はCSS製illustrationであり、実アプリのスクリーンショットではない。この報告では、最終PDFのSlide 3、5–9、11–12とcanonical Markdownを読み合わせ、実アプリ画面を撮影した。

## 実施環境

| 項目 | 値 |
|---|---|
| 実施日時 | 2026-09-03 19:50–20:12 AEST |
| Mac | macOS 26.3、build 25D125、arm64 |
| Xcode | 26.2、build 17C52 |
| Swift | 6.2.3 |
| 対象 | `macOSApp/dist/PermeationLab.app` |
| Bundle version | 1.0 (1) |
| Minimum macOS | 14.0 |

## E2Eチェック結果

| Check | Result | Evidence |
|---|---:|---|
| Release build | PASS | `scripts/build-app.sh`が完了 |
| ad-hoc署名 | PASS | `codesign --verify --deep --strict` |
| paper library resource | PASS | `latest_30_papers.csv`はheader込み31行 |
| Data S1 resource | PASS | `yuan2023_training_data.csv`はheader込み192行 |
| Release executable self-test | PASS | status `ok`、終了コード`0` |
| Local ML workflow tests | 14/14 PASS | fold内前処理、group分離、決定性、予測等 |
| Artifact validation tests | 6/6 PASS | JSON上限、有限値、次元、tree/forest/boosting制約等 |
| Fick publication bundle v6 | PASS | 全manifest itemと主要監査値を再検証 |
| Native app launch | PASS | Facts、Research、Fick、Model selectionを表示 |
| GUI XCUITest runner | NOT RUN | Automation Mode disabled、user authentication required |
| Presentation HTML local references | PASS | 5ページのlocal `href/src`を静的検査、missing `0` |
| Controlled-browser `file://` click test | NOT RUN | browser security policyがlocal file navigationを拒否。HTML defectではない |

### Release self-testの実測値

| 項目                         |                                                値 |
| -------------------------- | -----------------------------------------------: |
| 入力行                        |                                              191 |
| target                     |                              `Permeation amount` |
| split group                |                                           `Drug` |
| predictors                 |                                                7 |
| folds                      |                                                5 |
| candidates                 | Random Forest、Gradient Boosting、Ridge regression |
| selected candidate         |                                    Random Forest |
| selected internal-CV RMSE  |                                5288.566709886153 |
| final-fit rows             |                                              191 |
| artifact JSON              |                                     51,316 bytes |
| strict artifact round trip |                                            exact |
| predictions                |                                   191/191 finite |
| prediction round trip      |                                            exact |

同じtraining rowsをpractice predictionした値はRMSE `2361.0598`、MAE `964.6325`、R² `0.7260`だったが、学習内の操作確認なので外部性能として報告しない。

## スクリーンショットとプレゼンに沿った解説

### 1. Paper evidence — 原著の事実を研究結果から隔離

![[Prediction of drug permeation through microneedled skin by machine learning/macOSApp/Screenshots/e2e-2026-09-03/01-paper-evidence-overview.png]]

**見ているもの**

- 緑の`Verified Facts` mode。原著・公開supplement・検証済みData S1だけを置くread-only領域。
- `191 observations`、`6 drugs`、`4 reported models`、`8 paper figures`を表示する。
- Methods欄には7 predictorsと、原著のrandom 70:30 row splitを明記する。

**プレゼンとの対応**

- Slide 3の`191 observations / 6 drugs or chemicals / 7 predictors`に対応する。
- Slide 3のFick `R² = 0.82`、XGBoost `R² = 0.98`は**原著報告値**であり、画面下のscientific boundaryどおり、公開物だけから独立再現した値ではない。

> 発表では「この緑の領域は原著の事実です。以降の0.895やアプリ内学習結果を、原著が報告した値として混ぜないためにmodeを分けています」と説明する。

### 2. Local ML setup — 問い、target、splitを先に固定

![[Prediction of drug permeation through microneedled skin by machine learning/macOSApp/Screenshots/e2e-2026-09-03/02-local-ml-setup.png]]

**見ているもの**

- オレンジの`My Research` modeと`Scientific validity unverified`表示。
- `Data S1 practice copy · Local ML`の191 rowsを使用。
- targetは`Permeation amount`、split groupは`Drug`、predictorsは7列。
- 漏洩監査は既知のcritical patternを検出していない。

**プレゼンとの対応**

- Slide 11のDevelop段階、すなわちgroup-aware validationとfold内前処理に対応する。
- `Drug`で分けるため、同一drugのrowsはtraining/testへ跨がない。一方、Data S1には真正なrun/curve/donor/batch/site IDがないので、Slide 11–12が要求する独立run評価の代替にはならない。

> 発表では「ここで問うのは、Data S1内でdrugを分けた内部評価です。外部施設や新規runを一度だけ予測した試験ではありません」と説明する。

### 3. Fick 85% evidence — 0.895と確認的主張を分ける

![[Prediction of drug permeation through microneedled skin by machine learning/macOSApp/Screenshots/e2e-2026-09-03/03-fick-evidence-verdict.png]]

**見ているもの**

- in-app replayは一致したが、最上段のoverall verdictは`R² ≥ 0.850 claim is not confirmed`。
- `0.895`はsubsetに対するexploratory point estimateとして表示される。
- 画面内でも`Exploratory point R² 0.895 ≠ Confirmed claim R² ≥ 0.850`を明示する。
- family別はBSA `0.689`、caffeine `−0.101`、lidocaine `0.427`で、いずれも0.85未達。

**プレゼンとの対応**

- Slide 4–5：112 time points、12 proxy conditions、3 eligible familiesで得たrow-pooled OOF `R² = 0.895142`は再現可能。
- Slide 6：aggregationを変えると`0.895142 / 0.861608 / 0.592792 / 0.338346`へ変わり、total variationの`74.25%`がfamily間。
- Slide 7：family別0.85未達、unseen-family stress test `R² = −0.135867`。
- Slide 8：simple family-time baselineはrow-pooled R² `0.909`、RMSE `8.949 pp`でFick proxyを上回る。
- Slide 9：計算再現性はestablishedだが、外部妥当性はnot yet established。

> 発表では「0.895が再現できたことはsoftwareと計算の信頼性を支えます。しかし、Fick固有の優位性、各familyでの0.85、未知familyへの移送、独立外部runでの0.85は支えません」と説明する。

### 4. Internal CV — 候補を同じgroup-preserving foldsで比較

![[Prediction of drug permeation through microneedled skin by machine learning/macOSApp/Screenshots/e2e-2026-09-03/04-local-ml-internal-cv.png]]

**見ているもの**

- 191 rows、7 encoded features、5-fold group-preserving CV。
- 3候補内のfirst candidateはRandom Forest、RMSEは画面丸めで`5,289`。
- training-mean baseline RMSEは`5,215`で、Random Forestより小さい。
- Random ForestのOOF R²は`−0.3745`。画面も「best candidateでもmean predictionを下回る」「同じCVで最小RMSEを選ぶと楽観性があり得る」と警告する。

**最重要の区別**

この`−0.3745`とFick proxyの`0.895142`は矛盾ではない。評価設定が異なる。

|  | Local ML screenshot | Presentation Fick audit |
|---|---|---|
| outcome | Permeation amount | Permeation percentage |
| rows | 191 | 112 |
| split | Drug group、5 folds | proxy condition、12 folds、既知3 families内 |
| model | RF / GB / Ridge | family-specific A/k finite-slab proxy |
| purpose | 汎用tabular ML内部比較 | 限定されたFick型補間の監査 |

> 発表では「アプリは都合の悪い値も隠しません。今回のamount・Drug-holdout設定では全候補のR²が負で、mean baselineにも負けています。これはSlide 3のgeneralisation problemを実画面で示す結果です」と説明する。

### 5. Locked model artifact — 全development dataでfitして固定

![[Prediction of drug permeation through microneedled skin by machine learning/macOSApp/Screenshots/e2e-2026-09-03/05-locked-model-artifact.png]]

**見ているもの**

- Random Forestを191 rowsすべてで最終fit。
- model cardにtarget、split provenance、internal-CV RMSE、7 input dimensions、dataset hash、artifact IDを保存。
- JSON exportと別artifactのstrict importを用意する。
- final fit後の見かけ性能ではなく、OOF internal-CV summaryを保持する。

**プレゼンとの対応**

- Slide 9の`Locked-model workflow is implemented`を実装面で確認する。
- Slide 11のConfirm段階へ進むための「モデルをfreezeしてno-refit predictionする」器である。
- ただしartifactを作れたこと自体は、Slide 12の「genuinely independent runs」を入手したことを意味しない。

> 発表では「ここで固定されるのはcodeだけでなく、前処理、入力列、学習範囲、split来歴、dataset hashです。次に独立runを一度だけ入れる準備ができた、という意味です」と説明する。

### 6. Practice prediction — 191 predictions成功、しかし外部評価ではない

![[Prediction of drug permeation through microneedled skin by machine learning/macOSApp/Screenshots/e2e-2026-09-03/06-practice-prediction.png]]

**見ているもの**

- 191 rowsすべてへ予測を生成し、prediction CSV exportが可能。
- 欠測、未知category、training range外は検出されなかった。
- 画面自身が`Practice only — not external evaluation`と表示する。
- trainingに使ったrowsの再予測なので、表示誤差をmodel performanceとして報告してはいけない。

**プレゼンとの対応**

- Slide 12のone-time, no-refit external predictionへ進む操作経路は存在する。
- しかし今回入力したのは既知のData S1 practice copyであり、独立curve/runではない。
- 次に必要なのはrun、curve、replicate、donor、skin-batch、microneedle-batch、site IDを保持した未閲覧データである。

> 発表では「E2Eとして191件の予測生成は成功しました。しかしこの橙色warningが示すとおり、これはpipeline testです。external R²の証拠はまだ0件です」と説明する。

## 画面撮影の再現性と境界

- `01`–`03`は、checked Release appから作った隔離コピーを使用した。実行状態を既存preferencesから分離するためbundle IDとdisplay nameだけを一時変更し、同じexecutableを再署名した。
- `04`–`06`は、同じchecked sourceを一時directoryへコピーし、既存の`evaluate()`、`trainFinalModel()`、`predictPracticeData()`を順に呼び、該当sectionへscrollする撮影専用shimだけを追加したRelease buildである。画面、engine、data、数値ロジックは本体と同じで、Vault内sourceへshimを追加していない。
- 各再launchでartifact UUIDが変わるのは正常。dataset hashとmetricsは決定的に一致する。
- Computer Useのnative accessibility取得は対象SwiftUI appでpipe終了したため、通常のsemantic click操作へは使えなかった。これは既存2026-09-02記録と同じ環境制約である。
- GUI runnerの制約を補う保証経路は、unmodified Release executable self-test、20 unit tests、actual SwiftUI result screens、Fick bundle verificationである。

## プレゼンで守る一文

> `R² = 0.895`は、限定された既知family内のFick型proxy計算を再現できたという結果である。アプリのE2E成功は、その計算・artifact・予測pipelineが動くことを示す。一方、未知薬物または独立runで`R² ≥ 0.85`を達成したことは、どちらからもまだ示されない。

## 関連資料

- [[Prediction of drug permeation through microneedled skin by machine learning/macOSApp/docs/local-ml-platform-e2e-record-2026-09-02.md]]
- [[Prediction of drug permeation through microneedled skin by machine learning/macOSApp/README.md]]
- [[Prediction of drug permeation through microneedled skin by machine learning/research/確認的外部検証プロトコル-v2.md]]
- [[Prediction of drug permeation through microneedled skin by machine learning/study/FickモデルR2-85-独立監査報告-2026.md]]
