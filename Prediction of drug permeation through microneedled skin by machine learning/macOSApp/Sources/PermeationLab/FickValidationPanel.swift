import AppKit
import SwiftUI

private enum FickAutomaticExportError: LocalizedError {
    case missingPath
    case pathMustBeAbsolute
    case outputAlreadyExists(String)

    var errorDescription: String? {
        switch self {
        case .missingPath:
            "-fick-85-export-path requires a following JSON file path."
        case .pathMustBeAbsolute:
            "The automatic Fick export path must be absolute."
        case .outputAlreadyExists(let path):
            "The automatic Fick export will not overwrite an existing file: \(path)"
        }
    }
}

struct FickValidationPanel: View {
    let language: AppLanguage
    let dataset: TrainingDataset
    let datasetSnapshot: ExperimentDatasetSnapshot

    @State private var configuration = FickValidationConfiguration.default
    @State private var result: FickValidationRunResult?
    @State private var recentRuns: [FickValidationRunResult]
    @State private var runTask: Task<Void, Never>?
    @State private var activeRunID: UUID?
    @State private var auditTask: Task<Void, Never>?
    @State private var activeAuditToken: UUID?
    @State private var auditedResultID: UUID?
    @State private var auditedDiagnostics: FickValidationDiagnostics?
    @State private var auditedSidecarData: Data?
    @State private var failedAuditResultID: UUID?
    @State private var auditFailureMessage: String?
    @State private var isRunning = false
    @State private var errorMessage: String?
    @State private var isExporting = false
    @State private var exportDocument = ExperimentJSONDocument(data: Data("{}".utf8))
    @State private var exportSuggestedFilename = "fick-85-proxy-validation"
    @State private var isConfirmingHistoryClear = false
    @State private var didAttemptAutomaticRun = false

    private let persistence: FickValidationHistoryPersistence

    init(
        language: AppLanguage,
        dataset: TrainingDataset,
        datasetSnapshot: ExperimentDatasetSnapshot
    ) {
        self.language = language
        self.dataset = dataset
        self.datasetSnapshot = datasetSnapshot
        let persistence = FickValidationHistoryPersistence()
        self.persistence = persistence
        _recentRuns = State(initialValue: persistence.load().filter {
            $0.dataset.resolvedResearchMode == .myExperiment
                && $0.dataset.resolvedScientificStatus == .userProvidedUnvalidated
        })
    }

    var body: some View {
        LabSection(language.text(
            "Fick 85% エビデンス監査",
            "Fick 85% evidence audit"
        )) {
            VStack(alignment: .leading, spacing: 18) {
                targetHeader

                LabResponsiveActionHeader {
                    phaseSummary
                } actions: {
                    HStack(spacing: 10) {
                        Button {
                            startRun()
                        } label: {
                            Label(
                                language.text("現在の証拠を監査", "Audit current evidence"),
                                systemImage: "checkmark.shield"
                            )
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(!canRun)
                        .accessibilityIdentifier("experiment.fick-validation.run")

                        if isRunning {
                            Button(role: .cancel) {
                                cancelRun()
                            } label: {
                                Label(language.text("中止", "Cancel"), systemImage: "stop.fill")
                            }
                            .accessibilityIdentifier("experiment.fick-validation.cancel")
                        }
                    }
                }

                if result == nil {
                    interpretationNotices
                }

                if let result {
                    resultView(result)
                }

                historyView
            }
        }
        .accessibilityIdentifier("experiment.fick-validation")
        .fileExporter(
            isPresented: $isExporting,
            document: exportDocument,
            contentType: .json,
            defaultFilename: exportSuggestedFilename
        ) { exportResult in
            if case .failure(let error) = exportResult,
               (error as NSError).code != NSUserCancelledError {
                errorMessage = error.localizedDescription
            }
        }
        .alert(
            language.text("Fick proxy validationを完了できません", "Unable to complete Fick proxy validation"),
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
            language.text("Fick proxy履歴を消去しますか？", "Clear Fick proxy history?"),
            isPresented: $isConfirmingHistoryClear,
            titleVisibility: .visible
        ) {
            Button(language.text("履歴を消去", "Clear history"), role: .destructive) {
                persistence.clear()
                recentRuns = []
            }
            Button(language.text("キャンセル", "Cancel"), role: .cancel) {}
        } message: {
            Text(language.text(
                "このMacに保存されたproxy validation履歴だけを削除します。表示中の結果と通常のExperiment run履歴は残ります。",
                "Only locally saved proxy-validation history is removed. The visible result and regular Experiment run history remain."
            ))
        }
        .onAppear {
            resumeAuditIfNeeded()
            startAutomaticRunIfNeeded()
        }
        .onChange(of: datasetSnapshot.sha256) { _, _ in
            cancelRun()
            cancelAudit()
            clearAuditPresentation()
            if result?.dataset.sha256 != datasetSnapshot.sha256 {
                result = nil
            } else if let result {
                startAudit(result)
            }
            didAttemptAutomaticRun = false
            startAutomaticRunIfNeeded()
        }
        .onDisappear {
            cancelRun()
            cancelAudit()
            didAttemptAutomaticRun = false
        }
    }

    private var targetHeader: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(alignment: .leading, spacing: 5) {
                Text(language.text(
                    "まだモデルに見せていない条件を予測できるか監査",
                    "Audit prediction on conditions hidden from the model"
                ))
                .font(.headline)
                Text(language.text(
                    "似た測定行を一つの条件グループ（proxy condition）にまとめ、グループごと隠して透過率を予測します。",
                    "Similar rows are grouped into proxy conditions; each group is hidden in turn before predicting permeation percentage."
                ))
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 12)

            VStack(alignment: .trailing, spacing: 3) {
                Label(
                    language.text(
                        "将来の外部確認条件：pointと片側95%下限が共に R² ≥ \(format(configuration.targetRSquared))",
                        "Future external criterion: point and one-sided 95% lower bound both R² ≥ \(format(configuration.targetRSquared))"
                    ),
                    systemImage: "target"
                )
                .font(.headline.monospacedDigit())
                Text(language.text("現在: 未確認", "Current: not confirmed"))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.orange)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Color.orange.opacity(0.10),
                in: RoundedRectangle(cornerRadius: 11, style: .continuous)
            )
            .accessibilityLabel(language.text(
                "将来の外部確認条件",
                "Future external confirmation criterion"
            ))
            .accessibilityValue(language.text(
                "curveとrunを等重みにしたpoint R二乗と、事前規定した片側95%下限の両方が\(format(configuration.targetRSquared))以上。現在は未確認です。",
                "Both curve- and run-balanced point R squared and the prespecified one-sided 95% lower bound must be at least \(format(configuration.targetRSquared)). This is currently not confirmed."
            ))
            .accessibilityIdentifier("experiment.fick-validation.target")
        }
    }

    private var interpretationNotices: some View {
        VStack(alignment: .leading, spacing: 10) {
            LabNotice(
                title: language.text("85%は透過した質量割合ではありません", "85% is not a permeated-mass fraction"),
                message: language.text(
                    "ここでの0.85は、隠しておいた条件をどれだけ説明できたかを示すR²の目標です。85%の薬物が透過した、85%正解した、成功確率85%という意味ではありません。",
                    "Here, 0.85 is an R² target describing variation explained for hidden conditions. It does not mean that 85% of the drug permeated, that predictions were 85% correct, or that success probability is 85%."
                ),
                kind: .information
            )

            DisclosureGroup(language.text("評価境界を読む", "Read the evaluation boundaries")) {
                VStack(alignment: .leading, spacing: 10) {
                    LabNotice(
                        title: language.text("自分の研究・科学的妥当性未検証", "My Research · scientific validity unverified"),
                        message: language.text(
                            "全入力と結果はユーザー提供の未検証データとして扱います。proxy conditionはrun IDや個々のCSV行ではなく、反復観測をまとめる評価単位です。スキーマ合格は測定品質や外的妥当性を保証しません。",
                            "All inputs and results remain user-provided and scientifically unvalidated. A proxy condition is an evaluation unit grouping repeated observations, not a run ID or an individual CSV row. Passing schema checks does not establish measurement quality or external validity."
                        ),
                        kind: .limitation
                    )

                    LabNotice(
                        title: language.text("探索的・Paper/Table 4とは非比較", "Exploratory and not comparable with Paper/Table 4"),
                        message: language.text(
                            "同じデータを見た後の85%目標設定とfamily/condition探索はpost-hocです。新しい事前登録データで確認するまでconfirmatory claimに使えません。原著Fick、Table 4、Fick 2D有限差分プレビューとも直接比較しません。",
                            "Choosing the 85% target and exploring families or conditions after seeing these data is post hoc. It cannot support a confirmatory claim until tested on new preregistered data. It is not directly comparable with the paper's Fick result, Table 4, or the Fick 2D finite-difference preview."
                        ),
                        kind: .warning
                    )
                }
                .padding(.top, 8)
            }
        }
        .accessibilityIdentifier("experiment.fick-validation.boundaries")
    }

    private var phaseSummary: some View {
        HStack(spacing: 10) {
            if isRunning {
                ProgressView()
                    .controlSize(.small)
                Text(language.text(
                    "condition分割 → fit → 固定OOF再標本化 → stress test",
                    "Condition splits → fit → fixed-OOF resampling → stress test"
                ))
            } else if let result, auditedResultID == result.id {
                Image(systemName: "checkmark.shield.fill")
                    .foregroundStyle(.green)
                Text(language.text(
                    "アプリ内replay一致（計算整合性のみ）・履歴保存済み",
                    "In-app replay match (computational integrity only) · saved"
                ))
            } else if let result, failedAuditResultID == result.id {
                Image(systemName: "xmark.shield.fill")
                    .foregroundStyle(.red)
                Text(language.text("監査不合格・指標を非表示", "Audit failed · metrics hidden"))
            } else if result != nil {
                ProgressView()
                    .controlSize(.small)
                Text(language.text(
                    "主要・stress全foldの再fit、全予測、percentileを独立再計算中",
                    "Independently replaying all primary/stress folds, predictions, and percentiles"
                ))
            } else {
                Image(systemName: "circle")
                Text(language.text(
                    "探索的結果がどこまで通用するかを監査",
                    "Audit how far the exploratory result can support a claim"
                ))
            }
        }
        .font(.callout.weight(.semibold))
        .accessibilityIdentifier("experiment.fick-validation.phase")
    }

    private func resultView(_ result: FickValidationRunResult) -> some View {
        let diagnostics = auditedResultID == result.id ? auditedDiagnostics : nil
        let auditFailed = failedAuditResultID == result.id
        return VStack(alignment: .leading, spacing: 18) {
            if result.dataset.sha256 != datasetSnapshot.sha256 {
                LabNotice(
                    title: language.text("保存結果は別データで実行", "Saved result uses a different dataset"),
                    message: language.text(
                        "表示中の結果hashと現在の研究データhashが異なります。判定は保存時データだけに適用されます。",
                        "The displayed result hash differs from the active My Research hash. Its decision applies only to the saved dataset."
                    ),
                    kind: .warning
                )
            }

            Text(language.text("エビデンス監査結果", "Evidence audit result"))
                .font(.title2.bold())
                .accessibilityIdentifier(
                    diagnostics != nil
                        ? "experiment.fick-validation.result"
                        : auditFailed
                            ? "experiment.fick-validation.audit-failed"
                            : "experiment.fick-validation.raw-result"
                )

            if let diagnostics {
                FickValidationEvidenceDashboard(
                    language: language,
                    result: result,
                    diagnostics: diagnostics
                )
            } else if auditFailed {
                LabNotice(
                    title: language.text("監査を再計算できません", "Unable to recompute the audit"),
                    message: language.text(
                        "表示runは固定protocolで再現できません。保存値を信頼せず指標を隠しました。新しくrunを実行してください。" + (auditFailureMessage.map { "\n\n" + $0 } ?? ""),
                        "The displayed run cannot be reproduced under the locked protocol. Saved values are not trusted, so metrics are hidden. Start a new run." + (auditFailureMessage.map { "\n\n" + $0 } ?? "")
                    ),
                    kind: .warning
                )
            } else {
                HStack(spacing: 10) {
                    ProgressView()
                    Text(language.text(
                        "元データから全foldを再fitし、予測とpercentileを照合中です。",
                        "Refitting every fold from source rows and checking predictions and percentiles."
                    ))
                }
                .accessibilityIdentifier("experiment.fick-validation.audit-progress")
            }

            if diagnostics != nil {
                DisclosureGroup(language.text(
                    "再標本化・fold・従来指標の詳細",
                    "Resampling, folds, and legacy metric details"
                )) {
                    VStack(alignment: .leading, spacing: 16) {
                        legacyMetrics(result)
                        eligibleScope(result)
                        stressView(result)
                        familyMetricsView(result)
                        runMessages(result)
                    }
                    .padding(.top, 10)
                }
                .accessibilityIdentifier("experiment.fick-validation.run-details")

                LabResponsiveActionHeader {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(language.text("完全なproxy run記録", "Complete proxy run record"))
                            .font(.headline)
                        Text(language.text(
                            "設定、hash、fold、予測、percentile、stress結果、警告をJSONへ保存",
                            "Save configuration, hash, folds, predictions, percentiles, stress results, and warnings as JSON"
                        ))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                } actions: {
                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: 10) {
                            runExportButton(result)
                            auditExportButton(result)
                        }
                        VStack(alignment: .leading, spacing: 8) {
                            runExportButton(result)
                            auditExportButton(result)
                        }
                    }
                }
            } else if auditFailed {
                LabResponsiveActionHeader {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(language.text("監査不合格のraw run", "Raw run that failed audit"))
                            .font(.headline)
                        Text(language.text(
                            "指標は非表示です。原因調査用JSONとしてのみ保存でき、論文の証拠には使用できません。",
                            "Metrics are hidden. The JSON can be saved only for diagnosis and must not be used as manuscript evidence."
                        ))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                } actions: {
                    runExportButton(result)
                }
                .accessibilityIdentifier("experiment.fick-validation.failed-audit-record")
            }
        }
    }

    private func legacyMetrics(_ result: FickValidationRunResult) -> some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 205), spacing: 14)],
            alignment: .leading,
            spacing: 14
        ) {
            metricCard(
                identifier: "experiment.fick-validation.point-r2",
                title: language.text("点推定 R²", "Point R²"),
                value: formatOptional(result.pooledMetric.rSquared),
                detail: language.text("held-out condition予測", "Held-out-condition predictions"),
                symbol: "scope"
            )
            metricCard(
                identifier: "experiment.fick-validation.ci-two-sided",
                title: language.text("固定OOF 2.5–97.5 percentile", "Fixed-OOF 2.5–97.5 percentiles"),
                value: interval(
                    lower: result.confidenceInterval.twoSidedLower,
                    upper: result.confidenceInterval.twoSidedUpper
                ),
                detail: language.text(
                    "モデル再fitなし・\(result.confidenceInterval.validReplicateCount)回",
                    "No model refit · \(result.confidenceInterval.validReplicateCount) resamples"
                ),
                symbol: "arrow.left.and.right"
            )
            metricCard(
                identifier: "experiment.fick-validation.ci-one-sided-lower",
                title: language.text("固定OOF 5 percentile", "Fixed-OOF fifth percentile"),
                value: formatOptional(result.confidenceInterval.oneSidedLower),
                detail: language.text("内部構成感度に使用", "Used for internal composition sensitivity"),
                symbol: "arrow.up.to.line"
            )
            metricCard(
                identifier: "experiment.fick-validation.rmse",
                title: "RMSE",
                value: format(result.pooledMetric.rmse) + " pp",
                detail: language.text("透過率パーセントポイント", "Permeation-percentage points"),
                symbol: "waveform.path"
            )
            metricCard(
                identifier: "experiment.fick-validation.mae",
                title: "MAE",
                value: format(result.pooledMetric.mae) + " pp",
                detail: language.text("透過率パーセントポイント", "Permeation-percentage points"),
                symbol: "equal.square"
            )
            metricCard(
                identifier: "experiment.fick-validation.probability",
                title: language.text("再標本化share R² ≥ 0.85", "Resample share R² ≥ 0.85"),
                value: percent(result.confidenceInterval.probabilityAtOrAboveTarget),
                detail: language.text("p値・将来成功確率ではありません", "Not a p-value or future-success probability"),
                symbol: "percent"
            )
        }
    }

    private func eligibleScope(_ result: FickValidationRunResult) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(language.text("評価に含まれた範囲", "Eligible evaluation scope"))
                .font(.headline)

            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 190), spacing: 12)],
                alignment: .leading,
                spacing: 12
            ) {
                metricCard(
                    identifier: "experiment.fick-validation.eligible-families",
                    title: language.text("eligible families", "Eligible families"),
                    value: result.eligibleFamilyCount.formatted(),
                    detail: language.text("除外 \(result.excludedFamilyCount)", "\(result.excludedFamilyCount) excluded"),
                    symbol: "square.stack.3d.up"
                )
                metricCard(
                    identifier: "experiment.fick-validation.eligible-conditions",
                    title: language.text("eligible conditions", "Eligible conditions"),
                    value: result.eligibleConditionCount.formatted(),
                    detail: language.text("除外 \(result.excludedConditionCount)", "\(result.excludedConditionCount) excluded"),
                    symbol: "point.3.connected.trianglepath.dotted"
                )
                metricCard(
                    identifier: "experiment.fick-validation.eligible-rows",
                    title: language.text("eligible rows", "Eligible rows"),
                    value: result.eligibleObservationCount.formatted(),
                    detail: language.text("除外 \(result.excludedObservationCount)", "\(result.excludedObservationCount) excluded"),
                    symbol: "list.number"
                )
            }
        }
        .accessibilityIdentifier("experiment.fick-validation.eligible-scope")
    }

    private func stressView(_ result: FickValidationRunResult) -> some View {
        let stress = result.leaveOneFamilyOutStress
        return DisclosureGroup(language.text(
            "stress: leave-one-family-out",
            "Stress: leave one family out"
        )) {
            VStack(alignment: .leading, spacing: 12) {
                Text(language.text(
                    "drug × skin × MN typeのfamilyを丸ごと外し、近いconditionへの補間より厳しい移送を確認します。",
                    "Each drug × skin × MN-type family is held out in full, testing a harder transfer than interpolation to a nearby condition."
                ))
                .font(.callout)
                .foregroundStyle(.secondary)

                Grid(alignment: .leading, horizontalSpacing: 18, verticalSpacing: 7) {
                    GridRow {
                        Text("R²").bold()
                        Text(formatOptional(stress.metric.rSquared)).monospacedDigit()
                    }
                    GridRow {
                        Text("RMSE").bold()
                        Text(format(stress.metric.rmse) + " pp").monospacedDigit()
                    }
                    GridRow {
                        Text("MAE").bold()
                        Text(format(stress.metric.mae) + " pp").monospacedDigit()
                    }
                    GridRow {
                        Text(language.text("families", "Families")).bold()
                        Text(stress.familyCount.formatted()).monospacedDigit()
                    }
                    GridRow {
                        Text(language.text("rows", "Rows")).bold()
                        Text(stress.observationCount.formatted()).monospacedDigit()
                    }
                }

                ForEach(stress.folds, id: \.id) { fold in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "arrow.turn.down.right")
                            .foregroundStyle(.secondary)
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(familyTitle(fold.heldOutFamily))
                                .font(.callout.weight(.semibold))
                            Text(language.text(
                                "train \(fold.trainingRowIDs.count)行 · test \(fold.testRowIDs.count)行",
                                "\(fold.trainingRowIDs.count) train rows · \(fold.testRowIDs.count) test rows"
                            ))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .padding(.top, 9)
        }
        .accessibilityIdentifier("experiment.fick-validation.stress")
    }

    private func familyMetricsView(_ result: FickValidationRunResult) -> some View {
        DisclosureGroup(language.text("family別proxy成績", "Proxy metrics by family")) {
            VStack(alignment: .leading, spacing: 9) {
                ForEach(result.familyMetrics, id: \.family.id) { entry in
                    HStack(alignment: .firstTextBaseline, spacing: 12) {
                        Text(familyTitle(entry.family))
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text("R² " + formatOptional(entry.metric.rSquared))
                            .monospacedDigit()
                        Text("RMSE " + format(entry.metric.rmse) + " pp")
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                    .font(.callout)
                    Divider()
                }
            }
            .padding(.top, 9)
        }
        .accessibilityIdentifier("experiment.fick-validation.family-metrics")
    }

    @ViewBuilder
    private func runMessages(_ result: FickValidationRunResult) -> some View {
        if !result.warnings.isEmpty || !result.limitations.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(Array(result.warnings.enumerated()), id: \.offset) { _, message in
                    LabNotice(
                        title: language.text("run警告", "Run warning"),
                        message: message.resolve(language),
                        kind: .limitation
                    )
                }
                ForEach(Array(result.limitations.enumerated()), id: \.offset) { _, message in
                    LabNotice(
                        title: language.text("解釈限界", "Interpretation limit"),
                        message: message.resolve(language),
                        kind: .warning
                    )
                }
            }
            .accessibilityIdentifier("experiment.fick-validation.messages")
        }
    }

    private var historyView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Divider()
            HStack {
                Text(language.text("最近のFick proxy run", "Recent Fick proxy runs"))
                    .font(.headline)
                Spacer()
                if !recentRuns.isEmpty {
                    Button(role: .destructive) {
                        isConfirmingHistoryClear = true
                    } label: {
                        Label(language.text("履歴を消去", "Clear history"), systemImage: "trash")
                    }
                    .accessibilityIdentifier("experiment.fick-validation.clear-history")
                }
            }

            if recentRuns.isEmpty {
                Text(language.text(
                    "最大10件のraw計算runがこのMacへ保存され、選択時に毎回再監査されます。",
                    "Up to ten raw calculation runs are stored on this Mac and independently re-audited whenever selected."
                ))
                .font(.callout)
                .foregroundStyle(.secondary)
            } else {
                ForEach(recentRuns) { run in
                    Button {
                        result = run
                        startAudit(run)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "clock.arrow.circlepath")
                            VStack(alignment: .leading, spacing: 3) {
                                Text(language.text(
                                    "保存raw run・選択後に再監査",
                                    "Saved raw run · re-audited on selection"
                                ))
                                    .font(.headline)
                                Text(run.completedAt.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            historyAuditIcon(run)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .padding(10)
                    .labCard(radius: 10)
                    .accessibilityIdentifier("experiment.fick-validation.history.\(run.id.uuidString)")
                }
            }
        }
        .accessibilityIdentifier("experiment.fick-validation.history")
    }

    @ViewBuilder
    private func historyAuditIcon(_ run: FickValidationRunResult) -> some View {
        if auditedResultID == run.id {
            Image(systemName: "checkmark.shield.fill")
                .foregroundStyle(.green)
                .accessibilityLabel(language.text(
                    "このsessionで再監査済み",
                    "Re-audited in this session"
                ))
        } else if failedAuditResultID == run.id {
            Image(systemName: "xmark.shield.fill")
                .foregroundStyle(.red)
                .accessibilityLabel(language.text(
                    "再監査不合格",
                    "Re-audit failed"
                ))
        } else {
            Image(systemName: "shield.lefthalf.filled")
                .foregroundStyle(.secondary)
                .accessibilityLabel(language.text(
                    "未監査の保存run",
                    "Saved run not yet audited"
                ))
        }
    }

    private func metricCard(
        identifier: String,
        title: String,
        value: String,
        detail: String,
        symbol: String
    ) -> some View {
        LabMetricCard(title: title, value: value, detail: detail, systemImage: symbol)
            .accessibilityIdentifier(identifier)
    }

    private var canRun: Bool {
        !isRunning
            && !isAuditing
            && !dataset.rows.isEmpty
            && dataset.audit.isValid
            && datasetSnapshot.schemaIsValid
            && datasetSnapshot.rowCount == dataset.rows.count
            && datasetSnapshot.resolvedResearchMode == .myExperiment
            && datasetSnapshot.resolvedScientificStatus == .userProvidedUnvalidated
    }

    private func startRun() {
        guard canRun else { return }
        cancelRun()
        cancelAudit()
        clearAuditPresentation()
        result = nil
        errorMessage = nil
        isRunning = true

        let capturedDataset = dataset
        let capturedSnapshot = datasetSnapshot
        let capturedConfiguration = configuration
        let capturedRunID = UUID()
        let capturedStart = Date()
        activeRunID = capturedRunID

        runTask = Task {
            defer {
                if activeRunID == capturedRunID {
                    activeRunID = nil
                    isRunning = false
                    runTask = nil
                }
            }
            do {
                let worker = Task.detached(priority: .userInitiated) {
                    try FickValidationExperiment.run(
                        dataset: capturedDataset,
                        displayName: capturedSnapshot.displayName,
                        isBundledData: false,
                        researchMode: .myExperiment,
                        scientificStatus: .userProvidedUnvalidated,
                        importedAt: capturedSnapshot.importedAt,
                        configuration: capturedConfiguration,
                        runID: capturedRunID,
                        startedAt: capturedStart
                    )
                }
                let completed = try await withTaskCancellationHandler {
                    try await worker.value
                } onCancel: {
                    worker.cancel()
                }
                guard !Task.isCancelled, activeRunID == capturedRunID else { return }
                result = completed
                recentRuns = persistence.save([completed] + recentRuns)
                startAudit(completed)
                try writeAutomaticExportIfRequested(completed)
            } catch is CancellationError {
                // Explicit cancellation and navigation are expected paths.
            } catch {
                guard !Task.isCancelled, activeRunID == capturedRunID else { return }
                errorMessage = error.localizedDescription
            }
        }
    }

    private func cancelRun() {
        runTask?.cancel()
        runTask = nil
        activeRunID = nil
        isRunning = false
    }

    private func startAudit(_ candidate: FickValidationRunResult) {
        cancelAudit()
        clearAuditPresentation()

        let token = UUID()
        activeAuditToken = token
        let capturedDataset = dataset
        auditTask = Task {
            defer {
                if activeAuditToken == token {
                    activeAuditToken = nil
                    auditTask = nil
                }
            }
            do {
                let worker = Task.detached(priority: .userInitiated) {
                    let diagnostics = try FickValidationDiagnosticsEngine.make(
                        run: candidate,
                        dataset: capturedDataset
                    )
                    let sidecarData = try FickValidationAuditExportEncoder.data(
                        for: candidate,
                        dataset: capturedDataset
                    )
                    return (diagnostics: diagnostics, sidecarData: sidecarData)
                }
                let audited = try await withTaskCancellationHandler {
                    try await worker.value
                } onCancel: {
                    worker.cancel()
                }
                guard !Task.isCancelled, activeAuditToken == token else { return }
                auditedDiagnostics = audited.diagnostics
                auditedSidecarData = audited.sidecarData
                auditedResultID = candidate.id
            } catch is CancellationError {
                // Selection changes and navigation cancel stale audits.
            } catch {
                guard !Task.isCancelled, activeAuditToken == token else { return }
                failedAuditResultID = candidate.id
                auditFailureMessage = error.localizedDescription
            }
        }
    }

    private func cancelAudit() {
        auditTask?.cancel()
        auditTask = nil
        activeAuditToken = nil
    }

    private var isAuditing: Bool {
        activeAuditToken != nil
    }

    private func clearAuditPresentation() {
        auditedResultID = nil
        auditedDiagnostics = nil
        auditedSidecarData = nil
        failedAuditResultID = nil
        auditFailureMessage = nil
    }

    private func resumeAuditIfNeeded() {
        guard activeAuditToken == nil,
              let result,
              auditedResultID != result.id,
              failedAuditResultID != result.id else { return }
        startAudit(result)
    }

    private func startAutomaticRunIfNeeded() {
        guard ProcessInfo.processInfo.arguments.contains("-fick-85-auto-run"),
              !didAttemptAutomaticRun,
              result == nil,
              canRun else { return }
        didAttemptAutomaticRun = true
        startRun()
    }

    private func export(_ result: FickValidationRunResult) {
        do {
            exportDocument = ExperimentJSONDocument(
                data: try FickValidationExportEncoder.data(for: result)
            )
            exportSuggestedFilename = "fick-85-proxy-validation-\(result.id.uuidString.prefix(8))"
            isExporting = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func exportAudit(_ result: FickValidationRunResult) {
        guard auditedResultID == result.id,
              let auditedSidecarData else {
            errorMessage = language.text(
                "独立再計算監査が完了するまでsidecarは保存できません。",
                "The sidecar cannot be saved until independent replay audit has completed."
            )
            return
        }
        exportDocument = ExperimentJSONDocument(data: auditedSidecarData)
        exportSuggestedFilename = "fick-85-evidence-audit-\(result.id.uuidString.prefix(8))"
        isExporting = true
    }

    private func runExportButton(_ result: FickValidationRunResult) -> some View {
        Button {
            export(result)
        } label: {
            Label(language.text("run JSON", "Run JSON"), systemImage: "square.and.arrow.up")
        }
        .accessibilityIdentifier("experiment.fick-validation.export")
    }

    private func auditExportButton(_ result: FickValidationRunResult) -> some View {
        Button {
            exportAudit(result)
        } label: {
            Label(
                language.text("監査sidecar JSON", "Audit sidecar JSON"),
                systemImage: "checkmark.shield"
            )
        }
        .accessibilityIdentifier("experiment.fick-validation.export-audit")
    }

    /// Reproducibility-only export used by the documented command-line harness.
    /// Normal interactive launches continue to use the native save panel above.
    private func writeAutomaticExportIfRequested(_ result: FickValidationRunResult) throws {
        let arguments = ProcessInfo.processInfo.arguments
        guard let flagIndex = arguments.firstIndex(of: "-fick-85-export-path") else { return }
        guard arguments.indices.contains(flagIndex + 1) else {
            throw FickAutomaticExportError.missingPath
        }
        let path = arguments[flagIndex + 1]
        guard (path as NSString).isAbsolutePath else {
            throw FickAutomaticExportError.pathMustBeAbsolute
        }
        guard !FileManager.default.fileExists(atPath: path) else {
            throw FickAutomaticExportError.outputAlreadyExists(path)
        }

        try FickValidationExportEncoder.data(for: result)
            .write(to: URL(fileURLWithPath: path), options: .atomic)

        if arguments.contains("-fick-85-exit-after-export") {
            DispatchQueue.main.async {
                NSApplication.shared.terminate(nil)
            }
        }
    }

    private func familyTitle(_ family: FickValidationFamily) -> String {
        family.drugName
            + " · skin " + family.skinCode.formatted()
            + " · MN " + family.needleTypeCode.formatted()
    }

    private func format(_ value: Double) -> String {
        value.formatted(.number.precision(.significantDigits(4)))
    }

    private func formatOptional(_ value: Double?) -> String {
        value.map(format) ?? language.text("未定義", "Undefined")
    }

    private func interval(lower: Double?, upper: Double?) -> String {
        guard let lower, let upper else { return language.text("未定義", "Undefined") }
        return format(lower) + "–" + format(upper)
    }

    private func percent(_ value: Double?) -> String {
        guard let value else { return language.text("未定義", "Undefined") }
        return (100 * value).formatted(.number.precision(.fractionLength(1))) + "%"
    }
}
