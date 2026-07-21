[HTML版を開く](requirements.html)

# 要件定義 — Market/Commercial Competitive Analysis for Microneedle Drug & Cosmetic-Ingredient Delivery

文書版: 1.0
作成日: 2026-07-21
対象: `big-lab/microneedle-drug-delivery/market-competitive-analysis/market-competitive-analysis.md`
根拠資料: `big-lab/microneedle-drug-delivery/research/`(`CLAUDE.md`, `RESEARCH_PLAN.md`, データセット), `../small-data-ml-paper/`, `../active-learning-paper/`(いずれも別ブランチ、`git show`のみで参照)

## 1. 目的

`microneedle-drug-delivery/research/` の small-data MLアプローチ(214化合物皮膚透過性データ+Yuan et al. 2023の191点マイクロニードルデータへの転移学習+美容成分48件スクリーニング)について、**実在する商用・市場競合**(学術的手法比較ではない)を調査し、現在のシステムとの差分・ギャップを批判的に分析する。この分析結果は、後続タスクで [`../small-data-ml-paper/`](../small-data-ml-paper/) と [`../active-learning-paper/`](../active-learning-paper/) の両論文を批判的に改訂するための根拠として使われる。

**既存モジュールとの違い(重複回避)**: [`../competitive-landscape/`](../competitive-landscape/)(ブランチ `microneedle-competitive-gap-analysis`)は既に「MLアプローチそのもの」の学術的競合(手法・論文レベル、deep-researchハーネスで6検索角度・26一次資料・113主張抽出・25件adversarial verification済み)を調査済みである。本モジュールはそれとは異なる角度 ― **実在する企業・製品・商用サービス**(マイクロニードル製品メーカー、AI/ML活用を謳う企業、化粧品成分デリバリーの受託開発企業)を対象とする。学術論文・手法の比較は`../competitive-landscape/`の範囲であり、本モジュールで再調査しない。

## 2. 経緯(重要 — 実行方法の変更)

当初計画では Claude Code の `/deep-research` ハーネス(Web検索エージェントの並列実行)でこの調査を行う予定だったが、2026-07-21 12:16頃(Sydney時間)に実行したところ、**Claudeアカウントのセッション利用上限(15:50リセット予定)により5検索角度全てが失敗し、0件の一次資料取得で終了した**(このワークスペースで同時に複数のClaudeセッションが稼働していたことが一因と推測される)。ユーザーの指示により、この調査タスクを **Codex CLI(`gpt-5.6-terra` → `gpt-5.6-sol`、OpenAIアカウント・別クォータ)に委譲**する。Codex自身が実際のWeb検索・取得ツール(またはbash経由のHTTPアクセス)を用いて一次資料を取得し、引用可能なURLを伴う主張のみを採用すること。

## 3. 論文の位置づけ・ジャンル(最重要制約)

- ジャンル: **商用・市場競合分析(gap analysis)**。学術論文ではなく、実在企業・製品の公開情報に基づく調査レポート。
- **絶対に行ってはならないこと**:
  - **実在しない企業名・製品名・URL・特許番号・引用を作らない。** 見つけられなかった場合は「確認できなかった」と正直に書く(deep-researchハーネスの adversarial verification 相当の懐疑性を、Codex自身が代替として実施する)。
  - 「〜社はAI/MLを使っている」という主張は、**必ず実際に取得したURL(プレスリリース・特許・査読論文・製品ページ等)に基づいて引用し**、マーケティング文言(裏付けなし)と査読済み証拠(特許・論文)を明確に区別する。区別できない場合は「マーケティング上の主張であり、独立した裏付けは確認できなかった」と明記する。
  - `../competitive-landscape/`(学術的競合)の内容を重複して再調査・転記しない。参照する場合は `git show microneedle-competitive-gap-analysis:microneedle-drug-delivery/competitive-landscape/competitive-landscape.md` でファイル単位に閲覧するに留め、チェックアウト・マージはしない。
  - `../small-data-ml-paper/`・`../active-learning-paper/`(いずれも別ブランチ、未マージ)を直接編集しない。本モジュールはあくまで調査・分析であり、両論文の改訂は別タスクとして後続で実施する(§9参照)。
  - 実際にWeb取得できなかった主張を、あたかも取得したかのように書かない。ツールの利用不可・取得失敗があれば、その事実を `notes/decision-log.md` に明記する。
- **区別のための明確化(過剰な自主規制で価値を落とさないために)**: 十分な根拠(実URL)がある主張は、確信を持って報告してよい。「確認できなかった」で埋め尽くす必要はない ― 実在する具体的な企業・製品を実際に探し出すことが本タスクの核心的価値である。

## 4. 必須コンテンツ

`market-competitive-analysis.md` の章立て(新規作成):

1. **概要(Executive summary)** — 主要な発見3〜5点
2. **調査範囲と方法** — 何を調べ、何を調べなかったか(§1の重複回避を含む)、使用したツール・検索方法、取得できなかった情報の扱い
3. **マイクロニードル製品・企業マップ** — 医薬品デリバリー用MN製品/企業、化粧品・スキンケア用MN製品/企業。各企業について: 製品名、対象の薬剤/成分、公開されている処方開発・性能予測手法(経験的/試行錯誤 vs. 何らかの計算的手法の主張)
4. **AI/ML活用を謳う企業の検証** — 具体的な企業名・claim・出典URL・裏付けレベル(特許/査読論文で裏付け可能 vs. マーケティング文言のみ)
5. **化粧品成分デリバリーの受託開発(ODM)・プラットフォーム企業** — 予測的スクリーニングを用いる企業があるか
6. **商用検証手法との対比** — Franz cell透過試験・臨床試験・規制申請等の商用検証手法と、本プロジェクトの「既存公開データのみを用いたretrospective計算検証(新規wet-lab実験なし)」との違い。これが本プロジェクトの信頼性・実用化における意味を批判的に論じる
7. **現在のシステムとのギャップ分析** — `research/CLAUDE.md`・`RESEARCH_PLAN.md` に記載の現行アプローチ(小規模データQSAR、転移学習、美容成分スクリーニング)と、上記商用実態との具体的な差分。少なくとも以下を含めること: (a) 商用実証(wet-lab/臨床)の欠如、(b) 化粧品成分特化データの不足、(c) 規制・特許面での位置づけの欠如、(d) 商用主体が実際に使っている(公開情報から確認できる)手法との技術的な差
8. **小Data-mlAperと能動学習論文への示唆** — §9で行う両論文改訂の方向性を提案として記述(このモジュール自身では両論文を編集しない)
9. **未解決の問い・確認できなかった事項**
10. **References**(実在するURL・DOI・特許番号のみ)

## 5. 使用可能な情報源

- `microneedle-drug-delivery/research/CLAUDE.md`, `RESEARCH_PLAN.md`(現行システムの記述)
- `microneedle-drug-delivery/research/literature_map_report.md`(学術文献マップ、企業名が言及されている場合の出発点として参照可。ただし本モジュールの主目的は新規のWeb調査であり、このファイルへの転記のみで済ませない)
- `git show microneedle-competitive-gap-analysis:microneedle-drug-delivery/competitive-landscape/competitive-landscape.md`(重複回避の確認用。内容を転記しない)
- `git show microneedle-small-data-ml-paper:microneedle-drug-delivery/small-data-ml-paper/paper.md`(将来の改訂対象の現状把握用)
- `git show microneedle-active-learning-paper:microneedle-drug-delivery/active-learning-paper/paper.md`(同上)
- 実際のWeb検索・取得(企業サイト、プレスリリース、特許データベース、PubMed/Crossref、規制当局サイト等)― 本モジュールの主たる一次資料

## 6. Functional requirements

| ID | 要件 | 受入条件 |
| --- | --- | --- |
| F-01 | 調査本体 | `market-competitive-analysis.md` に§4の全章が存在し、各実質的主張に実URL/DOI/特許番号の出典が付いている |
| F-02 | 重複回避 | `../competitive-landscape/`と内容が重複しない(学術手法比較を含まない) |
| F-03 | 言語 | 本体は英語可・日本語可のいずれでも良いが、README/requirements/implementation-prompt/decision-logは日本語(既存慣行) |
| F-04 | HTML同期 | `AGENTS.md`の規則に従い、全Markdownの先頭本文行に`[HTML版を開く]`リンクを付与し、`build-website.sh`実行後にHTML生成される |
| F-05 | ファイル構成 | `README.md`, `requirements.md`, `implementation-prompt.md`, `market-competitive-analysis.md`, `notes/decision-log.md` が揃っている |
| F-06 | 取得失敗の記録 | Web取得・検索ツールが利用できなかった、または失敗した場合、その事実と代替手段(bash経由のcurl等)を`notes/decision-log.md`に記録する |

## 7. Non-functional requirements

| ID | 要件 | 基準 |
| --- | --- | --- |
| NF-01 | Scientific integrity | 実在しない企業・製品・URL・特許を作らない。確認できなかった事項は明示する |
| NF-02 | 出典の実在性 | 全URLが実際にアクセス可能な(またはアクセスを試みた)ものであること。アクセスできたURLとできなかったURLを区別して記録する |
| NF-03 | Consistency | `research/CLAUDE.md`の用語(logKp, Applicability Domain等)と矛盾しない |
| NF-04 | 批判性 | 単なる企業リストではなく、現行システムとの具体的な差分・示唆を伴う分析とする(§4-7, 8) |

## 8. 検証プロトコル(数値allowlistの代替 — 出典プロトコル)

このモジュールには対応する事前計算済みCSVが存在しないため、他モジュールの「数値allowlist」の代わりに以下の出典プロトコルを適用する:

- 企業名・製品名・「AI/ML使用」等の実質的主張は、**取得した実際のURL**(企業サイト、プレスリリース、特許庁DB、PubMed/Crossref、ニュース記事等)に基づく場合のみ記載する。
- 出典の確信度を3段階で明示する: **(a) 査読論文・特許で裏付け可能**、**(b) 公式発表・プレスリリースで確認できるが独立検証なし**、**(c) 二次情報源・推測**。§4の各主張にこの区分を付与する。
- 取得を試みたが失敗した(404、アクセス不可、ツール利用不可等)場合は、その旨を§9「未解決の問い」に記録し、主張を作らない。
- Codex-terra(第1段)は実際に検索・取得を行い、Codex-sol(第2段)は独立に主要な主張のURLへ再アクセスし、内容が主張と一致するかを検証する(deep-researchハーネスのadversarial verification相当)。不一致・アクセス不能を発見した場合は主張を弱めるか削除し、`notes/decision-log.md`に記録する。

## 9. Out of scope

- `../small-data-ml-paper/`・`../active-learning-paper/`の直接編集(本モジュールでは行わない。分析結果は§4-8で提案に留め、実際の改訂は別タスク・別作業ツリーで実施する)。
- `../competitive-landscape/`の学術的競合内容の再調査・転記。
- ブランチ`microneedle-competitive-gap-analysis`・`microneedle-small-data-ml-paper`・`microneedle-active-learning-paper`のチェックアウト・マージ(`git show`のみ可)。
- 新規のモデリング・計算コードの作成・実行(このモジュールは調査分析であり、`research/`のデータ・コードを変更しない)。
- PDF生成。

## 10. Acceptance checklist

- [ ] `market-competitive-analysis.md`の§4全章が存在し完成している
- [ ] 各実質的主張(企業名・製品名・AI/ML使用claim)に実URL/DOI/特許番号の出典と確信度区分(a/b/c)が付いている
- [ ] `../competitive-landscape/`との内容重複がない
- [ ] 実在しない企業・製品・URL・特許が無いことをCodex-sol段階で独立検証済み
- [ ] `README.md`, `notes/decision-log.md`が完成している
- [ ] 全Markdownファイルの先頭本文行に`[HTML版を開く]`リンクがあり、`build-website.sh`がこのモジュールに関してエラーなく完走する
- [ ] Web取得・検索ツールの利用可否・失敗事例が`notes/decision-log.md`に記録されている
- [ ] §8のsmall-data-ml-paper・active-learning-paperへの改訂提案が具体的に記述されている(後続タスクがそのまま着手できる程度に)
