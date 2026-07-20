# Final execution status - Curved Corneal Construct Geometry QC

Date: 2026-07-19  
Scope: locked-spec implementation audit and Gate 0 handoff  
Research state: **Gate 0 unresolved; Gate 2 and later remain on Hold**  
Data state: **no real pilot CAD, image, scan, OCT, calibration, or measurement output is available in this workspace**

This document is a status artifact, not a research-results report. It does not set a numeric QC threshold, classify a real construct, or infer biological, optical, mechanical, permeability, or clinical performance.

## 1. One-sentence research question

> **Proposal - PI confirmation required:** For a PI-defined curved corneal construct and versioned design reference, under a documented acquisition tier, how far does the PI-selected geometry-error endpoint deviate from the design target?

The endpoint component is deliberately not filled in. Radius deviation, wall-thickness variation, surface RMSE, or topographic chordal error must be selected as the primary endpoint at Gate 0; all other geometry metrics then remain secondary or exploratory.

## 2. Assumptions and unresolved questions

No answer below has been inferred from portfolio data, row order, or the literature.

| # | Gate 0 question | Current status | Decision owner |
| --- | --- | --- | --- |
| 1 | Which of radius error, wall-thickness variation, surface roughness, and topographic chordal error is currently hardest to measure reproducibly? | Unanswered | PI / lab measurement owner |
| 2 | Should the first pilot be an OCT/scan geometry-QC workflow or a run-level registry linking bioink and photocrosslinking conditions to outcomes? | Unanswered | PI |
| 3 | Which existing inputs are available: CAD, multi-angle photographs, structured-light scan, OCT, confocal z-stack, or instrument CSV? | No real inventory present | PI / data owner |
| 4 | Are the 3D scanner, OCT, and CAD software accessible, and what training is required? | Unconfirmed | Instrument owner / PI |
| 5 | Can the full text of Huang, Yuan et al. (2026), the dual-layer corneal paper, be obtained? | Metadata only | PI / library owner |
| 6 | May surface RMSE against the design mesh operationalize surface fidelity, or is separate Tier B Ra/Rq texture measurement required? | Unanswered | PI / metrology owner |
| 7 | What is the real nesting of material/bioink batch and print run? | Unknown; must not be inferred | PI / fabrication owner |

Additional unresolved schema decision: the source dictionary stores `protocol_version`, `design_version`, `registration_method`, and `measurement_id`, but it does not yet define dedicated `method_version`, Tier B `section_id`, or `layer_id` fields. Their final identifiers and linkage must follow the real lab hierarchy rather than be invented here.

## 3. File and data audit

| Asset class | Exists locally | Missing / consequence |
| --- | --- | --- |
| Locked specification | `requirements.md`, `implementation-prompt.md` | No substantive specification gap blocks the site audit |
| Planning templates | study charter, analysis plan, data dictionary, imaging sampling plan, construct log | Templates are blank; no PI-approved completed charter or data inventory exists |
| Governance | `notes/decision-log.md` with proposed D-001 and D-002 | PI approval and actual Gate 0 decisions are not recorded |
| Primary evidence | Yuan et al. (2026) local PDF | Supports the reporting gap and method framing, not a real pilot result |
| Related evidence | local reference index and related Yuan PDFs; dual-layer metadata | Dual-layer full text remains unavailable in the indexed workspace |
| Synthetic portfolio | charter, 12-row/3-batch CSV, run log, claim-evidence map, web/poster demo | Permitted only for structure and pipeline warm-up; no value or threshold transfers to a real pilot |
| Real design reference | None identified | Design-relative geometry error cannot be calculated |
| Real raw acquisition | None identified | No construct can be measured or classified |
| Calibration evidence | None identified | No pixel/voxel value can be converted to mm, micrometres, area, or volume |
| Data-use permission | None recorded | Private image/scan/OCT access and analysis must not begin |
| Actual run/batch hierarchy | None recorded | Grouped inference and leave-one-batch-out validation cannot run |
| Gate 1 code/evidence outputs | No loader, metric code skeleton, unit tests, or evidence matrix found in this project folder | Gate 1 remains available as future synthetic-only warm-up work; it is not claimed complete |

## 4. Experimental design status

| Domain / path | Proposed role | Current disposition |
| --- | --- | --- |
| Geometry error | Primary measurement domain; choose one predeclared component | Primary component pending PI decision |
| Print-process traceability | Explanatory fields: fabrication strategy, layer thickness, slice/overhang angle, support, material/bioink batch, printer/optics settings | Record design is present; real values absent |
| Extended characterization | Separate Gate 7 measurements for mechanics, transparency, refractive index/power, and permeability | Out of scope for Gate 0-6 and not yet supported |
| Tier A | Multi-angle photo, structured light, or surface scan to a registered 3D surface | Candidate only; availability and calibration unknown |
| Tier B | OCT, confocal z-stack, or profilometry for thickness, surfaces, boundaries, and local curvature | Candidate only; access, training, calibration, and interpretation unknown |

Planned hierarchy:

```text
study
└── print run
    └── material / bioink batch
        └── construct (sample)
            └── measurement event
                └── (Tier B only) section / layer technical measurement
```

`protocol_version`, `design_version`, acquisition/registration context, and the future approved method version must remain linked at their applicable level. Whether batch is truly nested within print run is a Gate 0 question, not an established fact.

## 5. QC and acceptance status

| QC element | Required rule | Current status |
| --- | --- | --- |
| Calibration | Verified reference before physical-unit values | **Hold - no calibration evidence** |
| Design reference | `design_version` resolves to stored CAD/mesh | **Hold - no design file identified** |
| Permission | Approved use of every raw image/scan/OCT file | **Hold - no permission record** |
| Hierarchy | Source-confirmed study/run/batch/construct mapping | **Hold - unknown** |
| Primary endpoint | One geometry component, unit, region, and sign convention fixed before results | **Pending PI selection** |
| Registration review limit | Predeclared fit-quality limit; high RMSE triggers review, not automatic acceptance | **Pending PI approval; no numeric value set** |
| PASS / REVIEW / FAIL thresholds | Metric-specific, predeclared, PI-approved rules | **Pending PI approval; no numeric value set** |
| Stored/display status mapping | Reconcile source `pass|review|exclude_from_primary` with reader-facing PASS/REVIEW/FAIL | **Pending deliberate schema/PI decision** |
| Failure handling | Retain raw row and record `exclusion_reason`; never silently delete | Defined in plan; no real failures exist to classify |

The portfolio rule `|radius deviation| <= 0.18 mm` is synthetic demonstration logic only. It is not a candidate real-pilot threshold and has not been copied into this acceptance table.

## 6. Analysis plan, equations, and units

| Metric | Definition / equation | Unit | Execution status |
| --- | --- | --- | --- |
| Radius deviation | `best_fit_radius - design_radius` | mm | Not calculated |
| Wall-thickness variation | `local_thickness(x) - design_thickness(x)` | mm | Not calculated |
| Surface RMSE | RMS of measured minus design surface over the registered region | mm | Not calculated; this is not Ra/Rq texture roughness |
| Topographic chordal error | Maximum discretised-path deviation from the intended smooth curve | mm | Not calculated |
| Volume change | `(measured_volume - design_volume) / design_volume` | fraction; source volumes in mm3 | Not calculated |
| Shrinkage rate | `(as_printed_dimension - post_process_dimension) / as_printed_dimension` | fraction | Not calculated; paired measurements required |
| Interlayer misalignment | Offset between adjacent printed layers | mm | Not calculated; normally Tier B |
| Registration RMSE | Registration fit-quality diagnostic | mm | Not calculated; never treated as geometry error |

Calibration rule: if `calibration_confirmed` is false, physical-unit length, area, and volume outputs remain `not_measurable`; they are not converted by assumption.

Execution step 8 status: no small-sample model or grouped validation was run. After the hierarchy is source-confirmed, batch and print run must be grouping factors; leave-one-batch-out or an equivalent grouped validation may be used only when there are enough real independent groups.

Execution step 9 status: there are no real results to report. The only data-derived counts on the site are visibly marked synthetic portfolio structure (12 constructs across 3 batches). The next minimum experiment is a PI-approved Gate 3 baseline using one or two approved samples after Gate 0 and Gate 2 are complete.

Execution step 10 status: the HTML separates literature fact, proposal, conceptual/non-measured diagrams, unavailable real data, and synthetic demo content, and identifies its update date and local sources.

## 7. Risks and mitigation

| Risk | Mitigation / stop rule |
| --- | --- |
| Missing calibration | Stop physical-unit calculation; recover instrument/reference evidence or mark not measurable |
| Missing design geometry | Stop design-relative metrics; resolve a versioned CAD/mesh first |
| Unknown permission or training | Do not access private data or equipment; confirm with PI, owner, SOP, and institution rules |
| Transparent/wet sample acquisition or segmentation failure | Record acquisition conditions and failure reason; review Tier suitability; retain the row |
| Registration non-convergence | Preserve parameters and overlay; send to human review; do not auto-accept or silently exclude |
| Incorrect run/batch nesting | Stop grouped inference until source records establish the hierarchy |
| Synthetic/real mixing | Keep badges, separate figures/tables, and `source_type`; exclude synthetic rows from real summaries |
| Geometry-to-performance overreach | Classify mechanical, optical, permeability, biological, and clinical claims as not supported until dedicated measurements exist |

## 8. Reproducible outputs and paths

- Roadmap page: `corneal-geometry-qc/site/index.html`
- Styles and print rules: `corneal-geometry-qc/site/assets/roadmap.css`
- Local behavior: `corneal-geometry-qc/site/assets/roadmap.js`
- Favicon: `corneal-geometry-qc/site/assets/favicon.svg`
- Concept illustration record: `corneal-geometry-qc/site/assets/hero-illustration-notes.md`
- Locked requirements: `corneal-geometry-qc/requirements.md`
- Reusable execution prompt: `corneal-geometry-qc/implementation-prompt.md`
- This Gate 0 status artifact: `corneal-geometry-qc/final-status-report.md`

Verification used local-only tools: Node syntax checking, HTML5 parsing, filesystem resolution of every `href`/`src`, headless Chrome on both `file://` and local HTTP, 360 px viewport checks, keyboard behavior checks, reduced-motion/print media inspection, A4 PDF rendering, and local PDF text plus page-image review.

## 9. Claims supported and not yet supported

Supported now:

- Yuan et al. (2026) identifies the systematic geometry-reporting gap and proposes test domes measured by high-resolution scanning or OCT with radius, thickness, roughness, and chordal metrics.
- Yuan et al. (2026) Table 3 organizes standard measurement methods for mechanics, transparency, refractive power/index, and permeability.
- The portfolio CSV contains 12 synthetic constructs across 3 synthetic batches with the displayed demo status counts.
- The roadmap implementation is a functioning local-first planning interface with explicit provenance and stop conditions.

Not yet supported:

- Any real construct radius, thickness, surface, chordal, volume, shrinkage, or interlayer result.
- Any PI-approved numeric PASS, REVIEW, FAIL, or registration threshold.
- Any comparison or superiority claim about fabrication strategies, materials, batches, or operators.
- Any Young's modulus, transparency, refractive index/power, permeability, biological function, safety, or clinical-suitability claim.
- Generalisation from a 12-construct pilot or from the synthetic portfolio demo.

## 10. Next decision and owner

1. **PI:** answer the seven Gate 0 questions and select the construct type, primary geometry endpoint, acquisition tier, actual hierarchy, and predeclared QC/status rules.
2. **Data/instrument owner:** confirm source files, calibration evidence, access, training, and data-use permission.
3. **Takumi:** record decisions in `notes/decision-log.md`, complete `templates/study-charter.md`, and create a real data inventory without copying synthetic values.
4. **Stop state:** Gate 2 and later remain on Hold until calibration, design reference, permission, hierarchy, endpoint, and thresholds are resolved. Gate 1 synthetic-only warm-up may proceed, but its outputs must remain visibly non-experimental.

