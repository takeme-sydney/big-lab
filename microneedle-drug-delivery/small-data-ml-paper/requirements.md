[HTML版を開く](requirements.html)

# 要件定義 — Small-Data ML for Microneedle Drug Permeation: A Perspective & Research-Proposal Paper

文書版: 1.0
作成日: 2026-07-20
対象: `big-lab/microneedle-drug-delivery/small-data-ml-paper/paper.md`
根拠資料: `big-lab/microneedle-drug-delivery/research/`（RESEARCH_PLAN.md, CLAUDE.md, literature_map_report.md, 各種CSV, descriptors.py, 図表）

## 1. 目的

`microneedle-drug-delivery/research/` に蓄積された研究準備内容(文献マップ116本、実測皮膚透過性データ214化合物、Yuan et al. (2023) の191点データセット再現、美容成分48件の記述子)を土台に、**論文（Perspective / Research proposal manuscript）を1本書き上げる**。

この論文は **新規の計算結果を報告しない**。すでに完了した作業(文献マップ、データ収集・統合、Yuan 2023データの再現、記述子計算パイプライン)は実測の成果として正確に報告し、RESEARCH_PLAN.md フェーズ2〜6(データキュレーション、モデル構築、transfer learning、SHAP解析、美容成分予測)は **明示的に「未実施・今後の計画」として** 記述する。目的は、Yunong Yuan (PI) と共有し、この研究方向の literature command と methodology の健全性を示す、査読可能な水準の草稿を用意することである。

## 2. 想定読者

- Yunong Yuan (PI, University of Sydney Biomedical Innovation Group) — 研究方向の妥当性を評価する読者
- 将来この研究に参加する学生・研究補助者 — 背景と計画を把握するための読者
- (将来的な拡張として)*Pharmaceutics*, *International Journal of Pharmaceutics*, *Journal of Controlled Release* 等、literature_map_report.md が特定した主要投稿先ジャーナルの査読者を意識した文体

## 3. 論文の位置づけ・ジャンル(最重要制約)

- ジャンル: **Perspective / Research proposal manuscript**(完了した実証研究の報告ではない)。
- 本文中で「本論文は着手前の研究計画であり、フェーズ4〜6のモデル構築・検証は実施していない」ことを Introduction 末尾か Methods 冒頭で明示すること。
- **絶対に行ってはならないこと(捏造防止)**:
  - RF/XGBoost/GPR の R²、RMSE、精度、AUC等、**一度も実行していないモデルの定量的性能値を書かない**。
  - SHAP値、feature importance の具体的な数値や順位を、実際に計算していないのに記述しない。
  - Leave-one-drug-out CV、transfer learning、applicability domain評価の「結果」を書かない — これらは §6(Proposed Methodology / Future Work)に「計画」として書く。
  - 美容成分48件の「予測されたlog Kp値」を具体的数値として提示しない — 予測パイプラインの設計のみ記述する。
  - 実在しない引用文献・DOIを作らない。引用は `research/literature_map_report.md`、`research/microneedle_ml_literature.csv`、RESEARCH_PLAN.md記載の5篇の中核文献に限定する。追加文献が必要な場合は、実際にその文献が実在し内容を確認できる場合のみ追加し、確認できない場合は追加しない。
- 上記制約に反する内容が書きかけになっている場合、完成させず「今後のモデル構築フェーズで実施」に書き換えること。

## 4. 必須コンテンツ(論文の章立て)

1. **Title & Abstract** — proposal/perspectiveであることが読み取れる書き方(例: "toward", "a proposed approach", "we outline"等の表現)。
2. **Introduction** — microneedle drug delivery の背景、Yuan et al. (2023) の到達点と限界(Discussion 4.2節: 191点・6薬剤の小規模訓練データによる新規薬剤への外挿誤差)、本論文の立ち位置(proposalである旨)を明記。
3. **Related Work / Literature Landscape** — `literature_map_report.md` の5クラスタ構成、2015–2026の急成長トレンド、著者・拠点、Figure 1 (`fig1_landscape.png`)・Figure 2 (`fig2_influence_methods.png`) を実データとして引用。
4. **Research Gap** — literature_map_report.md §6の3つのgap(データ標準化不足、QSAR–microneedleモデル間の断絶、physics-ML融合の欠如)+ RESEARCH_PLAN.mdの力点(transfer learning、物理モデル併用データ拡張、applicability domain厳格化)。
5. **Completed Preliminary Work(実測として報告可)** —
   - 文献マップ構築(Crossref/PubMed、990件→116件に絞り込み)
   - 皮膚透過性データセット統合(HuskinDB 129件 + SkinPiX 103件 + INRS 3件 → 重複除去後214化合物)
   - Yuan et al. (2023) 訓練データの完全再現(PMC10658566 Data S1より191点・6薬剤)
   - 美容成分48件の構造・記述子取得(PubChem由来、RDKit記述子計算)
   - 分子記述子計算パイプライン(`descriptors.py`)とPotts–Guy baseline式の実装
   - 化学空間(MW・LogP)によるapplicability domainの初期スクリーニング(48件中34件が範囲内)
6. **Proposed Methodology / Future Work(明示的に未実施と分かる書き方)** — RESEARCH_PLAN.mdフェーズ2〜6の内容(データキュレーション、4A/4Bモデル構築、leave-one-drug-out CV、transfer learning、物理モデルベースのデータ拡張、SHAP解釈、美容成分への適用)を計画として記述。
7. **Anticipated Contributions** — この研究が実施された場合に期待される学術的貢献(小規模データの外挿性改善という一般的課題への寄与、化粧品応用への橋渡し)。
8. **Limitations** — 6薬剤という検証薬剤数の少なさ、美容成分側の実測透過性データ欠如、単一ラボ・単一データセットへの依存、化学空間外10件の扱いなど。
9. **Data & Ethics Statement** — すべて公開データベース・既刊論文の補足データの二次利用であり、新規のヒト・動物実験を伴わないこと、購読資料の再配布はしないこと。
10. **References** — literature_map_report.md / microneedle_ml_literature.csv 由来の文献 + RESEARCH_PLAN.mdの中核5文献 + データベース出典(HuskinDB, SkinPiX, 統合QSPRデータセット)。

## 5. 使用可能な情報源(これ以外を根拠にしない)

- `microneedle-drug-delivery/research/RESEARCH_PLAN.md`
- `microneedle-drug-delivery/research/CLAUDE.md`
- `microneedle-drug-delivery/research/README.md`
- `microneedle-drug-delivery/research/literature_map_report.md`
- `microneedle-drug-delivery/research/microneedle_ml_literature.csv`
- `microneedle-drug-delivery/research/cosmetic_ingredients_descriptors.csv`
- `microneedle-drug-delivery/research/skin_permeability_training_set.csv`
- `microneedle-drug-delivery/research/yuan2023_training_data.csv` / `yuan2023_dataset_with_descriptors.csv`
- `microneedle-drug-delivery/research/descriptors.py`
- `microneedle-drug-delivery/research/fig1_landscape.png`, `fig2_influence_methods.png`(実データ図として再利用。新規図を捏造データで作らない)
- `microneedle-drug-delivery/drug-release-profile/`(release/permeation/retentionの区別など、関連する既存の要件定義)
- `shared/references/papers/yunong-yuan/`(PIの既存論文。文脈確認用。過度な引用は避け、事実確認できる範�囲で言及)

## 6. Functional requirements

| ID | 要件 | 受入条件 |
| --- | --- | --- |
| F-01 | 論文本文 | `small-data-ml-paper/paper.md` に完成した論文本文が存在する |
| F-02 | 言語 | 論文本文(`paper.md`)は英語。README/requirements/implementation-prompt/decision-logは日本語(ワークスペースの既存慣行に合わせる) |
| F-03 | HTML同期 | `AGENTS.md` の規則に従い、`paper.md` を含む全Markdownの先頭本文行に `[HTML版を開く](該当ファイル名.html)` を付与し、`shared/scripts/build-website.sh` 実行後に対応するHTMLが生成されること |
| F-04 | 図表再利用 | `fig1_landscape.png` / `fig2_influence_methods.png` を実データ図として本文に埋め込み、キャプションに出典(`research/`配下のファイル)を明記する |
| F-05 | 文献引用 | 本文で言及した文献はすべて `microneedle_ml_literature.csv` またはRESEARCH_PLAN.mdの5中核文献のいずれかに存在し、DOIが一致する |
| F-06 | ファイル構成 | `README.md`, `requirements.md`, `implementation-prompt.md`, `paper.md`, `notes/decision-log.md` が `small-data-ml-paper/` 配下に揃っている |

## 7. Non-functional requirements

| ID | 要件 | 基準 |
| --- | --- | --- |
| NF-01 | 分量 | 論文本文(参考文献リストを除く)はおおよそ4,000〜6,500語 |
| NF-02 | Scientific integrity | §3の捏造防止制約を厳守。実測・文献記載事実・提案/計画を明確に区別する語彙("we assembled", "we propose", "future work will"等)を一貫して使う |
| NF-03 | Reproducibility | 「完了した作業」として書く内容は、必ず対応する実ファイル(CSV行数、descriptors.py関数名等)で裏付けられること |
| NF-04 | Privacy/copyright | 購読論文本文の転載・再配布をしない。引用は書誌情報とDOIのみ |
| NF-05 | Consistency | `drug-release-profile/` 側の用語定義(release / permeation / retentionの区別)と矛盾しない |
| NF-06 | Style | Perspective論文としての体裁(見出し構成、能動的だが控えめな主張、hedging language)を守る |

## 8. Scientific requirements

1. 完了済みフェーズ(0, 1, 1.5)の内容のみを「結果」として提示し、フェーズ2以降は「計画」として提示する。
2. Yuan et al. (2023) の記述(手法、R²=0.98、Discussion 4.2節の限界)は原論文の記載を正確に引用し、誇張・改変しない。
3. 214化合物データセット、191点データセット、48件の美容成分データセットの件数・出典は元CSVと完全に一致させる。
4. 美容成分の化学空間適合性(48件中34件がMW・LogP範囲内、10件が範囲外)は事実として報告してよいが、それに基づく「予測性能」は主張しない。
5. Potts–Guy baseline式(`descriptors.py::potts_guy_baseline`)の式自体の引用は可(既存の公表式であるため)。ただしこのbaselineを本データセットに適用した具体的な性能値は、実際に計算していない限り記載しない。
6. 図表に用いる数値はすべて添付CSV・既存PNGに実在する値のみとする。

## 9. Out of scope

- 新規のモデル訓練・交差検証・SHAP計算の実行(このパイプライン内では行わない — 別タスクとして今後実施)
- 美容成分の実測皮膚透過性データの新規収集
- 投稿ジャーナルの選定・実際の投稿手続き
- wet-lab実験の設計・実施(`drug-release-profile/`の管轄)
- 未公開データ・購読資料本文の転載

## 10. Acceptance checklist

- [ ] `paper.md` が存在し、§4の10章立てをすべて含む
- [ ] フェーズ2以降の内容が「未実施・計画」であると明記されている(具体的な数値結果が一切ない)
- [ ] 引用文献がすべて実在し、`microneedle_ml_literature.csv` またはRESEARCH_PLAN.md中核5文献と照合できる
- [ ] Figure 1・Figure 2が実データ図として埋め込まれ、出典が明記されている
- [ ] データセットの件数(214, 191, 48, 116)が元資料と一致する
- [ ] `[HTML版を開く]` リンクが全Markdownファイルの先頭本文行にある
- [ ] `shared/scripts/build-website.sh` がエラーなく完走し、対応するHTMLが生成・検証される
- [ ] `notes/decision-log.md` に本タスクのパイプライン(sonnet→fable→codex-terra→codex-sol)と主要判断が記録されている
