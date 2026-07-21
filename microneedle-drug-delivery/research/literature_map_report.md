[HTML版を開く](literature_map_report.html)

# Recent Literature Map: Machine Learning & Computational Modeling for Microneedle and Transdermal Drug Delivery

*Prepared for an intern in Yuan Yunong's group (BIG, University of Sydney). Anchored on the group's own work — Yuan et al. (2023), "Prediction of drug permeation through microneedled skin by machine learning" (35 citations) — this map surveys the subfield that paper sits in: using computational and machine-learning models to predict, design, and optimize drug transport through skin.*

---

## 1. Scope and method

**Question mapped:** Where does the literature stand on **data-driven / computational prediction of drug permeation and delivery through skin** — spanning microneedle-treated skin, intact-skin permeability (QSAR), formulation optimization, and physics-based simulation (molecular dynamics, finite-element)?

**How this map was built.** I queried Crossref (≈480 records across 8 topic searches) and PubMed/E-utilities (≈600 records across 4 searches) for 2015–2026, merged and deduplicated by DOI and normalized title (**990 unique records**), then scored each record for presence of *both* a skin-delivery dimension and a computational-method dimension. An LLM classifier read every title+abstract and retained the records genuinely at that intersection — filtering out near-neighbours such as transdermal *alcohol biosensing*, wearable glucose sensing, image-based dermatology, and pure microneedle *fabrication* with no modeling. **Final curated corpus: 116 in-scope papers.** Citation counts are from Crossref, fetched from each paper's own DOI.

**Caveats.** No OpenAlex/contact-email access was available this session, so the corpus rests on Crossref + PubMed; several 2026 papers have low or zero citation counts simply because they are new. A few broadly-cited reviews (e.g., a topical-delivery history) reflect general reach rather than subfield-specific influence. Theme and method labels come from abstract-level LLM classification, so borderline papers could shift category — the full curated list with DOIs is in the attached CSV for spot-checking.

---

## 2. The headline: a subfield in steep take-off

The corpus spans 2015–2026. Publication volume was flat at ~5–7 papers/year through 2015–2023, then inflected sharply: **16 papers in 2024, 22 in 2025, and 30 already logged for 2026.** 59% of the entire corpus was published in 2024 or later. This is a young, fast-moving area — the Yuan (2023) microneedle-permeation paper arrived right as the wave began building.

Two forces drive the surge: (i) the broad diffusion of gradient-boosting/deep-learning tooling into pharmaceutics, and (ii) regulatory momentum behind *in silico* dermal-exposure assessment (PBK/PBPK models, model-informed drug development) as an alternative to animal and Franz-cell testing.

---

## 3. The five thematic clusters

The subfield organizes into distinct communities, each with its own methods and venues:

### 3.1 Skin-permeability QSAR / ML — *the largest and oldest cluster (48 papers)*
Predicting the permeability coefficient (log *Kp*) or flux of small molecules through intact skin from molecular descriptors. This is the intellectual ancestor of the whole field (Potts–Guy-style relationships), now modernized with ensemble ML and larger curated datasets.
- Roberts et al. (2021). Topical drug delivery: History, percutaneous absorption, and product development. *Advanced drug delivery reviews*, — **196 cites** [doi:10.1016/j.addr.2021.113929](https://doi.org/10.1016/j.addr.2021.113929)
- Toropova et al. (2017). The index of ideality of correlation: A criterion of predictability of QSAR models for skin permeability?. *The Science of the total environment*, — **111 cites** [doi:10.1016/j.scitotenv.2017.01.198](https://doi.org/10.1016/j.scitotenv.2017.01.198)
- Tsakovska et al. (2017). Quantitative structure-skin permeability relationships. *Toxicology*, — **93 cites** [doi:10.1016/j.tox.2017.06.008](https://doi.org/10.1016/j.tox.2017.06.008)
- Alves et al. (2015). Predicting chemically-induced skin reactions. Part II: QSAR models of skin permeability and the relationships between skin permeability and skin sensitization. *Toxicology and Applied Pharmacology*, — **69 cites** [doi:10.1016/j.taap.2014.12.013](https://doi.org/10.1016/j.taap.2014.12.013)
- Pecoraro et al. (2019). Predicting Skin Permeability by Means of Computational Approaches: Reliability and Caveats in Pharmaceutical Studies. *Journal of chemical information and modeling*, — **63 cites** [doi:10.1021/acs.jcim.8b00934](https://doi.org/10.1021/acs.jcim.8b00934)

### 3.2 Formulation optimization by ML (18 papers)
Using ML/DoE to optimize transdermal formulations, patches, nanocarriers, and process parameters — often coupling experimental screening with predictive surrogates.
- Gormley (2024). Machine learning in drug delivery. *Journal of Controlled Release*, — **73 cites** [doi:10.1016/j.jconrel.2024.06.045](https://doi.org/10.1016/j.jconrel.2024.06.045)
- Lefnaoui et al. (2020). Artificial neural network for modeling formulation and drug permeation of topical patches containing diclofenac sodium. *Drug delivery and translational research*, — **31 cites** [doi:10.1007/s13346-019-00671-w](https://doi.org/10.1007/s13346-019-00671-w)
- Salma et al. (2021). Efficient Prediction of In Vitro Piroxicam Release and Diffusion From Topical Films Based on Biopolymers Using Deep Learning Models and Generative Adversarial Networks. *Journal of pharmaceutical sciences*, — **25 cites** [doi:10.1016/j.xphs.2021.01.032](https://doi.org/10.1016/j.xphs.2021.01.032)
- Suriyaamporn et al. (2024). The artificial intelligence and design of experiment assisted in the development of progesterone-loaded solid-lipid nanoparticles for transdermal drug delivery. *Pharmacia*, — **22 cites** [doi:10.3897/pharmacia.71.e123549](https://doi.org/10.3897/pharmacia.71.e123549)

### 3.3 Microneedle ML permeation — *the group's home cluster (17 papers)*
Directly predicting drug transport through microneedle-treated skin, and ML-assisted microneedle design/application. This is where Yuan (2023) sits.
- Xue et al. (2022). Artificial Intelligence-Assisted Bioinformatics, Microneedle, and Diabetic Wound Healing: A "New Deal" of an Old Drug. *ACS applied materials & interfaces*, — **58 cites** [doi:10.1021/acsami.2c08994](https://doi.org/10.1021/acsami.2c08994)
- Bagde et al. (2023). Biphasic burst and sustained transdermal delivery in vivo using an AI-optimized 3D-printed MN patch. *International journal of pharmaceutics*, — **49 cites** [doi:10.1016/j.ijpharm.2023.122647](https://doi.org/10.1016/j.ijpharm.2023.122647)
- Albayati et al. (2025). AI-Driven Innovation in Skin Kinetics for Transdermal Drug Delivery: Overcoming Barriers and Enhancing Precision. *Pharmaceutics*, — **41 cites** [doi:10.3390/pharmaceutics17020188](https://doi.org/10.3390/pharmaceutics17020188)
- Abdallah et al. (2024). Predictive modeling of skin permeability for molecules: Investigating FDA-approved drug permeability with various AI algorithms. *PLOS digital health*, — **36 cites** [doi:10.1371/journal.pdig.0000483](https://doi.org/10.1371/journal.pdig.0000483)
- Yuan et al. (2023). Prediction of drug permeation through microneedled skin by machine learning. *Bioengineering &amp; Translational Medicine*, — **35 cites** [doi:10.1002/btm2.10512](https://doi.org/10.1002/btm2.10512)
- Han et al. (2025). On-patient medical record and mRNA therapeutics using intradermal microneedles. *Nature materials*, — **33 cites** [doi:10.1038/s41563-024-02115-4](https://doi.org/10.1038/s41563-024-02115-4)

### 3.4 Molecular dynamics of skin (14 papers)
Atomistic/coarse-grained simulation of the stratum-corneum lipid matrix to compute permeation free-energy profiles from first principles. Dominated by the Lundborg–Lindahl–Norlén (Stockholm) group.
- Lundborg et al. (2018). Predicting drug permeability through skin using molecular dynamics simulation. *Journal of controlled release : official journal of the Controlled Release Society*, — **123 cites** [doi:10.1016/j.jconrel.2018.05.026](https://doi.org/10.1016/j.jconrel.2018.05.026)
- Lundborg et al. (2018). Human skin barrier structure and function analyzed by cryo-EM and molecular dynamics simulation. *Journal of structural biology*, — **74 cites** [doi:10.1016/j.jsb.2018.04.005](https://doi.org/10.1016/j.jsb.2018.04.005)
- Chen et al. (2015). In silico prediction of percutaneous absorption and disposition kinetics of chemicals. *Pharmaceutical research*, — **51 cites** [doi:10.1007/s11095-014-1575-0](https://doi.org/10.1007/s11095-014-1575-0)
- Chen et al. (2016). In Silico Modelling of Transdermal and Systemic Kinetics of Topically Applied Solutes: Model Development and Initial Validation for Transdermal Nicotine. *Pharmaceutical research*, — **36 cites** [doi:10.1007/s11095-016-1900-x](https://doi.org/10.1007/s11095-016-1900-x)
- Wennberg et al. (2023). Understanding Drug Skin Permeation Enhancers Using Molecular Dynamics Simulations. *Journal of chemical information and modeling*, — **23 cites** [doi:10.1021/acs.jcim.3c00625](https://doi.org/10.1021/acs.jcim.3c00625)

### 3.5 Microneedle design & finite-element simulation (8 papers)
Mechanical/insertion modeling and FEM co-design of microneedle geometry — the physics complement to the data-driven permeation work.
- Sarabi et al. (2022). Machine Learning-Enabled Prediction of 3D-Printed Microneedle Features. *Biosensors*, — **76 cites** [doi:10.3390/bios12070491](https://doi.org/10.3390/bios12070491)
- Abdullah et al. (2024). Optimizing Solid Microneedle Design: A Comprehensive ML-Augmented DOE Approach. *ACS measurement science au*, — **32 cites** [doi:10.1021/acsmeasuresciau.4c00021](https://doi.org/10.1021/acsmeasuresciau.4c00021)
- Tarar et al. (2023). Machine Learning-Enabled Optimization of Interstitial Fluid Collection via a Sweeping Microneedle Design. *ACS omega*, — **26 cites** [doi:10.1021/acsomega.3c01744](https://doi.org/10.1021/acsomega.3c01744)
- Yan et al. (2025). Machine Learning-Driven Optimization of Therapeutic Substance Composition for High-Hardness, Fast-Dissolving Microneedles for Androgenetic Alopecia Treatment. *ACS nano*, — **10 cites** [doi:10.1021/acsnano.5c05505](https://doi.org/10.1021/acsnano.5c05505)

*Smaller clusters:* nanoparticle dermal delivery with ML (7), reviews/perspectives (3), and physical-enhancement modeling (1).

---

## 4. Methods landscape

The modeling toolkit splits into two camps: **data-driven ML** (tree ensembles/XGBoost/RF — the approach in Yuan 2023 — QSAR/QSPR, and neural networks together account for the majority of papers) and **physics-based simulation** (molecular dynamics and finite-element analysis). Tree ensembles and mixed-ML pipelines are the single most common approach, closely followed by classical QSAR/QSPR. Deep learning is rising but not yet dominant; generative AI is just appearing (2 papers, both 2025+). See Figure 2b.

---

## 5. Who and where

**Most active author groups (by in-scope paper count):**
- Guoping Lian — 6 papers
- Phuvamin Suriyaamporn — 5 papers
- Boonnada Pamornpathomkul — 5 papers
- Tanasait Ngawhirunpat — 5 papers
- Praneet Opanasopit — 5 papers
- Magnus Lundborg — 5 papers
- Erik Lindahl — 5 papers
- Lars Norlén — 5 papers

Three research clusters stand out:
- **Silpakorn University (Thailand)** — Opanasopit, Ngawhirunpat, Pamornpathomkul, Suriyaamporn: microneedle + AI-driven patch design and formulation.
- **Stockholm (KTH/Karolinska)** — Lundborg, Lindahl, Norlén: molecular-dynamics skin-permeation simulation (the most-cited methodological line).
- **University of Surrey** — Lian, Chen: mechanistic + ML skin-permeability modeling and PBK dermal exposure.

**Leading venues:**
- *International journal of pharmaceutics* — 9 papers
- *International Journal of Drug Delivery Technology* — 6 papers
- *Pharmaceutical research* — 6 papers
- *Pharmaceutics* — 4 papers
- *Journal of controlled release : official journal of the Controlled Release Society* — 3 papers
- *Journal of chemical information and modeling* — 3 papers
- *Journal of Drug Delivery and Therapeutics* — 2 papers
- *Journal of Drug Targeting* — 2 papers

*International Journal of Pharmaceutics*, *Pharmaceutical Research*, and *Pharmaceutics* are the core homes; *Journal of Controlled Release* and *Journal of Chemical Information and Modeling* carry the higher-impact methodological work.

---

## 6. Research frontier (2025–2026) and open gaps

The newest work (52 papers from 2025–26) points where the field is heading:
- **AI-integrated "smart" microneedles** — patches coupling ML with wearable sensing, closed-loop dosing, and theranostics (e.g., Suriyaamporn 2025 on AI-driven hydrogel microneedle patches; 3D-printed microneedles + wearables).
- **AI for skin kinetics & transdermal systems** — perspective and framework papers on embedding ML across the transdermal-delivery pipeline (Albayati 2025; Sabbagh 2025).
- **First-principles permeation** — atomistic stratum-corneum models and MD of ionizable-molecule permeation (Stockholm group).
- **FEM-guided microneedle co-design** — coupling mechanical simulation with delivery objectives.

**Gaps a microneedle-ML project could target:**
1. **Data scarcity & standardization.** Microneedle-permeation ML (Yuan's cluster) is one of the *smaller* modeling clusters (17 papers) despite microneedles being a major delivery route — public, standardized microneedle-permeation datasets barely exist. Curating one would be high-value.
2. **Bridging QSAR and microneedle models.** The large intact-skin QSAR literature (48 papers) and the microneedle literature are largely separate; transfer learning from log-*Kp* models to microneedle-perturbed skin is under-explored.
3. **Physics-ML hybrids.** MD-derived free energies and FEM insertion mechanics are rarely fed as features into permeation ML — a natural integration point.
4. **Generative & foundation models** are nearly absent (2 papers) — inverse design of microneedle geometry/formulation for a target flux is open territory.

---

*Corpus and analysis: Crossref + PubMed, 2015–2026, 116 curated in-scope papers. Full bibliography with DOIs, themes, methods, and citation counts in `microneedle_ml_literature.csv`.*
