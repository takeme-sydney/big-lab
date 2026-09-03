import AppKit
import Charts
import SwiftUI
import UniformTypeIdentifiers

struct ExperimentView: View {
    let language: AppLanguage
    let researchMode: ResearchMode
    @ObservedObject var dataStore: AppDatasetStore
    @ObservedObject var experimentStore: ExperimentStore
    let importAction: () -> Void

    @State private var selectedModel: ExperimentModelKind = .nativeGradientTreeBoosting
    @State private var isExporting = false
    @State private var exportDocument = ExperimentJSONDocument(data: Data("{}".utf8))
    @State private var exportError: String?
    @State private var isConfirmingHistoryClear = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                LabWorkspaceHeader(
                    title: language.text("エクスペリメント", "Experiment"),
                    subtitle: language.text(
                        "固定プロトコル、完全なsplit来歴、再実行可能な結果",
                        "Fixed protocol, complete split provenance, and rerunnable results"
                    ),
                    systemImage: "flask"
                )

                if researchMode == .paperEvidence {
                    LabNotice(
                        title: language.text("exact-paper replayは未解放", "Exact-paper replay is unavailable"),
                        message: language.text(
                            "原著のtrain/test行、前処理、学習済みforest/booster、テスト予測は公開されていません。この画面は確認済みData S1・7特徴量・seed 0・開示presetを固定し、代替splitまで記録する公開手順の再構成です。",
                            "The paper does not release its train/test rows, preprocessing, fitted forest/booster, or test predictions. This workspace fixes verified Data S1, seven predictors, seed 0, and disclosed presets and records the replacement split as a published-protocol reconstruction."
                        ),
                        kind: .limitation
                    )
                } else if experimentStore.datasetSnapshot.rowCount == 0 {
                    LabNotice(
                        title: language.text("自分の研究は確認済み事実と分離", "My Research is separate from verified facts"),
                        message: language.text(
                            "実験CSVはまだ読み込まれていません。論文Data S1へ自動的に切り替わることはありません。",
                            "No experiment CSV is loaded. The app never switches to Paper Data S1 as a fallback."
                        ),
                        kind: .information
                    )
                } else {
                    LabNotice(
                        title: language.text("未検証の自分の研究", "Unvalidated My Research"),
                        message: language.text(
                            "このモードのCSVと結果は論文の事実から分離されます。スキーマ検証は列・型・有限値を確認するだけで、測定品質、実験設計、再現性、科学的妥当性を保証しません。",
                            "This mode keeps your CSV and results separate from paper facts. Schema checks cover columns, types, and finite values only; they do not establish measurement quality, study design, reproducibility, or scientific validity."
                        ),
                        kind: .warning
                    )
                }

                if researchMode == .myExperiment,
                   experimentStore.datasetSnapshot.rowCount == 0 {
                    emptyPersonalExperimentView
                } else {
                    readinessSection
                    protocolSection

                    if let result = experimentStore.currentResult {
                        resultsSection(result)
                        splitSection(result)
                        provenanceSection(result)
                    }
                }

                historySection

                LabSection(language.text("Fick 2D有限差分ラボ", "Fick 2D finite-difference lab")) {
                    VStack(alignment: .leading, spacing: 14) {
                        Label(
                            researchMode.title(language),
                            systemImage: researchMode.symbol
                        )
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(researchMode.tint)
                        .accessibilityIdentifier("experiment.fick-2d.mode")

                        LabNotice(
                            title: language.text(
                                "85% proxy validationとは別の出力",
                                "Separate from the 85% proxy validation"
                            ),
                            message: language.text(
                                "この有限差分プレビューの「最終透過率」は搭載量のうちsinkへ到達した質量割合です。予測精度、R²、信頼区間、85%達成判定ではありません。",
                                "This finite-difference preview's final percentage is the share of loaded mass reaching the sink. It is not predictive accuracy, R², a confidence interval, or the 85% target decision."
                            ),
                            kind: .information
                        )

                        FickExperimentPanel(language: language)
                    }
                }

                LabNotice(
                    title: language.text("研究用途のみ", "Research use only"),
                    message: language.text(
                        "診断、投与量、治療効果、毒性、患者安全性の判断には使用できません。新規薬物への汎化はleave-one-drug-outで別途評価してください。",
                        "Do not use this feature for diagnosis, dosing, efficacy, toxicity, or patient-safety decisions. Evaluate generalization to a new drug separately with leave-one-drug-out validation."
                    ),
                    kind: .warning
                )
            }
            .frame(maxWidth: LabTheme.contentWidth, alignment: .leading)
            .padding(LabTheme.pagePadding)
            .frame(maxWidth: .infinity, alignment: .top)
        }
        .fileExporter(
            isPresented: $isExporting,
            document: exportDocument,
            contentType: .json,
            defaultFilename: exportFilename
        ) { result in
            if case .failure(let error) = result,
               (error as NSError).code != NSUserCancelledError {
                exportError = error.localizedDescription
            }
        }
        .alert(
            language.text("エクスポートできません", "Unable to export"),
            isPresented: Binding(
                get: { exportError != nil },
                set: { if !$0 { exportError = nil } }
            )
        ) {
            Button("OK", role: .cancel) { exportError = nil }
        } message: {
            Text(exportError ?? "")
        }
        .confirmationDialog(
            language.text("run履歴を消去しますか？", "Clear run history?"),
            isPresented: $isConfirmingHistoryClear,
            titleVisibility: .visible
        ) {
            Button(language.text("履歴を消去", "Clear history"), role: .destructive) {
                experimentStore.clearHistory()
            }
            Button(language.text("キャンセル", "Cancel"), role: .cancel) {}
        } message: {
            Text(language.text(
                "このMacに保存した最近のrunを削除します。画面上の現在の結果は残ります。",
                "This removes recent runs saved on this Mac. The result currently shown remains available."
            ))
        }
        .accessibilityIdentifier("screen.experiment")
    }

    private var emptyPersonalExperimentView: some View {
        ContentUnavailableView {
            Label(
                language.text("実験データ未読込", "No experiment dataset loaded"),
                systemImage: "flask"
            )
        } description: {
            Text(language.text(
                "11列のCSVを読み込むまでrunは作成されません。スキーマ検証後も、科学的妥当性は未検証として記録されます。",
                "No run is created until an 11-column CSV is imported. Passing schema checks is still recorded as scientifically unvalidated."
            ))
        } actions: {
            Button(action: importAction) {
                Label(
                    language.text("実験CSVを読み込む", "Import experiment CSV"),
                    systemImage: "square.and.arrow.down"
                )
            }
            .buttonStyle(.borderedProminent)
            .accessibilityIdentifier("experiment.import-experiment-data")

            Button {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(
                    TrainingDataSource.expectedHeader.joined(separator: ","),
                    forType: .string
                )
            } label: {
                Label(language.text("CSVヘッダーをコピー", "Copy CSV header"), systemImage: "doc.on.doc")
            }
            .accessibilityIdentifier("experiment.copy-csv-header")
        }
        .frame(maxWidth: .infinity, minHeight: 360)
        .accessibilityIdentifier("experiment.empty-personal")
    }

    private var readinessSection: some View {
        LabSection(language.text("1. データスナップショット", "1. Dataset snapshot")) {
            VStack(alignment: .leading, spacing: 16) {
                LabResponsiveActionHeader {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 9) {
                            Text(experimentStore.datasetSnapshot.displayName)
                                .font(.headline)
                            if experimentStore.datasetSnapshot.isBundledSource,
                               experimentStore.datasetSnapshot.isCanonicalPaperDataset,
                               experimentStore.datasetSnapshot.resolvedResearchMode == .paperEvidence {
                                Label(
                                    language.text("原著Data S1", "Canonical Data S1"),
                                    systemImage: "checkmark.seal.fill"
                                )
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.green)
                            } else if researchMode == .myExperiment,
                                      experimentStore.datasetSnapshot.rowCount > 0 {
                                Label(
                                    language.text("未検証データ", "Unvalidated data"),
                                    systemImage: "exclamationmark.triangle.fill"
                                )
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.orange)
                            }
                        }
                        Text(language.text(
                            "\(experimentStore.datasetSnapshot.rowCount)行 · \(experimentStore.datasetSnapshot.columnCount)列",
                            "\(experimentStore.datasetSnapshot.rowCount) rows · \(experimentStore.datasetSnapshot.columnCount) columns"
                        ))
                        .foregroundStyle(.secondary)
                    }
                } actions: {
                    HStack(spacing: 8) {
                        if experimentStore.datasetSnapshot.rowCount > 0 {
                            Button {
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setString(experimentStore.datasetSnapshot.sha256, forType: .string)
                            } label: {
                                Label(language.text("hashをコピー", "Copy hash"), systemImage: "number")
                            }
                            .accessibilityIdentifier("experiment.copy-hash")
                        }
                        if researchMode == .myExperiment {
                            Button {
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setString(
                                    TrainingDataSource.expectedHeader.joined(separator: ","),
                                    forType: .string
                                )
                            } label: {
                                Label(language.text("CSVヘッダーをコピー", "Copy CSV header"), systemImage: "doc.on.doc")
                            }
                            .accessibilityIdentifier("experiment.copy-csv-header")
                        }
                    }
                }

                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 210), spacing: 14)],
                    alignment: .leading,
                    spacing: 14
                ) {
                    LabMetricCard(
                        title: language.text("スキーマ", "Schema"),
                        value: experimentStore.datasetSnapshot.rowCount == 0
                            ? language.text("未読込", "Not loaded")
                            : experimentStore.datasetSnapshot.schemaIsValid
                                ? language.text("有効", "Valid")
                                : language.text("要修正", "Invalid"),
                        detail: experimentStore.datasetSnapshot.rowCount == 0
                            ? language.text("実験CSVが必要", "Experiment CSV required")
                            : language.text(
                                "監査エラー \(experimentStore.datasetSnapshot.auditErrorCount)件",
                                "\(experimentStore.datasetSnapshot.auditErrorCount) audit errors"
                            ),
                        systemImage: experimentStore.datasetSnapshot.rowCount == 0
                            ? "tray.and.arrow.down"
                            : experimentStore.datasetSnapshot.schemaIsValid
                                ? "checkmark.shield" : "xmark.shield"
                    )
                    LabMetricCard(
                        title: "SHA-256",
                        value: experimentStore.datasetSnapshot.rowCount == 0
                            ? "—"
                            : String(experimentStore.datasetSnapshot.sha256.prefix(12)) + "…",
                        detail: experimentStore.datasetSnapshot.rowCount == 0
                            ? language.text("実験CSVが必要", "Experiment CSV required")
                            : experimentStore.datasetSnapshot.sha256Basis.title(language),
                        systemImage: "number"
                    )
                    LabMetricCard(
                        title: language.text("入力", "Predictors"),
                        value: "7",
                        detail: language.text("原著の数値コードを保持", "Paper numeric coding retained"),
                        systemImage: "slider.horizontal.3"
                    )
                }

                DisclosureGroup(language.text("固定する7特徴量", "Seven fixed predictors")) {
                    LazyVGrid(
                        columns: [GridItem(.adaptive(minimum: 250), spacing: 8)],
                        alignment: .leading,
                        spacing: 7
                    ) {
                        ForEach(experimentStore.datasetSnapshot.predictorFields, id: \.self) { field in
                            Label(field, systemImage: "checkmark.circle")
                                .font(.callout)
                        }
                    }
                    .padding(.top, 8)
                }

                if researchMode == .myExperiment {
                    LabNotice(
                        title: language.text("論文エビデンスとは別管理", "Kept separate from paper evidence"),
                        message: language.text(
                            "内容がData S1と同一でも、このモードのrunはTable 4再構成へ昇格しません。モード、科学的状態、dataset hashはJSONへ保存されます。",
                            "Even if its values match Data S1, a run in this mode is never promoted to a Table 4 reconstruction. Mode, scientific status, and dataset hash are saved in JSON."
                        ),
                        kind: .warning
                    )

                    DisclosureGroup(language.text("自分の研究CSV要件", "My Research CSV requirements")) {
                        VStack(alignment: .leading, spacing: 8) {
                            ScrollView(.horizontal) {
                                Text(TrainingDataSource.expectedHeader.joined(separator: ","))
                                    .font(.caption.monospaced())
                                    .textSelection(.enabled)
                            }
                            Text(language.text(
                                "現行のLODO分類は原著6薬物名（BSA、copper ions、GHK peptide、Rhodamine B、lidocaine、caffeine）を使用します。skinとMN typeは1/2、数値は有限かつ非負、主要入力は正値が必要です。",
                                "The current LODO grouping uses the six paper drug names: BSA, copper ions, GHK peptide, Rhodamine B, lidocaine, and caffeine. Skin and MN type use codes 1/2; numbers must be finite and nonnegative, with primary inputs positive."
                            ))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                        .padding(.top, 8)
                    }
                }
            }
        }
        .accessibilityIdentifier("experiment.dataset")
    }

    private var protocolSection: some View {
        LabSection(language.text("2. プロトコルと実行", "2. Protocol and execution")) {
            VStack(alignment: .leading, spacing: 18) {
                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 270), spacing: 18)],
                    alignment: .leading,
                    spacing: 16
                ) {
                    experimentField(language.text("目的変数", "Outcome")) {
                        Picker(language.text("目的変数", "Outcome"), selection: $experimentStore.configuration.outcome) {
                            ForEach(ExperimentOutcome.allCases) { outcome in
                                Text(outcome.title(language)).tag(outcome)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.segmented)
                        .accessibilityIdentifier("experiment.outcome")
                    }

                    experimentField(language.text("検証", "Validation")) {
                        Picker(
                            language.text("検証", "Validation"),
                            selection: $experimentStore.configuration.validationStrategy
                        ) {
                            ForEach(ExperimentValidationStrategy.allCases) { strategy in
                                Text(strategy.title(language)).tag(strategy)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)
                        .disabled(researchMode == .paperEvidence)
                        .accessibilityIdentifier("experiment.validation")
                    }

                    if experimentStore.configuration.validationStrategy == .publishedStyleRowSplit {
                        experimentField(language.text("固定seed", "Fixed seed")) {
                            TextField(
                                language.text("seed", "Seed"),
                                value: $experimentStore.configuration.seed,
                                format: .number.grouping(.never)
                            )
                            .textFieldStyle(.roundedBorder)
                            .frame(maxWidth: 180)
                            .disabled(researchMode == .paperEvidence)
                            .accessibilityIdentifier("experiment.seed")
                        }
                    } else {
                        experimentField(language.text("学習から除外する薬物", "Drug held out from training")) {
                            Picker(
                                language.text("薬物", "Drug"),
                                selection: $experimentStore.configuration.heldOutDrug
                            ) {
                                ForEach(availableDrugs) { drug in
                                    Text(drug.displayName(language)).tag(Optional(drug))
                                }
                            }
                            .labelsHidden()
                            .pickerStyle(.menu)
                            .accessibilityIdentifier("experiment.held-out-drug")
                        }
                    }
                }

                presetSummary

                if experimentStore.datasetSnapshot.isCanonicalPaperDataset {
                    LabNotice(
                        title: language.text("2つの出力は独立ではありません", "The two outcomes are not independent"),
                        message: language.text(
                            "Data S1では全行が丸め誤差内で amount = loading × percentage / 100 を満たします。代替outcomeを説明変数には使いません。",
                            "Every Data S1 row satisfies amount = loading × percentage / 100 within source rounding. The alternate outcome is never used as a predictor."
                        ),
                        kind: .information
                    )
                }

                LabResponsiveActionHeader {
                    phaseSummary
                } actions: {
                    Button {
                        Task { await experimentStore.run() }
                    } label: {
                        Label(
                            researchMode == .paperEvidence
                                ? language.text("公開手順のrunを実行", "Run published protocol")
                                : language.text("自分の研究runを実行", "Run My Research"),
                            systemImage: "play.fill"
                        )
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!canRun)
                    .keyboardShortcut(.return, modifiers: [.command])
                    .accessibilityIdentifier("experiment.run")

                    if experimentStore.isRunning {
                        Button(role: .cancel) {
                            experimentStore.cancel()
                        } label: {
                            Label(language.text("中止", "Cancel"), systemImage: "stop.fill")
                        }
                        .accessibilityIdentifier("experiment.cancel")
                    }
                }

                if case .failed(let message) = experimentStore.phase {
                    LabNotice(
                        title: language.text("runに失敗しました", "Run failed"),
                        message: message.resolve(language),
                        kind: .warning
                    )
                }
            }
        }
        .accessibilityIdentifier("experiment.protocol")
    }

    private var presetSummary: some View {
        let preset = experimentStore.configuration.preset
        return VStack(alignment: .leading, spacing: 12) {
            Text(
                researchMode == .paperEvidence
                    ? language.text("原著プリセット（読取専用）", "Paper preset (read only)")
                    : language.text("原著設定を実験テンプレートとして使用", "Paper settings used as an experiment template")
            )
                .font(.headline)
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 240), spacing: 12)],
                alignment: .leading,
                spacing: 12
            ) {
                presetCard(
                    "MLR",
                    language.text(
                        "7特徴量 · 切片なし",
                        "7 predictors · no intercept"
                    )
                )
                presetCard(
                    "Random Forest",
                    "\(preset.randomForestTrees) trees · mtry \(preset.randomForestMtry) · native depth \(preset.randomForestMaximumDepth) · node size \(preset.randomForestMinimumNodeSize)"
                )
                presetCard(
                    language.text("Native Boosting", "Native boosting"),
                    "depth \(preset.boostingMaxDepth) · eta \(preset.boostingLearningRate.formatted()) · \(preset.boostingRounds) rounds"
                )
            }
            Text(language.text(
                "Native Random ForestとBoostingはSwift再構成です。R randomForest 4.7-1またはxgboost 1.5.0.2と数値同一ではありません。",
                "Native Random Forest and boosting are Swift reconstructions, not numerical equivalents of R randomForest 4.7-1 or xgboost 1.5.0.2."
            ))
            .font(.caption)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .labCard(radius: 12)
    }

    @ViewBuilder
    private func resultsSection(_ result: ExperimentRunResult) -> some View {
        let canCompareWithTable4 = result.canDisplayTable4Reference(in: researchMode)
        LabSection(language.text("3. 再構成結果", "3. Reconstructed result")) {
            VStack(alignment: .leading, spacing: 18) {
                if result.dataset.resolvedResearchMode != researchMode {
                    LabNotice(
                        title: language.text("別モードで保存されたrun", "Run saved in another mode"),
                        message: language.text(
                            "この履歴runのモードは\(result.dataset.resolvedResearchMode.title(language))です。現在の\(researchMode.title(language))へ結果を昇格・再分類しません。",
                            "This historical run belongs to \(result.dataset.resolvedResearchMode.title(language)). It is not promoted or reclassified into the current \(researchMode.title(language)) mode."
                        ),
                        kind: .warning
                    )
                }
                if result.dataset.sha256 != experimentStore.datasetSnapshot.sha256 {
                    LabNotice(
                        title: language.text("保存runは別データで実行", "Saved run uses a different dataset"),
                        message: language.text(
                            "表示中のrun hashと現在のデータhashが異なります。結果は保存時のデータに対するものです。",
                            "The displayed run hash differs from the active dataset hash. These results belong to the dataset captured in that run."
                        ),
                        kind: .warning
                    )
                }

                if result.configuration != experimentStore.configuration {
                    LabNotice(
                        title: language.text("設定変更後・未実行", "Configuration changed · not rerun"),
                        message: language.text(
                            "表示中の結果は変更前の設定です。現在の設定を評価するには新しいrunを実行してください。",
                            "The displayed result uses the previous configuration. Run again to evaluate the current setup."
                        ),
                        kind: .information
                    )
                }

                LabResponsiveActionHeader {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(result.configuration.outcome.title(language))
                            .font(.title2.bold())
                        Text(language.text(
                            "標準定義 · test n=\(result.split.testCount) · \(result.elapsedSeconds.formatted(.number.precision(.fractionLength(2))))秒",
                            "Standard definitions · test n=\(result.split.testCount) · \(result.elapsedSeconds.formatted(.number.precision(.fractionLength(2)))) s"
                        ))
                        .foregroundStyle(.secondary)
                    }
                } actions: {
                    Button {
                        export(result)
                    } label: {
                        Label(language.text("run JSONを書き出す", "Export run JSON"), systemImage: "square.and.arrow.up")
                    }
                    .accessibilityIdentifier("experiment.export")
                }

                ScrollView(.horizontal) {
                    Grid(alignment: .leading, horizontalSpacing: 22, verticalSpacing: 12) {
                        GridRow {
                            Text(language.text("モデル", "Model")).bold()
                            Text(language.text("再構成RMSE", "Reconstructed RMSE")).bold()
                            Text("MAE").bold()
                            Text("R²").bold()
                            Text(language.text("legacy √SSE", "Legacy √SSE")).bold()
                            if canCompareWithTable4 {
                                Text(language.text("原著RMSE表記", "Paper-labelled RMSE")).bold()
                                Text(language.text("原著R²", "Paper R²")).bold()
                            }
                        }
                        Divider().gridCellColumns(canCompareWithTable4 ? 7 : 5)
                        ForEach(result.metrics) { metric in
                            let reported = reportedMetric(for: metric.model, outcome: result.configuration.outcome)
                            GridRow {
                                Text(metric.model.title(language))
                                Text(format(metric.rmse))
                                Text(format(metric.mae))
                                Text(metric.rSquared.map(format) ?? language.text("未定義", "Undefined"))
                                Text(format(metric.rootSumSquaredError))
                                if canCompareWithTable4 {
                                    Text(reported.map { format($0.rmse) } ?? "—")
                                    Text(reported.map { format($0.rSquared) } ?? "—")
                                }
                            }
                        }
                    }
                    .monospacedDigit()
                    .padding(.bottom, 4)
                }

                LabNotice(
                    title: language.text("legacy √SSEは診断値", "Legacy √SSE is diagnostic"),
                    message: language.text(
                        "原著Table 4の「RMSE」は標準RMSEとR²に数学的整合性がなく、√SSEだった可能性があります。原著の計算コードが未公開なため推定であり、再構成RMSEを主指標とします。",
                        "The paper's Table 4 'RMSE' is mathematically inconsistent with its R² under the standard definition and may be √SSE. Because the calculation code is unavailable, this is an inference; reconstructed RMSE remains the primary metric."
                    ),
                    kind: .limitation
                )

                if result.configuration.outcome == .amount, canCompareWithTable4 {
                    LabNotice(
                        title: language.text("透過量の単位表記が不一致", "Amount-unit labels differ"),
                        message: language.text(
                            "Data S1はµg/cm²、Table 4はµgと表記します。この再構成はData S1のµg/cm²を保持し、暗黙に換算しません。",
                            "Data S1 labels amount as µg/cm², while Table 4 uses µg. This reconstruction retains µg/cm² and does not apply an implicit conversion."
                        ),
                        kind: .limitation
                    )
                }

                if !canCompareWithTable4 {
                    LabNotice(
                        title: language.text("Table 4とは比較不可", "Not comparable with Table 4"),
                        message: language.text(
                            "Table 4の報告値は同梱Data S1の70:30行split用です。現在のデータまたは検証法とは評価対象が異なるため、原著値を併記しません。",
                            "Table 4 reports a 70:30 row split on Data S1. The active dataset or validation scope differs, so paper values are intentionally hidden."
                        ),
                        kind: .information
                    )
                }

                Picker(language.text("予測モデル", "Prediction model"), selection: $selectedModel) {
                    ForEach(ExperimentModelKind.allCases) { model in
                        Text(model.title(language)).tag(model)
                    }
                }
                .pickerStyle(.segmented)
                .accessibilityIdentifier("experiment.chart-model")

                predictionChart(result)

                ForEach(result.warnings, id: \.code) { warning in
                    LabNotice(
                        title: language.text("監査警告", "Audit warning"),
                        message: warning.resolve(language),
                        kind: .warning
                    )
                }
            }
        }
        .accessibilityIdentifier("experiment.results")
    }

    private func splitSection(_ result: ExperimentRunResult) -> some View {
        LabSection(language.text("4. splitとリーク監査", "4. Split and leakage audit")) {
            VStack(alignment: .leading, spacing: 16) {
                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 205), spacing: 14)],
                    alignment: .leading,
                    spacing: 14
                ) {
                    LabMetricCard(
                        title: language.text("学習", "Training"),
                        value: result.split.trainingCount.formatted(),
                        detail: language.text("row IDをJSONへ保存", "Row IDs saved in JSON"),
                        systemImage: "brain"
                    )
                    LabMetricCard(
                        title: language.text("テスト", "Test"),
                        value: result.split.testCount.formatted(),
                        detail: result.configuration.validationStrategy.title(language),
                        systemImage: "checkmark.circle"
                    )
                    LabMetricCard(
                        title: language.text("共有条件", "Shared conditions"),
                        value: result.leakageAudit.sharedPredictorCombinationCount.formatted(),
                        detail: language.text(
                            "train/test双方にある7特徴量組合せ",
                            "Seven-predictor combinations in both partitions"
                        ),
                        systemImage: "arrow.left.arrow.right"
                    )
                }

                if result.leakageAudit.hasCrossPartitionConditionOverlap {
                    LabNotice(
                        title: language.text("同一条件がsplitをまたいでいます", "Matching conditions cross the split"),
                        message: language.text(
                            "学習側\(result.leakageAudit.trainingRowsInSharedConditions)行、テスト側\(result.leakageAudit.testRowsInSharedConditions)行が共有条件に属します。未知薬物性能にはleave-one-drug-outを使ってください。",
                            "\(result.leakageAudit.trainingRowsInSharedConditions) training rows and \(result.leakageAudit.testRowsInSharedConditions) test rows belong to shared conditions. Use leave-one-drug-out for unseen-drug performance."
                        ),
                        kind: .warning
                    )
                }

                if let isolated = result.leakageAudit.heldOutDrugIsIsolated {
                    LabNotice(
                        title: isolated
                            ? language.text("holdout薬物を完全分離", "Held-out drug fully isolated")
                            : language.text("holdout分離エラー", "Holdout isolation error"),
                        message: language.text(
                            "学習\(result.leakageAudit.heldOutDrugTrainingCount ?? 0)行 · テスト\(result.leakageAudit.heldOutDrugTestCount ?? 0)行",
                            "\(result.leakageAudit.heldOutDrugTrainingCount ?? 0) training rows · \(result.leakageAudit.heldOutDrugTestCount ?? 0) test rows"
                        ),
                        kind: isolated ? .information : .warning
                    )
                }

                DisclosureGroup(language.text("薬物別の割当", "Assignments by drug")) {
                    Grid(alignment: .leading, horizontalSpacing: 24, verticalSpacing: 9) {
                        GridRow {
                            Text(language.text("薬物", "Drug")).bold()
                            Text(language.text("学習", "Train")).bold()
                            Text(language.text("テスト", "Test")).bold()
                        }
                        ForEach(splitDrugNames(result), id: \.self) { drug in
                            GridRow {
                                Text(drug)
                                Text((result.split.trainDrugCounts[drug] ?? 0).formatted())
                                Text((result.split.testDrugCounts[drug] ?? 0).formatted())
                            }
                        }
                    }
                    .monospacedDigit()
                    .padding(.top, 8)
                }
            }
        }
        .accessibilityIdentifier("experiment.split-audit")
    }

    private func provenanceSection(_ result: ExperimentRunResult) -> some View {
        LabSection(language.text("5. 来歴と再現性境界", "5. Provenance and reproducibility boundary")) {
            VStack(alignment: .leading, spacing: 12) {
                keyValue(language.text("Evidence", "Evidence"), result.policyEvidenceLevel.title(language))
                keyValue(language.text("データモード", "Data mode"), result.dataset.resolvedResearchMode.title(language))
                keyValue(
                    language.text("科学的状態", "Scientific status"),
                    result.dataset.resolvedScientificStatus.title(language)
                )
                keyValue(
                    language.text("Table 4参照", "Table 4 reference"),
                    result.table4ReferenceStatus.title(language)
                )
                keyValue(language.text("Engine", "Engine"), result.engineVersion)
                keyValue(language.text("Run ID", "Run ID"), result.id.uuidString)
                keyValue(language.text("Dataset", "Dataset"), result.dataset.sha256)
                if result.dataset.normalizedSHA256 != result.dataset.sha256 {
                    keyValue(
                        language.text("正規化値SHA-256", "Normalized-value SHA-256"),
                        result.dataset.normalizedSHA256
                    )
                }
                keyValue(language.text("開始", "Started"), result.startedAt.formatted(date: .abbreviated, time: .standard))
                ForEach(result.limitations, id: \.code) { limitation in
                    Label(limitation.resolve(language), systemImage: "lock.trianglebadge.exclamationmark")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private var historySection: some View {
        LabSection(language.text("最近のrun", "Recent runs")) {
            VStack(alignment: .leading, spacing: 12) {
                if experimentStore.recentRuns.isEmpty {
                    Text(language.text(
                        "完了したrunはこのMacへ最大10件保存されます。",
                        "Up to ten completed runs are kept on this Mac."
                    ))
                    .foregroundStyle(.secondary)
                } else {
                    ForEach(experimentStore.recentRuns) { run in
                        Button {
                            experimentStore.restore(run)
                            selectedModel = .nativeGradientTreeBoosting
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "clock.arrow.circlepath")
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(run.configuration.outcome.title(language))
                                        .font(.headline)
                                    Text(run.completedAt.formatted(date: .abbreviated, time: .shortened))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Label(
                                    run.dataset.resolvedResearchMode.shortTitle(language),
                                    systemImage: run.dataset.resolvedResearchMode.symbol
                                )
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(run.dataset.resolvedResearchMode.tint)
                                Text(run.configuration.validationStrategy.shortTitle(language))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(.tertiary)
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .padding(10)
                        .labCard(radius: 10)
                        .accessibilityIdentifier("experiment.history.\(run.id.uuidString)")
                    }

                    Button(role: .destructive) {
                        isConfirmingHistoryClear = true
                    } label: {
                        Label(language.text("履歴を消去", "Clear history"), systemImage: "trash")
                    }
                    .accessibilityIdentifier("experiment.clear-history")
                }
            }
        }
        .accessibilityIdentifier("experiment.history")
    }

    private var phaseSummary: some View {
        HStack(spacing: 10) {
            switch experimentStore.phase {
            case .idle:
                Image(systemName: "circle")
                Text(language.text("設定を確認して実行", "Review the setup, then run"))
            case .running:
                ProgressView()
                    .controlSize(.small)
                Text(language.text("split → 学習 → 評価 → 保存", "Split → train → evaluate → save"))
            case .succeeded:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                if currentResultIsInHistory {
                    Text(language.text("run完了・ローカル保存済み", "Run complete and saved locally"))
                } else {
                    Text(language.text("run完了・履歴からは消去済み", "Run complete · removed from history"))
                }
            case .failed:
                Image(systemName: "xmark.octagon.fill")
                    .foregroundStyle(.red)
                Text(language.text("設定またはデータを確認", "Check the configuration or data"))
            }
        }
        .font(.callout.weight(.semibold))
        .accessibilityIdentifier("experiment.phase")
    }

    private var canRun: Bool {
        experimentStore.canRun
    }

    private var currentResultIsInHistory: Bool {
        guard let id = experimentStore.currentResult?.id else { return false }
        return experimentStore.recentRuns.contains { $0.id == id }
    }

    private var availableDrugs: [Drug] {
        Drug.allCases.filter { candidate in
            dataStore.dataset.rows.contains(where: { $0.drug == candidate })
        }
    }

    private var exportFilename: String {
        guard let run = experimentStore.currentResult else { return "permeation-experiment" }
        return "permeation-experiment-\(run.configuration.outcome.rawValue)-\(run.id.uuidString.prefix(8))"
    }

    private func predictionChart(_ result: ExperimentRunResult) -> some View {
        let points = result.predictions(for: selectedModel)
        let bounds = predictionBounds(points)
        return Chart {
            ForEach(points) { prediction in
                PointMark(
                    x: .value(language.text("実測", "Observed"), prediction.observed),
                    y: .value(language.text("予測", "Predicted"), prediction.predicted)
                )
                .foregroundStyle(by: .value(language.text("薬物", "Drug"), prediction.drugName))
                .symbol(by: .value(language.text("薬物", "Drug"), prediction.drugName))
            }
            if let bounds {
                LineMark(
                    x: .value("Observed", bounds.lowerBound),
                    y: .value("Predicted", bounds.lowerBound),
                    series: .value("Reference", "identity")
                )
                .foregroundStyle(.secondary)
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 4]))
                LineMark(
                    x: .value("Observed", bounds.upperBound),
                    y: .value("Predicted", bounds.upperBound),
                    series: .value("Reference", "identity")
                )
                .foregroundStyle(.secondary)
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 4]))
            }
        }
        .chartXAxisLabel(language.text("実測", "Observed") + " (\(result.configuration.outcome.unit))")
        .chartYAxisLabel(language.text("予測", "Predicted") + " (\(result.configuration.outcome.unit))")
        .frame(height: 350)
        .accessibilityLabel(language.text(
            "\(selectedModel.title(language))の実測対予測散布図",
            "Observed versus predicted scatter plot for \(selectedModel.title(language))"
        ))
        .accessibilityValue(language.text(
            "テスト\(points.count)点。点線は予測と実測が等しい位置。",
            "\(points.count) test points. The dashed line marks equal predicted and observed values."
        ))
        .accessibilityIdentifier("experiment.prediction-chart")
    }

    private func presetCard(_ title: String, _ detail: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.headline)
            Text(detail)
                .font(.callout.monospacedDigit())
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.quaternary.opacity(0.45), in: RoundedRectangle(cornerRadius: 9))
    }

    private func experimentField<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            content()
        }
    }

    private func keyValue(_ key: String, _ value: String) -> some View {
        LabeledContent(key) {
            Text(value)
                .font(.callout.monospaced())
                .textSelection(.enabled)
                .multilineTextAlignment(.trailing)
        }
    }

    private func export(_ result: ExperimentRunResult) {
        do {
            exportDocument = ExperimentJSONDocument(data: try experimentStore.exportData(for: result))
            isExporting = true
        } catch {
            exportError = error.localizedDescription
        }
    }

    private func reportedMetric(
        for model: ExperimentModelKind,
        outcome: ExperimentOutcome
    ) -> (rmse: Double, rSquared: Double)? {
        let paperKind: ModelKind
        switch model {
        case .multipleLinearRegression: paperKind = .mlr
        case .randomForest: paperKind = .rf
        case .nativeGradientTreeBoosting: paperKind = .xgboost
        }
        guard let metric = PaperMetric.reported.first(where: { $0.model == paperKind }) else { return nil }
        switch outcome {
        case .amount: return (metric.amountRMSE, metric.amountR2)
        case .percentage: return (metric.percentageRMSE, metric.percentageR2)
        }
    }

    private func predictionBounds(_ predictions: [ExperimentPrediction]) -> ClosedRange<Double>? {
        let values = predictions.flatMap { [$0.observed, $0.predicted] }.filter(\.isFinite)
        guard let minimum = values.min(), let maximum = values.max() else { return nil }
        if minimum == maximum { return (minimum - 1)...(maximum + 1) }
        return minimum...maximum
    }

    private func splitDrugNames(_ result: ExperimentRunResult) -> [String] {
        Set(result.split.trainDrugCounts.keys)
            .union(result.split.testDrugCounts.keys)
            .sorted()
    }

    private func format(_ value: Double) -> String {
        value.formatted(.number.precision(.significantDigits(5)))
    }
}

struct ExperimentJSONDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
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

private extension ExperimentOutcome {
    func title(_ language: AppLanguage) -> String {
        switch self {
        case .amount: language.text("透過量", "Permeation amount")
        case .percentage: language.text("透過率", "Permeation percentage")
        }
    }
}

private extension ExperimentValidationStrategy {
    func title(_ language: AppLanguage) -> String {
        switch self {
        case .publishedStyleRowSplit:
            language.text("原著型 70:30 行split", "Published-style 70:30 row split")
        case .leaveOneDrugOut:
            language.text("leave-one-drug-out", "Leave one drug out")
        }
    }

    func shortTitle(_ language: AppLanguage) -> String {
        switch self {
        case .publishedStyleRowSplit: language.text("70:30", "70:30")
        case .leaveOneDrugOut: language.text("薬物holdout", "Drug holdout")
        }
    }
}

private extension ExperimentModelKind {
    func title(_ language: AppLanguage) -> String {
        switch self {
        case .multipleLinearRegression: "MLR"
        case .randomForest: "Random Forest"
        case .nativeGradientTreeBoosting:
            language.text("Native Boosting（XGBoost再構成）", "Native boosting (XGBoost reconstruction)")
        }
    }
}

private extension ExperimentEvidenceLevel {
    func title(_ language: AppLanguage) -> String {
        switch self {
        case .publishedProtocolReconstruction:
            language.text("公開手順の決定論的再構成", "Deterministic published-protocol reconstruction")
        case .generalizationValidation:
            language.text("未知薬物への汎化検証", "Leave-one-drug-out generalization validation")
        case .compatibleDatasetExperiment:
            language.text("互換データによる新規実験", "Compatible-dataset experiment")
        case .paperDataProtocolVariation:
            language.text("論文データ上の手順変更", "Paper-data protocol variation")
        case .exactPaperReplayUnavailable:
            language.text("exact-paper replay未解放", "Exact-paper replay unavailable")
        }
    }
}

private extension ExperimentTable4ReferenceStatus {
    func title(_ language: AppLanguage) -> String {
        switch self {
        case .eligibleReportedReference:
            language.text("原著報告値を参考併記可能", "Reported paper values may be shown as reference")
        case .unavailableOutsidePaperEvidence:
            language.text("確認済み事実以外では非表示", "Hidden outside Verified Facts")
        case .unavailableNoncanonicalSource:
            language.text("正本Data S1ではないため非表示", "Hidden because the source is not canonical Data S1")
        case .unavailableProtocolVariation:
            language.text("固定手順と異なるため非表示", "Hidden because the fixed protocol differs")
        }
    }
}

private extension ExperimentDatasetHashBasis {
    func title(_ language: AppLanguage) -> String {
        switch self {
        case .bundledRawCSVBytes:
            language.text("同梱raw CSVのバイトhash・64文字をexport", "Bundled raw CSV bytes · full hash exported")
        case .normalizedParsedValues:
            language.text("正規化したパース値のhash・64文字をexport", "Normalized parsed values · full hash exported")
        }
    }
}
