# Permeation Lab for macOS

マイクロニードル処理皮膚の薬物透過研究を、資料確認・データ監査・モデル比較・最終学習・未知CSV予測までMac内で行うSwiftUIアプリです。機械学習処理にPython、R、クラウドAPI、ネットワーク接続は必要ありません。

## 動作環境

- macOS 14以降
- Xcode 26系（ソースからビルドする場合）
- Apple silicon / Intel Mac

## 起動

リポジトリ内で次を実行します。

```bash
./scripts/build-app.sh
open 'dist/PermeationLab.app'
```

`build-app.sh`はRelease版を一時DerivedDataでビルドし、`dist/PermeationLab.app`へ配置してad-hoc署名します。これは研究室内実行用であり、Mac App Store配布やnotarization済み製品を意味しません。

## はじめての機械学習

1. サイドバー上部で「自分の研究」を選びます。
2. 「研究ダッシュボード」の「機械学習を始める」、またはサイドバーの「モデル選定」を開きます。
3. 学習CSVを選びます。目的変数は有限数値を含む列で、最低20行、最大5,000行です。
4. 目的変数、分割グループ、説明変数を確認します。run/curve IDがある場合は分割グループに使います。透過量を予測するときは透過率を、透過率を予測するときは透過量を説明変数へ入れません。
5. 漏洩チェック後、平均値baseline、Ridge、Random Forest、Gradient Boostingを最大5-foldの内部CVで比較します。
6. 候補を選び、開発データ全体で最終学習します。前処理とモデルはこのMacに保存され、JSON artifactとして書き出し・再読込できます。
7. 「入力CSVテンプレート」を書き出し、目的変数なしの未知CSVを一括予測します。目的変数が同名で含まれる場合は、固定モデルを再学習せずRMSE・MAE・R²を計算します。

「現在データで操作練習」は学習データを再予測する動作確認です。その誤差は外部性能として報告できません。画面内のgroup-aware CVも内部評価であり、独立外部検証ではありません。

詳しい科学的手順、指標、漏洩例、CSV設計、チェックリストは[初心者向け機械学習実践ガイド](../study/初心者向け-機械学習実践ガイド.md)を参照してください。

## 保存物

- モデルJSON：前処理、学習済みnativeモデル、列定義、カテゴリ、学習範囲、内部CV要約、dataset hash、artifact ID
- 予測CSV：元の入力列、元CSV行番号、予測値、目的変数があれば残差、artifact ID
- アプリ内保存：直近の学習済みモデル1件をこのMacのUserDefaultsへ保存

重要な研究成果はアプリ内保存だけに頼らず、元CSV、モデルJSON、予測CSV、プロトコルMarkdownを同じ研究run IDで保管してください。

## 開発者向け検証

単体テストとUIテストは分けて実行します。

配布アプリ自身で、Data S1読込から内部CV、最終学習、モデルJSON往復、191行予測までを一括確認できます。成功時は1行のJSONを標準出力へ出し、終了コード`0`を返します。

```bash
'dist/PermeationLab.app/Contents/MacOS/PermeationLab' -local-ml-self-test
```

```bash
xcodebuild test -quiet \
  -project PermeationLab.xcodeproj \
  -scheme PermeationLab \
  -destination 'platform=macOS,arch=arm64' \
  -derivedDataPath /tmp/permeation-lab-unit \
  -only-testing:PermeationLabTests
```

```bash
xcodebuild test \
  -project PermeationLab.xcodeproj \
  -scheme PermeationLab \
  -destination 'platform=macOS,arch=arm64' \
  -derivedDataPath /tmp/permeation-lab-ui \
  -only-testing:PermeationLabUITests
```

macOS UIテストにはAutomation Modeが必要です。無効なMacではtest method開始前に`Timed out while enabling automation mode`となるため、アプリのassertion failureと区別してください。

2026-09-02の実施条件と結果は[ローカルMLプラットフォーム E2E実施記録](docs/local-ml-platform-e2e-record-2026-09-02.md)に記録しています。

## 科学的・利用上の境界

- Gradient BoostingはSwift製の軽量回帰木実装で、XGBoostそのものではありません。
- 候補選択と同じ内部CVの最小RMSEは、選択後性能を楽観的に示す可能性があります。
- Data S1には真正なrun/curve/donor/batch/site IDがなく、行の独立性を完全には確認できません。
- 本アプリは研究・教育・実験計画用です。診断、投与量、治療効果、毒性、患者安全性の判断には使用できません。

原著再構成、Fick proxy、既存実験機能の詳細は[Experiment execution runbook](docs/experiment-runbook.md)を参照してください。
