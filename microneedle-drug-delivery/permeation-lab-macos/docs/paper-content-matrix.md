[HTML版を開く](paper-content-matrix.html)

# Yuan et al. (2023) 論文内容カバレッジ表

この文書は、アプリが原著と補足資料の何をどこに収録するかを示すtraceability matrixである。`Required` は省略不可、`Source note` は原著内の差をそのまま示す項目である。

## 1. Article metadata and front matter

| Source content | Required app destination | Coverage rule |
| --- | --- | --- |
| received / revised / accepted dates | Overview / Full Paper | 3 datesを保持 |
| DOI、article type、title | Overview | 原著表記 |
| authors 7名、affiliations 6件 | Full Paper | 全件 |
| corresponding authors | Full Paper | affiliation、emailを含む |
| funding | Overview / Full Paper | CSC No. 202008320366、USYD PCA2019 |
| abstract | Overview / Full Paper | 全文 |
| keywords | Overview | 6語 |
| CC BY notice | Full Paper / Integrity | attributionを保持 |

## 2. Main article sections

| Section | Required content | Related items |
| --- | --- | --- |
| 1 Introduction | skin barrier、MN、in vitro permeation cost/time、simulation/ML rationale、study aim | References 1–28 |
| 2.1 Data collection | 6 permeants、hydrogel/plastic provenance、Franz experiments、Data S1 | Figure 3、Data S1 |
| 2.2 Overview | 4 methods、2 outcomes、descriptors、train/test concept | Figure 1 |
| 2.3 Fick | 2D finite-difference model、boundary elements、normalization、5 assumptions | Eq 1–2、Table 1、Figures 4–5、Data S2 C |
| 2.4 MLR | simple/multiple linear form | Eq 3–4、Data S2 R |
| 2.5 RF | independent trees、regression mean、importance | Figure 1c、Table 3、Figure 8 |
| 2.6 XGBoost | sequential trees、loss + complexity | Eq 5–6、Table 3、Figure 8 |
| 2.7 Evaluation | RMSE、R²、direction of better performance | Eq 7–8 |
| 2.8 Process | manual cleaning、191 points、7:3 random split、software versions | Figure 2、Data S2 |
| 3.1 Data | drug composition、small dataset limitation | Figure 3、Data S1 |
| 3.2 Fick results | concentration evolution、plateau、hydrogel/plastic approximation、parameter effects | Table 1、Figures 4–5 |
| 3.3 ML results | 7 features、MN geometries、surface area | Eq 9–11、番号なし計算例、Tables 2–3 |
| 3.4 Comparison | reported RMSE/R²、drug/skin panels、small-subset deviations | Table 4、Figures 6–7 |
| 3.5 Importance | percentage: area/time、amount: loading/time | Figure 8 |
| 4.1 Mechanistic vs statistical | interpretability、diffusion coefficient dependence、ML advantage | Figures 4–5 |
| 4.2 Model comparison | XGBoost best、XGBoost unseen-drug validationのlarge deviation、loading-range explanation | Table 4、Figures S1–S2 |
| 4.3 Feature comparison | outcome-specific importance、low importance caveat、future larger dataset | Figure 8 |
| 5 Conclusion | XGBoost best、RF second for percentage、Fick second for amount | Table 4 |

## 3. End matter

| Source content | Required coverage |
| --- | --- |
| Author contributions | 7 authors and all roles |
| Acknowledgments | PCA、USYD-CSC support |
| Conflict of interest | authors declare none |
| Peer review | statement as printed |
| Data availability | supplementary availability statement |
| Ethics | prior studies had required approvals |
| ORCID | Lifeng Kang identifier |
| References | entries 1–51, without importing their full texts |
| Supporting information list | Data S1、Data S2、Figure S1、Figure S2 |
| How to cite | full citation |

## 4. Dataset coverage

Data S1 は単一worksheetで、4行目がheader、続く191行がobservations、11列がmodel/data fieldsである。appは全行・全列を収録する。

| Column | Meaning in source | App handling |
| --- | --- | --- |
| Drug name | 6 permeants | text/filter |
| Drug loading in MN patch (µg) | 50–70,940 | original numeric value |
| Drug MW (Dalton) | molecular weight | original numeric value |
| MN Length (mm) | needle length | original numeric value |
| Skin type | rat=1、human=2 | code + source label |
| MN type | hydrogel=1、plastic=2 | code + source label |
| MN surface area (mm2) | total patch area | original numeric value |
| Permeation time (hour) | 0.083333333–48 | original numeric value |
| Drug permeation percentage | cumulative percentage | original numeric value |
| Drug permeation amounts (µg/cm2) | cumulative amount column as titled | preserve source unit string |
| References | source-study citation, blanks included | no forward-fill in raw view |

| Drug | Data S1 count | Article prose / Figure 3 note |
| --- | ---: | --- |
| lidocaine | 73 | prose states 73 and 38% |
| BSA | 33 | prose prints `33%`, while Data S1 count is 33 |
| GHK peptide | 24 | prose prints `24%`, while Data S1 count is 24 |
| copper ions | 24 | prose prints `24%`, while Data S1 count is 24 |
| Rhodamine B | 19 | prose describes 10%; Figure 6 discussion says fewer than 20 |
| caffeine | 18 | prose describes 10%; Figure 6 discussion says fewer than 20 |
| total | 191 | article and Data S1 agree |

アプリはData S1 countとarticle proseを別labelで示し、どちらかを無言で置換しない。

## 5. Equation coverage

| Eq | Expression / subject | Required context |
| ---: | --- | --- |
| 1 | `∂C/∂t = D(∂²C/∂x² + ∂²C/∂y²)` | 2D Fick's second law、C/t/D definition |
| 2 | `permeation percentage = (m_t / m_total) × 100%` | cumulative amount and loaded total |
| 3 | `y = kx + b` | simple regression |
| 4 | `y = k₁x₁ + … + kₙxₙ + b` | MLR |
| 5 | `Obj = Σl(yᵢ, ŷᵢ) + ΣΩ(fₖ)` | XGBoost loss + complexity |
| 6 | `Ω(fₖ) = γT + 1/2 λΣwⱼ²` | γ、T、w、λ definitions |
| 7 | `RMSE = sqrt[(1/n)Σ(yᵢ−ŷᵢ)²]` | lower is better |
| 8 | `R² = 1 − Σ(ŷᵢ−yᵢ)² / Σ(ȳᵢ−yᵢ)²` | render notation as printed; closer to 1 is better |
| 9 | `S = πr² + π(Rl + rl)` | hydrogel frustum surface area |
| 10 | `S = 4·1/2·a·sqrt((a/2)² + h²)` | square-pyramid plastic MN area |
| 11 | `S_total = S·n` | patch total surface area |

式 (11) 後の番号なし計算例も、架空の式番号を付けずに保持する。

- `a=0.075 mm`、`h=0.7 mm` から `S=0.105 mm²`
- `n=351` から `S_total=36.855 mm²`

## 6. Table coverage

### Table 1 — Fick parameters

| Parameter | Paper value |
| --- | --- |
| D | 50–1000 µm²/min |
| N | 64、351 |
| L | 700、820、876、889、999、1250、1063 µm |
| t | 15 min–48 h |
| m | 50–70,940 µg |
| dx、dy | 2 × 2 |
| dt | 0.00001–0.001 min |

### Table 2 — ML parameters

| Feature / outcome | Paper value |
| --- | --- |
| skin type | rat、human |
| MN type | hydrogel、solid |
| MN length | 700、820、889、1250、875.97、998.62、1062.97 µm |
| MN surface area | 26.76、28.54、29.97、32.13、32.43、34.49、36.86 mm² |
| loading | 50–70,940 µg |
| time | 0.08333–48 h |
| MW | 64、194、234、340、479、66,430 Da |
| amount outcome | 0–30,000 µg |

### Table 3 — Hyperparameters

| Outcome | XGBoost | RF |
| --- | --- | --- |
| amount | max depth 4、eta 0.4、Nround 100 | trees 500、mtry 5 |
| percentage | max depth 3、eta 0.2、Nround 45 | trees 500、mtry 6 |

### Table 4 — Reported performance

| Outcome / metric | XGBoost | RF | Fick | MLR |
| --- | ---: | ---: | ---: | ---: |
| amount RMSE (µg) | 4,447.23 | 7,043.97 | 6,778.17 | 23,398.91 |
| amount R² | 0.98 | 0.95 | 0.95 | 0.46 |
| percentage RMSE (%) | 28.24 | 34.33 | 85.58 | 120.33 |
| percentage R² | 0.98 | 0.97 | 0.82 | 0.65 |

## 7. Figure coverage

| Figure | Required content |
| --- | --- |
| 1 | four method schematics: Fick、MLR、RF、XGBoost |
| 2 | cleaning、7:3 split、training/prediction flow |
| 3 | drug distribution and molecular structures |
| 4 | Fick curve + concentration maps at 15 min、1、3、6、24 h |
| 5 | effects of D、MN number、MN length、loading |
| 6 | amount predictions vs experiments for 9 drug/skin panels |
| 7 | percentage predictions vs experiments for the same 9 panels |
| 8 | RF/XGBoost feature importance for amount and percentage |
| S1 | XGBoost unseen-drug amount prediction, 9 panels |
| S2 | XGBoost unseen-drug percentage prediction, 9 panels |

## 8. Supporting code coverage

### Data S2 R section

- `xgboost`、`Matrix`、`randomForest`
- `set.seed(0)`
- reads `train set.csv` and `test set.csv`
- MLR with `Results ~ . - 1`
- RF with 500 trees and mtry 6
- XGBoost with depth 3、eta 0.2、square-error objective、45 rounds
- importance plots and CSV outputs

### Data S2 C section

- finite-difference implementation of the 2D Fick model
- example declarations including `D=700`、`N=64`、`m=1637`、`dx=dy=2`、`dt=0.0001`
- separate update cases for corners、edges、interior
- receptor accumulation and time-series output

## 9. Reproducibility gap matrix

| Item | Present? | App statement |
| --- | --- | --- |
| Data S1 | yes | complete 191×11 source dataset |
| 7:3 ratio | yes, paper text | reported split ratio |
| train/test row assignment | no | not provided |
| split-generation code | no | not provided |
| `set.seed(0)` | yes, before existing CSV reads | split-generation code itself is absent, so it does not reconstruct the split |
| MLR formula code | yes | source code viewable |
| final MLR coefficients | no | not provided |
| RF training call | yes | source code viewable |
| trained RF forest | no | not provided |
| XGBoost training call | yes | source code viewable |
| trained booster | no | not provided |
| Fick example C code | yes | source code viewable |
| full condition-specific Fick artifacts | no | not provided |
| Table 4 metrics | yes | reported, not recomputed |

## 10. Integrity manifest baseline

| Source | Bytes | SHA-256 |
| --- | ---: | --- |
| original PDF | 3,800,340 | `4641e97362f3cc545586879f2da3735e5487a50fe3cc6149076c87151e47c820` |
| Data S1 XLSX | 25,802 | `a22cc32b4d461b1e65c2b29623186a0d0c1f984fc1935d8bd3b35ec0bc3c3a24` |
| Data S2 DOCX | 23,283 | `9d6fe3da0127ba26469b7a1fe61a98f723a5547d8a666c92670bf30f31820c81` |
| SI3 DOCX | 196,389 | `49f953203a33dd6c781e2761011c8124a6bac891e07ceedf61de6c1289626031` |
| Data S1 CSV | 14,819 | `03ff02276f333d06747efb7a625e9de1b4055b94b8736873f5e7cc389315b0f5` |

hashはこのrepository内のtracked一次資料に対するbaselineである。source更新時は、新旧hashと更新理由を監査報告へ記録する。
