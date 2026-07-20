---
title: マイクロニードル薬物送達 × Small-data Machine Learning
description: Yunong Yuan氏から共有された5文献の取得状況、4全文の日本語要約、横断的な批判的統合、次の研究設計案。加えて、初めてこのテーマに触れる読者向けの基礎知識、論文評価チェックリスト、用語集を収録。
created: 2026-07-17
updated: 2026-07-18
status: literature-review-and-research-design-draft
scope: 共有された5文献（全文4本、metadata-only 1本）に加え、分野の基礎知識・用語集・評価チェックリスト
---

# マイクロニードル薬物送達 × Small-data Machine Learning

## 共有5文献の要約と、次の研究設計

> **結論:** Yunong Yuan氏らの2023年研究は、マイクロニードル処理皮膚の薬物透過を機械学習で予測できることを示した重要なproof-of-conceptである。一方、191点は6薬物の経時観測を含む小規模データで、ランダムな時点分割では未知薬物への一般化を十分に検証できない。次の論文では、**物理モデル + uncertainty-aware ML + curve/run単位の外部検証 + active learning**へ進めるのが最も筋がよい。

この文書の `[論文]` は本文に記載された内容、`[統合]` は4本を横断した批判的解釈、`[提案]` は次の研究として議論する案、`[基礎]` は特定の論文への批評ではなく分野で広く共有されている教科書的な背景知識を示す。共有された5リンクを対象とし、5本目は全文未取得のため書誌情報以上を推測していない。`[基礎]` の記述は主に[2]の全文と、pharmacokinetics / MLの一般知識に基づく（出典の詳細は13章）。

> 初めてこのテーマに触れる場合は、先に[0. この分野を初めて読む人のための基礎知識](#foundations)を読むと、1章以降の批評的な内容を理解しやすい。

## 0. この分野を初めて読む人のための基礎知識 {#foundations}

### 0.1 なぜ針を刺さずに「刺す」のか — 経皮送達の壁 [基礎][2]

皮膚の最外層である角層（stratum corneum）は、死んだ角化細胞が15-20層重なった、厚さ約10-40µmのバリアである。角層は皮膚の中で最も硬く（弾性率 約3.5-1,000 MPa）、電気抵抗も最も高い（>10^5 Ω）。分子量が大きい、または親水性が高い薬物ほどこのバリアを通過しにくく、それが経皮吸収製剤の設計を難しくしてきた。

マイクロニードル（MN）は、数十〜数千µmの高さを持つ微小な針をパッチ状に配列し、角層だけを機械的に迂回する。角層とその下のviable epidermisを合わせた表皮全体は約100-150µmで血管を持たず、血管・リンパ管・神経が豊富なdermis（真皮）はさらに深部にある。MNの長さを適切に設計すれば、dermis深部の太い血管や神経までは届かせずに角層を突破できるため、注射針より低侵襲・低疼痛でありながら、貼付剤よりも高い透過性を持つとされる。

### 0.2 5つの基本構造と、薬物がどこにあり、どう放出されるか [基礎][2]

Zheng et al. (2024) はMNを次の5構造に分類している。同じ「マイクロニードル」でも、薬物の場所と放出機構は構造ごとに大きく異なるため、これを区別しないまま「マイクロニードルの効果」を語ると論点がずれる。

| 構造 | 薬物の場所 | 放出・送達の機構 | 典型的な使われ方 |
| --- | --- | --- | --- |
| Solid | 針自体は薬物を持たないか、表面をコーティング（coated MN） | 皮膚を穿孔して透過経路を作る（poke-and-patch）。coated MNは皮膚内でコーティングが溶解・剥離して放出 | 角層の前処理、少量・高力価薬物やワクチンの送達 |
| Hollow | 針内部が中空 | 薬液を注入する、または陰圧・電気浸透流で体液を吸引する（micro-syringeに近い） | 溶液・懸濁液の能動的送達、ISF・血液の採取 |
| Porous | 針が多孔質構造 | 毛細管現象で薬液を送達、またはISFを吸引する | hollowと同様の送達・採取、機械強度とのバランス調整 |
| Dissolving | 水溶性・生分解性ポリマー基質に薬物を分散 | 基質そのものが皮膚水分で溶解・分解し、基質ごと消失しながら薬物を放出 | sustained releaseや一回投与、鋭利な廃棄物を残さない設計 |
| Swellable（hydrogel-forming） | 架橋ポリマー網目に薬物を保持、または網目自体がISFを吸収 | 皮膚水分を吸って膨潤し、溶けずにチャネルを開いて薬物拡散・ISF吸収を行う | 徐放、ISFの継続的サンプリングやバイオセンシング |

[統合] Yuan et al. (2023) が対象としたのは、drug-loaded hydrogel MN（swellable/dissolvingに近い挙動）と、皮膚前処理用のplastic solid MNの2系統である（3.1参照）。この分類に照らすと、元論文の「permeation」は主にswellable/dissolving系のrelease-then-permeationと、solid MNによる前処理効果の混合として理解できる。

### 0.3 主な材料と作製法 [基礎][2]

| 材料カテゴリ | 代表例 | 主な作製法 | 特徴 |
| --- | --- | --- | --- |
| 金属 | ステンレス、チタン、ニッケル | レーザー切断・アブレーション、エッチング、micromolding+焼結 | 強い圧縮・曲げ強度、繰り返し使用可（例: Dermaroller） |
| シリコン | シリコン | フォトリソグラフィ、エッチング | 強い機械強度だが割れやすい |
| ガラス | ホウケイ酸ガラス | pulling technique | hollow MNで機械強度が必要な用途 |
| セラミックス | アルミナ、リン酸カルシウム系 | micromolding+焼結、3Dプリント（光重合） | 高い生体適合性、tunable porosity、割れやすい |
| 糖ガラス | マルトース、トレハロース、マンニトール | micromolding、drawing lithography | 生体適合性が高いが吸湿性 |
| 非分解性ポリマー | PDMS、PMMA、ナイロン | レーザーアブレーション、micromilling、3Dプリント、micromolding | 成形自由度が高い |
| 生分解性ポリマー | PLA、PLGA、PCL | micromolding、3Dプリント（FDM） | 分解速度で放出プロファイルを調整可能 |
| 水溶性ポリマー | PVA、PVP、ゼラチン | micromolding、drawing lithography | dissolving/swellable MNの主要材料 |

作製法として頻出するのは、鋳型に材料を流し込むmicromolding、フォトリソグラフィ・レーザー加工・エッチングなどの精密除去加工、そして光造形（stereolithography、digital light processing、two-photon polymerizationなど）を使う3Dプリンティングである。3Dプリンティングは形状の自由度が高い一方、材料・装置・生産速度・コストの制約を受ける。

[統合] [2]のTable 1（材料・作製法の対応表）は、「この論文のMNは何でできていて、どう作られたか」を読み解くチェックリストとしても使える。同じ「dissolving MN」でも、糖ガラスかPVAかPLGAかで、水分応答性・分解速度・機械強度が変わる。

### 0.4 なぜsmall-data MLが問題になるのか [基礎][3][4]

MN研究の実験（Franz拡散セルによるin vitro透過試験、動物・ヒト皮膚サンプル、細胞assay）は、1条件あたりの取得に時間・コスト・倫理的制約がかかる。そのため、他分野の画像認識や自然言語処理のように数万〜数百万件のデータを集めることは通常できず、数十〜数百件規模の観測が典型になる。

Xu et al. (2023) は、small-data対策を「データ」「アルゴリズム」「戦略」の3層で捉えることを提案している（3.3参照）。

- **データ層:** 既存文献からのデータ抽出、データベース化、計画実験（DOE）で少数でも情報量の高い点を選ぶ。
- **アルゴリズム層:** 少数データでも過学習しにくい手法（正則化線形回帰、SVM/SVR、Gaussian Process Regression、Random Forest、XGBoostなど）を、モデルの複雑さとデータ量に見合った形で選ぶ。
- **戦略層:** active learning（次にどの実験をすれば最も情報が増えるかをモデルに提案させる）、transfer learning（関連する大規模データセットの知識を転用する）。

### 0.5 初めて読むときのミニ用語ガイド：手法の一行説明 [基礎]

詳しい定義は[11. 用語集](#glossary)にまとめるが、本レビューを読むために最低限必要な手法だけ先に一行で説明する。

- **Fickの法則に基づくmechanistic model:** 濃度勾配による拡散を物理方程式で記述するモデル。パラメータ（diffusion coefficientなど）に機構的な意味があるが、値の入手や仮定の単純化に制約がある。
- **Random Forest / XGBoost:** 多数の決定木を組み合わせる非線形回帰・分類手法。表形式の少数〜中規模データでも扱いやすく、この分野のtree ensembleの代表格。
- **Gaussian Process Regression（GPR）:** 予測値だけでなく予測の不確実性（信頼区間）を返す手法。少数データでのbaselineやactive learningと相性がよい。
- **Active learning:** 次にどの条件を実験すれば予測の不確実性が最も減るかをモデルに提案させ、実験と学習を反復するアプローチ。
- **Transfer learning:** 別の（多くはより大規模な）関連データセットで学習した知識を、少数データの対象タスクに転用する手法。関連性が低いsourceからの転用は逆に性能を落とす（negative transfer）ことがある。
- **Physics-informed / hybrid residual model:** mechanistic modelの予測値を土台にして、その残差（実測との差）だけをMLで学習する構成。物理的な妥当性とデータからの補正を両立させやすい。

### 0.6 評価指標を読むときに、まず疑うこと [基礎][統合]

本レビューの4章・7章で詳述する内容の要約として、初めて読む際に持っておくべき3つの疑問を挙げる。

1. **その`R²`やRMSEは、何を分割してtrain/testに分けた結果か。** 同じ薬物・同じ透過曲線の時点が両方に混ざっていないか（1章の3点目、3.1「最重要の限界」で詳述）。
2. **未知の薬物・未知のMN設計に対する性能か、既知データ内の性能（補間）か。** 高い`R²`は多くの場合、後者を示しているに過ぎない（4.4参照）。
3. **予測に不確実性（誤差範囲）が付いているか。** 点推定だけの比較では、「どこまで信頼できる予測か」が分からない（4.4、7章参照）。

これらの疑問を持ったうえで、1章以降の各論文批評、7章のvalidation設計を読むと、なぜこのレビューがrandom point splitやsingle R² reportingに繰り返し注意しているかが理解しやすくなる。

## 1. まず押さえる7点 {#overview}

1. **元論文が予測したのは主に「マイクロニードル処理後の皮膚透過」であり、マイクロニードル内部からのreleaseだけではない。** 次研究では、matrixからのreleaseとskin transportを分けて定義する必要がある。[1]
2. **XGBoostは同じデータ分布内では最良だった。** 透過量・透過率の両方で `R² = 0.98` を示したが、未知薬物を丸ごと除外した検証では大きなずれが生じた。[1]
3. **191 time-point observationsを191 independent formulationsとして扱ってはいけない。** 同じ薬物・同じ透過曲線の時点がtrain/testへ分散すると、性能が楽観的に見える可能性がある。[1][3][4]
4. **物理モデルとMLは競合ではなく補完関係にある。** Fickモデルは機構・境界条件・単調性を与え、MLは未知の非線形残差や測定条件差を学習できる。[1][4]
5. **small dataではalgorithm選びより、experimental unit、descriptor、validation、uncertaintyが重要である。** SVM、GPR、RF、GBDT/XGBoost、symbolic regressionは候補だが、万能な方法はない。[3][4]
6. **臨床移行に必要な変数は薬物・針形状だけではない。** 挿入深さ、applicator、皮膚差、batch再現性、滅菌、包装、保存、投与量の一貫性までデータ化する必要がある。[2]
7. **次の最小実行案は、未知薬物をいきなり当てることではない。** まず同一薬物内の新しいMN設計をcurve/run単位で予測し、次にleave-one-drug-outと新規batchで外部検証する。

## 2. 取得状況とローカルファイル {#collection}

| No. | 文献 | 種別 | 取得状況 | ローカル |
| --- | --- | --- | --- | --- |
| 1 | Yuan et al., 2023 [1] | 原著研究 | 全文・publisher PDF・CC BY | [PDFを開く](../../references/papers/microneedle-small-data-ml/01-yuan-2023-drug-permeation-microneedled-skin-ml.pdf) |
| 2 | Zheng et al., 2024 [2] | MN総説 | 全文・publisher PDF | [PDFを開く](../../references/papers/microneedle-small-data-ml/02-zheng-2024-microneedle-biomedical-devices.pdf) |
| 3 | Xu et al., 2023 [3] | materials small-data総説 | 全文・publisher PDF・CC BY 4.0 | [PDFを開く](../../references/papers/microneedle-small-data-ml/03-xu-2023-small-data-ml-materials-science.pdf) |
| 4 | Dou et al., 2023 [4] | molecular small-data総説 | 全文・HHS author manuscript | [PDFを開く](../../references/papers/microneedle-small-data-ml/04-dou-2023-ml-methods-small-data-molecular-science.pdf) |
| 5 | Achar & Keith, 2024 [5] | 3頁のHighlight | **全文未取得**。ACSは抄録なし・購読対象 | [取得記録](../../references/papers/microneedle-small-data-ml/05-achar-keith-2024-highlight-metadata-only.md) |

ファイルサイズ、頁数、入手元、権利メモ、SHA-256は [PDF索引](../../references/papers/microneedle-small-data-ml/README.md) に記録した。

> **アクセス上の注意:** [5] は一般的なreview articleではなく、*Chemical Reviews* 124巻24号の3頁の`Highlight`である。ACS公式ページは「抄録の代わりにfirst pageを表示」としており、オープンアクセス版・機関リポジトリ版は確認できなかった。大学の購読認証が使える場合はDOIから取得できる。

## 3. 論文別要約 {#paper-summaries}

### 3.1 Yuan et al. (2023) - Prediction of drug permeation through microneedled skin by machine learning

**書誌:** Yunong Yuan, Yiting Han, Chun Wei Yap, et al. *Bioengineering & Translational Medicine* 8(6), e10512. DOI: [10.1002/btm2.10512](https://doi.org/10.1002/btm2.10512). [PubMed Central](https://pmc.ncbi.nlm.nih.gov/articles/PMC10658566/)

#### 目的

[論文] Franz diffusion cellを用いるin vitro皮膚透過試験は時間と費用がかかるため、既存の実験データからマイクロニードル（MN）処理皮膚の累積透過量と累積透過率を予測することを目的とした。比較したのは、Fickの第二法則に基づく2次元mechanistic model、multiple linear regression（MLR）、random forest（RF）、XGBoostの4方法である。

#### データと設計

- 既報の同一研究グループの実験から、BSA、銅イオン、GHK tripeptide、rhodamine B、lidocaine、caffeineの6 payloadを統合した。
- クリーニング後は**191 time-point observations**。
- MNはdrug-loaded hydrogel MNと、皮膚前処理に用いるplastic solid MNの2系統。
- MLの7特徴量は、skin type、MN type、MN length、MN surface area、drug loading、permeation time、molecular weight。
- データ点を**7:3でランダムにtrain/test分割**。Fickモデルは文献由来のdiffusion coefficientを使用し、学習はしていない。
- 評価指標はRMSEとR²。

#### 主結果

| 予測対象 | XGBoost | RF | Fick | MLR |
| --- | ---: | ---: | ---: | ---: |
| 透過量 RMSE (µg) | **4,447.23** | 7,043.97 | 6,778.17 | 23,398.91 |
| 透過量 R² | **0.98** | 0.95 | 0.95 | 0.46 |
| 透過率 RMSE (%) | **28.24** | 34.33 | 85.58 | 120.33 |
| 透過率 R² | **0.98** | 0.97 | 0.82 | 0.65 |

[論文] XGBoostが両予測で最良だった。feature importanceでは、透過率にはMN surface areaとtime、透過量にはdrug loadingとtimeが重要だった。Fickモデルは機構理解に有用だが、drug・skin・temperatureなどで変わるdiffusion coefficientの入手が制約になる。

#### 最重要の限界

- [論文] rhodamine Bとcaffeineのように各薬物の点数が少ない場合、予測偏差が大きかった。
- [論文] 1薬物をtraining setから完全に除外して予測すると、透過量・透過率ともに大きく外れた。著者は、drug loading範囲の偏りと他特徴量の重み不足を理由に挙げている。
- [統合] 191点は経時曲線上の点を含み、独立した191製剤とは限らない。random point splitでは、同一drug・MN condition・curve由来の近い時点がtrain/testの両方に入る可能性がある。その場合、`R² = 0.98` は**interpolation性能**としては有用でも、未知drugや未知platformへの性能とは解釈できない。
- [統合] `time`が最重要になるのは累積量の物理から自然であり、feature importanceだけで新しい機構を証明したとはいえない。
- [統合] RMSEはpayloadの量スケールに支配される。drug間の公平な比較には、per-curve normalized errorやdrug-wise metricsも必要である。

#### この論文から引き継ぐもの

[提案] 4モデルを比較する思想、公開data/code、量と率を分ける点、機構モデルをbaselineに置く点はそのまま引き継ぐ。一方、split単位、外部検証、uncertainty、curve構造を更新する。

### 3.2 Zheng et al. (2024) - Microneedle biomedical devices

**書誌:** Mengjia Zheng, Tao Sheng, Jicheng Yu, Zhen Gu, Chenjie Xu. *Nature Reviews Bioengineering* 2, 324-342. DOI: [10.1038/s44222-023-00141-6](https://doi.org/10.1038/s44222-023-00141-6).

#### 総説の地図

[論文] MNを単なる皮膚穿刺針ではなく、drug delivery、biofluid sampling、biosensing、wearable electronics、closed-loop theranosticsを統合するbiomedical deviceとして整理した総説である。

- **構造:** solid、hollow、porous、dissolving、swellable。
- **材料:** metals、silicon、glass、ceramics、oligosaccharides、non-degradable / biodegradable / water-soluble polymers。
- **設計変数:** tip radius、length、aspect ratio、spacing、needle number、patch area、internal density、multi-material composition。
- **応用:** skinに加え、eye、oral mucosa、heart、gastrointestinal tract、tumourなど。
- **機能統合:** stimuli-responsive delivery、electrical / photonic / mechanical stimulation、biosensing、living-cell delivery、wearables、feedback-controlled dosing。

#### 臨床移行に関する主結果

[論文] 著者らはClinicalTrials.govで2007-2022年の`microneedle`関連138試験を調べ、約4分の1がphase II以降と報告した。対象はvaccination、pain、anaesthesia、ocular delivery、cancer、osteoporosis、diabetes、diagnosisなどに広がる。一方、血液採取deviceにはFDA clearanceやCE markの例があるが、therapeutic MN patchの承認・商業化はなお難しい。

#### 研究データへ追加すべきtranslation variables

- **Safety:** 出血、感染、allergy、rash、炎症、反復使用、分解物。
- **Stability:** biologicsのtemperature、humidity、solvent感受性。
- **Mass production:** pharmacopoeial standard、batch-to-batch consistency、cost。
- **Sterilization:** ethylene oxide、gamma ray、autoclaving、aseptic processingがmaterial/cargoへ与える影響。
- **Packaging/storage:** hygroscopicity、oxidation、desiccant、nitrogen、cold chain。
- **Deployment:** thumb pressureまたはapplicator、insertion depth、skin thicknessとmechanicsの個人差・部位差。
- **Dose consistency:** penetration、release、needle detachmentがbioavailabilityへ与える影響。

[統合] 次のML研究でlaboratory variablesだけを使うと、実装時の分布変化を見落とす。少なくとも`applicator`, `insertion success`, `skin thickness/site`, `batch`, `sterilization`, `storage`を将来追加できるschemaにする必要がある。

### 3.3 Xu et al. (2023) - Small data machine learning in materials science

**書誌:** Pengcheng Xu, Xiaobo Ji, Minjie Li, Wencong Lu. *npj Computational Materials* 9, 42. DOI: [10.1038/s41524-023-01000-z](https://doi.org/10.1038/s41524-023-01000-z).

#### 中心的な整理

[論文] materials MLのsmall-data対策を3層に分ける。

| 層 | 方法 | MN研究での対応 |
| --- | --- | --- |
| Data source | publication extraction、database、高throughput computation/experiment | 過去のFranz-cell曲線、simulation、計画的DOE |
| Algorithm | SVM/SVR、GPR、RF、GBDT、XGBoost、symbolic regression、imbalanced learning | 少数表形式データのbaselineとuncertainty |
| Strategy | active learning、transfer learning | 次に測るMN条件の選択、近縁payload/platformからの知識移転 |

#### 実務上重要な点

- small/bigは固定のsample数ではなく、sample数、feature数、target complexityの関係で決まる。
- controlled conditionsで得た高品質small dataは、由来が不明な大量データより有用な場合がある。
- workflowはdata collection、feature engineering、model selection/evaluation、applicationで構成される。
- element / structure / process descriptorsに加え、**domain knowledgeから作るdescriptor**が精度と解釈性を改善し得る。
- 著者らはsample数が30未満ならLOOCVを推奨例として挙げるが、[統合] 時系列・曲線・batch構造がある場合は単純LOOCVではなく**group-aware validation**が優先される。
- y-scrambling、反復分割、external validationは偶然の相関やsplit依存性の確認に役立つ。
- active learningは、unlabeled candidate poolから情報量の高い点を選び、experiment-label-retrainを反復する。
- transfer learningは関連する大きなsource taskがあり、targetとの相関が高いときに有効。無関係なsourceからのnegative transferには注意が必要。

#### このテーマへの意味

[提案] MN実験ではGPRをuncertainty付きbaselineにし、RF/XGBoostを非線形baseline、mechanistic modelをphysics baseline、symbolic/regularized regressionを解釈baselineとして同じsplitで比較する。モデル数を増やすより、group splitと外部検証を固定することが先である。

### 3.4 Dou et al. (2023) - Machine Learning Methods for Small Data Challenges in Molecular Science

**書誌:** Bozheng Dou, Zailiang Zhu, Ekaterina Merkurjev, et al. *Chemical Reviews* 123(13), 8736-8780. DOI: [10.1021/acs.chemrev.3c00189](https://doi.org/10.1021/acs.chemrev.3c00189). [PubMed Central](https://pmc.ncbi.nlm.nih.gov/articles/PMC10999174/)

#### 対象と方法群

[論文] molecular scienceでsmall dataが生じる理由を、cost、time、ethics、privacy、security、acquisition limitsとして整理し、以下を広くレビューする。

- classical ML: linear/logistic regression、KNN、SVM、kernel methods、RF、GBT。
- neural/generative: ANN、CNN、U-Net、GNN、GAN、VAE、LSTM、transformer。
- data-efficient strategies: transfer/multitask learning、self-supervised learning、active learning、graph-based semi-supervised learning。
- hybrid strategies: traditional ML + DL、**physical model-based data augmentation**。

#### MN研究へ直結する主張

- small dataの即時的リスクはtrainだけでなくtestにも起こるoverfitting。
- imbalance、noise、missingness、diversity、high dimensionalityが同時に問題を悪化させる。
- materials scienceでは、black-box deep modelより、physics-informed variablesを使うsimple modelが同等性能と高い解釈性を示す場合がある。
- simulation augmentationは有望だが、noiseやnon-uniformityを持ち込む危険がある。
- modelability、data representability、small-and-diverse/noisy/imbalanced dataの評価方法が未成熟。
- 最終的には、physical / chemical / biological understandingをmodel design、selection、interpretationへ組み込む必要がある。

#### このテーマへの意味

[提案] simulation点を実験点と同じ重みで単純結合しない。`source = experiment | simulation`を保持し、multi-fidelity model、residual learning、calibration weightingのいずれかで扱う。物理的に不可能なnegative cumulative amount、loading超過、時間とともに減少する累積透過などを許さない制約も必要である。

### 3.5 Achar & Keith (2024) - Small Data Machine Learning Approaches in Molecular and Materials Science

**書誌:** Siddarth K. Achar, John A. Keith. *Chemical Reviews* 124(24), 13571-13573. DOI: [10.1021/acs.chemrev.4c00957](https://doi.org/10.1021/acs.chemrev.4c00957).

[論文] ACSとPubMedで確認できる範囲では、これは**3頁のHighlight**で、abstractは掲載されていない。subjectsはfirst-principles calculations、materials、materials science、molecular modeling、quality management。全文未取得のため、具体的主張、方法、結論は本レビューの根拠に使っていない。

[提案] 大学購読で取得できた場合は、[取得記録](../../references/papers/microneedle-small-data-ml/05-achar-keith-2024-highlight-metadata-only.md)の`未確認`欄を更新し、現在のsummaryへ追補する。

## 4. 5本を統合すると何が言えるか {#synthesis}

### 4.1 元論文の位置づけ

[統合] Yuan et al.は「同じ研究群・既知payloadを含むデータ空間で、非線形tree ensembleがmechanistic/linear baselineより高精度になり得る」ことを示した。これは有用な第一段階である。しかし、未知drugを除いたときの失敗は、現在のmodelがdrug-agnostic general predictorではないことも同時に示す。

### 4.2 releaseとpermeationを分ける

累積受容液量は少なくとも次の連鎖で決まる。

`MN hydration / dissolution -> payload release -> skin partition -> diffusion through tissue -> receptor mixing / sampling`

[統合] 一つのblack-box targetへまとめると、どの段階の変化を学習したか分からない。可能なら以下を別targetとして測る。

1. MNからmediaへのin vitro release。
2. skin内retention。
3. receptorへ到達したcumulative amount。
4. mass balance（MN残存 + skin + receptor + loss）。

### 4.3 物理モデルとMLの役割分担

| 方法 | 強み | 弱み | 次研究での役割 |
| --- | --- | --- | --- |
| Fick / mechanistic | 境界条件、単位、機構、extrapolationの形 | diffusion coefficientや単純化仮定に敏感 | physics baseline / constraint |
| Regularized linear / symbolic | 少数データ、解釈性 | 強い非線形に弱い | sanity-check baseline |
| GPR | uncertainty、active learningと相性 | 高次元・大規模に弱い | primary small-data baseline |
| RF / XGBoost | 非線形、interaction、表形式 | 外挿とcalibrationが弱い | predictive baseline |
| Hybrid residual | 物理の形 + data-driven correction | 設計と検証が複雑 | 推奨primary model |

推奨形は `prediction = mechanistic prediction + ML residual`。別案として、diffusion coefficientやrelease-rate parameterをMLで推定し、mechanistic solverへ戻す。

### 4.4 「精度が高い」より「どこまで使えるか」

[統合] small dataで重要なのは単一のR²順位ではなくapplicability domainである。少なくとも、各予測に以下を返すべきである。

- training range内か外か。
- nearest known drug / MN designとの距離。
- prediction interval。
- 主要なuncertainty source。
- 追加実験で最も不確実性が減る候補。

## 5. 次の論文として推奨する研究質問 {#next-study}

> **Can a physics-guided, uncertainty-aware small-data model predict complete drug release and skin permeation profiles from microneedle systems, while identifying the next most informative experiment?**

### Primary hypothesis

Fick-basedまたはrelease-diffusion mechanistic predictionへGPR/XGBoost residualを追加すると、pure mechanistic modelとpure ML modelより、**grouped external validation**で低い誤差と良いuncertainty calibrationを得られる。

### Secondary hypotheses

1. domain descriptors（solubility、logP、ionization、matrix hydration、crosslink density、geometry）を加えると、molecular weightだけよりleave-one-drug-out性能が改善する。
2. active learningで選んだ実験は、random samplingより少ない追加curveでerror/uncertaintyを下げる。
3. applicatorとinsertion qualityを加えると、batch間の残差が減る。

## 6. 推奨データ構造 {#data-design}

### Experimental unit

`study -> batch -> MN formulation/device -> skin specimen -> diffusion-cell run -> curve -> time point`

主split単位は**curveまたはrun**とし、time pointを独立にsplitしない。skin donorやbatchが複数curveを生む場合は、目的に応じてdonor/batchもgroup化する。

### 最低限のfield

| Block | 例 |
| --- | --- |
| Provenance | study_id, source_doi, raw_file, extraction_method, reviewer |
| Group IDs | batch_id, formulation_id, skin_donor_id, run_id, curve_id |
| MN | type, material, geometry, length, tip radius, surface area, count, spacing |
| Matrix/process | polymer MW, concentration, crosslinking, fabrication method, sterilization, storage |
| Payload | identity, loading, MW, logP/logD, pKa, solubility, charge, diffusivity |
| Barrier | species, anatomical site, thickness, preparation, integrity test |
| Deployment | applicator, force/speed, dwell time, insertion depth/success |
| Diffusion test | donor/receptor volume, medium, pH, temperature, agitation, sampling/replacement |
| Outcomes | time, cumulative amount, cumulative %, flux, lag time, skin retention, mass balance |
| Quality | replicate, censoring, missingness reason, protocol deviation, uncertainty |

## 7. Validationと解析計画 {#validation}

### 必須の4段階

1. **Grouped repeated cross-validation:** curve/run単位で分割。hyperparameter tuningをnested CV内に閉じる。
2. **Leave-one-formulation/drug-out:** 未知条件への外挿を明示的に測る。
3. **Leave-one-platform/material-out:** hydrogel/solidなどdevice classをまたぐ一般化を測る。
4. **Prospective external test:** 新しいbatch、可能なら新しいskin donor・laboratory dayを事前固定して評価。

### Metrics

- point-wise: MAE、RMSE、R²。ただしdrug-wiseにも集計。
- curve-wise: normalized RMSE、AUC error、`t50/t90` error、maximum deviation。
- physical validity: non-negativity、monotonic cumulative curve、loading upper bound、mass balance。
- uncertainty: 90/95% interval coverage、interval width、calibration curve。
- decision value: active learning 1 iterationあたりのerror reduction。

### Leakage guard

- normalization、feature selection、imputation、augmentationをCV foldの外でfitしない。
- 同一curveのtime pointsをtrain/testへ分けない。
- literature由来のduplicate curveを検出する。
- simulation-generated pointsの元parameterがtest experimentから推定されていないか確認する。

## 8. 最小実行プラン {#mvp}

### Phase 1 - Reproduce

- Data S1/S2から元論文の191点、4モデル、Table 4を再現。
- rowごとに`drug`, `run/curve`, `time`, `source study`を復元。
- random point splitとgrouped splitの性能差を報告。

### Phase 2 - Strengthen

- GPR、regularized linear、RF、XGBoost、Fick、hybrid residualを同一splitで比較。
- bootstrapでconfidence intervalを出す。
- leave-one-drug-out failureを定量化し、applicability domainを可視化。

### Phase 3 - Add information, not just rows

- drug descriptorsとrelease-stage dataを追加。
- MN batch/applicator/insertion variablesを追加。
- 追加実験候補をBayesian active learningで順位付けし、研究者が実行可能性を確認。

### Phase 4 - Prospective validation

- modelをfreezeしてから新規curveを取得。
- success criteriaとfailure criteriaを事前登録。
- 予測が外れた条件も削除せず、次iterationの情報として残す。

## 9. 主張できること／まだできないこと {#limits}

### 現時点で主張できる

- 既知drugを含む小規模統合dataでは、XGBoostが比較4法中で最良だった。[1]
- MN surface area、drug loading、timeは予測へ強く寄与した。[1]
- small-data対策には、domain descriptors、適切なclassical algorithms、active/transfer learning、physics integrationが有望である。[3][4]
- clinical translationには挿入・製造・滅菌・保存・投与量一貫性が不可欠である。[2]

### まだ主張できない

- `R² = 0.98`が未知drugにも維持されること。
- feature importanceが因果効果または機構を証明すること。
- simulation augmentationだけでexperimental generalizationが改善すること。
- MN typeやdrug MWが本質的に重要でないこと。
- laboratory modelがclinical doseやpatient responseを保証すること。

## 10. 新しい論文・自分のデータを評価するときのチェックリスト {#checklist}

[提案] 1〜9章で明らかになった論点を、次にMN×ML論文を読むとき、または自分のデータを解析するときに使えるチェックリストへまとめる。

### 10.1 データ構造

- [ ] 観測点はexperimental unit（curve/run）ごとに識別できるか、それとも時点だけの羅列か。
- [ ] `batch_id`、`skin_donor_id`、`run_id`のようなgroup IDが記録されているか。
- [ ] release、permeation、retention/recoveryのどれを測っているかが明示されているか（混同していないか）。
- [ ] nominal loading（設計値）とassay-confirmed loading（実測値）が区別されているか。

### 10.2 分割とvalidation

- [ ] train/testの分割単位はtime pointではなく、curve/run/donorなどgroupか。
- [ ] leave-one-drug-out、leave-one-platform-outのような外部検証を報告しているか。
- [ ] cross-validationのhyperparameter探索は、テスト対象のfoldの外で行われているか（リーク防止）。
- [ ] y-scramblingや反復分割など、偶然の相関を確認する手続きがあるか。

### 10.3 指標と物理的妥当性

- [ ] `R²`だけでなく、RMSE/MAE、可能ならcurve-wiseやdrug-wiseの指標も報告しているか。
- [ ] 予測値が物理的にあり得ない値（負の累積量、loading上限超え、時間とともに減少する累積曲線など）を許していないか。
- [ ] 予測に不確実性（prediction interval、信頼区間）が付いているか。

### 10.4 臨床・実装への翻訳変数

- [ ] insertion（applicator、挿入深さ、成功率）、滅菌、保存、製造ばらつきなど、laboratory変数以外の翻訳変数を記録・議論しているか（3.2参照）。
- [ ] sample数が少ない状態で、未知材料・患者集団への性能を過度に一般化していないか。

### 10.5 自分の研究にAI・MLを使うとき

- [ ] mechanistic baseline（Fickなど）を、MLモデルと同じデータ・同じsplitで比較しているか。
- [ ] simulationデータと実験データを同じ重みで単純結合していないか（4.3、9章参照）。
- [ ] 欠測値をAIで補完した場合、それを実測値と区別して記録しているか。
- [ ] AIが提案したコード・図・文章を、人間（研究者）がraw dataと突き合わせてレビューしたか。

## 11. 用語集 {#glossary}

日本語での議論用に、本レビューで使う主要用語を英日対照でまとめる。定義は本レビューでの使われ方に合わせた簡略なものであり、厳密な学術定義はそれぞれの原論文を参照する。

#### マイクロニードル・皮膚

| 用語 | 説明 |
| --- | --- |
| Microneedle (MN) | 数十〜数千µmの微小な針をパッチ状に配列した経皮送達・採取デバイス |
| Stratum corneum（角層） | 皮膚最外層。厚さ約10-40µmの死細胞層で、経皮吸収の主なバリア |
| Interstitial fluid, ISF（間質液） | 血管と細胞の間を満たす体液。血漿成分を薄めた形で含み、MNでの採取対象になる |
| Solid MN | 薬物を持たない、または表面コーティングのみの針。穿孔・前処理に使う |
| Hollow / porous MN | 内部が中空・多孔質で、薬液の注入や体液吸引に使う |
| Dissolving MN | 水溶性・生分解性の基質が皮膚水分で溶解し、基質ごと薬物を放出する |
| Swellable（hydrogel-forming）MN | 架橋ポリマーが皮膚水分で膨潤し、溶けずにチャネルを開いて薬物拡散・ISF吸収を行う |
| Applicator | MNを一定の力・速度で皮膚に押し込む補助器具。挿入成功率に影響する |
| Aspect ratio | 針の高さと基部幅の比。機械強度と穿刺性のトレードオフに関わる |
| Franz diffusion cell | donor/receptor 2槽構造で皮膚などの膜を介した透過を測るin vitro試験装置 |
| Cumulative permeation（累積透過量） | receptor側に一定時間内に到達した薬物の累積量 |
| Flux（流束） | 単位時間・単位面積あたりの透過速度 |
| Lag time（遅延時間） | 拡散が定常状態に達するまでの初期の遅れ |
| Burst release（バースト放出） | 投与直後に薬物の大部分が急速に放出される挙動 |
| IVRT / IVPT | In Vitro Release Testing / In Vitro Permeation Testing。局所製剤の品質・同等性評価に使われる規制文書上の試験枠組み |
| Mass balance | 投与量が、残存・透過・吸着・損失にどう配分されたかを合計で確認する考え方 |

#### Small-data ML・統計

| 用語 | 説明 |
| --- | --- |
| XGBoost / Random Forest（RF） | 複数の決定木を組み合わせる非線形回帰・分類手法。表形式データで頻用 |
| Gaussian Process Regression（GPR） | 予測と同時に不確実性（信頼区間）を返す非パラメトリック回帰手法 |
| SVM / SVR | サポートベクターマシン（分類）・回帰版。少数データでも比較的頑健 |
| Symbolic regression | データから解釈可能な数式そのものを探索する回帰手法 |
| Mechanistic model | Fickの法則など、物理・化学機構に基づく方程式で現象を記述するモデル |
| Physics-informed / Hybrid residual model | mechanistic modelの予測を土台に、その残差をMLで補正するモデル構成 |
| Active learning | 次に測るべき最も情報量の高い条件をモデルに提案させる反復的実験計画 |
| Transfer learning | 関連する別データセットで得た知識を、対象タスクへ転用する手法 |
| Negative transfer | 関連性の低いsourceからの転移学習によって、かえって性能が悪化する現象 |
| Data leakage（データリーク） | train情報がtestの評価に混入し、性能を実際より楽観的に見せる現象 |
| Group-aware cross-validation | 同一curve/run/donorなどのgroupがtrain/testに分かれないよう配慮した交差検証 |
| Leave-one-drug-out | ある薬物のデータを丸ごとtestにして、未知薬物への汎化を測る検証法 |
| LOOCV | Leave-One-Out Cross-Validation。1点だけをtestに残す交差検証（小規模データでの一手法） |
| y-scrambling | 目的変数をランダムに並べ替えて再学習し、偶然の当てはまりでないか確認する手法 |
| Applicability domain | モデルが妥当に予測できると考えられる、学習データの範囲・近傍 |
| RMSE / MAE | Root Mean Squared Error / Mean Absolute Error。予測誤差の代表的な指標 |
| R² | 決定係数。分散のうちモデルが説明できた割合。分割方法次第で楽観的になりやすい指標 |
| AICc | 赤池情報量規準の小サンプル補正版。モデルの当てはまりと複雑さのバランスを比較する指標 |
| Multi-fidelity model | 精度・コストの異なる複数のデータ源（実験・simulationなど）を区別して統合するモデリング手法 |
| Descriptor（記述子） | 材料・分子・条件を数値化してモデルへ入力する特徴量 |
| Prediction interval | 予測値に付随する不確実性の幅を表す区間 |
| Experimental unit | 統計的に独立とみなせる観測の単位（例: 1 curve、1 diffusion cell run） |
| Provenance | データがどこから、どの処理を経て今の形になったかの来歴情報 |

## 12. 参考文献と公式リンク {#references}

1. Yuan Y, Han Y, Yap CW, et al. [Prediction of drug permeation through microneedled skin by machine learning](https://doi.org/10.1002/btm2.10512). *Bioengineering & Translational Medicine*. 2023;8(6):e10512. [PMC full text](https://pmc.ncbi.nlm.nih.gov/articles/PMC10658566/)
2. Zheng M, Sheng T, Yu J, Gu Z, Xu C. [Microneedle biomedical devices](https://doi.org/10.1038/s44222-023-00141-6). *Nature Reviews Bioengineering*. 2024;2:324-342.
3. Xu P, Ji X, Li M, Lu W. [Small data machine learning in materials science](https://doi.org/10.1038/s41524-023-01000-z). *npj Computational Materials*. 2023;9:42.
4. Dou B, Zhu Z, Merkurjev E, et al. [Machine Learning Methods for Small Data Challenges in Molecular Science](https://doi.org/10.1021/acs.chemrev.3c00189). *Chemical Reviews*. 2023;123(13):8736-8780. [PMC full text](https://pmc.ncbi.nlm.nih.gov/articles/PMC10999174/)
5. Achar SK, Keith JA. [Small Data Machine Learning Approaches in Molecular and Materials Science](https://doi.org/10.1021/acs.chemrev.4c00957). *Chemical Reviews*. 2024;124(24):13571-13573. **Highlight; full text not reviewed.**

## 13. 作成方法と限界 {#methods}

- 2026-07-17に共有された5リンクを確認し、取得できた4全文をPDF化・text extraction・page renderingで照合した。
- 原著[1]はmethods、Table 2-4、feature importance、leave-one-drug-out discussionを重点確認した。
- [2]-[4]は各総説の分類、validation、translation、outlookを重点確認した。
- [5]はACS、PubMed、Crossref、OpenAlexで書誌とaccess状態を確認したが、合法的なopen full textは確認できなかった。
- 2026-07-18に、初めてこのテーマに触れる読者向けの基礎知識（0章）、論文評価チェックリスト（10章）、用語集（11章）を追加した。0章の構造・材料・作製法の記述は[2]の該当ページ（Fig. 1、Table 1、MN engineering節）を再確認して作成し、small-data MLの一行説明と評価指標の注意点は[3][4]および1-9章の既存内容を再構成したものである。
- 0章・10章・11章は新しい一次資料の追加取得を伴わない、既存4全文と一般知識の再構成であり、`[基礎]`タグの内容は本レビュー独自の主張ではない。
- これはnarrative critical reviewと研究設計draftであり、systematic review、meta-analysis、臨床判断ではない。
