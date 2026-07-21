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

## 2026-07-21: Fable-5段階 — Claude Fable 5が利用枠上限のため、Sonnet 5が代行

**発生した事象**: Fable-5への独立レビュー依頼(Agent tool, `model: "fable"`)が、エージェント起動直後に`You've reached your Fable 5 limit. Run /usage-credits to continue or switch models with /model.`エラーで終了した(タスクは一切実行されていない)。同日、同一ワークスペースで実行した`/deep-research`ハーネスもClaudeアカウントのセッション利用上限で失敗しており、関連する可能性がある(複数の並行Claude Codeセッションによるクォータ消費)。過去にも同じworkspaceで同種の代行が行われた前例が複数ある(`microneedle-competitive-gap-analysis`ブランチ、`microneedle-active-learning-paper`ブランチ)。この前例に倣い、Fable-5を待たずSonnet 5がこのレビュー段階を代行する。

**実施した独立検証(一次資料に直接あたって再確認)**:
- `descriptors.py`全文を読み、`potts_guy_baseline(logp, mw)`関数が実在し、`log Kp = -2.7 + 0.71*logP - 0.0061*MW`という具体的な式で実装されていることを確認した(requirements.md Phase 4Aの記述と一致)。
- 同ファイルに`check_applicability_domain(mw, logp, mw_range, logp_range)`関数も存在することを発見した。これはMW・LogP範囲の単純な範囲判定であり、`cosmetic_ingredients_descriptors.csv`の既存`in_MW_domain`/`in_LogP_domain`列を生成した実装である可能性が高い。requirements.mdの起草時点ではこの関数の存在を明示していなかったため、Phase 4Aの記述にこの関数への言及を追加し、レバレッジ法(要求されている、より厳密な手法)が単純範囲判定を置き換えるのではなく補完する位置づけであることを明記した。
- `skin_permeability_training_set.csv`の全15列ヘッダーを再確認し、`notes`列が存在しないことを独立に再確認した(requirements.mdの記述と一致)。
- `cosmetic_ingredients_descriptors.csv`の全29列ヘッダーを再確認し、マイクロニードル実験パラメータ(薬剤負荷量・MN長・MN表面積・透過時間)が一切存在しないことを独立に再確認した(requirements.md §3・Phase5の捏造禁止ルールの前提が正しいことを確認)。
- `drug-release-profile/references/supplementary/07-yuan-2023-code-si2.docx`が実在するファイル(23,283バイト)であることを確認した(中身のFick則実装が実際にCodexのツールで読み取れるかは未確認 — この点はrequirements.mdで既にPotts-Guy式への代替を許容している)。
- `research/requirements.txt`を再確認し、深層学習フレームワーク(torch/tensorflow等)が含まれないことを確認した(古典的ML手法での転移学習を要求するrequirements.mdの設計判断の前提が正しいことを確認)。

**結論**: 上記の再検証で、requirements.md・implementation-prompt.mdの主要な事実主張(データスキーマ、既存関数の存在、依存関係)に誤りは見つからなかった。`check_applicability_domain`関数の見落としを1件補記した。起草段階(Sonnet 5)の監査は概ね妥当であり、下流のCodexパイプラインに引き渡してよい状態と判断する。

## (以降、各ステージ完了時に追記される)
