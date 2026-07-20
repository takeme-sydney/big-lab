[HTML版を開く](analysis-plan.html)

# Analysis plan — Curved Corneal Construct Geometry QC

Status: draft / frozen / amended
Linked charter version:
Analyst:
Independent reviewer:

## 1. Endpoint classification

Select one primary endpoint family:

- [ ] Radius deviation: best-fit radius − design/nominal radius
- [ ] Wall-thickness variation: local thickness distribution vs design target
- [ ] Surface roughness: surface RMSE between measured mesh and design mesh
- [ ] Topographic chordal error: layer-wise faceting deviation from the intended smooth curve
- [ ] Volume change / shrinkage rate: measured volume vs design/as-printed volume
- [ ] Interlayer misalignment: offset between adjacent printed layers

## 2. Registration and calibration

すべての実測メトリクスは、次の順で確立してから計算する。

1. Calibration: pixel/voxel spacingを既知reference（calibration target、CT/OCTのvoxel size等）から確定する。calibrationのないデータは`not measurable`と記録する。
2. Registration: 実測mesh（photogrammetry / structured-light / OCT由来）をdesign / nominal meshへ位置合わせする（例: ICP、rigid + scale補正の要否を明記）。
3. Registration RMSEを記録する。これはgeometry errorではなくfit品質の診断指標である。RMSEが事前登録した上限を超えるsampleは、geometry error値を確定値ではなくreview対象として扱う。

```text
radius_deviation = best_fit_radius − design_radius
wall_thickness_variation = local_thickness(x) − design_thickness(x)
surface_rmse = RMS( measured_surface − design_surface ), over registered region
chordal_error = max deviation of discretised print path from intended smooth curve
volume_change = ( measured_volume − design_volume ) / design_volume
shrinkage_rate = ( as_printed_dimension − post_process_dimension ) / as_printed_dimension
```

派生指標を算出する場合は、単位・基準面・正負の符号規約を明記する。

## 3. Data quality

- Raw scan / image / OCTデータを変更しない。
- Segmentation失敗、透明試料での取得困難、calibration欠落は`qc_status`と`exclusion_reason`で記録し、削除しない。
- Re-scanの理由を保持する。
- Unit変換はscript化し、testする。
- Registration非収束（RMSE上限超過）は自動除外せずflagする。

## 4. Descriptive analysis

- 全constructのoverlay（design vs measured）を可視化する。
- batch / print run / fabrication strategy別の要約を、個々のconstructを隠さずに重ねる。
- print run、batch、construct各水準の`n`を報告する。
- 実際のcalibration値、registration RMSE、除外率、protocol deviationを要約する。

## 5. Print-process要因との比較

| 要因 | 想定される影響 | 使用/注意 |
| --- | --- | --- |
| Fabrication strategy（mould-assisted / direct） | 曲率保持能力、overhang制限との関係 | 交絡因子（材料・layer厚と同時変更しない） |
| Layer thickness | chordal error、surface roughness | 増加でchordal error増大が予想される（Yuan et al. 2026 §3.1） |
| Slice angle / overhang角度 | direct printingでの構造安定性 | 45°制限（Yuan et al. 2026 Figure 5e）との関係を記録 |
| Support構造の有無・除去 | 局所的な表面欠陥・寸法変化 | 除去手順・post-processingを記録 |
| Material / bioink batch | shrinkage rate、volume change | batchをgroup化因子として扱う |

比較の単位はconstructとし、batchを階層効果として扱わない単純比較は避ける。

## 6. Group comparison

- Primary contrast:
- Estimand:
- Model:
- Fixed effects:
- Random effects（batch、print run）:
- Covariates:
- Multiple-comparison control:
- Confidence / compatibility interval:
- Missing-data strategy（segmentation失敗等による欠損）:

Batchを繰り返し測定・階層構造として扱う。全constructを独立sampleとみなす検定は使わない。

## 7. Small-sample統計 / MLを使う場合

Mechanistic / geometric baseline（design−measured偏差の直接評価）を固定した後にのみ使用する。

- Group key for split（batchまたはprint run）:
- Nested cross-validation:
- Leave-one-batch-out test:
- External prospective set（Gate 6）:
- Uncertainty method:
- Applicability-domain rule:
- Leakage checks:
- Frozen preprocessing pipeline:

Minimum baselines: 設計値との単純差分、fabrication strategy別の記述統計、（該当する場合のみ）回帰モデル。

## 8. Figures

1. Construct-level design-vs-measured overlay（3D or断面）
2. Metric別（radius / thickness / surface / chordal / volume / shrinkage / interlayer）のbatch比較
3. Registration RMSE分布とflag基準
4. Print-process要因 vs geometry errorの散布図
5. Failure registry（segmentation失敗、calibration欠落、外れ値を含む）
6. Synthetic demoとreal pilotの構造監査比較（両者を明確にラベル分けする）

各captionにendpoint、単位、experimental `n`、summary statistic、interval、除外件数、実測かsyntheticかを明記する。

## 9. Claims

### Supported if criteria pass

-

### Not supported by this design

- Young's modulus、transparency、refractive index/power、corneal permeabilityの性能（Gate 7以前）
- 生物学的機能・臨床適合性
- 経験的なfit（例: 単一のR²）のみに基づくfabrication mechanismの断定
- 12構造体規模のpilotからの、印刷手法・材料一般への性能保証
