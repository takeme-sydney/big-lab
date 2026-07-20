---
title: Yunong Yuan氏の研究ガイド
created: 2026-07-16
updated: 2026-07-16
status: public-source-research-brief
scope: 公開一次資料で確認できた研究成果、論文要約、PDF取得状況、BiG Labでの接点
---

[HTML版を開く](../website/pages/intern-yunong-yuan.html)

# Yunong Yuan氏の研究ガイド

> **結論:** Yuan氏の研究は、材料押出時の熱・結晶化を説明する**物理モデル**から始まり、皮膚・ハイドロゲル中の**拡散予測**、データが少ない状況での**機械学習**、そして**角膜バイオプリンティング**へ発展している。一貫しているのは、実験だけ・計算だけで完結させず、**材料・プロセス・形状・生物機能を測定可能なモデルへ結ぶ姿勢**である。

この文書は `yunong.yuan@sydney.edu.au` と、論文に記載された所属・[ORCID `0000-0003-1470-6541`](https://orcid.org/0000-0003-1470-6541) を照合し、2026年7月16日までに公開一次資料で本人確認できた研究を整理した。完全なCVではなく、公開データベースの更新遅れや未索引論文があり得る。

## 1. 研究者像を30秒で理解する

2025年公開の著者略歴では、Yuan氏はUniversity of Sydneyのpostdoctoral researcherで、Aircraft Power Engineeringの学士、University of ManchesterのMaterials Science MPhil、University of SydneyのPharmacy PhD（2025）を経ている。研究関心は3D printing、biomaterials、tissue engineering、regenerative medicine、simulation、machine learningと記載されている。[1]

| 観点 | 読み取れる特徴 | 根拠となる研究 |
| --- | --- | --- |
| 物理を出発点にする | 熱伝達、結晶成長、Fick拡散、流体・光・力学を方程式で扱う | PLA熱・結晶化、酸素縫合糸、vancomycin放出、multiphysics review |
| 実験でモデルを閉じる | 予測値を温度測定、microelectrode、透過試験、in vivo結果と比較する | 2020、2023、2024の原著 |
| 小規模データの限界を明記する | MLの精度だけでなく、未知drugへの外挿失敗とデータ偏りを報告する | microneedle–skin ML論文 |
| 臨床課題から評価項目を逆算する | 角膜では透明性だけでなく、曲率、厚さ、屈折、力学、酸素・栄養透過を要求する | cornea strategy review |
| 標準化を重視する | 条件・形状誤差・生物評価の報告不足を、比較不能の原因として扱う | cornea review、multiphysics review、薬剤3D printing review |

## 2. 研究の発展を一本の線で見る

```text
2019–2020  PLA押出の熱・結晶化
     ↓     物理則 + domain discretisation + 実測検証
2022       3D printed dosage formと薬局実装
     ↓     個別化、品質管理、規制、非破壊評価
2023–2024  皮膚・酸素・薬物送達
     ↓     Fick拡散 + ML + hydrogel + in vivo proof of concept
2024       biomaterialと3D disease model
     ↓     sericin、bioprinted drug-testing model、非動物モデル
2025–2026  human cornea bioengineering
     ↓     collagen、曲率、多層構造、光学、細胞、標準化
2026       principle-based multiphysics
           inkjet・extrusion・DLPを物理モデルとMLで統合
```

`[統合]` 分野が移ったように見えても、研究上の主語は同じである。**「加工条件が、材料内部の物理現象を通じて、最終的な機能へどう伝わるか」**を、実験と計算で追っている。

## 3. 公開研究成果とPDF取得状況

### 3.1 学位論文

| 年 | 成果 | 内容 | ローカル資料 |
| --- | --- | --- | --- |
| 2019 | *Modelling of Temperature Evolution and Crystal Growth in Additive Manufacturing of PLA*（MPhil thesis）[2] | 2D domain discretisationとHoffman–Lauritzen理論で、PLA押出時の温度・結晶化をモデル化。2020年論文の基盤となる詳細版。 | [PDF](../references/papers/yunong-yuan/3d-printing/00-yuan-2019-mphil-thesis-temperature-crystal-growth.pdf) |

### 3.2 論文・レビュー

公開一次資料で本人確認できたjournal article / reviewは12本である。ORCIDには2026年7月16日時点でそのうち9本が登録され、2025–2026年の角膜関連3本は出版社側で確認した。これは公開記録の照合結果であり、公式CVの代替ではない。

| 年 | 論文 | 種別・Yuan氏の位置 | 一文要約 | PDF / 本文状況 |
| --- | --- | --- | --- | --- |
| 2020 | [Prediction of temperature and crystal growth evolution during 3D printing of polymeric materials via extrusion](https://doi.org/10.1016/j.matdes.2020.109121) [3] | 原著・first author | 2D熱モデルと結晶成長理論を結び、single-lineの温度を最大3.8 °C、full scale比2%以内のずれで予測。 | 出版社PDFは自動取得不可。上記MPhil thesisを保存 |
| 2022 | [Recent progress in three-dimensionally-printed dosage forms from a pharmacist perspective](https://doi.org/10.1093/jpp/rgab168) [4] | review・coauthor | 個別用量、複数薬、release制御、調剤薬局、品質・規制を薬剤師の視点で整理。 | [公式全文HTML](https://academic.oup.com/jpp/article/74/10/1367/6534282)、PDF未保存 |
| 2023 | [Prediction of drug permeation through microneedled skin by machine learning](https://doi.org/10.1002/btm2.10512) [5] | 原著・first author | Fick、MLR、RF、XGBoostを比較し、既知drug内ではXGBoostが最良。ただし未知drugへの外挿に失敗。 | [PDF](../references/papers/yunong-yuan/microneedle/03-yuan-2023-machine-learning-microneedled-skin-permeation.pdf) |
| 2023 | [Oxygen Penetration Through Full-Thickness Skin by Oxygen-Releasing Sutures](https://doi.org/10.1016/j.eng.2023.05.006) [6] | 原著・co-first author | 二層hydrogel縫合糸で深部へ酸素を送り、model、細胞、マウス皮膚移植で検証。 | [PDF](../references/papers/yunong-yuan/biomaterials/04-yuan-2023-oxygen-releasing-sutures-skin-graft.pdf) |
| 2023 | [Implications on the Development of Animal Disease Models from FDA Modernization Act 2.0](https://doi.org/10.12300/j.issn.1674-5817.2023.083) [7] | frontier review・coauthor | cell culture、organoid、organ-on-chip、3D bioprinting、computer modelの役割と、動物モデルとの組合せを整理。 | [PDF](../references/papers/yunong-yuan/biomedical-research-policy/02-yuan-2023-fda-modernization-disease-models.pdf) |
| 2024 | [Controlled release of vancomycin from PF-PEGDA hydrogel](https://doi.org/10.1016/j.bioadv.2024.213896) [8] | 原著・co-first author | gel stiffnessと拡散係数のpower-law関係を示し、drug loading・厚さ・硬さからreleaseを予測。 | [公式全文HTML](https://www.sciencedirect.com/science/article/pii/S2772950824001390)、PDF未保存 |
| 2024 | [Recent applications of 3D bioprinting in drug discovery and development](https://doi.org/10.1016/j.addr.2024.115456) [9] | review・coauthor | target selectionからlead、preclinicalまでの3D bioprinted modelを整理。臨床試験での実利用はまだ未報告。 | [PubMed](https://pubmed.ncbi.nlm.nih.gov/39306280/)、出版社PDF未保存 |
| 2024 | [Sericin coats of silk fibres, a degumming waste or future material?](https://doi.org/10.1016/j.mtbio.2024.101306) [10] | review・first author | 廃棄物扱いだったsericinを、分子量・抽出法・機能・hydrogel/printing用途から再評価。 | [PDF](../references/papers/yunong-yuan/biomaterials/07-yuan-2024-sericin-coats-silk-fibres.pdf) |
| 2025 online / 2026 issue | [3D Printing Strategies for Bioengineering Human Cornea](https://doi.org/10.1002/adhm.202502767) [1] | review・first / corresponding author | 角膜固有の曲率、異方性、透明性、力学、屈折、透過性を満たすprinting strategyを比較。 | [PDF](../references/papers/yunong-yuan/3d-printing/08-yuan-2025-3d-printing-human-cornea.pdf) |
| 2026 | [A New Bioprinted Dual-Layered Corneal Structure Using Collagen-Based Bioinks](https://doi.org/10.1177/19373341261424272) [11] | 原著・second author | Col-I stroma + Col-IV-supported endotheliumを曲面支持体へ印刷し、3週間、曲率・透明性・界面を保持。 | 公式abstractは公開、本文PDFは購読制限のため未保存 |
| 2026 | [Principle-based multiphysics simulation for 3D bioprinting systems](https://doi.org/10.1088/1758-5090/ae6ad0) [12] | review・first author | inkjet、extrusion、DLPを、流体・熱・光・力学・輸送の理論モデルで整理し、hybrid physics–MLを提案。 | [PDF](../references/papers/yunong-yuan/3d-printing/10-yuan-2026-multiphysics-simulation-bioprinting.pdf) |
| 2026 | [Advances in Differentiation of iPSC-Derived Corneal Endothelial Cells](https://doi.org/10.1016/j.ajpath.2026.03.017) [13] | review・coauthor / corresponding author | TGF-β、BMP、WNT等の分化経路と、研究用・臨床用characterizationの差を比較。 | [公式全文HTML](https://www.sciencedirect.com/science/article/pii/S0002944026001252)、PDF未保存 |

> **取得上の注意:** 「PDF未保存」は論文が存在しないという意味ではない。出版社のbot対策、購読制限、またはPDF endpointの制約により、合法的な公開PDFを自動取得できなかったものを示す。University of Sydney Libraryの認証、出版社のDownload PDF、または著者へのrequestで確認する。

## 4. 最重要論文を深く読む

### 4.1 熱・結晶化モデル — 研究スタイルの原点

**問い:** material extrusion中のPLAは、どのように冷却・再加熱され、結晶化するか。

**方法:** 印刷線を2D要素へ分割し、熱伝達のboundary conditionとHoffman–Lauritzen crystal-growth theoryを結合した。single-lineとmulti-lineを扱い、thermal cameraおよび既報データで検証した。

**結果:** 2020年論文ではsingle-line予測の最大ずれが3.8 °C、full scale比2%だった。MPhil thesisの2×2 multi-line解析では、後続線による再加熱で結晶化可能時間が延び、single-lineより最終結晶化率が約10倍になった。convection coefficient、platformとのthermal contact、nozzle diameterの影響が大きかった。[2][3]

**限界:** platform・air温度、流れ、形状、核生成等を単純化しており、複雑形状や材料へそのまま移せない。

**重要な読み方:** 高精度な数字そのものより、`process parameter → local temperature history → material structure → product quality` という因果鎖が、その後の研究でも使われ続けている点が重要である。

### 4.2 Microneedle × machine learning — 精度と外挿を分ける

**問い:** 時間と費用がかかるin vitro skin permeation testを、どこまで予測で補えるか。

**方法:** 6種のdrug/chemicalとhuman/rat skin、plastic/hydrogel microneedleの既存実験を統合し、Fick’s law、multiple linear regression、random forest、XGBoostを比較した。train/testは7:3に分割した。

| 予測対象 | XGBoost | Random Forest | Fick | MLR |
| --- | ---: | ---: | ---: | ---: |
| permeation amount RMSE（µg） | **4,447.23** | 7,043.97 | 6,778.17 | 23,398.91 |
| permeation amount R² | **0.98** | 0.95 | 0.95 | 0.46 |
| permeation percentage RMSE（%） | **28.24** | 34.33 | 85.58 | 120.33 |
| permeation percentage R² | **0.98** | 0.97 | 0.82 | 0.65 |

**結果:** 既知drugを含む分割ではXGBoostが最良で、drug loading、permeation time、microneedle surface areaが主要featureだった。[5]

**最重要の限界:** 一つのdrugを丸ごとtraining setから外すleave-one-drug-out型の確認では大きく外れた。小規模・不均衡データでは、通常のrandom splitのR²が高くても、**未知材料・未知drugへ一般化できるとは限らない**。

**Yuan氏の担当:** CRediTではformal analysis、investigation、methodology、softwareがleadで、validation・visualization・writingも担当した。Yuan氏の計算・解析能力を最も直接的に確認できる原著である。

### 4.3 Oxygen-releasing suture — modelをdeviceとin vivoへつなぐ

**問い:** 酸素が通りにくいfull-thickness skin graftの深部へ、表面からではなく縫合糸に沿って酸素を届けられるか。

**方法:** 内層のCaO₂がH₂O₂を作り、外層のcatalaseがO₂へ変換する二層hydrogel-coated sutureを設計した。microelectrode測定、Fick’s second lawの2D simulation、極低酸素下のendothelial cell、マウスskin graftで評価した。

**結果:** skin modelの深さ15 mmでtopical gaseous oxygenより100倍多い酸素を供給し、極低酸素下のendothelial cell proliferationを促進した。マウスではblood reperfusionとgraft survival areaが改善した。[6]

**限界:** modelはconstant diffusion coefficient等を仮定する。gel modelから実皮膚への換算、縫合間隔、大きなgraft、長期安全性は追加検証が必要である。

**重要な読み方:** `material design → diffusion model → cell response → animal outcome` を同じ問いへ接続したtranslational workflowの例である。

### 4.4 Vancomycin hydrogel — mechanicsとreleaseを結ぶ

**問い:** PF-PEGDA hydrogelの硬さ・厚さ・loading方法からvancomycin releaseを予測できるか。

**結果:** softer hydrogelほどdiffusion coefficientが大きいpower-law関係を報告した。gel内loadingはburst release、blank gel上にsolutionを置く構成はlag releaseとなり、数理モデルでdrug loading、gel thickness、stiffnessによるreleaseのcustomizationを扱った。rabbit median sternotomyのproof of conceptではosteogenic processの開始が早まった。[8]

**意味:** 力学特性を単なる強度として扱わず、mesh・diffusion・dose profileへ接続している。指定4論文中のcollagen + growth factor reviewとも強くつながる。

### 4.5 Sericin review — 原料名より履歴を記録する

**問い:** silk fibroinのdegumming wasteとされてきたsericinを、再生医療・drug delivery・energy・sensor等へ使うには何を管理すべきか。

**要点:** sericinはcocoon massの約20–30%で、antioxidant、biocompatibility、low immunogenicity、controlled biodegradation等が報告される。一方、抽出温度・pH・圧力でmolecular weightと鎖構造が変わり、それがviscosity、β-sheet、mechanics、bioactivity、加工性を変える。[10]

**限界:** sustainable / scalable extraction、弱い力学、animal origin、抽出時分解、限られたclinical trialが課題である。抗菌性の由来もsericin自体か不純物かで議論が残る。

**重要な読み方:** `sericin` という材料名だけでは再現性がない。source、layer、extraction、MW、functionalisation、batchを同じ材料identityとして残す必要がある。

### 4.6 Human cornea strategy review — BiGとの直接接点

**中心質問:** 3D printingでbioengineered human corneaを作ることは可能か。

**回答:** 技術的可能性は高まっているが、単に透明なcell-laden domeを作るだけでは不十分である。native corneaのmultilayer、collagen anisotropy、curvature、mechanics、refractive index/power、oxygen/nutrient permeabilityを同時に満たす必要がある。[1]

**重要なgap:** 公開研究は形状を示しても、design radiusやwall thicknessからの実測誤差をsystematicに報告していない。論文は、test domeを印刷し、high-resolution scanまたはOCTで次を測る案を具体的に示している。

- radius error
- local wall-thickness variation
- surface roughness
- topographic chordal error

さらに、mechanics、transparency、refractive index / power、permeabilityを含む標準characterization protocolを提案している。これはTakumiが最初に担えるQC pilotとほぼ一致する。

### 4.7 Dual-layer cornea — reviewの要求を実物へ近づける

**構成:** type I collagen中のcorneal stromal cellsと、type IV collagenで支えたcorneal endothelial monolayerを、native posterior curvatureを模した曲面支持体へbioprintした。[11]

**結果:** cell viabilityは90%超で、明確な二層と連続したendothelial layerを形成した。3週間の培養中、curvature、transparency、interfacial integrityを保持し、ex vivo corneal tissue上でadherenceを示した。

**読み方:** donor不足を直ちに解決する移植片の完成報告ではなく、stromal–endothelial architectureと相互作用を調べるphysiologically relevant in vitro modelである。次の課題は、定量geometry、optics、mechanics、permeability、長期functionの標準評価である。

### 4.8 Multiphysics review — 今後の計算研究の設計図

**範囲:** dot（inkjet）、line（material extrusion）、face（DLP）の3方式を、theory-based numerical simulationで比較する。[12]

| 現在の制約 | 論文が示す方向 |
| --- | --- |
| Newtonian前提、実測rheology不足 | Herschel–Bulkley / Carreau–Yasuda、温度・shear依存粘度を導入 |
| flow、heat、light、curingを別々に計算 | multiphysics couplingとpolymerisation / diffusion parameterを統合 |
| cell-ladenでもinert materialとして扱う | cell mechanics、nutrient / oxygen transport、viability dataと結合 |
| 2D・単純geometry | adaptive mesh、voxel / lattice-resolved model、topology optimization |
| 計算負荷が大きい | physics-based solver + ML surrogate / digital twin |
| benchmarkと定量検証がない | open dataset、in situ imaging、standardized validation |

**中心的な判断:** MLは複雑データに強いが、少量・不均衡データとoverfittingに弱い。physics-based modelは解釈可能でdata-efficientだが、仮定と計算負荷を持つ。したがって二者択一ではなく、**physicsで制約したhybrid model**が有望である。

### 4.9 iPSC-derived corneal endothelial cells — 造形後の「細胞の正しさ」

このreviewは、donor不足に対するrenewable cell sourceとしてiPSC-derived corneal endothelial cellを扱い、TGF-β、BMP、WNT等のpathwayとcharacterization practiceを比較する。[13]

BiGとの接点は、印刷形状が正しいだけでなく、endothelial identityとfunctionをどのmarker・morphology・pump/barrier evidenceで証明するかにある。protocol間のefficiencyとreproducibilityが大きく、research markerとclinical standardを分けて評価する必要がある。

## 5. Yuan氏の研究を表す重要フレーズ

以下は逐語引用ではなく、論文の主張を日本語で短く言い換えたものである。

| 重要フレーズ | 意味 | Takumiへの示唆 |
| --- | --- | --- |
| **加工履歴が材料機能を決める** | 温度、光、shear、diffusionの履歴がstructureとfunctionへ伝わる | 最終値だけでなくrun-level conditionを残す |
| **modelは実験を置き換えるのでなく、絞り込む** | costly experimentの前にparameter sensitivityと候補を評価する | 予測値にはvalidation statusを付ける |
| **random splitの高精度は外挿能力ではない** | 既知drug内R²と未知drug predictionは別問題 | batch / material単位でhold-outを設計する |
| **material nameだけでは再現できない** | extraction、MW、batch、functionalisationが性質を変える | bioink identity schemaを作る |
| **角膜は透明なhydrogel以上のもの** | 曲率、異方性、屈折、力学、透過、細胞機能が必要 | geometryとopticsを同一sampleで測る |
| **形状誤差を定量報告する** | radius、thickness、roughness、chordal errorが不足 | OCT / scan用のQC pipelineをpilotにする |
| **physicsとMLは補完関係** | theoryの解釈性とMLの速度・非線形性を組み合わせる | 小規模データではhybrid / surrogateを優先 |
| **標準化がtranslationの前提** | study間で条件と評価が揃わないと比較・規制対応できない | data dictionary、unit check、provenanceを先に作る |

## 6. 指定4論文との接続

| 指定論文 | Yuan氏の研究との接続 |
| --- | --- |
| Yu et al. — materials × light-based printing | Yuan氏のDLP simulationとcornea reviewが、材料・光・geometryの相互依存を角膜へ具体化 |
| Bao — advanced photoinitiators | visible / NIR、multi-component PIの性能と安全性を、DLP modelとevidence registryへ接続可能 |
| Lee et al. — cyto/genotoxicity | dual-layer corneaの高viabilityを重要な第一段階としつつ、viabilityだけで安全を断定しない評価設計が必要 |
| Sarrigiannidis et al. — collagen mechanics / GF | Col-I / Col-IV、hydrogel stiffness–diffusion、release modelが、力学・輸送・細胞機能の統合課題へ直結 |

## 7. 最初に読む順番

1. **3D Printing Strategies for Bioengineering Human Cornea** — 現在の直接テーマと未解決metricを把握する。
2. **A New Bioprinted Dual-Layered Corneal Structure** — BiGが実際に構築した曲面・多層modelをabstractから理解する。
3. **Principle-based multiphysics simulation** — 物理モデル、ML、validationの全体像を得る。
4. **Microneedled skin ML** — Yuan氏本人の解析実装と、外挿限界の扱いを読む。
5. **指定4論文review** — photochemistry、安全性、collagenの設計変数を補う。

時間が30分しかない場合は、cornea reviewのAbstract、Discussionのgeometry gap、Conclusion、dual-layer paperのAbstractを優先する。

## 8. 面談で使える質問

1. *Your cornea review proposes radius error, wall-thickness variation, surface roughness and chordal error. Which one is currently hardest to measure reproducibly in the lab?*
2. *Would a first pilot be more useful as an OCT/scan geometry-QC workflow, or as a run-level registry linking bioink and photocrosslinking conditions to outcomes?*
3. *For the dual-layer construct, what is the current experimental unit: print run, construct, region, or image field?*
4. *Which existing dataset can be used without creating new wet-lab work, and what are its sharing and AI-use restrictions?*
5. *For a hybrid physics–ML model, which variables are measured directly and which are currently estimated?*
6. *What result after four weeks would make you trust and reuse the analysis?*

## 9. 出典と調査範囲

1. Yuan Y, Lim KS, Sutton G, Wallace GG, You J. [3D Printing Strategies for Bioengineering Human Cornea](https://pmc.ncbi.nlm.nih.gov/articles/PMC12988584/). *Advanced Healthcare Materials*. 2026;15:e02767. 著者略歴とcornea review本文。
2. Yuan Y. [Modelling of Temperature Evolution and Crystal Growth in Additive Manufacturing of PLA](https://research.manchester.ac.uk/en/studentTheses/modelling-of-temperature-evolution-and-crystal-growth-in-additive). MPhil thesis, University of Manchester, 2019.
3. Yuan Y, et al. [Prediction of Temperature and Crystal Growth Evolution during 3D Printing of Polymeric Materials via Extrusion](https://research.manchester.ac.uk/en/publications/prediction-of-temperature-and-crystal-growth-evolution-during-3d-/). *Materials & Design*. 2020;196:109121.
4. Anwar-Fadzil AF, et al. [Recent progress in three-dimensionally-printed dosage forms from a pharmacist perspective](https://academic.oup.com/jpp/article/74/10/1367/6534282). *J Pharm Pharmacol*. 2022;74:1367–1390.
5. Yuan Y, et al. [Prediction of drug permeation through microneedled skin by machine learning](https://pmc.ncbi.nlm.nih.gov/articles/PMC10658566/). *Bioeng Transl Med*. 2023;8:e10512.
6. Zai W, Yuan Y, et al. [Oxygen Penetration Through Full-Thickness Skin by Oxygen-Releasing Sutures](https://www.engineering.org.cn/engi/EN/1159860456275894549). *Engineering*. 2023;29:83–94.
7. Wan Y, Gu Y, Yuan Y, et al. [FDA Modernization Act 2.0 and disease models](https://www.slarc.org.cn/dwyx/CN/10.12300/j.issn.1674-5817.2023.083). *Laboratory Animal and Comparative Medicine*. 2023;43:472–481.
8. Nguyen D-V, Yuan Y, et al. [Controlled release of vancomycin from PF-PEGDA hydrogel](https://www.sciencedirect.com/science/article/pii/S2772950824001390). *Biomaterials Advances*. 2024;161:213896.
9. Yang K, et al. [Recent applications of 3D bioprinting in drug discovery and development](https://pubmed.ncbi.nlm.nih.gov/39306280/). *Advanced Drug Delivery Reviews*. 2024;214:115456.
10. Yuan Y, et al. [Sericin coats of silk fibres, a degumming waste or future material?](https://pmc.ncbi.nlm.nih.gov/articles/PMC11554926/). *Materials Today Bio*. 2024;29:101306.
11. Huang H, Yuan Y, et al. [A New Bioprinted Dual-Layered Corneal Structure Using Collagen-Based Bioinks](https://pubmed.ncbi.nlm.nih.gov/41742708/). *Tissue Engineering Part A*. 2026. Online ahead of print.
12. Yuan Y, et al. [Principle-based multiphysics simulation for 3D bioprinting systems](https://doi.org/10.1088/1758-5090/ae6ad0). *Biofabrication*. 2026;18:032001.
13. Lin A, Yuan Y, et al. [Advances in Differentiation of iPSC-Derived Corneal Endothelial Cells](https://www.sciencedirect.com/science/article/pii/S0002944026001252). *The American Journal of Pathology*. 2026. In press.

### 調査上の限界

- 本人同定には、氏名だけでなく所属、email、ORCID、共著者、研究テーマを照合した。
- 数値はfull textを取得できた論文、または出版社・repositoryの公式abstractに限定した。
- 引用数、h-index、ランキング等は研究内容の理解に不要で、変動しやすいため採用していない。
- PDFを取得できなかった論文の本文を、第三者サイトから無断で複製していない。

---

**PDF索引:** [references/papers/yunong-yuan/README.md](../references/papers/yunong-yuan/README.md)  
**指定4論文レビュー:** [reviews/photopolymer-biomaterials/README.md](../../photopolymer-biomaterials/review/README.md)  
**BiGでの貢献案:** [contribution-map.md](contribution-map.md)
