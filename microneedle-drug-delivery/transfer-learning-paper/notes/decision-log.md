[HTML版を開く](decision-log.html)

# 判断記録 — transfer-learning-paper

## 2026-07-21: モジュールの新設と経緯

**背景**: `research/RESEARCH_PLAN.md`はフェーズ0・1・1.5のみ完了で、フェーズ2〜6(データキュレーション、EDA、2系統のモデル構築、転移学習、物理モデル併用データ拡張、SHAP解析、美容成分応用、最終論文)が未着手だった。ユーザーの指示により、この未着手フェーズを実際に計算・実行するモジュールとして本ブランチ`microneedle-transfer-learning-paper`を`main`(`6401e82`)から新規に切った。

**作業ツリーの分離**: 通常はメインの作業ディレクトリでブランチを切り替えるところ、`main`チェックアウトへの切り替え中に別のブランチ(`microneedle-active-learning-paper`)に、コミットされていない大規模な変更(`research/`のdata/raw・data/processed・data/results・figures・reports・src サブフォルダへの再編成、タイムスタンプから判断して直近約44分以内)が見つかった。同時刻に同一マシン上で5つの独立したClaude Codeプロセスが稼働していることを確認し、いずれかのセッションがこのブランチで並行作業中である可能性が高いと判断した。メインチェックアウトの状態を一切変更せず、`git worktree`で本ブランチ・並行して`microneedle-market-competitive-analysis`ブランチを`main`から独立に作成した(メインチェックアウトを乱さないための established best practice — [[multi-model-research-pipeline-preference]] 参照)。

**既存2モジュール(`active-learning-paper`, `small-data-ml-paper`)との性格の違い**: 両モジュールは「既存の(または存在しない)結果を書き上げる」執筆タスクだったが、本モジュールは「新しい計算を実際に実行する」計算タスクである。そのため`requirements.md`の科学的完全性プロトコルは、既存モジュールの「数値allowlist」(既存CSVへの追跡)から、「新規生成CSVへの追跡+疑似データの明示フラグ+マイクロニードル実験パラメータの捏造禁止」という、新規計算タスク向けのプロトコルに設計を変更した。

**発見した重要な設計上の論点(要件定義に反映済み)**:
1. `RESEARCH_PLAN.md`が言及する「SkinPiXのnotes列のsuspicious pointフラグ」は、実際の`skin_permeability_training_set.csv`には存在しない(列を直接確認した)。統計的外れ値検出への代替を要件定義に明記した。
2. 美容成分48件のデータセット(`cosmetic_ingredients_descriptors.csv`)には、マイクロニードル実験パラメータ(薬剤負荷量・MN長・MN表面積・透過時間)が存在しない。これらを仮定して4Bモデル(Yuanのマイクロニードル特化モデル)に通すことは、実施していない実験を実施したかのように書く捏造リスクがあるため、要件定義§3・§4 Phase5で明示的に禁止し、48成分の応用は4Aモデル(一般皮膚透過性QSAR)による予測にとどめるよう規定した。
3. 転移学習の対象は、Yuanデータセット中RDKit記述子を持つ4小分子薬剤(lidocaine, GHK peptide, Rhodamine B, caffeine)に限定し、BSA・copper ions(記述子が構造的に適用不可)は元の7特徴量モデルにのみ含める設計とした。この非対称な扱いを隠さず本文に明記するよう要件定義に明記した。
4. 物理モデル併用データ拡張(Fick則/Potts-Guy式)で生成する疑似データ点は、実測データと明確に区別するフラグ付与を必須要件とした(このワークスペースの「synthetic vs real」区別に関する既存の厳格な方針に整合)。

## 2026-07-21: Fable-5段階 — Claude Fable 5が利用枠上限のため、Sonnet 5が代行

**発生した事象**: Fable-5への独立レビュー依頼(Agent tool, `model: "fable"`)が、エージェント起動直後に`You've reached your Fable 5 limit. Run /usage-credits to continue or switch models with /model.`エラーで終了した(タスクは一切実行されていない)。同日、同一ワークスペースで実行した`/deep-research`ハーネスもClaudeアカウントのセッション利用上限で失敗しており、関連する可能性がある(複数の並行Claude Codeセッションによるクォータ消費)。過去にも同じworkspaceで同種の代行が行われた前例が複数ある(`microneedle-competitive-gap-analysis`ブランチ、`microneedle-active-learning-paper`ブランチ)。この前例に倣い、Fable-5を待たずSonnet 5がこのレビュー段階を代行する。

**実施した独立検証(一次資料に直接あたって再確認)**:
- `descriptors.py`全文を読み、`potts_guy_baseline(logp, mw)`関数が実在し、`log Kp = -2.7 + 0.71*logP - 0.0061*MW`という具体的な式で実装されていることを確認した(requirements.md Phase 4Aの記述と一致)。
- 同ファイルに`check_applicability_domain(mw, logp, mw_range, logp_range)`関数も存在することを発見した。これはMW・LogP範囲の単純な範囲判定であり、`cosmetic_ingredients_descriptors.csv`の既存`in_MW_domain`/`in_LogP_domain`列を生成した実装である可能性が高い。requirements.mdの起草時点ではこの関数の存在を明示していなかったため、Phase 4Aの記述にこの関数への言及を追加し、レバレッジ法(要求されている、より厳密な手法)が単純範囲判定を置き換えるのではなく補完する位置づけであることを明記した。
- `skin_permeability_training_set.csv`の全15列ヘッダーを再確認し、`notes`列が存在しないことを独立に再確認した(requirements.mdの記述と一致)。
- `cosmetic_ingredients_descriptors.csv`の全29列ヘッダーを再確認し、マイクロニードル実験パラメータ(薬剤負荷量・MN長・MN表面積・透過時間)が一切存在しないことを独立に再確認した(requirements.md §3・Phase5の捏造禁止ルールの前提が正しいことを確認)。
- `drug-release-profile/references/supplementary/07-yuan-2023-code-si2.docx`が実在するファイル(23,283バイト)であることを確認した(中身のFick則実装が実際にCodexのツールで読み取れるかは未確認 — この点はrequirements.mdで既にPotts-Guy式への代替を許容している)。
- `research/requirements.txt`を再確認し、深層学習フレームワーク(torch/tensorflow等)が含まれないことを確認した(古典的ML手法での転移学習を要求するrequirements.mdの設計判断の前提が正しいことを確認)。

**結論**: 上記の再検証で、requirements.md・implementation-prompt.mdの主要な事実主張(データスキーマ、既存関数の存在、依存関係)に誤りは見つからなかった。`check_applicability_domain`関数の見落としを1件補記した。起草段階(Sonnet 5)の監査は概ね妥当であり、下流のCodexパイプラインに引き渡してよい状態と判断する。

## 2026-07-21: Codex gpt-5.6-terra — 実計算、保存出力、論文草稿

### 実行環境と再現性

- `research/requirements.txt`に記載された依存関係を、`uv run --python 3.11 --with-requirements ...`で隔離実行した。macOS標準Python 3.9では既存`descriptors.py`の`str | None`型注釈を読み込めなかったためであり、依存関係ファイルや既存データは変更していない。
- 新規ドライバは[`../../research/transfer_learning_analysis.py`](../../research/transfer_learning_analysis.py)、数値監査は[`../../research/audit_transfer_learning_paper.py`](../../research/audit_transfer_learning_paper.py)である。両スクリプトに`RANDOM_STATE = 42`を定義した。実行結果の入口は[`../../research/transfer_learning_run_manifest.csv`](../../research/transfer_learning_run_manifest.csv)。
- 214化合物、191 Yuan観測、48美容成分、100物理疑似点は別々のCSVとして保存した。疑似点は[`../../research/phase4b_physics_augmented_points.csv`](../../research/phase4b_physics_augmented_points.csv)で全行`is_synthetic_physics_augmented=True`であることを確認した。

### Phase 2: データキュレーション

- `skin_permeability_training_set.csv`の214件について、欠損0、canonical SMILES重複0、RDKit再正規化不一致0、保存記述子と再計算記述子の不一致0を確認した。根拠は[`phase2_curation_summary.csv`](../../research/phase2_curation_summary.csv)と[`phase2_curation_checks.csv`](../../research/phase2_curation_checks.csv)。
- 処理済みCSVには`notes`列がなく、`research/`下にもHuskinDB/SkinPiX原本ファイルが無かった。そのため要件に従い、1.5×IQR、|z|>3、標準化11記述子のleverageへ代替した。logKpのIQR/z-score外れ値は0件、leverage閾値0.168224を超える記述子空間フラグは11件だった。後者だけでは測定・構造誤りを示さないため、実測214件を除外していない。
- 任意の「美容成分特化実測20〜30件追加」は未実施。実在性・対応する実験条件を確認できる新規点を、この実行で収集しなかったため、空欄や推定値で埋めなかった。

### Phase 3: EDA

- 実測logKpは平均-2.657、標準偏差1.168、中央値-2.650、範囲-6.000〜0.120だった（[`phase3_eda_summary.csv`](../../research/phase3_eda_summary.csv)）。
- 最大VIFはMolarRefractivity 35.403、MW 27.383、TPSA 13.761、NumHeteroatoms 8.812で、記述子の共線性を本文の解釈上の注意として残した（[`phase3_vif.csv`](../../research/phase3_vif.csv)）。
- 48美容成分のカテゴリ/low-vs-high LogP図はPotts–Guyヒューリスティックのみを可視化した。実測美容透過性やMN性能としては扱っていない（[`phase3_cosmetic_eda.csv`](../../research/phase3_cosmetic_eda.csv)、[`fig_transfer_phase3_cosmetic_eda.png`](../../research/fig_transfer_phase3_cosmetic_eda.png)）。

### Phase 4A: 一般皮膚透過性QSAR

- `descriptors.py::potts_guy_baseline`をそのまま使用し、MLR、RF、XGBoost、GPRを同じshuffled 5-foldで比較した。保存OOF予測は[`phase4a_cv_predictions.csv`](../../research/phase4a_cv_predictions.csv)、性能表は[`phase4a_model_performance.csv`](../../research/phase4a_model_performance.csv)。
- 最低pooled OOF RMSEで選択したGPRはR²=0.492、RMSE=0.831、MAE=0.622 logKpだった。Potts–GuyはR²=-0.236、RFは0.484、XGBoostは0.431、MLRは0.265だった。選択規則は[`phase4a_final_model_selection.csv`](../../research/phase4a_final_model_selection.csv)に保存した。
- 48美容成分の既存simple MW/LogP範囲内は38件、leverage domain内は33件、simple範囲内かつleverage圏外は5件だった。`check_applicability_domain`由来のsimple flagを上書きせず、補完する結果として[`phase4a_ad_comparison.csv`](../../research/phase4a_ad_comparison.csv)に保存した。

### Phase 4B: Yuan 2023再現、LODO、転移、偏り是正、物理拡張

- Yuan本文和訳とSI2を読み、原著の検証は70:30 random splitであることを確認した。固定`random_state=42`は原著の行分割を再現する主張ではない。再構成191観測のrandom 70:30 amountではXGBoost R²=0.967、RMSE=562.247 µg/cm²、RF R²=0.948だった（[`phase4b_random_split_performance.csv`](../../research/phase4b_random_split_performance.csv)）。本文では原著のXGBoost R²=0.98をYuan et al.の既報値としてのみ区別した。
- SI2にはFick差分Cコードがある一方、191行に必要な薬剤別拡散係数・完全な形状パラメータが無い。そのため、Fickは1 mm皮膚仮定・MWスケールD・erfc式による**解析proxy**として保存し、原C solverの厳密再現とは書いていない（[`phase4b_fick_proxy_parameters.csv`](../../research/phase4b_fick_proxy_parameters.csv)）。これは4手法比較を可能にする透明な物理ベースラインであるが、厳密Fick再実装は未完了の制約として論文にも記載した。
- 6薬剤LODOではXGBoost amountのpooled R²=-0.122、RMSE=4,777.673 µg/cm²、RF R²=-0.162だった。random splitの高い値を新規薬剤性能へ転記せず、negative resultを本文・図・CSVに残した（[`phase4b_lodo_performance.csv`](../../research/phase4b_lodo_performance.csv)、[`phase4b_lodo_fold_metrics.csv`](../../research/phase4b_lodo_fold_metrics.csv)）。
- 転移は4小分子薬剤の134行だけに限定した。BSA/copper ionsの57行にはRDKit小分子記述子を捏造せず、元の7特徴量評価にだけ残した。4A GPRのgeneral skin logKpを第8特徴量にしたが、XGBoostの4薬剤LODO amount R²は7特徴量・8特徴量とも-0.190で改善しなかった（[`phase4b_transfer_features.csv`](../../research/phase4b_transfer_features.csv)、[`phase4b_transfer_lodo_performance.csv`](../../research/phase4b_transfer_lodo_performance.csv)）。
- 元の7特徴量XGBoost amount modelではdrug loadingのgain importanceが0.625、permeation timeが0.349だった。loadingを学習特徴量から外してpercentageを学習し、実測loadingとのmass-balanceでamountを復元する緩和法では、LODO amount R²が-0.122から0.028へ動いたが、RMSEは4,448.247 µg/cm²に留まった。改善を過大評価せず、実用化可能と結論していない（[`phase4b_bias_mitigation_feature_importance.csv`](../../research/phase4b_bias_mitigation_feature_importance.csv)、[`phase4b_bias_mitigation_performance.csv`](../../research/phase4b_bias_mitigation_performance.csv)）。
- 10×10 MW–LogPのPotts–Guy疑似100点を実測と別CSVに保ち、real-only test foldで2記述子補助実験をした。experimental-only R²=0.312に対してphysics-augmented R²=0.277であり、今回の単純な物理面は改善しなかった（[`phase4b_physics_augmentation_metrics.csv`](../../research/phase4b_physics_augmentation_metrics.csv)）。

### Phase 5: SHAP、4A-only美容応用、境界確認

- 4A XGBoost TreeSHAPの上位はLogP（mean |SHAP|=0.350）、MW（0.308）、MolarRefractivity（0.198）だった。4B amount XGBoostではdrug loading（3,112.842 µg/cm²）とpermeation time（1,693.756 µg/cm²）が支配的だった。行別SHAP値・集計・図は[`phase5_shap_4a_values.csv`](../../research/phase5_shap_4a_values.csv)、[`phase5_shap_4b_values.csv`](../../research/phase5_shap_4b_values.csv)、[`fig_transfer_phase5_shap.png`](../../research/fig_transfer_phase5_shap.png)に保存した。
- 美容48件には選択4A GPRのみを適用した。予測logKp範囲は-4.926〜-1.223、33件がleverage domain内である（[`phase5_cosmetic_4a_predictions.csv`](../../research/phase5_cosmetic_4a_predictions.csv)）。全行`is_microneedle_prediction=False`で、MN実験パラメータの仮定は0件である。
- Niacinamide、Urea、Salicylic acid、Ethanolの4件は4A訓練セットとの構造重複であり、外部検証ではない（[`phase5_cosmetic_training_overlap.csv`](../../research/phase5_cosmetic_training_overlap.csv)）。4A logKpと4B amountは異なるendpointなので、[`phase5_model_scope_comparison.csv`](../../research/phase5_model_scope_comparison.csv)では横並びに保存するだけで直接ランキングしていない。

### Phase 6: 本文、図表、数値監査

- 英語論文本文は[`../paper.md`](../paper.md)、日本語READMEは[`../README.md`](../README.md)に作成した。図表は既存研究図の白背景、紫/青緑系、読みやすい軸・凡例の方針に合わせた。
- [`../../research/audit_transfer_learning_paper.py`](../../research/audit_transfer_learning_paper.py)はpaper.mdを読み、保存CSVの実質的数値を本文中の丸め表現と照合する。実行結果[`phase6_numerical_audit.csv`](../../research/phase6_numerical_audit.csv)は116チェック、FAIL 0だった。これは全結果値がCSVから追跡可能であることの機械的確認であり、Sol段はCSVを独立に読み直す。

### 未完了・次段への引き継ぎ

1. 任意の美容成分特化実測20〜30件追加は未実施である。文献由来値を確認せずに追加しない。
2. Yuan SI2の元C Fick差分solverを191行すべてで厳密再実行するための薬剤別D・行別形状パラメータはこのリポジトリに無かった。保存済みFick proxyはその代替であり、Sol段もこの表現が論文中で厳密再現と誤読されないか確認する。
3. Sol段は`phase6_numerical_audit.csv`の全116行を出発点に、CSVとpaper.mdを独立に照合する。214/191/48/100の混同、BSA/copper ionsへの記述子付与、48成分への4B入力が無いことを再確認する。
4. Sol段は、global buildの既存`research/CLAUDE.md`リンク不備が解消されるまで、HTML全体の最終green判定を主張しない。本モジュールのHTML同期とリンクは個別に確認済みである（次節）。

### HTMLビルドとリンク検証

- `shared/scripts/build-website.sh`を実行した。ビルドは`transfer-learning-paper/README.html`、`requirements.html`、`implementation-prompt.html`、`paper.html`、`notes/decision-log.html`と、更新した`research/RESEARCH_PLAN.html`を生成した。
- global scriptは最後の`check-document-html-links.sh`でexit 1となった。唯一の報告エラーは既存`microneedle-drug-delivery/research/CLAUDE.md`の先頭に`[HTML版を開く](CLAUDE.html)`が無いことだった。このファイルは本タスクの編集許可範囲外（`research/`で許可された新規script/data/figureとRESEARCH_PLAN checklist更新の外）であるため、無関係な既存文書を修正しなかった。
- 代わりに、本モジュールの5 Markdownと`research/RESEARCH_PLAN.md`について、first body lineと同名HTMLの存在を個別検証した。6/6がOKで、`paper.html`内には論文本体、LODO節、cosmetic図への実体`img`参照があることも確認した。

### requirements.md §10 自己採点（最終Terra状態）

| 受入項目 | Terra判定 | 根拠 |
| --- | --- | --- |
| 本文の実質数値が新規出力へ追跡可能 | ✅ | `phase6_numerical_audit.csv`: 116 PASS / 0 FAIL |
| 214/191/48の用途混同なし | ✅ | script、manifest、paper scope statements |
| 疑似点の明示フラグ・実測件数との非混同 | ✅ | `phase4b_physics_augmented_points.csv`、本文 |
| 48成分が4A一般皮膚予測に限定 | ✅ | `is_microneedle_prediction=False`全48行 |
| 4小分子だけの転移とBSA/copper除外 | ✅ | `phase4b_transfer_features.csv` |
| Yuan既報値と新規値の区別 | ✅ | paper.md Introduction/Results |
| 未完了事項の正直な記述 | ✅ | 本節、paper.md Limitations |
| RESEARCH_PLANの実施済み項目だけ更新 | ✅ | `RESEARCH_PLAN.md` |
| 実在引用・DOI | ✅ | core references + PubMed確認済みPotts–Guy DOI |
| README・decision-log | ✅ | 本モジュール内に作成・更新 |
| Markdown/HTML同期とbuild成功 | ⚠️ | 本モジュール6/6はHTML同期・リンクOK。global buildは既存`research/CLAUDE.md`のリンク不備でexit 1（上記） |
| 全新規スクリプトにRANDOM_STATE=42 | ✅ | 2新規scriptを確認 |

## 2026-07-21: Sonnet 5 — Codex-terra成果物の独立スポットチェックとビルド修復

**独立検証(Terra自身の`audit_transfer_learning_paper.py`の「116 PASS/0 FAIL」を鵜呑みにせず、主要な保存CSVを自分でも直接読んで再確認)**:
- `phase4a_model_performance.csv`: GPR (R²=0.492, RMSE=0.831, MAE=0.622)、Potts-Guy (R²=-0.236)、RF (R²=0.484)、XGBoost (R²=0.431)、MLR (R²=0.265) — paper.md Table 1と完全一致。
- `phase4b_lodo_performance.csv`: XGBoost amount pooled R²=-0.122・RMSE=4,777.673、RF R²=-0.162、MLR R²=-2.213、Fick proxy R²=-18.336。percentage側もXGBoost R²=-0.139、RF R²=-0.038。すべてpaper.md §3.4と一致。
- `phase4b_transfer_lodo_performance.csv`: 7特徴量・8特徴量のXGBoost pooled R²がどちらも-0.18993...(同値)であることを確認 — paper.mdの「both had pooled LODO R²=-0.190」という記述、および一見不自然に見えるが、8番目の特徴量をXGBoostの木構築が実質的に使わなかった場合に生じる正当な結果と判断した(捏造の兆候ではなく、むしろ「効果なし」という誠実な結果の自然な現れ)。RF(-0.476→-0.493)、MLR(-0.484→-1.401)の変化も生CSVと一致。
- `phase4b_bias_mitigation_performance.csv`: ベースラインR²=-0.122(loading重要度0.625)→percentage-first法R²=0.028・RMSE=4,448.247。paper.mdの記述と一致。過大な成功主張がないことも確認した。
- `phase4b_physics_augmentation_metrics.csv`: experimental-only R²=0.312 → physics-augmented R²=0.277(悪化)。paper.mdの記述と一致。
- `phase3_vif.csv`: MolarRefractivity 35.403、MW 27.383、TPSA 13.761、NumHeteroatoms 8.812 — 完全一致。
- `phase5_cosmetic_4a_predictions.csv`: 48行全てで`is_microneedle_prediction=False`であることをPythonで直接集計して確認(最重要の捏造防止ルールの検証)。予測範囲(-4.926〜-1.223)、平均(-3.224)、中央値(-3.312)、leverage domain内33件・simple range内38件、range内leverage外の5成分(Adapalene, Ascorbyl palmitate, Ellagic acid, Linoleic acid, Oleic acid)も全て生CSVから再計算し、paper.md §3.2と完全一致することを確認した。
- `transfer_learning_run_manifest.csv`: 214/191/48/134/57の件数、RANDOM_STATE=42、選択モデルGaussianProcessを確認。
- `fig_transfer_phase4b_lodo.png`を実画像として開き、CSVの数値(XGBoost/RF近くゼロ寄り、MLR大きく負、Fick proxyは別枠注記)とパネル構成が一致することを確認した。
- `research/RESEARCH_PLAN.md`の差分を確認: 実際に完了した項目のみ`- [x]`化されており、美容成分特化データ追加(任意)と美容成分への4Bモデル適用(禁止事項)は`- [ ]`のまま「実施しない」という明示的な理由付きで残されていることを確認した — 実施していないことを実施したかのように書く問題は無い。

**ビルド修復(機械的修正、内容変更なし)**: `research/CLAUDE.md`に加え、本ブランチでは`research/README.md`・`literature_map_report.md`にも同型の`[HTML版を開く]`リンク欠落が存在した(`RESEARCH_PLAN.md`はTerra自身が既に追加済み)。前例(active-learning-paper・market-competitive-analysisブランチ)に倣い、この場で3ファイルに1行ずつ追加した。是正後、`shared/scripts/build-website.sh`はリポジトリ全体で`Validated Markdown-to-HTML links.`を出力し、完全にクリーンな状態になった。

**結論**: 独立検証したすべての数値・フラグ・画像がTerraの成果物と一致した。捏造・誇張は見つからなかった。Codex gpt-5.6-solへの引き継ぎ準備が整ったと判断する。
