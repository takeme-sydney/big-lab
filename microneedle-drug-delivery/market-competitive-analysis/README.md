[HTML版を開く](README.html)

# Microneedle ML 商用・市場競合分析

更新日: 2026-07-21
状態: Codex-terraによるWeb調査・初稿・HTML生成完了 / Codex-sol独立検証待ち（リポジトリ全体のHTML validatorは既存の`research/CLAUDE.md`リンク不備で停止）

## 概要

`research/`で進めるsmall-data MLアプローチについて、実在する企業・製品・受託開発・商用検証を調べた商用・市場gap analysisです。医薬品/ワクチン用MN、化粧品用溶解性MN、ODM、*in vitro*＋*in silico*サービス、化粧品R&DのAI利用を分け、企業の公式発表と査読・規制・試験登録の証拠を混同しないように整理しています。

## Start here

1. 要件定義: [`requirements.md`](requirements.md)
2. 実行用指示文: [`implementation-prompt.md`](implementation-prompt.md)
3. 商用・市場競合分析本体: [`market-competitive-analysis.md`](market-competitive-analysis.md)
4. 判断記録: [`notes/decision-log.md`](notes/decision-log.md)
5. 比較対象のプロジェクト: [`../research/`](../research/)
6. 学術的競合分析(別モジュール・別ブランチ): `../competitive-landscape/`
7. 改訂対象の論文(別ブランチ): `../small-data-ml-paper/`, `../active-learning-paper/`

## このモジュールの位置づけ

`microneedle-drug-delivery/research/` で進めているsmall-data MLアプローチについて、**実在する商用・市場競合**(マイクロニードル製品メーカー、AI/ML活用を謳う企業、化粧品成分デリバリーの受託開発企業)を調査し、現在のシステムとの差分を批判的に分析するモジュール。

`../competitive-landscape/`(ブランチ `microneedle-competitive-gap-analysis`)が既に調査済みの「MLアプローチそのもの」の学術的競合(手法・論文レベル)とは異なる角度の分析であり、内容は重複しない。

この分析結果は、後続タスクで `../small-data-ml-paper/` と `../active-learning-paper/` の両論文を批判的に改訂するための根拠として使われる(改訂そのものは別作業ツリーで実施)。

## 今回の成果物

- [`market-competitive-analysis.md`](market-competitive-analysis.md): 企業/製品マップ、AI/ML claim監査、ODM・予測サービス、商用検証との対比、ギャップ、両論文への具体的な改訂提案、未解決事項、取得URL一覧。
- [`notes/decision-log.md`](notes/decision-log.md): 使用したWeb取得手段、取得成功/失敗、主張の確信度判定、重複回避、受入条件の自己採点。
- このREADME: スコープ、読み始める順番、ファイル構成、パイプライン境界。

本文の証拠区分は、(a) 査読論文・規制DB・試験登録、(b) 公式発表/企業ページ、(c) 二次情報源・推測です。今回の実質的な企業・AI/MLの主張には(a)または(b)のみを使用し、(c)を根拠にした結論は採用していません。

## 実行方法の経緯(重要)

当初はClaude Codeの`/deep-research`ハーネスでこの調査を行う予定だったが、実行時にClaudeアカウントのセッション利用上限に達し、0件の一次資料取得で失敗した。ユーザーの指示により、この調査タスクはCodex CLI(`gpt-5.6-terra` → `gpt-5.6-sol`、OpenAIアカウントの別クォータ)に委譲されている。詳細は[`notes/decision-log.md`](notes/decision-log.md)を参照。

## 執筆パイプライン

1. Claude Sonnet 5 — `requirements.md`・`implementation-prompt.md`を起草(deep-research失敗を受けてCodex実行前提の内容に設計)
2. Codex `gpt-5.6-terra`(reasoning effort: max) — 実際にWeb調査を行い、`market-competitive-analysis.md`を起草
3. Codex `gpt-5.6-sol`(reasoning effort: ultra) — 主要な主張を独立に再検証し、仕上げる
4. Claude Sonnet 5 — 最終レビュー・PR作成

## フォルダ構成

```text
market-competitive-analysis/
├── README.md
├── requirements.md
├── implementation-prompt.md
├── market-competitive-analysis.md   # 商用・市場競合分析本体
└── notes/
    └── decision-log.md              # 調査・レビューの経緯と主要判断
```

## 利用上の境界

- `../competitive-landscape/`、`../small-data-ml-paper/`、`../active-learning-paper/`(いずれも別ブランチ・別PR)のファイルは編集しない。参照は`git show <branch>:<path>`のみ。
- confidenceの低い主張・確認できなかった主張を確認済みの事実として書かない。
- 実在しない企業名・製品名・URL・DOI・特許番号を作らない。
- 企業サイト上の数値的な吸収・効果・特許の表現は、独立した試験/特許本文を取得できた場合を除き、企業自身のclaimとしてのみ扱う。
