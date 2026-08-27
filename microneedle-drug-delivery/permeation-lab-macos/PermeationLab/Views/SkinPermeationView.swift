import Charts
import Combine
import SwiftUI

struct SkinPermeationView: View {
    let repository: StudyRepository

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var selectedDrug = "すべて"
    @State private var selectedSkin = 0
    @State private var selectedNeedle = 0
    @State private var outcome: PermeationOutcome = .percentage
    @State private var selectedRecordID: Int
    @State private var illustratedMechanism: MicroneedleKind
    @State private var conceptStep = 0
    @State private var isPlaying = false

    private let motionTimer = Timer.publish(every: 1.25, on: .main, in: .common).autoconnect()

    init(repository: StudyRepository) {
        self.repository = repository
        let initialRecord = repository.records.first
        _selectedRecordID = State(initialValue: initialRecord?.id ?? 0)
        _illustratedMechanism = State(initialValue: initialRecord?.needle ?? .hydrogel)
    }

    private var filteredRecords: [PermeationRecord] {
        repository.filtered(
            drug: selectedDrug == "すべて" ? nil : selectedDrug,
            skin: SkinKind(rawValue: selectedSkin),
            needle: MicroneedleKind(rawValue: selectedNeedle)
        )
        .sorted { $0.id < $1.id }
    }

    private var selectedRecord: PermeationRecord? {
        filteredRecords.first { $0.id == selectedRecordID } ?? filteredRecords.first
    }

    private var observedPoints: [ObservedPermeationPoint] {
        SkinPermeationPresentation.observedPoints(records: filteredRecords, outcome: outcome)
    }

    private let drugDomain = ["BSA", "GHK peptide", "Rhodamine B", "caffeine", "copper ions", "lidocaine"]
    private let drugColors: [Color] = [.blue, .green, .purple, .pink, .cyan, .orange]
    private let drugSymbols: [BasicChartSymbolShape] = [.circle, .cross, .diamond, .square, .triangle, .plus]

    private var steps: [ConceptMechanismStep] {
        SkinPermeationPresentation.mechanismSteps(for: illustratedMechanism)
    }

    private var selectedStep: ConceptMechanismStep {
        steps[min(max(conceptStep, 0), max(steps.count - 1, 0))]
    }

    private var mechanismBinding: Binding<MicroneedleKind> {
        Binding(
            get: { illustratedMechanism },
            set: { newValue in
                illustratedMechanism = newValue
                selectedNeedle = newValue.rawValue
                resetMotion()
                normalizeSelection()
            }
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                PageHeader(
                    eyebrow: "Data S1 × Franz diffusion cell",
                    title: "皮膚透過",
                    subtitle: repository.loadingError == nil
                        ? "191件の累積時点観測を、マイクロニードル処理とreceptor到達の模式図に照合します。粒子の実測軌跡や皮膚内濃度mapではありません。"
                        : "Data S1を読み込めなかったため、観測数や皮膚透過表示を完全なデータとして提示しません。",
                    symbol: "cross.vial"
                )

                if let loadingError = repository.loadingError {
                    StudyDataLoadFailureCard(message: loadingError)
                } else {
                    TruthBoundaryBanner()

                    filterBar

                    ViewThatFits(in: .horizontal) {
                        HStack(alignment: .top, spacing: 16) {
                            mechanismCard
                                .frame(minWidth: 560, idealWidth: 700)
                            ObservationDetailCard(record: selectedRecord)
                                .frame(minWidth: 330, idealWidth: 370, maxWidth: 400)
                        }
                        VStack(alignment: .leading, spacing: 16) {
                            mechanismCard
                            ObservationDetailCard(record: selectedRecord)
                        }
                    }

                    observedChartCard

                    scienceBoundaryCard
                }
            }
            .frame(maxWidth: StudyTheme.contentWidth)
            .padding(28)
            .frame(maxWidth: .infinity)
        }
        .accessibilityIdentifier("skin-permeation-screen")
        .onChange(of: selectedDrug) { _, _ in normalizeSelection() }
        .onChange(of: selectedSkin) { _, _ in normalizeSelection() }
        .onChange(of: selectedNeedle) { _, newValue in
            if let needle = MicroneedleKind(rawValue: newValue) {
                illustratedMechanism = needle
                resetMotion()
            }
            normalizeSelection()
        }
        .onChange(of: selectedRecordID) { _, newValue in
            if let record = filteredRecords.first(where: { $0.id == newValue }) {
                illustratedMechanism = record.needle
                resetMotion()
            }
        }
        .onReceive(motionTimer) { _ in
            guard isPlaying, !reduceMotion, !steps.isEmpty else { return }
            conceptStep = (conceptStep + 1) % steps.count
        }
        .onDisappear { isPlaying = false }
    }

    private var filterBar: some View {
        VStack(alignment: .leading, spacing: 12) {
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 130, maximum: 190), spacing: 14)],
                alignment: .leading,
                spacing: 10
            ) {
                PermeationFilterPicker(title: "薬物", selection: $selectedDrug) {
                    Text("すべて").tag("すべて")
                    ForEach(repository.drugs, id: \.self) { Text($0).tag($0) }
                }
                .accessibilityIdentifier("permeation-drug-filter")

                PermeationFilterPicker(title: "皮膚", selection: $selectedSkin) {
                    Text("すべて").tag(0)
                    Text("ラット").tag(SkinKind.rat.rawValue)
                    Text("ヒト").tag(SkinKind.human.rawValue)
                }
                .accessibilityIdentifier("permeation-skin-filter")

                PermeationFilterPicker(title: "MN", selection: $selectedNeedle) {
                    Text("すべて").tag(0)
                    Text("ヒドロゲル").tag(MicroneedleKind.hydrogel.rawValue)
                    Text("プラスチック").tag(MicroneedleKind.plastic.rawValue)
                }
                .accessibilityIdentifier("permeation-needle-filter")

                PermeationFilterPicker(title: "表示値", selection: $outcome) {
                    ForEach(PermeationOutcome.allCases) { Text($0.rawValue).tag($0) }
                }
                .accessibilityIdentifier("permeation-outcome-picker")

                Button("すべて表示") {
                    selectedDrug = "すべて"
                    selectedSkin = 0
                    selectedNeedle = 0
                    normalizeSelection()
                }
                .buttonStyle(.bordered)
                .padding(.top, 17)
                .accessibilityIdentifier("permeation-reset-filters")

                Text("\(filteredRecords.count) / 191点")
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(StudyTheme.accent)
                    .padding(.top, 21)
                    .accessibilityIdentifier("permeation-filtered-count")
            }

            HStack(spacing: 8) {
                Label("Data S1の実測点のみ", systemImage: "circle.grid.cross")
                Text("series／replicate関係が未提供のため、点間は接続しません。")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .studyCard(padding: 14)
    }

    private var mechanismCard: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("マイクロニードルからreceptorまで")
                        .font(.title3.weight(.semibold))
                    Text("概念図・非定量・縮尺外")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(StudyTheme.warning)
                }
                Spacer()
                Picker("機序", selection: mechanismBinding) {
                    Text("Hydrogel · 留置").tag(MicroneedleKind.hydrogel)
                    Text("Plastic · 抜去後").tag(MicroneedleKind.plastic)
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 310)
                .accessibilityIdentifier("permeation-mechanism-picker")
            }

            SkinCrossSectionIllustration(
                mechanism: illustratedMechanism,
                step: conceptStep,
                reduceMotion: reduceMotion
            )
            .frame(minHeight: 410)

            if let selectedRecord {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "scope")
                        .foregroundStyle(StudyTheme.accent)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Data S1 転記行 #\(selectedRecord.id) · \(sourceNumber(selectedRecord.timeHours)) h · receptor到達 \(sourceNumber(selectedRecord.value(for: outcome))) \(outcome.unit)")
                            .font(.callout.weight(.semibold).monospacedDigit())
                        Text("この観測値はtextとして照合します。glyphの数・位置・速度・深さには反映しません。")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .accessibilityElement(children: .combine)
                .accessibilityIdentifier("permeation-illustration-observation")
            }

            HStack(spacing: 9) {
                Button {
                    isPlaying.toggle()
                } label: {
                    Label(isPlaying ? "一時停止" : "再生", systemImage: isPlaying ? "pause.fill" : "play.fill")
                }
                .disabled(reduceMotion)
                .accessibilityIdentifier(isPlaying ? "permeation-pause" : "permeation-play")

                Button {
                    isPlaying = false
                    conceptStep = (conceptStep + 1) % max(steps.count, 1)
                } label: {
                    Label("一段送り", systemImage: "forward.frame.fill")
                }
                .accessibilityIdentifier("permeation-step")

                Button {
                    resetMotion()
                } label: {
                    Label("リセット", systemImage: "arrow.counterclockwise")
                }
                .accessibilityIdentifier("permeation-reset-motion")

                Spacer()

                if reduceMotion {
                    Label("Reduce Motion: 静止表示", systemImage: "figure.stand")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                } else {
                    Text("固定数のglyphは分子数を表しません")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.bordered)

            VStack(alignment: .leading, spacing: 9) {
                ForEach(steps) { step in
                    HStack(alignment: .top, spacing: 10) {
                        Text("\(step.index + 1)")
                            .font(.caption.bold().monospacedDigit())
                            .foregroundStyle(step.index == conceptStep ? .white : StudyTheme.secondaryAccent)
                            .frame(width: 23, height: 23)
                            .background(step.index == conceptStep ? StudyTheme.secondaryAccent : StudyTheme.secondaryAccent.opacity(0.12), in: Circle())
                        VStack(alignment: .leading, spacing: 2) {
                            Text(step.title).font(.callout.weight(.semibold))
                            Text(step.detail).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    .accessibilityElement(children: .combine)
                }
            }
            .accessibilityElement(children: .contain)
        }
        .studyCard()
    }

    private var observedChartCard: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("191累積時点観測")
                        .font(.title3.weight(.semibold))
                    Text("透過時間 × \(outcome.rawValue) · PointMarkのみ")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                EvidenceBadge(evidence: .init(location: "実測 Data S1", note: "空間座標ではなく累積時点観測"))
            }

            if filteredRecords.isEmpty {
                ContentUnavailableView(
                    "該当する観測がありません",
                    systemImage: "line.3.horizontal.decrease.circle",
                    description: Text("filterを変更するか、すべて表示を選んでください。")
                )
                .frame(height: 320)
            } else {
                Chart(observedPoints) { point in
                    PointMark(
                        x: .value("透過時間 (h)", point.timeHours),
                        y: .value("\(outcome.rawValue) (\(outcome.unit))", point.value)
                    )
                    .foregroundStyle(by: .value("薬物", point.drug))
                    .symbol(by: .value("薬物", point.drug))
                    .symbolSize(38)

                    if point.recordID == selectedRecordID {
                        PointMark(
                            x: .value("選択時間 (h)", point.timeHours),
                            y: .value("選択値", point.value)
                        )
                        .foregroundStyle(StudyTheme.warning)
                        .symbol(.circle)
                        .symbolSize(185)
                        .annotation(position: .top, spacing: 6) {
                            Text("転記行 #\(point.recordID) · \(sourceNumber(point.value)) \(outcome.unit)")
                                .font(.caption.bold().monospacedDigit())
                                .padding(.horizontal, 7)
                                .padding(.vertical, 4)
                                .background(.regularMaterial, in: Capsule())
                        }
                    }
                }
                .chartXAxisLabel("透過時間 (h)")
                .chartYAxisLabel("\(outcome.rawValue) (\(outcome.unit))")
                .chartForegroundStyleScale(domain: drugDomain, range: drugColors)
                .chartSymbolScale(domain: drugDomain, range: drugSymbols)
                .chartLegend(position: .bottom, alignment: .leading, spacing: 12)
                .frame(height: 360)
                .accessibilityLabel(chartAccessibilityLabel)
                .accessibilityIdentifier("permeation-observed-chart")

                observationSelector
            }

            HStack(alignment: .top, spacing: 9) {
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundStyle(StudyTheme.warning)
                    .accessibilityHidden(true)
                Text("Data S1にはBSAの透過率108.3982246%が含まれます。100%へ制限せず原値を保持します。amountはData S1 headerに従いµg/cm²と表示し、本文・図表のµgと無言で統一しません。")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier("permeation-above-one-hundred-note")

            Text("Data S1の全191行ではamountがloading × percentage / 100と数値的に一致します。2列が独立測定か導出値かという生成方向は、補足表だけから断定しません。")
                .font(.caption)
                .foregroundStyle(.secondary)
                .accessibilityIdentifier("permeation-algebraic-relation-note")
        }
        .studyCard()
    }

    private var observationSelector: some View {
        HStack(spacing: 10) {
            Button {
                moveSelection(by: -1)
            } label: {
                Label("前の観測", systemImage: "chevron.left")
            }
            .disabled(filteredRecords.count < 2)
            .accessibilityIdentifier("permeation-previous-observation")

            Picker("選択観測", selection: $selectedRecordID) {
                ForEach(filteredRecords) { record in
                    Text("転記行 #\(record.id) · \(record.drug) · \(sourceNumber(record.timeHours)) h")
                        .tag(record.id)
                }
            }
            .frame(maxWidth: 390)
            .accessibilityIdentifier("permeation-record-picker")

            Button {
                moveSelection(by: 1)
            } label: {
                Label("次の観測", systemImage: "chevron.right")
            }
            .disabled(filteredRecords.count < 2)
            .accessibilityIdentifier("permeation-next-observation")

            Spacer()

            if let selectedRecord {
                Text("MN長 \(sourceNumber(selectedRecord.needleLengthMillimeters)) mmは幾何学値。実挿入深度ではありません。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .buttonStyle(.bordered)
    }

    private var scienceBoundaryCard: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack {
                Label("観測・model・概念図の境界", systemImage: "checkmark.shield")
                    .font(.headline)
                Spacer()
                EvidenceBadge(evidence: .init(location: "原著 §2.3 / Figure 4", note: "Fick第二法則による数値model"))
            }

            ScienceBoundaryRow(
                symbol: "circle.grid.cross",
                title: "観測",
                text: "Data S1の191行はreceptorへ到達した累積amount／percentageの時点観測です。皮膚内の位置測定ではありません。"
            )
            ScienceBoundaryRow(
                symbol: "square.grid.3x3",
                title: "原著Fick model",
                text: "Figure 4の15 min、1、3、6、24 hは数値modelの濃度mapです。選択行のsimulationではなく、ここで中間frameを生成しません。"
            )
            ScienceBoundaryRow(
                symbol: "arrow.down.right.circle",
                title: "概念図",
                text: "固定数のglyphと矢印は工程と方向だけを示します。分子数、速度、深さ、濃度、個別経路をencodeしません。"
            )
        }
        .studyCard()
        .accessibilityIdentifier("permeation-science-boundary")
    }

    private var chartAccessibilityLabel: String {
        let selection = selectedRecord.map {
            "選択はData S1転記行\($0.id)、\($0.drug)、\(sourceNumber($0.timeHours))時間、\(outcome.rawValue)\(sourceNumber($0.value(for: outcome)))\(outcome.unit)。"
        } ?? "選択観測はありません。"
        return "実測Data S1の非連結散布図。\(filteredRecords.count)点。横軸は透過時間、縦軸は\(outcome.rawValue)。\(selection)"
    }

    private func normalizeSelection() {
        guard let first = filteredRecords.first else {
            selectedRecordID = 0
            isPlaying = false
            return
        }
        if !filteredRecords.contains(where: { $0.id == selectedRecordID }) {
            selectedRecordID = first.id
        }
    }

    private func moveSelection(by offset: Int) {
        guard !filteredRecords.isEmpty else { return }
        let currentIndex = filteredRecords.firstIndex(where: { $0.id == selectedRecordID }) ?? 0
        let nextIndex = (currentIndex + offset + filteredRecords.count) % filteredRecords.count
        selectedRecordID = filteredRecords[nextIndex].id
    }

    private func resetMotion() {
        isPlaying = false
        conceptStep = 0
    }
}

private struct PermeationFilterPicker<Selection: Hashable, Content: View>: View {
    let title: String
    @Binding var selection: Selection
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Picker(title, selection: $selection) { content }
                .labelsHidden()
                .frame(minWidth: 130)
        }
    }
}

private struct StudyDataLoadFailureCard: View {
    let message: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title3)
                .foregroundStyle(.red)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 5) {
                Text("Data S1を表示できません")
                    .font(.headline)
                Text(message)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                Text("欠落時にsynthetic dataや固定の191件表示で補完しません。同梱resourceを修復してから再起動してください。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .studyCard(padding: 16)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("permeation-data-load-error")
    }
}

private struct TruthBoundaryBanner: View {
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "scope")
                .font(.title3)
                .foregroundStyle(StudyTheme.accent)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 5) {
                Text("191行 = 累積時点観測")
                    .font(.headline)
                Text("空間座標、皮膚内深さ、粒子ID、series／replicate IDはData S1にありません。図のglyphは191個の粒子や実測軌跡を表しません。")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
            EvidenceBadge(evidence: .init(location: "Data S1 · 191×11", note: "Yuan et al. (2023) Supporting Information"))
        }
        .studyCard(padding: 16)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("permeation-truth-boundary")
    }
}

private struct ObservationDetailCard: View {
    let record: PermeationRecord?

    var body: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack {
                Text("選択観測 · 全11列")
                    .font(.title3.weight(.semibold))
                Spacer()
                EvidenceBadge(evidence: .init(location: "Data S1", note: "転記CSVのsource value"))
            }

            if let record {
                Text("Data S1転記行 #\(record.id)")
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(StudyTheme.accent)

                Grid(alignment: .leading, horizontalSpacing: 14, verticalSpacing: 8) {
                    detailRow("Drug name", record.drug)
                    detailRow("Loading", "\(sourceNumber(record.loadingMicrograms)) µg")
                    detailRow("MW", "\(sourceNumber(record.molecularWeightDalton)) Da")
                    detailRow("MN length", "\(sourceNumber(record.needleLengthMillimeters)) mm")
                    detailRow("Skin", "\(record.skin.label) · code \(record.skin.rawValue)")
                    detailRow("MN type", "\(record.needle.label) · code \(record.needle.rawValue)")
                    detailRow("Surface area", "\(sourceNumber(record.surfaceAreaSquareMillimeters)) mm²")
                    detailRow("Time", "\(sourceNumber(record.timeHours)) h")
                    detailRow("Percentage", "\(sourceNumber(record.percentage)) %", identifier: "permeation-selected-percentage")
                    detailRow("Amount", "\(sourceNumber(record.amountMicrogramsPerSquareCentimeter)) µg/cm²")
                    detailRow("References", record.reference ?? "blank in Data S1")
                }

                Divider()

                Label("累積値はin vitro Franz receptor液への到達結果", systemImage: "drop.circle")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text("MN lengthは針の幾何学的長さで、実挿入深度や到達皮膚層を示しません。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ContentUnavailableView("選択可能な観測なし", systemImage: "tablecells.badge.ellipsis")
            }
        }
        .studyCard()
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("permeation-observation-detail")
    }

    @ViewBuilder
    private func detailRow(_ label: String, _ value: String, identifier: String? = nil) -> some View {
        GridRow(alignment: .top) {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.callout.monospacedDigit())
                .textSelection(.enabled)
                .accessibilityIdentifier(identifier ?? "permeation-detail-\(label)")
        }
    }
}

private struct ScienceBoundaryRow: View {
    let symbol: String
    let title: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 11) {
            Image(systemName: symbol)
                .foregroundStyle(StudyTheme.secondaryAccent)
                .frame(width: 22)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.callout.weight(.semibold))
                Text(text).font(.callout).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

private struct SkinCrossSectionIllustration: View {
    let mechanism: MicroneedleKind
    let step: Int
    let reduceMotion: Bool

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            ZStack {
                Canvas { context, canvasSize in
                    drawBackground(context: &context, size: canvasSize)
                    drawMechanism(context: &context, size: canvasSize)
                    drawConceptGlyphs(context: &context, size: canvasSize)
                }

                illustrationLabels(size: size)
            }
        }
        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(.primary.opacity(0.10)))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.72), value: step)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(mechanism.label)マイクロニードルの皮膚透過概念図。非定量、縮尺外。角質層、皮膚膜、Franz receptor液を示します。現在工程\(step + 1)。")
        .accessibilityIdentifier("permeation-skin-illustration")
    }

    private func drawBackground(context: inout GraphicsContext, size: CGSize) {
        let margin = size.width * 0.035
        let width = size.width - margin * 2
        let skinTop = size.height * 0.34
        let stratumHeight = size.height * 0.055
        let skinMembraneHeight = size.height * 0.37
        let receptorTop = skinTop + stratumHeight + skinMembraneHeight
        let receptorHeight = max(size.height - receptorTop - size.height * 0.055, 58)

        context.fill(
            Path(roundedRect: CGRect(x: margin, y: size.height * 0.075, width: width, height: size.height * 0.16), cornerRadius: 12),
            with: .color(Color.blue.opacity(0.10))
        )
        context.stroke(
            Path(roundedRect: CGRect(x: margin, y: size.height * 0.075, width: width, height: size.height * 0.16), cornerRadius: 12),
            with: .color(Color.blue.opacity(0.38)),
            lineWidth: 1.5
        )

        context.fill(Path(CGRect(x: margin, y: skinTop, width: width, height: stratumHeight)), with: .color(Color(red: 0.84, green: 0.64, blue: 0.27).opacity(0.78)))
        context.fill(Path(CGRect(x: margin, y: skinTop + stratumHeight, width: width, height: skinMembraneHeight)), with: .color(Color(red: 0.90, green: 0.56, blue: 0.50).opacity(0.58)))

        let receptorRect = CGRect(x: margin, y: receptorTop, width: width, height: receptorHeight)
        context.fill(Path(roundedRect: receptorRect, cornerRadius: 12), with: .color(Color.cyan.opacity(0.17)))
        context.stroke(Path(roundedRect: receptorRect, cornerRadius: 12), with: .color(Color.blue.opacity(0.48)), lineWidth: 1.5)

        var stirrer = Path()
        let stirrerY = receptorTop + receptorHeight * 0.72
        stirrer.move(to: CGPoint(x: size.width * 0.40, y: stirrerY))
        stirrer.addLine(to: CGPoint(x: size.width * 0.60, y: stirrerY))
        context.stroke(stirrer, with: .color(Color.blue.opacity(0.72)), style: .init(lineWidth: 5, lineCap: .round))
    }

    private func drawMechanism(context: inout GraphicsContext, size: CGSize) {
        let skinTop = size.height * 0.34
        let centerX = size.width * 0.34

        if mechanism == .hydrogel {
            let patchRect = CGRect(x: centerX - size.width * 0.17, y: skinTop - 42, width: size.width * 0.34, height: 24)
            context.fill(Path(roundedRect: patchRect, cornerRadius: 6), with: .color(StudyTheme.accent.opacity(0.82)))
            context.stroke(Path(roundedRect: patchRect, cornerRadius: 6), with: .color(StudyTheme.accent), lineWidth: 2)

            for offset in [-0.11, -0.035, 0.04, 0.115] {
                let x = centerX + size.width * offset
                var needle = Path()
                needle.move(to: CGPoint(x: x - 10, y: skinTop - 18))
                needle.addLine(to: CGPoint(x: x + 10, y: skinTop - 18))
                needle.addLine(to: CGPoint(x: x + 3, y: skinTop + size.height * 0.16))
                needle.addLine(to: CGPoint(x: x - 3, y: skinTop + size.height * 0.16))
                needle.closeSubpath()
                context.fill(needle, with: .color(StudyTheme.accent.opacity(0.68)))
                context.stroke(needle, with: .color(StudyTheme.accent), lineWidth: 1.5)
            }
        } else if step == 0 {
            let patchRect = CGRect(x: centerX - size.width * 0.17, y: skinTop - 42, width: size.width * 0.34, height: 24)
            context.fill(Path(roundedRect: patchRect, cornerRadius: 6), with: .color(StudyTheme.secondaryAccent.opacity(0.72)))
            context.stroke(Path(roundedRect: patchRect, cornerRadius: 6), with: .color(StudyTheme.secondaryAccent), lineWidth: 2)

            for offset in [-0.11, -0.035, 0.04, 0.115] {
                let x = centerX + size.width * offset
                var needle = Path()
                needle.move(to: CGPoint(x: x - 10, y: skinTop - 18))
                needle.addLine(to: CGPoint(x: x + 10, y: skinTop - 18))
                needle.addLine(to: CGPoint(x: x, y: skinTop + size.height * 0.20))
                needle.closeSubpath()
                context.fill(needle, with: .color(StudyTheme.secondaryAccent.opacity(0.58)))
                context.stroke(needle, with: .color(StudyTheme.secondaryAccent), lineWidth: 1.5)
            }
        } else {
            let removedPatch = CGRect(x: centerX - size.width * 0.16, y: size.height * 0.10, width: size.width * 0.32, height: 22)
            context.stroke(
                Path(roundedRect: removedPatch, cornerRadius: 6),
                with: .color(StudyTheme.secondaryAccent.opacity(0.75)),
                style: .init(lineWidth: 2, dash: [6, 4])
            )

            for offset in [-0.10, -0.033, 0.034, 0.101] {
                let x = centerX + size.width * offset
                var channel = Path()
                channel.move(to: CGPoint(x: x, y: skinTop - 2))
                channel.addCurve(
                    to: CGPoint(x: x + size.width * 0.012, y: skinTop + size.height * 0.20),
                    control1: CGPoint(x: x - 5, y: skinTop + size.height * 0.06),
                    control2: CGPoint(x: x + 7, y: skinTop + size.height * 0.14)
                )
                context.stroke(channel, with: .color(StudyTheme.secondaryAccent), style: .init(lineWidth: 3, dash: [5, 4]))
            }
        }

        if mechanism == .hydrogel || step >= 2 {
            var direction = Path()
            direction.move(to: CGPoint(x: centerX, y: skinTop + size.height * 0.08))
            direction.addLine(to: CGPoint(x: centerX + size.width * 0.04, y: size.height * 0.86))
            context.stroke(direction, with: .color(StudyTheme.warning.opacity(0.78)), style: .init(lineWidth: 2.2, dash: [8, 6]))
        }
    }

    private func drawConceptGlyphs(context: inout GraphicsContext, size: CGSize) {
        let clampedStep = min(max(step, 0), 3)
        let progress: Double
        if mechanism == .plastic {
            guard clampedStep >= 2 else { return }
            progress = Double(clampedStep - 2)
        } else {
            progress = Double(clampedStep) / 3.0
        }
        let skinTop = size.height * 0.34
        let startY = mechanism == .hydrogel ? skinTop + size.height * 0.07 : skinTop - size.height * 0.035
        let endY = size.height * 0.84
        let baseX = size.width * 0.34
        let offsets: [Double] = [-0.105, -0.072, -0.035, 0.0, 0.038, 0.075, 0.108]

        for (index, offset) in offsets.enumerated() {
            let lag = Double(index % 3) * 0.055
            let glyphProgress = min(max(progress - lag, 0), 1)
            let y = startY + (endY - startY) * glyphProgress
            let drift = sin(Double(index) * 1.7 + glyphProgress * .pi) * size.width * 0.014
            let x = baseX + size.width * offset + drift
            let diameter = index.isMultiple(of: 2) ? 9.0 : 7.0
            let rect = CGRect(x: x - diameter / 2, y: y - diameter / 2, width: diameter, height: diameter)
            context.fill(Path(ellipseIn: rect), with: .color(StudyTheme.warning.opacity(0.92)))
            context.stroke(Path(ellipseIn: rect), with: .color(Color.primary.opacity(0.55)), lineWidth: 1)
        }
    }

    @ViewBuilder
    private func illustrationLabels(size: CGSize) -> some View {
        Text(mechanism == .hydrogel ? "薬物含浸MN · 留置" : (step == 0 ? "plastic MN · 前処置" : "前処置後 · MN除去済み"))
            .font(.caption.weight(.bold))
            .foregroundStyle(mechanism == .hydrogel ? StudyTheme.accent : StudyTheme.secondaryAccent)
            .padding(.horizontal, 7)
            .padding(.vertical, 4)
            .background(.regularMaterial, in: Capsule())
            .position(x: size.width * 0.34, y: size.height * 0.045)

        layerLabel("donor / patch", x: size.width * 0.80, y: size.height * 0.155)
        layerLabel("角質層", x: size.width * 0.82, y: size.height * 0.367)
        layerLabel("皮膚膜", x: size.width * 0.82, y: size.height * 0.555)
        layerLabel("Franz receptor液", x: size.width * 0.80, y: size.height * 0.835)

        Text("原著工程の模式図・非定量・縮尺外")
            .font(.caption2.weight(.semibold))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 7)
            .padding(.vertical, 4)
            .background(.regularMaterial, in: Capsule())
            .position(x: size.width * 0.20, y: size.height * 0.955)
    }

    private func layerLabel(_ text: String, x: CGFloat, y: CGFloat) -> some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(.regularMaterial, in: Capsule())
            .position(x: x, y: y)
    }
}

private func sourceNumber(_ value: Double) -> String {
    value.formatted(
        .number
            .grouping(.never)
            .precision(.fractionLength(0...10))
    )
}
