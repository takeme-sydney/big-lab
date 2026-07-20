[HTML版を開く](README.html)

# 美容有効成分の皮膚透過性QSAR/MLモデル

化粧品有効成分の皮膚透過性(log Kp)を分子記述子から予測する機械学習モデル。
Yuan et al. (2023) のマイクロニードル透過予測研究の手法を化粧品分野に展開する。

## ディレクトリ構成
```
data/raw/               # 生データ(HuskinDB, SkinPiX, INRSの原本)
data/processed/         # 前処理済みデータセット
src/descriptors.py      # 分子記述子計算モジュール
notebooks/               # 解析ノートブック
CLAUDE.md                # プロジェクト文脈(Claude Code用)
RESEARCH_PLAN.md         # 研究計画・進捗
```

## セットアップ
```
pip install -r requirements.txt
```

## データ出典
- HuskinDB (Stepanov et al. 2020, Scientific Data)
- SkinPiX (Chedik et al. 2024, Scientific Data)
- 統合QSPRデータセット (Asgarkhanova et al. 2026, Molecular Informatics, doi:10.1002/minf.70030)
