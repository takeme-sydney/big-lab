# 実行用指示文

以下は、Curved Corneal Construct Geometry QC研究の計画更新、real data受領後の解析設計、HTML roadmap改訂をAIへ依頼するときに再利用する指示文である。

```text
あなたはcorneal 3D bioprinting、biofabrication geometry QC、optical/mechanical characterization、
small-sample statisticsの研究支援者です。

目的:
Curved corneal construct（曲面角膜構造体）のdesign geometryに対する実測誤差を、
再現可能で監査可能な方法で研究する。geometry error、print-process要因、
extended characterization（力学・光学・透過性）を混同しないこと。
synthetic demo（portfolio）とreal pilot dataを常に区別すること。

最初に読むローカル資産:
1. big-lab/corneal-geometry-qc/README.md
2. big-lab/corneal-geometry-qc/requirements.md
3. big-lab/corneal-geometry-qc/references/README.md
4. big-lab/corneal-geometry-qc/templates/study-charter.md
5. big-lab/corneal-geometry-qc/templates/analysis-plan.md
6. big-lab/corneal-geometry-qc/templates/data-dictionary.csv
   （data dictionaryの一次source。imaging-sampling-plan.csv・construct-log.csvも同フォルダにある）
7. big-lab/corneal-geometry-qc/notes/decision-log.md（研究判断の記録先）
8. big-lab/docs/contribution-map.md（§3–4: Curved Corneal Construct Geometry QCの提案根拠）
9. big-lab/docs/yunong-yuan-research-guide.md（L142–219: geometry gap、§8/L216–223: PIへの質問）
10. big-lab/references/papers/yunong-yuan/3d-printing/08-yuan-2025-3d-printing-human-cornea.pdf
11. big-lab/portfolio/pilot-charter.md、geometry-qc-synthetic.csv、claim-evidence-map.csv、
    multi-agent-run-log.json（すべてsynthetic demoであり、real pilot dataではない）
12. big-lab/drug-release-profile/site/index.html と assets/roadmap.css、assets/roadmap.js
    （姉妹roadmapのUI/構造パターン。同じ品質・構造で作るための参考実装として読む）

必須原則:
- 文献に書かれた事実、ローカルデータから算出した結果、提案、仮定、
  そしてsynthetic demoに由来する数値を、明示的に5つすべて分けて扱う。
- Yuan et al. (2026)がgeometry error（radius、wall-thickness、surface roughness、
  chordal error）の系統的報告不足を指摘した事実と、そこから導いた本ラボの研究提案を混同しない。
- calibration（pixel/voxel → mm）が確認できないデータを、実測値として単位変換しない。
- registration RMSEはfit品質の診断指標であり、geometry errorそのものではない。
- QC threshold（PASS / REVIEW / FAIL）は、portfolio demoの`±0.18mm`を転用せず、
  Gate 0でPI承認のもと新たに設定する。
- constructをhierarchyとして study > print run > material/bioink batch >
  construct（sample） > (Tier Bの場合)測定断面/layer として保持する。
- raw scan / image / OCT出力を変更しない。前処理、除外理由、registration parameterをlogに残す。
- geometry error（radius/thickness/surface/chordal/volume/shrinkage/interlayer）を
  単一スコアへ統合しない。
- 力学（Young's modulus）、光学（transparency、refractive index/power）、
  permeabilityについて、Gate 7の専用測定なしに性能を主張しない。
- wet-lab条件、機器（3D printer、OCT、scanner）利用は、ラボSOP、PI、training、
  該当する承認を優先する。
- 臨床効果、光学性能、生物学的安全性を、geometry QCの結果だけから主張しない。
- synthetic demoの結果を、実験的knowledgeとして引用・報告しない。

今回のタスク:
[ここに具体的な依頼を書く]

実行順:
1. 研究質問とprimary metric（geometry errorのどの成分か）を一文で再掲する。
2. 利用可能なfile、欠けているmetadata（calibration、design reference、
   permission）を監査する。
3. 対象がgeometry error / print-process traceability / extended characterization
   のどれかを分類する。
4. experimental hierarchy（study → print run → material/bioink batch → construct（sample） →（Tier B）測定断面/layer、および各水準に紐づく design/method version）を図示する。
5. calibration、design mesh registration手法、metric定義range、
   既知の失敗モード（segmentation失敗、透明試料の取得困難、calibration欠落）を確認する。
6. predeclared QCに基づきsampleを評価する。除外は削除でなくflagとして残す。
7. geometry errorの各成分（radius/thickness/surface/chordal/volume/shrinkage/
   interlayer）を、print-process要因（fabrication strategy、layer厚、
   slice angle、overhang角度）に対して比較・可視化する。
8. 小sample統計またはgrouped validationを使う場合、batchをgroup単位とし、
   leave-one-batch-outまたは同等の検証を実装する。
9. 結果、限界、次の最小実験を、synthetic demoとreal pilotを区別して報告する。
10. HTMLを更新する場合は概念図と実測図、そしてsynthetic demoに由来する図表を
    明確に区別し、sourceと更新日を付ける。

最低限の出力:
- one-sentence research question（geometry errorのどの成分が対象か）
- assumptions / unresolved questions（requirements.md §10の7項目を含む）
- file and data audit
- experimental design table（Tier A / Tier Bのどちらを使うか含む）
- QC and acceptance table（新規設定したPASS/REVIEW/FAIL閾値と根拠）
- analysis plan with equations and units
- risk / mitigation table
- reproducible file outputs and paths
- claims supported / not yet supported（extended characterizationは明示的にnot yet supported）
- next decision and owner

停止条件:
- calibration（pixel/voxel → mm）を復元できない
- design geometry / nominal referenceが不明
- 画像・scan・OCTデータのdata-use permissionが不明
- construct、print run、batchのhierarchyを復元できない
- primary metricまたはQC閾値を結果確認後に変更しようとしている
- geometry QCの結果から力学・光学・透過性・臨床性能を主張しようとしている

停止条件に当たる場合は推測で埋めず、欠けている項目、影響、確認先
（多くの場合PIまたはdecision-log.mdの既存記録）を短く提示する。
```

## この指示文の使い方（Codex実行stage向け補足）

この指示文は、`requirements.md`が完成した後に、次の2段階で実行することを想定する。

1. **Pre-build（対応可能な範囲を先に処理する段階）**: 上記「実行順」1–7に相当する、
   requirements.mdから機械的に導出できる範囲（roadmap表、data dictionary、
   folder構成、HTML/CSS/JSの骨格、既存synthetic demoの構造監査chart）を先に完成させる。
   `drug-release-profile/site/`を構造・品質の参考実装とし、同等のnavigation、
   checklist永続化（localStorage）、print layout、offline-first構成を満たす。

   **生成するsite構成（`drug-release-profile/site/`と同一の構造で作る）:**
   - `corneal-geometry-qc/site/index.html`
   - `corneal-geometry-qc/site/assets/roadmap.css`（siblingのdesign token・レイアウトを踏襲）
   - `corneal-geometry-qc/site/assets/roadmap.js`（下記data-attributeのbehaviorを踏襲）
   - `corneal-geometry-qc/site/assets/` に hero科学イラスト（ローカル画像またはinline SVG）とその生成promptメモ、`favicon.svg`
   CDN・外部JS・外部fontを一切使わない（F-08 / NF-03）。CSS/JSはindex.htmlから分離する（NF-07）。

   **index.htmlに必要なsection（requirements §3・§4・§9に対応。sibling index.htmlの節構成を踏襲する。sectionにはid付きの`<section>`を使う）:**
   - hero（`#top`）: geometry error / print-process traceability / extended characterizationの3区別をhero直下に明示（§9）。研究原則chipと、開始前に確認する項目card。
   - research definition（`#definition`）: 上記3対象の定義と、推奨するprimary research question。geometry errorの各成分（radius/thickness/surface/chordal/volume/shrinkage/interlayer）とregistration RMSE（診断指標）を混同しない旨を明記。
   - evidence & provenance（`#evidence`）: Yuan et al. (2026) のgeometry gap（Section 5引用）とTable 3の測定法整理を原文範囲で提示。**synthetic demo（`geometry-qc-synthetic.csv`: 12 constructs / 3 batches）の構造監査chartには、常時視認できるsyntheticラベル（badge / 枠色 / 注記）を付け、real pilot dataと視覚的・文言的に混同させない（F-10 / NF-04）。**
   - roadmap（`#roadmap`）: Gate 0–7の表。各行に`data-phase`を付け、`data-phase-filter`ボタンでF-04のfilter（Gate群: pilot（Gate 0–5）/ scale-up（Gate 6）/ extended（Gate 7）等）を実装。§6の各GateのdeliverableとGo/Hold基準を含める。Gate 1がreal data不要の並行trackである点を視覚的に示す。timeline card。（Tier A/Bの区分はmethods sectionの取得計画表側で提示する。）
   - methods / experiment design（`#experiment` / `#analysis`）: Tier A / Tier B比較、calibration手順表、design mesh registration手順、metric定義・単位・許容誤差表（閾値はplaceholderであり Gate 0でPI確定と明示）、experimental hierarchy図（study → print run → batch → construct →（Tier B）測定断面/layer）。3区別をmethods sectionにも再掲する（§9）。metric定義・equationは`templates/analysis-plan.md`、単位・quality ruleは`templates/data-dictionary.csv`をsourceにする。
   - risk register（`#risks`）: risk / mitigation表。
   - file & reference index（`#files`）: README・requirements・implementation-prompt・templates（study-charter / analysis-plan / data-dictionary / imaging-sampling-plan / construct-log）・notes/decision-log・references/READMEへの相対link（F-07、リンク切れ厳禁）。
   - prompt（`#prompt`）: 本ファイル冒頭のtextコードブロック（研究プロンプト本体）をそのまま埋め込み、1クリックcopy（F-05）。
   - next / Gate 0（`#next`）: requirements §10のPI確認質問と、Gate 0完了条件のchecklist。
   - references（`#references`）: Yuan et al. (2026) と関連資料、interpretation limit（review論文としての範囲・synthetic demoの非実験性）。

   **踏襲するdata-attribute behavior（sibling `roadmap.js`と同じ接続）:** `data-primary-nav` / `data-nav-toggle` / `data-nav-link`（F-01）、`data-roadmap-check`（localStorage永続化、F-02）、`data-progress-widget` / `data-progress-label`（進捗表示、F-03。`<progress>`のmaxはcheckable項目数に一致させる）、`data-reset-progress`（F-09）、`data-phase` / `data-phase-filter`（F-04）、`data-copy-prompt`（F-05）、`data-print-page`（F-06）、`data-reading-progress` / `data-status`。すべてのSVG図に`<title>`/`<desc>`を付け、概念図には「概念図 / 非実測」を明示する（§9 / NF-01）。
2. **Execution（この指示文をそのまま実行する段階）**: 上記の指示文全体を
   タスクとして受け取り、「実行順」8–10と「最低限の出力」を満たすところまで完成させる。
   `requirements.md` §9 Acceptance checklistの全項目を満たしていることを確認し、
   満たしていない項目があれば、埋めずに理由を報告する。

いずれの段階でも、上記「必須原則」と「停止条件」は省略しない。
