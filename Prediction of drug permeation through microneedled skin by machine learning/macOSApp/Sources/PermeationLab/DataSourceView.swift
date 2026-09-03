import Charts
import AppKit
import SwiftUI

struct DataSourceView: View {
    let language: AppLanguage
    @ObservedObject var dataStore: AppDatasetStore
    let importAction: () -> Void

    @State private var selectedDrug: Drug = .bsa
    @State private var selectedSkin: SkinType = .rat
    @State private var outcome: Outcome = .amount
    @State private var selectedRowID: Int?
    @State private var copiedRowID: Int?

    private var rows: [TrainingDataRow] { dataStore.dataset.rows }
    private var audit: DatasetAudit { dataStore.dataset.audit }

    private var filteredRows: [TrainingDataRow] {
        rows.filter { $0.drug == selectedDrug && $0.skin == selectedSkin }
    }

    private var references: [String] {
        rows.map(\.reference).filter { !$0.isEmpty }.reduce(into: []) { result, reference in
            if !result.contains(reference) {
                result.append(reference)
            }
        }
    }

    private var observedRange: ClosedRange<Double>? {
        let values = filteredRows.map { $0.value(for: outcome) }
        guard let minimum = values.min(), let maximum = values.max() else { return nil }
        return minimum...maximum
    }

    private var selectedRow: TrainingDataRow? {
        filteredRows.first(where: { $0.id == selectedRowID }) ?? filteredRows.first
    }

    var body: some View {
        Group {
            if dataStore.mode == .myExperiment, rows.isEmpty {
                emptyPersonalDataView
            } else {
                populatedDataView
            }
        }
        .accessibilityIdentifier("screen.data-source")
    }

    private var emptyPersonalDataView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                LabWorkspaceHeader(
                    title: language.text("実測データ", "Observed data"),
                    subtitle: language.text(
                        "自分の研究CSVを、確認済み事実とは別に確認する",
                        "Review your experiment CSV separately from paper data"
                    ),
                    systemImage: "point.3.connected.trianglepath.dotted"
                )

                ContentUnavailableView {
                    Label(
                        language.text("実験データ未読込", "No experiment dataset loaded"),
                        systemImage: "tray.and.arrow.down.fill"
                    )
                } description: {
                    Text(language.text(
                        "現在は論文Data S1へフォールバックしていません。11列のCSVを読み込むと、未検証の個人データとして探索できます。",
                        "Paper Data S1 is not used as a fallback. Import an 11-column CSV to explore it as unvalidated personal data."
                    ))
                } actions: {
                    Button(action: importAction) {
                        Label(
                            language.text("実験CSVを読み込む", "Import experiment CSV"),
                            systemImage: "square.and.arrow.down"
                        )
                    }
                    .buttonStyle(.borderedProminent)
                    .accessibilityIdentifier("data.import-experiment-data")
                }
                .frame(maxWidth: .infinity, minHeight: 380)
                .accessibilityIdentifier("data.empty-personal")
            }
            .frame(maxWidth: LabTheme.contentWidth, alignment: .leading)
            .padding(LabTheme.pagePadding)
            .frame(maxWidth: .infinity, alignment: .top)
        }
    }

    private var populatedDataView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                LabWorkspaceHeader(
                    title: language.text("実測データ", "Observed data"),
                    subtitle: language.text(
                        "現在のデータを、条件を混同せず点として読む",
                        "Explore the current dataset without implying a fitted curve"
                    ),
                    systemImage: "point.3.connected.trianglepath.dotted"
                )

                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 220, maximum: 300), spacing: 14)],
                    alignment: .leading,
                    spacing: 14
                ) {
                    LabMetricCard(
                        title: language.text("実測行", "Observations"),
                        value: "\(rows.count)",
                        detail: dataStore.displayName,
                        systemImage: "list.number"
                    )
                    LabMetricCard(
                        title: language.text("薬物", "Drugs"),
                        value: "\(Set(rows.map(\.drug)).count)",
                        detail: language.text("分子・イオン", "Molecules and ion"),
                        systemImage: "pills"
                    )
                    LabMetricCard(
                        title: language.text("列", "Columns"),
                        value: "\(audit.columnCount)",
                        detail: language.text("7特徴量 + 2結果 + 出典", "7 features + 2 outcomes + source"),
                        systemImage: "rectangle.split.3x1"
                    )
                    LabMetricCard(
                        title: language.text("解析エラー", "Parse errors"),
                        value: "\(audit.parseErrors.count)",
                        detail: audit.isValid
                            ? language.text("スキーマ検証済み", "Schema checks passed")
                            : language.text("要確認", "Review required"),
                        systemImage: audit.isValid ? "checkmark.seal" : "exclamationmark.triangle"
                    )
                }

                LabSection(language.text("実測点エクスプローラ", "Observation explorer")) {
                    VStack(alignment: .leading, spacing: 18) {
                        LazyVGrid(
                            columns: [GridItem(.adaptive(minimum: 190), spacing: 18)],
                            alignment: .leading,
                            spacing: 14
                        ) {
                            field(language.text("薬物", "Drug")) {
                                Picker(
                                    language.text("薬物", "Drug"),
                                    selection: $selectedDrug
                                ) {
                                    ForEach(Drug.allCases) { drug in
                                        Text(drug.displayName(language)).tag(drug)
                                    }
                                }
                                .labelsHidden()
                                .pickerStyle(.menu)
                                .accessibilityIdentifier("data.drug-picker")
                            }

                            field(language.text("皮膚", "Skin")) {
                                Picker(
                                    language.text("皮膚", "Skin"),
                                    selection: $selectedSkin
                                ) {
                                    ForEach(SkinType.allCases) { skin in
                                        Text(skin.displayName(language))
                                            .tag(skin)
                                            .disabled(!rows.contains { $0.drug == selectedDrug && $0.skin == skin })
                                    }
                                }
                                .labelsHidden()
                                .pickerStyle(.segmented)
                                .accessibilityIdentifier("data.skin-picker")
                            }

                            field(language.text("結果", "Outcome")) {
                                Picker(
                                    language.text("結果", "Outcome"),
                                    selection: $outcome
                                ) {
                                    ForEach(Outcome.allCases) { item in
                                        Text(item.displayName(language)).tag(item)
                                    }
                                }
                                .labelsHidden()
                                .pickerStyle(.menu)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .accessibilityIdentifier("data.outcome-picker")
                            }
                        }

                        Divider()

                        if filteredRows.isEmpty {
                            ContentUnavailableView(
                                language.text("該当データなし", "No matching observations"),
                                systemImage: "chart.xyaxis.line",
                                description: Text(
                                    language.text(
                                        "この薬物と皮膚の組み合わせは現在のデータにありません。",
                                        "This drug/skin combination is not present in the current dataset."
                                    )
                                )
                            )
                            .frame(minHeight: 300)
                        } else if let selectedRow {
                            ViewThatFits(in: .horizontal) {
                                HStack(alignment: .top, spacing: 18) {
                                    observationPlot(selectedRow: selectedRow)
                                        .frame(width: 500)
                                    observationCodePanel(row: selectedRow)
                                        .frame(width: 380)
                                }
                                .overlay(alignment: .topLeading) {
                                    observationLayoutMarker(
                                        identifier: "data.observation-layout.horizontal",
                                        label: "Side-by-side observation layout"
                                    )
                                }

                                VStack(alignment: .leading, spacing: 18) {
                                    observationPlot(selectedRow: selectedRow)
                                    observationCodePanel(row: selectedRow)
                                }
                                .overlay(alignment: .topLeading) {
                                    observationLayoutMarker(
                                        identifier: "data.observation-layout.vertical",
                                        label: "Stacked observation layout"
                                    )
                                }
                            }
                        }
                    }
                }

                LabSection(language.text("データ完全性監査", "Data integrity audit")) {
                    VStack(alignment: .leading, spacing: 14) {
                        auditRow(
                            title: language.text("入力データ検証", "Input data validation"),
                            value: rows.isEmpty
                                ? language.text("実験データ未読込", "No experiment data loaded")
                                : dataStore.isBundledData
                                    ? language.text("Data S1・191行", "Data S1 · 191 rows")
                                    : language.text("自分のCSV・\(rows.count)行", "My CSV · \(rows.count) rows"),
                            passed: audit.isValid && !rows.isEmpty
                        )
                        auditRow(
                            title: language.text("カテゴリコード", "Category codes"),
                            value: language.text("skin/MNとも無効値0", "0 invalid skin or MN codes"),
                            passed: audit.parseErrors.isEmpty
                        )
                        auditRow(
                            title: language.text("量 = loading × 率 / 100", "amount = loading × percentage / 100"),
                            value: language.text(
                                "最大絶対差 \(audit.maxAmountPercentageResidual.formatted(.number.precision(.significantDigits(4))))",
                                "max absolute residual \(audit.maxAmountPercentageResidual.formatted(.number.precision(.significantDigits(4))))"
                            ),
                            passed: audit.maxAmountPercentageResidual < 0.0001
                        )
                        auditRow(
                            title: language.text("100%超の透過率", "Permeation percentage above 100%"),
                            value: language.text("\(audit.percentageAbove100Count)点", "\(audit.percentageAbove100Count) points"),
                            passed: audit.percentageAbove100Count == 0,
                            symbol: audit.percentageAbove100Count == 0 ? nil : "exclamationmark.triangle.fill"
                        )

                        Text(
                            language.text(
                                "100%超の値も削除や上限クリップをせず、そのまま表示します。",
                                "Values above 100% are displayed as supplied without deletion or silent clipping."
                            )
                        )
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    }
                }

                LabSection(language.text("収録範囲", "Observed ranges")) {
                    LazyVGrid(
                        columns: [GridItem(.adaptive(minimum: 220), spacing: 12)],
                        alignment: .leading,
                        spacing: 12
                    ) {
                        rangeTile(language.text("薬物負荷量", "Drug loading"), rangeText(audit.loadingRange, unit: "µg"))
                        rangeTile(language.text("分子量", "Molecular weight"), rangeText(audit.molecularWeightRange, unit: "Da"))
                        rangeTile(language.text("MN長", "MN length"), rangeText(audit.needleLengthRange, unit: "mm"))
                        rangeTile(language.text("MN表面積", "MN surface area"), rangeText(audit.surfaceAreaRange, unit: "mm²"))
                        rangeTile(language.text("透過時間", "Permeation time"), rangeText(audit.permeationTimeRange, unit: "h"))
                        rangeTile(language.text("透過率", "Permeation percentage"), rangeText(audit.percentageRange, unit: "%"))
                        rangeTile(language.text("透過量", "Permeation amount"), rangeText(audit.amountRange, unit: "µg/cm²"))
                    }
                }

                dataPreview

                LabSection(language.text("現在のデータに記載された実験出典", "Experimental sources in the current data")) {
                    VStack(alignment: .leading, spacing: 12) {
                        if references.isEmpty {
                            Text(language.text(
                                "References列に出典が記録されていません。",
                                "No provenance is recorded in the References column."
                            ))
                            .foregroundStyle(.secondary)
                        } else {
                            ForEach(Array(references.enumerated()), id: \.offset) { index, reference in
                                HStack(alignment: .top, spacing: 10) {
                                    Text("\(index + 1).")
                                        .foregroundStyle(.secondary)
                                        .monospacedDigit()
                                    Text(reference)
                                        .font(.callout)
                                        .textSelection(.enabled)
                                }
                            }
                        }
                    }
                }

                if dataStore.mode == .paperEvidence {
                    LabSection(language.text("同梱Data S1と原著の一次ソース", "Primary sources for the bundled Data S1 and paper")) {
                        HStack(spacing: 18) {
                            Link(
                                language.text("PubMed Central全文", "PubMed Central full text"),
                                destination: URL(string: "https://pmc.ncbi.nlm.nih.gov/articles/PMC10658566/")!
                            )
                            Link(
                                language.text("PubMed 38023708", "PubMed 38023708"),
                                destination: URL(string: "https://pubmed.ncbi.nlm.nih.gov/38023708/")!
                            )
                        }
                    }
                } else {
                    LabNotice(
                        title: language.text("個人データの出典を記録", "Record provenance for personal data"),
                        message: language.text(
                            "このCSVのReferences列が自分の研究データの出典です。原著リンクやData S1を個人データの根拠として自動付与しません。",
                            "The References column in this CSV is the provenance for My Research. Paper links and Data S1 are never attached automatically as support for personal data."
                        ),
                        kind: .warning
                    )
                }
            }
            .frame(maxWidth: LabTheme.contentWidth, alignment: .leading)
            .padding(LabTheme.pagePadding)
            .frame(maxWidth: .infinity, alignment: .top)
        }
        .onChange(of: selectedDrug) { _, newDrug in
            if !rows.contains(where: { $0.drug == newDrug && $0.skin == selectedSkin }),
               let available = rows.first(where: { $0.drug == newDrug })?.skin {
                selectedSkin = available
            }
            selectedRowID = nil
            copiedRowID = nil
        }
        .onChange(of: selectedSkin) { _, _ in
            selectedRowID = nil
            copiedRowID = nil
        }
        .onChange(of: dataStore.revision) { _, _ in
            guard let first = rows.first else { return }
            selectedDrug = first.drug
            selectedSkin = first.skin
            selectedRowID = nil
            copiedRowID = nil
        }
    }

    private func observationPlot(selectedRow: TrainingDataRow) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline) {
                Text(language.text("既存の実測フィギュア", "Existing observed-data figure"))
                    .font(.headline)
                Spacer(minLength: 8)
                Text(language.text("選択点 #\(selectedRow.id)", "Selected #\(selectedRow.id)"))
                    .font(.caption.bold().monospacedDigit())
                    .foregroundStyle(.tint)
            }

            Chart {
                if outcome == .percentage {
                    RuleMark(y: .value("100 percent", 100))
                        .foregroundStyle(.orange.opacity(0.6))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 4]))
                }

                ForEach(filteredRows) { row in
                    PointMark(
                        x: .value("Time", row.permeationTime),
                        y: .value("Observed", row.value(for: outcome))
                    )
                    .foregroundStyle(by: .value("MN", row.needle.displayName(language)))
                    .symbol(by: .value("MN", row.needle.displayName(language)))
                    .symbolSize(70)
                    .opacity(row.id == selectedRow.id ? 1 : 0.68)
                }

                PointMark(
                    x: .value("Selected time", selectedRow.permeationTime),
                    y: .value("Selected observation", selectedRow.value(for: outcome))
                )
                .foregroundStyle(Color.accentColor)
                .symbol(.circle)
                .symbolSize(180)
            }
            .chartXAxisLabel(language.text("透過時間 (h)", "Permeation time (h)"))
            .chartYAxisLabel(outcome.axisTitle(language))
            .chartLegend(position: .top, alignment: .leading)
            .frame(height: 360)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(
                language.text(
                    "選択した薬物と皮膚の実測値散布図。観測 #\(selectedRow.id) を強調表示。",
                    "Scatter plot of observations for the selected drug and skin, highlighting observation #\(selectedRow.id)."
                )
            )
            .accessibilityIdentifier("data.observation-figure")

            HStack(spacing: 18) {
                Label(
                    language.text("\(filteredRows.count)点", "\(filteredRows.count) points"),
                    systemImage: "circle.grid.cross"
                )
                if let observedRange {
                    Label(
                        language.text("範囲", "Range") + ": "
                            + observedRange.lowerBound.formatted(.number.precision(.fractionLength(2)))
                            + "–"
                            + observedRange.upperBound.formatted(.number.precision(.fractionLength(2)))
                            + " " + outcome.unit,
                        systemImage: "arrow.left.and.right"
                    )
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            LabNotice(
                title: language.text("散布図の読み方", "How to read this plot"),
                message: language.text(
                    "同じ薬物・皮膚でも、drug loading、MN長、表面積、MNタイプが異なる点を含みます。点を線で結ぶと単一の時間曲線に見えてしまうため、実測点だけを表示しています。隣（狭幅では下）のJSONは強調した1点の全11列です。",
                    "Even within one drug and skin, points can differ in loading, MN length, surface area, and MN type. Only points are shown because connecting them would falsely imply a single time-course experiment. The JSON beside it (or below at narrow widths) contains all 11 columns for the highlighted point."
                ),
                kind: .information
            )
        }
    }

    private func observationCodePanel(row: TrainingDataRow) -> some View {
        let json = ExperimentalRecordCode.json(for: row)

        return VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(language.text("実験データをコードで読む", "Read the experiment as code"))
                        .font(.headline)
                    Text(dataStore.displayName + " · #\(row.id)")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
                Button {
                    copyJSON(json, rowID: row.id)
                } label: {
                    Label(
                        copiedRowID == row.id
                            ? language.text("コピー済み", "Copied")
                            : language.text("JSONをコピー", "Copy JSON"),
                        systemImage: copiedRowID == row.id ? "checkmark" : "doc.on.doc"
                    )
                }
                .buttonStyle(.borderless)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(
                    copiedRowID == row.id
                        ? language.text("コピー済み", "Copied")
                        : language.text("JSONをコピー", "Copy JSON")
                )
                .accessibilityIdentifier("data.copy-observation-json")
            }

            observationNavigator(row: row)

            Text(
                language.text(
                    "#は現在のCSVでヘッダーを除いた1始まりの行番号です。公開された実験IDやseries IDではありません。",
                    "# is the one-based row number after the header in the current CSV, not a released experiment or series identifier."
                )
            )
            .font(.caption2)
            .foregroundStyle(.secondary)

            Text(ExperimentalRecordCode.summary(for: row, language: language))
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("data.observation-summary")

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label("JSON", systemImage: "curlybraces")
                        .font(.caption.bold())
                    Spacer()
                    Text(language.text("原列名・数値は丸めず表示", "Source keys · unrounded values"))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                ScrollView(.horizontal) {
                    Text(json)
                        .font(.system(.caption, design: .monospaced))
                        .textSelection(.enabled)
                        .padding(12)
                        .accessibilityIdentifier("data.observation-json")
                }
                .background(Color.primary.opacity(0.045), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
            }

            Divider()

                VStack(alignment: .leading, spacing: 0) {
                    Label(
                        language.text("11列の意味と現在値", "Meaning and current value of all 11 fields"),
                        systemImage: "text.book.closed"
                    )
                    .font(.subheadline.bold())
                    .accessibilityIdentifier("data.observation-field-guide")

                    ForEach(Array(ExperimentalDataField.allCases.enumerated()), id: \.element.id) { index, field in
                        fieldExplanation(field, row: row)
                        if index < ExperimentalDataField.allCases.count - 1 {
                            Divider()
                        }
                    }
                }
        }
        .padding(14)
        .background(Color.secondary.opacity(0.055), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .background {
            Color.clear
                .allowsHitTesting(false)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(language.text("実験データのコードパネル", "Experiment data code panel"))
                .accessibilityIdentifier("data.observation-code-panel")
        }
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.accentColor.opacity(0.16), lineWidth: 1)
        }
    }

    private func observationLayoutMarker(identifier: String, label: String) -> some View {
        Color.clear
            .frame(width: 1, height: 1)
            .allowsHitTesting(false)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(label)
            .accessibilityIdentifier(identifier)
    }

    private func observationNavigator(row: TrainingDataRow) -> some View {
        let index = filteredRows.firstIndex(where: { $0.id == row.id }) ?? 0

        return HStack(spacing: 8) {
            Button {
                selectObservation(at: index - 1)
            } label: {
                Image(systemName: "chevron.left")
            }
        .disabled(index == 0)
        .help(language.text("前の観測", "Previous observation"))
        .accessibilityLabel(language.text("前の観測", "Previous observation"))
        .accessibilityIdentifier("data.previous-observation")

            observationPicker(row: row)

            Button {
                selectObservation(at: index + 1)
            } label: {
                Image(systemName: "chevron.right")
            }
        .disabled(index >= filteredRows.count - 1)
        .help(language.text("次の観測", "Next observation"))
        .accessibilityLabel(language.text("次の観測", "Next observation"))
        .accessibilityIdentifier("data.next-observation")
        }
    }

    private func observationPicker(row: TrainingDataRow) -> some View {
        let selection = Binding<Int>(
            get: { row.id },
            set: { newID in
                selectedRowID = newID
                copiedRowID = nil
            }
        )

        return Picker(language.text("観測", "Observation"), selection: selection) {
            ForEach(filteredRows) { candidate in
                Text(observationLabel(candidate))
                    .tag(candidate.id)
            }
        }
        .labelsHidden()
        .pickerStyle(.menu)
        .frame(maxWidth: .infinity)
        .accessibilityIdentifier("data.observation-picker")
    }

    private func observationLabel(_ row: TrainingDataRow) -> String {
        let time = ExperimentalRecordCode.sourceNumber(row.permeationTime)
        let value = ExperimentalRecordCode.sourceNumber(row.value(for: outcome))
        return "#\(row.id) · \(time) h · \(value) \(outcome.unit)"
    }

    private func fieldExplanation(_ field: ExperimentalDataField, row: TrainingDataRow) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(field.shortLabel.resolve(language))
                    .font(.subheadline.bold())
                Text(field.role.resolve(language))
                    .font(.caption2.bold())
                    .foregroundStyle(.tint)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.accentColor.opacity(0.09), in: Capsule())
            }
            Text(field.displayValue(for: row, language: language))
                .font(.callout.monospacedDigit())
                .textSelection(.enabled)
            Text(field.meaning.resolve(language))
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Text(field.sourceHeader)
                .font(.caption2.monospaced())
                .foregroundStyle(.tertiary)
                .textSelection(.enabled)
        }
        .padding(.vertical, 9)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("data.field.\(field.rawValue)")
    }

    private func selectObservation(at index: Int) {
        guard filteredRows.indices.contains(index) else { return }
        selectedRowID = filteredRows[index].id
        copiedRowID = nil
    }

    private func copyJSON(_ json: String, rowID: Int) {
        NSPasteboard.general.clearContents()
        if NSPasteboard.general.setString(json, forType: .string) {
            copiedRowID = rowID
        }
    }

    private var dataPreview: some View {
        GroupBox {
            ScrollView(.horizontal) {
                Grid(alignment: .leading, horizontalSpacing: 18, verticalSpacing: 10) {
                    GridRow {
                        tableHeader("#")
                        tableHeader(language.text("薬物", "Drug"))
                        tableHeader(language.text("負荷量 µg", "Loading µg"))
                        tableHeader("MW")
                        tableHeader(language.text("MN長", "MN length"))
                        tableHeader(language.text("皮膚", "Skin"))
                        tableHeader(language.text("MNタイプ", "MN type"))
                        tableHeader(language.text("面積 mm²", "Area mm²"))
                        tableHeader(language.text("時間 h", "Time h"))
                        tableHeader(language.text("透過率 %", "Permeation %"))
                        tableHeader(language.text("透過量 µg/cm²", "Amount µg/cm²"))
                    }
                    Divider().gridCellColumns(11)
                    ForEach(rows.prefix(12)) { row in
                        GridRow {
                            tableCell("\(row.id)")
                            tableCell(row.drug.displayName(language))
                            tableCell(number(row.loading, digits: 2))
                            tableCell(number(row.molecularWeight, digits: 2))
                            tableCell(number(row.needleLength, digits: 3))
                            tableCell(row.skin.displayName(language))
                            tableCell(row.needle.displayName(language))
                            tableCell(number(row.surfaceArea, digits: 3))
                            tableCell(number(row.permeationTime, digits: 3))
                            tableCell(number(row.percentage, digits: 3))
                            tableCell(number(row.amount, digits: 3))
                        }
                    }
                }
            }
            .padding(.top, 6)
        } label: {
            HStack {
                Text(language.text("データプレビュー", "Data preview"))
                Spacer()
                Text(language.text("先頭12行 / \(rows.count)行", "First 12 / \(rows.count) rows"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func field<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.bold())
                .foregroundStyle(.secondary)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func auditRow(
        title: String,
        value: String,
        passed: Bool,
        symbol: String? = nil
    ) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Image(systemName: symbol ?? (passed ? "checkmark.circle.fill" : "xmark.circle.fill"))
                .foregroundStyle(passed ? .green : .orange)
                .accessibilityHidden(true)
            Text(title)
            Spacer()
            Text(value)
                .font(.callout.monospacedDigit())
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.trailing)
        }
        .accessibilityElement(children: .combine)
    }

    private func rangeTile(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline.monospacedDigit())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .labCard(radius: 10)
    }

    private func tableHeader(_ value: String) -> some View {
        Text(value)
            .font(.caption.bold())
            .foregroundStyle(.secondary)
            .lineLimit(1)
    }

    private func tableCell(_ value: String) -> some View {
        Text(value)
            .font(.caption.monospacedDigit())
            .lineLimit(1)
    }

    private func number(_ value: Double, digits: Int) -> String {
        value.formatted(
            .number.precision(.fractionLength(0...digits))
        )
    }

    private func rangeText(_ range: ClosedRange<Double>?, unit: String) -> String {
        guard let range else { return "—" }
        return number(range.lowerBound, digits: 4) + "–" + number(range.upperBound, digits: 4) + " " + unit
    }
}

private extension TrainingDataRow {
    func value(for outcome: Outcome) -> Double {
        switch outcome {
        case .amount: amount
        case .percentage: percentage
        }
    }
}
