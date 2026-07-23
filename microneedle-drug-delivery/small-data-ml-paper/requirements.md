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
- **絶対に行ってはならないこと(捏造防止 — この節は下流の自律実行モデルが「論文を完成させよう」として無意識に破りやすい。1つでも破れば科学的不正になる)**:
  - RF/XGBoost/GPR/MLR/Gaussian Process 等、**本プロジェクトが一度も訓練していないモデルの定量的性能値(R²、RMSE、MAE、精度、AUC 等)を書かない**。「〜と予想される」「おそらく R²≈0.9」のような推測値・目標値も**数値としては**書かない(定量目標が必要なら「先行研究に匹敵する外挿精度を目指す」のように非数値で書く)。
  - 本プロジェクトのモデルについて SHAP値・feature importance の具体的な数値や順位を、実際に計算していないのに記述しない。
  - Leave-one-drug-out CV、transfer learning、applicability domain 評価の「結果」を書かない — これらは §6(Proposed Methodology / Future Work)に「計画」として書く。
  - 美容成分48件の**予測 log Kp 値を、いかなる出所であれ具体的数値・表・散布図として提示しない**。特に `cosmetic_ingredients_descriptors.csv` には `logKp_PottsGuy_baseline` 列(48行すべて数値入り)が既に存在するが、**これは検証されていない決定論的式の出力であり、本研究の「予測結果」ではない**。この48個の baseline 値を成果・予測として表や図に転記してはならない(§8-7 参照)。提示してよいのは Potts–Guy の**式そのもの**と、その式を将来 baseline として使う**計画**のみ。
  - 実在しない引用文献・DOIを作らない。引用は `research/literature_map_report.md`、`research/microneedle_ml_literature.csv` に載る文献、または `research/CLAUDE.md`「中核となる参考文献」節に列挙された中核5文献に限定する。中核5文献は次のとおり(DOIはCLAUDE.md記載): ①Yuan et al. 2023 `doi:10.1002/btm2.10512` ②Zheng et al. 2023 `doi:10.1038/s44222-023-00141-6` ③Xu et al. 2023 `doi:10.1038/s41524-023-01000-z` ④Achar & Keith 2024 `doi:10.1021/acs.chemrev.4c00957`(**本文入手不可・要旨のみ参照可**なので、要旨で確認できる範囲を超えた内容を帰属させない) ⑤Dou, Zhu, Merkurjev et al. 2023 `doi:10.1021/acs.chemrev.3c00189`。追加文献が必要な場合は、実際にその文献が実在し内容を確認できる場合のみ追加し、確認できない場合は追加しない。
- **区別のための明確化(過剰な自主規制で事実を落とさないために)** — 以下は捏造ではなく、literature/実ファイルに裏づけられた事実として**書いてよい**:
  - Yuan et al. (2023) が**自ら報告した**数値(XGBoost の透過量・透過率 R²=0.98、RF 0.95/0.97、Fick 0.95/0.82、MLR 0.46/0.65、7特徴量、7:3 の train/test 分割、著者らが報告した feature importance の傾向=透過率では MN 表面積と透過時間、透過量では薬剤搭載量と透過時間が支配的、Discussion 4.2 の外挿失敗が薬剤搭載量への過依存に起因すること)は、**先行研究の記載事実**として正確に引用してよい。これらを「本研究が計算した」かのように書かないこと。
  - 添付CSVに実在する件数・記述子・図(`fig1_landscape.png` / `fig2_influence_methods.png`)の数値は事実として引用してよい。
- 上記制約に反する内容が書きかけになっている場合、完成させず「今後のモデル構築フェーズで実施する計画」に書き換えること。判断に迷う数値は**書かない**方を選ぶ。

## 4. 必須コンテンツ(論文の章立て)

1. **Title & Abstract** — proposal/perspectiveであることが読み取れる書き方(例: "toward", "a proposed approach", "we outline"等の表現)。
2. **Introduction** — microneedle drug delivery の背景、Yuan et al. (2023) の到達点と限界(Discussion 4.2節: 191点・6薬剤の小規模訓練データによる新規薬剤への外挿誤差)、本論文の立ち位置(proposalである旨)を明記。
3. **Related Work / Literature Landscape** — `literature_map_report.md` のテーマ構成、2015–2026の急成長トレンド(2024年16本→2025年22本→2026年30本、コーパスの59%が2024年以降)、著者・拠点(Silpakorn / Stockholm / Surrey の3クラスタ、Lian 6本ほか)、Figure 1・Figure 2 を実データとして引用。図の記述は実物に厳密に合わせること:
   - **注意(件数の言い方)**: 本文では「5つの主要テーマクラスタ」(QSAR 48、formulation 18、microneedle-ML 17、molecular dynamics 14、FEM 8)+「3つの小クラスタ」(nanoparticle 7、reviews 3、physical-enhancement 1)と表現できるが、**Figure 1b は合計8カテゴリの棒**(合計116本)を示す。図キャプションを「5クラスタ」と書くと図と矛盾するので、キャプションは「8つのテーマカテゴリ」と記述する。
   - **Figure 1** (`fig1_landscape.png`): (a) 2015–2026の年別出版数の積み上げ棒(2026は partial)、(b) テーマ別構成(n=116、8カテゴリ)。
   - **Figure 2** (`fig2_influence_methods.png`): (a) 被引用数上位の論文(Crossref、対数軸: Roberts 2021=196、Lundborg 2018=123 等)、(b) 使用手法の分布(tree ensembles/mixed ML 25、QSAR/QSPR 21、review 19、NN/DL 15、MD 10 等)。Figure 2 は §5「著者・拠点/影響力」と本§4「手法landscape」の両方の根拠として引用してよい。
4. **Research Gap** — literature_map_report.md §6 は4つのgap(①データ希少性・標準化不足、②QSAR–microneedleモデル間の断絶、③physics-ML融合の欠如、④生成・基盤モデルの不在)を挙げる。本研究は主に①〜③に対応する(④は言及にとどめる)。RESEARCH_PLAN.md / CLAUDE.md の力点(transfer learning、物理モデル併用データ拡張、applicability domain厳格化)をここに接続する。**精度上の注意**: Yuan (2023) は「外挿を全く検証していない」わけではない — 学習セットから薬剤を意図的に除外して予測する**定性的**チェック(Figure S1/S2)を行い大きな乖離を示した。本研究の新規性は、これを systematic な leave-one-drug-out 交差検証で**定量化**する点にあるので、「Yuanは外挿未検証」と誤記しないこと。
5. **Completed Preliminary Work(実測として報告可)** —
   - 文献マップ構築(Crossref/PubMed、990件→116件に絞り込み)
   - 皮膚透過性データセット統合(HuskinDB 129件 + SkinPiX 103件 + INRS 3件 → 重複除去後214化合物)
   - Yuan et al. (2023) 訓練データの完全再現(PMC10658566 Data S1より191点・6薬剤: lidocaine 73, BSA 33, copper ions 24, GHK peptide 24, Rhodamine B 19, caffeine 18)
   - 美容成分48件の構造・記述子取得(PubChem由来、RDKit記述子計算)
   - 分子記述子計算パイプライン(`descriptors.py`)とPotts–Guy baseline式の実装
   - 化学空間(MW・LogP)によるapplicability domainの初期スクリーニング: **48件中38件が範囲内、10件が範囲外**。範囲内38件のうち4件(Niacinamide, Urea, Salicylic acid, Ethanol)は既に214化合物訓練セットに実測値がある。これらは実測comparatorとして使え、モデル開発の全工程から除外した場合に限りintact-skin log Kpの直接holdout検証に使える(マイクロニードル処理皮膚の累積透過を直接検証する値ではない)。差し引き**34件が「範囲内かつ未実測」の新規予測候補**。(注: 元CSVの `in_MW_domain`/`in_LogP_domain` 両方 true が38件。34ではなく38が「範囲内」の正しい総数。)
6. **Proposed Methodology / Future Work(明示的に未実施と分かる書き方)** — RESEARCH_PLAN.mdフェーズ2〜6の内容(データキュレーション、4A/4Bモデル構築、leave-one-drug-out CV、transfer learning、物理モデルベースのデータ拡張、SHAP解釈、美容成分への適用)を計画として記述。
7. **Anticipated Contributions** — この研究が実施された場合に期待される学術的貢献(小規模データの外挿性改善という一般的課題への寄与、化粧品応用への橋渡し)。
8. **Limitations** — 6薬剤という検証薬剤数の少なさ、美容成分側の実測透過性データ欠如、単一ラボ・単一データセットへの依存、化学空間外10件の扱いなど。
9. **Data & Ethics Statement** — すべて公開データベース・既刊論文の補足データの二次利用であり、新規のヒト・動物実験を伴わないこと、購読資料の再配布はしないこと。
10. **References** — literature_map_report.md / microneedle_ml_literature.csv 由来の文献 + CLAUDE.md「中核となる参考文献」節の中核5文献 + データベース出典(HuskinDB `doi:10.1038/s41597-020-00764-z`, SkinPiX `doi:10.57745/7FHQOY`, 統合QSPRデータセット `doi:10.57745/ZUU1DH`)。DOIはすべてCLAUDE.md「データ出典」節と照合すること。

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
- `microneedle-drug-delivery/references/translated  papers/01-yuan-2023-drug-permeation-microneedled-skin-ml-ja.md`(Yuan 2023 本文の日本語訳。R²=0.98・Discussion 4.2・7特徴量・7:3分割など、Yuan由来の記述事実の一次確認先。フォルダ名の `translated` と `papers` の間はスペース2つ)
- `microneedle-drug-delivery/drug-release-profile/`(release/permeation/retentionの区別など、関連する既存の要件定義)
- `shared/references/papers/yunong-yuan/`(PIの既存論文。文脈確認用。過度な引用は避け、事実確認できる範囲で言及)

## 6. Functional requirements

| ID | 要件 | 受入条件 |
| --- | --- | --- |
| F-01 | 論文本文 | `small-data-ml-paper/paper.md` に完成した論文本文が存在する |
| F-02 | 言語 | 論文本文(`paper.md`)は英語。README/requirements/implementation-prompt/decision-logは日本語(ワークスペースの既存慣行に合わせる) |
| F-03 | HTML同期 | `AGENTS.md` の規則に従い、`paper.md` を含む全Markdownの先頭本文行に `[HTML版を開く](該当ファイル名.html)` を付与し、`shared/scripts/build-website.sh` 実行後に対応するHTMLが生成されること |
| F-04 | 図表再利用 | `fig1_landscape.png` / `fig2_influence_methods.png` を実データ図として本文に埋め込み、キャプションに出典(`research/`配下のファイル)を明記する |
| F-05 | 文献引用 | 本文で言及した文献はすべて `microneedle_ml_literature.csv` または `CLAUDE.md`「中核となる参考文献」節の中核5文献(§3に列挙)のいずれかに存在し、DOIが一致する |
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
2. Yuan et al. (2023) の記述(手法、XGBoost R²=0.98、Discussion 4.2節の外挿限界)は**Yuanの報告値**として正確に引用し、誇張・改変せず、本研究の成果と取り違えない。
3. 214化合物データセット、191点データセット、48件の美容成分データセットの件数・出典は元CSVと完全に一致させる(214 = HuskinDB 129 + SkinPiX 103 + INRS 3 の重複除去後; 191 = 6薬剤の合計; 48 = 美容成分)。
4. 美容成分の化学空間適合性は**48件中38件がMW・LogP範囲内、10件が範囲外**(34ではない — 34は「範囲内かつ未実測」の内数)として事実報告してよいが、それに基づく「予測性能」は主張しない。範囲外10件を記述する場合は「高分子量脂質」と一括りにしない — 実際は大半が極端なLogP(squalane・tocopherol・CoQ10 のような高親油性、ascorbyl phosphate 類のような高親水性の両方)による範囲外である。元CSVで `in_MW_domain=False` は3件(CoQ10、Madecassoside、Asiaticoside)、`in_LogP_domain=False` は8件、両方falseは1件で、和集合が10件である。別指標の `large_molecule_flag=True`(MW>500)は6件であり、MW domain外の件数と混同しない。「訓練化学空間(MW・LogP)の外」と書くのが安全。
5. Potts–Guy baseline式(`descriptors.py::potts_guy_baseline`: log Kp = -2.7 + 0.71·logP − 0.0061·MW)の**式自体**の引用は可(公表式)。ただしこのbaselineを本データセット(美容成分・214化合物)に適用した**具体的な性能値や per-compound 予測値**は、実際に計算・検証していない限り記載しない。
6. 図表に用いる数値はすべて添付CSV・既存PNGに実在する値のみとする。新規の表・図を推定値/目標値で作らない。
7. **`cosmetic_ingredients_descriptors.csv` の `logKp_PottsGuy_baseline` 列は48行すべて数値入りだが、これは未検証の式出力であって本研究の「予測結果」ではない。**この48値を予測・成果として表・散布図・本文に転記しない(§3の捏造防止と同一趣旨)。descriptor 列(MW/LogP/TPSA等)は分子の物性値なので記述に使ってよいが、`logKp_PottsGuy_baseline` は結果として扱わない。

## 9. Out of scope

- **モデリング/計算コードの実行を一切行わない。これは執筆タスクであって計算タスクではない。** 具体的には、`research/descriptors.py` を含む一切の Python・R スクリプトを**この論文のために実行しない**。モデル訓練、交差検証、SHAP計算、Potts–Guy値や記述子の再計算、予測の生成をしない。`research/requirements.txt` に `rdkit`/`xgboost`/`scikit-learn`/`shap` 等が並んでいても、それは将来の別タスク用であり、`pip install` も実行もしない。
  - 許可される操作は「`research/` 配下のファイルを**読んで**件数・値・関数名を確認し引用すること」まで。実行してよいスクリプトは**ドキュメントビルドの `shared/scripts/build-website.sh`(とそれが内部で呼ぶビルド/リンク検証スクリプト)のみ**で、これはモデリングではなく Markdown→HTML 変換である。
- 新規のモデル訓練・交差検証・SHAP計算(内容としても — 別タスクとして今後実施)
- 美容成分の実測皮膚透過性データの新規収集
- 投稿ジャーナルの選定・実際の投稿手続き
- wet-lab実験の設計・実施(`drug-release-profile/`の管轄)
- 未公開データ・購読資料本文の転載

## 10. Acceptance checklist

- [ ] `paper.md` が存在し、§4の10章立てをすべて含む
- [ ] フェーズ2以降の内容が「未実施・計画」であると明記されている(本研究のモデルに関する R²/RMSE/精度/SHAP/feature importance/予測 log Kp の**具体的数値・推測値が一切ない**)
- [ ] Yuan (2023) 由来の報告値(R²=0.98 等)は「先行研究の値」として引用され、本研究の成果と混同されていない
- [ ] `logKp_PottsGuy_baseline` の48値や、その他のモデル予測値が「予測結果」として表・図・本文に転記されていない(§3・§8-7)
- [ ] モデリング/計算コード(`descriptors.py` 等)を一切実行していない。実行したスクリプトは `build-website.sh` 系のみ(§9)
- [ ] 引用文献がすべて実在し、`microneedle_ml_literature.csv` または CLAUDE.md 中核5文献と照合でき、DOIが一致する
- [ ] Figure 1・Figure 2が実データ図として埋め込まれ、出典(`research/` 配下ファイル名)が明記され、キャプションが実物と整合(Fig 1b は「8テーマカテゴリ」表記)
- [ ] データセットの件数(214, 191, 48, 116)が元資料と一致し、美容成分の domain 内訳が **38 in / 10 out**(34ではない)で記述されている
- [ ] `[HTML版を開く]` リンクが全Markdownファイルの先頭本文行(front matterがあれば `---` 直後)にあり、リンク先が同名 `.html`
- [ ] `shared/scripts/build-website.sh` がエラーなく完走し、対応するHTMLが生成・検証される
- [ ] `notes/decision-log.md` に本タスクのパイプライン(sonnet→fable→codex-terra→codex-sol)と主要判断が記録されている
