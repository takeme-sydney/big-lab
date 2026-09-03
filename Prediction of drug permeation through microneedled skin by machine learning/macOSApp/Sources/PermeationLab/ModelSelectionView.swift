import SwiftUI
import UniformTypeIdentifiers

struct ModelSelectionView: View {
    let language: AppLanguage
    @ObservedObject var dataStore: AppDatasetStore
    @ObservedObject var modelStore: ModelWorkspaceStore

    @State private var dataset = GenericDataset.paperData
    @State private var target = GenericDataset.paperData.headers.firstIndex(of: "Permeation amount") ?? 9
    @State private var group: Int? = 0
    @State private var features: Set<Int> = Set(1...7)
    @State private var report: ModelSelectionReport?
    @State private var selectedFamily: CandidateFamily = .linear
    @State private var predictionReport: LocalPredictionReport?
    @State private var errorMessage: String?
    @State private var isImportingTrainingData = false
    @State private var isImportingModel = false
    @State private var isImportingPredictionData = false
    @State private var isEvaluating = false
    @State private var isTraining = false
    @State private var isUsingAppData = true
    @State private var evaluationTask: Task<Void, Never>?
    @State private var trainingTask: Task<Void, Never>?
    @State private var isExportingModel = false
    @State private var isExportingPredictions = false
    @State private var modelDocument = ExperimentJSONDocument(data: Data("{}".utf8))
    @State private var predictionDocument = ModelCSVDocument(data: Data())
    @State private var csvExportFilename = "permeation-predictions"
    @State private var isConfirmingModelClear = false

    private var leakageAudit: DataLeakageAudit {
        DataLeakageAudit.review(
            dataset: dataset,
            target: target,
            group: group,
            features: usableFeatures
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                LabWorkspaceHeader(
                    title: language.text("はじめての機械学習", "Local machine-learning studio"),
                    subtitle: language.text(
                        "データ確認から学習済みモデル・未知データ予測まで、このMacだけで進める",
                        "Go from data checks to a trained model and new-data predictions entirely on this Mac"
                    ),
                    systemImage: "wand.and.stars.inverse"
                )

                workflowStrip

                LabNotice(
                    title: language.text("最初に予測の問いを決めます", "Start with the prediction question"),
                    message: language.text(
                        "同じ薬物の新しい時点、別の実験run、未知薬物では必要な分割が違います。run/curve IDがあれば分割グループにし、未知薬物を試すなら薬物名を選びます。ここでの交差検証は内部評価であり、独立した外部検証ではありません。",
                        "A new time point, a new experimental run, and an unseen drug require different splits. Use run/curve ID as the split group when available, or drug name for an unseen-drug question. Cross-validation here is internal evaluation, not independent external validation."
                    ),
                    kind: .information
                )

                dataStep
                designStep
                validationStep
                modelStep
                predictionStep

                LabNotice(
                    title: language.text("研究用途のみ", "Research use only"),
                    message: language.text(
                        "この軽量native実装は回帰研究の学習支援です。XGBoostそのものではなく、診断、投与量、治療効果、毒性、患者安全性の判断には使えません。",
                        "This lightweight native implementation supports regression research. It is not XGBoost and must not be used for diagnosis, dosing, efficacy, toxicity, or patient-safety decisions."
                    ),
                    kind: .warning
                )
            }
            .frame(maxWidth: LabTheme.contentWidth, alignment: .leading)
            .padding(LabTheme.pagePadding)
            .frame(maxWidth: .infinity, alignment: .top)
        }
        .fileImporter(
            isPresented: $isImportingTrainingData,
            allowedContentTypes: [.commaSeparatedText, .plainText]
        ) { result in handleTrainingImport(result) }
        .fileImporter(isPresented: $isImportingModel, allowedContentTypes: [.json]) { result in
            handleModelImport(result)
        }
        .fileImporter(
            isPresented: $isImportingPredictionData,
            allowedContentTypes: [.commaSeparatedText, .plainText]
        ) { result in handlePredictionImport(result) }
        .fileExporter(
            isPresented: $isExportingModel,
            document: modelDocument,
            contentType: .json,
            defaultFilename: modelFilename
        ) { handleExportResult($0) }
        .fileExporter(
            isPresented: $isExportingPredictions,
            document: predictionDocument,
            contentType: .commaSeparatedText,
            defaultFilename: csvExportFilename
        ) { handleExportResult($0) }
        .alert(
            language.text("処理を完了できません", "Unable to complete the operation"),
            isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
        .confirmationDialog(
            language.text("このMacに保存したモデルを削除しますか？", "Remove the model saved on this Mac?"),
            isPresented: $isConfirmingModelClear,
            titleVisibility: .visible
        ) {
            Button(language.text("モデルを削除", "Remove model"), role: .destructive) {
                modelStore.clear()
                predictionReport = nil
            }
            Button(language.text("キャンセル", "Cancel"), role: .cancel) {}
        }
        .onChange(of: target) { _, newValue in
            if group == newValue { group = nil }
            features = DataLeakageAudit.recommendedFeatures(
                dataset: dataset,
                target: newValue,
                group: group
            )
            invalidateValidation()
        }
        .onChange(of: group) { _, newValue in
            if let newValue { features.remove(newValue) }
            invalidateValidation()
        }
        .onAppear { useCurrentAppData() }
        .onChange(of: dataStore.revision) { _, _ in useCurrentAppData() }
        .onDisappear {
            evaluationTask?.cancel()
            trainingTask?.cancel()
        }
        .accessibilityIdentifier("screen.model-selection")
    }

    private var workflowStrip: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 155), spacing: 8)],
            alignment: .leading,
            spacing: 8
        ) {
            workflowBadge(number: "1", title: language.text("データ", "Data"), complete: !dataset.rows.isEmpty)
            workflowBadge(number: "2", title: language.text("内部評価", "Internal CV"), complete: report != nil)
            workflowBadge(number: "3", title: language.text("最終学習", "Final fit"), complete: modelStore.artifact != nil)
            workflowBadge(number: "4", title: language.text("未知データ予測", "New-data prediction"), complete: predictionReport != nil)
        }
        .accessibilityIdentifier("selector.workflow")
    }

    private func workflowBadge(number: String, title: String, complete: Bool) -> some View {
        HStack(spacing: 8) {
            Image(systemName: complete ? "checkmark.circle.fill" : "\(number).circle")
                .foregroundStyle(complete ? .green : .secondary)
            Text(title).font(.callout.weight(.semibold))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.quaternary.opacity(0.45), in: RoundedRectangle(cornerRadius: 9))
    }

    private var dataStep: some View {
        LabSection(language.text("1. 学習データを選ぶ", "1. Choose training data")) {
            VStack(alignment: .leading, spacing: 14) {
                LabResponsiveActionHeader {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(datasetDisplayName).font(.headline)
                        Text(language.text(
                            "\(dataset.rows.count)行 · \(dataset.headers.count)列 · hash \(dataset.normalizedSHA256.prefix(10))…",
                            "\(dataset.rows.count) rows · \(dataset.headers.count) columns · hash \(dataset.normalizedSHA256.prefix(10))…"
                        ))
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                    }
                } actions: {
                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: 8) { dataActionButtons }
                        VStack(alignment: .leading, spacing: 8) { dataActionButtons }
                    }
                }
                .accessibilityIdentifier("selector.data-actions")

                if dataset.rows.isEmpty {
                    LabNotice(
                        title: language.text("学習データがありません", "No training data"),
                        message: language.text(
                            "CSVを読み込んでください。1行目は重複のない列名、目的変数は数値、最低20行が必要です。",
                            "Import a CSV. The first row needs unique column names, the target must be numeric, and at least 20 rows are required."
                        ),
                        kind: .limitation
                    )
                }

                Text(language.text(
                    "CSVは端末内で読み取り、学習中にネットワークへ送信しません。最大5,000行です。単位は列名と研究記録で固定してください。",
                    "The CSV is read and trained on-device and is not sent over the network. The limit is 5,000 rows. Fix units in column names and the study record."
                ))
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            .padding(.top, 4)
        }
    }

    @ViewBuilder private var dataActionButtons: some View {
        Button(language.text("現在の研究データ", "Current app data"), systemImage: "arrow.counterclockwise") {
            useCurrentAppData()
        }
        if dataStore.comparisonDataset != nil {
            Button(language.text("比較研究データ", "Comparison study"), systemImage: "arrow.left.arrow.right") {
                useComparisonData()
            }
        }
        Button(language.text("学習CSVを読み込む", "Import training CSV"), systemImage: "square.and.arrow.down") {
            isImportingTrainingData = true
        }
        .buttonStyle(.borderedProminent)
        .accessibilityIdentifier("selector.import-training")
    }

    private var designStep: some View {
        LabSection(language.text("2. 答え・分割・説明変数を決める", "2. Choose target, split, and predictors")) {
            VStack(alignment: .leading, spacing: 16) {
                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 270), spacing: 18)],
                    alignment: .leading,
                    spacing: 16
                ) {
                    field(language.text("目的変数（予測したい数値）", "Target (numeric value to predict)")) {
                        Picker(language.text("目的変数", "Target"), selection: $target) {
                            ForEach(dataset.numericColumns, id: \.self) { index in
                                Text(headerName(at: index)).tag(index)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .accessibilityIdentifier("selector.target")
                    }
                    field(language.text("分割グループ（内部CV）", "Split group (internal CV)")) {
                        Picker(language.text("分割グループ", "Split group"), selection: $group) {
                            Text(language.text("指定なし（行単位・非推奨）", "None (row-wise; usually unsafe)"))
                                .tag(Optional<Int>.none)
                            ForEach(dataset.headers.indices.filter { $0 != target }, id: \.self) { index in
                                Text(headerName(at: index)).tag(Optional(index))
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .accessibilityIdentifier("selector.group")
                    }
                }

                Text(language.text(
                    "分割グループはモデルへ入力しません。同じrun/curve/患者/batchの行を学習側と検証側に分けないための印です。Data S1で未知薬物を問う場合は「薬物」を使います。",
                    "The split group is not fed to the model. It keeps rows from the same run, curve, patient, or batch out of both training and validation. Use Drug for an unseen-drug question in Data S1."
                ))
                .font(.caption)
                .foregroundStyle(.secondary)

                DisclosureGroup(language.text(
                    "説明変数を確認（\(usableFeatures.count)列）",
                    "Review predictors (\(usableFeatures.count) columns)"
                )) {
                    LazyVGrid(
                        columns: [GridItem(.adaptive(minimum: 220), spacing: 8)],
                        alignment: .leading,
                        spacing: 8
                    ) {
                        ForEach(dataset.headers.indices.filter { $0 != target && $0 != group }, id: \.self) { index in
                            Toggle(headerName(at: index), isOn: Binding(
                                get: { features.contains(index) },
                                set: { enabled in
                                    if enabled { features.insert(index) } else { features.remove(index) }
                                    invalidateValidation()
                                }
                            ))
                        }
                    }
                    .padding(.top, 10)
                }

                leakageFindings

                if let readinessIssue {
                    LabNotice(
                        title: language.text("まだ内部CVを開始できません", "Internal CV is not ready yet"),
                        message: readinessIssue,
                        kind: .limitation
                    )
                    .accessibilityIdentifier("selector.readiness-issue")
                }

                HStack(spacing: 10) {
                    if isEvaluating {
                        ProgressView()
                        Text(language.text("3候補を端末内で計算中…", "Evaluating three candidates on-device…"))
                            .foregroundStyle(.secondary)
                        Button(language.text("中止", "Cancel"), role: .cancel) {
                            evaluationTask?.cancel()
                            isEvaluating = false
                        }
                    } else {
                        Button {
                            evaluate()
                        } label: {
                            Label(language.text("漏洩を確認して内部CV", "Check leakage and run internal CV"), systemImage: "play.fill")
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(!canEvaluate)
                        .accessibilityIdentifier("selector.evaluate")
                    }
                }
            }
            .padding(.top, 4)
        }
    }

    @ViewBuilder private var leakageFindings: some View {
        if leakageAudit.findings.isEmpty {
            Label(language.text("既知の重大な漏洩パターンは見つかりません", "No known critical leakage pattern detected"), systemImage: "checkmark.shield.fill")
                .font(.callout.weight(.semibold))
                .foregroundStyle(.green)
                .accessibilityIdentifier("selector.leakage-clear")
        } else {
            ForEach(leakageAudit.findings) { finding in
                LabNotice(
                    title: finding.title.resolve(language),
                    message: finding.detail.resolve(language),
                    kind: finding.severity == .blocker ? .warning : .limitation
                )
                .accessibilityIdentifier("selector.leakage-\(finding.id)")
            }
        }
    }

    private var validationStep: some View {
        LabSection(language.text("3. 内部CVで候補を比べる", "3. Compare candidates with internal CV")) {
            Group {
                if let report {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "flag.checkered")
                                .font(.title2)
                                .foregroundStyle(.tint)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(language.text("探索上の第一候補: ", "Exploratory first candidate: ") + report.winner.displayName(language))
                                    .font(.title3.bold())
                                Text(language.text(
                                    "最小RMSEの候補です。まだ外部データで確認した最終性能ではありません。",
                                    "This candidate has the lowest RMSE. It is not yet final performance confirmed on external data."
                                ))
                                .foregroundStyle(.secondary)
                            }
                        }

                        resultGrid(report)

                        Text(language.text(
                            "\(report.foldCount)分割・\(report.usedGroupHoldout ? "グループ保持" : "行単位")CV · 有効\(report.observationCount)行 · エンコード後\(report.featureCount)特徴量",
                            "\(report.foldCount)-fold \(report.usedGroupHoldout ? "group-preserving" : "row-wise") CV · \(report.observationCount) valid rows · \(report.featureCount) encoded features"
                        ))
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)

                        if !report.excludedColumns.isEmpty {
                            LabNotice(
                                title: language.text("学習から除外された列", "Columns excluded during fitting"),
                                message: report.excludedColumns.joined(separator: ", ") + language.text(
                                    "（空、定数、またはカテゴリ13種類以上）",
                                    " (empty, constant, or 13+ categories)"
                                ),
                                kind: .limitation
                            )
                        }
                        ForEach(report.warnings, id: \.self) { warning in
                            LabNotice(
                                title: language.text("解釈上の注意", "Interpretation check"),
                                message: warning.resolve(language),
                                kind: .limitation
                            )
                        }

                        Divider()

                        HStack(alignment: .bottom, spacing: 12) {
                            field(language.text("最終学習する候補", "Candidate to fit finally")) {
                                Picker(language.text("モデル", "Model"), selection: $selectedFamily) {
                                    ForEach(CandidateFamily.allCases) { family in
                                        Text(family.displayName(language)).tag(family)
                                    }
                                }
                                .labelsHidden()
                                .frame(minWidth: 210)
                                .accessibilityIdentifier("selector.final-family")
                            }

                            if isTraining {
                                ProgressView().controlSize(.small)
                            } else {
                                Button {
                                    trainFinalModel()
                                } label: {
                                    Label(language.text("全データで最終学習", "Fit final model on all rows"), systemImage: "cpu")
                                }
                                .buttonStyle(.borderedProminent)
                                .accessibilityIdentifier("selector.train")
                            }
                        }

                        Text(language.text(
                            "この操作は前処理とモデルを全有効行でfitし、再利用可能なartifactに固定します。全データfit後の見かけ性能は計算せず、上のOOF内部CVを記録します。",
                            "This fits preprocessing and the model on all valid rows and freezes a reusable artifact. It does not report in-sample performance after the final fit; the OOF internal-CV summary above is retained."
                        ))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                    .accessibilityIdentifier("selector.report")
                } else {
                    ContentUnavailableView {
                        Label(language.text("内部CVは未実行です", "Internal CV has not run"), systemImage: "chart.bar.doc.horizontal")
                    } description: {
                        Text(language.text(
                            "手順2で設定を確認し、内部CVを実行すると平均値baselineと3候補を同じfoldで比較します。",
                            "Review step 2 and run internal CV to compare the mean baseline and three candidates on identical folds."
                        ))
                    }
                    .frame(minHeight: 150)
                }
            }
            .padding(.top, 4)
        }
    }

    private func resultGrid(_ report: ModelSelectionReport) -> some View {
        Grid(alignment: .leading, horizontalSpacing: 18, verticalSpacing: 10) {
            GridRow {
                Text(language.text("候補", "Candidate")).bold()
                Text("RMSE").bold()
                Text("MAE").bold()
                Text("R²").bold()
                if report.usedGroupHoldout {
                    Text(language.text("group均等RMSE", "Group-balanced RMSE")).bold()
                }
            }
            Divider().gridCellColumns(report.usedGroupHoldout ? 5 : 4)
            GridRow {
                Text(language.text("平均値baseline", "Training-mean baseline"))
                Text(number(report.baselineRMSE))
                Text("—")
                Text("—")
                if report.usedGroupHoldout { Text("—") }
            }
            ForEach(report.metrics) { metric in
                GridRow {
                    HStack(spacing: 5) {
                        if metric.family == report.winner {
                            Image(systemName: "arrow.right.circle.fill").foregroundStyle(.tint)
                        }
                        Text(metric.family.displayName(language))
                    }
                    Text("\(number(metric.rmse)) ± \(number(metric.foldRMSEStandardDeviation))")
                    Text(number(metric.mae))
                    Text(number(metric.rSquared))
                    if report.usedGroupHoldout {
                        Text(metric.groupBalancedRMSE.map(number) ?? "—")
                    }
                }
            }
        }
        .font(.callout.monospacedDigit())
    }

    private var modelStep: some View {
        LabSection(language.text("4. 学習済みモデルを保存・再読込", "4. Save or reload the trained model")) {
            VStack(alignment: .leading, spacing: 14) {
                if let artifact = modelStore.artifact {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "externaldrive.fill.badge.checkmark")
                            .font(.title2)
                            .foregroundStyle(.green)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(artifact.family.displayName(language)).font(.headline)
                            Text(language.text(
                                "\(artifact.trainingRowCount)行で学習 · 目的変数: \(artifact.targetName)",
                                "Trained on \(artifact.trainingRowCount) rows · target: \(artifact.targetName)"
                            ))
                            .foregroundStyle(.secondary)
                            Text("ID \(artifact.id.uuidString) · \(artifact.datasetNormalizedSHA256.prefix(12))…")
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityIdentifier("selector.model-card")

                    LazyVGrid(
                        columns: [GridItem(.adaptive(minimum: 210), spacing: 10)],
                        alignment: .leading,
                        spacing: 10
                    ) {
                        compactFact(language.text("エンジン", "Engine"), artifact.engineVersion)
                        compactFact(language.text("分割", "Split"), artifact.groupName ?? language.text("行単位", "Row-wise"))
                        compactFact(language.text("内部CV RMSE", "Internal-CV RMSE"), number(artifact.validation.selectedRMSE))
                        compactFact(language.text("入力次元", "Input dimensions"), "\(artifact.encodedFeatureCount)")
                    }

                    DisclosureGroup(language.text("モデルカード: 必要な入力列と学習範囲", "Model card: required columns and training ranges")) {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(artifact.featureProfiles) { profile in
                                HStack(alignment: .firstTextBaseline) {
                                    Text(profile.name).font(.callout.weight(.semibold))
                                    Spacer()
                                    Text(featureProfileDescription(profile))
                                        .font(.caption.monospacedDigit())
                                        .foregroundStyle(.secondary)
                                }
                                Divider()
                            }
                        }
                        .padding(.top, 8)
                    }

                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: 9) { modelActionButtons }
                        VStack(alignment: .leading, spacing: 9) { modelActionButtons }
                    }
                } else {
                    ContentUnavailableView {
                        Label(language.text("学習済みモデルはありません", "No trained model"), systemImage: "externaldrive.badge.questionmark")
                    } description: {
                        Text(language.text(
                            "手順3から最終学習するか、以前に保存したPermeation LabモデルJSONを読み込んでください。",
                            "Fit a final model in step 3 or import a previously saved Permeation Lab model JSON."
                        ))
                    } actions: {
                        Button(language.text("モデルJSONを読み込む", "Import model JSON"), systemImage: "square.and.arrow.down") {
                            isImportingModel = true
                        }
                        .buttonStyle(.borderedProminent)
                        .accessibilityIdentifier("selector.import-model")
                    }
                    .frame(minHeight: 180)
                }
            }
            .padding(.top, 4)
        }
    }

    @ViewBuilder private var modelActionButtons: some View {
        Button(language.text("モデルJSONを書き出す", "Export model JSON"), systemImage: "square.and.arrow.up") {
            exportModel()
        }
        .buttonStyle(.borderedProminent)
        .accessibilityIdentifier("selector.export-model")
        Button(language.text("別のモデルを読み込む", "Import another model"), systemImage: "square.and.arrow.down") {
            isImportingModel = true
        }
        .accessibilityIdentifier("selector.import-model")
        Button(language.text("このMacから削除", "Remove from this Mac"), systemImage: "trash", role: .destructive) {
            isConfirmingModelClear = true
        }
    }

    private var predictionStep: some View {
        LabSection(language.text("5. 未知CSVへ一括予測する", "5. Batch-predict a new CSV")) {
            VStack(alignment: .leading, spacing: 14) {
                if modelStore.artifact == nil {
                    Text(language.text(
                        "手順4でモデルを用意すると予測できます。未知CSVにはモデルカードの入力列が必要です。目的変数列はなくても構いません。",
                        "Prepare a model in step 4 to enable prediction. A new CSV needs the model-card input columns; the target column is optional."
                    ))
                    .foregroundStyle(.secondary)
                } else {
                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: 9) { predictionActionButtons }
                        VStack(alignment: .leading, spacing: 9) { predictionActionButtons }
                    }

                    Text(language.text(
                        "目的変数列がなければ予測だけを出力します。同名の目的変数列があれば、そのCSVを外部データとしてRMSE・MAE・R²を計算します。モデルの再fitは行いません。",
                        "Without the target column, the app exports predictions only. If a target column with the same name is present, it computes RMSE, MAE, and R² as an external-data evaluation. The model is never refitted."
                    ))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

                if let predictionReport {
                    predictionResult(predictionReport)
                }
            }
            .padding(.top, 4)
        }
    }

    @ViewBuilder private var predictionActionButtons: some View {
        Button(language.text("未知CSVを読み込んで予測", "Import new CSV and predict"), systemImage: "sparkles.rectangle.stack") {
            isImportingPredictionData = true
        }
        .buttonStyle(.borderedProminent)
        .accessibilityIdentifier("selector.import-prediction")
        Button(language.text("入力CSVテンプレート", "Input CSV template"), systemImage: "doc.badge.plus") {
            exportPredictionTemplate()
        }
        .accessibilityIdentifier("selector.export-prediction-template")
        Button(language.text("現在データで操作練習", "Practice with current data"), systemImage: "figure.play") {
            predictPracticeData()
        }
        .disabled(dataset.rows.isEmpty)
        .accessibilityIdentifier("selector.practice-prediction")
    }

    private func predictionResult(_ result: LocalPredictionReport) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Divider()
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(language.text("\(result.predictions.count)行の予測が完了", "Predicted \(result.predictions.count) rows"))
                        .font(.headline)
                    Text(result.datasetName).foregroundStyle(.secondary)
                }
                Spacer()
                Button(language.text("予測CSVを書き出す", "Export prediction CSV"), systemImage: "square.and.arrow.up") {
                    predictionDocument = ModelCSVDocument(data: result.csvData())
                    csvExportFilename = predictionFilename
                    isExportingPredictions = true
                }
                .buttonStyle(.borderedProminent)
                .accessibilityIdentifier("selector.export-predictions")
            }

            if result.isPracticeData {
                LabNotice(
                    title: language.text("これは操作練習で、外部評価ではありません", "Practice only — not external evaluation"),
                    message: language.text(
                        "学習に使ったデータを再予測しています。表示される誤差をモデル性能として報告しないでください。",
                        "These rows were used for training. Do not report the displayed errors as model performance."
                    ),
                    kind: .limitation
                )
            } else if let evaluation = result.evaluation {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 180), spacing: 10)], spacing: 10) {
                    compactFact("RMSE", number(evaluation.rmse))
                    compactFact("MAE", number(evaluation.mae))
                    compactFact("R²", evaluation.rSquared.map(number) ?? language.text("定義不可", "Undefined"))
                    compactFact("n", "\(evaluation.observationCount)")
                }
                LabNotice(
                    title: language.text("外部評価として扱う条件", "When this counts as external evaluation"),
                    message: language.text(
                        "このCSVがモデル・特徴量・閾値を決める間に一度も見ていない独立runである場合だけ、外部評価と呼べます。",
                        "Call this external evaluation only if these independent runs were never inspected while choosing the model, predictors, or thresholds."
                    ),
                    kind: .information
                )
            } else {
                Label(language.text("目的変数なし: 予測値のみ生成", "No target column: predictions only"), systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }

            diagnosticsView(result.diagnostics)

            DisclosureGroup(language.text("先頭8行の予測", "First eight predictions")) {
                Grid(alignment: .leading, horizontalSpacing: 18, verticalSpacing: 7) {
                    GridRow {
                        Text(language.text("CSV行", "CSV row")).bold()
                        Text(language.text("予測値", "Prediction")).bold()
                        Text(language.text("実測値", "Actual")).bold()
                    }
                    Divider().gridCellColumns(3)
                    ForEach(result.predictions.prefix(8)) { prediction in
                        GridRow {
                            Text("\(prediction.rowNumber)")
                            Text(number(prediction.predicted))
                            Text(prediction.actual.map(number) ?? "—")
                        }
                    }
                }
                .font(.callout.monospacedDigit())
                .padding(.top, 8)
            }
        }
        .accessibilityIdentifier("selector.prediction-report")
    }

    @ViewBuilder private func diagnosticsView(_ diagnostics: PredictionDataDiagnostics) -> some View {
        if diagnostics.hasWarnings {
            let messages = [
                diagnosticLine(language.text("欠測/非有限", "Missing/non-finite"), diagnostics.missingValueCounts),
                diagnosticLine(language.text("未知カテゴリ", "Unseen categories"), diagnostics.unseenCategoryCounts),
                diagnosticLine(language.text("学習範囲外", "Outside training range"), diagnostics.outsideTrainingRangeCounts),
            ].filter { !$0.isEmpty }
            LabNotice(
                title: language.text("入力分布の違いを確認してください", "Review input-distribution differences"),
                message: messages.joined(separator: "\n"),
                kind: .limitation
            )
        } else {
            Label(language.text("欠測・未知カテゴリ・学習範囲外を検出しませんでした", "No missing values, unseen categories, or out-of-range values detected"), systemImage: "checkmark.circle.fill")
                .font(.callout)
                .foregroundStyle(.green)
        }
    }

    private func diagnosticLine(_ title: String, _ values: [String: Int]) -> String {
        guard !values.isEmpty else { return "" }
        return title + ": " + values.keys.sorted().map {
            "\($0)=\(values[$0, default: 0])"
        }.joined(separator: ", ")
    }

    private func evaluate() {
        guard leakageAudit.canTrain else {
            errorMessage = language.text(
                "赤いデータ漏洩項目を解消してから実行してください。",
                "Resolve the red data-leakage items before running."
            )
            return
        }
        let capturedDataset = dataset
        let capturedTarget = target
        let capturedGroup = group
        let capturedFeatures = usableFeatures
        isEvaluating = true
        report = nil

        let worker = Task.detached(priority: .userInitiated) {
            try ModelSelectionEngine.evaluate(
                dataset: capturedDataset,
                target: capturedTarget,
                group: capturedGroup,
                features: capturedFeatures
            )
        }
        evaluationTask = Task {
            do {
                let result = try await withTaskCancellationHandler {
                    try await worker.value
                } onCancel: {
                    worker.cancel()
                }
                guard !Task.isCancelled else { return }
                report = result
                selectedFamily = result.winner
                errorMessage = nil
            } catch is CancellationError {
                // Cancellation is an expected user action.
            } catch {
                errorMessage = localizedMessage(for: error)
            }
            isEvaluating = false
        }
    }

    private func trainFinalModel() {
        guard let report else { return }
        let capturedDataset = dataset
        let capturedTarget = target
        let capturedGroup = group
        let capturedFeatures = usableFeatures
        let capturedFamily = selectedFamily
        isTraining = true

        let worker = Task.detached(priority: .userInitiated) {
            try ModelTrainingEngine.train(
                dataset: capturedDataset,
                target: capturedTarget,
                group: capturedGroup,
                features: capturedFeatures,
                family: capturedFamily,
                report: report
            )
        }
        trainingTask = Task {
            do {
                let artifact = try await withTaskCancellationHandler {
                    try await worker.value
                } onCancel: {
                    worker.cancel()
                }
                guard !Task.isCancelled else { return }
                try modelStore.install(artifact)
                predictionReport = nil
                errorMessage = nil
            } catch is CancellationError {
                // Cancellation is an expected user action.
            } catch {
                errorMessage = localizedMessage(for: error)
            }
            isTraining = false
        }
    }

    private func useCurrentAppData() {
        let current = GenericDataset.from(trainingDataset: dataStore.dataset, name: dataStore.displayName)
        applyDataset(current, usesAppDisplayNames: true)
    }

    private func useComparisonData() {
        guard let comparison = dataStore.comparisonDataset else { return }
        let rows = comparison.rows.map { row in
            [
                row.drugName,
                String(row.loading),
                String(row.molecularWeight),
                String(row.needleLength),
                String(row.skin.sourceCode),
                String(row.needle.sourceCode),
                String(row.surfaceArea),
                String(row.permeationTime),
                String(row.percentage),
                String(row.amount),
                row.reference,
            ]
        }
        applyDataset(
            GenericDataset(name: comparison.name, headers: TrainingDataSource.expectedHeader, rows: rows),
            usesAppDisplayNames: false
        )
    }

    private func applyDataset(_ imported: GenericDataset, usesAppDisplayNames: Bool) {
        dataset = imported
        target = imported.headers.firstIndex(of: "Permeation amount")
            ?? DataLeakageAudit.suggestedTarget(in: imported)
            ?? 0
        group = DataLeakageAudit.suggestedGroup(in: imported, excluding: target)
        features = imported.headers.indices.contains(target)
            ? DataLeakageAudit.recommendedFeatures(dataset: imported, target: target, group: group)
            : []
        report = nil
        predictionReport = nil
        errorMessage = nil
        isUsingAppData = usesAppDisplayNames
    }

    private func handleTrainingImport(_ result: Result<URL, Error>) {
        do {
            let url = try result.get()
            let text = try readSecurityScopedText(url)
            let imported = try GenericDataset.parse(name: url.lastPathComponent, text: text)
            guard !imported.numericColumns.isEmpty else {
                throw SelectionError.invalidCSV(BiText("有限な数値列が見つかりません。", "No finite numeric column was found."))
            }
            applyDataset(imported, usesAppDisplayNames: false)
        } catch {
            if (error as NSError).code != NSUserCancelledError {
                errorMessage = localizedMessage(for: error)
            }
        }
    }

    private func handleModelImport(_ result: Result<URL, Error>) {
        do {
            let url = try result.get()
            let data = try readSecurityScopedData(url)
            try modelStore.install(LocalModelArtifact.decode(data))
            predictionReport = nil
            errorMessage = nil
        } catch {
            if (error as NSError).code != NSUserCancelledError {
                errorMessage = localizedMessage(for: error)
            }
        }
    }

    private func handlePredictionImport(_ result: Result<URL, Error>) {
        do {
            let url = try result.get()
            let text = try readSecurityScopedText(url)
            let imported = try GenericDataset.parse(
                name: url.lastPathComponent,
                text: text,
                minimumColumnCount: 1
            )
            guard let artifact = modelStore.artifact else { return }
            predictionReport = try LocalPredictionEngine.predict(dataset: imported, with: artifact)
            errorMessage = nil
        } catch {
            if (error as NSError).code != NSUserCancelledError {
                errorMessage = localizedMessage(for: error)
            }
        }
    }

    private func predictPracticeData() {
        guard let artifact = modelStore.artifact else { return }
        do {
            predictionReport = try LocalPredictionEngine.predict(
                dataset: dataset,
                with: artifact,
                isPracticeData: true
            )
            errorMessage = nil
        } catch {
            errorMessage = localizedMessage(for: error)
        }
    }

    private func exportModel() {
        guard let artifact = modelStore.artifact else { return }
        do {
            modelDocument = ExperimentJSONDocument(data: try artifact.encodedData())
            isExportingModel = true
        } catch {
            errorMessage = localizedMessage(for: error)
        }
    }

    private func exportPredictionTemplate() {
        guard let artifact = modelStore.artifact else { return }
        let header = artifact.featureProfiles.map(\.name).map(csvEscaped).joined(separator: ",")
        predictionDocument = ModelCSVDocument(data: Data((header + "\n").utf8))
        csvExportFilename = "prediction-input-template"
        isExportingPredictions = true
    }

    private func csvEscaped(_ source: String) -> String {
        guard source.contains(",") || source.contains("\"") || source.contains("\n") || source.contains("\r") else {
            return source
        }
        return "\"" + source.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }

    private func handleExportResult(_ result: Result<URL, Error>) {
        if case .failure(let error) = result,
           (error as NSError).code != NSUserCancelledError {
            errorMessage = localizedMessage(for: error)
        }
    }

    private func readSecurityScopedText(_ url: URL) throws -> String {
        let accessed = url.startAccessingSecurityScopedResource()
        defer { if accessed { url.stopAccessingSecurityScopedResource() } }
        return try String(contentsOf: url, encoding: .utf8)
    }

    private func readSecurityScopedData(_ url: URL) throws -> Data {
        let accessed = url.startAccessingSecurityScopedResource()
        defer { if accessed { url.stopAccessingSecurityScopedResource() } }
        return try Data(contentsOf: url)
    }

    private func invalidateValidation() {
        evaluationTask?.cancel()
        trainingTask?.cancel()
        report = nil
        isEvaluating = false
        isTraining = false
    }

    private func field<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title).font(.caption.weight(.semibold)).foregroundStyle(.secondary)
            content()
        }
    }

    private func compactFact(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title).font(.caption.weight(.semibold)).foregroundStyle(.secondary)
            Text(value).font(.callout.monospacedDigit()).fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(.quaternary.opacity(0.45), in: RoundedRectangle(cornerRadius: 8))
    }

    private func number(_ value: Double) -> String {
        value.formatted(.number.precision(.significantDigits(4)))
    }

    private var canEvaluate: Bool {
        !isEvaluating && readinessIssue == nil
    }

    private var readinessIssue: String? {
        if dataset.rows.count < 20 {
            return language.text(
                "有効なデータ行を20件以上用意してください（現在\(dataset.rows.count)件）。",
                "Provide at least 20 valid data rows (currently \(dataset.rows.count))."
            )
        }
        if !dataset.numericColumns.contains(target) {
            return language.text(
                "90%以上が有限数値である目的変数を選んでください。NaNとInfinityは使用できません。",
                "Choose a target with finite numeric values in at least 90% of rows. NaN and infinity are not accepted."
            )
        }
        if usableFeatures.isEmpty {
            return language.text("説明変数を1列以上選んでください。", "Select at least one predictor.")
        }
        if let group {
            let validRows = dataset.rows.filter { finiteDouble($0[target]) != nil }
            let values = validRows.map { $0[group].trimmingCharacters(in: .whitespacesAndNewlines) }
            if values.contains(where: \.isEmpty) {
                return language.text(
                    "分割グループの空欄をすべて埋めてください。",
                    "Fill every blank value in the split-group column."
                )
            }
            if Set(values).count < 2 {
                return language.text(
                    "分割グループには2種類以上の値が必要です。",
                    "The split-group column needs at least two distinct values."
                )
            }
        }
        return leakageAudit.canTrain ? nil : language.text(
            "赤いデータ漏洩項目を解消してください。",
            "Resolve the red data-leakage items."
        )
    }

    private var usableFeatures: Set<Int> {
        features.subtracting([target]).subtracting(group.map { [$0] } ?? [])
    }

    private var datasetDisplayName: String {
        dataset.name.isEmpty ? language.text("名称なし", "Untitled") : dataset.name
    }

    private var modelFilename: String {
        guard let artifact = modelStore.artifact else { return "permeation-model" }
        return "permeation-model-\(artifact.id.uuidString.prefix(8))"
    }

    private var predictionFilename: String {
        guard let report = predictionReport else { return "permeation-predictions" }
        let stem = report.datasetName.replacingOccurrences(of: ".csv", with: "")
        return "\(stem)-predictions"
    }

    private func featureProfileDescription(_ profile: ModelFeatureProfile) -> String {
        switch profile.kind {
        case .numeric:
            guard let minimum = profile.numericMinimum, let maximum = profile.numericMaximum else {
                return language.text("数値", "Numeric")
            }
            return language.text(
                "数値 · 学習範囲 \(number(minimum))…\(number(maximum)) · 欠測\(profile.missingTrainingCount)",
                "Numeric · training range \(number(minimum))…\(number(maximum)) · missing \(profile.missingTrainingCount)"
            )
        case .categorical:
            return language.text(
                "カテゴリ: \(profile.categoricalLevels.joined(separator: ", "))",
                "Categories: \(profile.categoricalLevels.joined(separator: ", "))"
            )
        }
    }

    private func headerName(at index: Int) -> String {
        guard dataset.headers.indices.contains(index) else { return "—" }
        let header = dataset.headers[index]
        guard isUsingAppData else { return header }
        switch header {
        case "Drug": return language.text("薬物", header)
        case "Loading": return language.text("薬物負荷量", header)
        case "Molecular weight": return language.text("分子量", header)
        case "MN length": return language.text("MN長", header)
        case "Skin": return language.text("皮膚", header)
        case "MN type": return language.text("MNタイプ", header)
        case "Surface area": return language.text("表面積", header)
        case "Time": return language.text("透過時間", header)
        case "Permeation percentage": return language.text("透過率", header)
        case "Permeation amount": return language.text("透過量", header)
        default: return header
        }
    }

    private func localizedMessage(for error: Error) -> String {
        if let selectionError = error as? SelectionError {
            return selectionError.message(language)
        }
        if let artifactError = error as? LocalModelArtifactError {
            return artifactError.message(language)
        }
        return language.text("処理に失敗しました。", "The operation failed.") + " " + error.localizedDescription
    }
}

struct ModelCSVDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.commaSeparatedText, .plainText] }
    var data: Data

    init(data: Data) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        data = configuration.file.regularFileContents ?? Data()
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}
