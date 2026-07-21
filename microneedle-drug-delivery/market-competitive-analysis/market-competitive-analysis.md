[HTML版を開く](market-competitive-analysis.html)

# Commercial and Market Competitive Analysis — Microneedle Drug and Cosmetic-Ingredient Delivery

Date: 2026-07-21  
Scope snapshot: publicly accessible sources retrieved on the date above

## Evidence convention

This is a commercial and market gap analysis, not an academic-method survey. It uses the following source-strength labels throughout.

- **(a) Peer-reviewed / regulatory / registry evidence:** a peer-reviewed paper, regulator database, or registered clinical-study record retrieved during this task.
- **(b) Official announcement or company page:** directly retrieved first-party information, but not independently validated here.
- **(c) Secondary source or inference:** would be clearly marked if used. No substantive finding below relies on class (c).

An entry saying “not disclosed in the cited material” means only that the retrieved source did not describe the item. It is not evidence that the company never uses it. Citations such as `[R3; a]` resolve to the retrieved URLs in [References](#references).

## 1. Executive summary

1. The selected medical-market examples have progressed through forms of product-specific validation that the current research system has not attempted: a peer-reviewed measles–rubella microneedle-patch Phase 1/2 trial involving Micron Biomedical, a peer-reviewed Vaxess MIMIX influenza-patch Phase 1 study, and an FDA 510(k) record for NanoPass’s MicronJet 600 device. These are not evidence that every platform or payload is approved; they demonstrate the commercial emphasis on device-, formulation-, and product-specific validation. `[R1; a] [R3; a] [R5; a]`

2. In the retrieved material, no named company supplied **(a)-level evidence of an AI/ML system that prospectively predicts microneedle drug permeation from molecular structure and device conditions.** The strongest directly observed AI cases are Shiseido’s formulation-candidate generator and Kobayashi Pharmaceutical’s Raman-spectra analysis for measuring tranexamic-acid distribution in a 3D skin model. They are material commercial capabilities, but neither is the same endpoint or validation task as the proposed microneedle QSAR/transfer-learning system. `[R11; b] [R12; b]`

3. The closest publicly described commercial predictive service is Biocom Systems’ SKIN-CAD: a mechanistic skin diffusion/partition and systemic-compartment model that accepts *in vitro* permeation and PK inputs. Its public workflow explicitly pairs diffusion-cell/skin experiments with simulation; it is therefore a more translational comparator for validation architecture than a direct ML competitor. `[R9; b] [R10; b]`

4. Cosmetic microneedles are already commercialized as targeted skincare and white-label products. Raphas Japan lists retinol- and vitamin-C-containing ACROPASS microneedle patches, while Raphas’s ODM page markets a retinol/HA white-label patch. The latter’s numerical efficacy/absorption statements are explicitly described by the vendor as based on internal and/or clinical testing, without protocol, data set, or patent number on the retrieved page; they must remain company claims rather than independent performance evidence. `[R7; b] [R8; b]`

5. The current project is valuable as a transparent, low-cost hypothesis and prioritisation programme, but its inputs are public retrospective data: an intact-skin resource, Yuan et al.’s microneedle records, and 48 cosmetic candidates. Its key commercial gap is not an algorithmic label; it is the absence of a linked formulation/device/skin experiment, prospective validation, and a product-specific regulatory and intellectual-property plan. `[P1] [P2]`

## 2. Scope and method

### What was investigated

The investigation selected publicly described commercial actors in four adjacent segments:

1. drug/vaccine microneedle products with clinical or regulatory evidence;
2. cosmetic microneedle products and white-label/ODM offerings;
3. commercial skin-permeation test, simulation, or formulation-development platforms; and
4. companies making a concrete AI/ML claim relevant to cosmetic formulation or penetration measurement.

Sources were located with native web search and then retrieved from company, regulator, clinical-registry, journal, university-repository, FDA, and EMA URLs. The report records only claims supported by those retrieved pages. It deliberately does not turn a company’s marketing claim into an independently verified result.

### What was not investigated

- This report does **not** re-survey academic ML/QSAR papers, PBPK software, or methodology benchmarks. The existing `competitive-landscape` document was read only to preserve this boundary; no claim or table was copied from it.
- It is not an exhaustive census of every global microneedle vendor, cosmetic patch, patent, clinical trial, or market authorization.
- It does not determine whether any product is currently approved in every jurisdiction, assess freedom to operate, or infer undisclosed internal R&D methods.
- It does not make a medical, cosmetic, or regulatory claim about the project’s 48 candidate ingredients.

### Handling access and uncertainty

Direct web retrieval worked for the core evidence. A later direct fetch of the PubMed and PMC pages for the Micron paper encountered reCAPTCHA/cache issues, so the report relies on the independently retrieved London School of Hygiene & Tropical Medicine repository copy for that peer-reviewed article rather than treating an inaccessible page as evidence. An EMA French-language URL returned HTTP 429, while the English EMA page was retrieved successfully. Details are retained in [`notes/decision-log.md`](notes/decision-log.md).

## 3. Microneedle product and company map

The map is illustrative rather than exhaustive. “Public development/prediction method” describes what the cited material actually reveals; a blank disclosure is not proof of absence.

| Company / platform | Segment, product, and stated payload | What has been independently or officially evidenced | Public development or performance-prediction method | Evidence |
| --- | --- | --- | --- | --- |
| **Micron Biomedical** | Dissolvable microarray patch for measles–rubella vaccine (MRV-MNP). | A peer-reviewed Phase 1/2, double-blind, active-controlled age-de-escalation trial identifies the patch as Micron Biomedical’s product. The report makes no claim of marketing authorization. | The clinical paper describes a product-specific clinical comparison. The retrieved sources do not disclose a prospective AI/ML formulation or permeation predictor. | `[R1; a] [R2; a]` |
| **Vaxess Technologies — MIMIX / VX-103** | Slowly dissolving microneedle-array patch carrying H1 influenza vaccine. | A peer-reviewed Phase 1 report describes safety, reactogenicity, tolerability, and immunogenicity evaluation of VX-103; its authors include Vaxess staff. | The article describes formulation and printed-array manufacture, followed by a human study. No AI/ML performance-prediction workflow is disclosed in the retrieved paper or registry record. | `[R3; a] [R4; a]` |
| **NanoPass Technologies — MicronJet 600** | Hollow microneedle device for intradermal injection of a separately approved substance/drug. | FDA 510(k) K092746 records the device name MicronJet 600 and NanoPass as applicant. NanoPass’s current product page calls MicronJet FDA-cleared and CE-marked for intradermal drug delivery. This is device evidence, not evidence that a particular drug–device combination has been approved. | No payload formulation or predictive-design method is disclosed in the cited records. | `[R5; a] [R6; b]` |
| **Raphas Japan — ACROPASS** | Cosmetic microneedle patches; the product page lists a retinol patch containing retinol and ascorbyl glucoside, and describes delivery to the stratum corneum. | The official product page establishes that the product line and named ingredient combinations are marketed. It does not independently establish delivery magnitude, clinical benefit, or drug status. | The cited retail page does not disclose a computational formulation or permeability-prediction method. | `[R7; b]` |

### What this map means for the project

The medical examples show that market progression is organised around a defined patch/device, a defined payload, manufacturing/formulation controls, and a study protocol. The current programme instead begins with a broad molecular source domain and a small historical microneedle data set. That is appropriate for retrospective hypothesis formation, but it cannot be treated as a substitute for product-specific evidence. `[R1; a] [R3; a] [P1] [P2]`

The cosmetic example confirms a real commercial route for active-ingredient microneedle patches, but its official pages do not disclose a molecular applicability domain, an experimental protocol sufficient to reproduce its absorption claims, or an AI/ML predictor. The evidence should therefore motivate a testable downstream use case, not validate a score produced from the project’s public data. `[R7; b] [R8; b]`

## 4. Verification of company AI/ML claims

| Company / system | Exact scope of the retrieved claim | Verification result and boundary | Evidence |
| --- | --- | --- | --- |
| **Shiseido — VOYAGER** | Shiseido’s 2026 official release says its formulation-development AI integrates formulation knowledge and proposes/formally screens many candidate formulations before researchers compare a smaller set. The release associates the system with a planned mist sunscreen product. | **Verified as an official formulation-AI claim (b).** It is not a microneedle platform, does not claim to predict log *Kp* or cumulative microneedle permeation, and the retrieved release is not a patent or peer-reviewed validation of delivery performance. | `[R11; b]` |
| **Kobayashi Pharmaceutical — Raman + ML multivariate analysis** | Its skin-science page says Raman spectroscopy and ML-based multivariate analysis were used to extract a tranexamic-acid signal from a cream-treated 3D skin model and visualise/estimate penetration distribution. | **Verified as an official penetration-measurement claim (b).** The disclosed task is signal separation and *post-application* measurement in a model, not a structure-to-MN-delivery prediction before an experiment. The page cites a 2025 IFSCC poster, not a retrieved peer-reviewed paper or patent. | `[R12; b]` |
| **Biocom Systems — SKIN-CAD** | Biocom describes SKIN-CAD as a mathematical skin absorption/PK model using *in vitro* skin-permeation data and PK parameters to calculate skin/blood concentration time courses. | **Verified as an official computational-prediction service (b), explicitly not labelled AI/ML on the retrieved page.** Its dependence on experimental inputs makes it technically distinct from a public-data-only QSAR screen. | `[R9; b] [R10; b]` |
| **Micron, Vaxess, NanoPass, and Raphas sources in §3** | The retrieved clinical, FDA, retail, and ODM pages were checked for a specific AI/ML predictor claim. | **No AI/ML predictor claim was located in the cited material.** This is a scoped non-finding, not evidence that these companies do not use internal computational tools. | `[R1; a] [R3; a] [R5; a] [R7; b] [R8; b]` |

### Interpretation

The verified AI activity divides into three different commercial roles:

- **formulation ideation** (Shiseido),
- **experimental measurement/analysis** (Kobayashi), and
- **mechanistic simulation conditioned on experimental inputs** (Biocom).

None should be presented as evidence that the current project’s proposed small-data QSAR, transfer-learning, or active-learning approach has commercial validation. Equally, the absence of a retrieved direct competitor is not a novelty claim: private formulation data and unpublished workflows are expected to be non-public. `[R9; b] [R11; b] [R12; b]`

## 5. Cosmetic-ingredient delivery ODM and platform companies

### Raphas: a disclosed white-label microneedle offering

Raphas’s ODM site presents a “Retinol Anti-Aging Microneedle Patch” as a white-label product and identifies retinol (3,300 IU/g) and hyaluronic acid (800,000 ppm). It also makes numerical absorption and appearance claims, but explicitly qualifies them as based on internal and/or clinical testing. The page provides neither a study protocol/data set nor a patent number. Accordingly, the formulation and white-label offering are reportable facts; the numerical performance claims are not used here as independent efficacy or permeability evidence. `[R8; b]`

### Biocom: experiment-coupled predictive screening

Biocom is the strongest retrieved example of a commercial permeability-prediction service. Its public materials say SKIN-CAD uses *in vitro* skin-permeation results, skin diffusion/partition parameters, and systemic PK parameters; its example workflow measures release in a diffusion cell, measures flux/time lag through skin, and compares a resulting simulation to clinical concentration data. The evidence supports the existence and stated architecture of the service, but it remains a company description rather than an independent validation across cosmetic ingredients. `[R9; b] [R10; b]`

### Answer to the predictive-screening question

**Yes, a commercial predictive service was identified, but it is not a structure-only pre-screen.** SKIN-CAD is a mechanistic, experiment-coupled prediction tool. In contrast, the retrieved Raphas and ACROPASS pages establish ODM/product availability but do not expose a public prediction model. Shiseido’s system illustrates AI-assisted formulation candidate generation, not demonstrated skin-permeation prediction. `[R8; b] [R9; b] [R10; b] [R11; b]`

## 6. Comparison with commercial validation practices

The comparison below separates *in vitro* release testing (IVRT), *in vitro* permeation testing (IVPT), clinical evidence, and regulatory evidence. FDA’s cited documents concern topical semisolid products and generic-drug submissions, not a universal microneedle rulebook; they are useful for the evidence logic, not as a claim that the present system meets a microneedle regulatory standard. `[R13; a] [R14; a]`

| Evidence layer | What the retrieved commercial/regulatory sources show | Current project position | Critical implication |
| --- | --- | --- | --- |
| **Formulation-specific IVRT** | FDA’s semisolid guidance describes an open diffusion-cell setup such as a Franz cell with a membrane, sequential receptor samples, analytical assay, and method validation to characterise formulation-specific release. | No new release experiment is proposed or performed in the current retrospective programme. | A predicted skin endpoint cannot determine whether a particular MN matrix/coating releases the payload as intended. `[R14; a] [P1]` |
| **Skin-specific IVPT / flux** | FDA’s 2022 draft guidance describes IVPT for comparing a proposed generic topical product with a reference product for bioequivalence support. Biocom’s public workflow measures flux and lag time through skin before simulating concentration profiles. | The project reuses intact-skin log *Kp* and microneedle cumulative-permeation records; it does not generate matched new flux or lag-time data for a cosmetic formulation/device. | Retrospective prediction can prioritise tests, but it cannot establish formulation equivalence or validate a new device–skin–ingredient combination. `[R13; a] [R10; b] [P1] [P2]` |
| **Human clinical validation** | Micron’s MRV-MNP and Vaxess’s VX-103 sources report defined human trials with safety/tolerability/immunogenicity end points. | No wet-lab or human study has been conducted for this project. | Model output must remain a research hypothesis, not a clinical, consumer-benefit, or dose recommendation. `[R1; a] [R3; a] [P1]` |
| **Device/product regulation** | NanoPass has a specific FDA device record; FDA notes that authorised microneedling devices have limited, specific intended uses and its public page warns against assuming authorisation for delivery of cosmetics or topical drugs. EMA’s transdermal-patch guideline addresses quality requirements for systemic-delivery patches. | The reviewed project documents contain no product-specific regulatory classification, submission strategy, or jurisdictional claim map. | A future product programme must first define the intended claim, jurisdiction, device/drug/cosmetic status, and evidence pathway; it cannot inherit status from another company’s patch or device. `[R5; a] [R15; a] [R16; a] [P1] [P2]` |

Two cautions follow. First, IVRT is not IVPT: a synthetic-membrane release test can be highly useful yet does not measure transport through living or excised skin. Second, even regulatory documents for conventional topical/transdermal products should not be read as automatically governing every dissolvable microneedle patch. Product classification and test design require specific expert review. `[R13; a] [R14; a] [R15; a] [R16; a]`

## 7. Gap analysis against the current system

The baseline reviewed for this analysis is the project’s planned 214-compound intact-skin log-*Kp* resource, 191-record/six-payload Yuan microneedle resource, transfer-learning proposal, applicability-domain work, and 48-ingredient cosmetic screen. `[P1] [P2]`

### (a) Missing commercial validation chain

The current system is deliberately retrospective and computational. It has no new formulation manufacture, insertion/geometry check, release test, skin permeation test, human PK/clinical study, or product-quality programme. This is not a defect in a research-proposal stage, but it is the principal difference from the evidence pathways shown by Micron, Vaxess, NanoPass, and Biocom. Any future paper must make this boundary visible in the abstract, methods, limitations, and conclusion. `[R1; a] [R3; a] [R5; a] [R10; b] [P1] [P2]`

### (b) Insufficient cosmetic- and formulation-specific data

The current source-domain data are measured skin permeability records and the cosmetic list contains structures/descriptors, not matched measurements of cosmetic formulation, microneedle material, patch geometry, adhesive/contact, stability, or skin response. The four cosmetic ingredients already overlapping the measured resource can check intact-skin data handling, but they cannot validate cumulative delivery through microneedle-treated skin. The commercial examples make clear why a molecular candidate and a finished patch are different units of evidence. `[P1] [P2] [R7; b] [R10; b]`

### (c) Missing regulatory and patent position

The reviewed project baseline has no documented product-claim classification, regulatory evidence plan, patent landscape, or freedom-to-operate analysis. This report does not fill those gaps. Raphas’s ODM page invokes “patent recognition” without giving a number, so it cannot support a patent comparison; NanoPass’s 510(k) cannot be generalized to a different payload, patch, or claim. The next commercialisation-oriented phase needs a jurisdiction-specific legal/regulatory review before a product or performance claim is drafted. `[R5; a] [R8; b] [R15; a] [P1] [P2]`

### (d) Technical difference from publicly disclosed commercial methods

- **Biocom** starts with experiment-derived transport/PK parameters and uses a mechanistic diffusion/partition model. The current project starts with public molecular descriptors and historical outcome data. `[R9; b] [R10; b] [P1]`
- **Kobayashi** applies ML to deconvolve experimental Raman spectra after a formulation has been applied to a 3D skin model. The current project predicts an endpoint from records/descriptors; it does not measure an applied formulation. `[R12; b] [P1]`
- **Shiseido** uses AI to generate and narrow formulation candidates based on internal formulation knowledge. The current project does not have comparable proprietary formulation data or a candidate-to-experiment loop. `[R11; b] [P1] [P2]`
- **Micron and Vaxess** use defined patch/payload programmes and clinical protocols. The current system is not a product-development dataset and must avoid implied product readiness. `[R1; a] [R3; a] [P1]`

### Overall competitive position

The project’s defensible position is **transparent early-stage decision support under strict applicability-domain and held-out-payload controls**. It should not compete rhetorically with product developers on clinical readiness, or with an experiment-coupled simulator on product-specific PK. Its potentially useful contribution is to identify which small-molecule candidates and data gaps warrant a subsequent experimental programme, with explicit abstention outside the validated domain. `[P1] [P2] [R9; b]`

## 8. Implications for the small-data-ML and active-learning papers

These are proposed revisions for the two separate paper worktrees, not edits made by this module.

### Small-data ML paper

1. **Add a commercial-evidence boundary near the abstract and conclusion.** State plainly that the work is a retrospective research proposal using public data, not a formulation, device, clinical, or regulatory validation. Contrast this with product-specific clinical studies only as an evidence-layer difference, not a performance benchmark. `[R1; a] [R3; a] [P1]`
2. **Add a validation ladder to the future-work section.** After applicability-domain screening, specify that any product-oriented extension would need pre-specified formulation/device characterisation, appropriate release/permeation experiments, and only then product-specific clinical/regulatory planning. Do not present FDA topical guidance as an MN-specific requirement. `[R13; a] [R14; a] [R15; a]`
3. **Make the missing feature blocks explicit.** Molecular descriptors and the seven Yuan variables do not encode formulation matrix/coating chemistry, actual insertion, patch contact/adhesion, stability, assay conditions, or a product’s clinical context. The paper should name these as unobserved variables before claiming transferability. `[P1] [P2] [R10; b]`
4. **Tighten cosmetic framing.** Describe the 48 ingredients as prioritisation candidates, not a commercial cosmetic-product screen. Retain separate labels for intact-skin log *Kp*, microneedle cumulative permeation, in-domain candidates, and out-of-domain abstentions; prohibit consumer-efficacy or “deep delivery” language unless separately measured. `[P1] [R7; b] [R12; b]`
5. **Add a commercialization-limits paragraph.** Identify product claim classification, patent/FTO review, and jurisdictional strategy as later work. Do not use Raphas’s unnumbered patent marketing statement as prior art or evidence of clearance. `[R5; a] [R8; b] [R15; a]`

### Retrospective active-learning paper

1. **Make the outcome boundary more prominent.** The reported 18% saving is a retrospective ordering result within a fixed historical pool; it is not evidence of saving in a prospective manufacturing, Franz-cell/IVPT, or clinical programme. `[P2] [R13; a] [R14; a]`
2. **Specify the prospective acquisition unit.** A future active-learning experiment should select a pre-specified payload–formulation–device–skin–assay condition, record batch and quality variables, and reserve independent confirmation experiments. Selecting rows from a historical pool cannot estimate those operational sources of variance. `[R10; b] [P2]`
3. **Use acquisition to close the demonstrated coverage gap.** The paper already identifies molecular descriptors and transfer learning as future work. Add diversity/applicability constraints and an explicit policy for acquiring out-of-domain compounds or declining to rank them, rather than treating uncertainty alone as a commercial design rule. `[P1] [P2]`
4. **Add evidence and reproducibility gates.** A prospective study should pre-register the target endpoint, release/permeation protocol, stopping rule, model update rule, raw batch/assay data, and external confirmation split. This complements the paper’s existing disclosure that the retrospective workflow is not end-to-end regenerable. `[P2] [R14; a]`
5. **Avoid regulatory/product extrapolation.** The paper’s conclusion should continue to describe experimental-planning support within a known chemical space, never a product, dose, efficacy, or clearance claim. `[R15; a] [P2]`

## 9. Unresolved questions and items not verified

1. No retrieved source established that a commercial company uses AI/ML to prospectively predict **microneedle** permeation across new drug or cosmetic ingredients from structure plus device/formulation variables. This is a scoped search result, not proof of absence.
2. No Raphas patent number or underlying patent document was retrieved from its ODM page. The report therefore does not compare patent scope, priority, validity, or freedom to operate. `[R8; b]`
3. Current marketing authorization, geographic availability, and commercial status of each named product were not exhaustively checked. The report limits itself to the cited trial, device, and product-page evidence.
4. The publicly described FDA generic-topical and EMA transdermal-patch guidance is not a product classification decision for a dissolvable MN cosmetic patch. Product-specific regulatory advice is required. `[R13; a] [R15; a] [R16; a]`
5. Whether confidential commercial formulation data can be obtained, licensed, or generated prospectively is unresolved. Without it, a structure-only predictor cannot represent many finished-product variables.
6. Direct PMC/PubMed fetches of the Micron paper encountered access barriers after search retrieval; the peer-reviewed article was instead supported by the retrieved LSHTM repository copy. The exact access event is documented in the decision log.

## References

### Project context

- **[P1]** [`research/CLAUDE.md`](../research/CLAUDE.md) — current system, data sources, terminology, and known constraints.
- **[P2]** [`research/RESEARCH_PLAN.md`](../research/RESEARCH_PLAN.md) — current project phases and proposed modelling/validation work.

### Retrieved external sources

- **[R1] (a)** Adigweme et al. *A measles and rubella vaccine microneedle patch in The Gambia: a phase 1/2, double-blind, double-dummy, randomised, active-controlled, age de-escalation trial.* *The Lancet* (2024), DOI `10.1016/S0140-6736(24)00532-4`. Retrieved repository copy: [LSHTM Research Online PDF](https://researchonline.lshtm.ac.uk/id/eprint/4673141/1/Adigweme-etal-2024-A-measles-and-rubella-vaccine-microneedle-patch-in-The-Gambia.pdf).
- **[R2] (a)** [ClinicalTrials.gov — NCT04394689, Measles and Rubella Vaccine Microneedle Patch Phase 1–2 Age De-escalation Trial](https://clinicaltrials.gov/study/NCT04394689).
- **[R3] (a)** Garg et al. *Phase 1 … H1N1 influenza vaccine delivered by VX-103 (a MIMIX microneedle patch system).* *PLOS ONE* (2024), DOI `10.1371/journal.pone.0303450`: [article](https://journals.plos.org/plosone/article?id=10.1371%2Fjournal.pone.0303450).
- **[R4] (a)** [ClinicalTrials.gov — NCT06125717, Phase 1 Evaluation of H1 Influenza Vaccine Delivered by MIMIX MAP](https://clinicaltrials.gov/study/NCT06125717).
- **[R5] (a)** [FDA 510(k) Premarket Notification K092746 — MicronJet 600](https://www.accessdata.fda.gov/scripts/cdrh/cfdocs/cfpmn/pmn.cfm?ID=K092746).
- **[R6] (b)** [NanoPass MicronJet product page](https://www.nanopass.com/product/).
- **[R7] (b)** [Raphas Japan — ACROPASS product line](https://raphas.co.jp/acropass/).
- **[R8] (b)** [Raphas ODM — Retinol Anti-Aging Microneedle Patch](https://odm.raphas.com/en/wzcFJ/170).
- **[R9] (b)** [Biocom Systems — SKIN-CAD](https://www.biocom.co.jp/skin-cad/).
- **[R10] (b)** [Biocom Systems — *in vitro* + *in silico* workflow](https://www.biocom.co.jp/in-vitro-in-silico/).
- **[R11] (b)** [Shiseido — formulation-development AI “VOYAGER” release](https://corp.shiseido.com/jp/news/detail.html?n=00000000004127).
- **[R12] (b)** [Kobayashi Pharmaceutical — cosmetic-ingredient penetration assessment using Raman spectroscopy and ML](https://skincare.kobayashi.co.jp/field/skincare/penetration02.html).
- **[R13] (a)** [FDA — *In Vitro Permeation Test Studies for Topical Drug Products Submitted in ANDAs* (2022 draft guidance)](https://www.fda.gov/regulatory-information/search-fda-guidance-documents/in-vitro-permeation-test-studies-topical-drug-products-submitted-andas).
- **[R14] (a)** [FDA — *Guidance for Industry: Nonsterile Semisolid Dosage Forms*](https://www.fda.gov/media/71141/download?attachment=).
- **[R15] (a)** [FDA — Microneedling Devices](https://www.fda.gov/medical-devices/aesthetic-cosmetic-devices/microneedling-devices).
- **[R16] (a)** [European Medicines Agency — Quality of transdermal patches](https://www.ema.europa.eu/en/quality-transdermal-patches-scientific-guideline).
