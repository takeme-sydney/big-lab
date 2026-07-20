[HTML版を開く](requirements.html)

# 要件定義 — Retrospective Active Learning for Microneedle Drug Permeation: A Small-Data Case Study

文書版: 1.0
作成日: 2026-07-21
対象: `big-lab/microneedle-drug-delivery/active-learning-paper/paper.md`
根拠資料: `big-lab/microneedle-drug-delivery/research/`(`active_learning.py`, `active_learning_report.md`, 3件の結果CSV, 2枚の図, `yuan2023_dataset_with_descriptors.csv`, `RESEARCH_PLAN.md`, `CLAUDE.md`)

## 1. 目的

`microneedle-drug-delivery/research/` で既に実行済みの後ろ向き能動学習(retrospective active learning)シミュレーション ― Yuan et al. (2023) の191点・6薬剤データセットを「未実験プール」とみなし、Random / GP-Uncertainty / RF-QBC の3つの獲得戦略を比較した解析 ― の成果を、research noteとして書き上げる。

この論文は [`../small-data-ml-paper/`](../small-data-ml-paper/)(ブランチ `microneedle-small-data-ml-paper`。Perspective/proposal論文で新規計算結果を一切含まない)とは性格が異なる: **能動学習シミュレーションの計算は既に完了しており、実在する数値結果を報告する research note である。** 目的は、既に書かれた作業草稿(`paper.md`、旧 `research/paper_draft.md`)を、(a) 壊れた図参照の修正、(b) 全数値の一次データ(添付CSV)との照合、(c) ワークスペースの文書規約(Markdown/HTML同期、モジュール構成)への適合、を経て完成させることである。**新しい計算・新しい数値を追加することではない。**

## 2. 想定読者

- Yunong Yuan (PI, University of Sydney Biomedical Innovation Group) — 実験計画への示唆を評価する読者
- 将来この研究に参加する学生・研究補助者 — 背景と結論を把握するための読者
- (将来的な拡張として)short technical note / research note を掲載する専門誌の査読者を意識した文体(`literature_map_report.md` が特定した主要投稿先ジャーナルと同系統)

## 3. 論文の位置づけ・ジャンル(最重要制約)

- ジャンル: **Research note(後ろ向きシミュレーション研究)**。Perspective/proposalではなく、**実際に計算され、CSVとして保存済みの定量結果を報告する完成した解析**である。
- **絶対に行ってはならないこと(この節は下流の自律実行モデルが「論文を仕上げよう」として無意識に破りやすい。1つでも破れば科学的不正になる)**:
  - `paper.md` に記載する実質的な数値は、すべて `research/active_learning_curves_within_distribution.csv`、`research/experiments_to_threshold.csv`、`research/lodo_active_learning_results.csv` のいずれか、または Yuan et al. (2023) の既報値(帰属を明記)のいずれかに直接たどれるものに限る。**§8のallowlistに無い数値を新設しない。**
  - **`active_learning.py` を含む一切のモデリング・記述子計算・統計処理コードを、このタスクのために実行・再実行しない。** これは執筆タスクであって計算タスクではない。既に確定した結果を新しい実行で上書き・微修正すること自体が、既存の検証済み数値との不整合を生み、読者から見て説明のつかない改変になる。数値の再現・検算は、**既存CSVを読んで**行う(コード実行ではなくファイル読解による照合)。
  - **214化合物の皮膚透過性データセット(`skin_permeability_training_set.csv`)、美容成分48件のデータセット(`cosmetic_ingredients_descriptors.csv`)、transfer learningの結果を、この論文の結果として一切登場させない。** `active_learning.py` と3件の結果CSVはすべて `yuan2023_dataset_with_descriptors.csv`(Yuanの191点)のみを対象にしており、214化合物・48成分データセットは一度も使われていない。これらは別モジュール([`../small-data-ml-paper/`](../small-data-ml-paper/))の対象であり、混同すると事実と異なる主張になる。
  - Leave-one-drug-out の結果(RMSE・R²)を「能動学習は外挿を一般に改善できない」という無限定の一般論として誇張しない。既存草稿は「本データセット・本特徴量表現に関する結果」と明確にhedgeしている ― この限定を弱めない(§8参照)。
  - Yuan et al. (2023) の既報値(R²=0.98等)を、あたかも本研究が計算したかのように書かない。
  - 実在しない引用文献・DOIを作らない。引用は `research/CLAUDE.md`「中核となる参考文献」節の中核5文献、または既存 `paper.md` の References に既にリストされた文献に限定する。追加が必要な場合は実在・内容を確認できる場合のみ追加する。
  - `research/active_learning.py`、3件の結果CSV、2枚のPNG図の中身を書き換えない(バグに気づいても、このタスクでは書き換えず decision-log に記録する ― §9参照)。
- **区別のための明確化(過剰な自主規制で事実を落とさないために)** — 以下は捏造ではなく、**書いてよい・むしろ書くべき**:
  - §8のallowlistに載る本研究自身の数値結果(R²、RMSE、必要実験数など)は、この研究が実際に計算した**本研究の成果**として、"we found" / "we show" 等の確定的な語彙で報告してよい(Perspective論文の "we propose" のような未来形にする必要はない)。
  - Yuan et al. (2023) が自ら報告した数値(XGBoost R²=0.98 等)は、"Yuan et al. reported" のように先行研究の記載事実として正確に引用してよい。
  - 図・表現の精緻化、文章構成の改善、誤字脱字の修正、節の並べ替えは自由に行ってよい ― 制約対象は**数値の出所**であって文章表現ではない。

## 4. 必須コンテンツ(論文の章立て・既存草稿からの具体的な修正点)

`paper.md` は既に以下の章立てで下書きが完成している。この構成を維持し、**新しい章を増やす必要はない**。以下の具体的な欠陥を修正して完成させること:

1. **Title & Abstract**
2. **1. Introduction**
3. **2. Data and Methods**(2.1 Dataset, 2.2 Active learning simulation, 2.3 Leave-one-drug-out extrapolation test)
4. **3. Results**(3.1 within-distribution, 3.2 leave-one-drug-out)
5. **4. Discussion**(Limitations小節を含む)
6. **5. Conclusion**
7. **Data and Code Availability**
8. **References**

**必須の修正項目:**

- **F-a(図の参照が壊れている・最優先)**: 現在の草稿は Figure 1・Figure 2 の画像参照が `{{artifact:92f16820-...}}` 形式の未解決プレースホルダのままで、実際には表示されない。標準Markdown画像記法に置き換える:
  - Figure 1 → `../research/fig_active_learning_curves.png`
  - Figure 2 → `../research/fig_lodo_comparison.png`
  - 画像を`active-learning-paper/`配下にコピーしない(`research/`の実ファイルを相対パス参照する。small-data-ml-paperモジュールが`fig1_landscape.png`等を`../research/`から直接参照するのと同じ方式)。埋め込み後、実際にファイルが存在し相対パスが正しく解決することを確認する。
- **F-b(ステータス表記の更新)**: タイトル直下の "Working draft — prepared as a research note..." という下書き表記を、完成後の実態に合わせて更新する(内容の完成状況を正確に表す一文にする。過度な誇張は避ける)。
- **F-c(Data and Code Availability の正確化 ― 重要)**: 現在の草稿はこの節で「`active_learning.py`(獲得戦略とシミュレーションループ)」が提供されていると書いているが、実際の `research/active_learning.py` には獲得戦略の関数(`select_random`, `select_gp_uncertainty`, `select_rf_qbc`)と単一カーブを計算する `run_active_learning_curve()` のみが存在し、**データ読み込み・10反復の分割・leave-one-drug-outループ・CSV書き出し・図の生成を行うオーケストレーション(driver)コードは含まれていない。** この節は、実際に存在するもの(戦略の実装、既存の3結果CSV、既存の2図)と、含まれていないもの(报告された数値を最初から再生成する driver script)を正確に区別して記述すること。存在しないreproducibilityを主張しない。driver scriptを新規に書いて実行することはしない(§9 out of scope)。
- **F-d(関連ファイルの整合)**: `research/active_learning_report.md` の「再現方法」節は `src/active_learning.py` というパスを記載しているが、`research/` 配下に `src/` ディレクトリは存在せず、実際のパスは `active_learning.py`(`research/`直下)である。この既存の内部レポート内の誤記を修正する(同じ情報源検証作業の一環として、`active-learning-paper/`ではなく`research/active_learning_report.md`側を修正する)。

## 5. 使用可能な情報源(これ以外を根拠にしない)

- `microneedle-drug-delivery/active-learning-paper/paper.md`(既存の下書き ― ゼロから書き直すのではなく、これを検証・修正・完成させる)
- `microneedle-drug-delivery/research/active_learning.py`
- `microneedle-drug-delivery/research/active_learning_report.md`
- `microneedle-drug-delivery/research/active_learning_curves_within_distribution.csv`
- `microneedle-drug-delivery/research/experiments_to_threshold.csv`
- `microneedle-drug-delivery/research/lodo_active_learning_results.csv`
- `microneedle-drug-delivery/research/fig_active_learning_curves.png`, `fig_lodo_comparison.png`
- `microneedle-drug-delivery/research/yuan2023_dataset_with_descriptors.csv`, `yuan2023_training_data.csv`
- `microneedle-drug-delivery/research/CLAUDE.md`(中核5文献のDOI)
- `microneedle-drug-delivery/research/RESEARCH_PLAN.md`
- `microneedle-drug-delivery/references/translated  papers/01-yuan-2023-drug-permeation-microneedled-skin-ml-ja.md`(Yuan 2023本文の和訳。既報値の一次確認先。フォルダ名の`translated`と`papers`の間はスペース2つ)
- `microneedle-drug-delivery/small-data-ml-paper/`(ブランチ `microneedle-small-data-ml-paper` ― マージされておらず、この作業ツリーには存在しない。**参照する場合は `git show microneedle-small-data-ml-paper:<path>` でファイル単位に閲覧するに留め、チェックアウト・マージはしない。** 目的はパイプライン・文書構成・ビルド手順の前例確認のみ。このモジュールの数値(214化合物・48成分等)を本論文に持ち込まない)
- `AGENTS.md`(リポジトリルート。Markdown正本+HTML同期規則)
- `shared/scripts/build-website.sh`, `build-markdown-html.sh`, `check-document-html-links.sh`, `render-research-document.sh`(ビルド・検証機構。**`active-learning-paper/`はどのスクリプトにもカスタムレンダリング対象として登録されていないため、`build-markdown-html.sh`の汎用パス ― 同名`.html`を`research-document.html`テンプレートで生成 ― が使われる。特別なpaper用テンプレートを新設・探索する必要はない**)

## 6. Functional requirements

| ID | 要件 | 受入条件 |
| --- | --- | --- |
| F-01 | 論文本文 | `active-learning-paper/paper.md` に、§4の章立てを保ったまま§4の修正項目(F-a〜F-d)がすべて反映された完成稿が存在する |
| F-02 | 言語 | 論文本文(`paper.md`)は英語のまま維持。README/requirements/implementation-prompt/decision-logは日本語(ワークスペースの既存慣行) |
| F-03 | HTML同期 | `AGENTS.md` の規則に従い、`active-learning-paper/`配下の全Markdownの先頭本文行に `[HTML版を開く](同名.html)` を付与し、`shared/scripts/build-website.sh` 実行後に対応するHTML(`paper.html`含む)が生成されること |
| F-04 | 図表 | Figure 1・Figure 2が`../research/`配下の実ファイルへの相対パスで正しく埋め込まれ、キャプションが実物と整合する |
| F-05 | 文献引用 | 本文で言及した文献はすべて既存 `paper.md` の References、または `CLAUDE.md`「中核となる参考文献」節の中核5文献のいずれかに存在し、DOIが一致する |
| F-06 | ファイル構成 | `README.md`, `requirements.md`, `implementation-prompt.md`, `paper.md`, `notes/decision-log.md` が `active-learning-paper/` 配下に揃っている |
| F-07 | 関連ドキュメント修正 | `research/active_learning_report.md` の `src/active_learning.py` パス誤記が修正されている(§4 F-d) |

## 7. Non-functional requirements

| ID | 要件 | 基準 |
| --- | --- | --- |
| NF-01 | 分量 | 論文本文(参考文献リストを除く)は現行の約2,050語からおおよそ2,000〜3,200語の範囲に収める。修正のための微増は許容するが、内容のない水増しはしない |
| NF-02 | Scientific integrity | §3の制約を厳守。「本研究の確定した結果」「Yuan et al.の既報事実」「(もしあれば)今後の課題」を語彙で明確に区別する |
| NF-03 | Reproducibility の正確な記述 | 「利用可能」と書くものは実際に存在するものに限る(§4 F-c)。存在しないdriver scriptがあるかのように書かない |
| NF-04 | Privacy/copyright | 購読論文本文の転載・再配布をしない。Yuan et al.の引用は書誌情報とDOIのみ |
| NF-05 | Consistency | `drug-release-profile/` 側の用語定義(release / permeation / retentionの区別)と矛盾しない。本論文が扱うのは一貫して microneedle 処理皮膚を通した **permeation** である |
| NF-06 | Style | Research noteとしての確定的な文体("we found", "we show" 等)を、Yuan et al.由来の記述("Yuan et al. reported")と明確に書き分ける |

## 8. Scientific requirements(数値allowlist)

以下は、添付3 CSV・2図・Yuan et al. (2023) の既報値に直接たどれる値をまとめたものである。**この表にない実質的な数値は、原則 `paper.md` に書かない。** この allowlist は Sonnet-5 が3件のCSVを直接読んで独立に導出したものであり、下流の各ステージ(fable-5, codex-terra, codex-sol)は**この表を鵜呑みにせず、自分でも元CSVと突き合わせて再検証すること**(祖CSVと本表に不一致があれば、CSVを正とし decision-log.md に記録する)。

### 8-1. 本研究の結果(`research/`配下3 CSVより。Yuanデータ以外は一切未使用)

**分布内学習曲線**(`active_learning_curves_within_distribution.csv`、108行=3戦略×36訓練サイズ[12→117を3刻み]、10反復の平均値):

| n_train | Random R² | GP-Uncertainty R² | RF-QBC R² |
| --- | --- | --- | --- |
| 27 | 0.777 | 0.863 | 0.663 |
| 117(最大、全体の61%) | 0.977 | 0.979 | 0.980 |

**目標精度到達に必要な実験数**(`experiments_to_threshold.csv`):

| 戦略 | R²≥0.85 | R²≥0.90 | R²≥0.95 |
| --- | --- | --- | --- |
| Random | 33 | 39 | 69 |
| GP-Uncertainty | 27(−18%) | 39(±0%) | 84(+22%) |
| RF-QBC | 45(+36%) | 57(+46%) | 84(+22%) |

**Leave-one-drug-out RMSE**(`lodo_active_learning_results.csv`、log₁₀ permeation amount、6薬剤×3戦略=18行すべて):

| 除外薬剤 | Random | GP-Uncertainty | RF-QBC |
| --- | --- | --- | --- |
| BSA | 1.976(R²=−44.1) | 1.967(R²=−43.7) | 1.969(R²=−43.8) |
| lidocaine | 0.976 | 0.978 | 0.991 |
| Rhodamine B | 2.105(R²=−113.3) | 1.972(R²=−99.3) | 1.945(R²=−96.6) |
| caffeine | 0.568 | 0.561 | 0.586 |
| copper ions | 1.140 | 1.163 | 1.132 |
| GHK peptide | 1.438 | 1.413 | 1.428 |
| **6薬剤平均** | **1.367** | **1.342** | **1.342** |

### 8-2. Yuan et al. (2023) の既報値のみ(先行研究として引用可。本研究の結果ではない)

- 191点・6薬剤: lidocaine 73, BSA 33, copper ions 24, GHK peptide 24, Rhodamine B 19, caffeine 18(`yuan2023_dataset_with_descriptors.csv`で件数を再確認済み)
- 7特徴量(薬剤負荷量・薬剤分子量・MN長・皮膚タイプ・MNタイプ・MN表面積・透過時間)、目的変数は薬物透過量(µg/cm²)
- XGBoost R²=0.98(透過量・透過率とも)、RF 0.95/0.97、Fick 0.95/0.82、MLR 0.46/0.65(Yuan和訳・CLAUDE.mdで確認)
- Discussion §4.2: 訓練データにない新規薬剤への外挿で大きな乖離。薬剤負荷量への過度な依存が原因と分析

### 8-3. 明示的な除外(allowlist外)

- 214化合物データセット(`skin_permeability_training_set.csv`)、48件美容成分データセット(`cosmetic_ingredients_descriptors.csv`)の**いかなる数値・件数も本論文の本文・図・表に登場させない**(この active learning シミュレーションでは一度も使用されていない ― §3参照)。
- transfer learning、physical-model-augmented data augmentation、SHAP解析など、RESEARCH_PLAN.mdフェーズ2以降の**未実施項目の定量的な性能値**(本研究のものとして)。
- `active_learning.py`・記述子計算・依存パッケージ(`requirements.txt`のrdkit/xgboost等)を実行して得られる、上記allowlistに無い新規の数値。

## 9. Out of scope

- **`active_learning.py`を含む一切のモデリング・計算コードの実行・再実行**(§3)。すでに確定した数値の検算のための再実行も含めて行わない。
- **既存3 CSVを再生成するためのdriver/オーケストレーションスクリプトの新規作成・実行**(§4 F-c)。reproducibility gapは prose で正直に記述するに留める。
- `research/active_learning.py`・3件のCSV・2枚のPNGの中身の書き換え。**バグや疑問点に気づいた場合は、ファイルを直接修正せず `notes/decision-log.md` に記録して報告する**(下流ステージが誤って「修正」しコード実行に踏み込むのを防ぐ)。
- 214化合物データセット・48件美容成分データセットの使用(§8-3)。
- ブランチ `microneedle-small-data-ml-paper` のマージ・チェックアウト・依存(参照は`git show`のみ可。§5)。
- PDF生成(このワークスペースの確立された文書パイプラインはMarkdown→HTMLのみ。旧`research/paper.pdf`は標準ビルド経路の生成物ではなかったため既に削除済み。新規PDF生成は行わない)。
- 投稿ジャーナルの選定・実際の投稿手続き。
- 新規のwet-lab実験・新規データ収集。

## 10. Acceptance checklist

- [ ] `paper.md` の全数値が §8-1・§8-2 のallowlistに独立して(元CSVと突き合わせて)たどれる
- [ ] Figure 1・Figure 2が `../research/fig_active_learning_curves.png` / `fig_lodo_comparison.png` への正しい相対パスで埋め込まれ、実際に解決する
- [ ] 214化合物・48成分データセットの数値が本文・図・表のどこにも登場しない(§8-3)
- [ ] `active_learning.py` を含むモデリング・計算コードを一切実行していない。実行したスクリプトは `build-website.sh` 系のみ
- [ ] Data and Code Availability節が、実際に存在するもの(戦略実装・既存CSV・既存図)と存在しないもの(driverスクリプト)を正確に区別している(§4 F-c)
- [ ] `research/active_learning_report.md` の `src/active_learning.py` パス誤記が修正されている(§4 F-d)
- [ ] Yuan et al.の既報値が「先行研究の値」として明示的に引用され、本研究の結果と区別されている
- [ ] 引用文献がすべて実在し、DOIが `CLAUDE.md` またはpaper.md既存Referencesと一致する
- [ ] `README.md`, `notes/decision-log.md` が完成している
- [ ] `active-learning-paper/`配下の全Markdownファイルの先頭本文行に `[HTML版を開く]` リンクがあり、`shared/scripts/build-website.sh` がエラーなく完走する
- [ ] `research/RESEARCH_PLAN.md` フェーズ6にこのモジュールへのクロスリンクが存在する(Sonnet-5段階で追加済み。維持されていることを確認)
- [ ] `notes/decision-log.md` に4段パイプライン(sonnet→fable→codex-terra→codex-sol)と主要判断・数値監査結果が記録されている
