# 要件定義 — Microneedle Drug Release Profile Research Roadmap

文書版: 1.0  
作成日: 2026-07-17  
対象: `big-lab/drug-release-profile/site/index.html`（一覧ハブ: `big-lab/html/index.html`）

## 1. 目的

microneedle drug delivery研究を開始する研究者が、**release、skin permeation、retentionを区別**し、研究質問、分析法、実験、解析、small-data ML、前向き検証を順序立てて進められるlocal-first研究ポータルを提供する。

## 2. 想定利用者

- microneedle / transdermal delivery研究を始める学生・研究補助者
- 実験条件と解析設計をレビューするPI・supervisor
- 既存191-point datasetの再解析を担当するdata analyst

## 3. 必須コンテンツ

### 3.1 研究定義

- release、permeation、retention / recoveryの違い
- primary research question、hypotheses、scope / out-of-scope
- 原論文が直接測定したoutcomeの正確な位置づけ

### 3.2 Roadmap

- Gate 0からGate 7までの段階
- 各Gateに目的、主要タスク、成果物、Go / Hold基準、想定期間
- 0–12週のpilotと、その後のprospective studyを区別
- wet-lab開始前のPI、SOP、ethics、training確認

### 3.3 実験・解析設計

- assay development / validation
- release-only IVRT-like test
- skin permeation test
- endpoint retentionとmass balance
- sampling replacement correction
- experimental hierarchyとgroup-aware validation
- kinetic / mechanistic / ML modelの役割と限界

### 3.4 図表

- microneedle–skin–Franz cellのオリジナル科学イラスト
- releaseからreceptor collectionまでの因果chain
- 概念的なburst / sustained / lagged profile図
- phase roadmap表
- minimum data dictionary表
- model comparison表
- sampling calculation表
- risk register表
- file / reference index表
- 既存Data S1の構造監査chart

### 3.5 研究資産への導線

- 集約済みPDF 4本
- metadata-only文献 1本
- Yuan et al. Data S1 / SI 2 / SI 3
- 依頼メール画像
- charter、data dictionary、sampling plan、experiment log、analysis plan
- 要件定義と実行用指示文

## 4. Functional requirements

| ID | 要件 | 受入条件 |
| --- | --- | --- |
| F-01 | セクションnavigation | desktop / mobileで主要セクションへ移動できる |
| F-02 | 進捗checklist | check状態がbrowser localStorageに保存される |
| F-03 | 進捗表示 | 完了数とpercentageが即時更新される |
| F-04 | Table filter | roadmap phaseをcategoryで絞り込める |
| F-05 | Prompt copy | 実行用指示文を1クリックでclipboardへコピーできる |
| F-06 | Print | print / PDF保存向けlayoutを提供する |
| F-07 | Direct files | local referenceとtemplateを相対linkで開ける |
| F-08 | Offline-first | hero imageを含め、表示にCDNや外部JavaScriptを必須としない |
| F-09 | Reset | checklistを明示操作でresetできる |

## 5. Non-functional requirements

| ID | 要件 | 基準 |
| --- | --- | --- |
| NF-01 | Accessibility | semantic HTML、skip link、keyboard focus、十分なcontrast、SVG title / desc |
| NF-02 | Responsive | 360px幅からdesktopまでhorizontal overflowを抑える |
| NF-03 | Performance | local assetsのみ。heroはlazy loading対象外、その他画像はlazy load |
| NF-04 | Scientific integrity | 実測、文献、推奨、概念図をラベルで区別する |
| NF-05 | Reproducibility | experimental unit、units、provenance、raw/derivedを明示する |
| NF-06 | Privacy | 患者情報・未公開データをHTMLへ埋め込まない |
| NF-07 | Maintainability | CSS / JSを分離し、data attributeでbehaviorを接続する |
| NF-08 | Printability | navigation / controlsを除外し、A4で表とsectionが読める |

## 6. Scientific requirements

1. 累積回収量はsamplingによる取り出しとreplacementを補正する。
2. amount、amount/area、fraction of recovered loadを別列として保存する。
3. nominal loadingとassay-confirmed loadingを混同しない。
4. time pointは独立なexperimental unitとしてsplitしない。
5. primary split unitは最低でもcurve / diffusion cellとし、目的に応じてbatch / donorもgroup化する。
6. kinetic modelはzero-order、first-order、Higuchi、Korsmeyer–Peppas等を比較できるが、適用範囲・geometry・初期区間・残差を確認する。
7. `R²`単独でmodel selectionやmechanism assignmentをしない。AICc、RMSE / MAE、residual、parameter plausibility、外部予測を併記する。
8. release-only、skin permeation、skin retention / recoveryを同じtargetへ混合しない。
9. machine learningはmechanistic baselineより後に実施し、grouped / external validationとuncertaintyを必須にする。
10. acceptance criteriaは結果を見てから設定せず、PIと事前に固定する。

## 7. Out of scope

- 臨床用量・有効性・安全性の結論
- ethics / biosafety / regulatory approvalの代替
- microneedle専用規格が存在するという断定
- 未公開データの公開、購読資料の再配布
- 191-point datasetだけから未知薬物一般化を保証するmodel

## 8. Acceptance checklist

- [ ] `big-lab/drug-release-profile/site/index.html` がfile URLとlocal HTTPの両方で表示できる
- [ ] CSS、JS、hero、reference、templateの相対linkが切れていない
- [ ] release / permeationの区別がhero直下とmethods sectionの両方にある
- [ ] roadmapに各Gateのdeliverableとdecision criterionがある
- [ ] 図に「概念図 / 非実測」の明示がある
- [ ] Data S1の191 rows / 6 payloads / missing group IDsが記載されている
- [ ] FDA IVRT / IVPT guidanceのscope limitationが記載されている
- [ ] keyboard、mobile、print、reduced-motionを確認している
- [ ] HTML validatorで重大errorがない
- [ ] JavaScript syntax checkが通る
