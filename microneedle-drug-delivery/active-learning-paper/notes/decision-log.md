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

## (このセクションは各ステージ完了時に追記される)
