[HTML版を開く](README.html)

# 美容有効成分の皮膚透過性QSAR/MLモデル

化粧品有効成分の皮膚透過性(log Kp)を分子記述子から予測する機械学習モデル。
Yuan et al. (2023) のマイクロニードル透過予測研究の手法を化粧品分野に展開する。

## ディレクトリ構成
```
data/raw/                # 生データ(HuskinDB, SkinPiX, INRSの原本、文献コーパス)
data/processed/          # 前処理済みデータセット
data/results/            # 解析結果CSV(能動学習シミュレーション等)
src/descriptors.py       # 分子記述子計算モジュール
src/active_learning.py   # 能動学習シミュレーション(獲得戦略・学習曲線)
figures/                  # 図表(PNG)
reports/                  # 完成済みレポート(md/html)
notebooks/                # 解析ノートブック
CLAUDE.md                 # プロジェクト文脈(Claude Code用)
RESEARCH_PLAN.md          # 研究計画・進捗
requirements.txt          # Python依存パッケージ
```

## セットアップ
```
pip install -r requirements.txt
```

## データ出典
- HuskinDB (Stepanov et al. 2020, Scientific Data)
- SkinPiX (Chedik et al. 2024, Scientific Data)
- 統合QSPRデータセット (Asgarkhanova et al. 2026, Molecular Informatics, doi:10.1002/minf.70030)
