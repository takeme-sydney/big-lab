[HTML版を開く](pilot-charter.html)

# A-01 / Curved Corneal Construct Geometry QC — Pilot Charter

Status: portfolio demonstration  
Version: 0.3  
Date: 2026-07-17  
Data: synthetic only

## 1. Pilot question

既存の承認済み角膜construct meshから、設計形状に対するbest-fit radius deviationを再現可能に測定し、全sampleのQCと限界を研究者が一枚でレビューできるか。

## 2. Scope

- Duration: 4 weeks
- Construct type: curved corneal construct 1種類
- Dataset: 12 constructs / 3 print batches（portfolioでは合成データ）
- Primary metric: best-fit radius deviation (mm)
- Context metrics: median thickness、surface RMSE、registration RMSE
- Output: tested code、metric table、3D overlay、QC figure、failure registry、review poster

## 3. Demo acceptance rule

以下はUI動作を説明するための仮ルールで、実験・臨床上の閾値ではない。

- PASS: `|radius deviation| ≤ 0.18 mm` かつ他のQC triggerなし
- REVIEW: 軽度のradius / thickness / fit / registration trigger。自動除外しない
- FAIL: demo rangeを超えるfitまたはregistration trigger。自動除外しない

最終state、除外、再測定は研究者がsource meshとoverlayを確認して決定する。

## 4. Four-week plan

### Week 1 — Define

- data permission、sample hierarchy、単位、target、metricを確認
- data dictionaryとmanual referenceを作成
- Gate: metric definitionを研究者が承認

### Week 2 — Build

- loader、校正、registration、metric、testを実装
- すべてのsampleにoverlayとQC flagを保存
- Gate: methodとfailure modeを研究者が確認

### Week 3 — Compare

- radius deviation、batch、surface / registration qualityを可視化
- 失敗例を隠さずfailure registryへ記録
- Gate: QC stateを研究者が割り当て

### Week 4 — Communicate

- figure、caption、claim map、posterを同じvalidated outputから生成
- 固定configで全成果物を再生成
- Gate: claim、limit、authorship、共有範囲を研究者が承認

## 5. Out of scope

- patient data、未承認の未公開データ
- biological efficacy、optical performance、clinical suitabilityの判断
- sample除外の自動確定
- 新しい統計解析計画の無承認実行
- 一つのpilotから一般化した科学的主張

## 6. Success

成功は「完全なアプリ」ではない。同じ入力と固定versionから同じmetric、QC flag、figure、posterを再生成でき、flagged sampleと限界を第三者へ説明できること。
