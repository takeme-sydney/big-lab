[HTML版を開く](decision-log.html)

# 判断記録 — market-competitive-analysis

## 2026-07-21: モジュールの新設と経緯(deep-research失敗によるCodexへの委譲)

**当初計画**: ユーザーの指示に基づき、Claude Codeの`/deep-research`ハーネスで商用・市場競合(マイクロニードル製品企業、AI/ML活用を謳う企業、化粧品成分デリバリー企業)を調査する予定だった。調査範囲は「MLアプローチそのもの」の学術的競合を既に調査済みの`../competitive-landscape/`(ブランチ`microneedle-competitive-gap-analysis`)と明確に区別し、実在する商用主体に焦点を当てるようスコープした。

**発生した事象**: 2026-07-21 12:16頃(Sydney時間)に`/deep-research`ハーネスを実行したところ、5検索角度すべてが `You've hit your session limit · resets 3:50pm (Australia/Sydney)` エラーで失敗した(0件の一次資料取得、109→実質0エージェント成功)。同時刻に同一マシン上で5つの独立したClaude Codeプロセスが稼働していたことを別作業(git worktree調査)で確認しており、複数セッションによる共有クォータの消費が原因と推測される(確定はしていない)。

**ユーザーの指示**: 「codexで続きを代行」。Claudeのセッション制限はOpenAI/Codex CLIのクォータとは独立しているため、この調査タスクをCodex CLI(`gpt-5.6-terra` → `gpt-5.6-sol`)に委譲する。

**対応**: `requirements.md`・`implementation-prompt.md`を、当初のdeep-research前提から、Codexが自前のWeb検索・取得手段(またはbash経由のHTTPアクセス)を用いて実際に一次資料を取得する前提に書き直した。deep-researchハーネス自身が持つadversarial verification(3票制検証)に相当する機能を、Codex-terra(調査・起草)→ Codex-sol(独立再検証)の2段構成で代替する設計とした。

**影響**: 当初計画していた「Sonnet-5がdeep-research結果からrequirements.mdを起草→Fable-5が実行」というパイプラインから、「Sonnet-5がCodex実行前提でrequirements.mdを起草→Codex-terraが調査・起草→Codex-solが独立検証」という構成に変更した。Fable-5によるレビュー段階は、Codex-solの独立検証が実質的に代替する(両方は行わない — 冗長なため)。

## (以降、各ステージ完了時に追記される)
