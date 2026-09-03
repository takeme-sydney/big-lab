import XCTest
@testable import PermeationLab

final class LocalModelWorkflowTests: XCTestCase {
    private let groupIndex = 0
    private let doseIndex = 1
    private let vehicleIndex = 2
    private let temperatureIndex = 3
    private let targetIndex = 4

    func testFiniteDoubleRejectsNaNAndInfinityAndNumericDetectionUsesFiniteValuesOnly() {
        XCTAssertEqual(finiteDouble("  1.25  "), 1.25)
        XCTAssertEqual(finiteDouble("-3.5e2"), -350)
        XCTAssertNil(finiteDouble(""))
        XCTAssertNil(finiteDouble("not-a-number"))
        XCTAssertNil(finiteDouble("NaN"))
        XCTAssertNil(finiteDouble("nan"))
        XCTAssertNil(finiteDouble("inf"))
        XCTAssertNil(finiteDouble("-infinity"))
        XCTAssertNil(finiteDouble("1e309"))

        let rows: [[String]] = (0..<10).map { index in
            let mostlyFinite = index == 9 ? "NaN" : String(index)
            let lessFinite = index >= 8 ? "Infinity" : String(index)
            return [mostlyFinite, lessFinite]
        }
        let dataset = GenericDataset(
            name: "finite-values.csv",
            headers: ["90 percent finite", "80 percent finite"],
            rows: rows
        )

        XCTAssertEqual(dataset.numericColumns, [0])
    }

    func testLeakageAuditBlocksIdentifiersAndDerivedOutcomesAndRecommendsSafeColumns() {
        let dataset = leakageDataset()
        let audit = DataLeakageAudit.review(
            dataset: dataset,
            target: 4,
            group: 0,
            features: [0, 1, 2, 3]
        )

        XCTAssertFalse(audit.canTrain)
        XCTAssertEqual(Set(audit.blockers.map(\.id)), ["identifier-0", "paired-outcome-3"])
        XCTAssertEqual(audit.blockers.first?.severity, .blocker)
        XCTAssertEqual(
            DataLeakageAudit.recommendedFeatures(dataset: dataset, target: 4, group: 0),
            [1, 2]
        )
        XCTAssertEqual(DataLeakageAudit.suggestedGroup(in: dataset, excluding: 4), 0)

        let rowWiseAudit = DataLeakageAudit.review(
            dataset: dataset,
            target: 4,
            group: nil,
            features: [1, 2]
        )
        XCTAssertTrue(rowWiseAudit.canTrain)
        XCTAssertTrue(rowWiseAudit.warnings.contains { $0.id == "no-group" })
    }

    func testGroupFoldAssignmentsAreDeterministicAndNeverSplitOneGroupAcrossFolds() {
        let groups = (0..<11).flatMap { group in
            Array(repeating: "run-\(group)", count: group.isMultiple(of: 2) ? 3 : 2)
        }
        let first = ModelSelectionEngine.makeFoldAssignments(groups: groups, rowCount: groups.count)
        let second = ModelSelectionEngine.makeFoldAssignments(groups: groups, rowCount: groups.count)

        XCTAssertEqual(first, second)
        XCTAssertEqual(first.count, groups.count)
        XCTAssertEqual(Set(first).count, 5)

        let indicesByGroup = Dictionary(grouping: groups.indices, by: { groups[$0] })
        for indices in indicesByGroup.values {
            XCTAssertEqual(Set(indices.map { first[$0] }).count, 1)
        }
        for fold in Set(first) {
            let trainingGroups = Set(groups.indices.filter { first[$0] != fold }.map { groups[$0] })
            let validationGroups = Set(groups.indices.filter { first[$0] == fold }.map { groups[$0] })
            XCTAssertTrue(trainingGroups.isDisjoint(with: validationGroups))
        }
    }

    func testHeadlessSelfTestConfigurationMatchesLocalMLScreenDataS1Defaults() throws {
        let dataset = GenericDataset(
            name: LocalMLSelfTestCommand.dataS1Name,
            headers: [
                "Drug", "Loading", "Molecular weight", "MN length", "Skin",
                "MN type", "Surface area", "Time", "Permeation percentage",
                "Permeation amount",
            ],
            rows: []
        )

        let configuration = try LocalMLSelfTestCommand.defaultConfiguration(for: dataset)

        XCTAssertEqual(configuration.target, 9)
        XCTAssertEqual(configuration.group, 0)
        XCTAssertEqual(configuration.features, Set(1...7))
        XCTAssertEqual(dataset.headers[configuration.target], LocalMLSelfTestCommand.expectedTargetName)
        XCTAssertEqual(
            configuration.group.map { dataset.headers[$0] },
            LocalMLSelfTestCommand.expectedGroupName
        )
        XCTAssertEqual(
            configuration.features.sorted().map { dataset.headers[$0] },
            LocalMLSelfTestCommand.expectedFeatureNames
        )
    }

    func testFoldPreprocessorFitsMedianAndCategoryLevelsFromTrainingRowsOnly() throws {
        let rows = [
            ["1", "aqueous"],
            ["3", "lipid"],
            ["1000", "held-out-only"]
        ]
        let preprocessor = FoldPreprocessor.fit(
            rows: rows,
            featureIndices: [0, 1],
            trainingIndices: [0, 1]
        )

        XCTAssertEqual(preprocessor.outputDimension, 2)
        XCTAssertEqual(preprocessor.transform(row: ["", "held-out-only"]), [2, 0])

        guard case .numeric(_, let median) = preprocessor.columns[0] else {
            return XCTFail("The numeric predictor was not recognized as numeric.")
        }
        XCTAssertEqual(median, 2)

        guard case .categorical(_, let levels) = preprocessor.columns[1] else {
            return XCTFail("The categorical predictor was not recognized as categorical.")
        }
        XCTAssertEqual(levels, ["aqueous", "lipid"])
        XCTAssertFalse(levels.contains("held-out-only"))
    }

    func testModelSelectionEvaluatesAllCandidatesWithGroupHoldout() throws {
        let dataset = workflowDataset()
        let report = try ModelSelectionEngine.evaluate(
            dataset: dataset,
            target: targetIndex,
            group: groupIndex,
            features: selectedFeatures
        )

        XCTAssertEqual(report.metrics.count, CandidateFamily.allCases.count)
        XCTAssertEqual(Set(report.metrics.map(\.family)), Set(CandidateFamily.allCases))
        XCTAssertEqual(report.winner, report.metrics.first?.family)
        XCTAssertEqual(report.foldCount, 5)
        XCTAssertTrue(report.usedGroupHoldout)
        XCTAssertEqual(report.observationCount, dataset.rows.count)
        XCTAssertEqual(report.featureCount, 4)
        XCTAssertTrue(report.excludedColumns.isEmpty)
        XCTAssertTrue(report.baselineRMSE.isFinite)
        XCTAssertGreaterThan(report.baselineRMSE, 0)
        XCTAssertTrue(report.metrics.allSatisfy {
            $0.rmse.isFinite
                && $0.mae.isFinite
                && $0.rSquared.isFinite
                && $0.foldRMSEStandardDeviation.isFinite
                && $0.groupBalancedRMSE?.isFinite == true
                && $0.groupBalancedMAE?.isFinite == true
        })
        XCTAssertTrue(zip(report.metrics, report.metrics.dropFirst()).allSatisfy { $0.rmse <= $1.rmse })
    }

    func testFinalTrainingUsesAllFiniteRowsAndRecordsValidationProvenance() throws {
        let dataset = workflowDataset()
        let report = try selectionReport(for: dataset)
        let artifact = try trainArtifact(dataset: dataset, report: report, family: .linear)
        let metric = try XCTUnwrap(report.metrics.first { $0.family == .linear })

        XCTAssertNoThrow(try artifact.validate())
        XCTAssertEqual(artifact.schemaVersion, LocalModelArtifact.currentSchemaVersion)
        XCTAssertEqual(artifact.engineVersion, LocalModelArtifact.engineVersion)
        XCTAssertEqual(artifact.datasetName, dataset.name)
        XCTAssertEqual(artifact.datasetNormalizedSHA256, dataset.normalizedSHA256)
        XCTAssertEqual(artifact.sourceHeaders, dataset.headers)
        XCTAssertEqual(artifact.targetName, dataset.headers[targetIndex])
        XCTAssertEqual(artifact.groupName, dataset.headers[groupIndex])
        XCTAssertEqual(artifact.selectedFeatureNames, ["dose", "vehicle", "temperature"])
        XCTAssertEqual(artifact.trainingRowCount, dataset.rows.count)
        XCTAssertEqual(artifact.encodedFeatureCount, 4)
        XCTAssertEqual(artifact.featureProfiles.map(\.name), artifact.selectedFeatureNames)
        XCTAssertEqual(artifact.family, .linear)
        XCTAssertEqual(artifact.validation.foldCount, report.foldCount)
        XCTAssertEqual(artifact.validation.selectedFamily, .linear)
        XCTAssertEqual(artifact.validation.selectedRMSE, metric.rmse)
        XCTAssertEqual(artifact.validation.selectedMAE, metric.mae)
        XCTAssertEqual(artifact.validation.selectedRSquared, metric.rSquared)
        XCTAssertEqual(artifact.validation.baselineRMSE, report.baselineRMSE)
        XCTAssertEqual(artifact.validation.selectedWasCVWinner, report.winner == .linear)
    }

    func testArtifactJSONRoundTripPreservesPredictionsExactly() throws {
        let dataset = workflowDataset()
        let report = try selectionReport(for: dataset)
        let original = try trainArtifact(dataset: dataset, report: report, family: .randomForest)

        let json = try original.encodedData()
        let decoded = try LocalModelArtifact.decode(json)
        let before = try LocalPredictionEngine.predict(dataset: dataset, with: original)
        let after = try LocalPredictionEngine.predict(dataset: dataset, with: decoded)

        XCTAssertEqual(decoded, original)
        XCTAssertEqual(after, before)
        XCTAssertEqual(after.predictions.map(\.predicted), before.predictions.map(\.predicted))
    }

    func testPredictionWithoutTargetProducesPredictionsWithoutEvaluation() throws {
        let training = workflowDataset()
        let report = try selectionReport(for: training)
        let artifact = try trainArtifact(dataset: training, report: report, family: .linear)
        let rows = training.rows.prefix(6).map { [$0[temperatureIndex], $0[vehicleIndex], $0[doseIndex]] }
        let predictionData = GenericDataset(
            name: "future-candidates.csv",
            headers: ["temperature", "vehicle", "dose"],
            rows: rows
        )

        let prediction = try LocalPredictionEngine.predict(dataset: predictionData, with: artifact)

        XCTAssertEqual(prediction.predictions.count, rows.count)
        XCTAssertTrue(prediction.predictions.allSatisfy { $0.predicted.isFinite && $0.actual == nil })
        XCTAssertNil(prediction.evaluation)
        XCTAssertFalse(prediction.diagnostics.hasWarnings)

        let csv = try XCTUnwrap(String(data: prediction.csvData(), encoding: .utf8))
        XCTAssertTrue(
            csv.hasPrefix(
                "Source CSV row,temperature,vehicle,dose,Predicted response,Model artifact ID\n"
            )
        )
        XCTAssertTrue(csv.contains(artifact.id.uuidString))
        XCTAssertFalse(csv.contains("Residual (actual - predicted)"))
    }

    func testPredictionWithActualValuesCalculatesEvaluationFromFiniteOutcomes() throws {
        let training = workflowDataset()
        let report = try selectionReport(for: training)
        let artifact = try trainArtifact(dataset: training, report: report, family: .linear)
        var rows = training.rows.prefix(6).map { [$0[targetIndex], $0[doseIndex], $0[vehicleIndex], $0[temperatureIndex]] }
        rows[5][0] = "NaN"
        let evaluationData = GenericDataset(
            name: "external-evaluation.csv",
            headers: ["response", "dose", "vehicle", "temperature"],
            rows: rows
        )

        let reportWithActuals = try LocalPredictionEngine.predict(dataset: evaluationData, with: artifact)
        let evaluation = try XCTUnwrap(reportWithActuals.evaluation)
        let finitePredictions = reportWithActuals.predictions.compactMap { prediction -> (Double, Double)? in
            prediction.actual.map { ($0, prediction.predicted) }
        }
        let errors = finitePredictions.map { $0.0 - $0.1 }
        let expectedRMSE = sqrt(errors.reduce(0) { $0 + $1 * $1 } / Double(errors.count))
        let expectedMAE = errors.reduce(0) { $0 + abs($1) } / Double(errors.count)

        XCTAssertEqual(evaluation.observationCount, 5)
        XCTAssertEqual(evaluation.missingOutcomeCount, 1)
        XCTAssertEqual(evaluation.rmse, expectedRMSE, accuracy: 1e-12)
        XCTAssertEqual(evaluation.mae, expectedMAE, accuracy: 1e-12)
        XCTAssertNotNil(evaluation.rSquared)
        XCTAssertEqual(reportWithActuals.predictions[5].actual, nil)
        XCTAssertEqual(
            try XCTUnwrap(reportWithActuals.predictions[0].residual),
            errors[0],
            accuracy: 1e-12
        )

        let csv = try XCTUnwrap(String(data: reportWithActuals.csvData(), encoding: .utf8))
        XCTAssertTrue(
            csv.hasPrefix(
                "Source CSV row,response,dose,vehicle,temperature,Predicted response,Residual (actual - predicted),Model artifact ID\n"
            )
        )
        XCTAssertTrue(csv.contains(artifact.id.uuidString))
    }

    func testPredictionRejectsMissingRequiredColumn() throws {
        let training = workflowDataset()
        let report = try selectionReport(for: training)
        let artifact = try trainArtifact(dataset: training, report: report, family: .linear)
        let missingVehicle = GenericDataset(
            name: "missing-vehicle.csv",
            headers: ["dose", "temperature"],
            rows: [["1.0", "32.0"]]
        )

        XCTAssertThrowsError(try LocalPredictionEngine.predict(dataset: missingVehicle, with: artifact)) { error in
            XCTAssertEqual(error as? LocalModelArtifactError, .missingColumns(["vehicle"]))
        }
    }

    func testPredictionReportsUnseenCategoriesMissingValuesAndOutsideTrainingRange() throws {
        let training = workflowDataset()
        let report = try selectionReport(for: training)
        let artifact = try trainArtifact(dataset: training, report: report, family: .linear)
        let shiftedData = GenericDataset(
            name: "shifted-candidates.csv",
            headers: ["dose", "vehicle", "temperature"],
            rows: [
                ["999", "new-vehicle", "-100"],
                ["NaN", "", "31"],
                [training.rows[0][doseIndex], training.rows[0][vehicleIndex], training.rows[0][temperatureIndex]]
            ]
        )

        let prediction = try LocalPredictionEngine.predict(dataset: shiftedData, with: artifact)

        XCTAssertTrue(prediction.diagnostics.hasWarnings)
        XCTAssertEqual(prediction.diagnostics.missingValueCounts, ["dose": 1, "vehicle": 1])
        XCTAssertEqual(prediction.diagnostics.unseenCategoryCounts, ["vehicle": 1])
        XCTAssertEqual(
            prediction.diagnostics.outsideTrainingRangeCounts,
            ["dose": 1, "temperature": 1]
        )
        XCTAssertTrue(prediction.predictions.allSatisfy { $0.predicted.isFinite })
        XCTAssertNil(prediction.evaluation)
    }

    func testSelectionTrainingAndPredictionAreDeterministic() throws {
        let dataset = workflowDataset()
        let firstReport = try selectionReport(for: dataset)
        let secondReport = try selectionReport(for: dataset)

        XCTAssertEqual(firstReport, secondReport)

        let firstArtifact = try trainArtifact(dataset: dataset, report: firstReport, family: .randomForest)
        let secondArtifact = try trainArtifact(dataset: dataset, report: secondReport, family: .randomForest)
        XCTAssertEqual(firstArtifact, secondArtifact)

        let firstPrediction = try LocalPredictionEngine.predict(dataset: dataset, with: firstArtifact)
        let secondPrediction = try LocalPredictionEngine.predict(dataset: dataset, with: secondArtifact)
        XCTAssertEqual(firstPrediction, secondPrediction)
    }

    func testFinalTrainingRejectsAValidationReportFromDifferentData() throws {
        let original = workflowDataset()
        let report = try selectionReport(for: original)
        var changedRows = original.rows
        changedRows[0][doseIndex] = "999"
        let changed = GenericDataset(
            name: original.name,
            headers: original.headers,
            rows: changedRows
        )

        XCTAssertThrowsError(
            try trainArtifact(dataset: changed, report: report, family: .linear)
        ) { error in
            guard let artifactError = error as? LocalModelArtifactError,
                  case .incompatibleArtifact(let reason) = artifactError else {
                return XCTFail("Expected a provenance mismatch, got \(error)")
            }
            XCTAssertTrue(reason.contains("validation report"))
        }
    }

    private var selectedFeatures: Set<Int> {
        [doseIndex, vehicleIndex, temperatureIndex]
    }

    private func selectionReport(for dataset: GenericDataset) throws -> ModelSelectionReport {
        try ModelSelectionEngine.evaluate(
            dataset: dataset,
            target: targetIndex,
            group: groupIndex,
            features: selectedFeatures
        )
    }

    private func trainArtifact(
        dataset: GenericDataset,
        report: ModelSelectionReport,
        family: CandidateFamily
    ) throws -> LocalModelArtifact {
        try ModelTrainingEngine.train(
            dataset: dataset,
            target: targetIndex,
            group: groupIndex,
            features: selectedFeatures,
            family: family,
            report: report,
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000042")!,
            trainedAt: Date(timeIntervalSince1970: 1_700_000_042)
        )
    }

    private func workflowDataset() -> GenericDataset {
        let vehicles = ["aqueous", "lipid", "gel"]
        let vehicleEffects = ["aqueous": 0.5, "lipid": 2.0, "gel": -0.75]
        let rows = (0..<10).flatMap { group in
            (0..<3).map { replicate -> [String] in
                let dose = Double(group + 1) * 0.5 + Double(replicate) * 0.1
                let vehicle = vehicles[(group + replicate) % vehicles.count]
                let temperature = 30 + Double((group + replicate) % 5)
                let response = 1.5
                    + 2.0 * dose
                    + vehicleEffects[vehicle, default: 0]
                    + 0.25 * temperature
                    + 0.03 * dose * dose
                return [
                    "run-\(group)",
                    String(format: "%.6f", locale: Locale(identifier: "en_US_POSIX"), dose),
                    vehicle,
                    String(format: "%.6f", locale: Locale(identifier: "en_US_POSIX"), temperature),
                    String(format: "%.12f", locale: Locale(identifier: "en_US_POSIX"), response)
                ]
            }
        }
        return GenericDataset(
            name: "synthetic-permeation.csv",
            headers: ["run_id", "dose", "vehicle", "temperature", "response"],
            rows: rows
        )
    }

    private func leakageDataset() -> GenericDataset {
        GenericDataset(
            name: "leakage-audit.csv",
            headers: ["run_id", "Drug", "Loading", "Permeation percentage", "Permeation amount"],
            rows: (0..<30).map { index in
                let loading = Double(index + 1)
                let percentage = Double((index % 10) + 1)
                return [
                    "run-\(index / 3)",
                    index.isMultiple(of: 2) ? "A" : "B",
                    String(loading),
                    String(percentage),
                    String(loading * percentage / 100)
                ]
            }
        )
    }
}
