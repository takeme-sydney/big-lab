import CryptoKit
import Foundation

private func fickValidationSHA256Hex(_ data: Data) -> String {
    SHA256.hash(data: data)
        .map { String(format: "%02x", $0) }
        .joined()
}

enum FickValidationComparator: String, CaseIterable, Codable, Identifiable, Sendable {
    case fickProxy
    case familyTimeControl

    var id: Self { self }
}

enum FickValidationBaselinePredictionMode: String, Codable, Sendable {
    case exactTrainingTime
    case linearInterpolation
    case endpointHold
}

struct FickValidationBaselinePrediction: Identifiable, Equatable, Codable, Sendable {
    let rowID: Int
    let family: FickValidationFamily
    let condition: FickValidationCondition
    let foldID: String
    let timeHours: Double
    let observedPercentage: Double
    let predictedPercentage: Double
    let mode: FickValidationBaselinePredictionMode

    var id: String { "\(foldID)|\(rowID)" }
}

struct FickValidationCalibrationAudit: Equatable, Codable, Sendable {
    let intercept: Double?
    let slope: Double?
    /// Mean(predicted - observed), in percentage points. Ideal value is zero.
    let meanErrorPercentagePoints: Double
}

struct FickValidationComparatorSummary: Identifiable, Equatable, Codable, Sendable {
    let comparator: FickValidationComparator
    let rowPooledMetric: FickValidationMetric
    let conditionBalancedMetric: FickValidationMetric
    let familyCenteredRSquared: Double?
    let macroFamilyRSquared: Double?
    let conditionCount: Int
    let familyCount: Int
    let calibration: FickValidationCalibrationAudit

    var id: FickValidationComparator { comparator }
}

struct FickValidationTSSAudit: Equatable, Codable, Sendable {
    let globalTSS: Double
    let withinFamilyTSS: Double
    let betweenFamilyTSS: Double
    let betweenFamilyShare: Double?
}

struct FickValidationConditionAudit: Identifiable, Equatable, Codable, Sendable {
    let condition: FickValidationCondition
    let observationCount: Int
    let fickMetric: FickValidationMetric
    let controlMetric: FickValidationMetric
    let controlExactTimeCount: Int
    let controlInterpolationCount: Int
    let controlEndpointHoldCount: Int
    let fickWinsRMSE: Bool
    let fickRSquaredMeetsTarget: Bool?

    var id: String { condition.id }
}

struct FickValidationConditionInfluence: Identifiable, Equatable, Codable, Sendable {
    let condition: FickValidationCondition
    let excludedObservationCount: Int
    let rowPooledRSquaredWithoutCondition: Double?

    var id: String { condition.id }
}

struct FickValidationFamilyInfluence: Identifiable, Equatable, Codable, Sendable {
    let family: FickValidationFamily
    let excludedObservationCount: Int
    let rowPooledRSquaredWithoutFamily: Double?

    var id: String { family.id }
}

struct FickValidationSourceBlockAudit: Identifiable, Equatable, Codable, Sendable {
    let id: String
    let citation: String
    let rowIDs: [Int]
    let familyIDs: [String]
}

struct FickValidationHierarchyAudit: Equatable, Codable, Sendable {
    let canonicalMergedCellForwardFillApplied: Bool
    let rawReferencedRowCount: Int
    let resolvedSourceRowCount: Int
    let totalRowCount: Int
    let sourceBlockCount: Int
    let uniqueCitationCount: Int
    let eligibleSourceCount: Int
    let eligibleFamilySourceConfoundedCount: Int
    let sourceBlocks: [FickValidationSourceBlockAudit]
    let hasExperimentRunID: Bool
    let hasPermeationCurveID: Bool
    let hasDonorID: Bool
    let hasBatchID: Bool
    let hasSiteID: Bool
}

enum FickValidationGateStatus: String, Codable, Sendable {
    case met
    case notMet
    case unavailable
}

struct FickValidationEvidenceGate: Identifiable, Equatable, Codable, Sendable {
    let id: String
    let status: FickValidationGateStatus
    let measuredValue: Double?
    let targetValue: Double?
}

struct FickValidationDiagnostics: Equatable, Codable, Sendable {
    let comparatorSummaries: [FickValidationComparatorSummary]
    let recomputedFamilyMetrics: [FickValidationFamilyMetric]
    let leaveOneFamilyOutMetric: FickValidationMetric
    let baselinePredictions: [FickValidationBaselinePrediction]
    let baselineModeCounts: [String: Int]
    let tss: FickValidationTSSAudit
    let conditions: [FickValidationConditionAudit]
    let conditionInfluence: [FickValidationConditionInfluence]
    let familyInfluence: [FickValidationFamilyInfluence]
    let hierarchy: FickValidationHierarchyAudit
    let gates: [FickValidationEvidenceGate]
}

enum FickValidationDiagnosticsError: LocalizedError, Equatable, Sendable {
    case unsupportedRunSchema(String)
    case invalidConfiguration
    case datasetMismatch
    case duplicateDatasetRow(rowID: Int)
    case duplicateFold(foldID: String)
    case duplicatePrediction(rowID: Int)
    case missingRow(rowID: Int)
    case observedValueMismatch(rowID: Int)
    case timeValueMismatch(rowID: Int)
    case rowConditionMismatch(rowID: Int)
    case nonFinitePrediction(rowID: Int)
    case invalidFold(foldID: String)
    case predictionPopulationMismatch(foldID: String)
    case foldFitMismatch(foldID: String)
    case predictionValueMismatch(rowID: Int)
    case confidenceIntervalMismatch
    case runScopeMismatch
    case runMetricMismatch
    case runNarrativeMismatch
    case auditRunHashMismatch
    case auditDiagnosticsMismatch

    var errorDescription: String? {
        switch self {
        case .unsupportedRunSchema(let version):
            "Run schema \(version) is not supported by this audit engine."
        case .invalidConfiguration:
            "The saved run does not use the locked Fick R-squared 0.85 protocol."
        case .datasetMismatch:
            "The audit dataset does not match the validation run's normalized dataset hash."
        case .duplicateDatasetRow(let rowID):
            "The audit dataset contains duplicate row identifier \(rowID)."
        case .duplicateFold(let foldID):
            "The validation run contains duplicate fold identifier \(foldID)."
        case .duplicatePrediction(let rowID):
            "The validation run contains more than one primary prediction for row \(rowID)."
        case .missingRow(let rowID):
            "The audit dataset is missing row \(rowID) referenced by the validation run."
        case .observedValueMismatch(let rowID):
            "The observed outcome for row \(rowID) differs from the validation run."
        case .timeValueMismatch(let rowID):
            "The permeation time for row \(rowID) differs from the validation run."
        case .rowConditionMismatch(let rowID):
            "The family or condition for row \(rowID) differs from the audit dataset."
        case .nonFinitePrediction(let rowID):
            "The prediction for row \(rowID) is non-finite or outside the proxy's allowed range."
        case .invalidFold(let foldID):
            "Fold \(foldID) has missing, overlapping, or inconsistent row identifiers."
        case .predictionPopulationMismatch(let foldID):
            "Fold \(foldID) does not have exactly one prediction for every test row."
        case .foldFitMismatch(let foldID):
            "Fold \(foldID) does not reproduce the fitted A, k, and SSE values from its training rows."
        case .predictionValueMismatch(let rowID):
            "The saved prediction for row \(rowID) does not reproduce from the audited fold fit and Fick equation."
        case .confidenceIntervalMismatch:
            "The saved fixed-OOF percentile summary does not reproduce from the audited predictions."
        case .runScopeMismatch:
            "The run's saved eligibility counts do not match its validated prediction population."
        case .runMetricMismatch:
            "The run's saved metrics do not match metrics recomputed from validated predictions."
        case .runNarrativeMismatch:
            "The run's saved warnings or limitations do not match the deterministic audited notices."
        case .auditRunHashMismatch:
            "The audit sidecar is not bound to these exact run-export bytes."
        case .auditDiagnosticsMismatch:
            "The audit sidecar diagnostics or audited-run metadata do not match an independent replay."
        }
    }
}

/// A separately encoded audit artifact. Keeping this sidecar independent from
/// `FickValidationRunResult` preserves schema 1.1 run-history compatibility.
struct FickValidationAuditSidecar: Equatable, Codable, Sendable {
    static let currentSchemaVersion = "1.1"

    let schemaVersion: String
    let auditedRunID: UUID
    let auditedRunSchemaVersion: String
    let auditedModelVersion: String
    let auditedDatasetNormalizedSHA256: String
    let auditedRunExportSHA256: String
    let diagnosticsEngineVersion: String
    let diagnostics: FickValidationDiagnostics

    fileprivate init(
        run: FickValidationRunResult,
        diagnostics: FickValidationDiagnostics,
        auditedRunExportSHA256: String
    ) {
        schemaVersion = Self.currentSchemaVersion
        auditedRunID = run.id
        auditedRunSchemaVersion = run.schemaVersion
        auditedModelVersion = run.modelVersion
        auditedDatasetNormalizedSHA256 = run.dataset.normalizedSHA256
        self.auditedRunExportSHA256 = auditedRunExportSHA256
        diagnosticsEngineVersion = FickValidationDiagnosticsEngine.version
        self.diagnostics = diagnostics
    }
}

enum FickValidationAuditExportEncoder {
    static func data(
        for run: FickValidationRunResult,
        dataset: TrainingDataset
    ) throws -> Data {
        let runExport = try FickValidationExportEncoder.data(for: run)
        // Diagnostics are deliberately recomputed here. The API cannot pair a
        // run with arbitrary diagnostics from another run.
        let diagnostics = try FickValidationDiagnosticsEngine.make(
            run: run,
            dataset: dataset
        )
        let runHash = fickValidationSHA256Hex(runExport)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        return try encoder.encode(FickValidationAuditSidecar(
            run: run,
            diagnostics: diagnostics,
            auditedRunExportSHA256: runHash
        ))
    }

    static func verify(
        sidecarData: Data,
        runExportData: Data,
        dataset: TrainingDataset
    ) throws -> FickValidationAuditSidecar {
        let sidecar = try JSONDecoder().decode(
            FickValidationAuditSidecar.self,
            from: sidecarData
        )
        guard sidecar.schemaVersion == FickValidationAuditSidecar.currentSchemaVersion,
              sidecar.diagnosticsEngineVersion == FickValidationDiagnosticsEngine.version,
              sidecar.auditedRunExportSHA256 == fickValidationSHA256Hex(runExportData) else {
            throw FickValidationDiagnosticsError.auditRunHashMismatch
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let run = try decoder.decode(FickValidationRunResult.self, from: runExportData)
        let diagnostics = try FickValidationDiagnosticsEngine.make(
            run: run,
            dataset: dataset
        )
        guard sidecar.auditedRunID == run.id,
              sidecar.auditedRunSchemaVersion == run.schemaVersion,
              sidecar.auditedModelVersion == run.modelVersion,
              sidecar.auditedDatasetNormalizedSHA256 == run.dataset.normalizedSHA256,
              sidecar.diagnostics == diagnostics else {
            throw FickValidationDiagnosticsError.auditDiagnosticsMismatch
        }
        return sidecar
    }
}

enum FickValidationDiagnosticsEngine {
    static let version = "2.0.0-replay-ci"

    private final class DiagnosticsBox: NSObject {
        let diagnostics: FickValidationDiagnostics

        init(_ diagnostics: FickValidationDiagnostics) {
            self.diagnostics = diagnostics
        }
    }

    private struct ValidatedReplay {
        let primaryPredictions: [FickValidationPrediction]
        let stressPredictions: [FickValidationPrediction]
    }

    private struct ValidatedStressReplay {
        let predictions: [FickValidationPrediction]
        let boundaryFitCount: Int
        let foldCount: Int
    }

    private static let cache: NSCache<NSString, DiagnosticsBox> = {
        let cache = NSCache<NSString, DiagnosticsBox>()
        cache.countLimit = 12
        return cache
    }()

    private struct ComparablePrediction {
        let rowID: Int
        let family: FickValidationFamily
        let condition: FickValidationCondition
        let foldID: String
        let observed: Double
        let predicted: Double
    }

    private struct ResolvedSourceRow {
        let rowID: Int
        let sourceID: String?
        let citation: String?
        let familyID: String
    }

    static func make(
        run: FickValidationRunResult,
        dataset: TrainingDataset
    ) throws -> FickValidationDiagnostics {
        let runExport = try FickValidationExportEncoder.data(for: run)
        let cacheKey = [
            version,
            fickValidationSHA256Hex(runExport),
            ExperimentDatasetIdentity.identity(for: dataset).normalizedSHA256,
        ].joined(separator: "|") as NSString
        if let cached = cache.object(forKey: cacheKey) {
            return cached.diagnostics
        }

        let replay = try validate(run: run, dataset: dataset)
        let diagnostics = make(
            dataset: dataset,
            targetRSquared: run.configuration.targetRSquared,
            predictions: replay.primaryPredictions,
            folds: run.folds,
            leaveOneFamilyOutPredictions: replay.stressPredictions
        )
        cache.setObject(DiagnosticsBox(diagnostics), forKey: cacheKey, cost: run.predictions.count)
        return diagnostics
    }

    private static func make(
        dataset: TrainingDataset,
        targetRSquared: Double,
        predictions: [FickValidationPrediction],
        folds: [FickValidationFold],
        leaveOneFamilyOutPredictions: [FickValidationPrediction]
    ) -> FickValidationDiagnostics {
        let fickComparable = predictions.map {
            ComparablePrediction(
                rowID: $0.rowID,
                family: $0.family,
                condition: $0.condition,
                foldID: $0.foldID,
                observed: $0.observedPercentage,
                predicted: $0.predictedPercentage
            )
        }
        let baselinePredictions = makeBaselinePredictions(dataset: dataset, folds: folds)
        let baselineComparable = baselinePredictions.map {
            ComparablePrediction(
                rowID: $0.rowID,
                family: $0.family,
                condition: $0.condition,
                foldID: $0.foldID,
                observed: $0.observedPercentage,
                predicted: $0.predictedPercentage
            )
        }
        let leaveOneFamilyOutComparable = leaveOneFamilyOutPredictions.map {
            ComparablePrediction(
                rowID: $0.rowID,
                family: $0.family,
                condition: $0.condition,
                foldID: $0.foldID,
                observed: $0.observedPercentage,
                predicted: $0.predictedPercentage
            )
        }

        let fickSummary = summarize(.fickProxy, predictions: fickComparable)
        let baselineSummary = summarize(.familyTimeControl, predictions: baselineComparable)
        let recomputedFamilyMetrics = makeFamilyMetrics(predictions: fickComparable)
        let leaveOneFamilyOutMetric = metric(leaveOneFamilyOutComparable)
        let conditionAudits = makeConditionAudits(
            fick: fickComparable,
            baseline: baselinePredictions,
            targetRSquared: targetRSquared
        )
        let hierarchy = makeHierarchyAudit(
            dataset: dataset,
            eligiblePredictions: predictions
        )
        let aggregationCandidates = [
            fickSummary.conditionBalancedMetric.rSquared,
            fickSummary.familyCenteredRSquared,
            fickSummary.macroFamilyRSquared,
        ]
        let aggregationValues = finiteValuesRequiringAll(aggregationCandidates)
        let aggregationFloor = aggregationValues?.min()
        let baselinePairs = zip(
            [
                fickSummary.rowPooledMetric.rSquared,
                fickSummary.conditionBalancedMetric.rSquared,
                fickSummary.familyCenteredRSquared,
                fickSummary.macroFamilyRSquared,
            ],
            [
                baselineSummary.rowPooledMetric.rSquared,
                baselineSummary.conditionBalancedMetric.rSquared,
                baselineSummary.familyCenteredRSquared,
                baselineSummary.macroFamilyRSquared,
            ]
        ).map { pair -> Double? in
            let (lhs, rhs) = pair
            guard let lhs, let rhs, lhs.isFinite, rhs.isFinite else { return nil }
            return lhs - rhs
        }
        let baselineDeltas = finiteValuesRequiringAll(baselinePairs)
        let baselineDelta = baselineDeltas?.min()
        let familyValues = finiteValuesRequiringAll(
            recomputedFamilyMetrics.map(\.metric.rSquared)
        )
        let familyFloor = familyValues?.min()
        let familyStatus: FickValidationGateStatus = familyValues.map {
            !$0.isEmpty && $0.allSatisfy { $0 >= targetRSquared } ? .met : .notMet
        } ?? .unavailable
        let aggregationStatus: FickValidationGateStatus = aggregationFloor.map {
            $0 >= targetRSquared ? .met : .notMet
        } ?? .unavailable
        let baselineStatus = exploratoryBaselineStatus(
            rSquaredDeltas: baselinePairs,
            fickRMSE: fickSummary.rowPooledMetric.rmse,
            controlRMSE: baselineSummary.rowPooledMetric.rmse,
            fickMAE: fickSummary.rowPooledMetric.mae,
            controlMAE: baselineSummary.rowPooledMetric.mae
        )
        let rowPooledStatus: FickValidationGateStatus = fickSummary.rowPooledMetric.rSquared.map {
            $0.isFinite && $0 >= targetRSquared ? .met : .notMet
        } ?? .unavailable

        return FickValidationDiagnostics(
            comparatorSummaries: [fickSummary, baselineSummary],
            recomputedFamilyMetrics: recomputedFamilyMetrics,
            leaveOneFamilyOutMetric: leaveOneFamilyOutMetric,
            baselinePredictions: baselinePredictions,
            baselineModeCounts: Dictionary(
                grouping: baselinePredictions,
                by: { $0.mode.rawValue }
            ).mapValues(\.count),
            tss: makeTSSAudit(predictions: fickComparable),
            conditions: conditionAudits,
            conditionInfluence: makeConditionInfluence(predictions: fickComparable),
            familyInfluence: makeFamilyInfluence(predictions: fickComparable),
            hierarchy: hierarchy,
            gates: [
                FickValidationEvidenceGate(
                    id: "calculation-completed",
                    status: .met,
                    measuredValue: Double(
                        predictions.count + leaveOneFamilyOutPredictions.count
                    ),
                    targetValue: nil
                ),
                FickValidationEvidenceGate(
                    id: "row-pooled-point",
                    status: rowPooledStatus,
                    measuredValue: fickSummary.rowPooledMetric.rSquared,
                    targetValue: targetRSquared
                ),
                FickValidationEvidenceGate(
                    id: "aggregation-robustness",
                    status: aggregationStatus,
                    measuredValue: aggregationFloor,
                    targetValue: targetRSquared
                ),
                FickValidationEvidenceGate(
                    id: "simple-baseline",
                    status: baselineStatus,
                    measuredValue: baselineDelta,
                    targetValue: 0
                ),
                FickValidationEvidenceGate(
                    id: "every-family",
                    status: familyStatus,
                    measuredValue: familyFloor,
                    targetValue: targetRSquared
                ),
                FickValidationEvidenceGate(
                    id: "independent-run-curve",
                    status: hierarchy.hasExperimentRunID && hierarchy.hasPermeationCurveID
                        ? .met : .unavailable,
                    measuredValue: nil,
                    targetValue: nil
                ),
                FickValidationEvidenceGate(
                    id: "external-confirmation",
                    status: .unavailable,
                    measuredValue: nil,
                    targetValue: targetRSquared
                ),
            ]
        )
    }

    private static func validate(
        run: FickValidationRunResult,
        dataset: TrainingDataset
    ) throws -> ValidatedReplay {
        guard run.schemaVersion == FickValidationRunResult.currentSchemaVersion else {
            throw FickValidationDiagnosticsError.unsupportedRunSchema(run.schemaVersion)
        }
        guard FickValidationExperiment.supports(run.configuration) else {
            throw FickValidationDiagnosticsError.invalidConfiguration
        }
        let identity = ExperimentDatasetIdentity.identity(for: dataset)
        guard identity.normalizedSHA256 == run.dataset.normalizedSHA256,
              dataset.rows.count == run.dataset.rowCount,
              dataset.audit.isValid,
              run.modelVersion == FickValidationExperiment.modelVersion,
              run.evidenceLevel == .exploratoryProxyConditionCrossValidation,
              run.dataset.resolvedResearchMode == .myExperiment,
              run.dataset.resolvedScientificStatus == .userProvidedUnvalidated,
              !run.dataset.isBundledSource,
              run.dataset.columnCount == dataset.audit.columnCount,
              run.dataset.schemaIsValid,
              run.dataset.auditErrorCount == 0,
              run.dataset.predictorFields == ExperimentPredictor.allCases.map(\.sourceColumn),
              run.dataset.sha256 == run.dataset.normalizedSHA256,
              run.dataset.sha256Basis == .normalizedParsedValues,
              !run.exactPaperReplayAvailable else {
            throw FickValidationDiagnosticsError.datasetMismatch
        }

        let rowIDs = dataset.rows.map(\.id)
        guard Set(rowIDs).count == rowIDs.count else {
            let duplicate = Dictionary(grouping: rowIDs, by: { $0 })
                .first { $0.value.count > 1 }?.key ?? -1
            throw FickValidationDiagnosticsError.duplicateDatasetRow(rowID: duplicate)
        }
        let foldIDs = run.folds.map(\.id)
        guard Set(foldIDs).count == foldIDs.count else {
            let duplicate = Dictionary(grouping: foldIDs, by: { $0 })
                .first { $0.value.count > 1 }?.key ?? "unknown"
            throw FickValidationDiagnosticsError.duplicateFold(foldID: duplicate)
        }
        let predictionRowIDs = run.predictions.map(\.rowID)
        guard Set(predictionRowIDs).count == predictionRowIDs.count else {
            let duplicate = Dictionary(grouping: predictionRowIDs, by: { $0 })
                .first { $0.value.count > 1 }?.key ?? -1
            throw FickValidationDiagnosticsError.duplicatePrediction(rowID: duplicate)
        }

        let rowByID = Dictionary(uniqueKeysWithValues: dataset.rows.map { ($0.id, $0) })
        let foldByID = Dictionary(uniqueKeysWithValues: run.folds.map { ($0.id, $0) })
        let predictionsByFold = Dictionary(grouping: run.predictions, by: \.foldID)
        let allFamilies = Set(dataset.rows.map(family))
        let allConditions = Set(dataset.rows.map(condition))
        let conditionsByFamily = Dictionary(grouping: allConditions, by: \.family)
        let expectedEligibleFamilies = Set(conditionsByFamily.compactMap { entry in
            entry.value.count >= 3 ? entry.key : nil
        })
        let expectedEligibleConditions = Set(allConditions.filter {
            expectedEligibleFamilies.contains($0.family)
        })
        guard Set(run.folds.map(\.heldOutCondition)) == expectedEligibleConditions else {
            throw FickValidationDiagnosticsError.runScopeMismatch
        }

        var allTestRowIDs = Set<Int>()
        var replayFitByFoldID: [String: FickValidationFittedParameters] = [:]
        for fold in run.folds.sorted(by: { $0.id < $1.id }) {
            try Task.checkCancellation()
            let training = Set(fold.trainingRowIDs)
            let testing = Set(fold.testRowIDs)
            guard training.count == fold.trainingRowIDs.count,
                  testing.count == fold.testRowIDs.count,
                  !testing.isEmpty,
                  training.isDisjoint(with: testing),
                  allTestRowIDs.isDisjoint(with: testing),
                  training.isSubset(of: Set(rowIDs)),
                  testing.isSubset(of: Set(rowIDs)) else {
                throw FickValidationDiagnosticsError.invalidFold(foldID: fold.id)
            }
            allTestRowIDs.formUnion(testing)

            let expectedTesting = Set(dataset.rows.filter {
                condition($0) == fold.heldOutCondition
            }.map(\.id))
            let expectedTraining = Set(dataset.rows.filter {
                let rowCondition = condition($0)
                return rowCondition.family == fold.heldOutCondition.family
                    && rowCondition != fold.heldOutCondition
            }.map(\.id))
            let expectedTrainingConditions = Set(expectedTraining.compactMap {
                rowByID[$0].map(condition)
            }.map(\.id))
            guard testing == expectedTesting,
                  training == expectedTraining,
                  Set(fold.trainingConditionIDs) == expectedTrainingConditions,
                  Set(fold.trainingConditionIDs).count == fold.trainingConditionIDs.count,
                  !fold.trainingConditionIDs.contains(fold.heldOutCondition.id) else {
                throw FickValidationDiagnosticsError.invalidFold(foldID: fold.id)
            }

            let trainingRows = try expectedTraining.sorted().map { rowID in
                guard let row = rowByID[rowID] else {
                    throw FickValidationDiagnosticsError.missingRow(rowID: rowID)
                }
                return row
            }
            let replayFit = try FickValidationExperiment.recomputeFit(
                rows: trainingRows,
                configuration: run.configuration
            )
            guard close(fold.fittedAmplitude, replayFit.amplitude, tolerance: 1e-10),
                  close(fold.fittedRate, replayFit.rate, tolerance: 1e-10),
                  close(fold.trainingSSE, replayFit.sse, tolerance: 1e-10) else {
                throw FickValidationDiagnosticsError.foldFitMismatch(foldID: fold.id)
            }
            replayFitByFoldID[fold.id] = replayFit

            let foldPredictions = predictionsByFold[fold.id] ?? []
            guard foldPredictions.count == testing.count,
                  Set(foldPredictions.map(\.rowID)) == testing else {
                throw FickValidationDiagnosticsError.predictionPopulationMismatch(
                    foldID: fold.id
                )
            }
        }
        guard Set(predictionsByFold.keys) == Set(foldByID.keys),
              Set(predictionRowIDs) == allTestRowIDs else {
            throw FickValidationDiagnosticsError.runScopeMismatch
        }

        for prediction in run.predictions {
            guard let row = rowByID[prediction.rowID] else {
                throw FickValidationDiagnosticsError.missingRow(rowID: prediction.rowID)
            }
            guard abs(row.percentage - prediction.observedPercentage) <= 1e-10 else {
                throw FickValidationDiagnosticsError.observedValueMismatch(rowID: row.id)
            }
            guard abs(row.permeationTime - prediction.timeHours) <= 1e-10 else {
                throw FickValidationDiagnosticsError.timeValueMismatch(rowID: row.id)
            }
            guard prediction.family == family(row),
                  prediction.condition == condition(row) else {
                throw FickValidationDiagnosticsError.rowConditionMismatch(rowID: row.id)
            }
            guard prediction.predictedPercentage.isFinite,
                  prediction.observedPercentage.isFinite,
                  prediction.timeHours.isFinite,
                  prediction.timeHours >= 0,
                  (0...100).contains(prediction.predictedPercentage) else {
                throw FickValidationDiagnosticsError.nonFinitePrediction(rowID: row.id)
            }
            guard let fold = foldByID[prediction.foldID],
                  fold.testRowIDs.contains(row.id),
                  fold.heldOutCondition == prediction.condition else {
                throw FickValidationDiagnosticsError.invalidFold(foldID: prediction.foldID)
            }
        }

        var replayPredictions: [FickValidationPrediction] = []
        replayPredictions.reserveCapacity(run.predictions.count)
        for prediction in run.predictions.sorted(by: predictionComesBefore) {
            guard let row = rowByID[prediction.rowID],
                  let replayFit = replayFitByFoldID[prediction.foldID] else {
                throw FickValidationDiagnosticsError.invalidFold(foldID: prediction.foldID)
            }
            let replayedValue = replayFit.amplitude * FickValidationExperiment.fraction(
                replayFit.rate * row.permeationTime,
                termCount: run.configuration.seriesTermCount
            )
            guard replayedValue.isFinite,
                  close(
                    prediction.predictedPercentage,
                    replayedValue,
                    tolerance: 1e-10
                  ) else {
                throw FickValidationDiagnosticsError.predictionValueMismatch(rowID: row.id)
            }
            replayPredictions.append(FickValidationPrediction(
                rowID: row.id,
                family: family(row),
                condition: condition(row),
                foldID: prediction.foldID,
                timeHours: row.permeationTime,
                observedPercentage: row.percentage,
                predictedPercentage: replayedValue
            ))
        }

        let eligibleFamilies = Set(run.predictions.map(\.family))
        let eligibleConditions = Set(run.predictions.map(\.condition))
        guard eligibleFamilies == expectedEligibleFamilies,
              eligibleConditions == expectedEligibleConditions,
              run.eligibleFamilyCount == eligibleFamilies.count,
              run.eligibleConditionCount == eligibleConditions.count,
              run.eligibleObservationCount == run.predictions.count,
              run.excludedFamilyCount == allFamilies.count - eligibleFamilies.count,
              run.excludedConditionCount == allConditions.count - eligibleConditions.count,
              run.excludedObservationCount == dataset.rows.count - run.predictions.count else {
            throw FickValidationDiagnosticsError.runScopeMismatch
        }

        let stressReplay = try validateStress(
            run.leaveOneFamilyOutStress,
            dataset: dataset,
            rowByID: rowByID,
            configuration: run.configuration
        )

        let comparable = replayPredictions.map(comparablePrediction)
        let recomputedPooled = metric(comparable)
        let recomputedFamilies = makeFamilyMetrics(predictions: comparable)
        let savedFamilyIDs = run.familyMetrics.map(\.family.id)
        guard metricsEqual(run.pooledMetric, recomputedPooled),
              Set(savedFamilyIDs).count == savedFamilyIDs.count,
              run.familyMetrics.count == recomputedFamilies.count else {
            throw FickValidationDiagnosticsError.runMetricMismatch
        }
        let savedByFamily = Dictionary(uniqueKeysWithValues: run.familyMetrics.map {
            ($0.family, $0.metric)
        })
        guard recomputedFamilies.allSatisfy({ item in
            savedByFamily[item.family].map { metricsEqual($0, item.metric) } == true
        }) else {
            throw FickValidationDiagnosticsError.runMetricMismatch
        }
        let recomputedPointPass = recomputedPooled.rSquared.map {
            $0 >= run.configuration.targetRSquared
        } ?? false
        let recomputedConfidenceInterval = try FickValidationExperiment
            .recomputeConfidenceInterval(
                predictions: replayPredictions,
                configuration: run.configuration
            )
        guard confidenceIntervalsEqual(
            run.confidenceInterval,
            recomputedConfidenceInterval
        ) else {
            throw FickValidationDiagnosticsError.confidenceIntervalMismatch
        }
        let recomputedConfidencePass = recomputedPointPass
            && (recomputedConfidenceInterval.oneSidedLower.map {
                $0.isFinite && $0 >= run.configuration.targetRSquared
            } ?? false)
        guard run.pointPass == recomputedPointPass,
              run.confidencePass == recomputedConfidencePass else {
            throw FickValidationDiagnosticsError.runMetricMismatch
        }
        let recomputedWarnings = FickValidationExperiment.makeWarnings(
            dataset: dataset,
            eligibleConditionCount: expectedEligibleConditions.count,
            pooledMetric: recomputedPooled,
            familyMetrics: recomputedFamilies,
            confidenceInterval: recomputedConfidenceInterval,
            primaryBoundaryCount: replayFitByFoldID.values.count {
                $0.amplitude == 100
            },
            primaryFoldCount: replayFitByFoldID.count,
            stressBoundaryCount: stressReplay.boundaryFitCount,
            stressFoldCount: stressReplay.foldCount,
            configuration: run.configuration
        )
        guard run.warnings == recomputedWarnings,
              run.limitations == FickValidationExperiment.makeLimitations() else {
            throw FickValidationDiagnosticsError.runNarrativeMismatch
        }

        return ValidatedReplay(
            primaryPredictions: replayPredictions,
            stressPredictions: stressReplay.predictions
        )
    }

    private static func validateStress(
        _ stress: FickValidationStressResult,
        dataset: TrainingDataset,
        rowByID: [Int: TrainingDataRow],
        configuration: FickValidationConfiguration
    ) throws -> ValidatedStressReplay {
        let allRowIDs = Set(dataset.rows.map(\.id))
        let allFamilies = Set(dataset.rows.map(family))
        let foldFamilyIDs = stress.folds.map { $0.heldOutFamily.id }
        guard Set(foldFamilyIDs).count == foldFamilyIDs.count else {
            let duplicate = Dictionary(grouping: foldFamilyIDs, by: { $0 })
                .first { $0.value.count > 1 }?.key ?? "unknown"
            throw FickValidationDiagnosticsError.duplicateFold(
                foldID: "stress|\(duplicate)"
            )
        }
        let predictionRowIDs = stress.predictions.map(\.rowID)
        guard Set(predictionRowIDs).count == predictionRowIDs.count else {
            let duplicate = Dictionary(grouping: predictionRowIDs, by: { $0 })
                .first { $0.value.count > 1 }?.key ?? -1
            throw FickValidationDiagnosticsError.duplicatePrediction(rowID: duplicate)
        }
        guard Set(stress.folds.map(\.heldOutFamily)) == allFamilies,
              stress.familyCount == allFamilies.count,
              stress.observationCount == stress.predictions.count,
              Set(predictionRowIDs) == allRowIDs else {
            throw FickValidationDiagnosticsError.runScopeMismatch
        }

        let predictionsByFold = Dictionary(grouping: stress.predictions, by: \.foldID)
        var allTestRowIDs = Set<Int>()
        var replayFitByFoldID: [String: FickValidationFittedParameters] = [:]
        for fold in stress.folds.sorted(by: { $0.id < $1.id }) {
            try Task.checkCancellation()
            let foldID = "family-holdout|\(fold.heldOutFamily.id)"
            let training = Set(fold.trainingRowIDs)
            let testing = Set(fold.testRowIDs)
            let expectedTesting = Set(dataset.rows.filter {
                family($0) == fold.heldOutFamily
            }.map(\.id))
            let expectedTraining = allRowIDs.subtracting(expectedTesting)
            let expectedTrainingFamilies = allFamilies.subtracting([fold.heldOutFamily])
                .map(\.id)
            guard training.count == fold.trainingRowIDs.count,
                  testing.count == fold.testRowIDs.count,
                  training.isDisjoint(with: testing),
                  allTestRowIDs.isDisjoint(with: testing),
                  training == expectedTraining,
                  testing == expectedTesting,
                  Set(fold.trainingFamilyIDs) == Set(expectedTrainingFamilies),
                  Set(fold.trainingFamilyIDs).count == fold.trainingFamilyIDs.count else {
                throw FickValidationDiagnosticsError.invalidFold(foldID: foldID)
            }

            let trainingRows = try expectedTraining.sorted().map { rowID in
                guard let row = rowByID[rowID] else {
                    throw FickValidationDiagnosticsError.missingRow(rowID: rowID)
                }
                return row
            }
            let replayFit = try FickValidationExperiment.recomputeFit(
                rows: trainingRows,
                configuration: configuration
            )
            guard close(fold.fittedAmplitude, replayFit.amplitude, tolerance: 1e-10),
                  close(fold.fittedRate, replayFit.rate, tolerance: 1e-10),
                  close(fold.trainingSSE, replayFit.sse, tolerance: 1e-10) else {
                throw FickValidationDiagnosticsError.foldFitMismatch(foldID: foldID)
            }
            replayFitByFoldID[foldID] = replayFit
            allTestRowIDs.formUnion(testing)

            let foldPredictions = predictionsByFold[foldID] ?? []
            guard foldPredictions.count == testing.count,
                  Set(foldPredictions.map(\.rowID)) == testing else {
                throw FickValidationDiagnosticsError.predictionPopulationMismatch(
                    foldID: foldID
                )
            }
        }
        guard Set(predictionsByFold.keys) == Set(stress.folds.map {
            "family-holdout|\($0.heldOutFamily.id)"
        }), allTestRowIDs == allRowIDs else {
            throw FickValidationDiagnosticsError.runScopeMismatch
        }

        for prediction in stress.predictions {
            guard let row = rowByID[prediction.rowID] else {
                throw FickValidationDiagnosticsError.missingRow(rowID: prediction.rowID)
            }
            guard abs(row.percentage - prediction.observedPercentage) <= 1e-10 else {
                throw FickValidationDiagnosticsError.observedValueMismatch(rowID: row.id)
            }
            guard abs(row.permeationTime - prediction.timeHours) <= 1e-10 else {
                throw FickValidationDiagnosticsError.timeValueMismatch(rowID: row.id)
            }
            guard prediction.family == family(row),
                  prediction.condition == condition(row) else {
                throw FickValidationDiagnosticsError.rowConditionMismatch(rowID: row.id)
            }
            guard prediction.foldID == "family-holdout|\(prediction.family.id)",
                  prediction.predictedPercentage.isFinite,
                  prediction.observedPercentage.isFinite,
                  prediction.timeHours.isFinite,
                  prediction.timeHours >= 0,
                  (0...100).contains(prediction.predictedPercentage) else {
                throw FickValidationDiagnosticsError.nonFinitePrediction(rowID: row.id)
            }
        }

        var replayPredictions: [FickValidationPrediction] = []
        replayPredictions.reserveCapacity(stress.predictions.count)
        for prediction in stress.predictions.sorted(by: predictionComesBefore) {
            guard let row = rowByID[prediction.rowID],
                  let replayFit = replayFitByFoldID[prediction.foldID] else {
                throw FickValidationDiagnosticsError.invalidFold(foldID: prediction.foldID)
            }
            let replayedValue = replayFit.amplitude * FickValidationExperiment.fraction(
                replayFit.rate * row.permeationTime,
                termCount: configuration.seriesTermCount
            )
            guard replayedValue.isFinite,
                  close(
                    prediction.predictedPercentage,
                    replayedValue,
                    tolerance: 1e-10
                  ) else {
                throw FickValidationDiagnosticsError.predictionValueMismatch(rowID: row.id)
            }
            replayPredictions.append(FickValidationPrediction(
                rowID: row.id,
                family: family(row),
                condition: condition(row),
                foldID: prediction.foldID,
                timeHours: row.permeationTime,
                observedPercentage: row.percentage,
                predictedPercentage: replayedValue
            ))
        }

        let recomputed = metric(replayPredictions.map(comparablePrediction))
        guard metricsEqual(stress.metric, recomputed) else {
            throw FickValidationDiagnosticsError.runMetricMismatch
        }
        return ValidatedStressReplay(
            predictions: replayPredictions,
            boundaryFitCount: replayFitByFoldID.values.count { $0.amplitude == 100 },
            foldCount: replayFitByFoldID.count
        )
    }

    private static func finiteValuesRequiringAll(
        _ values: [Double?]
    ) -> [Double]? {
        guard !values.isEmpty else { return nil }
        var result: [Double] = []
        result.reserveCapacity(values.count)
        for value in values {
            guard let value, value.isFinite else { return nil }
            result.append(value)
        }
        return result
    }

    /// Used by the macro-family policy and directly unit-tested so a family
    /// with undefined R² can never be silently omitted from an average.
    static func meanRequiringAllFinite(_ values: [Double?]) -> Double? {
        guard let finite = finiteValuesRequiringAll(values), !finite.isEmpty else {
            return nil
        }
        return finite.reduce(0.0, +) / Double(finite.count)
    }

    /// This comparator was added during exploratory audit and has no sealed,
    /// preregistered improvement margin. It may show that Fick is worse, but it
    /// can never confirm incremental performance. Equal or better values remain
    /// unavailable until a future protocol binds positive margins in advance.
    static func exploratoryBaselineStatus(
        rSquaredDeltas: [Double?],
        fickRMSE: Double,
        controlRMSE: Double,
        fickMAE: Double,
        controlMAE: Double
    ) -> FickValidationGateStatus {
        guard let deltas = finiteValuesRequiringAll(rSquaredDeltas),
              deltas.count == 4,
              fickRMSE.isFinite,
              controlRMSE.isFinite,
              fickMAE.isFinite,
              controlMAE.isFinite else {
            return .unavailable
        }
        let tolerance = 1e-12
        if deltas.contains(where: { $0 < -tolerance })
            || fickRMSE > controlRMSE + tolerance
            || fickMAE > controlMAE + tolerance {
            return .notMet
        }
        return .unavailable
    }

    private static func predictionComesBefore(
        _ lhs: FickValidationPrediction,
        _ rhs: FickValidationPrediction
    ) -> Bool {
        lhs.rowID == rhs.rowID ? lhs.foldID < rhs.foldID : lhs.rowID < rhs.rowID
    }

    private static func confidenceIntervalsEqual(
        _ lhs: FickValidationConfidenceInterval,
        _ rhs: FickValidationConfidenceInterval
    ) -> Bool {
        lhs.validReplicateCount == rhs.validReplicateCount
            && lhs.requestedReplicateCount == rhs.requestedReplicateCount
            && lhs.clusterCount == rhs.clusterCount
            && optionalDoublesEqual(lhs.twoSidedLower, rhs.twoSidedLower)
            && optionalDoublesEqual(lhs.twoSidedUpper, rhs.twoSidedUpper)
            && optionalDoublesEqual(lhs.oneSidedLower, rhs.oneSidedLower)
            && optionalDoublesEqual(
                lhs.probabilityAtOrAboveTarget,
                rhs.probabilityAtOrAboveTarget
            )
    }

    private static func optionalDoublesEqual(
        _ lhs: Double?,
        _ rhs: Double?
    ) -> Bool {
        switch (lhs, rhs) {
        case (nil, nil):
            return true
        case let (lhs?, rhs?):
            return lhs.isFinite && rhs.isFinite
                && close(lhs, rhs, tolerance: 1e-12)
        default:
            return false
        }
    }

    private static func metricsEqual(
        _ lhs: FickValidationMetric,
        _ rhs: FickValidationMetric,
        tolerance: Double = 1e-9
    ) -> Bool {
        guard lhs.observationCount == rhs.observationCount,
              lhs.rmse.isFinite,
              lhs.mae.isFinite,
              rhs.rmse.isFinite,
              rhs.mae.isFinite,
              close(lhs.rmse, rhs.rmse, tolerance: tolerance),
              close(lhs.mae, rhs.mae, tolerance: tolerance) else {
            return false
        }
        switch (lhs.rSquared, rhs.rSquared) {
        case (nil, nil):
            return true
        case let (lhs?, rhs?):
            return lhs.isFinite && rhs.isFinite
                && close(lhs, rhs, tolerance: tolerance)
        default:
            return false
        }
    }

    private static func close(
        _ lhs: Double,
        _ rhs: Double,
        tolerance: Double
    ) -> Bool {
        abs(lhs - rhs) <= tolerance * max(1, max(abs(lhs), abs(rhs)))
    }

    private static func comparablePrediction(
        _ prediction: FickValidationPrediction
    ) -> ComparablePrediction {
        ComparablePrediction(
            rowID: prediction.rowID,
            family: prediction.family,
            condition: prediction.condition,
            foldID: prediction.foldID,
            observed: prediction.observedPercentage,
            predicted: prediction.predictedPercentage
        )
    }

    private static func makeBaselinePredictions(
        dataset: TrainingDataset,
        folds: [FickValidationFold]
    ) -> [FickValidationBaselinePrediction] {
        let rowByID = Dictionary(uniqueKeysWithValues: dataset.rows.map { ($0.id, $0) })
        var result: [FickValidationBaselinePrediction] = []
        for fold in folds {
            let training = fold.trainingRowIDs.sorted().compactMap { rowByID[$0] }
            let groupedByTime = Dictionary(grouping: training, by: \.permeationTime)
            let curve = groupedByTime.map { time, rows in
                (
                    time: time,
                    value: rows.reduce(0.0) { $0 + $1.percentage } / Double(rows.count)
                )
            }.sorted { $0.time < $1.time }
            guard !curve.isEmpty else { continue }

            for rowID in fold.testRowIDs.sorted() {
                guard let row = rowByID[rowID] else { continue }
                let estimate = interpolate(time: row.permeationTime, curve: curve)
                result.append(FickValidationBaselinePrediction(
                    rowID: row.id,
                    family: fold.heldOutCondition.family,
                    condition: fold.heldOutCondition,
                    foldID: fold.id,
                    timeHours: row.permeationTime,
                    observedPercentage: row.percentage,
                    predictedPercentage: estimate.value,
                    mode: estimate.mode
                ))
            }
        }
        return result.sorted {
            $0.rowID == $1.rowID ? $0.foldID < $1.foldID : $0.rowID < $1.rowID
        }
    }

    private static func interpolate(
        time: Double,
        curve: [(time: Double, value: Double)]
    ) -> (value: Double, mode: FickValidationBaselinePredictionMode) {
        if let exact = curve.first(where: { $0.time == time }) {
            return (exact.value, .exactTrainingTime)
        }
        guard let first = curve.first, let last = curve.last else {
            return (0, .endpointHold)
        }
        if time < first.time { return (first.value, .endpointHold) }
        if time > last.time { return (last.value, .endpointHold) }

        for index in 1..<curve.count where curve[index].time > time {
            let lower = curve[index - 1]
            let upper = curve[index]
            let weight = (time - lower.time) / (upper.time - lower.time)
            return (
                lower.value + weight * (upper.value - lower.value),
                .linearInterpolation
            )
        }
        return (last.value, .endpointHold)
    }

    private static func summarize(
        _ comparator: FickValidationComparator,
        predictions: [ComparablePrediction]
    ) -> FickValidationComparatorSummary {
        let conditionGroups = Dictionary(grouping: predictions, by: \.foldID)
        let familyGroups = Dictionary(grouping: predictions, by: { $0.family.id })
        let squaredError = predictions.reduce(0.0) {
            let residual = $1.observed - $1.predicted
            return $0 + residual * residual
        }
        let orderedFamilyValues = familyGroups.keys.sorted().compactMap {
            familyGroups[$0]
        }
        let withinFamilyTSS = orderedFamilyValues.reduce(0.0) { partial, values in
            let mean = values.reduce(0.0) { $0 + $1.observed } / Double(values.count)
            return partial + values.reduce(0.0) {
                let centered = $1.observed - mean
                return $0 + centered * centered
            }
        }
        let familyCentered = withinFamilyTSS > 1e-20
            ? 1 - squaredError / withinFamilyTSS : nil
        let macro = meanRequiringAllFinite(
            orderedFamilyValues.map { metric($0).rSquared }
        )

        return FickValidationComparatorSummary(
            comparator: comparator,
            rowPooledMetric: metric(predictions),
            conditionBalancedMetric: conditionBalancedMetric(conditionGroups),
            familyCenteredRSquared: familyCentered,
            macroFamilyRSquared: macro,
            conditionCount: conditionGroups.count,
            familyCount: familyGroups.count,
            calibration: calibration(predictions)
        )
    }

    private static func makeFamilyMetrics(
        predictions: [ComparablePrediction]
    ) -> [FickValidationFamilyMetric] {
        Dictionary(grouping: predictions, by: \.family).map { family, values in
            FickValidationFamilyMetric(
                family: family,
                metric: metric(values)
            )
        }.sorted { $0.family.id < $1.family.id }
    }

    private static func conditionBalancedMetric(
        _ groups: [String: [ComparablePrediction]]
    ) -> FickValidationMetric {
        guard !groups.isEmpty else {
            return FickValidationMetric(rSquared: nil, rmse: 0, mae: 0, observationCount: 0)
        }
        let orderedValues = groups.keys.sorted().compactMap { groups[$0] }
        let observedMeans = orderedValues.map {
            $0.reduce(0.0) { $0 + $1.observed } / Double($0.count)
        }
        let weightedMean = observedMeans.reduce(0, +) / Double(observedMeans.count)
        var sse = 0.0
        var tss = 0.0
        var absoluteError = 0.0
        for values in orderedValues {
            let count = Double(values.count)
            sse += values.reduce(0.0) {
                let residual = $1.observed - $1.predicted
                return $0 + residual * residual
            } / count
            tss += values.reduce(0.0) {
                let centered = $1.observed - weightedMean
                return $0 + centered * centered
            } / count
            absoluteError += values.reduce(0.0) {
                $0 + abs($1.observed - $1.predicted)
            } / count
        }
        return FickValidationMetric(
            rSquared: tss > 1e-20 ? 1 - sse / tss : nil,
            rmse: Foundation.sqrt(sse / Double(groups.count)),
            mae: absoluteError / Double(groups.count),
            observationCount: orderedValues.reduce(0) { $0 + $1.count }
        )
    }

    private static func metric(_ predictions: [ComparablePrediction]) -> FickValidationMetric {
        guard !predictions.isEmpty else {
            return FickValidationMetric(rSquared: nil, rmse: 0, mae: 0, observationCount: 0)
        }
        let mean = predictions.reduce(0.0) { $0 + $1.observed } / Double(predictions.count)
        var sse = 0.0
        var tss = 0.0
        var absoluteError = 0.0
        for prediction in predictions {
            let residual = prediction.observed - prediction.predicted
            sse += residual * residual
            absoluteError += abs(residual)
            let centered = prediction.observed - mean
            tss += centered * centered
        }
        return FickValidationMetric(
            rSquared: tss > 1e-20 ? 1 - sse / tss : nil,
            rmse: Foundation.sqrt(sse / Double(predictions.count)),
            mae: absoluteError / Double(predictions.count),
            observationCount: predictions.count
        )
    }

    private static func calibration(
        _ predictions: [ComparablePrediction]
    ) -> FickValidationCalibrationAudit {
        guard !predictions.isEmpty else {
            return FickValidationCalibrationAudit(
                intercept: nil,
                slope: nil,
                meanErrorPercentagePoints: 0
            )
        }
        let meanPredicted = predictions.reduce(0.0) { $0 + $1.predicted }
            / Double(predictions.count)
        let meanObserved = predictions.reduce(0.0) { $0 + $1.observed }
            / Double(predictions.count)
        let covariance = predictions.reduce(0.0) {
            $0 + ($1.predicted - meanPredicted) * ($1.observed - meanObserved)
        }
        let predictedSS = predictions.reduce(0.0) {
            let centered = $1.predicted - meanPredicted
            return $0 + centered * centered
        }
        let slope = predictedSS > 1e-20 ? covariance / predictedSS : nil
        let intercept = slope.map { meanObserved - $0 * meanPredicted }
        let meanError = predictions.reduce(0.0) {
            $0 + ($1.predicted - $1.observed)
        } / Double(predictions.count)
        return FickValidationCalibrationAudit(
            intercept: intercept,
            slope: slope,
            meanErrorPercentagePoints: meanError
        )
    }

    private static func makeTSSAudit(
        predictions: [ComparablePrediction]
    ) -> FickValidationTSSAudit {
        guard !predictions.isEmpty else {
            return FickValidationTSSAudit(
                globalTSS: 0,
                withinFamilyTSS: 0,
                betweenFamilyTSS: 0,
                betweenFamilyShare: nil
            )
        }
        let globalMean = predictions.reduce(0.0) { $0 + $1.observed }
            / Double(predictions.count)
        let global = predictions.reduce(0.0) {
            let centered = $1.observed - globalMean
            return $0 + centered * centered
        }
        let groups = Dictionary(grouping: predictions, by: { $0.family.id })
        let within = groups.keys.sorted().compactMap { groups[$0] }
            .reduce(0.0) { partial, values in
            let mean = values.reduce(0.0) { $0 + $1.observed } / Double(values.count)
            return partial + values.reduce(0.0) {
                let centered = $1.observed - mean
                return $0 + centered * centered
            }
            }
        let between = max(0, global - within)
        return FickValidationTSSAudit(
            globalTSS: global,
            withinFamilyTSS: within,
            betweenFamilyTSS: between,
            betweenFamilyShare: global > 1e-20 ? between / global : nil
        )
    }

    private static func makeConditionAudits(
        fick: [ComparablePrediction],
        baseline: [FickValidationBaselinePrediction],
        targetRSquared: Double
    ) -> [FickValidationConditionAudit] {
        let fickGroups = Dictionary(grouping: fick, by: \.foldID)
        let baselineGroups = Dictionary(grouping: baseline, by: \.foldID)
        return fickGroups.keys.sorted().compactMap { foldID in
            guard let fickValues = fickGroups[foldID],
                  let first = fickValues.first else { return nil }
            let baselineValues = baselineGroups[foldID] ?? []
            let baselineComparable = baselineValues.map {
                ComparablePrediction(
                    rowID: $0.rowID,
                    family: $0.family,
                    condition: $0.condition,
                    foldID: $0.foldID,
                    observed: $0.observedPercentage,
                    predicted: $0.predictedPercentage
                )
            }
            let fickMetric = metric(fickValues)
            let controlMetric = metric(baselineComparable)
            return FickValidationConditionAudit(
                condition: first.condition,
                observationCount: fickValues.count,
                fickMetric: fickMetric,
                controlMetric: controlMetric,
                controlExactTimeCount: baselineValues.count {
                    $0.mode == .exactTrainingTime
                },
                controlInterpolationCount: baselineValues.count {
                    $0.mode == .linearInterpolation
                },
                controlEndpointHoldCount: baselineValues.count {
                    $0.mode == .endpointHold
                },
                fickWinsRMSE: fickMetric.rmse < controlMetric.rmse,
                fickRSquaredMeetsTarget: fickMetric.rSquared.map {
                    $0 >= targetRSquared
                }
            )
        }.sorted {
            if $0.condition.family.id != $1.condition.family.id {
                return $0.condition.family.id < $1.condition.family.id
            }
            return $0.condition.id < $1.condition.id
        }
    }

    private static func makeConditionInfluence(
        predictions: [ComparablePrediction]
    ) -> [FickValidationConditionInfluence] {
        Dictionary(grouping: predictions, by: \.condition).map { condition, values in
            FickValidationConditionInfluence(
                condition: condition,
                excludedObservationCount: values.count,
                rowPooledRSquaredWithoutCondition: metric(
                    predictions.filter { $0.condition != condition }
                ).rSquared
            )
        }.sorted { $0.condition.id < $1.condition.id }
    }

    private static func makeFamilyInfluence(
        predictions: [ComparablePrediction]
    ) -> [FickValidationFamilyInfluence] {
        Dictionary(grouping: predictions, by: \.family).map { family, values in
            FickValidationFamilyInfluence(
                family: family,
                excludedObservationCount: values.count,
                rowPooledRSquaredWithoutFamily: metric(
                    predictions.filter { $0.family != family }
                ).rSquared
            )
        }.sorted { $0.family.id < $1.family.id }
    }

    private static func makeHierarchyAudit(
        dataset: TrainingDataset,
        eligiblePredictions: [FickValidationPrediction]
    ) -> FickValidationHierarchyAudit {
        let canonical = ExperimentDatasetIdentity.identity(for: dataset)
            .isCanonicalPaperDataset
        let orderedRows = dataset.rows.sorted { $0.id < $1.id }
        let rawReferencedRowCount = orderedRows.count {
            !$0.reference.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        let resolvedRows: [ResolvedSourceRow]
        if canonical {
            var activeSourceID: String?
            var activeCitation: String?
            var sourceIndex = 0
            resolvedRows = orderedRows.map { row in
                let citation = row.reference.trimmingCharacters(in: .whitespacesAndNewlines)
                if !citation.isEmpty {
                    sourceIndex += 1
                    activeSourceID = "source-block-\(sourceIndex)"
                    activeCitation = citation
                }
                return ResolvedSourceRow(
                    rowID: row.id,
                    sourceID: activeSourceID,
                    citation: activeCitation,
                    familyID: familyID(row)
                )
            }
        } else {
            let citations = Array(Set(orderedRows.map {
                $0.reference.trimmingCharacters(in: .whitespacesAndNewlines)
            }.filter { !$0.isEmpty })).sorted()
            let citationIDs = Dictionary(uniqueKeysWithValues: citations.enumerated().map {
                ($1, "source-citation-\($0 + 1)")
            })
            resolvedRows = orderedRows.map { row in
                let citation = row.reference.trimmingCharacters(in: .whitespacesAndNewlines)
                return ResolvedSourceRow(
                    rowID: row.id,
                    sourceID: citationIDs[citation],
                    citation: citation.isEmpty ? nil : citation,
                    familyID: familyID(row)
                )
            }
        }

        let grouped = Dictionary(grouping: resolvedRows.compactMap { row -> ResolvedSourceRow? in
            row.sourceID == nil ? nil : row
        }, by: { $0.sourceID! })
        let sourceBlocks = grouped.keys.sorted().compactMap { sourceID -> FickValidationSourceBlockAudit? in
            guard let rows = grouped[sourceID], let citation = rows.first?.citation else {
                return nil
            }
            return FickValidationSourceBlockAudit(
                id: sourceID,
                citation: citation,
                rowIDs: rows.map(\.rowID).sorted(),
                familyIDs: Array(Set(rows.map(\.familyID))).sorted()
            )
        }
        let eligibleRowIDs = Set(eligiblePredictions.map(\.rowID))
        let eligibleRows = resolvedRows.filter { eligibleRowIDs.contains($0.rowID) }
        let familyToSources = Dictionary(grouping: eligibleRows, by: \.familyID)
            .mapValues { Set($0.compactMap(\.sourceID)) }
        let sourceToFamilies = Dictionary(
            grouping: eligibleRows.compactMap { row -> (String, String)? in
                guard let sourceID = row.sourceID else { return nil }
                return (sourceID, row.familyID)
            },
            by: { $0.0 }
        ).mapValues { Set($0.map { $0.1 }) }
        let confounded = familyToSources.count { entry in
            let (familyID, sourceIDs) = entry
            guard sourceIDs.count == 1, let sourceID = sourceIDs.first else { return false }
            return sourceToFamilies[sourceID] == Set([familyID])
        }

        return FickValidationHierarchyAudit(
            canonicalMergedCellForwardFillApplied: canonical,
            rawReferencedRowCount: rawReferencedRowCount,
            resolvedSourceRowCount: resolvedRows.count { $0.sourceID != nil },
            totalRowCount: orderedRows.count,
            sourceBlockCount: sourceBlocks.count,
            uniqueCitationCount: Set(sourceBlocks.map(\.citation)).count,
            eligibleSourceCount: Set(eligibleRows.compactMap(\.sourceID)).count,
            eligibleFamilySourceConfoundedCount: confounded,
            sourceBlocks: sourceBlocks,
            hasExperimentRunID: false,
            hasPermeationCurveID: false,
            hasDonorID: false,
            hasBatchID: false,
            hasSiteID: false
        )
    }

    private static func family(_ row: TrainingDataRow) -> FickValidationFamily {
        FickValidationFamily(
            drugName: row.sourceDrugName,
            skinCode: row.skin.sourceCode,
            needleTypeCode: row.needle.sourceCode
        )
    }

    private static func condition(_ row: TrainingDataRow) -> FickValidationCondition {
        FickValidationCondition(
            family: family(row),
            loading: row.loading,
            molecularWeight: row.molecularWeight,
            needleLength: row.needleLength,
            surfaceArea: row.surfaceArea
        )
    }

    private static func familyID(_ row: TrainingDataRow) -> String {
        family(row).id
    }
}
