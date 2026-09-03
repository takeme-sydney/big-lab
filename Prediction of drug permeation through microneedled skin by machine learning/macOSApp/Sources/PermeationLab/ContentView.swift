import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    enum Workspace: String, CaseIterable, Identifiable {
        case studyOverview
        case literatureLibrary
        case researchHome
        case fick85Assessment
        case paperReader
        case methods
        case datasetImpact
        case experiment
        case modelSelection
        case modelEvidence
        case modelProfiles
        case paperFigures
        case skinPermeation
        case dataSource
        case integrity

        var id: Self { self }

        var symbol: String {
            switch self {
            case .studyOverview: "books.vertical"
            case .literatureLibrary: "books.vertical.fill"
            case .researchHome: "scope"
            case .fick85Assessment: "checkmark.shield"
            case .paperReader: "text.book.closed"
            case .methods: "function"
            case .datasetImpact: "arrow.triangle.2.circlepath.doc.on.clipboard"
            case .experiment: "flask"
            case .modelSelection: "checklist.checked"
            case .modelEvidence: "chart.bar.xaxis"
            case .modelProfiles: "chart.xyaxis.line"
            case .paperFigures: "doc.richtext"
            case .skinPermeation: "cross.vial"
            case .dataSource: "tablecells"
            case .integrity: "checkmark.shield"
            }
        }

        func title(_ language: AppLanguage, mode: ResearchMode) -> String {
            switch self {
            case .studyOverview:
                language.text("論文の概要", "Paper overview")
            case .literatureLibrary:
                language.text("関連論文30報", "30-paper library")
            case .researchHome:
                language.text("研究ダッシュボード", "Research dashboard")
            case .fick85Assessment:
                language.text("Fick 85% エビデンス", "Fick 85% evidence")
            case .paperReader:
                language.text("論文リーダー", "Paper reader")
            case .methods:
                language.text("方法・数式・表", "Methods, equations & tables")
            case .datasetImpact:
                language.text("データ比較", "Data comparison")
            case .experiment:
                language.text("エクスペリメント", "Experiment")
            case .modelSelection:
                language.text("モデル選定", "Model selection")
            case .modelEvidence:
                language.text("モデル評価", "Model evidence")
            case .modelProfiles:
                language.text("4モデル透過曲線", "Four-model profiles")
            case .paperFigures:
                language.text("全8図ガイド", "All 8 figures")
            case .skinPermeation:
                language.text("皮膚透過", "Skin permeation")
            case .dataSource:
                mode == .paperEvidence
                    ? language.text("出典データ", "Source data")
                    : language.text("自分の研究データ", "My research data")
            case .integrity:
                mode == .paperEvidence
                    ? language.text("出典・完全性", "Sources & integrity")
                    : language.text("研究監査", "Research audit")
            }
        }

        func isAvailable(in mode: ResearchMode) -> Bool {
            switch (mode, self) {
            case (.paperEvidence, .studyOverview),
                 (.paperEvidence, .literatureLibrary),
                 (.paperEvidence, .paperReader),
                 (.paperEvidence, .methods),
                 (.paperEvidence, .modelEvidence),
                 (.paperEvidence, .paperFigures),
                 (.paperEvidence, .dataSource),
                 (.paperEvidence, .integrity),
                 (.myExperiment, .researchHome),
                 (.myExperiment, .fick85Assessment),
                 (.myExperiment, .datasetImpact),
                 (.myExperiment, .experiment),
                 (.myExperiment, .modelSelection),
                 (.myExperiment, .modelProfiles),
                 (.myExperiment, .skinPermeation),
                 (.myExperiment, .dataSource),
                 (.myExperiment, .integrity):
                true
            default:
                false
            }
        }

        var accessibilityIdentifier: String {
            switch self {
            case .studyOverview: "nav.study-overview"
            case .literatureLibrary: "nav.literature-library"
            case .researchHome: "nav.research-home"
            case .fick85Assessment: "nav.fick-85-assessment"
            case .paperReader: "nav.paper-reader"
            case .methods: "nav.methods"
            case .datasetImpact: "nav.dataset-impact"
            case .experiment: "nav.experiment"
            case .modelSelection: "nav.model-selection"
            case .modelEvidence: "nav.model-evidence"
            case .modelProfiles: "nav.model-profiles"
            case .paperFigures: "nav.paper-figures"
            case .skinPermeation: "nav.skin-permeation"
            case .dataSource: "nav.data-source"
            case .integrity: "nav.integrity"
            }
        }
    }

    @AppStorage("appLanguage") private var languageCode = AppLanguage.defaultLanguage.rawValue
    @StateObject private var dataStore: AppDatasetStore
    @StateObject private var experimentStore: ExperimentStore
    @StateObject private var modelWorkspaceStore: ModelWorkspaceStore
    @State private var workspace: Workspace
    @State private var lastPaperWorkspace: Workspace = .studyOverview
    @State private var lastExperimentWorkspace: Workspace = .researchHome
    @State private var showReportedTable = false
    @State private var isImportingExperimentData = false
    @State private var experimentDataError: String?
    @State private var isConfirmingPersonalDataClear = false

    init() {
        let arguments = ProcessInfo.processInfo.arguments
        let launchesExploratoryFickValidation = arguments.contains("-fick-85-my-experiment")
        let launchesLocalModelE2E = arguments.contains("-local-ml-e2e")
        _modelWorkspaceStore = StateObject(
            wrappedValue: ModelWorkspaceStore(loadPersisted: !arguments.contains("-ui-testing"))
        )

        if launchesExploratoryFickValidation || launchesLocalModelE2E {
            // Reproducibility entry point for the documented 2026-08-30 exploratory
            // run. The values come from Data S1, but the copy is deliberately
            // initialized in My Experiment and never receives paper-evidence status.
            let dataset = TrainingDataSource.bundled
            let displayName = launchesLocalModelE2E
                ? "Data S1 practice copy · Local ML"
                : "Data S1 exploratory copy · Fick proxy"
            _dataStore = StateObject(
                wrappedValue: AppDatasetStore(
                    dataset: dataset,
                    displayName: displayName,
                    isBundledData: false
                )
            )
            _experimentStore = StateObject(
                wrappedValue: ExperimentStore(
                    dataset: dataset,
                    displayName: displayName,
                    isBundledData: false,
                    researchMode: .myExperiment,
                    scientificStatus: .userProvidedUnvalidated
                )
            )
        } else {
            _dataStore = StateObject(wrappedValue: AppDatasetStore())
            _experimentStore = StateObject(wrappedValue: ExperimentStore())
        }

        _workspace = State(initialValue: launchesLocalModelE2E
            ? .modelSelection
            : launchesExploratoryFickValidation
                ? .fick85Assessment
                : .studyOverview)
    }

    private var language: AppLanguage {
        AppLanguage(rawValue: languageCode) ?? .defaultLanguage
    }

    private var datasetStatus: String {
        if dataStore.mode == .myExperiment, !dataStore.hasPersonalDataset {
            return language.text("自分の研究 · 未読込", "My Research · not loaded")
        }
        return dataStore.mode.shortTitle(language) + " · " + dataStore.displayName + language.text(
            " · \(dataStore.dataset.rows.count)点",
            " · \(dataStore.dataset.rows.count) observations"
        )
    }

    private var compactDatasetStatus: String {
        language.text(
            "\(dataStore.mode.shortTitle(language)) · \(dataStore.dataset.rows.count)点",
            "\(dataStore.mode.shortTitle(language)) · \(dataStore.dataset.rows.count) rows"
        )
    }

    private var availableWorkspaces: [Workspace] {
        Workspace.allCases.filter { $0.isAvailable(in: dataStore.mode) }
    }

    var body: some View {
        NavigationSplitView {
            VStack(spacing: 0) {
                ResearchModeSwitcher(
                    language: language,
                    selectedMode: dataStore.mode,
                    onSelect: switchResearchMode
                )
                .padding(.horizontal, 12)
                .padding(.vertical, 10)

                Divider()

                List(selection: $workspace) {
                    Section(dataStore.mode.title(language)) {
                        ForEach(availableWorkspaces) { item in
                            Label(item.title(language, mode: dataStore.mode), systemImage: item.symbol)
                                .tag(item)
                                .accessibilityLabel(item.title(language, mode: dataStore.mode))
                                .accessibilityIdentifier(item.accessibilityIdentifier)
                        }
                    }
                }
            }
            .navigationTitle("Permeation Lab")
            .navigationSplitViewColumnWidth(min: 230, ideal: 270, max: 310)
        } detail: {
            VStack(spacing: 0) {
                ResearchContextBar(
                    language: language,
                    mode: dataStore.mode,
                    scientificStatus: dataStore.scientificStatus,
                    datasetName: dataStore.displayName,
                    rowCount: dataStore.dataset.rows.count,
                    hasPersonalDataset: dataStore.hasPersonalDataset,
                    importAction: { isImportingExperimentData = true },
                    clearAction: { isConfirmingPersonalDataClear = true }
                )

                Divider()

                Group {
                    switch workspace {
                    case .studyOverview:
                        StudyOverviewView(language: language, dataStore: dataStore)
                    case .literatureLibrary:
                        LiteratureLibraryView(language: language)
                    case .researchHome:
                        ResearchHomeView(
                            language: language,
                            dataStore: dataStore,
                            importAction: { isImportingExperimentData = true },
                            openFickAudit: { workspace = .fick85Assessment },
                            openResearchData: { workspace = .dataSource },
                            openModelLab: { workspace = .modelSelection }
                        )
                    case .fick85Assessment:
                        Fick85AssessmentView(
                            language: language,
                            dataStore: dataStore,
                            experimentStore: experimentStore,
                            importAction: { isImportingExperimentData = true }
                        )
                    case .paperReader:
                        PaperReaderView(language: language)
                    case .methods:
                        MethodsReferenceView(language: language)
                    case .datasetImpact:
                        DatasetImpactView(language: language, dataStore: dataStore)
                    case .experiment:
                        ExperimentView(
                            language: language,
                            researchMode: dataStore.mode,
                            dataStore: dataStore,
                            experimentStore: experimentStore,
                            importAction: { isImportingExperimentData = true }
                        )
                    case .modelSelection:
                        ModelSelectionView(
                            language: language,
                            dataStore: dataStore,
                            modelStore: modelWorkspaceStore
                        )
                    case .modelEvidence:
                        ModelEvidenceView(language: language)
                    case .modelProfiles:
                        ModelProfileView(language: language, dataStore: dataStore)
                    case .paperFigures:
                        PaperFiguresView(language: language, dataStore: dataStore)
                    case .skinPermeation:
                        SkinPermeationView(language: language, dataStore: dataStore)
                    case .dataSource:
                        DataSourceView(
                            language: language,
                            dataStore: dataStore,
                            importAction: { isImportingExperimentData = true }
                        )
                    case .integrity:
                        ResearchIntegrityView(language: language, dataStore: dataStore)
                    }
                }
            }
            .navigationTitle(workspace.title(language, mode: dataStore.mode))
            .toolbar {
                ToolbarItem {
                    ViewThatFits(in: .horizontal) {
                        Label(datasetStatus, systemImage: "doc.text")
                            .fixedSize()
                        Label(compactDatasetStatus, systemImage: "doc.text")
                            .fixedSize()
                        Label("\(dataStore.dataset.rows.count)", systemImage: "doc.text")
                            .fixedSize()
                    }
                    .labelStyle(.titleAndIcon)
                    .foregroundStyle(.secondary)
                    .help(datasetStatus)
                    .accessibilityLabel(datasetStatus)
                    .accessibilityIdentifier("toolbar.dataset-status")
                }

                ToolbarItemGroup {
                    if dataStore.mode == .paperEvidence {
                        Button {
                            showReportedTable = true
                        } label: {
                            Label(
                                language.text("報告性能", "Reported metrics"),
                                systemImage: "tablecells.badge.ellipsis"
                            )
                        }
                        .help(language.text("原著Table 4を表示", "Show the paper's Table 4"))
                        .accessibilityIdentifier("toolbar.reported-metrics")
                    }

                    Picker(
                        language.text("言語", "Language"),
                        selection: $languageCode
                    ) {
                        ForEach(AppLanguage.allCases) { item in
                            Text(item.displayName(in: language)).tag(item.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 180)
                    .accessibilityIdentifier("language.picker")
                    .help(language.text("表示言語を切り替える", "Change display language"))
                }
            }
        }
        .navigationSplitViewStyle(.balanced)
        .onChange(of: dataStore.trainingRevision) { _, revision in
            synchronizeExperimentDataset(revision: revision)
        }
        .onChange(of: workspace) { _, newWorkspace in
            if dataStore.mode == .paperEvidence {
                lastPaperWorkspace = newWorkspace
            } else {
                lastExperimentWorkspace = newWorkspace
            }
        }
        .onAppear {
            synchronizeExperimentDataset(revision: dataStore.trainingRevision)
        }
        .sheet(isPresented: $showReportedTable) {
            ReportedMetricsSheet(
                language: language,
                isPresented: $showReportedTable
            )
        }
        .fileImporter(
            isPresented: $isImportingExperimentData,
            allowedContentTypes: [.commaSeparatedText, .plainText]
        ) { result in
            switch result {
            case .success(let url): importPersonalCSV(url)
            case .failure(let error):
                if (error as NSError).code != NSUserCancelledError {
                    experimentDataError = localizedDatasetError(error)
                }
            }
        }
        .alert(
            language.text("実験データを読み込めません", "Unable to import experiment data"),
            isPresented: Binding(
                get: { experimentDataError != nil },
                set: { if !$0 { experimentDataError = nil } }
            )
        ) {
            Button("OK", role: .cancel) { experimentDataError = nil }
        } message: {
            Text(experimentDataError ?? "")
        }
        .confirmationDialog(
            language.text("自分の研究データを外しますか？", "Remove My Research data?"),
            isPresented: $isConfirmingPersonalDataClear,
            titleVisibility: .visible
        ) {
            Button(language.text("データを外す", "Remove data"), role: .destructive) {
                dataStore.clearPersonalDataset()
            }
            Button(language.text("キャンセル", "Cancel"), role: .cancel) {}
        } message: {
            Text(language.text(
                "確認済みData S1と保存済みrun履歴は変更されません。",
                "Verified Data S1 and saved run history are not changed."
            ))
        }
        .environment(\.locale, language.locale)
        .accessibilityIdentifier("app.root")
    }

    private func switchResearchMode(_ mode: ResearchMode) {
        if dataStore.mode == .paperEvidence {
            lastPaperWorkspace = workspace
        } else {
            lastExperimentWorkspace = workspace
        }

        dataStore.selectMode(mode)
        workspace = mode == .paperEvidence ? lastPaperWorkspace : lastExperimentWorkspace
        if !availableWorkspaces.contains(workspace) {
            workspace = mode == .paperEvidence ? .studyOverview : .researchHome
        }
    }

    private func synchronizeExperimentDataset(revision: Int) {
        experimentStore.updateDataset(
            dataStore.dataset,
            displayName: dataStore.displayName,
            isBundledData: dataStore.isBundledData,
            revision: revision,
            researchMode: dataStore.mode,
            scientificStatus: dataStore.scientificStatus,
            importedAt: dataStore.mode == .myExperiment ? dataStore.personalImportedAt : nil
        )
    }

    private func importPersonalCSV(_ url: URL) {
        let accessed = url.startAccessingSecurityScopedResource()
        defer { if accessed { url.stopAccessingSecurityScopedResource() } }
        do {
            let text = try String(contentsOf: url, encoding: .utf8)
            try dataStore.importPersonalDataset(csvText: text, fileName: url.lastPathComponent)
        } catch {
            experimentDataError = localizedDatasetError(error)
        }
    }

    private func localizedDatasetError(_ error: Error) -> String {
        if let replacementError = error as? DatasetReplacementError {
            return replacementError.message(language)
        }
        return language.text(
            "ファイルを読み込めませんでした: \(error.localizedDescription)",
            "Could not read the file: \(error.localizedDescription)"
        )
    }
}

private struct ResearchModeSwitcher: View {
    @Environment(\.colorScheme) private var colorScheme

    let language: AppLanguage
    let selectedMode: ResearchMode
    let onSelect: (ResearchMode) -> Void

    var body: some View {
        HStack(spacing: 6) {
            ForEach(ResearchMode.allCases) { mode in
                Button {
                    onSelect(mode)
                } label: {
                    VStack(spacing: 5) {
                        Image(systemName: mode.symbol)
                            .font(.body.weight(.semibold))
                            .foregroundStyle(mode.tint)
                            .accessibilityHidden(true)
                        Text(mode.shortTitle(language))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 9)
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                    .background(
                        mode == selectedMode
                            ? mode.tint.opacity(colorScheme == .dark ? 0.22 : 0.13)
                            : LabTheme.surface(colorScheme),
                        in: RoundedRectangle(cornerRadius: 11, style: .continuous)
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 11, style: .continuous)
                            .stroke(
                                mode == selectedMode
                                    ? mode.tint.opacity(0.85)
                                    : LabTheme.border(colorScheme).opacity(0.70),
                                lineWidth: mode == selectedMode ? 1.5 : 0.5
                            )
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(mode.title(language))
                .accessibilityHint(mode.explanation(language))
                .accessibilityValue(
                    mode == selectedMode
                        ? language.text("選択中", "Selected")
                        : language.text("未選択", "Not selected")
                )
                .accessibilityAddTraits(mode == selectedMode ? .isSelected : [])
                .accessibilityIdentifier("mode.\(mode.rawValue)")
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(language.text("事実と自分の研究の切替", "Switch between Facts and My Research"))
        .accessibilityIdentifier("mode.selector")
    }
}

private struct ResearchContextBar: View {
    let language: AppLanguage
    let mode: ResearchMode
    let scientificStatus: ScientificDataStatus
    let datasetName: String
    let rowCount: Int
    let hasPersonalDataset: Bool
    let importAction: () -> Void
    let clearAction: () -> Void

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 12) {
                summary
                Spacer(minLength: 12)
                actions
            }
            VStack(alignment: .leading, spacing: 8) {
                summary
                actions
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 9)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(mode.tint.opacity(0.055))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("mode.context")
    }

    private var summary: some View {
        HStack(spacing: 9) {
            Label(mode.title(language), systemImage: mode.symbol)
                .font(.callout.weight(.semibold))
                .foregroundStyle(mode.tint)
            Text("·")
                .foregroundStyle(.tertiary)
            if mode == .paperEvidence {
                Text(language.text(
                    "出典確認済み · \(datasetName) · \(rowCount)行",
                    "Source-backed · \(datasetName) · \(rowCount) rows"
                ))
            } else if hasPersonalDataset {
                Text(language.text(
                    "研究データ・科学的妥当性は未検証 · \(datasetName) · \(rowCount)行",
                    "Scientific validity unverified · \(datasetName) · \(rowCount) rows"
                ))
            } else {
                Text(language.text(
                    "論文データは使用していません · CSVを読み込んでください",
                    "Paper data are not in use · import a CSV"
                ))
            }
        }
        .font(.callout)
        .lineLimit(2)
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityElement(children: .combine)
        .accessibilityValue(scientificStatus.title(language))
    }

    @ViewBuilder
    private var actions: some View {
        if mode == .myExperiment {
            HStack(spacing: 8) {
                Button {
                    importAction()
                } label: {
                    Label(
                        hasPersonalDataset
                            ? language.text("CSVを入れ替える", "Replace CSV")
                            : language.text("実験CSVを読み込む", "Import experiment CSV"),
                        systemImage: "square.and.arrow.down"
                    )
                }
                .buttonStyle(.borderedProminent)
                .accessibilityIdentifier("mode.import-experiment-data")

                if hasPersonalDataset {
                    Button(role: .destructive) {
                        clearAction()
                    } label: {
                        Label(language.text("データを外す", "Remove data"), systemImage: "xmark.circle")
                    }
                    .accessibilityIdentifier("mode.clear-experiment-data")
                }
            }
        }
    }
}

extension ResearchMode {
    func title(_ language: AppLanguage) -> String {
        switch self {
        case .paperEvidence: language.text("確認済み事実", "Verified Facts")
        case .myExperiment: language.text("自分の研究", "My Research")
        }
    }

    func shortTitle(_ language: AppLanguage) -> String {
        switch self {
        case .paperEvidence: language.text("事実", "Facts")
        case .myExperiment: language.text("研究", "Research")
        }
    }

    func explanation(_ language: AppLanguage) -> String {
        switch self {
        case .paperEvidence:
            language.text(
                "原著、公開補足資料、確認済みData S1だけを読み取り専用で表示",
                "Read-only paper, public supplements, and verified Data S1"
            )
        case .myExperiment:
            language.text(
                "計算、CSV、run履歴を事実タブと分離して探索",
                "Explore calculations, CSVs, and run history separately from facts"
            )
        }
    }

    var symbol: String {
        switch self {
        case .paperEvidence: "checkmark.shield.fill"
        case .myExperiment: "flask.fill"
        }
    }

    var tint: Color {
        switch self {
        case .paperEvidence: .green
        case .myExperiment: .orange
        }
    }
}

private struct ReportedMetricsSheet: View {
    let language: AppLanguage
    @Binding var isPresented: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(language.text("原著Table 4", "Paper Table 4"))
                            .font(.title.bold())
                        Text(language.text("報告性能（未再現）", "Reported performance (not reproduced)"))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button(language.text("閉じる", "Close")) {
                        isPresented = false
                    }
                    .keyboardShortcut(.cancelAction)
                    .accessibilityIdentifier("reported-metrics.close")
                }

                Text(
                    language.text(
                        "Yuan et al. (2023) · 191データ点 · 7:3無作為分割",
                        "Yuan et al. (2023) · 191 data points · 7:3 random split"
                    )
                )
                    .foregroundStyle(.secondary)

                Grid(alignment: .leading, horizontalSpacing: 26, verticalSpacing: 14) {
                    GridRow {
                        Text(language.text("モデル", "Model")).bold()
                        Text(language.text("量 RMSE", "Amount RMSE")).bold()
                        Text(language.text("量 R²", "Amount R²")).bold()
                        Text(language.text("率 RMSE", "Percent RMSE")).bold()
                        Text(language.text("率 R²", "Percent R²")).bold()
                    }
                    Divider().gridCellColumns(5)
                    ForEach(PaperMetric.reported) { row in
                        GridRow {
                            Label(row.model.rawValue, systemImage: "circle.fill")
                                .foregroundStyle(row.model.color)
                            Text(row.amountRMSE.formatted(.number.precision(.fractionLength(2))))
                            Text(row.amountR2.formatted(.number.precision(.fractionLength(2))))
                            Text(row.percentageRMSE.formatted(.number.precision(.fractionLength(2))))
                            Text(row.percentageR2.formatted(.number.precision(.fractionLength(2))))
                        }
                    }
                }

                Text(
                    language.text(
                        "量RMSEは原著表記µg、率RMSEは%。RMSEは小さいほど、R²は1に近いほど良好と定義されています。",
                        "Amount RMSE is labelled µg in the paper; percentage RMSE is %. Lower RMSE and R² closer to 1 are defined as better."
                    )
                )
                .font(.callout)

                LabNotice(
                    title: language.text("監査注記", "Audit note"),
                    message: language.text(
                        "値の転記は正確ですが、式(7)・式(8)とData S1の範囲に対して内部不整合があり、公開資料だけでは再現できません。",
                        "The transcription is exact, but the metrics are internally inconsistent with Equations (7)-(8) and the Data S1 ranges, and cannot be reproduced from the released materials."
                    ),
                    kind: .warning
                )

                HStack(spacing: 18) {
                    Link(
                        language.text("PubMedを開く", "Open PubMed"),
                        destination: URL(string: "https://pubmed.ncbi.nlm.nih.gov/38023708/")!
                    )
                    Link(
                        language.text("全文を開く", "Open full text"),
                        destination: URL(string: "https://pmc.ncbi.nlm.nih.gov/articles/PMC10658566/")!
                    )
                }
            }
            .padding(30)
            .frame(maxWidth: 860, alignment: .leading)
        }
        .frame(minWidth: 780, minHeight: 520)
        .accessibilityIdentifier("sheet.reported-metrics")
    }
}
