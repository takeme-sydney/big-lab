[HTML版を開く](README.html)

# Curved Corneal Construct Geometry QC Research

更新日: 2026-07-19
状態: 研究計画ドラフト / PI・指導者レビュー前

## Start here

1. 研究ロードマップHTML: [`site/index.html`](site/index.html)
2. 要件定義: [`requirements.md`](requirements.md)
3. 実行用指示文: [`implementation-prompt.md`](implementation-prompt.md)
4. 参考資料索引: [`references/README.md`](references/README.md)
5. 研究計画テンプレート: [`templates/study-charter.md`](templates/study-charter.md)
6. 解析計画テンプレート: [`templates/analysis-plan.md`](templates/analysis-plan.md)
7. 意思決定log: [`notes/decision-log.md`](notes/decision-log.md)

## 研究の中心

このプロジェクトでは、次の3つを別の測定対象として扱う。

1. **Geometry error:** design/nominal geometryに対する実測構造体の偏差（radius deviation、wall-thickness variation、surface roughness、topographic chordal error、volume change、shrinkage rate、interlayer misalignment）
2. **Print-process traceability:** fabrication strategy、layer厚、slice angle、overhang角度、support方式、material/bioink batchなど、geometry errorを説明しうる要因
3. **Extended characterization（将来scope）:** Young's modulus、transparency、refractive index/power、corneal permeabilityなど、Yuan et al. (2026)が標準化を求める特性

Yuan et al. (2026) "3D Printing Strategies for Bioengineering Human Cornea" は、公開されている33の3D printed cornea研究を横断reviewし、**design radiusやwall thicknessからの実測誤差が系統的に報告されていない**ことを明示的なevidence gapとして指摘している。このプロジェクトは、そのgapを埋める最初のpilotを、既存のsynthetic demoポートフォリオの次段階として計画する。

## 既存のsynthetic demoとの違い（重要）

`portfolio/`と`website/pages/research-portfolio.html`には、同じテーマの**完全にsynthetic（架空）なcapability demonstration**が既に存在する。これは求職・面談用のportfolio pieceであり、実験データでも、PIが承認した研究計画でもない。

このフォルダ（`corneal-geometry-qc/`）は、real data・real PI承認を前提とした**研究計画そのもの**を扱う。synthetic demoの数値（例: `±0.18mm`のQC閾値）は参考にはするが、real pilotの受入基準としては転用しない。詳細は[`requirements.md`](requirements.md) §0.1を参照する。

## フォルダ構成

```text
corneal-geometry-qc/
├── README.md
├── requirements.md
├── implementation-prompt.md
├── references/
│   └── README.md         # 既存references/papers・portfolioへの索引（ファイルは複製しない）
├── templates/             # charter、data dictionary、imaging sampling plan、construct log、解析計画
├── notes/                 # 研究判断を残すdecision log
└── site/                  # standalone HTMLと専用asset
```

`site/`は、drug-release-profile roadmap（`../drug-release-profile/site/`）と同じ構造・品質水準のstandalone local siteとして実装する。

## 利用上の境界

- 3D printer、OCT、surface scanner等の機器利用、材料取り扱い、画像・scanデータの利用許可は、ラボSOP、PI承認、training、該当する機関ルールを優先する。
- Yuan et al. (2026)はreview論文であり、特定の測定・印刷手法の優劣を実証した一次研究ではない。引用は同論文が実際に述べた範囲（gap指摘、Table 3の測定法整理）に限定する。
- geometry QCの結果だけから、力学・光学・透過性・生物学的機能・臨床適合性を主張しない。
- synthetic demo（`portfolio/`）の結果を、実験的knowledgeとして引用・再利用しない。
- 既存の購読資料・論文PDFは個人研究利用の範囲を守り、再配布しない。
