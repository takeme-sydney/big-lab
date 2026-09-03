# Experiment platform research

Updated: 2026-08-30  
Scope: Yuan et al. (2023), *Prediction of drug permeation through microneedled skin by machine learning*

## Research conclusion

The paper did not use a single packaged “platform.” It combined two execution environments:

- Statistical models: R 4.1.2 in RStudio, with `xgboost` 1.5.0.2, `randomForest` 4.7-1, and `Matrix`.
- Mechanistic model: C in Microsoft Visual Studio 2022, implementing a two-dimensional explicit finite-difference form of Fick's second law.

Data S1 is public and contains 191 observations. Data S2 publishes model code, but that code starts by reading pre-split files named `train set.csv` and `test set.csv`. Those files, their row assignments, preprocessing instructions, fitted models, and per-row predictions were not released. Consequently, no implementation can truthfully reproduce the exact Table 4 numbers from the public record alone.

The macOS feature therefore exposes four explicit evidence states:

1. **Published-protocol reconstruction**: canonical Data S1 with the disclosed row-split protocol and a recorded deterministic replacement split.
2. **Leave-one-drug-out generalization validation**: canonical Data S1 with one drug isolated from training; this is a future-use validation, not the paper's evaluation.
3. **Compatible-dataset experiment**: any run on a schema-compatible follow-up dataset; this is a new experiment, not a reproduction claim.
4. **Exact-paper replay unavailable**: a capability/readiness state shown until an authoritative split manifest or the original train/test files are supplied. It must never be labelled failed or reproduced merely because a reconstruction run completed.

## Published system specification

### Dataset

- 191 observations from previous Franz-type in-vitro permeation studies.
- Six permeants: BSA, copper ions, GHK peptide, rhodamine B, lidocaine, and caffeine.
- Skin: rat (`1`) or human (`2`).
- Microneedle type: hydrogel (`1`) or plastic/solid (`2`).
- Seven predictors:
  - drug loading in the MN patch (µg)
  - molecular weight (Da)
  - MN length (mm in Data S1)
  - skin code
  - MN type code
  - total MN surface area (mm²)
  - permeation time (h)
- Two outcomes:
  - cumulative permeation percentage
  - cumulative permeation amount (µg/cm² in Data S1)

The bundled canonical CSV has raw-byte SHA-256 `03ff02276f333d06747efb7a625e9de1b4055b94b8736873f5e7cc389315b0f5`. Imported data no longer retain authoritative source bytes, so the app separately labels their hash as a normalized parsed-value SHA-256. An imported semantic copy may match canonical values without falsely claiming the bundled file's raw-byte hash. Data S1 has 104 unique predictor combinations; 53 combinations are replicated and 87 rows are duplicates beyond the first occurrence. A row-level split can therefore place matching experimental conditions in both training and test partitions.

Additional Data S1 integrity findings:

- Permeation amount is deterministically derived, within source rounding, as `loading × percentage / 100`; the two targets are not independent measurements.
- One BSA observation reports 108.3982246% permeation. The source value must be retained and warned about, not silently clipped.
- The source uses millimetres for MN length and µg/cm² for amount, whereas narrative tables/metrics use µm and µg in places.
- BSA is 66,000 Da in Data S1/model input but 66,430 Da in Table 2.
- The paper's prose confuses several drug counts with percentages: BSA has 33 rows (17.3%), while GHK and copper have 24 rows each (12.6% each).

### Statistical workflow

- Manual cleaning produced 191 rows.
- Random train/test split: 70% / 30%.
- R seed shown in Data S2: `set.seed(0)`.
- Multiple linear regression: `lm(Results ~ . - 1, data = train)`; no intercept is requested.
- Random Forest:
  - 500 trees
  - `mtry = 5` for permeation amount
  - `mtry = 6` for permeation percentage
  - feature importance enabled
- XGBoost:
  - squared-error regression objective
  - amount: maximum depth 4, eta 0.4, 100 rounds
  - percentage: maximum depth 3, eta 0.2, 45 rounds
- Evaluation: test-set RMSE and R².

Data S2 does not create the split despite calling `set.seed(0)`. It also does not show the column-renaming or transformation that produced the expected `Results` and `Releasing.time` fields. The app must preserve these as unresolved provenance gaps.

The Table 4 values labelled RMSE are incompatible with conventional RMSE and conventional R² over values bounded by Data S1. A plausible explanation is that the table reports `sqrt(SSE)` without division by the test count: if a reconstructed test set has 57 rows, dividing the reported XGBoost values by `sqrt(57)` gives about 589 µg/cm² for amount and 3.74 percentage points, values that can coexist with R² near 0.98. This remains an inference because the metric-calculation code and predictions were not released. The app should show conventional RMSE as the primary metric and a clearly labelled `legacy √SSE` diagnostic, never silently redefine RMSE.

### Fick finite-difference workflow

The C listing models half of a symmetric MN–skin cross-section. It uses a uniform 2D grid, explicit time stepping, reflective side/top boundaries, and a receptor sink along the bottom boundary. It accumulates drug crossing that boundary and multiplies by two for symmetry and by the MN count.

Published ranges are:

- diffusion coefficient: 50–1,000 µm²/min
- MN count: 64 or 351
- MN length: 700–1,250 µm (listed discrete values vary between tables)
- release time: 15 min–48 h
- loaded mass: 50–70,940 µg
- grid: 2 × 2 µm
- time step: 0.00001–0.001 min
- assumed skin thickness: 1,000 µm

Five simplifying assumptions are stated: incompressible/nondegrading MN geometry; uniform initial drug and cell concentration; 2D diffusion; constant diffusivity with negligible temperature effect; instant receptor mixing/no interface blockage; and a common 1 mm skin thickness.

Data S2 exposes one hard-coded example, not a parameter table covering all 191 observations. It uses 50 h even though the paper's stated range ends at 48 h. The example requires roughly 1.9 trillion cell updates at its stated grid, duration, and time step, opens two output files that it never writes, and treats the receptor as a perfect zero-concentration sink. Per-drug diffusivity mapping, all geometry settings, and all held-constant values used for the paper figures are not fully supplied.

The source listing's initial concentration and sink accumulation are not grid-consistent when its 2 µm grid is replaced with a coarser interactive grid. The macOS preview therefore makes a documented numerical adaptation: it normalizes initial mass across the discrete loaded cells, integrates dimensionally consistent sink flux `dt · D · C · dy / dx`, reports `initial − remaining − permeated` mass-balance error, and never clips an output to 100%. This is a stable, mass-consistent method reconstruction, not a literal SI2-output replay and not the undisclosed per-row Fick evaluation behind Table 4.

### Exploratory Fick R² proxy workflow

The My Experiment validation uses a second, deliberately separate model. It is the standard finite planar-slab release solution of Fick's second law, not the paper's two-dimensional MN geometry:

```text
F(x) = 1 - (8/π²) Σ[n=0…79] exp(-(2n+1)²x) / (2n+1)²
prediction(t) = A × F(k × t)
```

`A` is a bounded recoverable-percentage asymptote (`0–100%`). `k` is an effective rate (`1e-8–100 h⁻¹`) that absorbs the diffusivity/length scale and other omitted transport effects. Every outer fold fits both parameters from calibration rows only. The series form is source-supported for a planar matrix under Fickian release, but the fitted effective parameters must not be interpreted as the paper's per-drug diffusivities.

Because Data S1 has no experiment-run or curve identifier, the app constructs an explicitly labelled proxy condition from drug, loading, molecular weight, MN length, skin, MN type, and surface area, excluding time. It holds out each proxy condition in turn within drug/skin/MN families that have at least three such conditions. This reduces exact-condition/time leakage but is not leave-one-run-out: multiple biological/technical replicates at one condition cannot be separated from the public data.

The frozen exploratory Data S1-copy run includes three eligible families, 12 proxy conditions, and 112 observations. Its pooled OOF point estimate is about `R² = 0.895`, but the condition-cluster bootstrap lower bound remains below 0.85 and leave-one-family-out performance is negative. The UI therefore reports a point-estimate pass and confidence/generalization failures side by side. This result lives only in My Experiment and is not compared with or promoted to Table 4.

### Native macOS execution mapping

- MLR uses scaled Householder QR and preserves the published no-intercept formula.
- Random Forest uses 500 seeded bootstrap trees and the target-specific published `mtry`, plus app-specific depth 32 and minimum node size 5. These extra native settings are exported; this engine is not numerically identical to R `randomForest` 4.7-1.
- Native boosting uses the published depth, eta, and round count, but is not XGBoost 1.5.0.2.
- The default replacement split is seeded Fisher–Yates with 134 train / 57 test rows. It is deterministic but is not asserted to be the unpublished R split.
- Conventional RMSE, MAE, optional conventional R², and diagnostic `sqrt(SSE)` are exported with every prediction and split row ID.
- Canonical row-split, canonical leave-one-drug-out, and compatible-dataset runs receive different evidence labels.

## Reproducibility gaps and controls

| Gap | Scientific impact | macOS control |
| --- | --- | --- |
| Original train/test rows unavailable | Exact fitted models and metrics cannot be recovered | Persist and export every generated row assignment; support future authoritative manifest import |
| Split-generation statement/code unavailable | `set.seed(0)` alone does not identify the sampling call | Label the app split as a deterministic replacement split |
| Trained coefficients/forest/booster unavailable | Paper predictions cannot be replayed | Refit locally and identify engine/version in every result |
| Native app does not embed R packages/XGBoost | Native forest and boosting will differ from the paper engines | Export every native setting and label both engines as reconstructions |
| Per-row Fick inputs unavailable | Test-set Fick RMSE cannot be independently recomputed | Keep Fick as a parameterized numerical-method lab with an explicit evidence badge |
| Data S1 lacks series/replicate IDs | Row split can leak matching conditions | Report matching-condition overlap and offer leave-one-drug-out validation |
| Data S1 lacks run IDs for Fick calibration | Proxy-condition OOF may still share paper, batch, and biological context | Label it exploratory, bootstrap by proxy condition, expose family stress performance, and require future independent runs |
| Table 4 values are internally inconsistent with the published formulas/data range | Reported RMSE and R² cannot both be validated as written | Show reported and reconstructed values only for canonical row-split runs, without forcing agreement |

## UX implications

- Separate immutable, source-backed Paper Evidence from user-provided My Experiment data at the application level, not only with a result badge.
- Treat schema validity and scientific validity as different concepts. Personal data remain unvalidated even when their columns and numeric values parse successfully.
- Never promote a personal import to paper evidence from semantic/hash similarity alone; execution intent and source provenance are independent inputs to the evidence policy.
- Lead with the run's evidence level and readiness, not with a large “Run” button.
- Make dataset snapshot, split, seed, target, and model presets visible before execution.
- Default to the paper protocol while offering leave-one-drug-out as the scientifically safer future-experiment check.
- Keep a single primary action: run the experiment.
- Present metrics together with test count, split overlap, elapsed time, and engine identity.
- Make every run exportable as one JSON artifact containing configuration, hashes, exact split rows, metrics, and predictions.
- Retain recent runs locally so a scientist can compare or export them without reconstructing state.
- Use plain Japanese/English explanations and disclose that this is not a clinical, dosing, or safety tool.

## Primary sources

- Paper and supporting-information index: https://pmc.ncbi.nlm.nih.gov/articles/PMC10658566/
- PubMed record: https://pubmed.ncbi.nlm.nih.gov/38023708/
- DOI landing page: https://doi.org/10.1002/btm2.10512
- Archived XGBoost 1.5.0.2 source: https://cran.r-project.org/src/contrib/Archive/xgboost/xgboost_1.5.0.2.tar.gz
- Archived randomForest 4.7-1 source: https://cran.r-project.org/src/contrib/Archive/randomForest/randomForest_4.7-1.tar.gz
- R random-number generation documentation: https://stat.ethz.ch/R-manual/R-devel/library/base/html/Random.html
- Europe PMC supplementary-file package: https://www.ebi.ac.uk/europepmc/webservices/rest/PMC10658566/supplementaryFiles
- Fick finite-slab equation reference: https://pmc.ncbi.nlm.nih.gov/articles/PMC10892858/
- Direct Data S1: https://aiche.onlinelibrary.wiley.com/action/downloadSupplement?doi=10.1002%2Fbtm2.10512&file=btm210512-sup-0001-Supinfo1.xlsx
- Direct Data S2: https://aiche.onlinelibrary.wiley.com/action/downloadSupplement?doi=10.1002%2Fbtm2.10512&file=btm210512-sup-0002-Supinfo2.docx
- Direct supplementary figures: https://aiche.onlinelibrary.wiley.com/action/downloadSupplement?doi=10.1002%2Fbtm2.10512&file=btm210512-sup-0003-Figures.docx
