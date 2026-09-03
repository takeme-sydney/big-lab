# ローカルMLプラットフォーム E2E実施記録

- 実施日：2026-09-02
- 実施環境：macOS 26.3（25D125）、arm64、Xcode 26.2（17C52）
- 対象：`dist/PermeationLab.app`
- 目的：学習データの読込から内部評価、最終学習、artifact保存形式、再読込、予測までがMac内だけで完結することを確認する

## 結論

配布用アプリ実行ファイルの`-local-ml-self-test`は終了コード`0`で完了した。Data S1の191行を読み込み、group-aware 5-fold内部CVで3候補を比較し、選択モデルを191行すべてで最終学習し、JSON artifactを厳格再読込した後、191行すべてへ有限な予測を返した。

この自己診断はローカル処理系のE2Eである。学習データを再入力した評価値は操作確認用であり、独立test性能または外部検証結果ではない。

## 配布アプリE2E

実行コマンド：

```bash
'dist/PermeationLab.app/Contents/MacOS/PermeationLab' -local-ml-self-test
```

主要結果：

| 項目 | 結果 |
|---|---:|
| 終了コード | 0 |
| status | `ok` |
| 入力行数 | 191 |
| 目的変数 | `Permeation amount` |
| 分割group | `Drug` |
| 説明変数 | Loading、Molecular weight、MN length、Skin、MN type、Surface area、Time |
| fold数 | 5 |
| 比較候補 | Ridge regression、Random Forest、Gradient Boosting |
| 選択モデル | Random Forest |
| 選択モデルの内部CV RMSE | 5288.566709886153 |
| 最終学習行数 | 191 |
| 変換後特徴数 | 7 |
| artifact JSON | 51,316 bytes |
| artifact厳格往復 | 完全一致 |
| 予測件数 | 191 |
| 有限予測件数 | 191 |
| artifact再読込前後の予測 | 完全一致 |

同じ学習データを再入力した動作確認値はRMSE 2361.0598307143073、MAE 964.6324827406117、R² 0.7260378814563737だった。これらは学習内評価であり、研究成果の外部性能として報告しない。

## ビルド・署名・リソース

- Releaseアプリ生成：成功
- `codesign --verify --deep --strict`：成功
- `latest_30_papers.csv`：配布アプリ内に存在、ヘッダーを含め31行
- `yuan2023_training_data.csv`：配布アプリ内に存在、ヘッダーを含め192行
- Python、R、クラウドAPI、ネットワーク通信：ローカルMLの学習・予測には不使用

## 自動テスト

| テスト群 | 結果 | 主な確認内容 |
|---|---:|---|
| `LocalModelWorkflowTests` | 14/14成功 | 有限値CSV、漏洩防止、group分離、fold内前処理、3候補評価、全行fit、決定性、artifact往復、目的変数なし予測、評価付き予測、未知カテゴリ・範囲外警告、設定来歴一致 |
| `LocalModelArtifactValidationTests` | 6/6成功 | 4 MiB上限、深さ上限、未知フィールド、次元、有限値、木の深さ・node数、forest/boosting上限、全3モデルの厳格往復 |
| 既存`ExperimentReproducibilityTests`の計算・状態検証 | 14件成功 | Data S1同一性、分割再現性、固定設定再現性、Fick計算、履歴分離、モード分離など |

既存テストのうち論文ライブラリ1件は、`xctest`バンドルを単独起動すると`Bundle.main`がアプリ本体を指さないため、その経路では実行条件を満たさなかった。配布アプリへのファイル同梱と30報分の行数は上記のとおり別途確認した。アプリをホストする通常のXcodeテスト経路は、このMacのテストworkerが`waiting for workers to materialize`で停止したため完走していない。

## GUI E2Eの状態

`PermeationLabUITests.testLocalMachineLearningWorkflowCanTrainAndPredictEndToEnd`を追加し、次の画面操作をコード化した。

1. 個人研究用Data S1コピーでモデル選定画面を起動する。
2. 漏洩チェック付き内部CVを実行する。
3. 候補を選び、全開発データで最終学習する。
4. モデルカードの生成を確認する。
5. 現在データで練習予測し、予測レポートを確認する。

UIテストを含む`build-for-testing`は成功した。一方、実行Macでは`xcrun automationmodetool status`が次を返した。

```text
Automation Mode is disabled.
This device requires user authentication to enable Automation Mode.
```

そのためXCUITestはtest method開始前にAutomation Mode有効化待ちで停止し、GUIテスト成功とは記録していない。Computer Use経由でも対象アプリのAccessibility取得時にnative pipeが終了したため、GUIクリック完走の代替証拠にはしていない。OS設定を無断変更せず、配布アプリ実行ファイルのE2Eと20件のローカルML単体テストを実行可能な保証経路とした。

Automation Modeを利用できるMacでは次を実行する。

```bash
xcodebuild test \
  -project PermeationLab.xcodeproj \
  -scheme PermeationLab \
  -destination 'platform=macOS,arch=arm64' \
  -derivedDataPath /tmp/permeation-lab-ui \
  -only-testing:PermeationLabUITests/PermeationLabUITests/testLocalMachineLearningWorkflowCanTrainAndPredictEndToEnd
```

## 科学的境界

- Data S1には真正なrun、curve、donor、batch、site IDがない。`Drug`分割は未知薬物を模した内部評価であり、反復構造を完全には保証しない。
- 候補選択と同じ内部CVの最小値には選択楽観性があり得る。
- 独立施設、独立時期、または前向きに封印したデータでの外部評価は未実施である。
- 本機能は研究・教育・実験計画用であり、診断、投与、治療、患者安全性の判断には用いない。

## 関連文書

- [初心者向け機械学習実践ガイド](../../study/初心者向け-機械学習実践ガイド.md)
- [macOSアプリ README](../README.md)
- [Experiment execution runbook](./experiment-runbook.md)
