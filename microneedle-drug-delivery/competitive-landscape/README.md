[HTML版を開く](README.html)

# Microneedle ML 競合・関連研究マップ

更新日: 2026-07-20
状態: deep-research結果の統合ドラフト作成中 / PI・指導者レビュー前

## Start here

1. 要件定義: [`requirements.md`](requirements.md)
2. 実行用指示文: [`implementation-prompt.md`](implementation-prompt.md)
3. 競合・関連研究マップ本体: [`competitive-landscape.md`](competitive-landscape.md)
4. 判断記録: [`notes/decision-log.md`](notes/decision-log.md)
5. 比較対象のプロジェクト: [`../research/`](../research/)
6. 関連する論文ドラフト(別ブランチ・別PR): `../small-data-ml-paper/`

## このモジュールの位置づけ

`microneedle-drug-delivery/research/` で進めているsmall-data MLアプローチについて、deep-researchハーネス(6検索角度、26件一次資料取得、113件の主張抽出、25件をadversarial verificationで検証)による競合・関連研究調査を行い、その結果を`research/`プロジェクトの計画に反映するためのギャップ分析文書。

**最重要の発見**: CNRS-Strasbourg/INRSのグループ(Asgarkhanova et al. 2026, *Molecular Informatics*, doi:10.1002/minf.70030)が、本プロジェクトが使用しているHuskinDB+SkinPiX+INRS統合データセットと実質的に同一組成のデータセットで既にQSPRモデルを発表していることが判明した。詳細は[`competitive-landscape.md`](competitive-landscape.md) §4。

## 執筆パイプライン

1. Claude Sonnet 5 — deep-researchハーネスを実行し、結果を基に`competitive-landscape.md`を起草。`research/RESEARCH_PLAN.md`・`research/CLAUDE.md`への具体的な追記も直接実施
2. Claude Fable 5 — 起草内容をレビューし、未解決の問いについて追加調査を行い、仕上げる

## フォルダ構成

```text
competitive-landscape/
├── README.md
├── requirements.md
├── implementation-prompt.md
├── competitive-landscape.md   # 競合・関連研究マップ本体
└── notes/
    └── decision-log.md        # 調査・レビューの経緯と主要判断
```

## 利用上の境界

- `../small-data-ml-paper/`(別ブランチ・別PR)のファイルは編集しない。影響がある場合は`competitive-landscape.md` §11で言及するに留める。
- confidenceの低い主張・棄却済みの主張を確認済みの事実として書かない。
- 実在しないDOI・URLを作らない。
