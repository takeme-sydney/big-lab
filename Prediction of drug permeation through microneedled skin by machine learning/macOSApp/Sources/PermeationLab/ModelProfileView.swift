import Charts
import SwiftUI
import UniformTypeIdentifiers

struct ProfileValidationMetric: Identifiable, Equatable, Sendable {
    let model: ModelKind
    let count: Int
    let rmse: Double
    let mae: Double

    var id: ModelKind { model }

    static func make(
        profiles: [ExploratoryProfilePoint],
        observations: [ComparableStudyRow],
        outcome: Outcome
    ) -> [Self] {
        ModelKind.allCases.compactMap { model in
            let curve = profiles.filter { $0.model == model }.sorted { $0.time < $1.time }
            guard curve.count >= 2 else { return nil }
            let errors = observations.compactMap { row -> Double? in
                guard let prediction = interpolate(curve: curve, time: row.permeationTime) else { return nil }
                let observed = outcome == .amount ? row.amount : row.percentage
                return observed - prediction
            }
            guard !errors.isEmpty else { return nil }
            return Self(
                model: model,
                count: errors.count,
                rmse: sqrt(errors.reduce(0) { $0 + $1 * $1 } / Double(errors.count)),
                mae: errors.reduce(0) { $0 + abs($1) } / Double(errors.count)
            )
        }
    }

    private static func interpolate(curve: [ExploratoryProfilePoint], time: Double) -> Double? {
        guard let first = curve.first, let last = curve.last, time >= first.time, time <= last.time else { return nil }
        if time == first.time { return first.value }
        for upperIndex in 1..<curve.count where time <= curve[upperIndex].time {
            let lower = curve[upperIndex - 1]
            let upper = curve[upperIndex]
            let width = upper.time - lower.time
            guard width > 0 else { return upper.value }
            let fraction = (time - lower.time) / width
            return lower.value + fraction * (upper.value - lower.value)
        }
        return last.value
    }
}

struct ModelProfileView: View {
    let language: AppLanguage
    @ObservedObject var dataStore: AppDatasetStore

    @State private var scenario = Scenario()
    @State private var outcome: Outcome = .amount
    @State private var points: [ExploratoryProfilePoint] = []
    @State private var isImportingInVitro = false
    @State private var errorMessage: String?
    @State private var profileUpdateTask: Task<Void, Never>?
    @State private var requestedProfileRevision = 0

    private var rows: [TrainingDataRow] { dataStore.dataset.rows }

    private var observedRows: [TrainingDataRow] {
        rows.filter {
            $0.drug == scenario.drug
                && $0.skin == scenario.skin
                && $0.needle == scenario.needle
                && $0.permeationTime <= scenario.duration
        }
    }

    private var inVitroRows: [ComparableStudyRow] {
        guard let comparison = dataStore.comparisonDataset else { return [] }
        return comparison.rows.filter {
            $0.matchesExperimentalCondition(scenario)
                && $0.permeationTime <= scenario.duration
        }
    }

    private var validationMetrics: [ProfileValidationMetric] {
        ProfileValidationMetric.make(profiles: points, observations: inVitroRows, outcome: outcome)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                LabWorkspaceHeader(
                    title: language.text("4モデル透過曲線", "Four-model permeation profiles"),
                    subtitle: language.text(
                        "薬物とMN条件を指定し、Fick・MLR・Random Forest・XGBoost代替の時間曲線を比較",
                        "Compare time profiles from Fick, MLR, Random Forest, and an XGBoost surrogate for a selected drug and MN scenario"
                    ),
                    systemImage: "chart.xyaxis.line"
                )

                controls
                profileChart
                inVitroComparison

                LabNotice(
                    title: language.text("再学習した探索用表示", "Locally refitted exploratory display"),
                    message: language.text(
                        "原著の学習済み係数・決定木・XGBoost boosterと分割後予測値は公開されていません。MLRとRFは現在のCSVで再学習し、XGBoost線は端末内Gradient Boosting代替、Fick線は実測に合わせた単調飽和参照曲線です。原著モデルの再現値や臨床予測として使用しないでください。",
                        "The paper does not release fitted coefficients, decision trees, the XGBoost booster, split assignments, or prediction outputs. MLR and RF are refitted on the current CSV; the XGBoost line is an on-device gradient-boosting surrogate, and the Fick line is a monotone saturating reference fitted to observations. Do not treat these as reproduced paper predictions or clinical estimates."
                    ),
                    kind: .warning
                )
            }
            .frame(maxWidth: LabTheme.contentWidth, alignment: .leading)
            .padding(LabTheme.pagePadding)
            .frame(maxWidth: .infinity, alignment: .top)
        }
        .onAppear {
            requestProfileUpdate()
        }
        .onChange(of: dataStore.revision) { _, _ in requestProfileUpdate() }
        .onChange(of: dataStore.comparisonRevision) { _, _ in requestProfileUpdate() }
        .onChange(of: scenario) { _, _ in requestProfileUpdate() }
        .onChange(of: outcome) { _, _ in requestProfileUpdate() }
        .onDisappear { profileUpdateTask?.cancel() }
        .fileImporter(
            isPresented: $isImportingInVitro,
            allowedContentTypes: [.commaSeparatedText, .plainText]
        ) { result in
            switch result {
            case .success(let url): importInVitroCSV(url)
            case .failure(let error):
                if (error as NSError).code != NSUserCancelledError {
                    errorMessage = error.localizedDescription
                }
            }
        }
        .alert(
            language.text("in vitro CSVを読み込めません", "Unable to import in vitro CSV"),
            isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })
        ) {
            Button("OK", role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
        .accessibilityIdentifier("screen.model-profiles")
    }

    private var controls: some View {
        LabSection(language.text("シナリオ", "Scenario")) {
            VStack(alignment: .leading, spacing: 16) {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 210), spacing: 16)], spacing: 14) {
                    Picker(language.text("薬物", "Drug"), selection: $scenario.drug) {
                        ForEach(Drug.allCases) { drug in Text(drug.displayName(language)).tag(drug) }
                    }
                    Picker(language.text("皮膚", "Skin"), selection: $scenario.skin) {
                        ForEach(SkinType.allCases) { skin in Text(skin.displayName(language)).tag(skin) }
                    }
                    Picker(language.text("MNタイプ", "MN type"), selection: $scenario.needle) {
                        ForEach(NeedleType.allCases) { needle in Text(needle.displayName(language)).tag(needle) }
                    }
                    Picker(language.text("結果", "Outcome"), selection: $outcome) {
                        Text(language.text("累積透過量", "Cumulative amount")).tag(Outcome.amount)
                        Text(language.text("累積透過率", "Cumulative percentage")).tag(Outcome.percentage)
                    }
                }

                scenarioSlider(language.text("薬物充填量", "Drug loading"), value: $scenario.loading, range: 50...70_940, unit: "µg")
                scenarioSlider(language.text("MN長", "MN length"), value: $scenario.length, range: 0.7...1.25, unit: "mm")
                scenarioSlider(language.text("MN表面積", "MN surface area"), value: $scenario.surfaceArea, range: 26.761...36.855, unit: "mm²")
                scenarioSlider(language.text("表示時間", "Profile duration"), value: $scenario.duration, range: 1...48, unit: "h")

                HStack {
                    Label(
                        language.text("ドラッグ中も連続自動更新", "Live updates while dragging"),
                        systemImage: "bolt.horizontal.circle.fill"
                    )
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(.blue)
                    .accessibilityIdentifier("model-profiles.auto-update")
                    Text(language.text("現在のCSV: \(dataStore.displayName)", "Current CSV: \(dataStore.displayName)"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Divider()

                HStack {
                    Button(language.text("in vitro CSVを読み込む", "Import in vitro CSV"), systemImage: "cross.vial") {
                        isImportingInVitro = true
                    }
                    .accessibilityIdentifier("model-profiles.import-in-vitro")
                    if dataStore.comparisonDataset != nil {
                        Button(language.text("比較データを外す", "Remove comparison"), systemImage: "xmark.circle") {
                            dataStore.removeComparison()
                        }
                    }
                    Spacer()
                    if let comparison = dataStore.comparisonDataset {
                        Text("\(comparison.name) · \(comparison.rows.count) rows")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private var profileChart: some View {
        LabSection(language.text("時間プロファイル", "Time profile")) {
            Chart {
                ForEach(points) { point in
                    LineMark(
                        x: .value(language.text("時間", "Time"), point.time),
                        y: .value(outcomeTitle, point.value),
                        series: .value(language.text("モデル", "Model"), point.model.rawValue)
                    )
                    .foregroundStyle(by: .value(language.text("モデル", "Model"), point.model.rawValue))
                    .lineStyle(StrokeStyle(lineWidth: 2.5))
                }

                ForEach(observedRows) { row in
                    PointMark(
                        x: .value(language.text("時間", "Time"), row.permeationTime),
                        y: .value(outcomeTitle, outcome == .amount ? row.amount : row.percentage)
                    )
                    .foregroundStyle(.red)
                    .symbol(.circle)
                    .symbolSize(48)
                }

                ForEach(inVitroRows) { row in
                    PointMark(
                        x: .value(language.text("時間", "Time"), row.permeationTime),
                        y: .value(outcomeTitle, outcome == .amount ? row.amount : row.percentage)
                    )
                    .foregroundStyle(.orange)
                    .symbol(.diamond)
                    .symbolSize(70)
                }
            }
            .chartXAxisLabel(language.text("透過時間 (h)", "Permeation time (h)"))
            .chartYAxisLabel("\(outcomeTitle) (\(outcomeUnit))")
            .chartLegend(position: .bottom, alignment: .leading)
            .frame(height: 460)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(language.text(
                "4モデルの探索的な時間プロファイル",
                "Exploratory time profiles for four models"
            ))
            .accessibilityValue(language.text(
                "モデル線\(points.count)点、現在の研究データの実測\(observedRows.count)点、比較in vitro実測\(inVitroRows.count)点。線は原著の学習済みモデルではありません。",
                "\(points.count) model-line points, \(observedRows.count) observations from current research data, and \(inVitroRows.count) comparison in-vitro observations. Lines are not the paper's fitted models."
            ))
            .accessibilityIdentifier("model-profiles.chart")

            Text(language.text(
                "赤丸はData S1実測、橙のひし形は読み込んだin vitro実測です。線は選択シナリオの時間以外を固定した探索用出力です。",
                "Red circles are Data S1 observations and orange diamonds are imported in vitro observations. Lines are exploratory outputs with scenario inputs held fixed while time varies."
            ))
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }

    private var inVitroComparison: some View {
        LabSection(language.text("in vitro比較", "In vitro comparison")) {
            if dataStore.comparisonDataset == nil {
                ContentUnavailableView(
                    language.text("in vitroデータは未読込です", "No in vitro dataset imported"),
                    systemImage: "doc.badge.plus",
                    description: Text(language.text(
                        "Data S1と同じ11列スキーマのCSVを読み込んでください。比較データは4モデルの再学習には使用しません。",
                        "Import a CSV using the same 11-column schema as Data S1. Comparison observations are not used to refit the four models."
                    ))
                )
                .frame(height: 180)
            } else if inVitroRows.isEmpty {
                ContentUnavailableView(
                    language.text("選択条件にin vitro観測がありません", "No in vitro observations match the scenario"),
                    systemImage: "line.3.horizontal.decrease.circle",
                    description: Text(language.text(
                        "薬物名、皮膚、MNタイプ、表示時間を確認してください。",
                        "Check the drug name, skin, MN type, and profile duration."
                    ))
                )
                .frame(height: 180)
            } else {
                Grid(alignment: .leading, horizontalSpacing: 28, verticalSpacing: 10) {
                    GridRow {
                        Text(language.text("モデル", "Model")).bold()
                        Text("n").bold()
                        Text("RMSE").bold()
                        Text("MAE").bold()
                    }
                    Divider().gridCellColumns(4)
                    ForEach(validationMetrics) { metric in
                        GridRow {
                            Text(metric.model.rawValue)
                            Text("\(metric.count)").monospacedDigit()
                            Text(number(metric.rmse)).monospacedDigit()
                            Text(number(metric.mae)).monospacedDigit()
                        }
                    }
                }
                .accessibilityIdentifier("model-profiles.in-vitro-metrics")

                Text(language.text(
                    "誤差は薬物、皮膚、MNタイプ、充填量、MN長、表面積が一致するin vitro観測だけを対象に、表示中の曲線を各測定時刻へ線形補間して計算します。比較データを読み込むと、最初の実験条件が自動設定されます。",
                    "Errors use only in vitro observations matching drug, skin, MN type, loading, MN length, and surface area, and linearly interpolate the displayed curves at each sampling time. Importing comparison data automatically selects its first experimental condition."
                ))
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
    }

    private func scenarioSlider(
        _ title: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        unit: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(title).font(.callout.weight(.semibold))
                Spacer()
                Text("\(number(value.wrappedValue)) \(unit)").monospacedDigit()
            }
            Slider(value: value, in: range)
        }
    }

    private var outcomeTitle: String {
        outcome == .amount
            ? language.text("累積透過量", "Cumulative permeation amount")
            : language.text("累積透過率", "Cumulative permeation percentage")
    }

    private var outcomeUnit: String { outcome == .amount ? "µg/cm²" : "%" }

    private func requestProfileUpdate() {
        requestedProfileRevision += 1
        guard profileUpdateTask == nil else { return }
        profileUpdateTask = Task { @MainActor in
            while !Task.isCancelled {
                let revisionBeingCalculated = requestedProfileRevision
                let inputRows = rows
                let inputScenario = scenario
                let inputOutcome = outcome
                let calculated = await Task.detached(priority: .userInitiated) {
                    ExploratoryProfileEngine.make(
                        rows: inputRows,
                        scenario: inputScenario,
                        outcome: inputOutcome
                    )
                }.value
                guard !Task.isCancelled else { break }

                // Show every completed intermediate result so the chart visibly
                // follows a continuously dragged slider. If controls changed while
                // this fit ran, immediately continue with the newest values.
                points = calculated
                if revisionBeingCalculated == requestedProfileRevision { break }
            }
            profileUpdateTask = nil
        }
    }

    private func importInVitroCSV(_ url: URL) {
        let accessed = url.startAccessingSecurityScopedResource()
        defer { if accessed { url.stopAccessingSecurityScopedResource() } }
        do {
            let text = try String(contentsOf: url, encoding: .utf8)
            try dataStore.importComparison(csvText: text, fileName: url.lastPathComponent)
            if let first = dataStore.comparisonDataset?.rows.first {
                applyExperimentalCondition(first)
            }
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func applyExperimentalCondition(_ row: ComparableStudyRow) {
        guard let drug = Drug.allCases.first(where: {
            $0.sourceName.caseInsensitiveCompare(row.drugName) == .orderedSame
                || $0.rawValue.caseInsensitiveCompare(row.drugName) == .orderedSame
        }) else { return }
        scenario.drug = drug
        scenario.skin = row.skin
        scenario.needle = row.needle
        scenario.loading = row.loading
        scenario.length = row.needleLength
        scenario.surfaceArea = row.surfaceArea
        let matchingTimes = dataStore.comparisonDataset?.rows
            .filter { $0.matchesExperimentalCondition(scenario) }
            .map(\.permeationTime) ?? []
        scenario.duration = min(max(matchingTimes.max() ?? row.permeationTime, 1), 48)
    }

    private func number(_ value: Double) -> String {
        value.formatted(.number.grouping(.automatic).precision(.fractionLength(0...2)))
    }
}
