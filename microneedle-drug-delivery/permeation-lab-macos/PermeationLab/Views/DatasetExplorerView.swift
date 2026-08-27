import Charts
import SwiftUI

struct DatasetExplorerView: View {
    let repository: StudyRepository

    @State private var selectedDrug = "すべて"
    @State private var selectedSkin = 0
    @State private var selectedNeedle = 0
    @State private var outcome: PermeationOutcome = .amount
    @State private var page = 0

    private let pageSize = 20

    private var filteredRecords: [PermeationRecord] {
        repository.filtered(
            drug: selectedDrug == "すべて" ? nil : selectedDrug,
            skin: SkinKind(rawValue: selectedSkin),
            needle: MicroneedleKind(rawValue: selectedNeedle)
        )
    }

    private var outcomeValues: [Double] {
        filteredRecords.map { $0.value(for: outcome) }
    }

    private var pageCount: Int {
        max(1, Int(ceil(Double(filteredRecords.count) / Double(pageSize))))
    }

    private var pagedRecords: [PermeationRecord] {
        let safePage = min(page, pageCount - 1)
        return Array(filteredRecords.dropFirst(safePage * pageSize).prefix(pageSize))
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    PageHeader(
                        eyebrow: "Supporting Information · Data S1",
                        title: "実測データ・エクスプローラ",
                        subtitle: "公開された191観測点だけを、条件で絞り込み、時系列散布図と全列テーブルで確認します。",
                        symbol: "tablecells"
                    )

                    HStack(spacing: 14) {
                        FilterPicker(title: "薬物", selection: $selectedDrug) {
                            Text("すべて").tag("すべて")
                            ForEach(repository.drugs, id: \.self) { Text($0).tag($0) }
                        }
                        FilterPicker(title: "皮膚", selection: $selectedSkin) {
                            Text("すべて").tag(0)
                            Text("ラット").tag(SkinKind.rat.rawValue)
                            Text("ヒト").tag(SkinKind.human.rawValue)
                        }
                        FilterPicker(title: "MN", selection: $selectedNeedle) {
                            Text("すべて").tag(0)
                            Text("ヒドロゲル").tag(MicroneedleKind.hydrogel.rawValue)
                            Text("プラスチック").tag(MicroneedleKind.plastic.rawValue)
                        }
                        FilterPicker(title: "表示値", selection: $outcome) {
                            ForEach(PermeationOutcome.allCases) { Text($0.rawValue).tag($0) }
                        }
                        Spacer(minLength: 8)
                        Text("\(filteredRecords.count) 件")
                            .font(.title3.bold().monospacedDigit())
                            .foregroundStyle(StudyTheme.accent)
                            .accessibilityIdentifier("filtered-count")
                    }
                    .studyCard(padding: 14)

                    if let loadingError = repository.loadingError {
                        Label(loadingError, systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                            .studyCard()
                    } else {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 14), count: 2), spacing: 14) {
                            MetricTile(
                                value: formatted(outcomeValues.min() ?? 0),
                                label: "最小値",
                                detail: outcome.unit
                            )
                            MetricTile(
                                value: formatted(outcomeValues.max() ?? 0),
                                label: "最大値",
                                detail: outcome.unit,
                                color: StudyTheme.secondaryAccent
                            )
                        }

                        VStack(alignment: .leading, spacing: 14) {
                            HStack {
                                Text("透過時間と \(outcome.rawValue)").font(.title3.weight(.semibold))
                                Spacer()
                                EvidenceBadge(evidence: .init(location: "Data S1", note: "線や推定値を加えない実測散布図"))
                            }
                            Chart(filteredRecords) { record in
                                PointMark(
                                    x: .value("透過時間 (h)", record.timeHours),
                                    y: .value("\(outcome.rawValue) (\(outcome.unit))", record.value(for: outcome))
                                )
                                .foregroundStyle(by: .value("薬物", record.drug))
                                .symbol(by: .value("薬物", record.drug))
                                .symbolSize(34)
                            }
                            .chartXAxisLabel("透過時間 (h)")
                            .chartYAxisLabel("\(outcome.rawValue) (\(outcome.unit))")
                            .chartLegend(position: .bottom, alignment: .leading, spacing: 12)
                            .frame(height: 330)
                            .accessibilityElement(children: .ignore)
                            .accessibilityLabel("Data S1 の実測散布図。\(filteredRecords.count)観測点。横軸は透過時間、縦軸は\(outcome.rawValue)。")
                            .accessibilityIdentifier("observed-data-chart")
                            Text("点はすべて実測値です。曲線補間、回帰、外挿、論文外の推定は行っていません。")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .studyCard()

                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundStyle(StudyTheme.warning)
                            Text("Data S1 には BSA の透過率 108.3982246% が含まれます。原データを保持するため100%へ丸めたり制限したりしません。透過量の列名は Data S1 に従い µg/cm² と表示します。")
                                .font(.callout)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .studyCard(padding: 15)

                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Data S1 · 全11列の内容").font(.title3.weight(.semibold))
                                Spacer()
                                Text("列見出しと値は補足データ準拠 · 1ページ20件")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            StudyDataTable(records: pagedRecords)
                                .frame(height: 430)
                            HStack {
                                Button("前へ", systemImage: "chevron.left") {
                                    page = max(0, page - 1)
                                }
                                .disabled(page == 0)
                                Spacer()
                                Text("\(page + 1) / \(pageCount) ページ")
                                    .font(.callout.monospacedDigit())
                                    .accessibilityIdentifier("data-page-indicator")
                                Spacer()
                                Button("次へ", systemImage: "chevron.right") {
                                    page = min(pageCount - 1, page + 1)
                                }
                                .disabled(page >= pageCount - 1)
                            }
                        }
                        .studyCard()
                    }
                }
                .frame(maxWidth: StudyTheme.contentWidth)
                .padding(28)
                .frame(maxWidth: .infinity)
            }
        }
        .accessibilityIdentifier("dataset-screen")
        .onChange(of: selectedDrug) { page = 0 }
        .onChange(of: selectedSkin) { page = 0 }
        .onChange(of: selectedNeedle) { page = 0 }
    }

    private func formatted(_ value: Double) -> String {
        value.formatted(.number.grouping(.never).precision(.fractionLength(0...10)))
    }
}

private struct FilterPicker<Selection: Hashable, Content: View>: View {
    let title: String
    @Binding var selection: Selection
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Picker(title, selection: $selection) { content }
                .labelsHidden()
                .frame(minWidth: 135)
        }
    }
}

private struct StudyDataTable: View {
    let records: [PermeationRecord]

    var body: some View {
        Table(records) {
            TableColumn("薬物") { record in Text(record.drug) }
                .width(min: 95, ideal: 110)
            TableColumn("搭載量 µg") { record in Text(number(record.loadingMicrograms)).monospacedDigit() }
                .width(min: 78, ideal: 90)
            TableColumn("MW Da") { record in Text(number(record.molecularWeightDalton)).monospacedDigit() }
                .width(min: 70, ideal: 82)
            TableColumn("長さ mm") { record in Text(number(record.needleLengthMillimeters)).monospacedDigit() }
                .width(min: 65, ideal: 75)
            TableColumn("皮膚 / MN") { record in Text("\(record.skin.label) / \(record.needle.label)") }
                .width(min: 110, ideal: 130)
            TableColumn("面積 mm²") { record in Text(number(record.surfaceAreaSquareMillimeters)).monospacedDigit() }
                .width(min: 75, ideal: 88)
            TableColumn("時間 h") { record in Text(number(record.timeHours)).monospacedDigit() }
                .width(min: 62, ideal: 72)
            TableColumn("透過率 %") { record in Text(number(record.percentage)).monospacedDigit() }
                .width(min: 78, ideal: 92)
            TableColumn("透過量 µg/cm²") { record in Text(number(record.amountMicrogramsPerSquareCentimeter)).monospacedDigit() }
                .width(min: 100, ideal: 118)
            TableColumn("References") { record in Text(record.reference ?? "—") }
                .width(min: 95, ideal: 145)
        }
        .accessibilityIdentifier("data-table")
    }

    private func number(_ value: Double) -> String {
        value.formatted(.number.grouping(.never).precision(.fractionLength(0...10)))
    }
}
