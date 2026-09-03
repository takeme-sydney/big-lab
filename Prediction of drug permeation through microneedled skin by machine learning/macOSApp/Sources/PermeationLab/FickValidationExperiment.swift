import Foundation

struct FickValidationConfiguration: Equatable, Codable, Sendable {
    var targetRSquared: Double
    var seriesTermCount: Int
    var minimumRate: Double
    var maximumRate: Double
    var logKGridCount: Int
    var goldenSectionIterations: Int
    var bootstrapIterations: Int
    var bootstrapSeed: UInt64

    init(
        targetRSquared: Double = 0.85,
        seriesTermCount: Int = 80,
        minimumRate: Double = 1e-8,
        maximumRate: Double = 100,
        logKGridCount: Int = 401,
        goldenSectionIterations: Int = 80,
        bootstrapIterations: Int = 20_000,
        bootstrapSeed: UInt64 = 20_260_830
    ) {
        self.targetRSquared = targetRSquared
        self.seriesTermCount = seriesTermCount
        self.minimumRate = minimumRate
        self.maximumRate = maximumRate
        self.logKGridCount = logKGridCount
        self.goldenSectionIterations = goldenSectionIterations
        self.bootstrapIterations = bootstrapIterations
        self.bootstrapSeed = bootstrapSeed
    }

    static let `default` = Self()
}

struct FickValidationFamily: Identifiable, Hashable, Codable, Sendable {
    let drugName: String
    let skinCode: Int
    let needleTypeCode: Int

    var id: String {
        "\(drugName)|skin=\(skinCode)|mn=\(needleTypeCode)"
    }
}

struct FickValidationCondition: Identifiable, Hashable, Codable, Sendable {
    let family: FickValidationFamily
    let loading: Double
    let molecularWeight: Double
    /// The unscaled millimetre value parsed from the compatible CSV.
    let needleLength: Double
    let surfaceArea: Double

    var id: String {
        [
            family.id,
            "loading=\(String(loading.bitPattern, radix: 16))",
            "mw=\(String(molecularWeight.bitPattern, radix: 16))",
            "length=\(String(needleLength.bitPattern, radix: 16))",
            "area=\(String(surfaceArea.bitPattern, radix: 16))",
        ].joined(separator: "|")
    }
}

struct FickValidationMetric: Equatable, Codable, Sendable {
    let rSquared: Double?
    let rmse: Double
    let mae: Double
    let observationCount: Int
}

struct FickValidationConfidenceInterval: Equatable, Codable, Sendable {
    let twoSidedLower: Double?
    let twoSidedUpper: Double?
    let oneSidedLower: Double?
    let probabilityAtOrAboveTarget: Double?
    let validReplicateCount: Int
    let requestedReplicateCount: Int
    let clusterCount: Int
}

/// Deterministically recomputed fit values used to audit a persisted fold
/// against the active dataset without trusting the fold's serialized fields.
struct FickValidationFittedParameters: Equatable, Sendable {
    let sse: Double
    let amplitude: Double
    let rate: Double
}

struct FickValidationPrediction: Identifiable, Equatable, Codable, Sendable {
    let rowID: Int
    let family: FickValidationFamily
    let condition: FickValidationCondition
    let foldID: String
    let timeHours: Double
    let observedPercentage: Double
    let predictedPercentage: Double

    var residual: Double { observedPercentage - predictedPercentage }
    var id: String { "\(foldID)|\(rowID)" }
}

struct FickValidationFold: Identifiable, Equatable, Codable, Sendable {
    let heldOutCondition: FickValidationCondition
    let trainingConditionIDs: [String]
    let trainingRowIDs: [Int]
    let testRowIDs: [Int]
    let fittedAmplitude: Double
    let fittedRate: Double
    let trainingSSE: Double

    var id: String { heldOutCondition.id }
}

struct FickValidationFamilyMetric: Identifiable, Equatable, Codable, Sendable {
    let family: FickValidationFamily
    let metric: FickValidationMetric

    var id: String { family.id }
}

struct FickValidationStressFold: Identifiable, Equatable, Codable, Sendable {
    let heldOutFamily: FickValidationFamily
    let trainingFamilyIDs: [String]
    let trainingRowIDs: [Int]
    let testRowIDs: [Int]
    let fittedAmplitude: Double
    let fittedRate: Double
    let trainingSSE: Double

    var id: String { heldOutFamily.id }
}

struct FickValidationStressResult: Equatable, Codable, Sendable {
    let metric: FickValidationMetric
    let predictions: [FickValidationPrediction]
    let folds: [FickValidationStressFold]
    let familyCount: Int
    let observationCount: Int
}

enum FickValidationEvidenceLevel: String, Codable, Sendable {
    case exploratoryProxyConditionCrossValidation
}

struct FickValidationRunResult: Identifiable, Equatable, Codable, Sendable {
    static let currentSchemaVersion = "1.1"

    let schemaVersion: String
    let id: UUID
    let startedAt: Date
    let completedAt: Date
    let elapsedSeconds: Double
    let modelVersion: String
    let evidenceLevel: FickValidationEvidenceLevel
    let dataset: ExperimentDatasetSnapshot
    let configuration: FickValidationConfiguration
    let pooledMetric: FickValidationMetric
    let familyMetrics: [FickValidationFamilyMetric]
    let confidenceInterval: FickValidationConfidenceInterval
    let predictions: [FickValidationPrediction]
    let folds: [FickValidationFold]
    let eligibleFamilyCount: Int
    let eligibleConditionCount: Int
    let eligibleObservationCount: Int
    let excludedFamilyCount: Int
    let excludedConditionCount: Int
    let excludedObservationCount: Int
    let leaveOneFamilyOutStress: FickValidationStressResult
    let pointPass: Bool
    let confidencePass: Bool
    let exactPaperReplayAvailable: Bool
    let warnings: [ExperimentMessage]
    let limitations: [ExperimentMessage]
}

enum FickValidationError: LocalizedError, Equatable, Sendable {
    case invalidConfiguration
    case unsupportedEvidenceContext
    case invalidDataset(errorCount: Int)
    case invalidTime(rowID: Int)
    case insufficientEligibleConditions
    case insufficientFamiliesForStress
    case nonFinitePrediction(rowID: Int)

    var errorDescription: String? {
        switch self {
        case .invalidConfiguration:
            "The Fick validation configuration is invalid."
        case .unsupportedEvidenceContext:
            "Fick proxy validation is restricted to unvalidated My Research data."
        case .invalidDataset(let errorCount):
            "The dataset has \(errorCount) validation error(s)."
        case .invalidTime(let rowID):
            "Row \(rowID) has a negative or non-finite permeation time."
        case .insufficientEligibleConditions:
            "No family has at least three proxy conditions for leave-one-condition-out validation."
        case .insufficientFamiliesForStress:
            "At least two drug-skin-microneedle families are required for the unseen-family stress test."
        case .nonFinitePrediction(let rowID):
            "The Fick proxy produced a non-finite prediction for row \(rowID)."
        }
    }
}

/// Deterministic exploratory validation of a finite-slab release proxy. This is
/// intentionally separate from the two-dimensional Data S2 preview and from the
/// three statistical reconstructions in `ExperimentRunner`.
enum FickValidationExperiment {
    static let modelVersion = "fick-finite-slab-release-proxy-v1"

    static func run(
        dataset: TrainingDataset,
        displayName: String,
        isBundledData: Bool = false,
        researchMode: ResearchMode = .myExperiment,
        scientificStatus: ScientificDataStatus = .userProvidedUnvalidated,
        importedAt: Date? = nil,
        configuration: FickValidationConfiguration = .default,
        runID: UUID = UUID(),
        startedAt: Date = Date()
    ) throws -> FickValidationRunResult {
        let uptime = ProcessInfo.processInfo.systemUptime
        try validate(
            configuration: configuration,
            dataset: dataset,
            researchMode: researchMode,
            scientificStatus: scientificStatus,
            isBundledData: isBundledData
        )

        let observations = try dataset.rows.map(Observation.init)
        let grouped = group(observations)
        guard grouped.count >= 2 else {
            throw FickValidationError.insufficientFamiliesForStress
        }
        let orderedFamilies = grouped.keys.sorted(by: familyComesBefore)
        let eligibleFamilies = orderedFamilies.filter { (grouped[$0]?.count ?? 0) >= 3 }
        guard !eligibleFamilies.isEmpty else {
            throw FickValidationError.insufficientEligibleConditions
        }

        var predictions: [FickValidationPrediction] = []
        var folds: [FickValidationFold] = []
        for family in eligibleFamilies {
            guard let familyConditions = grouped[family] else { continue }
            let orderedConditions = familyConditions.keys.sorted(by: conditionComesBefore)
            for heldOutCondition in orderedConditions {
                try Task.checkCancellation()
                let trainingConditions = orderedConditions.filter { $0 != heldOutCondition }
                let training = trainingConditions.flatMap { familyConditions[$0] ?? [] }
                    .sorted { $0.rowID < $1.rowID }
                let test = (familyConditions[heldOutCondition] ?? [])
                    .sorted { $0.rowID < $1.rowID }
                let fit = fit(training: training, configuration: configuration)
                let foldID = heldOutCondition.id
                let foldPredictions = try test.map { observation -> FickValidationPrediction in
                    let predicted = fit.amplitude * fraction(
                        fit.rate * observation.timeHours,
                        termCount: configuration.seriesTermCount
                    )
                    guard predicted.isFinite else {
                        throw FickValidationError.nonFinitePrediction(rowID: observation.rowID)
                    }
                    return FickValidationPrediction(
                        rowID: observation.rowID,
                        family: observation.family,
                        condition: observation.condition,
                        foldID: foldID,
                        timeHours: observation.timeHours,
                        observedPercentage: observation.observedPercentage,
                        predictedPercentage: predicted
                    )
                }
                predictions.append(contentsOf: foldPredictions)
                folds.append(FickValidationFold(
                    heldOutCondition: heldOutCondition,
                    trainingConditionIDs: trainingConditions.map(\.id),
                    trainingRowIDs: training.map(\.rowID),
                    testRowIDs: test.map(\.rowID),
                    fittedAmplitude: fit.amplitude,
                    fittedRate: fit.rate,
                    trainingSSE: fit.sse
                ))
            }
        }
        predictions.sort { lhs, rhs in
            lhs.rowID == rhs.rowID ? lhs.foldID < rhs.foldID : lhs.rowID < rhs.rowID
        }
        folds.sort { conditionComesBefore($0.heldOutCondition, $1.heldOutCondition) }

        let pooledMetric = metric(predictions)
        let familyMetrics = eligibleFamilies.map { family in
            FickValidationFamilyMetric(
                family: family,
                metric: metric(predictions.filter { $0.family == family })
            )
        }
        let confidenceInterval = try bootstrap(
            predictions: predictions,
            configuration: configuration
        )
        let stress = try leaveOneFamilyOutStress(
            observations: observations,
            grouped: grouped,
            configuration: configuration
        )

        let eligibleFamilySet = Set(eligibleFamilies)
        let eligibleConditionCount = eligibleFamilies.reduce(0) { partial, family in
            partial + (grouped[family]?.count ?? 0)
        }
        let eligibleObservationCount = observations.count { eligibleFamilySet.contains($0.family) }
        let excludedFamilies = orderedFamilies.filter { !eligibleFamilySet.contains($0) }
        let excludedConditionCount = excludedFamilies.reduce(0) { partial, family in
            partial + (grouped[family]?.count ?? 0)
        }
        let excludedObservationCount = observations.count - eligibleObservationCount
        let snapshot = ExperimentDatasetSnapshot.make(
            dataset: dataset,
            displayName: displayName,
            isBundledData: isBundledData,
            researchMode: researchMode,
            scientificStatus: scientificStatus,
            importedAt: importedAt
        )
        let pointPass = pooledMetric.rSquared.map { $0 >= configuration.targetRSquared } ?? false
        let confidencePass = pointPass && (confidenceInterval.oneSidedLower.map {
            $0 >= configuration.targetRSquared
        } ?? false)
        let warnings = makeWarnings(
            dataset: dataset,
            eligibleConditionCount: eligibleConditionCount,
            pooledMetric: pooledMetric,
            familyMetrics: familyMetrics,
            confidenceInterval: confidenceInterval,
            primaryBoundaryCount: folds.count { $0.fittedAmplitude == 100 },
            primaryFoldCount: folds.count,
            stressBoundaryCount: stress.folds.count { $0.fittedAmplitude == 100 },
            stressFoldCount: stress.folds.count,
            configuration: configuration
        )
        let limitations = makeLimitations()
        let completedAt = Date()

        return FickValidationRunResult(
            schemaVersion: FickValidationRunResult.currentSchemaVersion,
            id: runID,
            startedAt: startedAt,
            completedAt: completedAt,
            elapsedSeconds: max(0, ProcessInfo.processInfo.systemUptime - uptime),
            modelVersion: modelVersion,
            evidenceLevel: .exploratoryProxyConditionCrossValidation,
            dataset: snapshot,
            configuration: configuration,
            pooledMetric: pooledMetric,
            familyMetrics: familyMetrics,
            confidenceInterval: confidenceInterval,
            predictions: predictions,
            folds: folds,
            eligibleFamilyCount: eligibleFamilies.count,
            eligibleConditionCount: eligibleConditionCount,
            eligibleObservationCount: eligibleObservationCount,
            excludedFamilyCount: excludedFamilies.count,
            excludedConditionCount: excludedConditionCount,
            excludedObservationCount: excludedObservationCount,
            leaveOneFamilyOutStress: stress,
            pointPass: pointPass,
            confidencePass: confidencePass,
            exactPaperReplayAvailable: false,
            warnings: warnings,
            limitations: limitations
        )
    }

    /// The specified finite-slab fraction using exactly the requested odd series.
    static func fraction(_ x: Double, termCount: Int = 80) -> Double {
        if x <= 0 { return 0 }
        let coefficient = 8 / (Double.pi * Double.pi)
        var sum = 0.0
        for index in 0..<termCount {
            let odd = Double(2 * index + 1)
            let square = odd * odd
            sum += Foundation.exp(-square * x) / square
        }
        return 1 - coefficient * sum
    }

    static func supports(_ configuration: FickValidationConfiguration) -> Bool {
        // This screen is a locked R² ≥ 0.85 protocol, not a general-purpose
        // optimizer. Requiring the complete preregisterable configuration also
        // prevents a malformed history record from requesting unbounded work
        // while it is being audited in the UI.
        configuration == .default
    }

    /// Re-runs the exact deterministic optimizer on the supplied training rows.
    /// Audit code uses this rather than serialized A/k/SSE values.
    static func recomputeFit(
        rows: [TrainingDataRow],
        configuration: FickValidationConfiguration
    ) throws -> FickValidationFittedParameters {
        guard supports(configuration), !rows.isEmpty else {
            throw FickValidationError.invalidConfiguration
        }
        let fit = fit(
            training: try rows.map(Observation.init),
            configuration: configuration
        )
        return FickValidationFittedParameters(
            sse: fit.sse,
            amplitude: fit.amplitude,
            rate: fit.rate
        )
    }

    /// Recomputes the fixed-OOF composition sensitivity from predictions and
    /// configuration so imported percentile fields are never trusted.
    static func recomputeConfidenceInterval(
        predictions: [FickValidationPrediction],
        configuration: FickValidationConfiguration
    ) throws -> FickValidationConfidenceInterval {
        guard supports(configuration), !predictions.isEmpty else {
            throw FickValidationError.invalidConfiguration
        }
        return try bootstrap(predictions: predictions, configuration: configuration)
    }

    private struct Observation: Sendable {
        let rowID: Int
        let family: FickValidationFamily
        let condition: FickValidationCondition
        let timeHours: Double
        let observedPercentage: Double

        init(row: TrainingDataRow) throws {
            guard row.permeationTime.isFinite, row.permeationTime >= 0 else {
                throw FickValidationError.invalidTime(rowID: row.id)
            }
            let family = FickValidationFamily(
                drugName: row.sourceDrugName,
                skinCode: row.skin.sourceCode,
                needleTypeCode: row.needle.sourceCode
            )
            self.rowID = row.id
            self.family = family
            condition = FickValidationCondition(
                family: family,
                loading: row.loading,
                molecularWeight: row.molecularWeight,
                needleLength: row.needleLength,
                surfaceArea: row.surfaceArea
            )
            timeHours = row.permeationTime
            observedPercentage = row.percentage
        }
    }

    private struct Fit: Equatable, Sendable {
        let sse: Double
        let amplitude: Double
        let rate: Double
    }

    private static func validate(
        configuration: FickValidationConfiguration,
        dataset: TrainingDataset,
        researchMode: ResearchMode,
        scientificStatus: ScientificDataStatus,
        isBundledData: Bool
    ) throws {
        guard supports(configuration) else {
            throw FickValidationError.invalidConfiguration
        }
        guard researchMode == .myExperiment,
              scientificStatus == .userProvidedUnvalidated,
              !isBundledData else {
            throw FickValidationError.unsupportedEvidenceContext
        }
        guard dataset.audit.isValid, !dataset.rows.isEmpty else {
            throw FickValidationError.invalidDataset(
                errorCount: dataset.audit.parseErrors.count
            )
        }
    }

    private static func group(
        _ observations: [Observation]
    ) -> [FickValidationFamily: [FickValidationCondition: [Observation]]] {
        var result: [FickValidationFamily: [FickValidationCondition: [Observation]]] = [:]
        for observation in observations {
            result[observation.family, default: [:]][observation.condition, default: []]
                .append(observation)
        }
        return result
    }

    private static func familyComesBefore(
        _ lhs: FickValidationFamily,
        _ rhs: FickValidationFamily
    ) -> Bool {
        if lhs.drugName != rhs.drugName { return lhs.drugName < rhs.drugName }
        if lhs.skinCode != rhs.skinCode { return lhs.skinCode < rhs.skinCode }
        return lhs.needleTypeCode < rhs.needleTypeCode
    }

    private static func conditionComesBefore(
        _ lhs: FickValidationCondition,
        _ rhs: FickValidationCondition
    ) -> Bool {
        if lhs.family != rhs.family { return familyComesBefore(lhs.family, rhs.family) }
        if lhs.loading != rhs.loading { return lhs.loading < rhs.loading }
        if lhs.molecularWeight != rhs.molecularWeight {
            return lhs.molecularWeight < rhs.molecularWeight
        }
        if lhs.needleLength != rhs.needleLength { return lhs.needleLength < rhs.needleLength }
        return lhs.surfaceArea < rhs.surfaceArea
    }

    private static func fit(
        training: [Observation],
        configuration: FickValidationConfiguration
    ) -> Fit {
        let lowerLogRate = Foundation.log(configuration.minimumRate)
        let upperLogRate = Foundation.log(configuration.maximumRate)
        let gridDenominator = Double(configuration.logKGridCount - 1)
        var grid: [(logRate: Double, fit: Fit)] = []
        grid.reserveCapacity(configuration.logKGridCount)
        for index in 0..<configuration.logKGridCount {
            let fraction = Double(index) / gridDenominator
            let logRate = lowerLogRate + fraction * (upperLogRate - lowerLogRate)
            grid.append((logRate, evaluate(logRate: logRate, training: training)))
        }
        let bestGridIndex = grid.indices.min { lhs, rhs in
            fitComesBefore(grid[lhs].fit, grid[rhs].fit)
        } ?? 0
        var lower = grid[max(0, bestGridIndex - 1)].logRate
        var upper = grid[min(grid.count - 1, bestGridIndex + 1)].logRate
        let golden = (Foundation.sqrt(5) - 1) / 2
        var left = upper - golden * (upper - lower)
        var right = lower + golden * (upper - lower)
        var leftFit = evaluate(logRate: left, training: training)
        var rightFit = evaluate(logRate: right, training: training)

        for _ in 0..<configuration.goldenSectionIterations {
            if fitComesBefore(leftFit, rightFit) {
                upper = right
                right = left
                rightFit = leftFit
                left = upper - golden * (upper - lower)
                leftFit = evaluate(logRate: left, training: training)
            } else {
                lower = left
                left = right
                leftFit = rightFit
                right = lower + golden * (upper - lower)
                rightFit = evaluate(logRate: right, training: training)
            }
        }

        return [
            grid[bestGridIndex].fit,
            leftFit,
            rightFit,
            evaluate(logRate: lower, training: training),
            evaluate(logRate: upper, training: training),
        ].min(by: fitComesBefore) ?? grid[bestGridIndex].fit
    }

    private static func evaluate(logRate: Double, training: [Observation]) -> Fit {
        let rate = Foundation.exp(logRate)
        var numerator = 0.0
        var denominator = 0.0
        var basis: [Double] = []
        basis.reserveCapacity(training.count)
        for observation in training {
            let value = fraction(rate * observation.timeHours)
            basis.append(value)
            numerator += observation.observedPercentage * value
            denominator += value * value
        }
        let unconstrainedAmplitude = denominator > 1e-24 ? numerator / denominator : 0
        let amplitude = min(100, max(0, unconstrainedAmplitude))
        let sse = zip(training, basis).reduce(0.0) { partial, pair in
            let residual = pair.0.observedPercentage - amplitude * pair.1
            return partial + residual * residual
        }
        return Fit(sse: sse, amplitude: amplitude, rate: rate)
    }

    private static func fitComesBefore(_ lhs: Fit, _ rhs: Fit) -> Bool {
        lhs.sse == rhs.sse ? lhs.rate < rhs.rate : lhs.sse < rhs.sse
    }

    private static func metric(_ predictions: [FickValidationPrediction]) -> FickValidationMetric {
        let values = predictions.map { ($0.observedPercentage, $0.predictedPercentage) }
        return metric(values)
    }

    private static func metric(_ values: [(observed: Double, predicted: Double)]) -> FickValidationMetric {
        guard !values.isEmpty else {
            return FickValidationMetric(rSquared: nil, rmse: 0, mae: 0, observationCount: 0)
        }
        let mean = values.reduce(0.0) { $0 + $1.observed } / Double(values.count)
        var squaredError = 0.0
        var absoluteError = 0.0
        var total = 0.0
        for value in values {
            let residual = value.observed - value.predicted
            squaredError += residual * residual
            absoluteError += abs(residual)
            let centered = value.observed - mean
            total += centered * centered
        }
        return FickValidationMetric(
            rSquared: total > 1e-20 ? 1 - squaredError / total : nil,
            rmse: Foundation.sqrt(squaredError / Double(values.count)),
            mae: absoluteError / Double(values.count),
            observationCount: values.count
        )
    }

    private static func bootstrap(
        predictions: [FickValidationPrediction],
        configuration: FickValidationConfiguration
    ) throws -> FickValidationConfidenceInterval {
        // Dictionary grouping preserves input order within each condition. Fix
        // that order first so the same run produces byte-identical percentiles
        // even when a decoded prediction array has been reordered.
        let orderedPredictions = predictions.sorted {
            $0.rowID == $1.rowID ? $0.foldID < $1.foldID : $0.rowID < $1.rowID
        }
        let grouped = Dictionary(
            grouping: orderedPredictions,
            by: \FickValidationPrediction.condition
        )
        let conditions = grouped.keys.sorted(by: conditionComesBefore)
        var generator = FickValidationRandomNumberGenerator(seed: configuration.bootstrapSeed)
        var values: [Double] = []
        values.reserveCapacity(configuration.bootstrapIterations)
        for iteration in 0..<configuration.bootstrapIterations {
            if iteration.isMultiple(of: 256) {
                try Task.checkCancellation()
            }
            var sample: [(observed: Double, predicted: Double)] = []
            for _ in conditions.indices {
                let condition = conditions[generator.nextIndex(upperBound: conditions.count)]
                sample.append(contentsOf: (grouped[condition] ?? []).map {
                    ($0.observedPercentage, $0.predictedPercentage)
                })
            }
            if let rSquared = metric(sample).rSquared, rSquared.isFinite {
                values.append(rSquared)
            }
        }
        values.sort()
        let probability = values.isEmpty ? nil : Double(values.count {
            $0 >= configuration.targetRSquared
        }) / Double(values.count)
        return FickValidationConfidenceInterval(
            twoSidedLower: quantile(values, probability: 0.025),
            twoSidedUpper: quantile(values, probability: 0.975),
            oneSidedLower: quantile(values, probability: 0.05),
            probabilityAtOrAboveTarget: probability,
            validReplicateCount: values.count,
            requestedReplicateCount: configuration.bootstrapIterations,
            clusterCount: conditions.count
        )
    }

    private static func quantile(_ sorted: [Double], probability: Double) -> Double? {
        guard !sorted.isEmpty else { return nil }
        let position = min(1, max(0, probability)) * Double(sorted.count - 1)
        let lower = Int(Foundation.floor(position))
        let upper = Int(Foundation.ceil(position))
        if lower == upper { return sorted[lower] }
        let weight = position - Double(lower)
        return sorted[lower] + weight * (sorted[upper] - sorted[lower])
    }

    private static func leaveOneFamilyOutStress(
        observations: [Observation],
        grouped: [FickValidationFamily: [FickValidationCondition: [Observation]]],
        configuration: FickValidationConfiguration
    ) throws -> FickValidationStressResult {
        let families = grouped.keys.sorted(by: familyComesBefore)
        var predictions: [FickValidationPrediction] = []
        var folds: [FickValidationStressFold] = []
        for heldOutFamily in families {
            try Task.checkCancellation()
            let trainingFamilies = families.filter { $0 != heldOutFamily }
            let training = observations.filter { $0.family != heldOutFamily }
                .sorted { $0.rowID < $1.rowID }
            let test = observations.filter { $0.family == heldOutFamily }
                .sorted { $0.rowID < $1.rowID }
            let fit = fit(training: training, configuration: configuration)
            let foldID = "family-holdout|\(heldOutFamily.id)"
            let foldPredictions = try test.map { observation -> FickValidationPrediction in
                let predicted = fit.amplitude * fraction(
                    fit.rate * observation.timeHours,
                    termCount: configuration.seriesTermCount
                )
                guard predicted.isFinite else {
                    throw FickValidationError.nonFinitePrediction(rowID: observation.rowID)
                }
                return FickValidationPrediction(
                    rowID: observation.rowID,
                    family: observation.family,
                    condition: observation.condition,
                    foldID: foldID,
                    timeHours: observation.timeHours,
                    observedPercentage: observation.observedPercentage,
                    predictedPercentage: predicted
                )
            }
            predictions.append(contentsOf: foldPredictions)
            folds.append(FickValidationStressFold(
                heldOutFamily: heldOutFamily,
                trainingFamilyIDs: trainingFamilies.map(\.id),
                trainingRowIDs: training.map(\.rowID),
                testRowIDs: test.map(\.rowID),
                fittedAmplitude: fit.amplitude,
                fittedRate: fit.rate,
                trainingSSE: fit.sse
            ))
        }
        predictions.sort { lhs, rhs in
            lhs.rowID == rhs.rowID ? lhs.foldID < rhs.foldID : lhs.rowID < rhs.rowID
        }
        return FickValidationStressResult(
            metric: metric(predictions),
            predictions: predictions,
            folds: folds,
            familyCount: families.count,
            observationCount: predictions.count
        )
    }

    /// Deterministic scientific notices are part of the audited artifact, not
    /// editable presentation copy. Diagnostics independently regenerates them.
    static func makeWarnings(
        dataset: TrainingDataset,
        eligibleConditionCount: Int,
        pooledMetric: FickValidationMetric,
        familyMetrics: [FickValidationFamilyMetric],
        confidenceInterval: FickValidationConfidenceInterval,
        primaryBoundaryCount: Int,
        primaryFoldCount: Int,
        stressBoundaryCount: Int,
        stressFoldCount: Int,
        configuration: FickValidationConfiguration
    ) -> [ExperimentMessage] {
        var warnings: [ExperimentMessage] = [
            .init(
                code: "proxy_condition_not_run_id",
                japanese: "実験run/curve IDがないため、時間以外の完全一致条件をproxy clusterとして使用しています。独立実験単位とは確認できません。",
                english: "Because experiment run/curve IDs are unavailable, exact matching non-time conditions are used as proxy clusters; they are not verified independent experiment units."
            ),
            .init(
                code: "pooled_metric_is_row_weighted",
                japanese: "pooled指標は\(eligibleConditionCount)条件内の行を等重みで集計します。時点数の多い条件とfamily間平均差の影響を受けます。family別指標も確認してください。",
                english: "The pooled metric weights rows within \(eligibleConditionCount) conditions equally. Conditions with more time points and between-family mean differences influence it; inspect the family-level metrics as well."
            ),
            .init(
                code: "small_cluster_bootstrap",
                japanese: "固定済みOOF予測を\(eligibleConditionCount) conditionで再標本化します。各replicateでモデルを再fitせず、family層別化も行わないため、percentileは不安定な探索的組成感度であり、一般的な信頼区間ではありません。",
                english: "The \(eligibleConditionCount) condition clusters resample already-fixed OOF predictions. Replicates do not refit the model or stratify by family, so the percentiles are an unstable exploratory composition sensitivity, not a generic confidence interval."
            ),
        ]
        if dataset.audit.percentageAbove100Count > 0 {
            warnings.append(.init(
                code: "percentage_above_100_retained",
                japanese: "100%を超える実測透過率\(dataset.audit.percentageAbove100Count)件を除外・clampせず保持しています。proxy予測のAのみ物理制約として0...100に制約します。",
                english: "\(dataset.audit.percentageAbove100Count) observed percentage value(s) above 100% are retained without exclusion or clipping; only the proxy amplitude A is physically constrained to 0...100."
            ))
        }
        if !familyMetrics.isEmpty,
           familyMetrics.allSatisfy({
               ($0.metric.rSquared ?? -Double.infinity) < configuration.targetRSquared
           }) {
            warnings.append(.init(
                code: "all_family_metrics_below_target",
                japanese: "row-pooled R²とは異なり、eligibleな全familyのR²が0.85未満です。pooled値をfamily別達成へ一般化しないでください。",
                english: "Unlike the row-pooled R², every eligible-family R² is below 0.85. Do not generalize the pooled value to family-specific attainment."
            ))
        }
        if primaryBoundaryCount > 0 || stressBoundaryCount > 0 {
            warnings.append(.init(
                code: "amplitude_upper_boundary_reached",
                japanese: "A=100の上限へ主要fold \(primaryBoundaryCount)/\(primaryFoldCount)、stress fold \(stressBoundaryCount)/\(stressFoldCount)が到達しました。観測modelとtransportabilityの境界問題として扱ってください。",
                english: "The A=100 upper boundary was reached by \(primaryBoundaryCount)/\(primaryFoldCount) primary fold(s) and \(stressBoundaryCount)/\(stressFoldCount) stress fold(s). Treat this as an observation-model and transportability boundary issue."
            ))
        }
        if pooledMetric.rSquared.map({ $0 >= configuration.targetRSquared }) == true,
           confidenceInterval.oneSidedLower.map({ $0 < configuration.targetRSquared }) == true {
            warnings.append(.init(
                code: "point_threshold_without_confidence_support",
                japanese: "row-pooled R²点推定は目標を超えますが、固定OOF分布の5 percentileは未達です。85%以上を確認した結果ではなく、family別・等重み集計と独立データ検証が必要です。",
                english: "The row-pooled R² point estimate exceeds the target but the fixed-OOF distribution's fifth percentile does not. This is not confirmation of at least 85%; family/equal-weight summaries and independent-data validation are required."
            ))
        }
        return warnings
    }

    static func makeLimitations() -> [ExperimentMessage] {
        [
            .init(
                code: "not_original_2d_fick_or_table4",
                japanese: "これはFick第二法則の有限平板放出proxyであり、原著Data S2の2D有限差分法、未公開の行別設定、Table 4予測の再現ではありません。",
                english: "This is a finite-slab release proxy based on Fick's second law, not the paper's Data S2 two-dimensional finite-difference method, its unpublished row settings, or a replay of Table 4 predictions."
            ),
            .init(
                code: "effective_parameters_not_identified_physics",
                japanese: "Aとkはtraining目的値へ合わせた有効曲線パラメータです。拡散係数、分配係数、皮膚厚を個別に同定した物性値ではありません。",
                english: "A and k are effective curve parameters fitted to training targets; they are not separately identified physical diffusivity, partition, or skin-thickness measurements."
            ),
            .init(
                code: "known_family_internal_validation_only",
                japanese: "主評価は既知drug×skin×MN family内の新しいproxy conditionへの内部検証です。未知family、別batch、別donor、外部施設への一般化を示しません。",
                english: "The primary evaluation is internal validation of new proxy conditions within known drug × skin × MN families. It does not establish generalization to unseen families, batches, donors, or sites."
            ),
            .init(
                code: "time_only_curve_grouping_fields_not_covariates",
                japanese: "予測式へ数値入力されるのは時間だけです。loading、MW、MN長、面積、skin、MN typeはgroup keyであり、condition-awareな物理共変量ではありません。",
                english: "Time is the only numerical input to the prediction curve. Loading, molecular weight, MN length, area, skin and MN type are grouping keys, not condition-aware physical covariates."
            ),
            .init(
                code: "run_donor_batch_source_hierarchy_missing",
                japanese: "run、curve、donor、batch、siteの独立IDがなく、familyとsource studyも交絡し得ます。time-point rowsをそのまま独立実験として扱えません。",
                english: "Independent run, curve, donor, batch and site IDs are unavailable, and family may be confounded with source study. Time-point rows cannot be treated as independent experiments."
            ),
            .init(
                code: "measurement_uncertainty_not_modeled",
                japanese: "測定誤差、run内相関、run間変動をmodel化していません。",
                english: "Measurement error, within-run correlation and between-run variation are not modeled."
            ),
            .init(
                code: "model_development_requires_external_confirmation",
                japanese: "同じData S1でモデル式と評価法を開発しているため、結果は探索的です。モデルを凍結した後の独立データで確認が必要です。",
                english: "Because the model form and evaluation were developed on the same Data S1 source, the result is exploratory and requires confirmation on independent data after the model is frozen."
            ),
        ]
    }
}

private struct FickValidationRandomNumberGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var value = state
        value = (value ^ (value >> 30)) &* 0xBF58_476D_1CE4_E5B9
        value = (value ^ (value >> 27)) &* 0x94D0_49BB_1331_11EB
        return value ^ (value >> 31)
    }

    mutating func nextIndex(upperBound: Int) -> Int {
        Int(next() % UInt64(upperBound))
    }
}

enum FickValidationExportEncoder {
    static func data(for result: FickValidationRunResult) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(result)
    }
}

struct FickValidationHistoryPersistence {
    static let defaultKey = "permeationLab.fickValidation.recentRuns.v1"

    let userDefaults: UserDefaults
    let key: String
    let maximumRunCount: Int
    let maximumEncodedBytes: Int

    init(
        userDefaults: UserDefaults = .standard,
        key: String = Self.defaultKey,
        maximumRunCount: Int = 10,
        maximumEncodedBytes: Int = 4 * 1_024 * 1_024
    ) {
        self.userDefaults = userDefaults
        self.key = key
        self.maximumRunCount = max(1, maximumRunCount)
        self.maximumEncodedBytes = max(64 * 1_024, maximumEncodedBytes)
    }

    func load() -> [FickValidationRunResult] {
        guard let data = userDefaults.data(forKey: key) else { return [] }
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return Array(
                try decoder.decode([FickValidationRunResult].self, from: data)
                    .sorted { $0.completedAt > $1.completedAt }
                    .prefix(maximumRunCount)
            )
        } catch {
            userDefaults.removeObject(forKey: key)
            return []
        }
    }

    @discardableResult
    func save(_ runs: [FickValidationRunResult]) -> [FickValidationRunResult] {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        encoder.dateEncodingStrategy = .iso8601
        var seen = Set<UUID>()
        let candidates = runs
            .sorted { $0.completedAt > $1.completedAt }
            .filter { seen.insert($0.id).inserted }
            .prefix(maximumRunCount)
        var retained: [FickValidationRunResult] = []
        var skippedOversizedRun = false
        for candidate in candidates {
            let proposed = retained + [candidate]
            guard let data = try? encoder.encode(proposed), data.count <= maximumEncodedBytes else {
                skippedOversizedRun = true
                continue
            }
            retained = proposed
        }
        if retained.isEmpty {
            if !skippedOversizedRun {
                userDefaults.removeObject(forKey: key)
            } else {
                return load()
            }
        } else if let data = try? encoder.encode(retained) {
            userDefaults.set(data, forKey: key)
        }
        return retained
    }

    func clear() {
        userDefaults.removeObject(forKey: key)
    }
}
