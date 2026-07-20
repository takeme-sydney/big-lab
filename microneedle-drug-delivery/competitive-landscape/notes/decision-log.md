[HTML版を開く](decision-log.html)

# 判断記録 — competitive-landscape

## 2026-07-20: deep-research調査の実行とスコープ

**決定**: 「競合サービス」の比較対象を「microneedle ML予測アプローチそのもの」とした
(ユーザー指定)。big-lab全体のWebサイト/ポータルツールとの比較ではない。

**実施**: deep-researchハーネスを実行(6検索角度、26件一次資料取得、113件の主張抽出、
25件を3票制adversarial verificationで検証 — 15件確認・10件棄却)。所要: 約70分、
109エージェント呼び出し、約437万トークン。

## 2026-07-20: 最重要発見とその扱い

**発見**: CNRS-Strasbourg/INRSのグループ(Asgarkhanova et al. 2026, *Molecular
Informatics*, doi:10.1002/minf.70030)が、本プロジェクトのHuskinDB+SkinPiX+INRS
統合データセット(214化合物)と実質的に同一組成(209化合物、HuskinDB129+SkinPiX103+
INRS3)のデータセットで既にQSPRモデルを発表している。本文は購読制(HTTP 403、
Unpaywallでも確認)のため手法・性能指標は不明。

**判断**: この発見は`research/CLAUDE.md`が最初から「統合QSPRデータセット」の出典として
Asgarkhanova et al.のデータリポジトリ(doi:10.57745/ZUU1DH)を引用していたことと
整合する — つまり本プロジェクトは元々この関係性を知っていたが、その論文自体が
QSPRモデリングを行っていることまでは明示的に認識・記録していなかった可能性が高い。
`RESEARCH_PLAN.md`と`CLAUDE.md`に、データセットの出典表現を正確化する注記を追加した。

**Task 1 (`small-data-ml-paper`, PR #1) への影響**: 別ブランチ・別PRのため、
このタスクでは`small-data-ml-paper/paper.md`を直接編集していない。
`competitive-landscape.md` §11 に、ユーザーへの推奨事項として記録した。

## (このセクションは各ステージ完了時に追記される)
