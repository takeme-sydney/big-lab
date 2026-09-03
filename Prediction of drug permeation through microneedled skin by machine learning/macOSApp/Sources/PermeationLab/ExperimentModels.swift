import CryptoKit
import Foundation

/// The two response variables published in Data S1.
enum ExperimentOutcome: String, CaseIterable, Codable, Identifiable, Sendable {
    case amount
    case percentage

    var id: Self { self }

    var unit: String {
        switch self {
        case .amount: "µg/cm²"
        case .percentage: "%"
        }
    }

    func value(in row: TrainingDataRow) -> Double {
        switch self {
        case .amount: row.amount
        case .percentage: row.percentage
        }
    }
}

enum ExperimentValidationStrategy: String, CaseIterable, Codable, Identifiable, Sendable {
    case publishedStyleRowSplit
    case leaveOneDrugOut

    var id: Self { self }
}

/// The exact seven numeric fields supplied to every reconstructed statistical model.
enum ExperimentPredictor: String, CaseIterable, Codable, Identifiable, Sendable {
    case drugLoading
    case molecularWeight
    case needleLength
    case skinCode
    case needleTypeCode
    case surfaceArea
    case permeationTime

    var id: Self { self }

    var sourceColumn: String {
        switch self {
        case .drugLoading: TrainingDataSource.expectedHeader[1]
        case .molecularWeight: TrainingDataSource.expectedHeader[2]
        case .needleLength: TrainingDataSource.expectedHeader[3]
        case .skinCode: TrainingDataSource.expectedHeader[4]
        case .needleTypeCode: TrainingDataSource.expectedHeader[5]
        case .surfaceArea: TrainingDataSource.expectedHeader[6]
        case .permeationTime: TrainingDataSource.expectedHeader[7]
        }
    }

    func value(in row: TrainingDataRow) -> Double {
        switch self {
        case .drugLoading: row.loading
        case .molecularWeight: row.molecularWeight
        case .needleLength: row.needleLength
        case .skinCode: Double(row.skin.sourceCode)
        case .needleTypeCode: Double(row.needle.sourceCode)
        case .surfaceArea: row.surfaceArea
        case .permeationTime: row.permeationTime
        }
    }
}

enum ExperimentModelKind: String, CaseIterable, Codable, Identifiable, Sendable {
    case multipleLinearRegression
    case randomForest
    case nativeGradientTreeBoosting

    var id: Self { self }

    /// This label is deliberately distinct from XGBoost. The shipped app does not
    /// contain the paper's R/XGBoost runtime or its unpublished fitted booster.
    var engineLabel: String {
        switch self {
        case .multipleLinearRegression: "Native no-intercept OLS"
        case .randomForest: "Native seeded Random Forest reconstruction"
        case .nativeGradientTreeBoosting: "Native gradient-tree boosting reconstruction (not XGBoost)"
        }
    }
}

struct ExperimentConfiguration: Equatable, Codable, Sendable {
    var outcome: ExperimentOutcome
    var validationStrategy: ExperimentValidationStrategy
    var seed: UInt64
    var heldOutDrug: Drug?

    init(
        outcome: ExperimentOutcome = .amount,
        validationStrategy: ExperimentValidationStrategy = .publishedStyleRowSplit,
        seed: UInt64 = 0,
        heldOutDrug: Drug? = .lidocaine
    ) {
        self.outcome = outcome
        self.validationStrategy = validationStrategy
        self.seed = seed
        self.heldOutDrug = heldOutDrug
    }

    var preset: ExperimentHyperparameters {
        ExperimentHyperparameters(outcome: outcome)
    }

    private enum CodingKeys: String, CodingKey {
        case outcome
        case validationStrategy
        case seed
        case heldOutDrug
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        outcome = try container.decode(ExperimentOutcome.self, forKey: .outcome)
        validationStrategy = try container.decode(ExperimentValidationStrategy.self, forKey: .validationStrategy)
        seed = try container.decode(UInt64.self, forKey: .seed)
        if let sourceName = try container.decodeIfPresent(String.self, forKey: .heldOutDrug) {
            guard let decodedDrug = Drug(sourceName: sourceName) else {
                throw DecodingError.dataCorruptedError(
                    forKey: .heldOutDrug,
                    in: container,
                    debugDescription: "Unknown held-out drug source name: \(sourceName)"
                )
            }
            heldOutDrug = decodedDrug
        } else {
            heldOutDrug = nil
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(outcome, forKey: .outcome)
        try container.encode(validationStrategy, forKey: .validationStrategy)
        try container.encode(seed, forKey: .seed)
        try container.encodeIfPresent(heldOutDrug?.sourceName, forKey: .heldOutDrug)
    }
}

struct ExperimentHyperparameters: Equatable, Codable, Sendable {
    let predictorCount: Int
    let mlrIncludesIntercept: Bool
    let randomForestTrees: Int
    let randomForestMtry: Int
    let randomForestMaximumDepth: Int
    let randomForestMinimumNodeSize: Int
    let boostingMaxDepth: Int
    let boostingLearningRate: Double
    let boostingRounds: Int
    let boostingEngine: String

    init(outcome: ExperimentOutcome) {
        predictorCount = ExperimentPredictor.allCases.count
        mlrIncludesIntercept = false
        randomForestTrees = 500
        randomForestMtry = outcome == .amount ? 5 : 6
        randomForestMaximumDepth = 32
        randomForestMinimumNodeSize = 5
        boostingMaxDepth = outcome == .amount ? 4 : 3
        boostingLearningRate = outcome == .amount ? 0.4 : 0.2
        boostingRounds = outcome == .amount ? 100 : 45
        boostingEngine = ExperimentModelKind.nativeGradientTreeBoosting.engineLabel
    }
}

struct ExperimentDatasetSnapshot: Identifiable, Equatable, Codable, Sendable {
    let displayName: String
    let isBundledSource: Bool
    /// Optional for backwards-compatible decoding of run-history v1 records.
    let researchMode: ResearchMode?
    /// Syntactic/schema validation is recorded separately from this scientific status.
    let scientificStatus: ScientificDataStatus?
    let importedAt: Date?
    let rowCount: Int
    let columnCount: Int
    let schemaIsValid: Bool
    let auditErrorCount: Int
    let sha256: String
    let normalizedSHA256: String
    let sha256Basis: ExperimentDatasetHashBasis
    let isCanonicalPaperDataset: Bool
    let predictorFields: [String]

    var id: String { sha256 }

    var resolvedResearchMode: ResearchMode {
        researchMode ?? (isBundledSource ? .paperEvidence : .myExperiment)
    }

    var resolvedScientificStatus: ScientificDataStatus {
        scientificStatus ?? (isBundledSource ? .paperSourceVerified : .legacyUnspecified)
    }

    static func make(
        dataset: TrainingDataset,
        displayName: String,
        isBundledData: Bool = false,
        researchMode: ResearchMode? = nil,
        scientificStatus: ScientificDataStatus? = nil,
        importedAt: Date? = nil
    ) -> Self {
        let identity = ExperimentDatasetIdentity.identity(for: dataset)
        let hasBundledRawBytes = isBundledData && identity.isCanonicalPaperDataset
        let resolvedMode = researchMode ?? (isBundledData ? .paperEvidence : .myExperiment)
        let resolvedStatus = scientificStatus ?? (
            isBundledData ? .paperSourceVerified : .userProvidedUnvalidated
        )
        return Self(
            displayName: displayName,
            isBundledSource: isBundledData,
            researchMode: resolvedMode,
            scientificStatus: resolvedStatus,
            importedAt: importedAt,
            rowCount: dataset.rows.count,
            columnCount: dataset.audit.columnCount,
            schemaIsValid: dataset.audit.isValid && !dataset.rows.isEmpty,
            auditErrorCount: dataset.audit.parseErrors.count,
            sha256: hasBundledRawBytes ? identity.sha256 : identity.normalizedSHA256,
            normalizedSHA256: identity.normalizedSHA256,
            sha256Basis: hasBundledRawBytes ? .bundledRawCSVBytes : .normalizedParsedValues,
            isCanonicalPaperDataset: identity.isCanonicalPaperDataset,
            predictorFields: ExperimentPredictor.allCases.map(\.sourceColumn)
        )
    }
}

enum ExperimentDatasetHashBasis: String, Equatable, Codable, Sendable {
    case bundledRawCSVBytes = "bundled raw CSV bytes"
    case normalizedParsedValues = "normalized parsed values"
}

enum ExperimentEvidenceLevel: String, Codable, Sendable {
    case publishedProtocolReconstruction = "published-protocol reconstruction"
    case generalizationValidation = "leave-one-drug-out generalization validation"
    case compatibleDatasetExperiment = "compatible-dataset experiment"
    case paperDataProtocolVariation = "paper-data protocol variation"
    /// Retained so existing local history remains decodable. New runs never emit
    /// this as an evidence level; exact-replay availability is a separate state.
    case exactPaperReplayUnavailable = "exact-paper replay unavailable"
}

enum ExperimentTable4ReferenceStatus: String, Codable, Sendable {
    case eligibleReportedReference
    case unavailableOutsidePaperEvidence
    case unavailableNoncanonicalSource
    case unavailableProtocolVariation
}

struct ExperimentMessage: Equatable, Codable, Sendable {
    let code: String
    let japanese: String
    let english: String

    init(code: String, japanese: String, english: String) {
        self.code = code
        self.japanese = japanese
        self.english = english
    }

    func resolve(_ language: AppLanguage) -> String {
        language.text(japanese, english)
    }
}

struct ExperimentSplit: Equatable, Codable, Sendable {
    let trainRowIDs: [Int]
    let testRowIDs: [Int]
    let trainDrugCounts: [String: Int]
    let testDrugCounts: [String: Int]

    var trainingCount: Int { trainRowIDs.count }
    var testCount: Int { testRowIDs.count }
}

struct ExperimentLeakageAudit: Equatable, Codable, Sendable {
    /// Number of unique seven-predictor combinations present in both partitions.
    let sharedPredictorCombinationCount: Int
    let trainingRowsInSharedConditions: Int
    let testRowsInSharedConditions: Int
    let heldOutDrugTrainingCount: Int?
    let heldOutDrugTestCount: Int?

    var hasCrossPartitionConditionOverlap: Bool {
        sharedPredictorCombinationCount > 0
    }

    var heldOutDrugIsIsolated: Bool? {
        heldOutDrugTrainingCount.map { $0 == 0 }
    }
}

struct ExperimentMetric: Identifiable, Equatable, Codable, Sendable {
    let model: ExperimentModelKind
    let rmse: Double
    /// sqrt(SSE), retained as a clearly named audit diagnostic because the
    /// paper's Table 4 values may have used this quantity while labelling RMSE.
    let rootSumSquaredError: Double
    let mae: Double
    /// Nil when the test target has zero variance; JSON encodes this as `null`
    /// instead of conflating an undefined statistic with a valid value of zero.
    let rSquared: Double?
    let observationCount: Int

    var id: ExperimentModelKind { model }
}

struct ExperimentPrediction: Identifiable, Equatable, Codable, Sendable {
    let rowID: Int
    let drugName: String
    let model: ExperimentModelKind
    let observed: Double
    let predicted: Double

    var residual: Double { observed - predicted }
    var id: String { "\(model.rawValue)|\(rowID)" }
}

struct ExperimentRunResult: Identifiable, Equatable, Codable, Sendable {
    static let schemaVersion = "2.0"

    let id: UUID
    let startedAt: Date
    let completedAt: Date
    let elapsedSeconds: Double
    let engineVersion: String
    let evidenceLevel: ExperimentEvidenceLevel
    let dataset: ExperimentDatasetSnapshot
    let configuration: ExperimentConfiguration
    let hyperparameters: ExperimentHyperparameters
    let split: ExperimentSplit
    let leakageAudit: ExperimentLeakageAudit
    let metrics: [ExperimentMetric]
    let predictions: [ExperimentPrediction]
    let warnings: [ExperimentMessage]
    let limitations: [ExperimentMessage]

    var schemaVersion: String { Self.schemaVersion }

    func metric(for model: ExperimentModelKind) -> ExperimentMetric? {
        metrics.first { $0.model == model }
    }

    func predictions(for model: ExperimentModelKind) -> [ExperimentPrediction] {
        predictions.filter { $0.model == model }
    }

    var table4ReferenceStatus: ExperimentTable4ReferenceStatus {
        ExperimentEvidencePolicy.table4ReferenceStatus(
            dataset: dataset,
            configuration: configuration,
            split: split,
            hyperparameters: hyperparameters
        )
    }

    var isTable4ReferenceComparisonEligible: Bool {
        table4ReferenceStatus == .eligibleReportedReference
    }

    /// Eligibility belongs to the saved run, while visibility also belongs to
    /// the active workspace. A paper run restored in My Experiment keeps its
    /// provenance but must not expose paper comparison columns there.
    func canDisplayTable4Reference(in activeMode: ResearchMode) -> Bool {
        activeMode == .paperEvidence && isTable4ReferenceComparisonEligible
    }

    /// The fitted paper artifacts and original row assignment were not published.
    var exactPaperReplayAvailable: Bool { false }

    /// Re-evaluate saved/legacy evidence with the current policy. This prevents an
    /// old or inconsistent stored label from promoting a personal run.
    var policyEvidenceLevel: ExperimentEvidenceLevel {
        ExperimentEvidencePolicy.evidenceLevel(
            dataset: dataset,
            configuration: configuration,
            split: split,
            hyperparameters: hyperparameters
        )
    }
}

enum ExperimentEvidencePolicy {
    private static let canonicalSeedZeroTestRowIDs: Set<Int> = [
        4, 16, 17, 19, 20, 23, 25, 28, 31, 33, 36, 41, 47, 48, 53, 60, 62, 64, 68,
        71, 72, 78, 80, 81, 82, 86, 89, 93, 97, 101, 106, 107, 112, 117, 118, 119,
        120, 122, 124, 128, 133, 144, 145, 154, 157, 158, 163, 164, 170, 173, 177,
        178, 182, 185, 186, 188, 190,
    ]

    static func evidenceLevel(
        dataset: ExperimentDatasetSnapshot,
        configuration: ExperimentConfiguration,
        split: ExperimentSplit,
        hyperparameters: ExperimentHyperparameters
    ) -> ExperimentEvidenceLevel {
        if table4ReferenceStatus(
            dataset: dataset,
            configuration: configuration,
            split: split,
            hyperparameters: hyperparameters
        ) == .eligibleReportedReference {
            return .publishedProtocolReconstruction
        }
        if configuration.validationStrategy == .leaveOneDrugOut {
            return .generalizationValidation
        }
        if dataset.resolvedResearchMode == .myExperiment {
            return .compatibleDatasetExperiment
        }
        return .paperDataProtocolVariation
    }

    static func table4ReferenceStatus(
        dataset: ExperimentDatasetSnapshot,
        configuration: ExperimentConfiguration,
        split: ExperimentSplit,
        hyperparameters: ExperimentHyperparameters
    ) -> ExperimentTable4ReferenceStatus {
        guard dataset.resolvedResearchMode == .paperEvidence else {
            return .unavailableOutsidePaperEvidence
        }
        guard dataset.isBundledSource,
              dataset.isCanonicalPaperDataset,
              dataset.resolvedScientificStatus == .paperSourceVerified,
              dataset.sha256Basis == .bundledRawCSVBytes,
              dataset.sha256 == ExperimentDatasetIdentity.canonicalPaperSHA256 else {
            return .unavailableNoncanonicalSource
        }
        let trainIDs = Set(split.trainRowIDs)
        let testIDs = Set(split.testRowIDs)
        guard configuration.validationStrategy == .publishedStyleRowSplit,
              configuration.seed == 0,
              split.trainingCount == 134,
              split.testCount == 57,
              trainIDs.count == split.trainingCount,
              testIDs.count == split.testCount,
              trainIDs.isDisjoint(with: testIDs),
              trainIDs.union(testIDs) == Set(1...191),
              testIDs == canonicalSeedZeroTestRowIDs,
              hyperparameters == configuration.preset else {
            return .unavailableProtocolVariation
        }
        return .eligibleReportedReference
    }
}

/// Standalone, intentionally redundant export record. Keeping all provenance at
/// the top level makes the JSON useful without knowledge of app-internal types.
struct ExperimentExportManifest: Equatable, Codable, Sendable {
    let schemaVersion: String
    let engineVersion: String
    let runID: UUID
    let startedAt: Date
    let completedAt: Date
    let elapsedSeconds: Double
    let evidenceLevel: ExperimentEvidenceLevel
    let researchMode: ResearchMode
    let scientificStatus: ScientificDataStatus
    let table4ReferenceStatus: ExperimentTable4ReferenceStatus
    let exactPaperReplayAvailable: Bool
    let dataset: ExperimentDatasetSnapshot
    let configuration: ExperimentConfiguration
    let hyperparameters: ExperimentHyperparameters
    let trainRowIDs: [Int]
    let testRowIDs: [Int]
    let trainDrugCounts: [String: Int]
    let testDrugCounts: [String: Int]
    let leakageAudit: ExperimentLeakageAudit
    let metrics: [ExperimentMetric]
    let predictions: [ExperimentPrediction]
    let warnings: [ExperimentMessage]
    let limitations: [ExperimentMessage]

    init(result: ExperimentRunResult) {
        schemaVersion = result.schemaVersion
        engineVersion = result.engineVersion
        runID = result.id
        startedAt = result.startedAt
        completedAt = result.completedAt
        elapsedSeconds = result.elapsedSeconds
        evidenceLevel = result.policyEvidenceLevel
        researchMode = result.dataset.resolvedResearchMode
        scientificStatus = result.dataset.resolvedScientificStatus
        table4ReferenceStatus = result.table4ReferenceStatus
        exactPaperReplayAvailable = result.exactPaperReplayAvailable
        dataset = result.dataset
        configuration = result.configuration
        hyperparameters = result.hyperparameters
        trainRowIDs = result.split.trainRowIDs
        testRowIDs = result.split.testRowIDs
        trainDrugCounts = result.split.trainDrugCounts
        testDrugCounts = result.split.testDrugCounts
        leakageAudit = result.leakageAudit
        metrics = result.metrics
        predictions = result.predictions
        warnings = result.warnings
        limitations = result.limitations
    }
}

enum ExperimentDatasetIdentity {
    static let canonicalPaperSHA256 = "03ff02276f333d06747efb7a625e9de1b4055b94b8736873f5e7cc389315b0f5"
    /// Hash of the parsed canonical values. This lets test hosts and command-line
    /// tools identify Data S1 even when `Bundle.main` is not the app bundle.
    private static let canonicalNormalizedSHA256 = "a0f8cd81f2369e08d0155a8644ff8ee1cb9128b16ee1bcea72c4df7e91848a07"

    struct Value: Equatable, Sendable {
        let sha256: String
        let normalizedSHA256: String
        let sha256Basis: ExperimentDatasetHashBasis
        let isCanonicalPaperDataset: Bool
    }

    static func identity(for dataset: TrainingDataset) -> Value {
        let normalizedHash = normalizedSHA256(for: dataset)
        if isCanonical(dataset, normalizedHash: normalizedHash) {
            return Value(
                sha256: canonicalPaperSHA256,
                normalizedSHA256: normalizedHash,
                sha256Basis: .bundledRawCSVBytes,
                isCanonicalPaperDataset: true
            )
        }
        return Value(
            sha256: normalizedHash,
            normalizedSHA256: normalizedHash,
            sha256Basis: .normalizedParsedValues,
            isCanonicalPaperDataset: false
        )
    }

    static func sha256(for dataset: TrainingDataset) -> String {
        identity(for: dataset).sha256
    }

    private static func isCanonical(_ dataset: TrainingDataset, normalizedHash: String) -> Bool {
        dataset.audit.isValid
            && dataset.audit.columnCount == TrainingDataSource.expectedHeader.count
            && dataset.rows.count == 191
            && normalizedHash == canonicalNormalizedSHA256
    }

    /// Replacement data no longer retain their original CSV bytes. Their identity
    /// is therefore a stable hash of parsed values, field boundaries, and schema.
    private static func normalizedSHA256(for dataset: TrainingDataset) -> String {
        var data = Data()

        func append(_ value: String) {
            let bytes = Data(value.utf8)
            var length = UInt64(bytes.count).bigEndian
            withUnsafeBytes(of: &length) { data.append(contentsOf: $0) }
            data.append(bytes)
        }

        func append(_ value: Double) {
            append(String(value.bitPattern, radix: 16))
        }

        TrainingDataSource.expectedHeader.forEach(append)
        for row in dataset.rows.sorted(by: { $0.id < $1.id }) {
            append(String(row.id))
            append(row.sourceDrugName)
            append(row.loading)
            append(row.molecularWeight)
            append(row.needleLength)
            append(String(row.skin.sourceCode))
            append(String(row.needle.sourceCode))
            append(row.surfaceArea)
            append(row.permeationTime)
            append(row.percentage)
            append(row.amount)
            append(row.reference)
        }
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}

enum ExperimentExportEncoder {
    static func data(for result: ExperimentRunResult) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(ExperimentExportManifest(result: result))
    }
}
