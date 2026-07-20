[HTML版を開く](README.html)

# Reference index

取得・集約日: 2026-07-17

| No. | File | Role | Access / handling |
| --- | --- | --- | --- |
| 01 | `papers/01-yuan-2023-drug-permeation-microneedled-skin-ml.pdf` | Primary study; 191-point permeation dataset and four-model comparison | CC BY publisher PDF |
| 02 | `papers/02-zheng-2024-microneedle-biomedical-devices.pdf` | Device classes, design variables, translation risks | Subscription publisher PDF; personal research use |
| 03 | `papers/03-xu-2023-small-data-ml-materials-science.pdf` | Small-data methods, validation, active learning | CC BY 4.0 |
| 04 | `papers/04-dou-2023-ml-methods-small-data-molecular-science.pdf` | Small-data ML review; physics integration | HHS public-access manuscript |
| 05 | `papers/05-achar-keith-2024-highlight-metadata-only.md` | Metadata for a 3-page Highlight | Full text not acquired |
| 06 | `supplementary/06-yuan-2023-data-s1.xlsx` | Data S1; 191 time-point rows | CC BY article supplementary file |
| 07 | `supplementary/07-yuan-2023-code-si2.docx` | R code for MLR/RF/XGBoost and C code for Fick model | CC BY article supplementary file |
| 08 | `supplementary/08-yuan-2023-new-drug-figures-si3.docx` | Leave-one-drug-out prediction figures | CC BY article supplementary file |
| 09 | `correspondence/2026-07-17-yunong-yuan-microneedle-references-email.png` | Source request and reference links | Private correspondence; local use only |

## Canonical online sources

1. Yuan Y, Han Y, Yap CW, et al. <https://doi.org/10.1002/btm2.10512>; open full text: <https://pmc.ncbi.nlm.nih.gov/articles/PMC10658566/>
2. Zheng M, Sheng T, Yu J, Gu Z, Xu C. <https://doi.org/10.1038/s44222-023-00141-6>
3. Xu P, Ji X, Li M, Lu W. <https://doi.org/10.1038/s41524-023-01000-z>
4. Dou B, Zhu Z, Merkurjev E, et al. <https://doi.org/10.1021/acs.chemrev.3c00189>; open full text: <https://pmc.ncbi.nlm.nih.gov/articles/PMC10999174/>
5. Achar SK, Keith JA. <https://doi.org/10.1021/acs.chemrev.4c00957>

The supplementary files were retrieved from the Europe PMC supplementary-file endpoint for `PMC10658566`.

## Data S1 audit

Read-only audit of `supplementary/06-yuan-2023-data-s1.xlsx`:

| Item | Result |
| --- | ---: |
| Data rows | 191 |
| Payloads | 6 |
| Unique non-time feature signatures | 18 |
| Rows sharing an identical feature + time signature | 140 |
| Exact duplicate outcome rows | 0 |
| Time range | 0.0833–48 h |
| Loading range | 50–70,940 µg |
| Missing `run_id`, `curve_id`, `batch_id`, `donor_id` | Yes |

The 140 overlapping rows have different outcomes and may represent replicates or separate curves, but the workbook does not supply identifiers needed to prove the grouping. Confirm this mapping with the authors before group-aware reanalysis.

## Integrity

Run from `big-lab/drug-release-profile/references/`:

```sh
find . -type f -exec shasum -a 256 {} +
```

Do not redistribute the subscription article or private correspondence.
