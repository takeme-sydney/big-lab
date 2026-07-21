[HTML版を開く](decision-log.html)

# 判断記録 — transfer-learning-paper

## 2026-07-21: モジュールの新設と経緯

**背景**: `research/RESEARCH_PLAN.md`はフェーズ0・1・1.5のみ完了で、フェーズ2〜6(データキュレーション、EDA、2系統のモデル構築、転移学習、物理モデル併用データ拡張、SHAP解析、美容成分応用、最終論文)が未着手だった。ユーザーの指示により、この未着手フェーズを実際に計算・実行するモジュールとして本ブランチ`microneedle-transfer-learning-paper`を`main`(`6401e82`)から新規に切った。

**作業ツリーの分離**: 通常はメインの作業ディレクトリでブランチを切り替えるところ、`main`チェックアウトへの切り替え中に別のブランチ(`microneedle-active-learning-paper`)に、コミットされていない大規模な変更(`research/`のdata/raw・data/processed・data/results・figures・reports・src サブフォルダへの再編成、タイムスタンプから判断して直近約44分以内)が見つかった。同時刻に同一マシン上で5つの独立したClaude Codeプロセスが稼働していることを確認し、いずれかのセッションがこのブランチで並行作業中である可能性が高いと判断した。メインチェックアウトの状態を一切変更せず、`git worktree`で本ブランチ・並行して`microneedle-market-competitive-analysis`ブランチを`main`から独立に作成した(メインチェックアウトを乱さないための established best practice — [[multi-model-research-pipeline-preference]] 参照)。

**既存2モジュール(`active-learning-paper`, `small-data-ml-paper`)との性格の違い**: 両モジュールは「既存の(または存在しない)結果を書き上げる」執筆タスクだったが、本モジュールは「新しい計算を実際に実行する」計算タスクである。そのため`requirements.md`の科学的完全性プロトコルは、既存モジュールの「数値allowlist」(既存CSVへの追跡)から、「新規生成CSVへの追跡+疑似データの明示フラグ+マイクロニードル実験パラメータの捏造禁止」という、新規計算タスク向けのプロトコルに設計を変更した。

**発見した重要な設計上の論点(要件定義に反映済み)**:
1. `RESEARCH_PLAN.md`が言及する「SkinPiXのnotes列のsuspicious pointフラグ」は、実際の`skin_permeability_training_set.csv`には存在しない(列を直接確認した)。統計的外れ値検出への代替を要件定義に明記した。
2. 美容成分48件のデータセット(`cosmetic_ingredients_descriptors.csv`)には、マイクロニードル実験パラメータ(薬剤負荷量・MN長・MN表面積・透過時間)が存在しない。これらを仮定して4Bモデル(Yuanのマイクロニードル特化モデル)に通すことは、実施していない実験を実施したかのように書く捏造リスクがあるため、要件定義§3・§4 Phase5で明示的に禁止し、48成分の応用は4Aモデル(一般皮膚透過性QSAR)による予測にとどめるよう規定した。
3. 転移学習の対象は、Yuanデータセット中RDKit記述子を持つ4小分子薬剤(lidocaine, GHK peptide, Rhodamine B, caffeine)に限定し、BSA・copper ions(記述子が構造的に適用不可)は元の7特徴量モデルにのみ含める設計とした。この非対称な扱いを隠さず本文に明記するよう要件定義に明記した。
4. 物理モデル併用データ拡張(Fick則/Potts-Guy式)で生成する疑似データ点は、実測データと明確に区別するフラグ付与を必須要件とした(このワークスペースの「synthetic vs real」区別に関する既存の厳格な方針に整合)。

## (以降、各ステージ完了時に追記される)
