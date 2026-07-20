# 要件定義 — Curved Corneal Construct Geometry QC Research Roadmap

文書版: 1.0
作成日: 2026-07-19
作成者: Claude Sonnet 5（一次draft）→ Claude Fable 5（改善）→ Codex GPT-5.6-Terra / GPT-5.6-Sol（実装）
対象: `big-lab/corneal-geometry-qc/site/index.html`

## 0. 背景と根拠

Yuan et al. (2026, *Advanced Healthcare Materials*, 3D Printing Strategies for Bioengineering Human Cornea, DOI: 10.1002/adhm.202502767) は、3D printed corneaに関する公開文献（40 publications、うち33 research article）を横断reviewし、そのうちcurved geometryで作製されたのは13研究のみである（Section 3.1）と整理した上で、次を明示的な evidence gap として指摘している（Section 5, Outlook and Opportunities）。

> "To our knowledge, no study has systematically reported measured geometric errors (e.g. deviations in radius or thickness) as a function of curvature in such constructs... Key metrics should include radius error, local wall-thickness variation, surface roughness, and topographic chordal error."

同論文は同じSection 5で、test domeを条件を変えて印刷し、high-resolution scanningまたはOCTで実測してcurvature angleとdimensional errorを対応づける具体案を示す。またSection 3.1は、layer厚とslice angleの増加に伴いchordal error（曲面を平面facetで近似することによる層状の段差誤差）が増大すること、direct printingが概ね45°のoverhang角度に制限されること（Figure 5e）を述べる。さらに同論文Table 3は、cornea特性として Young's modulus、transparency、refractive power、refractive index、corneal permeability の標準測定法を整理しており、これを踏まえてSection 5は "a comprehensive, standardized characterization protocol"（力学・光学・屈折・透過性を含む標準評価プロトコル）の必要性を結論づけている。これは、`docs/contribution-map.md` §3–4 がP0優先で挙げる **Curved Corneal Construct Geometry QC** と、`docs/yunong-yuan-research-guide.md` L142–219 が同じgapとして参照する内容に一致する。

この文書は、上記gapを埋めるための**実際の研究**（既存のsynthetic portfolio demoではない）を、段階を踏んで安全に進めるためのroadmap要件を定義する。

### 0.1 既存資産との関係（重要な区別）

| 既存資産 | 性質 | このroadmapとの関係 |
| --- | --- | --- |
| `portfolio/pilot-charter.md`, `geometry-qc-synthetic.csv`, `multi-agent-run-log.json`, `claim-evidence-map.csv` | **完全なsynthetic data**によるcapability demonstration（求職・面談用ポートフォリオ） | 方法論の出発点として参照するが、数値・閾値（例: `±0.18mm`）は実験的根拠を持たない仮値であり、このroadmapの受入基準には使わない |
| `website/pages/research-portfolio.html`, `geometry-qc-poster.html` | 上記portfolioのWeb / poster表現 | 同上。UI/可視化パターンは参考にしてよいが、「demo」であることを常に明示する |
| `docs/contribution-map.md` §3–4 | Yuan氏との面談前に書かれたdiscussion draft | 研究提案の一次根拠。面談後は`notes/decision-log.md`で更新差分を記録する |
| このroadmap（`corneal-geometry-qc/`） | **実データ・実PI承認を前提とした研究計画** | portfolio demoの次段階。real dataが使えるようになるまではGate 1（後述）に留まる |

## 1. 目的

3D printed curved corneal construct（曲面角膜構造体）について、design geometry（設計形状）に対する実測誤差を、**再現可能で監査可能な方法**で定量化し、研究者が次の印刷条件・評価法を判断できるlocal-first研究ポータルを提供する。特にgeometry error（形状誤差）、print-process要因、そしてYuan et al. (2026)が指摘するextended characterization（力学・光学・透過性）の3つを区別し、混同しない。

## 2. 想定利用者

- corneal bioprinting / biofabrication研究を始める学生・研究補助者（Takumi本人を想定した最初の利用者）
- 実験条件・評価法・データ利用範囲をレビューするPI・supervisor（Yunong Yuan氏を想定）
- 承認済みのCAD・画像・scan・OCTデータを用いてgeometry QC解析を担当するdata analyst
- portfolio demoとこのroadmapの違いを確認する第三者レビュアー

## 3. 必須コンテンツ

### 3.1 研究定義

- **Geometry error（主要測定対象）**: design/nominal geometryに対する実測構造体の偏差。radius deviation、wall-thickness variation、surface roughness / surface fidelity（本roadmapでは design meshに対する surface RMSE として算出する。これは Yuan et al. (2026) が挙げる surface roughness の operationalizationであり、classical texture roughness（Ra / Rq等）そのものとは区別する。真のtexture roughnessが必要な場合はTier Bで別途測る）、topographic chordal error、volume change、shrinkage rate、interlayer misalignmentを含む。registration RMSEはこれらの偏差そのものではなく、design meshへの位置合わせ品質を示す診断指標であり、別枠で扱う。
- **Print-process traceability（説明変数層）**: fabrication strategy（mould-assisted / direct-support-free printing）、layer thickness、slice angle、overhang angle（45°制限との関係）、support除去手順、bioink/material batch、printer・光学系設定。これらはoutcomeではなく、geometry errorを説明しうる要因として記録する。
- **Extended characterization（将来scope・現段階では対象外）**: Young's modulus（AFM / uniaxial-biaxial tensile / strip extensometry）、transparency（UV–Vis spectrophotometry）、refractive index（OCT / Abbe refractometry）、refractive power（keratometry / OCT）、corneal permeability（fluorophotometry / diffusion chamber）。Yuan et al. (2026) Table 3が示す標準測定法を引用し、Gate 7として明示的にroadmap化するが、Gate 0–6の受入条件には含めない。
- Primary research question、hypotheses、scope / out-of-scopeをGate 0で確定する。
- 原論文（Yuan et al. 2026）が指摘した内容と、本ラボがまだ検証していない内容を明確に分離する。

### 3.2 Roadmap

- Gate 0からGate 7までの段階（詳細は§6）
- 各Gateに目的、主要タスク、成果物、Go / Hold基準、想定期間
- **Gate 1（Evidence & Synthetic Pipeline Warm-up）はreal dataへのアクセス許可を待たずに開始できる並行track**とし、それ以外のGateはGate 0の許可・校正・PI確認が揃うまでHoldする
- 0–8週の pilot（Gate 0–5）と、その後のprospective scale-up（Gate 6）・extended characterization（Gate 7）を区別する
- 機器（3D printer、OCTまたはsurface scanner、CAD software）アクセス、PI承認、data-use permissionの確認をwet-lab / 機器利用開始前に置く

### 3.3 実験・解析設計

- calibration（pixel/voxel → mm）の取得と記録。calibrationのない画像は物理単位へ変換しない。
- design/nominal meshまたはCADと、実測mesh（photogrammetry / structured-light scan / OCT / confocal z-stack由来）とのregistration（例: ICP）手順。
- metric定義: radius deviation、wall-thickness variation、surface RMSE、topographic chordal error、volume change、shrinkage rate、interlayer misalignment、registration RMSE。
- 2つのdata acquisition tierを区別する：
  - Tier A（低コスト）: 複数角度写真 / structured light / surface scan → 3D表面再構築 → design meshとのregistration → 偏差map。透明・湿潤試料は取得条件の工夫が必要。
  - Tier B（高精度）: OCT / confocal z-stack / profilometry → 厚さ・前後面・層境界・局所曲率の空間解析。装置校正と専門家解釈が必要。
- QC state（PASS / REVIEW / FAIL）の predeclared threshold は、**portfolio demoの`±0.18mm`をそのまま転用せず**、Gate 0でPIと新たに確定する。
- experimental hierarchy: study → print run → material / bioink batch → construct（sample） →（Tier Bの場合）測定断面 / layer。設計・手法を識別する design / method version を各水準に紐づける。この入れ子は`templates/study-charter.md` §6、`templates/data-dictionary.csv`のlevel列、実行用指示文と一致させる。sample単位の疑似反復（pseudoreplication）を避け、print run と batch をgroup化因子として扱う。
- 失敗例（fit失敗、segmentation失敗、calibration欠落、曲面外領域）を削除せず、failure registryへ記録する。
- kinetic / mechanistic modelに相当する概念はここでは「誤差の系統的要因（層厚・slice angle・overhang角度・support方式）に対する回帰・比較」であり、単一の高い決定係数だけで印刷戦略の優劣を断定しない。

### 3.4 図表

- microneedle drug-release-profile roadmapと同様式の、curved corneal construct断面 + scan/OCT取得のオリジナル科学イラスト（概念図であることを明示）
- design geometryから測定・QC判定・記録までの因果chain図
- Tier A / Tier B data acquisition比較図
- phase roadmap表（Gate 0–7）
- minimum data dictionary表
- metric定義・単位・許容誤差表（閾値はplaceholderであることを明示し、Gate 0での確定を要求する）
- calibration手順表
- risk register表
- file / reference index表
- 既存synthetic demo（`geometry-qc-synthetic.csv`: 12 construct / 3 batch）の構造監査chart。**synthetic dataである旨を図中に常時表示する。**

### 3.5 研究資産への導線

- Yuan et al. (2026) cornea review PDF（`references/papers/yunong-yuan/3d-printing/08-yuan-2025-3d-printing-human-cornea.pdf`）
- 関連するYuan研究室論文（`references/papers/yunong-yuan/`配下の他ファイル、および未取得のdual-layer corneal bioprinting論文のmetadata参照）
- `docs/contribution-map.md`、`docs/yunong-yuan-research-guide.md`、`docs/contribution-strategy.md`の該当section
- portfolio demo一式（`portfolio/pilot-charter.md`、`geometry-qc-synthetic.csv`、`multi-agent-run-log.json`、`claim-evidence-map.csv`）— **demoである旨を明示した上で**参照
- `website/pages/research-portfolio.html#geometry`、`geometry-qc-poster.html`（同上、demo）
- charter、data dictionary、imaging sampling plan、construct log、analysis planのtemplate
- 要件定義（本文書）と実行用指示文

## 4. Functional requirements

| ID | 要件 | 受入条件 |
| --- | --- | --- |
| F-01 | セクションnavigation | desktop / mobileで主要セクションへ移動できる |
| F-02 | 進捗checklist | check状態がbrowser localStorageに保存される |
| F-03 | 進捗表示 | 完了数とpercentageが即時更新される |
| F-04 | Table filter | roadmap phaseをcategory（Gate種別、Tier A/B等）で絞り込める |
| F-05 | Prompt copy | 実行用指示文を1クリックでclipboardへコピーできる |
| F-06 | Print | print / PDF保存向けlayoutを提供する |
| F-07 | Direct files | local referenceとtemplateを相対linkで開ける |
| F-08 | Offline-first | hero imageを含め、表示にCDNや外部JavaScriptを必須としない |
| F-09 | Reset | checklistを明示操作でresetできる |
| F-10 | Synthetic/Real区別表示 | synthetic demoに由来する数値・図表には、常時視認できるラベル（例: badge、枠色、注記）が表示され、real pilot dataと視覚的に混同しない |

## 5. Non-functional requirements

| ID | 要件 | 基準 |
| --- | --- | --- |
| NF-01 | Accessibility | semantic HTML、skip link、keyboard focus、十分なcontrast、SVG title / desc |
| NF-02 | Responsive | 360px幅からdesktopまでhorizontal overflowを抑える |
| NF-03 | Performance | local assetsのみ。heroはlazy loading対象外、その他画像はlazy load |
| NF-04 | Scientific integrity | 実測、文献、推奨、概念図、**synthetic demo**をラベルで区別する |
| NF-05 | Reproducibility | experimental unit、units、provenance、raw/derived、calibration記録を明示する |
| NF-06 | Privacy | 未承認の画像・患者情報・未公開データをHTMLへ埋め込まない |
| NF-07 | Maintainability | CSS / JSを分離し、data attributeでbehaviorを接続する |
| NF-08 | Printability | navigation / controlsを除外し、A4で表とsectionが読める |

## 6. Roadmap gate定義（Gate 0–7）

| Gate | 名称 | 目的 | 主要タスク | 成果物 | Go / Hold基準 | 想定期間 |
| --- | --- | --- | --- | --- | --- | --- |
| 0 | Scope & Access Lock | PIと優先metric・data tier・primary endpointを確定する | `docs/yunong-yuan-research-guide.md` L218–219の2つの質問をPIへ確認；利用可能なCAD/photo/scan/OCTを棚卸；calibration有無を確認；QC閾値をPI承認で新規設定 | 1ページcharter（`templates/study-charter.md`）、data inventory、primary metric決定記録 | calibration・design reference・data-use許可のいずれかが欠ける場合はGate 1のみ継続しGate 2以降をHold | 1週 |
| 1 | Evidence & Synthetic Pipeline Warm-up | real dataなしで進められる作業を先に終える | Yuan et al. (2026) + dual-layer論文のrun-level data dictionary作成；`geometry-qc-synthetic.csv`を使ったloader/calibration/registration/metric codeのunit test；missing-field・duplicate-ID等のQC checker；公開論文の geometry報告状況 evidence matrix | tested code skeleton、synthetic dataでのend-to-end再現、evidence/missingness matrix | Gate 0の状態に関わらず開始可；ここで得た数値をreal pilotの結果として報告しない | Gate 0と並行、1–2週 |
| 2 | Define | 研究charterとhierarchyを固定する | primary metric、experimental unit（print run/batch/construct/method version）、predeclared QC threshold、randomisation・blinding方針を確定 | `templates/study-charter.md`記入版、data dictionary v1 | 研究者（Takumi）とPIの両者がcharterを承認 | 1週 |
| 3 | Build & Baseline | pipelineを1–2件の承認済みsampleで検証する | calibration記録、design meshとのregistration実装、metric計算、overlay生成 | manual reference値、calibration record、baseline overlay | manualとcodeの差の原因を説明できない場合はmetric追加をHold | 1–2週 |
| 4 | Batch Application | 承認された小規模set（例: 既存synthetic demoと同規模の12construct/3batchを real data で置き換え）へ適用する | failure分類、registry記録、batch別集計 | metric table、failure log、condition plot | sample独立性・batch構造が不明なら推測統計を行わない | 1–2週 |
| 5 | Verify & Communicate | PIレビューと再現性確認を行い、成果物を固定する | 検証済み出力のみからfigure/report/posterを再生成；method・limitationを記述 | versioned code、figure、1ページreport、次実験候補（最大3件） | PIがrawとの照合を完了し、synthetic demoとの違いを確認した時点でpilot完了 | 1週 |
| 6 | Prospective Scale-up | 新しいprint run・材料条件へ前向きに適用する | 事前登録した閾値とgroup-aware validationで複数batchを比較；一般化可能性を評価 | prospective study charter、grouped validation report | 閾値・成功基準を結果を見てから変更しない | pilot後、継続 |
| 7 | Extended Characterization Roadmap | Yuan et al. (2026)が求める標準特性評価（力学・光学・透過性）へ拡張する | Young's modulus、transparency、refractive index/power、permeabilityの測定法をラボ設備に合わせて計画；Gate 0–6の知見と接続 | extended characterization charter（草案） | Gate 0–6が検証済みになるまで着手しない | 将来（本roadmapでは計画のみ） |

## 7. Scientific requirements

1. calibration（pixel/voxel → mm）が確認できない画像・scanは、µm/mm単位の実測値へ変換せず、pixel単位または`not measurable`として扱う。
2. radius deviation、wall-thickness variation、surface RMSE、topographic chordal error、volume change、shrinkage rate、interlayer misalignmentを別変数として保存し、単一の「誤差スコア」に統合しない。
3. registration RMSEはfit品質の診断指標であり、geometry errorそのものと混同しない。registration RMSEが高いsampleのgeometry error値は、自動的に確定値として扱わずhuman reviewへ回す。
4. QC state（PASS / REVIEW / FAIL）の閾値は、portfolio demoの値を転用せず、Gate 0でPI承認のもと新たに設定し、結果を見た後に変更しない。
5. sample（construct）を独立実験単位として無条件にrandom splitしない。print run / material batchをgroup化因子として扱う。
6. print-process要因（fabrication strategy、layer厚、slice angle、overhang角度、support方式）は、geometry errorの説明変数として記録するが、biological・optical・clinical performanceの代理指標として扱わない。
7. Extended characterization（力学・光学・透過性・permeability）に関する主張は、Gate 7の専用測定を経ずに、geometry QCの結果だけから導出しない。
8. Yuan et al. (2026)の引用は、原文の主張範囲（review論文としてのgap指摘、Table 3の測定法整理）を超えて拡大解釈しない。特定手法の優劣を同論文が実証したかのように記載しない。
9. Fail・borderline例を隠さず、failure registryへ残す。自動除外は行わない。
10. synthetic demo（`geometry-qc-synthetic.csv`ほか）由来の数値・図は、real pilot dataのセクションへ混在させず、常にsynthetic出典を明示する。

## 8. Out of scope

- corneal construct の生物学的機能、光学性能、臨床適合性についての結論
- ethics / biosafety / 機関の画像利用規定・研究倫理承認の代替
- 「microneedle drug-release-profile roadmapと同一のwet-lab承認」を自動的に本研究へ適用すること（機器・材料・データが異なるため、Gate 0で個別に確認する）
- Young's modulus、transparency、refractive index/power、corneal permeabilityの実測を伴わない、力学的・光学的性能の主張（Gate 7着手前）
- portfolio demo（synthetic data）の結果を、実験的に検証されたfindingとして引用・再利用すること
- 12 construct規模のpilotのみから、印刷手法・材料一般への性能保証を行うこと

## 9. Acceptance checklist

- [ ] `big-lab/corneal-geometry-qc/site/index.html` がfile URLとlocal HTTPの両方で表示できる
- [ ] CSS、JS、hero、reference、templateの相対linkが切れていない
- [ ] geometry error / print-process traceability / extended characterizationの区別がhero直下とmethods sectionの両方にある
- [ ] roadmapに各Gate（0–7）のdeliverableとdecision criterionがある
- [ ] 図に「概念図 / 非実測」の明示がある
- [ ] synthetic demo（12 constructs / 3 batches、`geometry-qc-synthetic.csv`）が、real pilot dataと視覚的・文言的に区別されている
- [ ] Yuan et al. (2026)のgeometry gap指摘とTable 3の測定法整理が、原文の範囲内で正確に引用されている
- [ ] keyboard、mobile、print、reduced-motionを確認している
- [ ] HTML validatorで重大errorがない
- [ ] JavaScript syntax checkが通る

## 10. 未解決事項（Gate 0で確認する質問）

`docs/yunong-yuan-research-guide.md` §8（L216–223）のPI面談質問群と、本roadmap固有のaccess・data・method確認に基づく、Gate 0でPIへ確認する事項:

1. radius error、wall-thickness variation、surface roughness、topographic chordal errorのうち、ラボで再現可能に測るのが現在最も難しいのはどれか。
2. 最初のpilotは、OCT / scan geometry-QC workflowと、bioink・photocrosslinking条件をoutcomeへ結びつけるrun-level registryの、どちらとして始めるのが有用か。
3. 利用可能な既存データはCAD、複数角度写真、structured light scan、OCT、confocal z-stack、instrument CSVのいずれか。
4. 3D scanner / OCT / CAD softwareへのアクセスと、必要なtrainingの有無。
5. dual-layer corneal bioprinting論文（Huang, Yuan et al. 2026）の全文入手可否（現状はURLのみ把握）。
6. surface roughness を design meshからの surface RMSE で代替してよいか、それとも Tier B で classical texture roughness（Ra / Rq等）を別途測る必要があるか（§3.1の operationalizationの妥当性確認）。
7. material / bioink batch と print run の実際の入れ子関係（1つのbatchが複数のprint runに供給されるか、print runごとにbatchを調製するか）。§3.3のhierarchyとgroup化因子の定義に影響する。
