[HTML版を開く](README.html)

# Microneedle ML 商用・市場競合分析

更新日: 2026-07-21
状態: 要件定義・指示文作成済み / Codex実行前

## Start here

1. 要件定義: [`requirements.md`](requirements.md)
2. 実行用指示文: [`implementation-prompt.md`](implementation-prompt.md)
3. 商用・市場競合分析本体: [`market-competitive-analysis.md`](market-competitive-analysis.md)(作成予定)
4. 判断記録: [`notes/decision-log.md`](notes/decision-log.md)
5. 比較対象のプロジェクト: [`../research/`](../research/)
6. 学術的競合分析(別モジュール・別ブランチ): `../competitive-landscape/`
7. 改訂対象の論文(別ブランチ): `../small-data-ml-paper/`, `../active-learning-paper/`

## このモジュールの位置づけ

`microneedle-drug-delivery/research/` で進めているsmall-data MLアプローチについて、**実在する商用・市場競合**(マイクロニードル製品メーカー、AI/ML活用を謳う企業、化粧品成分デリバリーの受託開発企業)を調査し、現在のシステムとの差分を批判的に分析するモジュール。

`../competitive-landscape/`(ブランチ `microneedle-competitive-gap-analysis`)が既に調査済みの「MLアプローチそのもの」の学術的競合(手法・論文レベル)とは異なる角度の分析であり、内容は重複しない。

この分析結果は、後続タスクで `../small-data-ml-paper/` と `../active-learning-paper/` の両論文を批判的に改訂するための根拠として使われる(改訂そのものは別作業ツリーで実施)。

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
├── market-competitive-analysis.md   # 商用・市場競合分析本体(作成予定)
└── notes/
    └── decision-log.md              # 調査・レビューの経緯と主要判断
```

## 利用上の境界

- `../competitive-landscape/`、`../small-data-ml-paper/`、`../active-learning-paper/`(いずれも別ブランチ・別PR)のファイルは編集しない。参照は`git show <branch>:<path>`のみ。
- confidenceの低い主張・確認できなかった主張を確認済みの事実として書かない。
- 実在しない企業名・製品名・URL・DOI・特許番号を作らない。
