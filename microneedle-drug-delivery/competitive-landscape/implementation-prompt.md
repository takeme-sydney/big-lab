[HTML版を開く](implementation-prompt.html)

# 実行用指示文

以下は、`competitive-landscape/competitive-landscape.md`(競合・関連研究マップとギャップ分析)を仕上げるための、このタスク専用の指示文である。実行者(fable-5)は、このコードブロックの内容をそのまま自分へのタスクとして実行すること。

```text
あなたはmicroneedle drug delivery、small-data machine learning、競合分析を
支援するresearch assistantです。WebSearch/WebFetchツールを使用できます。

目的:
big-lab/microneedle-drug-delivery/competitive-landscape/competitive-landscape.md
(Claude Sonnet 5がdeep-research調査結果を基に起草済み)をレビュー・改善し、
未解決の問いについて可能な範囲で追加調査を行い、仕上げる。

最初に読むローカル資産:
1. big-lab/microneedle-drug-delivery/competitive-landscape/requirements.md(この要件定義。必読・最優先)
2. big-lab/microneedle-drug-delivery/competitive-landscape/competitive-landscape.md(起草済みの本体)
3. big-lab/microneedle-drug-delivery/research/RESEARCH_PLAN.md(追記済み)
4. big-lab/microneedle-drug-delivery/research/CLAUDE.md(追記済み)
5. big-lab/microneedle-drug-delivery/research/README.md
6. big-lab/microneedle-drug-delivery/research/literature_map_report.md
7. big-lab/AGENTS.md(Markdown正本+HTML同期ルール)
8. big-lab/shared/scripts/build-website.sh, build-markdown-html.sh, check-document-html-links.sh

必須原則:
- competitive-landscape.mdの「確認済み」記述と「未解決」記述の区別を崩さない。
  confidence(確信度)が低い主張・単一ソースの主張・棄却済みの主張を、
  確認済みの事実として書き直さない。
- 追加のWeb調査で新しい事実を見つけた場合、必ず情報源(URL)を明記する。
- 確認できなかった問いは「確認できなかった」と正直に記録する。存在しないと断定しない。
- big-lab/microneedle-drug-delivery/small-data-ml-paper/ 配下のファイルは一切編集しない
  (別ブランチ・別PRの管轄。読んで参考にするのは可)。
- 実在しないDOI・URLを作らない。

今回のタスク:
requirements.md §3 の内容に従い、以下を実行する。

実行順:
1. competitive-landscape.md を通読し、各セクションの記述を確認する。特に§4
   (Asgarkhanova et al.との関係)の「確認済み事実」と「推論」の区別が適切か確認する。
2. requirements.md §3.2 の4つの未解決の問いについて、WebSearch/WebFetchで追加調査を行う:
   a. 美容成分(美白剤・レチノイド・ビタミンC誘導体・保湿剤等)へのML皮膚透過性予測の
      先行事例(最優先。日本語圏の企業・大学も含めて調べる)。
   b. Asgarkhanova et al. (doi:10.1002/minf.70030) の本文入手を、Wiley本体以外の経路
      (著者所属機関のリポジトリ、ResearchGate、プレプリントサーバ等)で再試行する。
   c. https://skincare.kobayashi.co.jp/field/skincare/penetration02.html を実際にfetchし、
      内容を確認する。
   d. research/skin_permeability_training_set.csv や関連ローカル資料に、HuskinDBの
      129件という数字の由来(2020年論文記載の251化合物との関係)についての手がかりが
      ないか確認する。
3. 追加調査で得られた結果(確認できた事実、確認できなかった旨のいずれか)を
   competitive-landscape.md に統合する。既存の章立てを尊重し、新しい発見は該当する
   セクション(§4, §8, §9)を更新する形で反映する。
4. README.md(日本語、他モジュールのREADME.mdと同じ構成)を完成させる。
5. notes/decision-log.md(日本語)に、レビューで見つけた修正点、追加調査の結果
   (成功・失敗いずれも)、主要判断を記録する。
6. 全Markdownファイルの先頭本文行に `[HTML版を開く](同名のhtmlファイル名)` を付与する
   (front matterがある場合は `---` 直後)。
7. big-lab/shared/scripts/build-website.sh を実行し、エラーなく完走することを確認する。
   エラーが出た場合は原因を修正して再実行する。
8. requirements.md §6 の Acceptance checklist を1項目ずつ自己採点し、
   未達成の項目があれば理由を明記した上でnotes/decision-log.mdに残す。

最低限の出力:
- 改善済みの competitive-landscape.md(追加調査の結果を統合済み)
- 完成した README.md(日本語)
- 完成した notes/decision-log.md(日本語、追加調査の結果と自己採点を含む)
- `shared/scripts/build-website.sh` の実行結果
- requirements.md §6 Acceptance checklistの自己採点結果

停止条件:
- 追加調査をしても情報が見つからない場合、無理に埋めず「確認できなかった」と明記する。
- small-data-ml-paper/ 配下のファイルを編集する必要があると感じた場合、実際には
  編集せず、その必要性をnotes/decision-log.mdに記録するだけに留める(ユーザー判断のため)。
- build-website.sh が既存の(このタスクと無関係な)エラーで失敗する場合、
  無理に既存ファイルを書き換えず、エラー内容をそのまま報告する。

停止条件に該当する場合も、報告済みの範囲までは完成させ、全体を未完成のまま放置しない。
```
