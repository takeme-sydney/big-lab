import Charts
import SwiftUI
import UniformTypeIdentifiers

enum DatasetComparisonMetric: String, CaseIterable, Identifiable, Sendable {
    case loading
    case molecularWeight
    case needleLength
    case surfaceArea
    case permeationTime
    case amount
    case percentage

    var id: Self { self }

    func title(_ language: AppLanguage) -> String {
        switch self {
        case .loading: language.text("薬物負荷量", "Drug loading")
        case .molecularWeight: language.text("分子量", "Molecular weight")
        case .needleLength: language.text("MN長", "MN length")
        case .surfaceArea: language.text("MN表面積", "MN surface area")
        case .permeationTime: language.text("透過時間", "Permeation time")
        case .amount: language.text("透過量", "Permeation amount")
        case .percentage: language.text("透過率", "Permeation percentage")
        }
    }

    var unit: String {
        switch self {
        case .loading: "µg"
        case .molecularWeight: "Da"
        case .needleLength: "mm"
        case .surfaceArea: "mm²"
        case .permeationTime: "h"
        case .amount: "µg/cm²"
        case .percentage: "%"
        }
    }

    func value(for row: TrainingDataRow) -> Double {
        switch self {
        case .loading: row.loading
        case .molecularWeight: row.molecularWeight
        case .needleLength: row.needleLength
        case .surfaceArea: row.surfaceArea
        case .permeationTime: row.permeationTime
        case .amount: row.amount
        case .percentage: row.percentage
        }
    }
}

struct DrugComparisonSummary: Identifiable, Equatable, Sendable {
    let drug: Drug
    let count: Int
    let minimum: Double
    let median: Double
    let maximum: Double

    var id: Drug { drug }

    static func make(rows: [TrainingDataRow], metric: DatasetComparisonMetric) -> [Self] {
        Dictionary(grouping: rows, by: \TrainingDataRow.drug)
            .compactMap { drug, drugRows in
                let values = drugRows.map { metric.value(for: $0) }.sorted()
                guard let minimum = values.first, let maximum = values.last else { return nil }
                let middle = values.count / 2
                let median = values.count.isMultiple(of: 2)
                    ? (values[middle - 1] + values[middle]) / 2
                    : values[middle]
                return Self(
                    drug: drug,
                    count: values.count,
                    minimum: minimum,
                    median: median,
                    maximum: maximum
                )
            }
            .sorted { $0.drug.rawValue < $1.drug.rawValue }
    }
}

enum InputOutcomeTrendMetric: String, CaseIterable, Identifiable, Sendable {
    case loading
    case permeationTime
    case surfaceArea

    var id: Self { self }

    func title(_ language: AppLanguage) -> String {
        switch self {
        case .loading: language.text("薬物充填量", "Drug loading")
        case .permeationTime: language.text("透過時間", "Permeation time")
        case .surfaceArea: language.text("マイクロニードルの表面積", "MN surface area")
        }
    }

    var unit: String {
        switch self {
        case .loading: "µg"
        case .permeationTime: "h"
        case .surfaceArea: "mm²"
        }
    }

    func value(for row: TrainingDataRow) -> Double {
        switch self {
        case .loading: row.loading
        case .permeationTime: row.permeationTime
        case .surfaceArea: row.surfaceArea
        }
    }
}

enum TrendOutcome: String, CaseIterable, Identifiable, Sendable {
    case amount
    case percentage

    var id: Self { self }

    func title(_ language: AppLanguage) -> String {
        switch self {
        case .amount: language.text("累積透過量", "Cumulative permeation amount")
        case .percentage: language.text("累積透過率", "Cumulative permeation percentage")
        }
    }

    var unit: String { self == .amount ? "µg/cm²" : "%" }

    func value(for row: TrainingDataRow) -> Double {
        self == .amount ? row.amount : row.percentage
    }
}

struct InputOutcomeTrendPoint: Identifiable, Equatable, Sendable {
    let drug: Drug
    let input: Double
    let medianOutcome: Double
    let observationCount: Int

    var id: String { "\(drug.rawValue)|\(input)" }

    static func make(
        rows: [TrainingDataRow],
        metric: InputOutcomeTrendMetric,
        outcome: TrendOutcome
    ) -> [Self] {
        Dictionary(grouping: rows, by: { row in
            TrendGroup(drug: row.drug, input: metric.value(for: row))
        })
        .map { group, groupedRows in
            let values = groupedRows.map { outcome.value(for: $0) }.sorted()
            let middle = values.count / 2
            let median = values.count.isMultiple(of: 2)
                ? (values[middle - 1] + values[middle]) / 2
                : values[middle]
            return Self(
                drug: group.drug,
                input: group.input,
                medianOutcome: median,
                observationCount: values.count
            )
        }
        .sorted {
            $0.drug.rawValue == $1.drug.rawValue
                ? $0.input < $1.input
                : $0.drug.rawValue < $1.drug.rawValue
        }
    }

    private struct TrendGroup: Hashable {
        let drug: Drug
        let input: Double
    }
}

struct DatasetImpactView: View {
    let language: AppLanguage
    @ObservedObject var dataStore: AppDatasetStore

    @State private var metric: DatasetComparisonMetric = .needleLength
    @State private var selectedSkin: SkinType?
    @State private var selectedNeedle: NeedleType?
    @State private var trendOutcome: TrendOutcome = .amount
    @State private var isImporting = false
    @State private var errorMessage: String?

    private var allRows: [TrainingDataRow] { dataStore.dataset.rows }

    private var rows: [TrainingDataRow] {
        allRows.filter { row in
            (selectedSkin == nil || row.skin == selectedSkin)
                && (selectedNeedle == nil || row.needle == selectedNeedle)
        }
    }

    private var summaries: [DrugComparisonSummary] {
        DrugComparisonSummary.make(rows: rows, metric: metric)
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 24) {
                LabWorkspaceHeader(
                    title: language.text("データ比較", "Data comparison"),
                    subtitle: language.text(
                        "薬物ごとにMN長、表面積、負荷量、透過結果の違いを同じ尺度で比較",
                        "Compare MN geometry, drug loading, and permeation outcomes across drugs on a shared scale"
                    ),
                    systemImage: "chart.dots.scatter"
                )

                dataActions
                studyComparison
                comparisonControls

                LabSection(language.text("薬物別の分布", "Distribution by drug")) {
                    VStack(alignment: .leading, spacing: 12) {
                        if rows.isEmpty {
                            ContentUnavailableView(
                                language.text("該当データがありません", "No matching observations"),
                                systemImage: "line.3.horizontal.decrease.circle",
                                description: Text(language.text(
                                    "皮膚またはMNフィルターを変更してください。",
                                    "Change the skin or MN filter."
                                ))
                            )
                            .frame(height: 330)
                        } else {
                            Chart(rows) { row in
                                PointMark(
                                    x: .value(language.text("薬物", "Drug"), row.drug.displayName(language)),
                                    y: .value(metric.title(language), metric.value(for: row))
                                )
                                .foregroundStyle(by: .value(
                                    language.text("MNタイプ", "MN type"),
                                    row.needle.displayName(language)
                                ))
                                .symbol(by: .value(
                                    language.text("皮膚", "Skin"),
                                    row.skin.displayName(language)
                                ))
                                .opacity(0.72)
                            }
                            .chartYAxisLabel("\(metric.title(language)) (\(metric.unit))")
                            .chartLegend(position: .bottom, alignment: .leading)
                            .frame(height: 370)
                            .accessibilityElement(children: .ignore)
                            .accessibilityLabel(language.text("薬物別の実測値分布", "Observed-value distribution by drug"))
                            .accessibilityValue(language.text("\(rows.count)観測", "\(rows.count) observations"))
                            .accessibilityIdentifier("comparison.distribution-chart")
                        }

                        Text(language.text(
                            "各点は1観測です。色はMNタイプ、記号は皮膚種を表します。点は系列として接続せず、因果関係や予測値を示しません。",
                            "Each point is one observation. Colour identifies MN type and symbol identifies skin type. Points are not connected as series and do not imply causality or predictions."
                        ))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                }
                .accessibilityIdentifier("comparison.distribution-section")

                inputOutcomeTrends

                summaryTable

                LabNotice(
                    title: language.text("論文正本と比較データは別スロット", "Paper source and comparison data use separate slots"),
                    message: language.text(
                        "Yuan Data S1は変更されません。類似研究CSVは横並び比較だけに使われ、現在の研究CSVとも混在しません。原著画像とTable 4は固定された文献証拠です。",
                        "Yuan Data S1 is immutable. A similar-study CSV is used only for side-by-side comparison and is not mixed with the active My Research CSV. Original figures and Table 4 remain fixed literature evidence."
                    ),
                    kind: .information
                )

                csvRequirements
            }
            .frame(maxWidth: LabTheme.contentWidth, alignment: .leading)
            .padding(LabTheme.pagePadding)
            .frame(maxWidth: .infinity, alignment: .top)
        }
        .fileImporter(
            isPresented: $isImporting,
            allowedContentTypes: [.commaSeparatedText, .plainText]
        ) { result in
            switch result {
            case .success(let url): importCSV(url)
            case .failure(let error):
                if (error as NSError).code != NSUserCancelledError {
                    errorMessage = localizedErrorMessage(error)
                }
            }
        }
        .alert(
            language.text("比較データを読み込めません", "Unable to import comparison data"),
            isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
        .accessibilityIdentifier("screen.dataset-impact")
    }

    private var inputOutcomeTrends: some View {
        LabSection(language.text("入力条件別の結果トレンド", "Outcome trends by input")) {
            LazyVStack(alignment: .leading, spacing: 18) {
                Picker(language.text("表示する結果", "Outcome"), selection: $trendOutcome) {
                    ForEach(TrendOutcome.allCases) { outcome in
                        Text(outcome.title(language)).tag(outcome)
                    }
                }
                .pickerStyle(.segmented)
                .accessibilityIdentifier("comparison.trend-outcome-picker")

                ForEach(InputOutcomeTrendMetric.allCases) { input in
                    trendChartCard(for: input)
                }

                Text(language.text(
                    "各線は薬物別です。同じ薬物・同じ入力値に複数の観測がある場合は結果の中央値を表示し、隣接する観測入力を線で結んでいます。これは実測トレンドであり、他の条件を固定した因果効果やモデル予測ではありません。",
                    "Each line represents one drug. When a drug has multiple observations at the same input value, the chart shows their median outcome and connects adjacent observed inputs. These are observed trends, not model predictions or causal effects with other conditions held constant."
                ))
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .accessibilityIdentifier("comparison.input-outcome-trends")
    }

    private func trendChartCard(for input: InputOutcomeTrendMetric) -> some View {
        let points = InputOutcomeTrendPoint.make(rows: rows, metric: input, outcome: trendOutcome)

        return VStack(alignment: .leading, spacing: 10) {
            Text(input.title(language))
                .font(.headline)

            if points.isEmpty {
                ContentUnavailableView(
                    language.text("該当データがありません", "No matching observations"),
                    systemImage: "chart.xyaxis.line"
                )
                .frame(height: 240)
            } else {
                Chart(points) { point in
                    LineMark(
                        x: .value(input.title(language), point.input),
                        y: .value(trendOutcome.title(language), point.medianOutcome),
                        series: .value(language.text("薬物", "Drug"), point.drug.displayName(language))
                    )
                    .foregroundStyle(by: .value(
                        language.text("薬物", "Drug"),
                        point.drug.displayName(language)
                    ))
                    .interpolationMethod(.linear)

                    PointMark(
                        x: .value(input.title(language), point.input),
                        y: .value(trendOutcome.title(language), point.medianOutcome)
                    )
                    .foregroundStyle(by: .value(
                        language.text("薬物", "Drug"),
                        point.drug.displayName(language)
                    ))
                    .symbol(by: .value(
                        language.text("薬物", "Drug"),
                        point.drug.displayName(language)
                    ))
                }
                .chartXAxisLabel("\(input.title(language)) (\(input.unit))")
                .chartYAxisLabel("\(trendOutcome.title(language)) (\(trendOutcome.unit))")
                .chartLegend(position: .bottom, alignment: .leading)
                .frame(height: 300)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(language.text("\(input.title(language))と結果の実測トレンド", "Observed trend between \(input.title(language)) and outcome"))
                .accessibilityValue(language.text("\(points.count)集計点", "\(points.count) aggregated points"))
                .accessibilityIdentifier("comparison.trend-chart.\(input.rawValue)")
            }
        }
        .padding(16)
        .labCard()
    }

    private var dataActions: some View {
        LabResponsiveActionHeader {
            VStack(alignment: .leading, spacing: 4) {
                Text(language.text("Yuan 2023を基準に研究間比較", "Compare studies against Yuan 2023")).font(.headline)
                Text(language.text(
                    "基準 \(TrainingDataSource.rows.count)行" + (dataStore.comparisonDataset.map { " · 比較 \($0.rows.count)行" } ?? ""),
                    "Baseline \(TrainingDataSource.rows.count) rows" + (dataStore.comparisonDataset.map { " · comparison \($0.rows.count) rows" } ?? "")
                ))
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        } actions: {
            HStack(spacing: 10) {
                if dataStore.comparisonDataset != nil {
                    Button(language.text("比較データを外す", "Remove comparison"), systemImage: "xmark.circle") {
                        dataStore.removeComparison()
                    }
                }

                Button(
                    language.text("類似研究CSVを読み込む", "Import similar-study CSV"),
                    systemImage: "square.and.arrow.down"
                ) {
                    isImporting = true
                }
                .buttonStyle(.borderedProminent)
                .accessibilityIdentifier("impact.import")
            }
        }
        .padding(16)
        .labCard()
        .accessibilityIdentifier("impact.data-actions")
    }

    private var studyComparison: some View {
        LabSection(language.text("Yuanデータとの直接比較", "Direct comparison with Yuan data")) {
            VStack(alignment: .leading, spacing: 16) {
                if let imported = dataStore.comparisonDataset {
                    let baseline = ComparableStudyDataset.yuan
                    let baselineRows = filteredStudyRows(baseline.rows)
                    let importedRows = filteredStudyRows(imported.rows)
                    ViewThatFits(in: .horizontal) {
                        HStack(alignment: .top, spacing: 16) {
                            studyPanel(baseline.name, rows: baselineRows, isBaseline: true)
                            studyPanel(imported.name, rows: importedRows, isBaseline: false)
                        }
                        VStack(alignment: .leading, spacing: 16) {
                            studyPanel(baseline.name, rows: baselineRows, isBaseline: true)
                            studyPanel(imported.name, rows: importedRows, isBaseline: false)
                        }
                    }
                    comparisonSummary(baselineRows: baselineRows, importedRows: importedRows)
                    if !imported.references.isEmpty {
                        Text(language.text("読込データの出典: ", "Imported references: ") + imported.references.joined(separator: " · "))
                            .font(.caption).foregroundStyle(.secondary).textSelection(.enabled)
                    }
                } else {
                    ContentUnavailableView(
                        language.text("比較する研究データを読み込んでください", "Import a study dataset to compare"),
                        systemImage: "doc.badge.plus",
                        description: Text(language.text(
                            "Yuan 2023の191点は変更せず、同じ11列スキーマの別研究を横に並べます。薬物名は原著6種以外でも使用できます。",
                            "Yuan 2023's 191 observations stay unchanged. A second study using the same 11-column schema is shown alongside it, and may contain other drug names."
                        ))
                    )
                    .frame(height: 180)
                }
            }
        }
        .accessibilityIdentifier("comparison.study-section")
    }

    private func filteredStudyRows(_ source: [ComparableStudyRow]) -> [ComparableStudyRow] {
        source.filter { row in
            (selectedSkin == nil || row.skin == selectedSkin)
                && (selectedNeedle == nil || row.needle == selectedNeedle)
        }
    }

    private func studyPanel(_ title: String, rows: [ComparableStudyRow], isBaseline: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.headline)
            Text(language.text("\(rows.count)観測 · \(Set(rows.map(\.drugName)).count)薬物", "\(rows.count) observations · \(Set(rows.map(\.drugName)).count) drugs"))
                .font(.caption).foregroundStyle(.secondary)
            Chart(rows) { row in
                PointMark(
                    x: .value(language.text("透過時間", "Permeation time"), row.permeationTime),
                    y: .value(metric.title(language), row.value(for: metric))
                )
                .foregroundStyle(by: .value(language.text("薬物", "Drug"), row.drugName))
                .symbol(by: .value(language.text("薬物", "Drug"), row.drugName))
                .opacity(0.75)
            }
            .chartXAxisLabel(language.text("透過時間 (h)", "Permeation time (h)"))
            .chartYAxisLabel("\(metric.title(language)) (\(metric.unit))")
            .chartLegend(position: .bottom, alignment: .leading)
            .frame(minWidth: 380, minHeight: 300)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(title)
            .accessibilityValue(language.text("\(rows.count)観測", "\(rows.count) observations"))
            .accessibilityIdentifier(isBaseline ? "comparison.yuan-chart" : "comparison.imported-chart")
        }
        .padding(14).labCard()
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder private func comparisonSummary(baselineRows: [ComparableStudyRow], importedRows: [ComparableStudyRow]) -> some View {
        if let baseline = StudyMetricSummary.make(rows: baselineRows, metric: metric),
           let imported = StudyMetricSummary.make(rows: importedRows, metric: metric) {
            Grid(alignment: .leading, horizontalSpacing: 24, verticalSpacing: 9) {
                GridRow { Text(language.text("研究", "Study")).bold(); Text("n").bold(); Text(language.text("最小", "Min")).bold(); Text(language.text("中央値", "Median")).bold(); Text(language.text("最大", "Max")).bold() }
                Divider().gridCellColumns(5)
                metricRow("Yuan 2023", baseline)
                metricRow(dataStore.comparisonDataset?.name ?? "", imported)
            }
            let ratio = baseline.median == 0 ? nil : imported.median / baseline.median
            Text(ratio.map { language.text("比較研究の中央値はYuanの \(number($0))倍です。条件・薬物・測定法の差を調整した因果比較ではありません。", "The imported median is \(number($0))× Yuan's median. This is descriptive and does not adjust for differences in conditions, drugs, or methods.") } ?? language.text("中央値比は計算できません。", "The median ratio cannot be calculated."))
                .font(.caption).foregroundStyle(.secondary)
        }
    }

    private func metricRow(_ name: String, _ summary: StudyMetricSummary) -> some View {
        GridRow { Text(name); Text("\(summary.count)"); Text(number(summary.minimum)); Text(number(summary.median)); Text(number(summary.maximum)) }
    }

    private var comparisonControls: some View {
        LabSection(language.text("比較条件", "Comparison controls")) {
            VStack(alignment: .leading, spacing: 14) {
                Picker(language.text("比較指標", "Comparison metric"), selection: $metric) {
                    ForEach(DatasetComparisonMetric.allCases) { item in
                        Text(item.title(language)).tag(item)
                    }
                }
                .pickerStyle(.segmented)
                .accessibilityIdentifier("comparison.metric-picker")

                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 16) { filterPickers }
                    VStack(alignment: .leading, spacing: 12) { filterPickers }
                }

                HStack(spacing: 16) {
                    Label(
                        language.text("\(rows.count) / \(allRows.count)観測", "\(rows.count) / \(allRows.count) observations"),
                        systemImage: "number"
                    )
                    Label(
                        language.text("\(summaries.count)薬物", "\(summaries.count) drugs"),
                        systemImage: "pills"
                    )
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private var filterPickers: some View {
        optionalPicker(
            language.text("皮膚", "Skin"),
            selection: $selectedSkin,
            values: SkinType.allCases
        ) { $0.displayName(language) }

        optionalPicker(
            language.text("MNタイプ", "MN type"),
            selection: $selectedNeedle,
            values: NeedleType.allCases
        ) { $0.displayName(language) }

        Button(language.text("フィルター解除", "Clear filters"), systemImage: "xmark.circle") {
            selectedSkin = nil
            selectedNeedle = nil
        }
        .disabled(selectedSkin == nil && selectedNeedle == nil)
    }

    private func optionalPicker<T: Hashable & Identifiable>(
        _ title: String,
        selection: Binding<T?>,
        values: [T],
        label: @escaping (T) -> String
    ) -> some View {
        Picker(title, selection: selection) {
            Text(language.text("すべて", "All")).tag(Optional<T>.none)
            ForEach(values) { value in
                Text(label(value)).tag(Optional(value))
            }
        }
        .frame(minWidth: 190)
    }

    private var summaryTable: some View {
        LabSection(language.text("最小値・中央値・最大値", "Minimum, median, and maximum")) {
            Grid(alignment: .leading, horizontalSpacing: 28, verticalSpacing: 11) {
                GridRow {
                    Text(language.text("薬物", "Drug")).bold()
                    Text("n").bold()
                    Text(language.text("最小", "Minimum")).bold()
                    Text(language.text("中央値", "Median")).bold()
                    Text(language.text("最大", "Maximum")).bold()
                }
                Divider().gridCellColumns(5)
                ForEach(summaries) { summary in
                    GridRow {
                        Text(summary.drug.displayName(language))
                        Text("\(summary.count)").monospacedDigit()
                        Text(number(summary.minimum)).monospacedDigit()
                        Text(number(summary.median)).monospacedDigit()
                        Text(number(summary.maximum)).monospacedDigit()
                    }
                }
            }
            .accessibilityIdentifier("comparison.summary-table")

            Text("\(metric.title(language)) · \(metric.unit)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var csvRequirements: some View {
        LabSection(language.text("CSV要件", "CSV requirements")) {
            VStack(alignment: .leading, spacing: 8) {
                Text(language.text(
                    "ヘッダーはData S1と同じ11列・同じ順序が必要です。薬物名は自由、skinは1/2、MN typeは1/2を使用します。出典をReferences列へ記録してください。無効なCSVでもYuan基準データは変更されません。",
                    "The header must use the same 11 columns and order as Data S1. Drug names may be arbitrary; use skin codes 1/2 and MN type codes 1/2, and record provenance in References. Invalid files never alter the Yuan baseline."
                ))
                .font(.callout)
                ScrollView(.horizontal) {
                    Text(TrainingDataSource.expectedHeader.joined(separator: ","))
                        .font(.caption.monospaced())
                        .textSelection(.enabled)
                }
            }
        }
    }

    private func number(_ value: Double) -> String {
        value.formatted(.number.grouping(.automatic).precision(.fractionLength(0...6)))
    }

    private func importCSV(_ url: URL) {
        let accessed = url.startAccessingSecurityScopedResource()
        defer { if accessed { url.stopAccessingSecurityScopedResource() } }
        do {
            let text = try String(contentsOf: url, encoding: .utf8)
            try dataStore.importComparison(csvText: text, fileName: url.lastPathComponent)
        } catch {
            errorMessage = localizedErrorMessage(error)
        }
    }

    private func localizedErrorMessage(_ error: Error) -> String {
        if let replacementError = error as? DatasetReplacementError {
            return replacementError.message(language)
        }
        return language.text(
            "ファイルを読み込めませんでした: \(error.localizedDescription)",
            "Could not read the file: \(error.localizedDescription)"
        )
    }
}
