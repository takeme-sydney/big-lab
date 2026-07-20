[HTML版を開く](hero-illustration-notes.html)

# Hero illustration notes — Curved Corneal Construct Geometry QC

## Asset

- Location: `corneal-geometry-qc/site/index.html` (inline SVG in `#top`)
- Format: hand-authored inline SVG; no raster asset, remote URL, font, or generation service is used
- Status: conceptual illustration / non-measured

## What it depicts

The figure shows a curved corneal-construct cross-section with:

1. a dashed design curve;
2. a deliberately different solid measured curve, labelled as illustrative;
3. radius-target and wall-thickness annotations;
4. a small OCT / surface-scan acquisition glyph; and
5. the workflow `design reference → calibration → registration → metric → human review`.

It is intentionally a workflow diagram, not a scientific figure. Its curves, annotations, and layout do **not** encode an experimental value, a QC threshold, a biological outcome, or an optical / mechanical performance result.

## Why this treatment

The roadmap must work offline from `file://`, make the design-versus-measurement distinction visible before readers reach the methods section, and avoid presenting an AI-generated or portfolio-style visual as evidence. Inline SVG keeps the illustration crisp at mobile and print sizes, allows a local-only build, and provides a `<title>` and `<desc>` for assistive technology.

The visible labels `概念図 / 非実測`, `Conceptual illustration · non-measured`, and `MEASURED CURVE* illustrative deviation` are deliberate scientific-integrity safeguards. Real pilot overlays should replace neither this wording nor this asset until approved raw data, calibration, registration quality review, and PI-authorized interpretation are available.
