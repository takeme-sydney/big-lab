[HTML版を開く](study-charter.html)

# Study charter — Curved Corneal Construct Geometry QC

Version:
Owner:
PI / reviewer:
Date opened:
Target decision date:
Status: draft / approved / frozen / amended / closed

## 1. One-sentence research question

> For [defined corneal construct type / design geometry] fabricated by [defined printing strategy], how large is the [radius deviation / wall-thickness variation / surface roughness / topographic chordal error] relative to the design target, under [defined acquisition method]?

## 2. Primary endpoint

- Endpoint（geometry errorのどの成分か）:
- Unit:
- Design / nominal reference source:
- Acquisition tier: Tier A（photo / structured light / surface scan） or Tier B（OCT / confocal z-stack / profilometry）
- Experimental unit:
- Primary comparison:
- Success criterion（Gate 0でPI承認のもと確定。synthetic demoの`±0.18mm`は転用しない）:

## 3. Secondary endpoints

| Endpoint | Unit | Purpose | Confirmatory or exploratory |
| --- | --- | --- | --- |
| Registration RMSE |  | Fit品質の診断（geometry errorではない） | exploratory |
|  |  |  |  |

## 4. Scope

### Included

-

### Excluded

- 力学（Young's modulus）、光学（transparency、refractive index/power）、permeabilityの主張（Gate 7以前）
- 生物学的機能・臨床適合性の結論
- 機器・データ利用の許可・training要件の代替

## 5. System classification

- Construct type: curved dome / crescent-shaped / other
- Fabrication approach: mould-assisted / direct（support-free） / other
- Print method: material extrusion（ME） / digital light processing（DLP） / inkjet / stereolithography（SLA） / other
- Data acquisition tier: Tier A / Tier B / both
- Calibration available? yes / no / to be confirmed

## 6. Experimental hierarchy

```text
study
└── print run
    └── material / bioink batch
        └── construct (sample)
            └── (Tier Bのみ) 測定断面 / layer
```

独立にrandomiseする水準と、technical replicateとして扱う水準を定義する:

## 7. Factors and controls

| Factor | Levels / range | Fixed or random | Rationale |
| --- | --- | --- | --- |
| Print run |  | random |  |
| Material / bioink batch |  | random |  |
| Fabrication strategy（mould-assisted / direct） |  | fixed |  |
| Layer thickness |  | fixed |  |
| Slice angle / overhang角度 |  | fixed |  |
| Design geometry（target radius / thickness） |  | fixed |  |

Controls:

- Design reference / CAD model:
- 未印刷（未硬化）material controlの要否:
- Repeat-scan control（同一constructの再測定による測定誤差評価）:

## 8. Sample size and replication

- Pilot variance source:
- Independent print runs:
- Material / bioink batches:
- Constructs per batch:
- Repeated measurements per construct（re-scan等）:
- Power / precision target:
- Attrition allowance（segmentation失敗・calibration欠落等）:

Constructを無条件に独立`n`として数えない。batchをgroup化因子として扱う。

## 9. Predeclared quality gates

| Gate | Acceptance criterion | Evidence file | Decision owner |
| --- | --- | --- | --- |
| Calibration（pixel/voxel → mm） |  |  |  |
| Design mesh / CAD availability |  |  |  |
| Registration convergence（RMSE上限） |  |  |  |
| Segmentation / mesh quality |  |  |  |
| Repeat-scan precision |  |  |  |
| Data-use permission |  |  |  |

## 10. Randomisation and blinding

- Randomisation unit and method:
- Blocking factors（print run、operator、scan日）:
- Sample label blinding:
- Analyst blinding:
- Code unblinding point:

## 11. Data and code

- Raw scan / image / OCT data location:
- Read-only archive:
- File naming rule:
- Data dictionary: `templates/data-dictionary.csv`
- Analysis environment:
- Version-control location:
- Access / publication restriction:

## 12. Amendments

| Date | Change | Reason | Before or after unblinding? | Approved by |
| --- | --- | --- | --- | --- |
|  |  |  |  |  |
