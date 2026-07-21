[HTML版を開く](requirements.html)

# 要件定義 — Transfer Learning for Small-Data Microneedle Drug Permeation QSAR: Executing RESEARCH_PLAN.md Phases 2–6

文書版: 1.0
作成日: 2026-07-21
対象: `big-lab/microneedle-drug-delivery/transfer-learning-paper/paper.md`(新規)
根拠資料: `big-lab/microneedle-drug-delivery/research/`(全データ・コード・計画文書)

## 1. 目的

`research/RESEARCH_PLAN.md`はフェーズ0・1・1.5のみ完了しており、フェーズ2〜6(データキュレーション、EDA、2系統のモデル構築、転移学習、物理モデル併用データ拡張、SHAP解析、美容成分への応用、最終論文)は未着手である。本モジュールは、この未着手フェーズを**実際に計算・実行し**、real, newly-computed resultsを報告する研究論文として完成させる。

これは[`../small-data-ml-paper/`](../small-data-ml-paper/)(Perspective/proposal論文、新規計算結果を一切含まない)とも[`../active-learning-paper/`](../active-learning-paper/)(既に完了済みの計算を書き上げるresearch note)とも性格が異なる: **本モジュールでは実際に新しいコードを書き、実際に実行し、実際の出力から論文を書く。** 計算タスクであり執筆タスクではない、という点が他2モジュールと逆である。

## 2. 想定読者

- Yunong Yuan(PI)— モデルの実用性・次の実験計画への示唆を評価する読者
- 将来この研究に参加する学生・研究補助者
- (将来的な拡張として)QSAR/QSPR・small-data ML分野の専門誌の査読者

## 3. 論文の位置づけ・ジャンル(最重要制約 — 他モジュールとは逆方向の規律)

- ジャンル: **実計算に基づく研究論文(Research article)**。新規モデル構築・転移学習・物理モデル併用データ拡張・SHAP解析・応用予測を実際に実行し、その結果を報告する。
- **絶対に行ってはならないこと**:
  - **`paper.md`に書く実質的な数値(R²、RMSE、LODO性能、SHAP値、予測logKp値など)は、すべて本モジュールの中で実際に実行したPythonスクリプトが生成し保存したファイル(CSV/画像)に直接たどれるものに限る。** 実行せずに「妥当と思われる数値」を書かない。既存文献(Yuan et al. 2023等)の既報値を引用する場合は"Yuan et al. reported"等の帰属を明示し、本研究の結果と混同しない。
  - **[`../active-learning-paper/`](../active-learning-paper/)の3結果CSV(`active_learning_curves_within_distribution.csv`等)・[`../small-data-ml-paper/`](../small-data-ml-paper/)の記述内容を、本モジュール自身の計算結果として転用・転記しない。** 参照する場合は`git show <branch>:<path>`のみ。
  - **214化合物データセット(`skin_permeability_training_set.csv`)による予測を、実験未実施のマイクロニードル固有パラメータ(薬剤負荷量・MN長・MN表面積・透過時間など)込みの「マイクロニードル送達性能予測」であるかのように書かない。** 美容成分48件のデータセット(`cosmetic_ingredients_descriptors.csv`)にはこれらのマイクロニードル実験パラメータが存在しない(§4 Phase 5-4で詳述)。これらのパラメータを仮定・捏造して4Bモデルに通すことは禁止。48成分の応用は**皮膚透過性の一般的スクリーニング(4Aモデル)** として扱い、「マイクロニードル送達に適するか」は4Aの一般皮膚透過性予測からの示唆にとどめ、断定しない。
  - **物理モデル併用データ拡張(Phase 4B-5)で生成する疑似データ点を、実測データと混同・合算しない。** 疑似データには明示的なフラグ列(例: `is_synthetic`)を付与し、本文・図表・件数表記のいずれでも実測214件・191件と混ざらないようにする。
  - Yuan et al. (2023)の既報値(XGBoost R²=0.98等)を本研究が計算したかのように書かない。
  - 実在しない引用文献・DOIを作らない。引用は`research/CLAUDE.md`「中核となる参考文献」節の中核5文献、`research/literature_map_report.md`の116件の文献リスト(`microneedle_ml_literature.csv`)、またはこれらに実在が確認できる追加文献に限る。
  - 転移学習・物理モデル拡張について、実装不可能な手法(深層学習フレームワーク等、`research/requirements.txt`に無い依存)を前提とした記述をしない。§4 Phase 4B-3, 4B-5に指定する具体的手法を用いる(正当な理由があれば代替可、ただし`notes/decision-log.md`に理由を記録すること)。
- **区別のための明確化**: §4の各Phaseで実際に計算し保存した数値は、"we found"/"we show"等の確定的な語彙で報告してよい。ネガティブな結果(転移学習が改善しない、LODOが依然として悪い等)も、Yuan et al.自身の限界報告やactive-learning-paperの誠実な報告姿勢に倣い、隠さず正直に報告する。

## 4. 必須コンテンツ(フェーズ別マイルストーン)

`research/RESEARCH_PLAN.md`の未着手項目を、以下の順序でマイルストーンとして実行する。各マイルストーンは独立してチェックポイント可能とし、時間・実行環境の制約で全てを完了できない場合は、**完了したマイルストーンまでを確定させ、`notes/decision-log.md`に未完了部分を明記して次段階(Codex-sol)に引き継ぐ**(捏造で埋めるより正直な未完の方が良い)。

新規スクリプトは`research/`直下に置く(既存の`descriptors.py`, `active_learning.py`と同じ配置。生成物 — CSV・PNG — も`research/`直下)。`transfer-learning-paper/`には論文本文・要件文書のみを置き、コード・データは置かない(既存2モジュールと同じ規約)。全スクリプトで`RANDOM_STATE = 42`を使用する(`CLAUDE.md`規約)。

### Phase 2 — データキュレーション(前提作業)

- **2-1(必須)**: `skin_permeability_training_set.csv`(214行)の外れ値・整合性チェック。**注意**: `RESEARCH_PLAN.md`は「SkinPiXのnotes列のsuspicious pointフラグ確認」を挙げているが、実際にこのCSVには`notes`列や"suspicious"に類するフラグ列は存在しない(§5で確認済み)。生データ(HuskinDB/SkinPiX原本)がこのリポジトリに存在するかも`research/`配下で確認し、無ければ統計的手法(logKp_cm_hの分布に対するIQR/z-score、または記述子空間でのレバレッジ)による外れ値検出に代替する。この代替の理由を`notes/decision-log.md`に記録する。
- **2-2(必須)**: `canon_smiles`列の重複チェック(同一化合物が複数行に存在し、`logKp_cm_h`が矛盾していないか)。
- **2-3(任意・厳格なゲート付き)**: 美容成分特化データの追加収集(目標20〜30件、`RESEARCH_PLAN.md`フェーズ2)。**実在する文献引用(著者・誌名・年・DOIまたはURL)を提示できるデータ点のみ追加可。1件も確認できない場合は追加せず、その旨を記録する。** これは達成目標であり必須要件ではない。

### Phase 3 — 探索的データ分析(EDA)

- 214化合物データセットの`logKp_cm_h`分布(ヒストグラム)、記述子間相関行列・VIF、美容成分カテゴリ別(`cosmetic_ingredients_descriptors.csv`の`category`列、親水性=LogP低 vs 親油性=LogP高)の透過性傾向可視化。

### Phase 4A — 皮膚透過性QSARモデル(化粧品成分向け、214化合物データセット)

- ベースライン: `descriptors.py`の`potts_guy_baseline`関数(既存実装を確認して使用。再実装しない)。
- MLR, Random Forest, XGBoost, Gaussian Process Regression(`sklearn.gaussian_process`)の比較。
- **5-fold交差検証**(`CLAUDE.md`規約通り、単純train/test splitは不可 — 214件のみのため)。
- Applicability Domain: レバレッジ法(hat行列対角、Williams plot相当)。`cosmetic_ingredients_descriptors.csv`に既存の`in_MW_domain`/`in_LogP_domain`列との整合性を確認する(矛盾があれば`notes/decision-log.md`に記録)。

### Phase 4B(優先)— Yuan 2023マイクロニードルモデルの再現・改良

- **4B-1(再現)**: `yuan2023_dataset_with_descriptors.csv`(191行、6薬剤)の元の7特徴量(薬剤負荷量・薬剤分子量・MN長・皮膚タイプ・MNタイプ・MN表面積・透過時間)を用い、Yuan et al. (2023)の4手法(Fick則・MLR・RF・XGBoost)を再現する。**検証方法はYuan et al. (2023)本文(`references/translated  papers/01-yuan-2023-drug-permeation-microneedled-skin-ml-ja.md`)が実際に使った分割方法を確認し、可能な限り同じ方法で再現する**(単純に5-fold CVを当てはめて数値が異なる場合、それを「再現の失敗」ではなく「検証方法の違い」として明記する)。報告済みXGBoost R²=0.98との近さ・乖離を正直に報告する。
- **4B-2(LODO、必須)**: Leave-one-drug-out交差検証。**[`../active-learning-paper/`](../active-learning-paper/)のLODO(能動学習プールを用いた、RF評価器固定の獲得戦略比較)とは目的が異なる** — 本タスクのLODOは、各foldで残り5薬剤の全データを学習に使い(能動学習的なプール制限なし)、Yuan 2023の主要手法(RF・XGBoostは必須、Fick・MLRは可能なら)で外挿性能(Yuan論文が定性的にしか示していない乖離)を定量評価する。
- **4B-3(転移学習、必須 — 具体的手法を指定)**: **推奨手法(特徴量転移)**: (a) 214化合物データセットで皮膚透過性の一般モデル(Phase 4Aの最良モデル)を学習する。(b) Yuan データセット中、RDKit記述子を持つ4薬剤(lidocaine, GHK peptide, Rhodamine B, caffeine — `is_small_molecule=True`)についてのみ、この一般モデルによる予測値を新規特徴量(`predicted_general_skin_logKp`)として追加し、8特徴量モデルを学習・LODO評価する。(c) BSA・copper ions(`is_small_molecule=False`、RDKit記述子が構造的に適用不可)は、この転移学習強化モデルの対象**外**とし、元の7特徴量モデル(4B-1/4B-2)には引き続き含めて比較する。この除外理由(タンパク質・金属イオンにRDKit記述子は適用できない)を本文で明記し、隠さない。**代替手法を用いる場合**(Xu 2023・Dou 2023が整理する他の転移学習戦略でも可)、その選択理由を`notes/decision-log.md`に記録すること。7特徴量モデル(4B-1/2)と8特徴量転移学習モデルのLODO性能を比較し、改善の有無を正直に報告する(改善しなくても良い結果として報告する — active-learning-paperの前例に倣う)。
- **4B-4(特徴量重要度の偏り是正、必須)**: 4B-1の再現モデルで特徴量重要度(またはSHAP、Phase 5で本格実施)を計算し、Yuan論文が指摘する「薬剤負荷量への過度な依存」を定量的に確認する。是正手法(例: 正則化・max_depth制限・薬剤負荷量の重み低減・アンサンブル)を最低1つ試し、LODO性能への影響を報告する(改善してもしなくても正直に報告)。
- **4B-5(物理モデル併用データ拡張、必須 — 疑似データの明示フラグ必須)**: `descriptors.py::potts_guy_baseline`(Potts-Guy式、既存実装)、または`drug-release-profile/references/supplementary/07-yuan-2023-code-si2.docx`(Yuan 2023のFick則実装、SI2)が読み取り可能であればその式、のいずれかを用いて、化学空間(MW・LogP)グリッド上に疑似データ点を生成し、214化合物データセットまたはYuanデータセットを拡張して4A/4Bモデルを再学習し、性能変化を報告する。**疑似データ点には必ず`is_synthetic_physics_augmented=True`等のフラグを付与し、実測データ件数(214件・191件)との合算表記を一切行わない。** SI2 docxが読み取れない場合はPotts-Guy式を使用し、その旨を記録する。

### Phase 5 — 解釈・応用

- SHAP値による特徴量重要度分析(4A・4Bモデル双方)。
- LODO性能比較: 改良モデル(4B-3転移学習後)vs Yuan 2023オリジナル(4B-1再現)。
- 4Aモデル(医薬品ベース)と4Bモデル(マイクロニードル特化)の予測精度比較。
- **美容成分48件への応用(重要な範囲限定)**: `cosmetic_ingredients_descriptors.csv`には薬剤負荷量・MN長・MN表面積・透過時間等のマイクロニードル実験パラメータが存在しない(分子記述子のみ)。したがって48成分の予測は**4Aモデル(一般皮膚透過性QSAR)による`logKp`予測**にとどめ、Applicability Domainフラグ(既存`in_MW_domain`/`in_LogP_domain`列、または4A-ADの結果)を付与する。**マイクロニードル実験パラメータを仮定して4Bモデルに通すことは、実施しない実験を実施したかのように書く捏造に相当するため禁止。** マイクロニードル送達への適性は、4Aの一般皮膚透過性予測からの「示唆」としてのみ論じ、断定的なマイクロニードル送達性能予測とは書かない。

### Phase 6 — 成果物整理

- 図表(既存図`fig1_landscape.png`等と視覚的に一貫したスタイルのmatplotlib図。ワークスペース内に実体を伴う`figure-style`スキル・設定ファイルは確認できなかった — 既存4図との統一感を優先する)。
- `paper.md`草稿(英語、Abstract〜Referencesの構成、§4の全マイルストーン結果を統合)。
- `research/RESEARCH_PLAN.md`のフェーズ2〜6チェックリストのうち、実際に完了した項目のみ`- [x]`に更新し、本モジュールへのクロスリンクを追記する(未完了の項目は`- [ ]`のまま残す — 実施していないことを実施したかのように書かない)。

## 5. 使用可能な情報源

- `microneedle-drug-delivery/research/CLAUDE.md`, `RESEARCH_PLAN.md`
- `microneedle-drug-delivery/research/skin_permeability_training_set.csv`(214行。列: MW, LogP, TPSA, HBD, HBA, RotB, NumRings, NumAromaticRings, FractionCSP3, MolarRefractivity, NumHeteroatoms, canon_smiles, logKp_cm_h, n_measurements, sources。`notes`列は存在しない)
- `microneedle-drug-delivery/research/yuan2023_dataset_with_descriptors.csv`(191行)、`yuan2023_training_data.csv`(同191行、記述子なし版)
- `microneedle-drug-delivery/research/cosmetic_ingredients_descriptors.csv`(48行。`logKp_PottsGuy_baseline`, `in_MW_domain`, `in_LogP_domain`, `large_molecule_flag`, `highly_polar_flag`列が既に存在)
- `microneedle-drug-delivery/research/descriptors.py`(RDKit記述子計算、`potts_guy_baseline`関数を含む — 実装を確認してから使用)
- `microneedle-drug-delivery/research/active_learning.py`(コーディングスタイル・`RANDOM_STATE`規約の参照用。本モジュールの計算に流用しない)
- `microneedle-drug-delivery/research/literature_map_report.md`, `microneedle_ml_literature.csv`(方法論の先行研究文脈、Xu 2023/Dou 2023の転移学習分類など)
- `microneedle-drug-delivery/research/requirements.txt`(利用可能な依存: rdkit, xgboost, scikit-learn, pandas, numpy, scipy, matplotlib, seaborn, shap, openpyxl — この範囲で実装可能な手法のみ用いる)
- `microneedle-drug-delivery/references/translated  papers/01-yuan-2023-drug-permeation-microneedled-skin-ml-ja.md`(Yuan 2023本文和訳。既報値・検証方法の一次確認先)
- `microneedle-drug-delivery/drug-release-profile/references/supplementary/07-yuan-2023-code-si2.docx`(Yuan 2023 Fick則実装、Phase 4B-5用。読み取れない場合はPotts-Guy式で代替)
- `git show microneedle-active-learning-paper:microneedle-drug-delivery/active-learning-paper/paper.md`, `git show microneedle-small-data-ml-paper:microneedle-drug-delivery/small-data-ml-paper/paper.md`(前例確認用。チェックアウト・マージ不可、内容を本モジュールの結果として転用しない)
- `AGENTS.md`(Markdown正本+HTML同期規則)
- `shared/scripts/build-website.sh`等のビルドスクリプト(`transfer-learning-paper/`はカスタムレンダリング対象として登録されていないため、`build-markdown-html.sh`の汎用パスが使われる)

## 6. Functional requirements

| ID | 要件 | 受入条件 |
| --- | --- | --- |
| F-01 | 論文本文 | `transfer-learning-paper/paper.md`に§4の全マイルストーン(完了分)の結果が、Abstract〜Referencesの構成で記述されている |
| F-02 | 数値の追跡可能性 | 本文の実質的数値がすべて、本モジュールが実際に生成・保存したCSV/スクリプト出力にたどれる |
| F-03 | データセット境界 | 214化合物・48成分・191点データセットの用途混同がない(§3, §4 Phase5参照) |
| F-04 | 疑似データフラグ | Phase 4B-5の疑似データ点が実測データと明確に区別され、件数が混同されていない |
| F-05 | 言語・HTML同期 | `paper.md`は英語。README/requirements/implementation-prompt/decision-logは日本語。全MarkdownにAGENTS.md規則の`[HTML版を開く]`リンクがあり`build-website.sh`後にHTML生成される |
| F-06 | ファイル構成 | `README.md`, `requirements.md`, `implementation-prompt.md`, `paper.md`, `notes/decision-log.md`が揃っている |
| F-07 | RESEARCH_PLAN.md更新 | 実際に完了したフェーズ2〜6の項目のみ`- [x]`化され、本モジュールへのクロスリンクが追加されている |
| F-08 | 未完了の扱い | 時間・環境制約で完了できなかったマイルストーンは、`notes/decision-log.md`に明記され、`paper.md`でも「未実施」として正直に記述される(実施したかのように書かない) |

## 7. Non-functional requirements

| ID | 要件 | 基準 |
| --- | --- | --- |
| NF-01 | 分量 | 論文本文(参考文献除く)はおおよそ4,000〜7,000語(§4の対象範囲の広さに応じた分量。内容のない水増しはしない) |
| NF-02 | Scientific integrity | §3の制約を厳守。実施した計算・実施していない計算・先行研究の既報値を語彙で明確に区別する |
| NF-03 | Reproducibility | 各スクリプトの入出力ファイルパスをData and Code Availability節に正確に記述する(存在しないdriverや自動化を主張しない) |
| NF-04 | Consistency | `../active-learning-paper/`・`../small-data-ml-paper/`との用語・データセット記述の矛盾がない(参照は`git show`のみ) |
| NF-05 | Style | 確定的な語彙("we found")と先行研究の帰属("Yuan et al. reported")を明確に書き分ける |

## 8. Scientific requirements(計算的完全性プロトコル — 数値allowlistの代替)

他モジュール(active-learning-paper等)は「既存CSVの数値を書き写す」ため事前のallowlistが機能したが、本モジュールは**新規計算**が本質のため、代わりに以下のプロトコルを適用する:

1. **すべての新規スクリプトは`research/`直下に保存し、実行結果(CSV・PNG)も同様に保存する。** paper.mdのどの数値も、対応するCSV/PNGファイル名を`notes/decision-log.md`または本文中で明示できること。
2. **各段階(codex-terra, codex-sol)は、前段階が生成したCSVを実際に読んで数値を突き合わせてから引用する。前段階の「検証済み」という自己申告を鵜呑みにしない。**
3. **すべてのモデルで`RANDOM_STATE=42`を使用し、乱数依存の結果には(可能な範囲で)複数シードまたは交差検証のfoldごとの分散も報告する。**
4. **ネガティブな結果(転移学習が効かない、偏り是正が効かない等)を、有効な結果に見せかけて書き換えない。** Yuan et al.自身の限界報告、`../active-learning-paper/`の「一貫した改善なし」という誠実な報告に倣う。
5. **疑似データ(Phase 4B-5)には`is_synthetic`等のフラグを必ず付与し、実測データと合算した件数を一切書かない。**
6. **§3で禁止した「マイクロニードル実験パラメータの仮定」を、48美容成分のいかなる予測にも適用しない。**

## 9. Out of scope

- `../active-learning-paper/`・`../small-data-ml-paper/`・`../competitive-landscape/`(いずれも別ブランチ)の直接編集・チェックアウト・マージ。参照は`git show`のみ。
- `research/requirements.txt`に無い依存(深層学習フレームワーク等)を要求する手法の実装。
- 美容成分48件へのマイクロニードル実験パラメータの仮定・捏造(§3, §4 Phase5)。
- 新規のwet-lab実験・新規データ収集(Phase 2-3の任意項目を除く。§4参照)。
- PDF生成(このワークスペースの標準パイプラインはMarkdown→HTMLのみ)。
- 投稿ジャーナルの選定・実際の投稿手続き。

## 10. Acceptance checklist

- [ ] `paper.md`の全実質的数値が、本モジュールが実際に生成したCSV/スクリプト出力に独立にたどれる
- [ ] 214化合物・191点・48成分データセットの用途混同がない(§3, §4 Phase5)
- [ ] Phase 4B-5の疑似データが実測データと明確に区別され、件数混同がない
- [ ] 48美容成分の予測がマイクロニードル実験パラメータの仮定を伴わない、4Aモデルベースの一般皮膚透過性予測にとどまっている
- [ ] Phase 4B-3の転移学習の対象範囲(4小分子薬剤のみ、BSA/copper ions除外)とその理由が本文に明記されている
- [ ] Yuan et al.の既報値が先行研究の値として明示的に引用され、本研究の結果と区別されている
- [ ] 完了できなかったマイルストーンが`notes/decision-log.md`と`paper.md`の両方で正直に記述されている
- [ ] `research/RESEARCH_PLAN.md`フェーズ2〜6が、実際に完了した項目のみ更新され、本モジュールへのクロスリンクが追加されている
- [ ] 引用文献がすべて実在し、DOIが確認可能である
- [ ] `README.md`, `notes/decision-log.md`が完成している
- [ ] 全Markdownファイルの先頭本文行に`[HTML版を開く]`リンクがあり、`shared/scripts/build-website.sh`がエラーなく完走する
- [ ] 全スクリプトで`RANDOM_STATE=42`が使用されている
