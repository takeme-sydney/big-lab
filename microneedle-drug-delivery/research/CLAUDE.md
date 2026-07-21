[HTML版を開く](CLAUDE.html)

# プロジェクト: Small-data MLによるマイクロニードル薬物送達予測の改良と美容成分への応用

## 目的
Yuan et al. (2023)「Prediction of drug permeation through microneedled skin by
machine learning」(Bioeng Transl Med, doi:10.1002/btm2.10512)が抱える中心的な
限界 ― **訓練データが191点・6薬剤のみと小規模で、訓練セットにない新規薬剤への
外挿で大きな誤差が生じる**(論文Discussion 4.2節で著者自身が明記)― を、
Small-data ML分野の確立手法(転移学習・データ拡張・Applicability Domain評価)で
解決することを主目的とする。美容有効成分への応用はこの改良モデルの実証先として
位置づける。

## 中核となる参考文献(この研究の設計思想の土台)
1. **Yuan et al. 2023** (doi:10.1002/btm2.10512) — 本研究の直接の前身。
   Fick則・MLR・RF・XGBoostの4手法比較。XGBoostが最良(R²=0.98)だが、
   訓練データ外の新規薬剤への予測で「大きな乖離」が生じることが確認されている
   (Discussion 4.2, Figure S1/S2)。特徴量: 薬剤負荷量・透過時間・MN表面積・
   MN長・MNタイプ・皮膚タイプ・薬剤分子量の7種。
2. **Zheng et al. 2023, Nature Reviews Bioengineering** (doi:10.1038/s44222-023-00141-6)
   "Microneedle biomedical devices" — マイクロニードル工学の包括的レビュー。
   MN設計・材料・応用の最新動向の参照元。
3. **Xu et al. 2023, npj Computational Materials** (doi:10.1038/s41524-023-01000-z)
   "Small data machine learning in materials science" — 小規模データ対処法の
   体系的整理:データソースレベル(文献抽出・DB構築・ハイスループット実験)、
   アルゴリズムレベル(不均衡学習向けモデル)、ML戦略レベル(能動学習・転移学習)。
4. **Achar & Keith 2024, Chem Rev** (doi:10.1021/acs.chemrev.4c00957)
   "Small Data Machine Learning Approaches in Molecular and Materials Science"
   (本文入手不可、要旨のみ参照)
5. **Dou, Zhu, Merkurjev et al. 2023, Chem Rev** (doi:10.1021/acs.chemrev.3c00189)
   "Machine Learning Methods for Small Data Challenges in Molecular Science" —
   基礎アルゴリズム(MLR, LR, KNN, SVM, KL, RF, GBT)から発展手法(ANN, CNN, GNN,
   GAN, LSTM, transformer, 転移学習, 能動学習, 物理モデルベースのデータ拡張)
   までを網羅。

## 研究の力点(優先順位)
1. **転移学習によるYuan 2023モデルの外挿性改善** — 本プロジェクトで新規構築した
   実測皮膚透過性データセット(214化合物、HuskinDB+SkinPiX統合)を「元ドメイン」、
   Yuan 2023のMN透過データ(191点・6薬剤)を「目標ドメイン」とし、皮膚透過性の
   一般知識をMN文脈に転移する。
2. **データ拡張・物理モデル併用** — Yuan 2023のFick則モデル(C言語実装)を
   物理制約として、機械学習モデルの予測を補正・拡張する(Zhu 2024, Zhang 2023
   で紹介される物理モデルベースのデータ拡張に相当)。
3. **Applicability Domain評価の厳格化** — Yuan 2023では新規薬剤の予測乖離が
   「薬剤負荷量への過度な依存」が原因と分析されている。特徴量重要度の分布を
   平滑化する正則化・アンサンブル手法を検討する。
4. **美容成分への応用** — 上記の改良モデルを用いて、美容有効成分48件
   (`data/processed/cosmetic_ingredients_descriptors.csv`)のマイクロニードル
   送達性能を予測する。

## データスキーマ

### `data/processed/skin_permeability_training_set.csv`
実測皮膚透過性データ(214化合物、HuskinDB + SkinPiX + INRS 2025年追加分を統合・重複除去済み)。
- `canon_smiles`: RDKit正規化SMILES(主キー)
- `logKp_cm_h`: log10(Kp), 単位cm/h(複数実測値がある場合は平均)
- `n_measurements`: 統合前の実測値の数
- `sources`: データ由来(HuskinDB / SkinPiX / INRS_new)
- `MW, LogP, TPSA, HBD, HBA, RotB, NumRings, NumAromaticRings, FractionCSP3,
  MolarRefractivity, NumHeteroatoms`: RDKit記述子

### `data/processed/cosmetic_ingredients_descriptors.csv`
候補美容成分48件の構造・記述子(PubChem CID・SMILES・RDKit記述子)。
- `category`: 機能分類(whitening, anti_aging_retinoid, antioxidant, moisturizer, etc.)
- `large_molecule_flag`: MW>500(適用範囲外の可能性)
- `in_MW_domain`, `in_LogP_domain`: 訓練データの化学空間範囲内かどうか
- 48件中4件(Niacinamide, Urea, Salicylic acid, Ethanol)はすでにトレーニングセット内に
  実測値あり。残り44件のうち34件が化学空間(MW・LogP)の範囲内、10件が範囲外
  (高分子量の脂質類・誘導体)。

### `data/processed/yuan2023_dataset_with_descriptors.csv`
Yuan et al. (2023) の訓練データ(191点・6薬剤: BSA, copper ions, GHK peptide,
Rhodamine B, lidocaine, caffeine)を論文補足データ(Data S1, PMC10658566)から
再現し、小分子(GHK peptide, Rhodamine B, lidocaine, caffeine)にRDKit記述子を
追加したもの。BSA(タンパク質, MW 66,000)とcopper ions(金属イオン)は
`is_small_molecule=False` としてフラグ管理し、低分子記述子の対象外とする。

### データ出典
- HuskinDB: https://huskindb.drug-design.de (Stepanov, Canipa & Wolber 2020,
  doi:10.1038/s41597-020-00764-z)
- SkinPiX: Recherche Data Gouv doi:10.57745/7FHQOY (Chedik et al. 2024)
- 統合QSPRデータセット: Recherche Data Gouv doi:10.57745/ZUU1DH (Asgarkhanova et al.,
  Laboratory of Chemoinformatics, University of Strasbourg)
- Yuan 2023訓練データ: PMC10658566 Data S1 (doi:10.1002/btm2.10512 補足情報)

## 命名規則・コーディング規約
- 日本語コメント可、変数名・関数名は英語(snake_case)
- 分子記述子計算は `src/descriptors.py` を必ず経由する(RDKit呼び出しを散在させない)
- 図表は `figure-style` スキル適用(最終成果物のみ。探索的プロットは簡易でよい)
- 乱数シードは全スクリプトで `RANDOM_STATE = 42` に統一

## モデリング方針
- ベースライン: Potts-Guy式(`src/descriptors.py::potts_guy_baseline`)、多重線形回帰
- 主要手法: Random Forest, XGBoost(Yuan 2023と同一アプローチ)、Gaussian Process Regression
- 検証: 5-fold交差検証(データ数214件のため単純train/test splitは避ける)
- 適用範囲(Applicability Domain): 訓練データのMW・LogP範囲外の美容成分(高分子脂質類など
  10件)は別枠で扱い、予測結果に「範囲外」フラグを必ず付与する
- 解釈: SHAP値による特徴量重要度分析を必須とする

## 既知の制約
- 訓練データ(214件)は主に医薬品・環境化学物質由来。化粧品有効成分特有のデータは
  文献から個別収集が必要(フェーズ1-2で継続対応)。
- ヒアルロン酸等の高分子・重合体は本モデルの対象外(別途プロジェクト化を検討)。
