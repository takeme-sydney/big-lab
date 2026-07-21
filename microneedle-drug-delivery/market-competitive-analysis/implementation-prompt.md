[HTML版を開く](implementation-prompt.html)

# 実行用指示文

以下は、`market-competitive-analysis/market-competitive-analysis.md`(商用・市場競合分析)を新規作成するための、このタスク専用の指示文である。実行者(Codex gpt-5.6-terra → Codex gpt-5.6-sol)は、このコードブロックの内容をそのまま自分へのタスクとして実行すること。

```text
あなたはmicroneedle drug delivery市場・化粧品成分デリバリー市場の競合分析を行う
research analystです。

目的:
big-lab/microneedle-drug-delivery/research/ で進めているsmall-data MLアプローチ
(214化合物の皮膚透過性データ+Yuan et al. 2023の191点マイクロニードルデータへの
転移学習+美容成分48件スクリーニング)について、実在する商用・市場競合(学術的手法
比較ではない)を実際にWeb調査し、
big-lab/microneedle-drug-delivery/market-competitive-analysis/market-competitive-analysis.md
として批判的なgap analysisを新規作成する。

経緯: 当初Claude Code側のdeep-researchハーネスでこの調査を行う予定だったが、
Claudeアカウントのセッション利用上限により実行できなかった。そのためこのタスクは
あなた(Codex)に委譲されている。あなたは実際のWeb検索・取得ツール(利用可能な場合)
または bash 経由の curl/HTTPアクセスを用いて、実在する一次資料(企業サイト、
プレスリリース、特許データベース、PubMed/Crossref、規制当局サイト等)を実際に
取得すること。取得できなかった場合はその旨を正直に記録し、主張を捏造しない。

最初に読むローカル資産:
1. big-lab/microneedle-drug-delivery/market-competitive-analysis/requirements.md
   (この調査の要件定義。必読・最優先)
2. big-lab/microneedle-drug-delivery/research/CLAUDE.md, RESEARCH_PLAN.md
   (現行システムの記述 ― ギャップ分析の比較対象)
3. git show microneedle-competitive-gap-analysis:microneedle-drug-delivery/competitive-landscape/competitive-landscape.md
   (既存の学術的競合分析。内容を転記せず、重複回避の確認にのみ使う。
   git showでファイル単位に閲覧し、ブランチのチェックアウト・マージはしない)
4. big-lab/microneedle-drug-delivery/research/literature_map_report.md(参考、任意)

必須原則(requirements.md §3, §8と同一。矛盾する場合はrequirements.mdを優先):
- 実在しない企業名・製品名・URL・特許番号・引用を作らない。見つけられなかった
  情報は「確認できなかった」と正直に書く。
- 「〜社はAI/MLを使っている」という主張は、実際に取得したURLに基づく場合のみ記載し、
  マーケティング文言(裏付けなし)と査読論文・特許による裏付けを明確に区別する。
  各主張に確信度区分(a: 査読論文・特許で裏付け可能 / b: 公式発表のみ・独立検証なし /
  c: 二次情報源・推測)を付与する。
- ../competitive-landscape/(学術的競合、別ブランチ)の内容を重複調査・転記しない。
- ../small-data-ml-paper/、../active-learning-paper/(いずれも別ブランチ、未マージ)
  を直接編集しない。改訂提案は本文書§7で述べるに留める。
- Web取得に失敗した場合(ツール利用不可、404、アクセス拒否等)、その事実をそのまま
  notes/decision-log.mdに記録する。取得できなかったことを隠して一般論で埋めない。

今回のタスク(requirements.md §4 の章立てに対応):
1. まず、利用可能なWeb検索・取得手段を確認する(native web search tool、
   ブラウジングツール、または bash 経由の curl/wget)。利用可能な手段を
   notes/decision-log.mdの冒頭に記録する。
2. requirements.md §4の章立てに従い、実際に検索・取得を行いながら
   market-competitive-analysis.md を執筆する:
   - マイクロニードル製品・企業マップ(医薬品用・化粧品用)
   - AI/ML活用を謳う企業の検証(確信度区分付き)
   - 化粧品成分デリバリーの受託開発・プラットフォーム企業
   - 商用検証手法(Franz cell、臨床試験、規制申請)との対比
   - 現在のシステムとの具体的ギャップ分析(§4の(a)〜(d)を含む)
   - small-data-ml-paper・active-learning-paperへの改訂提案(§4-8、提案のみ)
   - 未解決の問い・確認できなかった事項
   - References(実在するURL・DOI・特許番号のみ)
3. 各主張の出典URLと確信度区分を本文に明記する(脚注形式・インライン引用いずれでも可、
   一貫していること)。
4. README.md(日本語、他モジュールと同じ構成: 概要・Start here・このモジュールの
   位置づけ・今回の成果物・執筆パイプライン・フォルダ構成)を作成する。
5. notes/decision-log.md(日本語)に、使用した検索手段、主要な判断、
   ../competitive-landscape/との重複回避の確認結果を記録する。

Codex gpt-5.6-sol(第2段)への引き継ぎ事項:
- 第1段(terra)が本文中に記載した主要な主張(特に「企業Xが手法Yを使用している」
  という主張)を、独立に元のURLへ再アクセスして内容が一致するか検証する。
  一致しない・アクセス不能な場合は主張を弱めるか削除し、notes/decision-log.mdに
  理由とともに記録する(deep-researchのadversarial verification相当)。
- 実在しないURL・企業・DOIが紛れ込んでいないか、全References節を再確認する。
- requirements.md §10 Acceptance checklistを自己採点し、未達成項目は理由を
  明記した上でnotes/decision-log.mdに残す。

実行順:
1. requirements.md全文を読む。
2. 利用可能なWeb検索・取得手段を確認し記録する。
3. §4の章立てに従い実際に調査・執筆する。出典URLと確信度区分を都度記録する。
4. README.md、notes/decision-log.mdを作成する。
5. market-competitive-analysis/配下の全Markdownファイルの先頭本文行に
   `[HTML版を開く](同名のhtmlファイル名)`を付与する。
6. big-lab/shared/scripts/build-website.sh を実行し、このモジュールに関して
   エラーなく完走することを確認する。このタスクと無関係な既存のエラーが
   あれば無理に修正せず報告する。
7. requirements.md §10のAcceptance checklistを自己採点し、
   notes/decision-log.mdに記録する。

最低限の出力:
- 完成した market-competitive-analysis.md(実URL/DOI/特許番号付きの引用、
  確信度区分付き)
- 完成した README.md(日本語)
- 完成した notes/decision-log.md(日本語、使用した検索手段・主要判断・
  数値/主張監査結果を含む)
- shared/scripts/build-website.sh の実行結果
- requirements.md §10 Acceptance checklistの自己採点結果

停止条件:
- Web検索・取得手段が全く利用できない場合、その事実を最優先でnotes/decision-log.md
  に記録し、可能な範囲(ローカル資産からの示唆等)で§7の分析のみ行い、
  企業・製品の具体名を伴う主張は一切追加しない(捏造するくらいなら空白のほうが良い)。
- 個々の主張についてURLでの裏付けが得られない場合、その主張を書かず、
  §9「未解決の問い」に記録する。
- build-website.shがこのタスクと無関係な既存のエラーで失敗する場合、
  無理に既存ファイルを書き換えず、エラー内容をそのまま報告する。
- git commit・git push・ghコマンドは実行しない(Sonnet-5が最終レビュー後に行う)。

停止条件に該当する場合も、報告済みの範囲までは完成させ、全体を未完成のまま放置しない。
```
