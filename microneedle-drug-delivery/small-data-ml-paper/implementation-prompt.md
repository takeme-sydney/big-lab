[HTML版を開く](implementation-prompt.html)

# 実行用指示文

以下は、`small-data-ml-paper/paper.md`(Perspective / Research proposal論文)を書き上げるための、このタスク専用の指示文である。実行者(fable-5、codex gpt-5.6-terra、codex gpt-5.6-sol)は、このコードブロックの内容をそのまま自分へのタスクとして実行すること。

```text
あなたはmicroneedle drug delivery、small-data machine learning、QSAR、
学術論文執筆を支援するresearch writing assistantです。

目的:
big-lab/microneedle-drug-delivery/research/ に蓄積された研究準備内容を土台に、
big-lab/microneedle-drug-delivery/small-data-ml-paper/paper.md として
Perspective / Research proposal論文(英語)を完成させる。
この論文は新規の計算結果を一切報告しない。

最初に読むローカル資産:
1. big-lab/microneedle-drug-delivery/small-data-ml-paper/requirements.md(この論文の要件定義。必読・最優先)
2. big-lab/microneedle-drug-delivery/research/RESEARCH_PLAN.md
3. big-lab/microneedle-drug-delivery/research/CLAUDE.md
4. big-lab/microneedle-drug-delivery/research/README.md
5. big-lab/microneedle-drug-delivery/research/literature_map_report.md
6. big-lab/microneedle-drug-delivery/research/microneedle_ml_literature.csv
7. big-lab/microneedle-drug-delivery/research/cosmetic_ingredients_descriptors.csv
8. big-lab/microneedle-drug-delivery/research/skin_permeability_training_set.csv
9. big-lab/microneedle-drug-delivery/research/yuan2023_training_data.csv
10. big-lab/microneedle-drug-delivery/research/yuan2023_dataset_with_descriptors.csv
11. big-lab/microneedle-drug-delivery/research/descriptors.py
12. big-lab/microneedle-drug-delivery/research/fig1_landscape.png, fig2_influence_methods.png
13. big-lab/AGENTS.md(Markdown正本+HTML同期ルール)
14. big-lab/shared/scripts/build-website.sh, build-markdown-html.sh, check-document-html-links.sh

必須原則(要件定義 requirements.md §3, §8 と同一。矛盾する場合はrequirements.mdを優先):
- 「実測・完了済みの事実」「文献に書かれた事実」「今後の計画・提案」を語彙で明確に分ける
  (例: "we assembled / we curated"は完了事実、"we propose / future work will"は計画)。
- RESEARCH_PLAN.mdのフェーズ0, 1, 1.5(文献マップ構築、データ収集、Yuan 2023再現)は
  完了した成果として報告してよい。フェーズ2〜6(データキュレーション、モデル構築、
  transfer learning、SHAP、美容成分予測)は一度も実行していないため、
  「今後実施する計画」としてのみ記述する。
- RF/XGBoost/GPR/SHAPの具体的な数値結果(R²、RMSE、feature importance等)を、
  実際に計算していないのに書かない。美容成分の予測log Kp値を具体的数値として書かない。
- 引用文献はmicroneedle_ml_literature.csvまたはRESEARCH_PLAN.md中核5文献の範囲に限る。
  実在確認できない文献・DOIを作らない。
- データセットの件数(214化合物, 191点・6薬剤, 美容成分48件, 文献116本)は
  元CSVの実際の行数と完全に一致させる。
- Figure 1(fig1_landscape.png)とFigure 2(fig2_influence_methods.png)は
  実データ図としてそのまま論文に埋め込む。新しい図を数値なしで作らない。
- Yuan et al. (2023) の記述(手法、R²=0.98、Discussion 4.2節の限界)は
  原論文の記載を正確に引用し、誇張・改変しない。
- 購読論文の本文を転載・再配布しない。書誌情報とDOIのみ引用する。

今回のタスク:
requirements.md §4 の10章立て(Title & Abstract, Introduction, Related Work /
Literature Landscape, Research Gap, Completed Preliminary Work, Proposed
Methodology / Future Work, Anticipated Contributions, Limitations, Data &
Ethics Statement, References)に従い、paper.md を英語で完成させる。
分量はNF-01(4,000〜6,500語、参考文献リスト除く)を満たす。
README.md(日本語、他モジュールのREADME.mdと同じ構成)と
notes/decision-log.md(日本語、今回のパイプラインと主要判断の記録)も完成させる。

実行順:
1. requirements.md §3(捏造防止制約)を読み、違反していないか常に自己点検する。
2. research/配下の全資産を読み、完了済み事実(フェーズ0/1/1.5)と
   未実施計画(フェーズ2〜6)を仕分けたメモを作る(notes/decision-log.mdに残してよい)。
3. paper.mdの章立てを requirements.md §4 の順に埋める。
   各章を書くたびに、直前に定めた「事実 vs 計画」の仕分けと矛盾しないか確認する。
4. Figure 1・Figure 2をMarkdown画像記法で埋め込み、キャプションに出典ファイル名を明記する。
5. Referencesセクションをmicroneedle_ml_literature.csv/RESEARCH_PLAN.mdと突き合わせながら作成する。
6. README.md、notes/decision-log.mdを完成させる。
7. 全Markdownファイルの先頭本文行に `[HTML版を開く](対応するhtmlファイル名)` を付与する
   (front matterがある場合は`---`直後)。
8. `big-lab/shared/scripts/build-website.sh` を実行し、エラーなく完走することを確認する
   (Markdown→HTML変換とリンク検証を兼ねる)。エラーが出た場合は原因を修正して再実行する。
9. requirements.md §10 の Acceptance checklist を1項目ずつ自己採点し、
   未達成の項目があれば理由を明記した上でnotes/decision-log.mdに残す。

最低限の出力:
- 完成した paper.md(英語、10章立て、4,000〜6,500語、Figure 1・2埋め込み済み、
  Referencesに実在文献のみ)
- 完成した README.md(日本語)
- 完成した notes/decision-log.md(日本語、事実/計画の仕分けメモと自己採点結果を含む)
- `shared/scripts/build-website.sh` の実行結果(成功ログ、または修正内容)
- requirements.md §10 Acceptance checklistの自己採点結果

停止条件:
- research/配下の資産だけでは requirements.md §4 のある章が事実に基づいて書けない
  (例: 追加の一次資料が必要)場合、その章を捏造で埋めず、不足している情報と
  確認先を明記して報告する。
- 引用したい文献がmicroneedle_ml_literature.csv/RESEARCH_PLAN.md中核5文献の
  どちらにも存在せず、かつその実在・内容を確認する手段がない場合、その文献の追加を諦め、
  その旨をnotes/decision-log.mdに記録する。
- `build-website.sh` が既存の(このタスクと無関係な)エラーで失敗する場合、
  無理に既存ファイルを書き換えず、エラー内容をそのまま報告する。

停止条件に該当する場合も、報告済みの範囲までは完成させ、全体を未完成のまま放置しない。
```
