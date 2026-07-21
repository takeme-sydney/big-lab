[HTML版を開く](README.html)

# Transfer Learning for Microneedle Drug Permeation QSAR

更新日: 2026-07-21
状態: Terra段の実計算・論文草稿・数値監査を完了。Sol段の独立検証・仕上げ待ち。

## Start here

1. 研究論文（英語）: [`paper.md`](paper.md)
2. 要件定義: [`requirements.md`](requirements.md)
3. 実行用指示文: [`implementation-prompt.md`](implementation-prompt.md)
4. 実行判断・数値監査・自己採点: [`notes/decision-log.md`](notes/decision-log.md)
5. 実行コード: [`../research/transfer_learning_analysis.py`](../research/transfer_learning_analysis.py)
6. 数値監査コード: [`../research/audit_transfer_learning_paper.py`](../research/audit_transfer_learning_paper.py)
7. 研究計画のチェックリスト: [`../research/RESEARCH_PLAN.md`](../research/RESEARCH_PLAN.md)

## このモジュールの位置づけ

このモジュールは、`../research/RESEARCH_PLAN.md`のフェーズ2〜6を**実際に計算した**研究論文である。214化合物の一般皮膚透過性QSAR（4A）と、191点・6薬剤のYuan 2023マイクロニードル透過データ（4B）を別の科学的対象として扱う。48美容成分は分子記述子しか持たないため、一般皮膚透過性の4Aによるスクリーニングに限定する。薬剤負荷量、MN長、MN表面積、透過時間などを仮定して4Bに通すことは行っていない。

Terra段で保存した主な結果は次のとおりである。

- 214件の4AではGaussian Process Regressionが選択され、5-fold OOF (R^2=0.492)、RMSE=0.831 log (K_p) だった。根拠: [`../research/phase4a_model_performance.csv`](../research/phase4a_model_performance.csv)
- Yuanデータの固定70:30 splitではXGBoost amountモデルが (R^2=0.967) だった一方、6薬剤LODOでは (R^2=-0.122) となった。根拠: [`../research/phase4b_random_split_performance.csv`](../research/phase4b_random_split_performance.csv)、[`../research/phase4b_lodo_performance.csv`](../research/phase4b_lodo_performance.csv)
- 4小分子薬剤だけを対象に一般皮膚log (K_p) を第8特徴量として転移したが、XGBoostのLODO amount (R^2) は7特徴量・8特徴量とも (-0.190) で、改善しなかった。根拠: [`../research/phase4b_transfer_lodo_performance.csv`](../research/phase4b_transfer_lodo_performance.csv)
- 100点のPotts–Guy疑似データは`is_synthetic_physics_augmented=True`で分離して保存し、2記述子補助実験では性能を改善しなかった。根拠: [`../research/phase4b_physics_augmented_points.csv`](../research/phase4b_physics_augmented_points.csv)、[`../research/phase4b_physics_augmentation_metrics.csv`](../research/phase4b_physics_augmentation_metrics.csv)

これらは独立レビュー前の結果であり、数値はすべて保存CSVから引用している。既報のYuan et al. (2023) の値は先行研究としてのみ扱い、本モジュールの計算結果とは区別している。

## 実行物

`../research/`直下に、再実行可能なドライバ、全予測CSV、性能CSV、SHAP CSV、適用範囲CSV、疑似データCSV、最終PNGを置く。入口となるファイルは次のとおり。

- `transfer_learning_analysis.py` — フェーズ2〜5の計算ドライバ。全乱数処理は`RANDOM_STATE = 42`。
- `transfer_learning_run_manifest.csv` — データセット境界、選択4Aモデル、疑似データファイルの記録。
- `phase2_curation_summary.csv` — 重複・外れ値・記述子整合性・原データ不在の確認。
- `phase4a_model_performance.csv` / `phase4a_cv_predictions.csv` — 4A比較とOOF予測。
- `phase4b_*` — Yuan再現、LODO、転移、負荷量是正、物理拡張の各出力。
- `phase5_*` — SHAP、4A-only美容成分予測、適用範囲、スコープ比較。
- `phase6_numerical_audit.csv` — 本文の実質的数値と保存CSVの照合結果。

## 再実行

macOS標準のPython 3.9は既存`descriptors.py`の型注釈を解釈できないため、作業時は依存関係を変更せず、隔離したPython 3.11ランタイムを使用した。リポジトリのルートから以下を実行する。

```sh
uv run --python 3.11 --with-requirements microneedle-drug-delivery/research/requirements.txt \
  python microneedle-drug-delivery/research/transfer_learning_analysis.py

uv run --python 3.11 --with-requirements microneedle-drug-delivery/research/requirements.txt \
  python microneedle-drug-delivery/research/audit_transfer_learning_paper.py
```

前者はCSV・PNGを再生成し、後者は`paper.md`の監査対象となる実質的な結果数値をCSV出力と照合する。各段階は先行CSVを実際に読み直してから引用する。

## 守るべきデータ境界

- **214化合物**: 実測の一般皮膚透過性log (K_p)。4Aモデルの学習・評価にのみ使用する。
- **191観測・6薬剤**: 実測のMN透過実験。4Bの再現・LODO・転移評価に使用する。
- **48美容成分**: 分子記述子のみ。4Aの一般皮膚透過性予測に限定する。
- **100疑似点**: Potts–Guy式から生成し、`is_synthetic_physics_augmented=True`で明示した。214件または191件の実測数と合算して記述しない。
- **BSA・copper ions**: RDKit小分子記述子の対象外。7特徴量4Bには残すが、8特徴量転移には入れない。

## 関連モジュールと編集境界

`../active-learning-paper/`、`../small-data-ml-paper/`、`../competitive-landscape/`は別ブランチの別モジュールであり、このタスクでは編集していない。比較が必要な場合も`git show <branch>:<path>`だけを使う。新規スクリプト、結果、図は`../research/`直下に置き、本文・要件・判断記録はこのディレクトリに置く。
