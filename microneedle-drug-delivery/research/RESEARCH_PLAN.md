# 研究計画: Small-data MLによるマイクロニードル薬物送達予測の改良(美容成分応用を含む)

*2026-07-20更新: ユーザー提供の5文献(Yuan 2023本人論文、マイクロニードルレビュー、
Small-data MLレビュー3本)を精読し、研究の軸をYuan 2023の限界克服型に再定義。*


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
- [ ] 214件の実測値の外れ値・矛盾データチェック(SkinPiXのnotes列に記載の
      "suspicious point" フラグの確認・除外検討)
- [ ] 美容成分特有の透過性データを化粧品科学誌(*Int J Cosmetic Science* 等)から
      個別収集し、訓練データセットに追加(目標: 美容成分特化データ20〜30件追加)
- [ ] SMILES重複・立体異性体表記ゆれの最終チェック

## フェーズ3: 探索的データ分析(EDA)
- [ ] 目的変数の分布確認、記述子との相関・多重共線性(VIF)チェック
- [ ] 美容成分カテゴリ別(親水性 vs 親油性)の透過性傾向を可視化

## フェーズ4: モデル構築(2系統並行)

### 4A. 皮膚透過性QSARモデル(化粧品成分向け、既存軸)
- [ ] ベースライン: Potts-Guy式、多重線形回帰
- [ ] Random Forest, XGBoost, Gaussian Process Regression の比較
- [ ] 5-fold交差検証によるR²・RMSE評価
- [ ] Applicability Domain評価(leverage法)

### 4B. Yuan 2023マイクロニードルモデルの再現・改良(中心軸)
- [ ] Yuan 2023の4手法(Fick則, MLR, RF, XGBoost)をまず再現し、報告値
      (XGBoost R²=0.98)との整合性を確認
- [ ] **Leave-one-drug-out交差検証**で外挿性能を定量評価(論文が定性的にしか
      示していない「新規薬剤への乖離」を数値化する)
- [ ] **転移学習**: フェーズ1で構築した皮膚透過性QSARモデル(214化合物)を
      事前学習し、Yuan 2023の191点でファインチューニング。Xu 2023 / Dou・Zhu・
      Merkurjev 2023が整理する転移学習戦略を適用。
- [ ] **特徴量重要度の偏り是正**: 薬剤負荷量への過度な依存を緩和する正則化・
      特徴量選択・アンサンブル手法を比較
- [ ] **物理モデル併用データ拡張**: Yuan 2023のFick則シミュレーションを用いて
      疑似データ点を生成し、小規模データを補強(Achar・Keith 2024が言及する
      物理モデルベースのデータ拡張に相当)

## フェーズ5: 解釈・応用考察
- [ ] SHAP値による特徴量重要度分析(4A・4Bの両モデル)
- [ ] Leave-one-drug-out性能: 改良モデル(4B) vs Yuan 2023オリジナルモデルの比較
- [ ] 医薬品ベースモデルと美容成分特化モデルの予測精度比較(4A)
- [ ] 改良済みMNモデル(4B)を用いた美容成分48件のマイクロニードル送達性能予測

## フェーズ6: 成果物整理
- [ ] `figure-style` 適用済み最終図表の作成
- [ ] 論文/レポート草稿
- [x] **副次的検討(能動学習)**: Yuan 2023データ(191点)を用いたretrospective active
      learningシミュレーション(Random vs GP-Uncertainty vs RF-QBC)を実施し、
      研究ノートとして執筆中: [`../active-learning-paper/`](../active-learning-paper/)。
      新規データ収集なし・既存191点の再利用のみ。フェーズ2〜6本体(transfer learning等)
      の代替ではなく、実験計画最適化に関する独立した補足的知見。

---
*進捗: フェーズ0, 1, 1.5 完了。次はフェーズ2(データキュレーション)を経て、
フェーズ4B(Yuan 2023の再現とleave-one-drug-out評価)に優先着手する。*
