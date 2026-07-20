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

## (このセクションは各ステージ完了時に追記される)
