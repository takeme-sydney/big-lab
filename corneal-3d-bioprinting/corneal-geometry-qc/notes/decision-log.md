[HTML版を開く](decision-log.html)

# Decision log

Project: Curved Corneal Construct Geometry QC
Rule: 結果を見た後の変更は、変更前の定義、理由、影響、承認者を残す。

| ID | Date | Status | Decision / change | Evidence | Impact on primary analysis | Owner / approver |
| --- | --- | --- | --- | --- | --- | --- |
| D-001 | 2026-07-19 | proposed | Geometry error、print-process traceability、extended characterizationを別測定対象として設計する | Yuan et al. (2026) 3D Printing Strategies for Bioengineering Human Cornea + docs/contribution-map.md §3–4 | Primary metricをPIと確定するまでGate 2以降をfreezeしない | Takumi / PI review pending |
| D-002 | 2026-07-19 | proposed | Portfolio synthetic demo（`geometry-qc-synthetic.csv`ほか）の数値・閾値をreal pilotの受入基準として転用しない | portfolio/pilot-charter.md §3「demo acceptance rule」の自己申告（実験・臨床閾値ではない） | QC threshold（PASS/REVIEW/FAIL）はGate 0でPI承認のもと新規設定する | Takumi |
