---
title: BiG LabでTakumiができること
created: 2026-07-16
updated: 2026-07-16
status: discussion-draft
scope: Yuan氏の研究と指定4論文に基づく、最初の4週間の研究貢献候補
---

# BiG LabでTakumiができること

> **結論:** 最初の価値は、新しいbioinkを単独で設計したり、AIに臨床判断をさせたりすることではない。BiGの既存実験を、**比較可能・追跡可能・再実行可能な定量データへ変えること**である。第一候補は、Yuan氏が論文中で明示した未解決課題に沿う **Curved Corneal Construct Geometry QC** とする。

## 1. 「PIG」表記について

依頼文の「PIG」は、公開情報で確認できたUniversity of Sydneyの **Biomedical Innovation Group（BIG / このポータルではBiG）** を指すものとして整理した。対象フォルダ、既存資料、Yunong Yuan氏の所属・共同研究、公開ラボ名のいずれからも、この文脈の研究組織としての「PIG」は確認できなかったためである。

これは名称の推定であり、別のproject / groupを意味する場合は、その正式名称に合わせて文書を更新する。

## 2. 私の役割を一文で言う

**I can turn experimental images, print settings and assay outputs into traceable, reproducible evidence that helps the team compare constructs and decide the next experiment.**

日本語では、次の役割である。

> 実験画像、print条件、材料batch、assay結果を同じsample / runへ結び、研究者が次の実験を判断できるQCと解析成果物を作る。

## 3. 優先順位つき貢献候補

| 優先 | 貢献 | 具体的な成果物 | 研究上の価値 | 最初の境界 |
| --- | --- | --- | --- | --- |
| P0 | **Curved Corneal Construct Geometry QC** | radius error、local thickness、surface / chordal errorのoverlay、CSV、1ページreport | Yuan氏のcornea reviewが指摘する「形状誤差の定量報告不足」を直接埋める | 既存の承認済みOCT / scan / image、1 construct type、1–2 metrics |
| P0 | **Run-level Evidence Registry** | data dictionary、sample–run–batch対応表、unit / missingness check | 材料、光、造形、力学、細胞を同じexperimental unitへ接続 | 欠測を推測で埋めず、sourceとmeasurementを分離 |
| P1 | **Photocrosslinking Condition & Safety Matrix** | PI全成分、濃度、波長、照度、時間、dose、post-cure、assayの比較表 | 指定4論文が示す性能・細胞安全性trade-offを可視化 | 文献整理と既存metadataまで。PI・DNA assayの選定は研究者が行う |
| P1 | **Simulation–Experiment Comparison** | measured / predicted trace、residual、parameter table、validation report | Yuan氏のphysics-based workflowを再現し、model assumptionを明確化 | 小さな既存dataset、既知baseline、外挿禁止 |
| P2 | **Drug / Growth-factor Release Analysis** | release curve、burst / lag指標、model fit、condition comparison | hydrogel mechanicsとtransportをつなぐ | 十分なtime pointと研究者承認がある場合のみ |
| P2 | **Reusable Analysis Package** | versioned code、tests、config、README、method card | 次のoperator・batchでも同じ方法を再実行できる | P0 pilotがmanual referenceで検証された後 |

## 4. 第一候補 — Curved Corneal Construct Geometry QC

### 4.1 なぜこのテーマか

Yuan氏らのcornea reviewは、曲面constructについて次の定量値がsystematicに報告されていないと指摘している。[1]

- design radiusに対する実測radius error
- local wall-thickness variation
- surface roughness
- layer-by-layer造形に由来するtopographic chordal error

さらに、test domeを条件を変えて印刷し、high-resolution scanningまたはOCTで実測する案まで示している。つまり、これは外部から作った思いつきではなく、**Yuan氏自身が明記したevidence gap**である。

### 4.2 最小のresearch question

> 承認済みの既存画像またはscanから、1種類のcurved corneal constructについて、設計値に対するradiusまたはthicknessの誤差を、再実行可能な方法で測定できるか。

### 4.3 入力と出力

| 必要な入力 | 作る出力 |
| --- | --- |
| design geometryまたはnominal radius / thickness | design–measured overlay |
| raw OCT、3D scan、cross-section imageのいずれか | per-sample metric table |
| pixel / voxel calibration | calibration recordとunit check |
| sample ID、print run、bioink batch | traceable registry |
| 研究者が選んだmanual reference | error / agreement report |
| 除外ルールとprimary metric | failure examplesを含む1ページsummary |

### 4.4 成功基準

- raw dataを変更せず、processed dataと明確に分ける。
- 全metricを `sample → print run → bioink batch → method version` まで追跡できる。
- calibrationがない画像をµmへ勝手に変換せず、pixel単位または`not measurable`とする。
- 少なくとも5例、または研究者が妥当とする小規模setでmanual referenceと比較する。
- 良い例だけでなく、blur、欠損、曲面外、segmentation failureをreportに残す。
- 同じinputとversionからtable・figure・reportを再生成できる。

## 5. 第二候補 — Photocrosslinking Evidence Registry

指定4論文を統合すると、次の因果鎖で記録する必要がある。

```text
material / batch
  → initiator / wavelength / irradiance / time
  → conversion / network / geometry
  → mechanics / transparency / transport
  → viability / metabolism / phenotype / DNA damage
  → tissue function and translational claim
```

### 5.1 最低限のfield

| 区分 | 必須field |
| --- | --- |
| Identity | sample ID、print run ID、bioink batch、operator、date |
| Material | polymer / collagen type、source、lot、concentration、functionalisation、additives |
| Photochemistry | PIの全成分、各濃度、wavelength、irradiance、exposure time、post-cure |
| Printing | printer / optics、layer / voxel、temperature、design version、build orientation |
| Geometry | radius、thickness、layer continuity、design deviation、method / calibration |
| Function | transparency / refractive measurement、mechanicsのtest mode、release / permeability |
| Biology | cell type、passage、density、assay、time point、spatial region |
| Safety | viability、metabolism、phenotype、承認された場合のDNA-damage assay |
| Provenance | raw path、processed path、code version、parameter file、reviewer |

光doseは `irradiance (mW/cm²) × time (s) / 1000` で `J/cm²`へ計算する。ただし、同じdoseでも波長、PI吸収、散乱、厚さ、oxygen、kineticsが違えば同じ硬化・毒性にはならない。doseを安全性の代替指標にしない。

## 6. 最初の4週間

| 週 | 作業 | 成果物 | Go / No-go |
| --- | --- | --- | --- |
| Week 1 — Scope | Yuan氏 / supervisorと問い、experimental unit、primary metric、データ区分を固定 | 1ページcharter、data dictionary、5例のinventory | calibration、design reference、利用許可のいずれもない場合はregistry prototypeへ切替 |
| Week 2 — Baseline | 1–2例を手動で測り、loader・calibration・metricを実装 | manual reference、test data、QC overlay | manualとcodeの差の原因を説明できない場合はmetricを増やさない |
| Week 3 — Batch | 承認された小規模setへ適用し、失敗条件を分類 | metric table、failure log、condition plot | sample独立性やbatch構造が不明なら推測統計を行わない |
| Week 4 — Verify | 研究者review、再実行、method / limitationを記述 | versioned code、figure、1ページreport、next-experiment案 | reviewerがrawと照合できたらpilot完了 |

## 7. 2週間で先に見せられるもの

研究データの許可に時間がかかる場合でも、次は公開情報だけで作れる。

1. 指定4論文とYuan氏論文のrun-level data dictionary。
2. synthetic dome画像を使ったcalibration / radius metricのunit test。
3. `dose`, `unit`, `missing field`, `duplicate sample ID` のQC checker。
4. 公開論文の条件を並べたevidence matrixとmissingness heatmap。
5. 実データへ移る前のpilot charterとdata-handling checklist。

この段階では、実constructの性能や安全性について結論を出さない。

## 8. 私が判断しないこと

- PI、bioink、cell source、assayを独断で選ばない。
- wet-lab操作、human / animal sample、laser / UV、chemical handlingを訓練・監督なしで行わない。
- LIVE/DEADが高いことだけから、genotoxicityやclinical safetyを否定しない。
- 画像の見た目だけでcell phenotype、透明性、屈折、力学を推定しない。
- sample数が少ない状態で、random splitの高R²を未知材料への性能として報告しない。
- 欠測値をAIで補完して実測値のように扱わない。
- 未承認の患者情報、未公開データ、共同研究データを外部AIや公開Gitへ送らない。
- AI生成コード・figure・文章を、原データと研究者reviewなしで公開しない。

## 9. BiGに確認する最小事項

1. 今最も困っている比較はgeometry、optics、mechanics、cell、releaseのどれか。
2. 最初の4週間で使える既存データは何か。
3. experimental unitはconstruct、print run、batch、image fieldのどれか。
4. design referenceとpixel / voxel calibrationはあるか。
5. raw / processed / codeの保存場所と命名規則は何か。
6. AI・cloud・Gitへ入力可能なデータ区分は何か。
7. scientific reviewerは誰で、どの基準なら成果物を再利用するか。

## 10. 面談用30秒pitch

> I would like to start with a small, verifiable analysis rather than a broad AI project. Your cornea review identifies a clear gap in quantitative geometry reporting—radius error, wall-thickness variation, surface roughness and chordal error. If suitable OCT, scan or cross-section data already exist, I can build a traceable QC pilot around one or two of those metrics, compare it with manual references, document failure cases, and deliver reproducible code and a one-page report within four weeks. If the data are not yet available, I can first build the photocrosslinking and bioink evidence registry using approved public information.

## 11. どの資料を使うか

- **科学的根拠:** [光重合性バイオマテリアル4論文レビュー](../reviews/photopolymer-biomaterials/README.md)
- **Yuan氏の研究と直接のgap:** [Yunong Yuan氏の研究ガイド](yunong-yuan-research-guide.md)
- **役割・能力・12週間の詳細版:** [Takumiの研究貢献戦略](contribution-strategy.md)
- **参加後の学習順:** [12週間の学習・研究参加ロードマップ](learning-roadmap.md)
- **データとAIの境界:** [Claude Science安全ガイド](../website/pages/safety.html)

## 12. 根拠

1. Yuan Y, Lim KS, Sutton G, Wallace GG, You J. [3D Printing Strategies for Bioengineering Human Cornea](https://pmc.ncbi.nlm.nih.gov/articles/PMC12988584/). *Advanced Healthcare Materials*. 2026;15:e02767.
2. Huang H, Yuan Y, et al. [A New Bioprinted Dual-Layered Corneal Structure Using Collagen-Based Bioinks](https://pubmed.ncbi.nlm.nih.gov/41742708/). *Tissue Engineering Part A*. 2026.
3. Yuan Y, et al. [Principle-based multiphysics simulation for 3D bioprinting systems](https://doi.org/10.1088/1758-5090/ae6ad0). *Biofabrication*. 2026;18:032001.
4. University of Sydney. [Biomedical Innovation Group](https://www.sydney.edu.au/medicine-health/our-research/research-centres/biomedical-innovation-group.html). 2026-07-16確認。

---

この文書は正式な研究計画ではなく、面談でscope・data・reviewerを決めるためのdiscussion draftである。
