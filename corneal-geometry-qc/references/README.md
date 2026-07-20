# 参考資料索引 — Curved Corneal Construct Geometry QC

このフォルダはファイルを複製しない。既存の`big-lab/references/`と`big-lab/portfolio/`にある資料への索引のみを保持する。

## 一次文献（取得済み）

| # | 文献 | 保存場所 | 用途 |
| --- | --- | --- | --- |
| 1 | Yuan Y, Lim KS, Sutton G, Wallace GG, You J. 3D Printing Strategies for Bioengineering Human Cornea. *Advanced Healthcare Materials*. 2026;15:e02767. DOI: 10.1002/adhm.202502767 | `../../references/papers/yunong-yuan/3d-printing/08-yuan-2025-3d-printing-human-cornea.pdf` | geometry error報告不足の一次根拠。Table 3（標準測定法）、Section 3.1（curvature/chordal error）、Section 5（Outlook）を参照 |
| 2 | Yuan Y, et al. FDA Modernization Act 2.0 disease models（関連） | `../../references/papers/yunong-yuan/biomedical-research-policy/02-yuan-2023-fda-modernization-disease-models.pdf` | 背景理解のみ。geometry QCとの直接関連は低い |
| 3 | Yuan Y, et al. Machine learning for microneedled skin permeation | `../../references/papers/yunong-yuan/microneedle/03-yuan-2023-machine-learning-microneedled-skin-permeation.pdf` | small-data ML手法の参考（`drug-release-profile`と共通） |
| 4 | Yuan Y, et al. Principle-based multiphysics simulation for 3D bioprinting systems. *Biofabrication*. 2026;18:032001 | `../../references/papers/yunong-yuan/3d-printing/10-yuan-2026-multiphysics-simulation-bioprinting.pdf` | print-processシミュレーションとgeometry errorの接続を検討する際の参考（Gate 6以降） |

## 一次文献（未取得・metadata-only）

| # | 文献 | 既知の情報 | 状態 |
| --- | --- | --- | --- |
| 5 | Huang H, Yuan Y, et al. A New Bioprinted Dual-Layered Corneal Structure Using Collagen-Based Bioinks. *Tissue Engineering Part A*. 2026. | URL: https://pubmed.ncbi.nlm.nih.gov/41742708/（`docs/learning-roadmap.md`より） | PDF未取得。全文入手可否をGate 0でPIへ確認する（`requirements.md` §10-5） |

## ラボ内の戦略・背景資料

| 資料 | 場所 | 関連箇所 |
| --- | --- | --- |
| BiG LabでTakumiができること | `../../docs/contribution-map.md` | §3–4: Curved Corneal Construct Geometry QCの提案根拠、成功基準、最初の4週間 |
| Yunong Yuan氏の研究ガイド | `../../docs/yunong-yuan-research-guide.md` | L142–219: geometry gapの詳細、PIへの確認質問 |
| Takumiの研究貢献戦略 | `../../docs/contribution-strategy.md` | Geometry関連metric一覧、data acquisition tier（写真/scan vs OCT/confocal）の整理 |
| 12週間の学習・研究参加ロードマップ | `../../docs/learning-roadmap.md` | オンボーディング全体の位置づけ |

## Portfolio synthetic demo（real pilot dataではない）

| 資料 | 場所 | 注意 |
| --- | --- | --- |
| Pilot charter（demo） | `../../portfolio/pilot-charter.md` | 「portfolio demonstration」「Data: synthetic only」と明記。閾値は仮ルール |
| Synthetic QC dataset | `../../portfolio/geometry-qc-synthetic.csv` | 12 construct / 3 batchの合成データ。`synthetic_data_notice`列で明示 |
| Multi-agent run log（demo） | `../../portfolio/multi-agent-run-log.json` | "Synthetic portfolio demonstration. Not an experimental or clinical record." と明記 |
| Claim–evidence map | `../../portfolio/claim-evidence-map.csv` | Introduction〜Posterのevidence spineの型。real pilotでも同じ型を使ってよいが、内容はsyntheticのまま |
| Webサイト表現 | `../../website/pages/research-portfolio.html#geometry`, `geometry-qc-poster.html` | 上記demoのWeb/poster表現 |

## 利用ルール

- ここに列挙した論文PDFは、各`references/papers/*/README.md`に記載された入手元・利用条件に従う。再配布しない。
- Portfolio synthetic demoの数値は、UIパターンや構造の参考にはできるが、real pilotの結果や受入基準としては引用しない。
- 未取得文献（#5）は、全文入手前に断定的な内容引用をしない。
