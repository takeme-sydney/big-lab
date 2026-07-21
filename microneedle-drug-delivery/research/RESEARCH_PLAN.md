[HTML版を開く](RESEARCH_PLAN.html)

# 研究計画: Small-data MLによるマイクロニードル薬物送達予測の改良(美容成分応用を含む)

*2026-07-20更新: ユーザー提供の5文献(Yuan 2023本人論文、マイクロニードルレビュー、
Small-data MLレビュー3本)を精読し、研究の軸をYuan 2023の限界克服型に再定義。*

> 2026-07-21実行結果: フェーズ2〜6の計算・図表・論文草稿は
> [`../transfer-learning-paper/`](../transfer-learning-paper/README.md)に記録した。
> 実測214件・Yuan 191観測・美容48成分・物理疑似100点は明確に分離し、
> 数値監査は[`transfer_learning_run_manifest.csv`](transfer_learning_run_manifest.csv)と
> [`phase6_numerical_audit.csv`](phase6_numerical_audit.csv)を参照する。


## フェーズ0: スコープ定義 ✅ 完了
- 対象成分: 美白剤・抗老化剤(レチノイド)・ビタミンC誘導体・保湿剤・脂質バリア成分・
  抗炎症剤・角質剥離剤・浸透促進剤の8カテゴリ、50成分をリストアップ(`handoff/ingredient_list.json`)
- 目的変数: log Kp (cm/h) に統一
- 高分子(ヒアルロン酸、ペプチド)は低分子モデルの対象外とし、別枠管理

## フェーズ1: データ収集 ✅ 完了(初期版)
- PubChemより48/50成分の構造・物性データ取得(`data/processed/cosmetic_ingredients_descriptors.csv`)
- 実測皮膚透過性データを2つの公開データベースから取得・統合:
  - HuskinDB(129件、Stepanov 2020)
  - SkinPiX(103件、Chedik 2024)+ INRS追加データ(3件、2025年)
  - 重複除去後 **214件のユニーク化合物** による訓練データセット
    (`data/processed/skin_permeability_training_set.csv`)
- 美容成分48件中4件(ナイアシンアミド・尿素・サリチル酸・エタノール)はすでに
  訓練データに実測値あり → モデル検証用の直接比較に使える
- 美容成分48件中38件が訓練データの化学空間(MW・LogP範囲)内 → 予測信頼性が高い
- 残り10件(高分子量脂質・誘導体)は適用範囲外 → 予測は参考値として扱う

## フェーズ1.5: Yuan 2023データセットの再現 ✅ 完了
- PMC補足データ(PMC10658566, Data S1)からYuan 2023の訓練データ191点を完全再現
  (`data/raw/yuan2023_training_data.csv`)
- 薬剤別内訳: lidocaine 73件, BSA 33件, copper ions 24件, GHK peptide 24件,
  Rhodamine B 19件, caffeine 18件(論文記載と一致)
- 小分子4薬剤(lidocaine, GHK peptide, Rhodamine B, caffeine)にPubChem SMILES +
  RDKit記述子を付与(`data/processed/yuan2023_dataset_with_descriptors.csv`)
- BSA・copper ionsは非小分子としてフラグ管理(低分子QSAR記述子の対象外)
- 論文の限界点を確認: 訓練セット外の薬剤への外挿で大きな乖離が生じる
  (Discussion 4.2節)。薬剤負荷量への特徴量重要度の偏りが一因と分析されている。

## フェーズ2: データキュレーション
- [x] 214件の実測値の外れ値・矛盾データチェック。処理済みCSVに`notes`列・
      raw SkinPiX/HuskinDB原本が無かったため、IQR/z-score/記述子leverageに代替
      (`phase2_curation_checks.csv`, `phase2_curation_summary.csv`)。記述子leverage
      11件は誤りの証拠ではないため実測値を除外しなかった。
- [ ] 美容成分特有の透過性データを化粧品科学誌(*Int J Cosmetic Science* 等)から
      個別収集し、訓練データセットに追加(目標: 美容成分特化データ20〜30件追加)
- [x] SMILES重複・立体異性体表記ゆれの最終チェック
      (`phase2_duplicate_smiles.csv`: canonical SMILES重複0件、RDKit再正規化不一致0件)

## フェーズ3: 探索的データ分析(EDA)
- [x] 目的変数の分布確認、記述子との相関・多重共線性(VIF)チェック
      (`phase3_eda_summary.csv`, `phase3_descriptor_correlation.csv`, `phase3_vif.csv`,
      `fig_transfer_phase3_eda.png`)
- [x] 美容成分カテゴリ別(親水性 vs 親油性)のPotts–Guyヒューリスティック傾向を可視化
      (`phase3_cosmetic_eda.csv`, `fig_transfer_phase3_cosmetic_eda.png`)。これは実測値でも
      MN予測でもないことを明記した。

## フェーズ4: モデル構築(2系統並行)

### 4A. 皮膚透過性QSARモデル(化粧品成分向け、既存軸)
- [x] ベースライン: `descriptors.py::potts_guy_baseline`、多重線形回帰
- [x] Random Forest, XGBoost, Gaussian Process Regression の比較
- [x] 5-fold交差検証によるR²・RMSE評価
      (`phase4a_cv_predictions.csv`, `phase4a_model_performance.csv`)
- [x] Applicability Domain評価(leverage法)。既存MW/LogP範囲フラグを置換せず補完
      (`phase4a_applicability_domain.csv`, `phase4a_ad_comparison.csv`)

### 4B. Yuan 2023マイクロニードルモデルの再現・改良(中心軸)
- [x] Yuan 2023の4手法(Fick則, MLR, RF, XGBoost)を固定70:30 splitで比較
      (`phase4b_random_split_*.csv`)。SI2の完全な行別拡散係数・形状が無いため、Fickは
      **明示的な解析proxy**であり、元C solverの厳密再現とは主張していない。
- [x] **Leave-one-drug-out交差検証**で外挿性能を定量評価
      (`phase4b_lodo_predictions.csv`, `phase4b_lodo_performance.csv`,
      `phase4b_lodo_fold_metrics.csv`)
- [x] **転移学習**: 214化合物の選択4Aモデルの予測logKpを、RDKit記述子が有効な
      4小分子薬剤だけの第8特徴量として追加。BSA/copper ionsは構造的に除外
      (`phase4b_transfer_features.csv`, `phase4b_transfer_lodo_performance.csv`)。
- [x] **特徴量重要度の偏り是正**: loadingを学習コンポーネントから除外してpercentageを
      学習し、mass-balanceでamountを復元する緩和法をLODOで比較
      (`phase4b_bias_mitigation_*.csv`)。
- [x] **物理モデル併用データ拡張**: Potts–Guy式からMW–LogPグリッド100点を生成し、
      全点に`is_synthetic_physics_augmented=True`を付けて、実測test foldだけで評価
      (`phase4b_physics_augmented_points.csv`, `phase4b_physics_augmentation_metrics.csv`)。

## フェーズ5: 解釈・応用考察
- [x] SHAP値による特徴量重要度分析(4A・4Bの両モデル)
      (`phase5_shap_4a_*.csv`, `phase5_shap_4b_*.csv`, `fig_transfer_phase5_shap.png`)
- [x] Leave-one-drug-out性能: 7特徴量、8特徴量転移、loading緩和法を比較
      (`phase4b_lodo_performance.csv`, `phase4b_transfer_lodo_performance.csv`,
      `phase4b_bias_mitigation_performance.csv`)
- [x] 4A一般皮膚QSARと4B MNモデルの精度を、異なるendpointで直接順位付けしない
      スコープ比較として記録 (`phase5_model_scope_comparison.csv`)
- [ ] 改良済みMNモデル(4B)を用いた美容成分48件のマイクロニードル送達性能予測
      — **実施しない**。48成分にMN実験パラメータが無いため、仮定して4Bへ入れることを禁止。
- [x] 美容成分48件を4A一般皮膚透過性としてのみ予測し、simple rangeとleverage ADを併記
      (`phase5_cosmetic_4a_predictions.csv`, `phase5_cosmetic_category_summary.csv`)。

## フェーズ6: 成果物整理
- [x] 既存研究図と同じ白背景・紫/青緑系のmatplotlib最終図表を作成
      (`fig_transfer_phase3_eda.png`, `fig_transfer_phase4a_performance.png`,
      `fig_transfer_phase4b_lodo.png`, `fig_transfer_phase5_shap.png`,
      `fig_transfer_phase5_cosmetic_predictions.png`)
- [x] 論文草稿・README・判断記録・数値監査を作成
      (`../transfer-learning-paper/paper.md`, `phase6_numerical_audit.csv`)

---
*進捗: フェーズ0, 1, 1.5, 2, 3, 4A, 4B, 5, 6を実行済み。任意の美容成分特化
実測値20〜30件追加は未実施。Terraの保存出力はSol段で独立に再読・再照合する。*
