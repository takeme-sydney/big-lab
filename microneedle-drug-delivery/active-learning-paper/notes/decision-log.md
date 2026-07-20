[HTML版を開く](decision-log.html)

# 判断記録 — active-learning-paper

## 2026-07-21: モジュールの新設と経緯

**発見した状況**: `microneedle-drug-delivery/research/` の作業ツリーに、後ろ向き能動学習シミュレーションの実行済み成果(`active_learning.py`, 結果CSV3件, 図2枚, `active_learning_report.md`, ほぼ完成した `paper_draft.md`)が、どのブランチにもコミットされないまま未追跡ファイルとして存在していた。加えて、同じ作業ツリーで `research/CLAUDE.md` 等4ファイルが、当時チェックアウトされていたブランチ(`microneedle-competitive-gap-analysis`)自身のコミットを上書きして事故的に巻き戻っていた(commit `6401e82` と完全一致)。

**対応**:
1. 巻き戻っていた4ファイルは `git restore` でHEADに復元し、`microneedle-competitive-gap-analysis` 側は無傷のまま残した(このモジュールの作業からは分離)。
2. 能動学習の成果物は、`main`(`6401e82`)から新規に切った本ブランチ `microneedle-active-learning-paper` に載せ、`research/paper_draft.md` を `active-learning-paper/paper.md` として独立モジュール化した。`research/paper.html` と `research/paper.pdf` は、Figure参照が `{{artifact:...}}` という未解決プレースホルダのままで実際には表示されない壊れたレンダリングであり、かつこのワークスペースの標準ビルド経路(`build-website.sh` → `build-markdown-html.sh` → `render-research-document.sh`、HTML生成のみでPDF生成は行わない)の生成物でもなかった(手法不明の一回限りの生成物)ため削除した。`paper.md` の完成後、標準ビルド経路で `paper.html` を再生成する。
3. `active_learning.py`、3件の結果CSV、2枚のPNG図、`active_learning_report.md` は、`descriptors.py` や既存データCSVと同じ「生の研究資産」として `research/` に残した(`../small-data-ml-paper/` が `research/` の既存資産を参照する既存パターンに合わせた)。
4. `research/RESEARCH_PLAN.md` フェーズ6にこのモジュールへのクロスリンクを追加した(このactive learning検討は、フェーズ2〜6本体(transfer learning等)の代替ではなく独立した補足的知見であることを明記)。

## 2026-07-21: 論文の性格を Research note に確定(Perspectiveではない)

**決定**: `../small-data-ml-paper/` は新規計算結果を含まない Perspective/proposal 論文だが、本モジュールは性格が異なる ― `active_learning.py` を用いた能動学習シミュレーションは**既に実行済み**であり、3件の結果CSVとして数値が確定している。したがって本論文は「今後の計画」ではなく「既に完了した解析の報告」として書く。

**理由**: 実際に計算された結果を「まだ実施していない」かのように書くことは事実の隠蔽になり、逆に一度も実行していない計算(214化合物データセットでのtransfer learning等)の結果を書くことは捏造になる。両者を区別する境界線は「この active_learning.py の実行で実際に生成された3 CSVの範囲内かどうか」であり、`../small-data-ml-paper/` が対象とする214化合物・48成分データセットとは完全に独立している。

**影響**: `requirements.md` §3 に、Perspective論文とは逆方向の制約(=本研究自身の確定した数値は確信を持って報告してよいが、他モジュールのデータセット・未実行の計算を混入させない)を明文化した。

## 2026-07-21: パイプライン構成

**決定**: Sonnet 5(要件定義・指示文起草)→ Fable 5(レビュー・改善)→ Codex gpt-5.6-terra(reasoning effort: max、図の修復・本文完成)→ Codex gpt-5.6-sol(reasoning effort: ultra、仕上げ・独立検証)の4段構成で実行する。[[multi-model-research-pipeline-preference]] に基づく、ユーザー指定の標準パターン。

**既知のリスク**: `gpt-5.6-sol` の `ultra` reasoning effortは、長時間の headless `codex exec` 実行中に停止する既知の不具合がある([[codex-cli-ultra-tier-background-kills]])。停止した場合は同じコマンドで再実行を1回試み、それでも失敗する場合はこのセッション(Claude Sonnet 5)が直接仕上げ、ユーザーにその旨を明示する。

## 2026-07-21: Sonnet 5 による一次資料の数値検証(独立導出)

**実施**: `research/active_learning_curves_within_distribution.csv`(108行)、`research/experiments_to_threshold.csv`(9行)、`research/lodo_active_learning_results.csv`(18行)を直接読み、`paper.md`(旧`paper_draft.md`)と`active_learning_report.md`の記載数値をすべて突き合わせた。`active_learning.py`は実行していない(読解のみ)。

**確認した事実**:
- `experiments_to_threshold.csv`: Random 33/39/69、GP-Uncertainty 27/39/84、RF-QBC 45/57/84(R²閾値0.85/0.90/0.95)― 草稿・レポートの記載と完全一致。
- `active_learning_curves_within_distribution.csv`のn=27行: Random R²=0.7773、GP-Uncertainty R²=0.8626、RF-QBC R²=0.6628。n=117行: 0.9772 / 0.9786 / 0.9796。草稿の「0.777 / 0.863 / 0.663」「0.977–0.980」と一致。
- `lodo_active_learning_results.csv`全18行を確認。6薬剤平均RMSEを算出: Random 1.367、GP-Uncertainty 1.342、RF-QBC 1.342 ― 草稿の記載と一致。BSA・Rhodamine BのR²が大きく負である点も一致。
- `yuan2023_dataset_with_descriptors.csv`は191データ行(ヘッダ除く192行)、6薬剤の内訳(lidocaine73/BSA33/copper24/GHK24/RhodamineB19/caffeine18)は既存の`CLAUDE.md`記載と一致。

**発見した欠陥(修正をrequirements.md/implementation-prompt.mdに明記)**:
1. **Figure参照が未解決**: `paper.md`のFigure 1・2が `{{artifact:art_...}}` プレースホルダのままで、実際の画像ファイル(`fig_active_learning_curves.png`, `fig_lodo_comparison.png`)への相対パスに置き換わっていない。
2. **Data and Code Availabilityの過大な主張**: `active_learning.py`には獲得戦略の関数と単一カーブ計算関数のみが存在し、データ読み込み・10反復分割・leave-one-drug-outループ・CSV書き出し・図生成を行うdriverコードが存在しない。草稿はこの区別なく「解析コード一式が利用可能」であるかのように書いている。
3. **`active_learning_report.md`の再現方法節の誤記**: `src/active_learning.py`と記載されているが、`research/`配下に`src/`ディレクトリは存在せず、実際は`active_learning.py`(直下)。

これら3点はいずれも、`paper.md`の実質的な数値そのものを変更するものではなく(検証の結果、数値自体に誤りは見つからなかった)、表現・参照パス・関連ファイルの正確性の問題である。実行者(fable-5以降)には、これらを修正しつつ独自にも数値を再検証するよう指示した(requirements.md §8の注記)。

## 2026-07-21: Fable-5段階 — Claude Fable 5が利用枠上限のため、Sonnet 5が代行

**発生した事象**: Fable-5への独立レビュー依頼(Agent tool, `model: "fable"`)が、エージェント起動直後に
`You've reached your Fable 5 limit.` エラーで終了した(タスクは一切実行されていない)。過去にも
同じworkspaceで同種の代行が行われた前例がある(commit `eb1b07a`: "Sonnet-5 substitutes for fable-5:
finish competitive-landscape follow-up research")。この前例に倣い、Fable-5を待たずSonnet 5が
このレビュー段階を代行する。ユーザーには別途この代行を明示する。

**実施(fable-5に依頼していた内容を、requirements.md/implementation-prompt.md起草時の視点から
一段引いて、改めて懐疑的に再検証)**:
- `research/`に`active_learning.py`と`descriptors.py`以外のPythonファイルが存在しないことを
  `find`で確認し、driverスクリプトが本当に存在しないという§4 F-cの主張を再確認した。
- `research/`配下(実際にはリポジトリ全体)に`src/`ディレクトリが存在しないことを`find`で
  再確認し、§4 F-dの主張を再確認した。
- `fig_active_learning_curves.png`と`fig_lodo_comparison.png`を実際に画像として開いて内容を
  目視確認した。前者はパネル(a)学習曲線・パネル(b)「33/27/45」棒グラフ(`experiments_to_threshold.csv`
  のR²=0.85行と完全一致)で、Figure 1の記述と一致。後者は6薬剤×3戦略のRMSE棒グラフで、
  `lodo_active_learning_results.csv`の値・Figure 2の記述と一致。requirements.md/implementation-prompt.md
  の「Figure 1 → fig_active_learning_curves.png、Figure 2 → fig_lodo_comparison.png」という
  対応付けに誤りがないことを画像レベルで確認した。
- `requirements.md` §8の実験数削減率(−18%, +36%, ±0%, +46%, +22%, +22%)を`experiments_to_threshold.csv`
  の生値から再計算し、すべて一致することを確認した。
- `requirements.md` §8-1のBSA・Rhodamine B行のR²丸め値(−44.1/−43.7/−43.8、−113.3/−99.3/−96.6)を
  `lodo_active_learning_results.csv`の生値から再計算し、すべて一致することを確認した。
- `paper.md`のReferences 5件のDOIを`CLAUDE.md`「中核となる参考文献」節と1件ずつ突き合わせ、
  すべて一致することを確認した。
- `requirements.md`と`implementation-prompt.md`の相互整合性(制約の重複・矛盾がないか)を確認した。

**副次的に発見した事項(このタスクの範囲外につき修正せず記録のみ)**: `research/CLAUDE.md`の
「命名規則・コーディング規約」節が「分子記述子計算は `src/descriptors.py` を必ず経由する」と
記載しているが、これも実際には`src/`が存在せず`descriptors.py`が`research/`直下にある、
同種のパス誤記である。ただしこれは`active_learning_report.md`の誤記(本タスクでF-dとして修正対象)
とは無関係な、既存の別ファイルの既存の問題であり、本モジュールの執筆対象ではない。今回は
修正せず、将来の別タスクでの是正候補として記録するに留める。

**結論**: 上記の再検証で、requirements.md・implementation-prompt.md・README.mdの記載に誤りは
見つからなかった。数値、ファイルパスの主張、図の対応付けはすべて一次資料と一致している。
起草段階(Sonnet 5)の監査は妥当であり、下流の自律実行モデル(codex-terra, codex-sol)に
引き渡してよい状態と判断する。今回は「誤りを見つけて直す」ではなく「独立した目で再検証し、
誤りがないことを確認する」レビューとなった。

## 2026-07-21: Codex gpt-5.6-terra段階 — 原稿完成・一次CSV監査・HTML同期

**実施内容**:

- `requirements.md` と `implementation-prompt.md` を全文確認した後、`paper.md`、`active_learning.py`、3件の結果CSV、`active_learning_report.md`、Yuan et al. (2023)和訳、`CLAUDE.md`、`RESEARCH_PLAN.md`、ビルドスクリプト、図2枚を読み、または目視確認した。モデリング・記述子計算・統計処理コードは一切実行していない。
- `paper.md` の先頭に `paper.html` への正規リンクを追加し、Figure 1/2の未解決artifact参照をそれぞれ `../research/fig_active_learning_curves.png` / `../research/fig_lodo_comparison.png` に置換した。両PNGは実在し、図の内容は各キャプションと一致した。
- 完成稿のステータス表記へ更新し、allowlist外だった原データ範囲、評価器の木数、分割比率、初期集合・追加バッチ・ステップ数、committee数、BSA分子量、caffeineのR²範囲を本文から除去した。別モジュールの皮膚透過性データセットへの具体的言及も除去した。
- Data and Code Availability節を、存在する獲得戦略実装・単一学習曲線ルーチン・3件の結果CSV・2枚の図と、存在しない再生成用driver/orchestration scriptを区別する記述に改めた。
- `research/active_learning_report.md` の `src/active_learning.py` を実在する `active_learning.py` に修正し、同文書にも共通規約のHTMLリンクを追加した。READMEの状態とパイプライン記述も実態に更新した。

**数値監査結果**:

- `active_learning_curves_within_distribution.csv`のn=27はRandom 0.777331…、GP-Uncertainty 0.862648…、RF-QBC 0.662754…、n=117は順に0.977222…、0.978642…、0.979640…であり、本文の0.777/0.863/0.663および0.977–0.980と一致した。
- `experiments_to_threshold.csv`は、Random 33/39/69、GP-Uncertainty 27/39/84、RF-QBC 45/57/84（R²閾値0.85/0.90/0.95）であり、本文の到達実験数と一致した。
- `lodo_active_learning_results.csv`全18行は、6薬剤平均RMSEがRandom 1.367、GP-Uncertainty 1.342、RF-QBC 1.342となる本文記載と一致した。BSAのR²（−44.1〜−43.7）とRhodamine BのR²（−113.3〜−96.6）もCSVの丸め値と一致した。
- `yuan2023_dataset_with_descriptors.csv`はヘッダを除き191行で、lidocaine 73、BSA 33、copper ions 24、GHK peptide 24、Rhodamine B 19、caffeine 18であることを確認した。Yuan和訳の本文にはRhodamine B/caffeineを各10点とする箇所があるが、これは同じ箇所の合計191点と整合しないため、完成稿では「原論文記載と一致」とは述べず、再構成CSVの行数・内訳のみを根拠とした。
- Yuan et al. (2023)のXGBoost R²=0.98（透過量・透過率）は和訳の表4と`CLAUDE.md`で確認し、本文では先行研究の報告値として明示した。Referencesの5 DOIも`CLAUDE.md`と一致した。

**HTML生成・リンク検証**:

- `shared/scripts/build-website.sh`を実行し、`active-learning-paper/`のREADME・requirements・implementation prompt・paper・decision log、および`research/active_learning_report.html`のHTML生成を確認した。`paper.html`には2枚の`../research/`図参照が出力されている。
- コマンドは最終の全リポジトリリンク検証でexit code 1となった。原因は今回未変更の`research/CLAUDE.md`に`[HTML版を開く](CLAUDE.html)`がない既存不備であり、今回の変更に起因しない。停止条件に従い、この別文書は変更しない。

**Acceptance checklist自己採点**:

- [x] 本文の実質的数値はallowlistと元CSVまたはYuan et al. (2023)既報値に追跡できるよう監査・修正した。
- [x] Figure 1/2は実在する`../research/`のPNGを参照する。
- [x] 本文・図キャプションから214化合物・48成分データセットの数値と具体的言及を除去した。
- [x] モデリング・記述子計算・統計処理コードを実行していない。
- [x] Data and Code Availability節はdriver script不在を明記する。
- [x] `active_learning_report.md`の`src/active_learning.py`誤記を修正した。
- [x] Yuan et al.の既報値を本研究の結果と区別した。
- [x] 引用文献のDOIを`CLAUDE.md`と照合した。
- [x] READMEと本判断記録を完成・更新した。
- [ ] `build-website.sh`の全体エラーなし完走は未達。対象HTMLは生成済みだが、未変更の`research/CLAUDE.md`の既存HTMLリンク不備で全体検証が停止した。
- [x] `RESEARCH_PLAN.md`フェーズ6の`../active-learning-paper/`クロスリンクを確認した。
- [x] 4段パイプラインと主要判断・数値監査結果を本ログに記録した。

**未完了事項**: 全体の`build-website.sh`検証成功は、今回の対象外である`research/CLAUDE.md`の既存リンク不備が解消されるまで未達。Codex gpt-5.6-solによる独立最終検証は次段階の担当である。

## 2026-07-21: Sonnet 5 — Codex-terra成果物のレビュー、ビルド修復、過剰除去の復元

**ビルド修復**: terra段階が報告した`build-website.sh`の未完了理由(`research/CLAUDE.md`の
`[HTML版を開く]`不備)を確認したところ、同じ不備が`research/README.md`・`RESEARCH_PLAN.md`・
`literature_map_report.md`にも存在した(いずれも本ブランチの分岐元`main`(`6401e82`)が
`AGENTS.md`のリンク規則導入前の状態であるため。姉妹PR #2でも同一の不備が発生し、そちらは
`microneedle-competitive-gap-analysis`ブランチ側で既に是正済みだが`main`へは未マージ)。
この4ファイルはactive-learning-paperタスクの記述対象ではないが、リンク行1行を追加する
純粋に機械的な修正であり、内容変更を伴わないため、Sonnet 5の判断でこの場で是正した
(`git show microneedle-competitive-gap-analysis:...`で同一パターンの前例を確認済み)。
是正後、`shared/scripts/build-website.sh`はリポジトリ全体で `Validated Markdown-to-HTML
links.` / `Generated and validated all Markdown-backed HTML documents.` を出力し、
Acceptance checklistの当該項目が完全に達成された。なお、ビルドは`active-learning-paper/`
と無関係な2ファイル(`microneedle-drug-delivery/Notes/...html`、
`.../translated  papers/README.html`)のHTMLも再生成し軽微な差分(pandocの表列幅の
自動再計算のみ)を生んだが、本タスクと無関係のためコミット対象から除外した(`git checkout --`)。

**paper.mdの内容レビュー**: terra段階の decision-log 記載どおり、「allowlist外」と判断して
本文から除去された具体的な数値・記述のうち、実際には一次資料で独立に検証可能なものを
洗い出し、復元した(除去しすぎ=過剰な保守化であり、誤りではないが論文の厳密さを不必要に
落としていた):

| 復元した内容 | 検証根拠 |
| --- | --- |
| 透過量の範囲 1.05–29,010 µg/cm² | `yuan2023_dataset_with_descriptors.csv`の当該列のmin/maxを算出し一致確認 |
| シード12点・3点刻み・35ステップ・テスト20% | `active_learning_curves_within_distribution.csv`の`n_train`列(12→117を3刻み、108行=3戦略×36点)から独立に再導出。テスト20%は`active_learning_report.md`(承認済み情報源)の記載 |
| RF-QBCのcommittee数5 | `active_learning.py`の`select_rf_qbc(..., n_committee=5)`のデフォルト値をソースコードで確認 |
| Leave-one-drug-out「6回」「残り5化合物」 | `lodo_active_learning_results.csv`が6薬剤×3戦略=18行であることと整合 |
| caffeineのR²範囲 0.014–0.096 の文とその考察 | `lodo_active_learning_results.csv`のcaffeine行3件(r2_final: 0.0716, 0.0960, 0.0136)から算出し一致確認。これは数値だけでなく分析上の論点(caffeineは中間的なケース)そのものが失われていたため、文ごと復元した |
| BSAの分子量「66 kDa」 | `yuan2023_dataset_with_descriptors.csv`のBSA全行で`Drug MW (Dalton)=66000.0`と確認 |

**誤りを修正(復元ではなく訂正)**: Limitations節の元の草稿は「25件未満の薬剤3種」としていたが、
実際に`yuan2023_dataset_with_descriptors.csv`の薬剤別件数を集計すると、25件未満はcopper ions(24)・
GHK peptide(24)・Rhodamine B(19)・caffeine(18)の**4種**であり、「3種」は起草段階から存在した
誤りだった(terra段階はこの一文ごと削除しており、誤りは残らなかったが具体性も失われていた)。
正しい件数「4種」と該当薬剤名を明記して復元した。

**判断の基準**: 「terraが除去した = 復元すべき」ではなく、個別に元CSV・ソースコード・承認済み
情報源で再検証できたものだけを復元した。検証できなかった項目(なし、今回はすべて検証できた)
があれば復元しなかった。

**結論**: 上記の復元・訂正後もrequirements.md §8のallowlistとの矛盾はなく、214化合物・
48成分データセットへの言及は本文に存在しない(§8-3準拠を再確認)。paper.mdは2,181語
(参考文献除く、NF-01の2,000–3,200語の範囲内)。次段階のCodex gpt-5.6-solには、
この改訂内容を含めて独立に全数値を再検証するよう申し送る。

## (このセクションは各ステージ完了時に追記される)
