[HTML版を開く](decision-log.html)

# 判断記録 — small-data-ml-paper

## 2026-07-20: 論文の性格をPerspective/proposalに限定

**決定**: `research/` の RESEARCH_PLAN.md はフェーズ2〜6(データキュレーション、モデル構築、
transfer learning、SHAP解析、美容成分への適用)が未着手のまま止まっている。この状態で
「論文を書く」ためには、(a) フェーズ2〜6を実際に実行してから結果を報告する、
(b) 新規計算を行わずPerspective/proposalとして書く、の2択があった。
ユーザーは (b) を明示的に選択した。

**理由**: 実行していない計算の結果を書くと科学的誠実性(データ捏造)に関わる重大な問題になる。
(b) であれば、既に実在する文献マップ・データセット・記述子コードという「本物の」土台の上に、
誠実に「ここまで完了・ここからは計画」と区別した文書を作れる。

**影響**: `requirements.md` §3 に捏造防止の制約を明文化し、`implementation-prompt.md` の
実行順・停止条件にも同じ制約を繰り返し埋め込んだ。後続のfable-5・codexステージが
この区別を破らないよう、各ステージの成果物を都度この観点でレビューする。

## 2026-07-20: パイプライン構成

**決定**: Sonnet 5(要件定義・指示文起草)→ Fable 5(レビュー・改善)→
Codex gpt-5.6-terra(reasoning effort: max、本文の下書き)→
Codex gpt-5.6-sol(reasoning effort: ultra、仕上げ・検証)の4段構成で実行する。

**理由**: ユーザーの明示的な指定(過去のcorneal-geometry-qcモジュールと同じパターン)。
複数モデルによる独立レビューを重視し、1モデルが自分の成果を自己採点する状態を避ける。

**既知のリスク**: `gpt-5.6-sol` の `ultra` reasoning effortは、長時間の headless
`codex exec` 実行中に停止する既知の不具合がある(内部でmulti-agent委任が走り、
`codex exec resume` では復帰できない)。停止した場合は同じコマンドで再実行を1回試み、
それでも失敗する場合はこのセッション(Claude Sonnet 5)が直接仕上げ、
ユーザーにその旨を明示する。

## 2026-07-20: Fable 5 による requirements/implementation-prompt の独立レビュー・改善

**実施**: Sonnet 5 起草の `requirements.md` / `implementation-prompt.md` / `README.md` を、
`research/` 配下の一次資料(各CSV・literature_map_report.md・descriptors.py・両図・
Yuan 2023和訳)に対して逐一検証し、直接修正した。

**検証で確定した事実(すべて元ファイルと一致を確認)**:
- 件数: 文献 **116**、皮膚透過性 **214**(= HuskinDB 129 + SkinPiX 103 + INRS 3 の重複除去後。
  内訳: HuskinDB単独108 + SkinPiX単独82 + 両方21 + INRS3 = 214)、Yuan **191点・6薬剤**
  (lidocaine73 / BSA33 / copper24 / GHK24 / RhodamineB19 / caffeine18)、美容成分 **48**。
- Yuan (2023) 報告値: XGBoost 透過量・透過率とも **R²=0.98**(RF 0.95/0.97、Fick 0.95/0.82、
  MLR 0.46/0.65)、7特徴量、**7:3 の train/test 分割**、Discussion **4.2** で薬剤搭載量への
  過依存による外挿失敗を報告。和訳(references/translated papers)で一次確認済み。

**修正した誤り・曖昧さ**:
1. **美容成分の domain 件数の誤り**: 起草版は「48件中34件が範囲内」「34範囲内+10範囲外」
   としていたが、34+10=44≠48 で内部矛盾。CSVの `in_MW_domain`/`in_LogP_domain` 両 true は
   **38件**。正しくは「**範囲内38 / 範囲外10**」で、34は「範囲内かつ未実測」の内数
   (範囲内38のうち4件=Niacinamide/Urea/Salicylic acid/Ethanol は実測済み)。全該当箇所を修正。
2. **中核5文献の所在の誤り**: 「RESEARCH_PLAN.md 記載の5文献」としていたが、DOI付き正本は
   **CLAUDE.md**「中核となる参考文献」節。requirements/implementation-prompt/README の
   全参照を CLAUDE.md に修正し、5文献のDOIを §3 に明記。
3. **図の記述リスク**: 「5クラスタ」表現。Figure 1b は実際は **8テーマカテゴリ**の棒
   (48/18/17/14/8/7/3/1=116)。本文は「5主要クラスタ+3小クラスタ」でよいが図キャプションは
   8カテゴリと明記するよう指示を追加。両図のパネル内容も正確に記述。
4. **捏造トラップの明文化**: `cosmetic_ingredients_descriptors.csv` に `logKp_PottsGuy_baseline`
   列が **48行すべて数値入り**で存在する。未検証の式出力であり「予測結果」ではないので、
   これを表・図・本文に転記しない旨を §3・§8-7・implementation-prompt に明記(自律実行モデルが
   「完成」させようとして最も踏みやすい地雷)。
5. **過剰自主規制の防止**: Yuanが自ら報告した数値・feature importance傾向は literature 事実として
   引用可、と明記(禁止は「本研究の未実行モデルの数値」のみ)。Yuanの外挿検証は定性的に存在
   (Fig S1/S2)し、本研究の新規性は leave-one-drug-out CV での定量化、と精度注記を追加。
6. **コード実行の全面禁止**: §9 と implementation-prompt に「執筆タスクであって計算タスクでない。
   descriptors.py 等モデリング/計算コードを一切実行しない。実行してよいのは build-website.sh 系のみ」
   を明記(research/requirements.txt の rdkit/xgboost/sklearn/shap を見て実行に走るのを防ぐ)。
7. **実行順の事前ゲート化**: 捏造を「後で直す」から「書く前に防ぐ」へ。step1 で「数値allowlist」を
   先に作り、allowlist に無い数値は書かない方針とし、build 前に専用の「捏造監査パス」(step6)を追加。
8. その他: HuskinDB/SkinPiX/INRS の DB出典DOIを References 指示に補記、Yuan和訳を情報源リストに追加、
   §5 の文字化け(「範囲」が壊れたバイトを含んでいた箇所)を修正、build スクリプトの同名 `.html` 要求に合わせたリンク指示の明確化。

**判断の分かれ目**: 「範囲外10件」の性質。RESEARCH_PLAN.md は「高分子量脂質」と表現するが、
CSV確認では大半が極端なLogP(高親油: squalane/tocopherol/CoQ10、高親水: ascorbyl phosphate類)
による範囲外である。`in_MW_domain=False` は3件、`in_LogP_domain=False` は8件、両方falseは1件で、
和集合が10件である。別指標の `large_molecule_flag=True`(MW>500)は6件である。paper では
「訓練化学空間(MW・LogP)の外」と書くよう §8-4 に注記。

## (このセクションは各ステージ完了時に追記される)

## 2026-07-20: Codex gpt-5.6-terra — 執筆前の根拠読了と数値allowlist

**実施**: `requirements.md` と `implementation-prompt.md` を全文読了した後、指定された
`research/` 配下のMarkdown、CSV、`descriptors.py`、既存図、Yuan et al. (2023) 和訳、
HTMLビルド／検証スクリプトを読んだ。`descriptors.py`、依存関係、モデル学習、記述子計算、
予測生成は実行していない。`drug-release-profile/` の用語定義も確認し、本稿では
microneedle処理皮膚を通過してreceptor compartmentへ到達する **permeation** を、
release-only や skin retention と混同しない。

### paper.md 用の数値allowlist

以下は、根拠ファイル、既存図、または Yuan et al. (2023) の報告値に直接たどれる値だけを
まとめたもの。章番号、参考文献番号、書誌情報の年・DOIは構造的な表記として別扱いとする。
この表にない実質的な数値は、本文では原則使用しない。

| 用途 | 使用を許可する値 | 根拠 |
| --- | --- | --- |
| 文献マップ | 990候補から116件、対象期間2015–2026、2024年16件、2025年22件、2026年（partial）30件、2024年以降59% | `research/literature_map_report.md`, `research/fig1_landscape.png` |
| テーマ構成 | 48 / 18 / 17 / 14 / 8 / 7 / 3 / 1（Figure 1bの8カテゴリ） | `research/literature_map_report.md`, `research/fig1_landscape.png` |
| 手法・影響力図 | tree ensembles/mixed ML 25、QSAR/QSPR 21、review 19、NN/DL 15、MD 10、other ML/AI 8、FEM/physics 8、SVM/SVR 6、linear/GPR 2、generative AI 2；Roberts 196、Lundborg 123等の図中値 | `research/fig2_influence_methods.png`, `research/literature_map_report.md` |
| 皮膚透過性データ | HuskinDB 129、SkinPiX 103、INRS 3、重複除去後214ユニーク化合物 | `research/RESEARCH_PLAN.md`, `research/CLAUDE.md`, `research/skin_permeability_training_set.csv` |
| Yuanデータ再現 | 191点、6薬剤；lidocaine 73、BSA 33、copper ions 24、GHK peptide 24、Rhodamine B 19、caffeine 18 | `research/RESEARCH_PLAN.md`, `research/yuan2023_training_data.csv`, `research/yuan2023_dataset_with_descriptors.csv` |
| Yuanの既報値のみ | 7特徴量、7:3 train/test split、XGBoostのR²=0.98（透過量・透過率）、RF 0.95/0.97、Fick 0.95/0.82、MLR 0.46/0.65；feature-importanceの定性的傾向 | Yuan和訳、`research/CLAUDE.md` |
| 美容成分の準備データ | 48成分、MW・LogP範囲内38、範囲外10、範囲内かつ実測済み4（Niacinamide、Urea、Salicylic acid、Ethanol）、範囲内かつ未実測34 | `research/cosmetic_ingredients_descriptors.csv`, `research/RESEARCH_PLAN.md` |
| 将来のbaselineの式 | `log Kp = -2.7 + 0.71·logP − 0.0061·MW` | `research/descriptors.py::potts_guy_baseline` |

**明示的な除外**: `cosmetic_ingredients_descriptors.csv` の
`logKp_PottsGuy_baseline` 列にある48個の個別出力はallowlist外とする。これらは未検証の
決定論的式の出力であり、本稿の結果、予測値、表、図、または比較値として使用しない。
本プロジェクトが未実施のモデルについて、R²、RMSE、MAE、accuracy、AUC、SHAP値、
feature importance順位、leave-one-drug-out結果、transfer-learning結果、applicability-domain
の性能値、または美容成分の予測log Kpもallowlist外とする。

### 事実と計画の仕分け

- **完了済み事実（過去形で記述可）**: フェーズ0、1、1.5の文献マップ構築、公開皮膚透過性
  データの統合、Yuanデータの再現、PubChem由来の美容成分構造・記述子収集、
  `compute_descriptors`／`potts_guy_baseline`／`check_applicability_domain` を含む
  記述子パイプラインの実装、MW・LogPによる初期スクリーニング。
- **未実施の将来計画（`we propose` / `future work will` でのみ記述）**: フェーズ2以降の
  データキュレーション、EDA、Potts–Guy・MLR・RF・XGBoost・GPRの学習／比較、
  leave-one-drug-out交差検証、transfer learning、物理モデル併用データ拡張、SHAP解析、
  美容成分への予測適用と実測比較。

**執筆ルール**: Yuan et al. の数値は必ず「Yuan et al. reported」と帰属させる。本研究の
既完了作業はデータ資産・再現・パイプラインの整備までであり、予測モデルの結果は報告しない。
ビルド前に、本文の数値、予測値の混入、Yuan値の帰属、未来形の一貫性を個別に再監査する。

## 2026-07-20: Codex gpt-5.6-terra — 本文完成と捏造監査

**作成した成果物**: 英語のpaper.mdを完成させ、Title & Abstract、Introduction、
Related Work / Literature Landscape、Research Gap、Completed Preliminary Work、
Proposed Methodology / Future Work、Anticipated Contributions、Limitations、
Data & Ethics Statement、Referencesの順で構成した。本文は参考文献を除いて5,482語であり、
要件の4,000–6,500語に収まる。Figure 1とFigure 2はresearch配下の既存PNGをそのまま
埋め込み、Figure 1bを8テーマカテゴリとしてキャプションに明記した。

### 数値allowlist監査

本文のReferences手前から数値トークンを抽出し、section番号・引用番号を除いて手作業で
allowlistと照合した。文献マップ、テーマ構成、データセット、Yuan既報値、美容成分のdomain
内訳、Potts–Guy式以外の実質的な数値は検出しなかった。YuanのR²、7特徴量、7:3分割は
すべてYuan et al.の報告値として文脈内で帰属させた。書誌情報の年とDOIはReferences内の
メタデータに限定した。

### 捏造監査パス

- **(i) 数値の出所**: 本文中の実質的な数値は上記allowlistに一致することを確認した。
- **(ii) 未実施モデルの結果**: 本プロジェクトのR²、RMSE、MAE、accuracy、AUC、SHAP値、
  feature-importance順位、leave-one-drug-out結果、transfer-learning結果、または
  applicability-domain性能値は記載していない。
- **(iii) 美容成分の数値予測**: logKp_PottsGuy_baseline列の個別出力、その他のper-compound
  予測値、予測散布図、予測表は記載していない。Potts–Guyは式と将来のbaseline計画のみである。
- **(iv) Yuan値の帰属**: Yuan et al.の性能値・特徴量傾向・定性的なexcluded-drug checkを、
  すべて先行研究の記載として扱った。本研究が再計算したとの文言はない。
- **(v) 時制**: データ資産・文献マップ・再現・記述子準備は完了済みとして記述し、データ
  キュレーション以降、モデル構築、検証、転移、増強、解釈、化粧品への適用はfuture work
  またはproposalの語彙に限定した。

**引用照合**: Yuan、Roberts、Lundborg、Rezapour SarabiのDOIは
microneedle_ml_literature.csvに照合した。Zheng、Xu、Achar & Keith、Dou/Zhu/Merkurjevの
DOIと、HuskinDB、SkinPiX、統合QSPRデータセットのDOIはCLAUDE.mdに照合した。実在確認
できない文献や新規DOIは追加していない。

### requirements.md §10 の自己採点（HTML build前）

- [x] paper.mdに英語の本文と指定章立てがある。
- [x] フェーズ2以降を未実施の計画として明示し、未実行モデルの数値結果を載せていない。
- [x] Yuanの既報値は先行研究の値として明示した。
- [x] 未検証のPotts–Guy個別出力や美容成分の予測値を掲載していない。
- [x] モデリング・記述子・依存関係の実行を行っていない。
- [x] 引用のDOIを指定ソースと照合した。
- [x] Figure 1・Figure 2を正しい出典・キャプションで埋め込んだ。
- [x] 116、214、191、48、38/10、および34の関係を根拠どおりに記述した。
- [ ] 同名HTMLの生成と全Markdownリンク検証は、最終のbuild-website.sh実行後に更新する。
- [x] 4段パイプラインと主要判断を本decision logに記録した。

## 2026-07-20: Codex gpt-5.6-terra — HTML buildの結果と既存ブロッカー

**実施**: shared/scripts/build-website.sh を実行した。ビルドはpaper.html、README.html、
notes/decision-log.html、requirements.html、implementation-prompt.htmlを含む当該モジュールの
HTMLを生成した。したがって、今回更新したMarkdown正本には対応HTMLが存在する。

**停止した検証**: 最後の全Markdownリンク検証で、research/CLAUDE.mdの先頭本文行が
HTMLリンクではないことにより停止した。検出された内容は次のとおりである。

    Invalid HTML link in microneedle-drug-delivery/research/CLAUDE.md
      expected first body line: [HTML版を開く](CLAUDE.html)
      actual first body line:   # プロジェクト: Small-data MLによるマイクロニードル薬物送達予測の改良と美容成分への応用

このファイルは今回の執筆対象ではなく、今回の変更以前から先頭リンクがない既存の状態である。
実行用指示文の停止条件に従い、無関係な既存ファイルは修正しない。次ステージでは、必要なら
この既存Markdownリンクを別途是正したうえで、リポジトリ全体のvalidatorを成功させられる。

### requirements.md §10 の自己採点（build後）

- [x] paper.mdに英語の本文と指定章立てがある。
- [x] フェーズ2以降を未実施の計画として明示し、未実行モデルの数値結果を載せていない。
- [x] Yuanの既報値は先行研究の値として明示した。
- [x] 未検証のPotts–Guy個別出力や美容成分の予測値を掲載していない。
- [x] モデリング・記述子・依存関係の実行を行っていない。
- [x] 引用のDOIを指定ソースと照合した。
- [x] Figure 1・Figure 2を正しい出典・キャプションで埋め込んだ。
- [x] 116、214、191、48、38/10、および34の関係を根拠どおりに記述した。
- [x] 今回の全Markdownは同名HTMLへの先頭リンクを持ち、対応HTMLが生成された。
- [ ] shared/scripts/build-website.shのリポジトリ全体の成功は、上記の既存research/CLAUDE.mdリンク不備のため未達。
- [x] 4段パイプラインと主要判断を本decision logに記録した。

## 2026-07-20: Codex gpt-5.6-sol — 一次資料からの独立再検証と最終仕上げ

**実施原則**: 上記terra段階のallowlistと自己監査は証拠として使わず、比較対象として隔離した。
`RESEARCH_PLAN.md`、`CLAUDE.md`、`literature_map_report.md`、指定5 CSV、`descriptors.py`、両PNGの実物、
Yuan et al. (2023)日本語訳を改めて読み、raw row・flag・DOI・図中値から独立に再構成した。
`descriptors.py`、Python/R、RDKit、XGBoost、scikit-learn、SHAP、記述子計算、モデル学習、
予測生成は実行していない。行・flagの検査に限定したread-only CLIとCSVパースを用い、
実行したリポジトリ内スクリプトは `shared/scripts/build-website.sh` 系のみである。

### 独立再導出した数値allowlist

| 用途 | 允許値 | 独立の根拠 |
| --- | --- | --- |
| 文献コーパス | 990候補→116件、2015–2026、2024/2025/partial-2026は16/22/30件、2024以降68/116=58.6%→報告値59% | `literature_map_report.md`、literature CSV 116 rows、Figure 1a |
| Figure 1bテーマ | 48 / 18 / 17 / 14 / 8 / 7 / 3 / 1 = 116、8カテゴリ | literature CSVの `theme`、Figure 1b |
| Figure 2a被引用上位 | 196 / 123 / 111 / 93 / 76 / 74 / 73 / 69 / 63 / 58 / 51 / 49 | literature CSVの `citations`、Figure 2a |
| Figure 2b手法 | 25 / 21 / 19 / 15 / 10 / 8 / 8 / 6 / 2 / 2 | Figure 2bの集約カテゴリ |
| 皮膚透過性資源 | 214 unique。HuskinDB-only 108 + SkinPiX-only 82 + 両方 21 + INRS 3。従ってsource contributionは129 / 103 / 3 | `skin_permeability_training_set.csv` 214 rowsと `sources` |
| Yuanデータ | 191点・6薬剤: lidocaine 73 / BSA 33 / copper ions 24 / GHK peptide 24 / Rhodamine B 19 / caffeine 18 | 両Yuan CSVの191 rowsと `Drug name` |
| Yuan既報値のみ | 7特徴量、7:3 random split、XGBoost R² 0.98/0.98、RF 0.95/0.97、Fick 0.95/0.82、MLR 0.46/0.65、feature-importanceの定性的傾向 | Yuan日本語訳 §2.8・表4・§3.5・§4.2 |
| 美容成分 | 48 rows、38 in both MW/LogP domains、10 out of either、4 measured overlaps、34 in-domain/unmeasured | cosmetic CSVの両domain flagとtraining CSVとの `canon_smiles` 一致 |
| domain内訳の監査用値 | `in_MW_domain=False` 3、`in_LogP_domain=False` 8、両方false 1→和集合10。`large_molecule_flag=True` は別指標で6 | `cosmetic_ingredients_descriptors.csv` |
| Potts–Guy式 | log Kp = -2.7 + 0.71·logP − 0.0061·MW | `descriptors.py::potts_guy_baseline` のソースコード読み取り |

### 一次資料内で発見した不整合

1. **Yuan訳本文の薬剤別件数**: 本文はRhodamine Bとcaffeineを各10点と記載するが、
   その内訳は174点にしかならず、同文の総数191点と矛盾する。Data S1由来の両CSVは19/18点で、
   6薬剤の合計が191点になる。従ってpaperの19/18を維持し、訳本の10/10は内部矛盾と記録する。
2. **MW domain外数の先行監査ミス**: 先行ステージの「MW超過4件」は誤り。元CSVで
   `in_MW_domain=False` はCoenzyme Q10、Madecassoside、Asiaticosideの3件である。MW>500の
   `large_molecule_flag=True` 6件との混同を防ぐため、`requirements.md` §8-4と本logの先行記述を修正した。

### paper.mdの数値・捻造・引用監査

- **全数値**: References前の数値を行ごとに再抽出し、上記allowlistと照合した。支持不能な数値は0件。
- **モデル成果**: 本プロジェクトのR²、RMSE、MAE、accuracy、AUC、SHAP値、feature-importance数値・順位、
  leave-one-drug-out、transfer learning、美容成分予測の結果は0件。R²数値はYuan et al.の既報値のみで、
  直後に本プロジェクトの結果ではないと明記している。
- **Potts–Guy漏洩**: `logKp_PottsGuy_baseline` の48個別値について、完全文字列一致は0件。
  成分別表・散布図・予測主張も0件。式と将来baseline計画のみである。
- **DOI**: References 11件を1件ずつ独立照合し、11/11件が `CLAUDE.md` または
  `microneedle_ml_literature.csv` と完全一致。存在しないDOI、孤立引用、未引用参考文献は0件。
- **時制**: `we found`、`we show`、未実施modelの `our results`に相当する完了表現は0件。
  フェーズ2以降はproposal/future/conditionalの語彙で統一した。

### 論文に直接加えた修正

1. 214 uniqueの算術を明確化し、HuskinDB-only 108、SkinPiX-only 82、両方21、INRS 3から
   source contribution 129/103/3とunique 214を追跡できる文にした。
2. 4つの実測済み美容成分を「直接検証」と無条件に呼ぶデータ漏洩リスクを修正した。
   intact-skin log Kpで全前処理・学習・モデル選択から除外した場合のみout-of-sample検証とし、
   それ以外はmeasured comparator、microneedle-treated cumulative permeationの検証には使えないと明記した。
3. leave-one-drug-out transferの主解析で、保留薬剤と同一のsource-domainレコードをpretrainingと
   source-derived preprocessingからも除外する規則を追加した。既知のintact-skin実測値を利用する場合は
   別のauxiliary analysisとし、unseen-chemistry generalizationと呼ばない。
4. Figure 1の説明を査読原稿向けに整理し、5主要クラスタと3小カテゴリ、図の8カテゴリを自然に接続した。
   Referencesの最初出現も[1, 2]とし、数字引用の登場順を整えた。
5. Yuanデータ再現を「訓練済みモデルの再現」と読まれない表現に改め、anticipated contributionsを
   conditionalな語気に統一した。

### プローズ・分量・文書整合

- 完成済み資産→研究gap→一般化を反証可能にする段階的protocol→条件付きの貢献と限界、という
  Perspectiveの論旨を通読し、章間のendpointと時制を統一した。
- References前で `awk` により区切り `wc -w` で数えた最終文量は **5,558語**(タイトル、見出し、
  keywords、図キャプションを含み、Referencesを除外)で、NF-01の4,000–6,500語に収まる。
- READMEの旧build blocker記述を現状に合わせて更新した。先行ステージの
  `research/CLAUDE.md` 先頭リンク不備は解消済みで、本ステージのbuildは成功した。

### HTML build最終結果

`shared/scripts/build-website.sh` をリポジトリrootから実行し、当モジュールの
`paper.html`、`README.html`、`requirements.html`、`implementation-prompt.html`、
`notes/decision-log.html` を再生成した。エラーなく完走し、最終行に以下を確認した。

    Validated Markdown-to-HTML links.
    Generated and validated all Markdown-backed HTML documents.

先行段階で報告された無関係のblockerは再発せず、今回のモジュール内エラーもなかった。

### requirements.md §10 最終自己採点

- [x] **1/11** `paper.md` が存在し、指定の10章構成をすべて含む。
- [x] **2/11** フェーズ2以降は未実施の計画で、本研究モデルの具体的成果値を含まない。
- [x] **3/11** Yuan (2023)の既報値は先行研究の値と明記し、本研究と混同しない。
- [x] **4/11** `logKp_PottsGuy_baseline` の48個別値、予測表、予測散布図、その他予測値は未掲載。
- [x] **5/11** モデリング・記述子・予測コードは実行せず、リポジトリ内で実行したスクリプトはbuild系のみ。
- [x] **6/11** Referencesは11/11件が許可ソースに存在し、DOIが完全一致する。
- [x] **7/11** Figure 1・2は実データPNGを埋め込み、出典を明記し、Figure 1bは8カテゴリと正確に記述する。
- [x] **8/11** 116、214、191、48、38/10、34とその内訳をraw fileに対して再照合済み。
- [x] **9/11** 対象Markdownの先頭本文行に同名HTMLリンクがあり、リンク先が存在する。
- [x] **10/11** `shared/scripts/build-website.sh` がエラーなく完走し、Markdown-to-HTMLリンク検証に成功した。
- [x] **11/11** sonnet→fable→codex-terra→codex-solの4段パイプライン、主要判断、独立allowlist、最終監査を本記録に収録した。

**最終スコア: 11/11 (全項目適合)**

## 2026-07-21: PR #1への追加コミット — Asgarkhanova et al. (2026) 発見を反映した帰属表現の修正

**発生した経緯**: 別ブランチ・別PR(`microneedle-competitive-gap-analysis`, PR #2)のdeep-research調査で、
CNRS-Strasbourg/INRSのAsgarkhanova et al. (2026, *Molecular Informatics*, doi:10.1002/minf.70030) が、
本論文§5.2の214化合物データセット(HuskinDB129+SkinPiX103+INRS3)と**内訳が完全一致**する統合データセットを
既に構築・公開している可能性が高いことが判明した(データDOI 10.57745/ZUU1DH — 本プロジェクトの
`research/CLAUDE.md`が元々「統合QSPRデータセットの出典」として引用していたのと同一)。PR #2の
`competitive-landscape.md` §11がこの帰属表現の修正をPR #1への追加コミットとして推奨し、ユーザーが
「今すぐ修正する」を選択したため、本コミットで対応する。

**修正内容**:
- Abstract(§1)・§5.2の「we assembled a training resource of 214 unique compounds」という自己統合を
  示唆する表現を、「reused」(公開済み統合データセットの再利用)へ修正。
- §5.2に、Asgarkhanova et al.との内訳一致・DOIの一致・本文入手不可(購読制)という制約・
  「本研究の新規性はデータ統合ではなく転移学習のソースドメインとしての橋渡しにある」という
  位置づけの明確化を追記。
- References に Asgarkhanova et al. (2026) を新規追加(#12)。本文入手不可のためタイトルは
  「unconfirmed」と明記し、確認できない情報を確定事実として書かない既存の原則を維持した。
- Data & Ethics Statement の引用範囲を [9–11] から Asgarkhanova言及を含む形に更新。

**捏造防止原則との整合性確認**: Asgarkhanova et al.の実際の手法・性能指標は依然として不明のため、
「Asgarkhanova et al.は既にこの問題を解決した」という逆方向の過大主張はしていない。あくまで
「214化合物データセットの構築主体」についての帰属表現の訂正であり、本論文の新規性の所在
(転移学習のソースドメインとしての利用)は変更していない。

**実施者**: Claude Sonnet 5(オーケストレーションセッション)。`git worktree`を用いて、並行実行中の
別タスク(`microneedle-active-learning-paper`ブランチでのCodex gpt-5.6-sol実行)と作業ツリーを
分離した上で実施した。

## 2026-07-21: 独立QA監査(サブエージェント)とSonnet 5による修正 — Asgarkhanova化合物数の不整合

**監査の実施**: 別作業ツリー(`git worktree`、`microneedle-active-learning-paper`ブランチでの並行Codex実行から分離)で独立QA監査サブエージェントを実行した。`paper.md`全文の再検証に加え、Asgarkhanova et al. (2026)の実在性・データDOI(10.57745/ZUU1DH)の公開メタデータを外部から直接確認した。

**発見した不整合**: §5.2は「129/103/3の内訳を含め、Asgarkhanova et al.のデータセットと一致する」と記述していたが、独立監査でAsgarkhanova et al.のデータリポジトリ公開ページの最終重複除去後の総数を確認したところ、約207〜209化合物(情報源により207または209)であり、本プロジェクトの214とは5〜7件の差があることが判明した。129+103+3=235の生内訳から本プロジェクトが導出した重複21件(214=235-21)と、Asgarkhanova側の重複除去件数は一致しない。原文(購読制)にアクセスできないため、この差異の原因(重複除去方法の違いか、対象化合物の範囲の違いか)は特定できなかった。

**判断**: 「内訳(129/103/3)が一致する」こと自体は事実(本プロジェクトの`skin_permeability_training_set.csv`の`sources`列集計で独立に再確認済み)だが、内訳の一致を根拠に「同一の統合資源」であるかのように読める表現は、最終件数が一致しないという事実を書かないまま残すと読者に誤った精度の印象を与える。§5.2を修正し、内訳の一致と最終件数の不一致(207〜209 vs 214)の両方を明記し、原因不明である旨を追記した。捏造防止の原則(逆方向にも既存論文の成果を偽って引用しない)は維持し、Asgarkhanova et al.が実際に何を行ったかについての新たな断定は追加していない。

**軽微な修正**: §2「Achar and Keith review small-data approaches」を「Achar and Keith also discuss small-data approaches」に変更。この文献(doi:10.1021/acs.chemrev.4c00957, 本文入手不可)が実際には特集号への短い序文(3ページ程度)であり、包括的レビューと呼ぶには誇張の可能性があるという監査の指摘(確信度は監査自身も低いと明記)を受け、より中立的な動詞に置き換えた。要件定義が既にこの文献を「abstract-only、過大な帰属をしない」と注記していたことと整合する、低リスクな精緻化。

**実施者**: Claude Sonnet 5(オーケストレーションセッション)。監査サブエージェントの発見事項をそのまま鵜呑みにせず、`skin_permeability_training_set.csv`の`sources`列集計を自分でも独立に再確認してから修正を適用した。
