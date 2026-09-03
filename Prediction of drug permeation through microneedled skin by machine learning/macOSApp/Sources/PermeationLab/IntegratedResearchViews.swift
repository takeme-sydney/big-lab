import Charts
import SwiftUI

struct PaperReaderView: View {
    let language: AppLanguage

    private let sections: [(BiText, BiText, [BiText])] = [
        (BiText("要旨", "Abstract"), BiText("マイクロニードル処置皮膚を介する薬物透過を、Fickモデル、重回帰、Random Forest、XGBoostで比較した研究です。191点を7:3で無作為分割した原著評価ではXGBoostが最良と報告されました。", "The paper compares Fick modelling, multiple linear regression, Random Forest, and XGBoost for drug permeation through microneedled skin. Under the paper's random 7:3 split of 191 observations, XGBoost was reported as best."), []),
        (BiText("はじめに", "Introduction"), BiText("Franz型拡散セルによるin vitro透過試験は有用ですが、時間、費用、動物・ヒト組織を要します。著者らは既報実験を統合し、設計検討を支援する計算手法を比較しました。", "Franz-cell in-vitro permeation studies are useful but consume time, cost, and animal or human tissue. The authors pooled earlier experiments to compare computational approaches for design support."), []),
        (BiText("方法", "Methods"), BiText("6薬物、ヒト／ラット皮膚、hydrogel／plastic MNの191観測を使用し、皮膚種、MN種、長さ、表面積、搭載量、時間、分子量の7特徴量から累積透過量または透過率を扱いました。", "The dataset contains 191 observations across six drugs, human or rat skin, and hydrogel or plastic microneedles. Seven inputs describe skin, MN type, length, surface area, loading, time, and molecular weight."), [BiText("Fickモデルは2次元有限差分で拡散を表現。", "The Fick model uses a two-dimensional finite-difference scheme."), BiText("統計モデルは行単位の70:30無作為分割で評価。", "Statistical models used a random row-level 70:30 split."), BiText("評価指標はRMSEとR²。", "Evaluation metrics were RMSE and R².")]),
        (BiText("結果", "Results"), BiText("原著Table 4ではXGBoostが両アウトカムで最小RMSE・最大R²でした。Figure 8では、透過量は搭載量と時間、透過率は表面積と時間が主要特徴量と報告されています。", "In Table 4, XGBoost had the lowest RMSE and highest R² for both outcomes. Figure 8 reports loading and time as key for amount, and surface area and time as key for percentage."), []),
        (BiText("考察と結論", "Discussion and conclusion"), BiText("既知薬物と近い条件の補間では有望ですが、薬物を丸ごと除外した補足検証では大きな偏差と負の予測が生じました。対象薬物が学習データに含まれる範囲に用途を限定すべきです。", "The approach is promising for interpolation among represented drugs, but leave-one-drug-out tests showed large deviations and negative predictions. Use should remain limited to settings where the target drug is represented in training."), [])
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                LabWorkspaceHeader(title: language.text("論文リーダー", "Paper reader"), subtitle: language.text("本文構成、書誌情報、研究上の境界を一続きで読む", "Read the paper structure, metadata, and scientific boundaries in one place"), systemImage: "text.book.closed")

                LabSection(language.text("書誌情報", "Bibliographic record")) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Prediction of drug permeation through microneedled skin by machine learning").font(.title2.bold()).textSelection(.enabled)
                        Text("Yunong Yuan, Yiting Han, Chun Wei Yap, Jaspreet S. Kochhar, Hairui Li, Xiaoqiang Xiang, Lifeng Kang")
                        Text("Bioengineering & Translational Medicine · 2023 · 8(6) · e10512").foregroundStyle(.secondary)
                        metadata("DOI", "10.1002/btm2.10512")
                        metadata("PMID", "38023708")
                        metadata("PMCID", "PMC10658566")
                        metadata(language.text("ライセンス", "License"), "CC BY 4.0")
                    }
                }

                ForEach(Array(sections.enumerated()), id: \.offset) { _, section in
                    LabSection(section.0.resolve(language)) {
                        VStack(alignment: .leading, spacing: 10) {
                            Text(section.1.resolve(language)).fixedSize(horizontal: false, vertical: true)
                            ForEach(Array(section.2.enumerated()), id: \.offset) { _, bullet in
                                Label(bullet.resolve(language), systemImage: "circle.fill").font(.callout)
                            }
                        }
                    }
                }

                LabSection(language.text("原著末尾情報", "End matter")) {
                    VStack(alignment: .leading, spacing: 10) {
                        metadata(language.text("研究資金", "Funding"), "China Scholarship Council (202008320366); University of Sydney PCA2019")
                        metadata(language.text("利益相反", "Conflicts"), language.text("著者らは利益相反なしと宣言", "The authors declared no conflicts of interest"))
                        metadata(language.text("データ可用性", "Data availability"), language.text("論文とともに公開された補足資料", "Supporting information published with the article"))
                        metadata("ORCID", "Lifeng Kang · 0000-0002-1676-7607")
                    }
                }

                LabNotice(title: language.text("全文と参考文献", "Full text and references"), message: language.text("原文、参考文献1–51、査読履歴、著者貢献の完全な表記は一次ソースで確認してください。", "Use the primary source for the complete text, references 1–51, peer-review history, and full author-contribution statement."))
                HStack(spacing: 18) {
                    Link(language.text("PMC全文を開く", "Open PMC full text"), destination: URL(string: "https://pmc.ncbi.nlm.nih.gov/articles/PMC10658566/")!)
                    Link(language.text("PubMedを開く", "Open PubMed"), destination: URL(string: "https://pubmed.ncbi.nlm.nih.gov/38023708/")!)
                    Link(language.text("DOIを開く", "Open DOI"), destination: URL(string: "https://doi.org/10.1002/btm2.10512")!)
                }
            }
            .frame(maxWidth: LabTheme.contentWidth, alignment: .leading).padding(LabTheme.pagePadding).frame(maxWidth: .infinity, alignment: .top)
        }
        .accessibilityIdentifier("screen.paper-reader")
    }

    private func metadata(_ key: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(key).font(.caption.bold()).foregroundStyle(.secondary).frame(width: 110, alignment: .leading)
            Text(value).textSelection(.enabled)
        }
    }
}

struct MethodsReferenceView: View {
    let language: AppLanguage

    private let equations: [ResearchEquation] = [
        .init(1, BiText("Fickの第2法則", "Fick's second law"), "∂C/∂t = D(∂²C/∂x² + ∂²C/∂y²)", BiText("Cは濃度、Dは拡散係数。", "C is concentration and D is diffusivity.")),
        .init(2, BiText("累積透過率", "Cumulative percentage"), "percentage = (mₜ / m_total) × 100%", BiText("累積量を総搭載量で割る。", "Cumulative amount divided by total loading.")),
        .init(3, BiText("単回帰", "Simple regression"), "y = kx + b", BiText("応答、傾き、切片。", "Response, slope, and intercept.")),
        .init(4, BiText("重回帰", "Multiple regression"), "y = k₁x₁ + k₂x₂ + … + kₙxₙ + b", BiText("複数特徴量の一次結合。", "A linear combination of multiple features.")),
        .init(5, "XGBoost", "Obj = Σᵢ l(yᵢ, ŷᵢ) + Σₖ Ω(fₖ)", BiText("学習損失と木の複雑度。", "Training loss plus tree complexity.")),
        .init(6, BiText("木の複雑度", "Tree complexity"), "Ω(fₖ) = γT + ½λΣⱼwⱼ²", BiText("葉数と葉スコアを正則化。", "Regularization over leaves and leaf scores.")),
        .init(7, "RMSE", "RMSE = √[(1/n)Σᵢ(yᵢ − ŷᵢ)²]", BiText("小さいほど良い。", "Lower is better.")),
        .init(8, "R²", "R² = 1 − Σᵢ(ŷᵢ − yᵢ)² / Σᵢ(ȳ − yᵢ)²", BiText("1に近いほど良い。", "Closer to one is better.")),
        .init(9, BiText("hydrogel MN表面積", "Hydrogel MN surface area"), "S = πr² + π(Rl + rl)", BiText("円錐台近似。", "Frustum approximation.")),
        .init(10, BiText("plastic MN表面積", "Plastic MN surface area"), "S = 4 × ½a × √((a/2)² + h²)", BiText("正四角錐近似。", "Square-pyramid approximation.")),
        .init(11, BiText("パッチ総表面積", "Patch surface area"), "S_total = S × n", BiText("単一MN表面積×本数。", "Single-MN area multiplied by count."))
    ]

    private let assumptions = [
        BiText("MN形状は挿入後も非圧縮・非分解。", "MN geometry remains incompressible and non-degrading after insertion."),
        BiText("各要素内の濃度は均一で、拡散は2次元。", "Concentration is uniform within each element and diffusion is two-dimensional."),
        BiText("皮膚内拡散係数は一定で、温度影響を無視。", "Skin diffusivity is constant and temperature effects are ignored."),
        BiText("receptor液は攪拌され、界面を閉塞しない。", "The receptor is stirred and the interface does not become occluded."),
        BiText("皮膚厚は全実験で1 mm。", "Skin thickness is 1 mm for all experiments.")
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                LabWorkspaceHeader(title: language.text("方法・数式・表", "Methods, equations & tables"), subtitle: language.text("原著の式(1)–(11)、仮定、入力範囲、学習条件", "Paper Equations (1)–(11), assumptions, ranges, and training settings"), systemImage: "function")
                LabSection(language.text("Fickモデルの5仮定", "Five Fick-model assumptions")) {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(Array(assumptions.enumerated()), id: \.offset) { index, item in Label("\(index + 1). \(item.resolve(language))", systemImage: "checkmark.circle") }
                    }
                }
                LabSection(language.text("原著の全数式", "All numbered equations")) {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 320), spacing: 14)], spacing: 14) {
                        ForEach(equations) { equation in
                            VStack(alignment: .leading, spacing: 9) {
                                Text(language.text("式 (\(equation.number))", "Equation (\(equation.number))")).font(.caption.bold()).foregroundStyle(.tint)
                                Text(equation.title.resolve(language)).font(.headline)
                                Text(equation.expression).font(.system(.body, design: .serif, weight: .medium)).textSelection(.enabled)
                                Text(equation.detail.resolve(language)).font(.caption).foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity, minHeight: 120, alignment: .topLeading).padding(14).labCard(radius: 12)
                        }
                    }
                }
                LabSection(language.text("番号なし計算例", "Unnumbered calculation examples")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("S = 4 × ½ × 0.075 × √((0.075/2)² + 0.7²) = 0.105 mm²").textSelection(.enabled)
                        Text("S_total = 0.105 × 351 = 36.855 mm²").textSelection(.enabled)
                        Text(language.text("式(11)直後の例で、独立した式番号はありません。", "These follow Equation (11) and have no separate equation numbers.")).font(.caption).foregroundStyle(.secondary)
                    }
                }
                ViewThatFits(in: .horizontal) { HStack(alignment: .top, spacing: 16) { parameterTables }; VStack(alignment: .leading, spacing: 16) { parameterTables } }
                LabSection("Table 3 · " + language.text("ハイパーパラメータ", "hyperparameters")) {
                    Grid(alignment: .leading, horizontalSpacing: 26, verticalSpacing: 10) {
                        GridRow { Text(language.text("結果", "Outcome")).bold(); Text("XGBoost").bold(); Text("Random Forest").bold() }
                        Divider().gridCellColumns(3)
                        GridRow { Text(language.text("透過量", "Amount")); Text("depth 4 · eta 0.4 · 100 rounds"); Text("500 trees · mtry 5") }
                        GridRow { Text(language.text("透過率", "Percentage")); Text("depth 3 · eta 0.2 · 45 rounds"); Text("500 trees · mtry 6") }
                    }
                }
                LabNotice(title: "Data S2 · " + language.text("コード境界", "code boundary"), message: language.text("公開Rコードは欠落したtrain/test CSVを読み、Table 4を再計算しません。Cコードには構文欠落があります。アプリは推測補完しません。", "The R code reads missing train/test CSVs and does not recompute Table 4. The C listing contains syntax gaps. This app does not guess missing content."), kind: .limitation)
            }
            .frame(maxWidth: LabTheme.contentWidth, alignment: .leading).padding(LabTheme.pagePadding).frame(maxWidth: .infinity, alignment: .top)
        }
        .accessibilityIdentifier("screen.methods")
    }

    @ViewBuilder private var parameterTables: some View {
        parameterTable("Table 1 · Fick", [("D", "50–1,000 µm²/min"), ("N", "64, 351"), ("L", "700–1,250 µm"), ("t", "15 min–48 h"), ("m", "50–70,940 µg"), ("dx, dy", "2 × 2"), ("dt", "0.00001–0.001 min")])
        parameterTable("Table 2 · ML", [(language.text("皮膚種", "Skin"), language.text("ラット / ヒト", "Rat / human")), (language.text("MN種", "MN type"), language.text("ハイドロゲル / solid（原表記）", "Hydrogel / solid (source wording)")), (language.text("MN長", "MN length"), "0.7–1.25 mm"), (language.text("表面積", "Surface area"), "26.76–36.86 mm²"), (language.text("搭載量", "Loading"), "50–70,940 µg"), (language.text("時間", "Time"), "0.08333–48 h"), (language.text("分子量", "Molecular weight"), "64–66,430 Da")])
        LabNotice(
            title: language.text("Table 2とData S1の差", "Table 2 vs Data S1"),
            message: language.text(
                "Table 2はMN種をhydrogel / solid、分子量範囲を64–66,430 Daと記載します。一方、本文とData S1はhydrogel / plasticで、Data S1の分子量範囲は63.5–66,000 Daです。上表はTable 2を忠実に示し、アプリの再集計はData S1値を使用します。",
                "Table 2 says hydrogel / solid and gives a molecular-weight range of 64–66,430 Da; the text and Data S1 use hydrogel / plastic, while Data S1 spans 63.5–66,000 Da. The table above preserves Table 2, while app recomputations use Data S1 values."
            ),
            kind: .limitation
        )
    }

    private func parameterTable(_ title: String, _ rows: [(String, String)]) -> some View {
        LabSection(title) { Grid(alignment: .leading, horizontalSpacing: 22, verticalSpacing: 8) { ForEach(Array(rows.enumerated()), id: \.offset) { _, row in GridRow { Text(row.0).font(.callout.weight(.medium)); Text(row.1).font(.callout).monospacedDigit() } } } }.frame(maxWidth: .infinity, alignment: .top)
    }
}

struct SkinPermeationView: View {
    let language: AppLanguage
    @ObservedObject var dataStore: AppDatasetStore
    @State private var drug: Drug? = nil
    @State private var skin: SkinType? = nil
    @State private var needle: NeedleType? = nil
    @State private var outcome: Outcome = .percentage
    @State private var mechanism: NeedleType = .hydrogel
    @State private var step = 0

    private var rows: [TrainingDataRow] {
        dataStore.dataset.rows.filter { row in (drug == nil || row.drug == drug) && (skin == nil || row.skin == skin) && (needle == nil || row.needle == needle) }
    }

    private var steps: [BiText] {
        mechanism == .hydrogel ? [
            BiText("薬物含浸hydrogel MNを皮膚へ挿入・留置", "Insert and retain the drug-loaded hydrogel MN"),
            BiText("MNが膨潤し、有限reservoirから放出", "The MN swells and releases from a finite reservoir"),
            BiText("薬物が皮膚膜内をreceptor側へ移行", "Drug moves through the skin toward the receptor"),
            BiText("receptor液を採取し、累積量・率を算出", "Sample receptor fluid and calculate cumulative amount and percentage")
        ] : [
            BiText("plastic MNで皮膚を前処置", "Pretreat the skin with plastic MNs"),
            BiText("MNを除去し、microchannelを残す", "Remove the MNs and leave microchannels"),
            BiText("donor側へ薬物水溶液を添加", "Add drug solution to the donor side"),
            BiText("receptor液を採取し、累積量・率を算出", "Sample receptor fluid and calculate cumulative amount and percentage")
        ]
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                LabWorkspaceHeader(title: language.text("皮膚透過", "Skin permeation"), subtitle: language.text("累積時点観測とFranz-cell概念工程を照合", "Relate cumulative observations to the conceptual Franz-cell workflow"), systemImage: "cross.vial")
                LabNotice(title: language.text("実測値と概念図の境界", "Observation/illustration boundary"), message: language.text("チャートは非連結実測点です。工程は非定量の概念図で、粒子軌跡や皮膚内濃度mapではありません。", "The chart contains unconnected observations. The workflow is non-quantitative, not a particle trajectory or intradermal concentration map."), kind: .limitation)
                LabSection(language.text("フィルター", "Filters")) {
                    VStack(alignment: .leading, spacing: 14) {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 220), spacing: 14)], spacing: 12) {
                            optionalPicker(language.text("薬物", "Drug"), selection: $drug, values: Drug.allCases) { $0.displayName(language) }
                            optionalPicker(language.text("皮膚", "Skin"), selection: $skin, values: SkinType.allCases) { $0.displayName(language) }
                            optionalPicker("MN", selection: $needle, values: NeedleType.allCases) { $0.displayName(language) }
                            filterField(language.text("結果", "Outcome")) {
                                Picker(language.text("結果", "Outcome"), selection: $outcome) {
                                    ForEach(Outcome.allCases) { Text($0.displayName(language)).tag($0) }
                                }
                                .labelsHidden()
                                .pickerStyle(.menu)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }

                        HStack(spacing: 12) {
                            Button(language.text("全て表示", "Show all"), systemImage: "line.3.horizontal.decrease.circle") {
                                drug = nil
                                skin = nil
                                needle = nil
                            }
                            Spacer(minLength: 12)
                            Text(language.text("\(rows.count) / \(dataStore.dataset.rows.count)点", "\(rows.count) / \(dataStore.dataset.rows.count) observations"))
                                .font(.headline.monospacedDigit())
                        }
                    }
                }
                .accessibilityIdentifier("skin-permeation.filters")
                LabSection(language.text("実測散布図", "Observation plot")) {
                    Chart(rows) { row in
                        PointMark(x: .value(language.text("時間 (h)", "Time (h)"), row.permeationTime), y: .value(outcome.axisTitle(language), researchValue(row, outcome)))
                            .foregroundStyle(by: .value(language.text("薬物", "Drug"), row.drug.displayName(language)))
                            .symbol(by: .value("MN", row.needle.displayName(language)))
                    }
                    .chartLegend(position: .bottom, spacing: 12)
                    .frame(height: 390)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(language.text("皮膚透過の実測散布図", "Observed skin-permeation scatter plot"))
                    .accessibilityValue(language.text("\(rows.count)観測", "\(rows.count) observations"))
                    .accessibilityIdentifier("skin-permeation.chart")
                    Text(language.text("series／replicate関係が公開されていないため点間を接続しません。", "Points are not connected because series and replicate relationships were not released.")).font(.caption).foregroundStyle(.secondary)
                }
                LabSection(language.text("Franz-cell 概念工程", "Conceptual Franz-cell workflow")) {
                    VStack(alignment: .leading, spacing: 16) {
                        Picker("MN", selection: $mechanism) { ForEach(NeedleType.allCases) { Text($0.displayName(language)).tag($0) } }.pickerStyle(.segmented).onChange(of: mechanism) { _, _ in step = 0 }
                        HStack(spacing: 8) { ForEach(steps.indices, id: \.self) { index in Capsule().fill(index <= step ? Color.accentColor : Color.secondary.opacity(0.2)).frame(height: 7) } }
                        Label("\(step + 1). \(steps[step].resolve(language))", systemImage: ["syringe", "drop.triangle", "arrow.down.to.line", "testtube.2"][step]).font(.title3.weight(.semibold)).frame(maxWidth: .infinity, minHeight: 90, alignment: .leading).padding(16).labCard()
                        HStack { Button(language.text("前へ", "Previous"), systemImage: "chevron.left") { step = max(0, step - 1) }.disabled(step == 0); Button(language.text("次へ", "Next"), systemImage: "chevron.right") { step = min(steps.count - 1, step + 1) }.disabled(step == steps.count - 1); Spacer(); Button(language.text("リセット", "Reset"), systemImage: "arrow.counterclockwise") { step = 0 } }
                    }
                }
            }
            .frame(maxWidth: LabTheme.contentWidth, alignment: .leading).padding(LabTheme.pagePadding).frame(maxWidth: .infinity, alignment: .top)
        }
        .accessibilityIdentifier("screen.skin-permeation")
    }

    private func optionalPicker<T: Hashable & Identifiable>(_ title: String, selection: Binding<T?>, values: [T], label: @escaping (T) -> String) -> some View {
        filterField(title) {
            Picker(title, selection: selection) {
                Text(language.text("すべて", "All")).tag(Optional<T>.none)
                ForEach(values) { value in Text(label(value)).tag(Optional(value)) }
            }
            .labelsHidden()
            .pickerStyle(.menu)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func filterField<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct ResearchIntegrityView: View {
    let language: AppLanguage
    @ObservedObject var dataStore: AppDatasetStore
    private var audit: DatasetAudit { dataStore.dataset.audit }

    private let reproducibility: [(BiText, BiText, Bool)] = [
        (BiText("Data S1", "Data S1"), BiText("全行・全11列", "All rows and 11 columns"), true),
        (BiText("無作為分割比", "Random split ratio"), BiText("本文に7:3と記載", "Paper states 7:3"), true),
        (BiText("train/test行割当", "Train/test row assignment"), BiText("公開なし", "Not released"), false),
        (BiText("分割生成コード", "Split-generation code"), BiText("公開なし", "Not released"), false),
        (BiText("Data S2コード", "Data S2 code"), BiText("掲載あり・入力CSV欠落", "Published; input CSVs missing"), true),
        (BiText("学習済みモデル", "Trained models"), BiText("係数・forest・booster未公開", "Coefficients, forest, and booster absent"), false),
        (BiText("Table 4", "Table 4"), BiText("転記値・独立再計算不可", "Transcribed; not independently reproducible"), true)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                LabWorkspaceHeader(
                    title: dataStore.mode == .paperEvidence
                        ? language.text("出典・完全性", "Sources & integrity")
                        : language.text("自分の研究監査", "My research audit"),
                    subtitle: dataStore.mode == .paperEvidence
                        ? language.text("一次資料、公開物、再現性の境界", "Primary sources, released artifacts, and reproducibility boundaries")
                        : language.text("自分のCSVだけを対象に、発表可能性の不足を確認", "Audit only the active CSV and identify publication gaps"),
                    systemImage: "checkmark.shield"
                )
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 190), spacing: 14)], spacing: 14) {
                    LabMetricCard(title: language.text("行", "Rows"), value: "\(audit.rowCount)", detail: dataStore.displayName, systemImage: "list.number")
                    LabMetricCard(title: language.text("列", "Columns"), value: "\(audit.columnCount)", detail: language.text("期待値 11", "Expected 11"), systemImage: "rectangle.split.3x1")
                    LabMetricCard(title: language.text("解析エラー", "Parse errors"), value: "\(audit.parseErrors.count)", detail: audit.isValid ? language.text("検証済み", "Validated") : language.text("要確認", "Review needed"), systemImage: audit.isValid ? "checkmark.seal" : "exclamationmark.triangle")
                    LabMetricCard(title: language.text("100%超の行", "Rows above 100%"), value: "\(audit.percentageAbove100Count)", detail: language.text("原値を保持", "Source retained"), systemImage: "exclamationmark.circle")
                }
                LabSection(language.text("決定論的整合性", "Deterministic consistency")) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("amount = loading × percentage / 100").font(.title3.monospaced()).textSelection(.enabled)
                        Text(language.text("最大絶対残差: \(audit.maxAmountPercentageResidual.formatted(.number.precision(.fractionLength(8)))) µg/cm²", "Maximum absolute residual: \(audit.maxAmountPercentageResidual.formatted(.number.precision(.fractionLength(8)))) µg/cm²"))
                        if audit.maxAmountPercentageResidual < 0.0001 {
                            LabNotice(title: language.text("整合", "Consistent"), message: language.text("現在のデータでは透過量と透過率が搭載量を介して丸め誤差内で結ばれ、独立な2アウトカムではありません。", "In the current data, amount and percentage are linked through loading within rounding tolerance and are not independent outcomes."), kind: .limitation)
                        } else {
                            LabNotice(title: language.text("不整合", "Mismatch"), message: language.text("現在のデータは amount = loading × percentage / 100 を許容誤差内で満たしません。量と率を決定的変換として扱う前に、単位・正規化・入力値を確認してください。", "The current data do not satisfy amount = loading × percentage / 100 within tolerance. Check units, normalization, and source values before treating amount and percentage as deterministic transforms."), kind: .warning)
                        }
                    }
                }
                if dataStore.mode == .paperEvidence {
                    LabSection(language.text("再現可能性の境界", "Reproducibility boundary")) {
                        Grid(alignment: .leading, horizontalSpacing: 22, verticalSpacing: 10) {
                            GridRow { Text(language.text("項目", "Item")).bold(); Text(language.text("状態", "Status")).bold(); Text(language.text("判定", "Assessment")).bold() }
                            Divider().gridCellColumns(3)
                            ForEach(Array(reproducibility.enumerated()), id: \.offset) { _, row in
                                GridRow(alignment: .top) { Text(row.0.resolve(language)); Text(row.1.resolve(language)).foregroundStyle(.secondary); Label(row.2 ? language.text("あり", "Present") : language.text("未公開", "Missing"), systemImage: row.2 ? "checkmark.circle.fill" : "minus.circle.fill").foregroundStyle(row.2 ? Color.green : Color.orange) }
                            }
                        }
                    }
                    LabSection(language.text("一次ソース", "Primary sources")) {
                        VStack(alignment: .leading, spacing: 12) {
                            Link("PubMed · PMID 38023708", destination: URL(string: "https://pubmed.ncbi.nlm.nih.gov/38023708/")!)
                            Link("PubMed Central · PMC10658566", destination: URL(string: "https://pmc.ncbi.nlm.nih.gov/articles/PMC10658566/")!)
                            Link("DOI · 10.1002/btm2.10512", destination: URL(string: "https://doi.org/10.1002/btm2.10512")!)
                            Text(language.text("Data S1由来CSVを同梱し、全11列を型付きで検証します。PDF、workbook、Data S2、SI3は上記一次ソースから確認できます。", "The app bundles a Data S1-derived CSV and validates all 11 columns. The PDF, workbook, Data S2, and SI3 can be checked through the primary sources above.")).font(.callout).foregroundStyle(.secondary)
                        }
                    }
                } else {
                    personalResearchBoundary
                }
                LabNotice(title: language.text("利用禁止範囲", "Prohibited use"), message: language.text("診断、治療、処方、投与量、安全性、有効性、患者転帰の判断には使用しないでください。", "Do not use this app for diagnosis, treatment, prescribing, dosing, safety, efficacy, or patient-outcome decisions."), kind: .warning)
            }
            .frame(maxWidth: LabTheme.contentWidth, alignment: .leading).padding(LabTheme.pagePadding).frame(maxWidth: .infinity, alignment: .top)
        }
        .accessibilityIdentifier("screen.integrity")
    }

    private var personalResearchBoundary: some View {
        VStack(alignment: .leading, spacing: 16) {
            LabSection(language.text("発表可能性の必須ゲート", "Publication-readiness gates")) {
                VStack(alignment: .leading, spacing: 12) {
                    integrityGate(
                        title: language.text("11列スキーマ", "11-column schema"),
                        detail: audit.isValid
                            ? language.text("型・有限値の検査に合格", "Types and finite values pass")
                            : language.text("入力エラーあり", "Input errors present"),
                        status: audit.isValid
                    )
                    integrityGate(
                        title: language.text("独立run・curve ID", "Independent run and curve IDs"),
                        detail: language.text("現在の11列スキーマには含まれない", "Absent from the current 11-column schema"),
                        status: false
                    )
                    integrityGate(
                        title: language.text("盲検の外部outcome", "Blinded external outcomes"),
                        detail: language.text("アプリ内CSVだけでは証明できない", "Cannot be established from the in-app CSV"),
                        status: false
                    )
                    integrityGate(
                        title: language.text("片側95%下限 ≥ 0.85", "One-sided 95% lower bound ≥ 0.85"),
                        detail: language.text("独立runの外部評価が必要", "Requires external evaluation of independent runs"),
                        status: false
                    )
                }
            }

            LabNotice(
                title: language.text("論文の出典を自動付与しません", "Paper sources are not attached automatically"),
                message: language.text(
                    "この研究領域の根拠は、読み込んだCSVのReferences列と別途保存するprotocol・run記録です。事実タブの論文リンクは、自分のCSVを支持する出典として流用されません。",
                    "Evidence for this research area comes from the imported CSV's References column and separately retained protocols and run records. Links in Facts are never reused as support for the active CSV."
                ),
                kind: .limitation
            )
        }
        .accessibilityIdentifier("integrity.personal-boundary")
    }

    private func integrityGate(title: String, detail: String, status: Bool) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: status ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundStyle(status ? Color.green : Color.red)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.headline)
                Text(detail)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

private func researchValue(_ row: TrainingDataRow, _ outcome: Outcome) -> Double { outcome == .amount ? row.amount : row.percentage }

private struct ResearchEquation: Identifiable {
    let number: Int
    let title: BiText
    let expression: String
    let detail: BiText
    var id: Int { number }
    init(_ number: Int, _ title: BiText, _ expression: String, _ detail: BiText) { self.number = number; self.title = title; self.expression = expression; self.detail = detail }
    init(_ number: Int, _ title: String, _ expression: String, _ detail: BiText) { self.init(number, BiText(title, title), expression, detail) }
}
