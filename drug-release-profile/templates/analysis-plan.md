# Analysis plan — Microneedle Drug Release Profile

Status: draft / frozen / amended  
Linked charter version:  
Analyst:  
Independent reviewer:  

## 1. Endpoint classification

Select one primary endpoint family:

- [ ] Release-only: MN / matrix → receptor medium without skin barrier
- [ ] Permeation: donor / MN → through skin → receptor
- [ ] Retention: payload recovered in tissue at endpoint
- [ ] Recovery: receptor + tissue + residual device + donor / wash fractions

## 2. Cumulative amount correction

For constant receptor volume `V_r`, sample volume `V_s`, complete replacement, and a well-mixed receptor:

```text
Q_n = V_r × C_n + V_s × Σ(C_i), i = 1 … n−1
```

Record the actual sampling scheme. Use a mass-balance recurrence instead when volume, replacement, or mixing differs.

Derived outputs:

```text
amount_per_area_n = Q_n / diffusion_area
fraction_loaded_n = Q_n / assay_confirmed_exposed_load
percent_loaded_n = 100 × fraction_loaded_n
```

Never substitute nominal whole-patch loading for assay-confirmed exposed-needle loading without justification.

## 3. Data quality

- Raw concentrations remain unchanged.
- Below-quantification handling is predeclared.
- Re-injection and repeat-assay reasons are retained.
- Unit conversion is scripted and tested.
- Non-monotonic cumulative values are flagged; they are not silently forced upward.
- Exclusions remain in the dataset with `qc_status` and `exclusion_reason`.

## 4. Descriptive analysis

- Plot every cell-level curve.
- Overlay batch / donor / condition summaries without hiding individual curves.
- Report `n` at batch, donor, cell, and time-point levels.
- Summarise actual temperature, sampled volume, exposed area, loading, recovery, and protocol deviations.

## 5. Candidate kinetic models

| Model | Common form | Use / caution |
| --- | --- | --- |
| Zero-order | `Q_t = Q_0 + k_0 t` | Constant release rate; verify residuals and depletion |
| First-order | `F_t = 1 − exp(−k_1 t)` | Concentration-dependent approach to plateau |
| Higuchi | `Q_t = k_H √t` | Diffusion-controlled approximation; assumptions and early-time range matter |
| Korsmeyer–Peppas | `M_t/M∞ = k t^n` | Empirical early-fraction model; geometry and fitted range affect `n` |
| Weibull | `F_t = 1 − exp[−(t/α)^β]` | Flexible descriptive curve; mechanism is not identified by fit alone |
| Mechanistic diffusion / erosion | system-specific PDE / ODE | Preferred when boundaries and material processes are identifiable |

Model comparison:

- cell / curve is the unit of fit unless a hierarchical model is specified
- report RMSE / MAE, AICc where applicable, residual plots, parameter intervals, parameter plausibility
- compare predictive performance on held-out curves / batches
- do not choose a mechanism from the largest `R²` alone

## 6. Group comparison

- Primary contrast:
- Estimand:
- Model:
- Fixed effects:
- Random effects:
- Covariates:
- Multiple-comparison control:
- Confidence / compatibility interval:
- Missing-data strategy:

For repeated time points, use a hierarchical / repeated-measures approach or compare predeclared curve-level summaries. Do not use a test that assumes all time points are independent.

## 7. Small-data ML

Use only after the mechanistic and classical baselines are fixed.

- Group key for split:
- Nested cross-validation:
- Leave-one-batch / drug / platform-out test:
- External prospective set:
- Uncertainty method:
- Applicability-domain rule:
- Leakage checks:
- Frozen preprocessing pipeline:

Minimum baselines: mean / simple parametric curve, regularised linear model, mechanistic model, GPR, RF / XGBoost if justified.

## 8. Figures

1. Cell-level cumulative profile
2. Amount/area and fraction-loaded panels
3. Endpoint mass-balance stacked plot
4. Residual and observed-vs-predicted plots
5. Batch / donor variability
6. Prediction interval and applicability-domain plot for ML

Each caption must state endpoint, unit, experimental `n`, summary statistic, interval, exclusions, and whether data are measured or simulated.

## 9. Claims

### Supported if criteria pass

- 

### Not supported by this design

- Clinical efficacy
- Clinical dose optimisation
- Generalisation to unseen drug / platform without external validation
- Mechanism inferred only from empirical curve fit

