[HTML版を開く](decision-log.html)

# 判断記録 — small-data-ml-paper

## 2026-07-20: 論文の性格をPerspective/proposalに限定

**決定**: `research/` の RESEARCH_PLAN.md はフェーズ2〜6(データキュレーション、モデル構築、
transfer learning、SHAP解析、美容成分への適用)が未着手のまま止まっている。この状態で
「論文を書く」ためには、(a) フェーズ2〜6を実際に実行してから結果を報告する、
(b) 新規計算を行わずPerspective/proposalとして書く、の2択があった。
ユーザーは (b) を明示的に選択した。

**理由**: 実行していない計算の結果を書くと科学的誠実性(データ捏造)に関わる重大な問題になる。
(b) であれば、既に実在する文献マップ・データセット・記述子コードという「本物の」土台の上に、
誠実に「ここまで完了・ここからは計画」と区別した文書を作れる。

**影響**: `requirements.md` §3 に捏造防止の制約を明文化し、`implementation-prompt.md` の
実行順・停止条件にも同じ制約を繰り返し埋め込んだ。後続のfable-5・codexステージが
この区別を破らないよう、各ステージの成果物を都度この観点でレビューする。

## 2026-07-20: パイプライン構成

**決定**: Sonnet 5(要件定義・指示文起草)→ Fable 5(レビュー・改善)→
Codex gpt-5.6-terra(reasoning effort: max、本文の下書き)→
Codex gpt-5.6-sol(reasoning effort: ultra、仕上げ・検証)の4段構成で実行する。

**理由**: ユーザーの明示的な指定(過去のcorneal-geometry-qcモジュールと同じパターン)。
複数モデルによる独立レビューを重視し、1モデルが自分の成果を自己採点する状態を避ける。

**既知のリスク**: `gpt-5.6-sol` の `ultra` reasoning effortは、長時間の headless
`codex exec` 実行中に停止する既知の不具合がある(内部でmulti-agent委任が走り、
`codex exec resume` では復帰できない)。停止した場合は同じコマンドで再実行を1回試み、
それでも失敗する場合はこのセッション(Claude Sonnet 5)が直接仕上げ、
ユーザーにその旨を明示する。

## (このセクションは各ステージ完了時に追記される)
