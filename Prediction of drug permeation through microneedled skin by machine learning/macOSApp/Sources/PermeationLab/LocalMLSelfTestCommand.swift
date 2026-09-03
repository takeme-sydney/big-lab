import Foundation

enum LocalMLSelfTestError: LocalizedError, Equatable {
    case invalidBundledData(rowCount: Int, parseErrorCount: Int)
    case assertionFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidBundledData(let rowCount, let parseErrorCount):
            "Bundled Data S1 is unavailable or invalid (rows: \(rowCount), parse errors: \(parseErrorCount))."
        case .assertionFailed(let detail):
            "Local ML self-test assertion failed: \(detail)"
        }
    }
}

struct LocalMLSelfTestConfiguration: Equatable, Sendable {
    let target: Int
    let group: Int?
    let features: Set<Int>
}

struct LocalMLSelfTestEvaluationSummary: Codable, Equatable, Sendable {
    let observations: Int
    let missingOutcomes: Int
    let rmse: Double
    let mae: Double
    let rSquared: Double?
}

struct LocalMLSelfTestSummary: Codable, Equatable, Sendable {
    let command: String
    let status: String
    let dataset: String
    let datasetNormalizedSHA256: String
    let rows: Int
    let target: String
    let group: String
    let features: [String]
    let candidateFamilies: [String]
    let folds: Int
    let winner: String
    let selectedCVRMSE: Double
    let trainingRows: Int
    let encodedFeatures: Int
    let artifactBytes: Int
    let artifactRoundTripExact: Bool
    let predictions: Int
    let finitePredictions: Int
    let predictionRoundTripExact: Bool
    let practiceData: Bool
    let evaluation: LocalMLSelfTestEvaluationSummary?

    func jsonLineData() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        var data = try encoder.encode(self)
        data.append(0x0A)
        return data
    }
}

/// A bounded, non-UI smoke test for the complete local tabular-regression path.
/// It always uses the immutable bundled Data S1, the same defaults as the local
/// ML screen, three fixed candidate families, and at most five grouped folds.
enum LocalMLSelfTestCommand {
    static let flag = "-local-ml-self-test"
    static let dataS1Name = "Yuan 2023 · Data S1"
    static let expectedRowCount = 191
    static let expectedTargetName = "Permeation amount"
    static let expectedGroupName = "Drug"
    static let expectedFeatureNames = [
        "Loading",
        "Molecular weight",
        "MN length",
        "Skin",
        "MN type",
        "Surface area",
        "Time",
    ]

    static func isRequested(arguments: [String]) -> Bool {
        arguments.contains(flag)
    }

    /// Resolves defaults with the same target/group/recommendation sequence used
    /// when `ModelSelectionView` loads the current app dataset.
    static func defaultConfiguration(for dataset: GenericDataset) throws -> LocalMLSelfTestConfiguration {
        guard let target = dataset.headers.firstIndex(of: expectedTargetName)
            ?? DataLeakageAudit.suggestedTarget(in: dataset) else {
            throw LocalMLSelfTestError.assertionFailed("the default target could not be resolved")
        }
        let group = DataLeakageAudit.suggestedGroup(in: dataset, excluding: target)
        let features = DataLeakageAudit.recommendedFeatures(
            dataset: dataset,
            target: target,
            group: group
        )
        return LocalMLSelfTestConfiguration(target: target, group: group, features: features)
    }

    @discardableResult
    static func execute() throws -> LocalMLSelfTestSummary {
        let source = TrainingDataSource.bundled
        let identity = ExperimentDatasetIdentity.identity(for: source)
        guard source.audit.isValid,
              source.rows.count == expectedRowCount,
              identity.isCanonicalPaperDataset else {
            throw LocalMLSelfTestError.invalidBundledData(
                rowCount: source.rows.count,
                parseErrorCount: source.audit.parseErrors.count
            )
        }

        let dataset = GenericDataset.from(trainingDataset: source, name: dataS1Name)
        let configuration = try defaultConfiguration(for: dataset)
        try require(dataset.rows.count == expectedRowCount, "the generic Data S1 row count changed")
        try require(
            dataset.headers[configuration.target] == expectedTargetName,
            "the default target no longer matches the local ML screen"
        )
        try require(
            configuration.group.map { dataset.headers[$0] } == expectedGroupName,
            "the default split group no longer matches the local ML screen"
        )
        let featureNames = configuration.features.sorted().map { dataset.headers[$0] }
        try require(
            featureNames == expectedFeatureNames,
            "the safe default predictor set changed"
        )

        let leakageAudit = DataLeakageAudit.review(
            dataset: dataset,
            target: configuration.target,
            group: configuration.group,
            features: configuration.features
        )
        try require(
            leakageAudit.canTrain,
            "the safe default configuration has leakage blocker(s): \(leakageAudit.blockers.map(\.id).joined(separator: ","))"
        )

        let report = try ModelSelectionEngine.evaluate(
            dataset: dataset,
            target: configuration.target,
            group: configuration.group,
            features: configuration.features
        )
        let expectedFamilies = Set(CandidateFamily.allCases)
        try require(report.usedGroupHoldout, "model selection did not use grouped holdout")
        try require(report.observationCount == expectedRowCount, "CV did not evaluate every Data S1 row")
        try require(report.foldCount >= 2 && report.foldCount <= 5, "CV fold count is outside the bounded range")
        try require(
            Set(report.metrics.map(\.family)) == expectedFamilies,
            "CV did not evaluate every candidate family exactly once"
        )
        try require(report.metrics.count == expectedFamilies.count, "CV returned duplicate candidate metrics")
        try require(report.metrics.allSatisfy(Self.metricIsFinite), "CV produced a non-finite metric")
        guard let selectedMetric = report.metrics.first(where: { $0.family == report.winner }) else {
            throw LocalMLSelfTestError.assertionFailed("the CV winner has no metric")
        }

        let artifact = try ModelTrainingEngine.train(
            dataset: dataset,
            target: configuration.target,
            group: configuration.group,
            features: configuration.features,
            family: report.winner,
            report: report,
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000191")!,
            trainedAt: Date(timeIntervalSince1970: 1_700_000_191)
        )
        try require(artifact.trainingRowCount == expectedRowCount, "final fit did not use every finite Data S1 row")
        try require(artifact.validation.selectedWasCVWinner, "final fit did not use the CV winner")

        let artifactJSON = try artifact.encodedData(prettyPrinted: false)
        try require(
            artifactJSON.count <= LocalModelArtifactImportLimits.maximumEncodedByteCount,
            "the model artifact exceeds the bounded import size"
        )
        let decodedArtifact = try LocalModelArtifact.decode(artifactJSON)
        try require(decodedArtifact == artifact, "strict JSON round-trip changed the model artifact")

        let fittedPrediction = try LocalPredictionEngine.predict(
            dataset: dataset,
            with: artifact,
            isPracticeData: true
        )
        let importedPrediction = try LocalPredictionEngine.predict(
            dataset: dataset,
            with: decodedArtifact,
            isPracticeData: true
        )
        try require(
            importedPrediction == fittedPrediction,
            "strict artifact round-trip changed Data S1 predictions"
        )
        try require(
            importedPrediction.predictions.count == expectedRowCount,
            "prediction did not return one output per Data S1 row"
        )
        let finitePredictionCount = importedPrediction.predictions.filter { $0.predicted.isFinite }.count
        try require(finitePredictionCount == expectedRowCount, "prediction produced a non-finite output")
        try require(
            importedPrediction.predictions.allSatisfy { $0.actual?.isFinite == true },
            "prediction did not retain every finite Data S1 outcome"
        )
        try require(!importedPrediction.diagnostics.hasWarnings, "in-sample Data S1 prediction reported data-shift warnings")

        guard let evaluation = importedPrediction.evaluation else {
            throw LocalMLSelfTestError.assertionFailed("Data S1 outcomes did not produce an evaluation")
        }
        try require(evaluation.observationCount == expectedRowCount, "evaluation omitted Data S1 outcomes")
        try require(evaluation.missingOutcomeCount == 0, "evaluation reported missing Data S1 outcomes")
        try require(
            evaluation.rmse.isFinite && evaluation.rmse >= 0
                && evaluation.mae.isFinite && evaluation.mae >= 0
                && evaluation.rSquared?.isFinite == true,
            "evaluation produced a missing or non-finite metric"
        )

        return LocalMLSelfTestSummary(
            command: "local-ml-self-test",
            status: "ok",
            dataset: dataset.name,
            datasetNormalizedSHA256: dataset.normalizedSHA256,
            rows: dataset.rows.count,
            target: dataset.headers[configuration.target],
            group: configuration.group.map { dataset.headers[$0] } ?? "",
            features: featureNames,
            candidateFamilies: report.metrics.map { $0.family.rawValue },
            folds: report.foldCount,
            winner: report.winner.rawValue,
            selectedCVRMSE: selectedMetric.rmse,
            trainingRows: artifact.trainingRowCount,
            encodedFeatures: artifact.encodedFeatureCount,
            artifactBytes: artifactJSON.count,
            artifactRoundTripExact: true,
            predictions: importedPrediction.predictions.count,
            finitePredictions: finitePredictionCount,
            predictionRoundTripExact: true,
            practiceData: importedPrediction.isPracticeData,
            evaluation: LocalMLSelfTestEvaluationSummary(
                observations: evaluation.observationCount,
                missingOutcomes: evaluation.missingOutcomeCount,
                rmse: evaluation.rmse,
                mae: evaluation.mae,
                rSquared: evaluation.rSquared
            )
        )
    }

    static func failureJSONLine(for error: Error) -> Data {
        struct Failure: Codable {
            let command: String
            let status: String
            let error: String
        }

        let failure = Failure(
            command: "local-ml-self-test",
            status: "failure",
            error: String(error.localizedDescription.prefix(512))
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        var data = (try? encoder.encode(failure))
            ?? Data(#"{"command":"local-ml-self-test","error":"encoding failure","status":"failure"}"#.utf8)
        data.append(0x0A)
        return data
    }

    private static func metricIsFinite(_ metric: SelectionMetric) -> Bool {
        metric.rmse.isFinite
            && metric.rmse >= 0
            && metric.mae.isFinite
            && metric.mae >= 0
            && metric.rSquared.isFinite
            && metric.foldRMSEStandardDeviation.isFinite
            && metric.foldRMSEStandardDeviation >= 0
            && metric.groupBalancedRMSE?.isFinite == true
            && metric.groupBalancedMAE?.isFinite == true
    }

    private static func require(_ condition: @autoclosure () -> Bool, _ detail: String) throws {
        guard condition() else { throw LocalMLSelfTestError.assertionFailed(detail) }
    }
}
