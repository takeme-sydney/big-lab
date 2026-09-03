import XCTest
@testable import PermeationLab

final class ExperimentReproducibilityTests: XCTestCase {
    func testLanguageNamesFollowInterfaceLanguage() {
        XCTAssertEqual(AppLanguage.english.displayName(in: .english), "English")
        XCTAssertEqual(AppLanguage.japanese.displayName(in: .english), "Japanese")
        XCTAssertEqual(AppLanguage.english.displayName(in: .japanese), "英語")
        XCTAssertEqual(AppLanguage.japanese.displayName(in: .japanese), "日本語")
    }

    func testCanonicalDataS1AuditAndIdentity() {
        let dataset = TrainingDataSource.bundled
        let snapshot = ExperimentDatasetSnapshot.make(
            dataset: dataset,
            displayName: "Yuan 2023 · Data S1",
            isBundledData: true
        )

        XCTAssertTrue(dataset.audit.isValid)
        XCTAssertEqual(dataset.rows.count, 191)
        XCTAssertEqual(dataset.audit.columnCount, 11)
        XCTAssertEqual(dataset.audit.percentageAbove100Count, 1)
        XCTAssertLessThan(dataset.audit.maxAmountPercentageResidual, 0.00004)
        XCTAssertEqual(dataset.audit.drugCounts["lidocaine"], 73)
        XCTAssertEqual(dataset.audit.drugCounts["BSA"], 33)
        XCTAssertEqual(dataset.audit.drugCounts["copper ions"], 24)
        XCTAssertEqual(dataset.audit.drugCounts["GHK peptide"], 24)
        XCTAssertEqual(dataset.audit.drugCounts["Rhodamine B"], 19)
        XCTAssertEqual(dataset.audit.drugCounts["caffeine"], 18)
        XCTAssertTrue(snapshot.isCanonicalPaperDataset)
        XCTAssertEqual(snapshot.sha256, ExperimentDatasetIdentity.canonicalPaperSHA256)
        XCTAssertEqual(snapshot.sha256Basis, .bundledRawCSVBytes)
        XCTAssertEqual(snapshot.normalizedSHA256.count, 64)

        let semanticallyMatchingImport = ExperimentDatasetSnapshot.make(
            dataset: dataset,
            displayName: "imported-copy.csv",
            isBundledData: false
        )
        XCTAssertTrue(semanticallyMatchingImport.isCanonicalPaperDataset)
        XCTAssertEqual(semanticallyMatchingImport.sha256Basis, .normalizedParsedValues)
        XCTAssertEqual(semanticallyMatchingImport.sha256, semanticallyMatchingImport.normalizedSHA256)
        XCTAssertNotEqual(semanticallyMatchingImport.sha256, ExperimentDatasetIdentity.canonicalPaperSHA256)
    }

    func testPublishedStyleSplitIsDeterministicAndComplete() throws {
        let dataset = TrainingDataSource.bundled
        let configuration = ExperimentConfiguration(seed: 0)
        let first = try ExperimentRunner.makeSplit(rows: dataset.rows, configuration: configuration)
        let second = try ExperimentRunner.makeSplit(rows: dataset.rows, configuration: configuration)

        XCTAssertEqual(first, second)
        XCTAssertEqual(first.trainingCount, 134)
        XCTAssertEqual(first.testCount, 57)
        XCTAssertTrue(Set(first.trainRowIDs).isDisjoint(with: Set(first.testRowIDs)))
        XCTAssertEqual(Set(first.trainRowIDs + first.testRowIDs), Set(dataset.rows.map(\.id)))

        var differentSeed = configuration
        differentSeed.seed = 1
        let third = try ExperimentRunner.makeSplit(rows: dataset.rows, configuration: differentSeed)
        XCTAssertNotEqual(first.trainRowIDs, third.trainRowIDs)
    }

    func testFixedConfigurationProducesIdenticalMetricsAndPredictions() throws {
        let dataset = TrainingDataSource.bundled
        let configuration = ExperimentConfiguration(outcome: .amount, seed: 0)
        let runID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let start = Date(timeIntervalSince1970: 1_700_000_000)

        let first = try ExperimentRunner.execute(
            dataset: dataset,
            displayName: "Yuan 2023 · Data S1",
            isBundledData: true,
            configuration: configuration,
            runID: runID,
            startedAt: start
        )
        let second = try ExperimentRunner.execute(
            dataset: dataset,
            displayName: "Yuan 2023 · Data S1",
            isBundledData: true,
            configuration: configuration,
            runID: runID,
            startedAt: start
        )

        XCTAssertEqual(first.split, second.split)
        XCTAssertEqual(first.metrics, second.metrics)
        XCTAssertEqual(first.predictions, second.predictions)
        XCTAssertEqual(first.metrics.count, 3)
        XCTAssertEqual(first.predictions.count, 171)
        XCTAssertEqual(first.split.trainingCount, 134)
        XCTAssertEqual(first.split.testCount, 57)
        XCTAssertEqual(first.leakageAudit.sharedPredictorCombinationCount, 28)
        XCTAssertEqual(first.evidenceLevel, .publishedProtocolReconstruction)
        XCTAssertTrue(first.canDisplayTable4Reference(in: .paperEvidence))
        XCTAssertFalse(first.canDisplayTable4Reference(in: .myExperiment))
        for metric in first.metrics {
            XCTAssertEqual(
                metric.rootSumSquaredError,
                metric.rmse * sqrt(Double(metric.observationCount)),
                accuracy: 1e-9
            )
            XCTAssertNotNil(metric.rSquared)
        }

        let export = try ExperimentExportEncoder.data(for: first)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let manifest = try decoder.decode(ExperimentExportManifest.self, from: export)
        XCTAssertEqual(manifest.runID, runID)
        XCTAssertEqual(manifest.dataset.sha256, ExperimentDatasetIdentity.canonicalPaperSHA256)
        XCTAssertEqual(manifest.researchMode, .paperEvidence)
        XCTAssertEqual(manifest.scientificStatus, .paperSourceVerified)
        XCTAssertEqual(manifest.table4ReferenceStatus, .eligibleReportedReference)
        XCTAssertFalse(manifest.exactPaperReplayAvailable)
        XCTAssertEqual(manifest.trainRowIDs, first.split.trainRowIDs)
        XCTAssertEqual(manifest.predictions.count, 171)
    }

    func testEvidencePolicyRequiresPaperModeRawSourceAndFixedProtocol() throws {
        let dataset = TrainingDataSource.bundled
        let configuration = ExperimentConfiguration(seed: 0)
        let split = try ExperimentRunner.makeSplit(rows: dataset.rows, configuration: configuration)
        let paper = ExperimentDatasetSnapshot.make(
            dataset: dataset,
            displayName: "Yuan 2023 · Data S1",
            isBundledData: true,
            researchMode: .paperEvidence,
            scientificStatus: .paperSourceVerified
        )
        let personalCopy = ExperimentDatasetSnapshot.make(
            dataset: dataset,
            displayName: "my-copy.csv",
            isBundledData: false,
            researchMode: .myExperiment,
            scientificStatus: .userProvidedUnvalidated
        )
        let unverifiedPaper = ExperimentDatasetSnapshot.make(
            dataset: dataset,
            displayName: "inconsistent-paper.csv",
            isBundledData: true,
            researchMode: .paperEvidence,
            scientificStatus: .userProvidedUnvalidated
        )
        let normalizedPaperCopy = ExperimentDatasetSnapshot.make(
            dataset: dataset,
            displayName: "normalized-paper-copy.csv",
            isBundledData: false,
            researchMode: .paperEvidence,
            scientificStatus: .paperSourceVerified
        )

        XCTAssertEqual(
            ExperimentEvidencePolicy.table4ReferenceStatus(
                dataset: paper,
                configuration: configuration,
                split: split,
                hyperparameters: configuration.preset
            ),
            .eligibleReportedReference
        )
        XCTAssertEqual(
            ExperimentEvidencePolicy.table4ReferenceStatus(
                dataset: personalCopy,
                configuration: configuration,
                split: split,
                hyperparameters: configuration.preset
            ),
            .unavailableOutsidePaperEvidence
        )
        XCTAssertEqual(
            ExperimentEvidencePolicy.evidenceLevel(
                dataset: personalCopy,
                configuration: configuration,
                split: split,
                hyperparameters: configuration.preset
            ),
            .compatibleDatasetExperiment
        )
        XCTAssertEqual(
            ExperimentEvidencePolicy.table4ReferenceStatus(
                dataset: unverifiedPaper,
                configuration: configuration,
                split: split,
                hyperparameters: configuration.preset
            ),
            .unavailableNoncanonicalSource
        )
        XCTAssertEqual(
            ExperimentEvidencePolicy.table4ReferenceStatus(
                dataset: normalizedPaperCopy,
                configuration: configuration,
                split: split,
                hyperparameters: configuration.preset
            ),
            .unavailableNoncanonicalSource
        )

        let overlappingSplit = ExperimentSplit(
            trainRowIDs: Array(repeating: 1, count: 134),
            testRowIDs: Array(repeating: 1, count: 57),
            trainDrugCounts: split.trainDrugCounts,
            testDrugCounts: split.testDrugCounts
        )
        XCTAssertEqual(
            ExperimentEvidencePolicy.table4ReferenceStatus(
                dataset: paper,
                configuration: configuration,
                split: overlappingSplit,
                hyperparameters: configuration.preset
            ),
            .unavailableProtocolVariation
        )

        var changedSeed = configuration
        changedSeed.seed = 1
        let changedSplit = try ExperimentRunner.makeSplit(rows: dataset.rows, configuration: changedSeed)
        XCTAssertEqual(
            ExperimentEvidencePolicy.table4ReferenceStatus(
                dataset: paper,
                configuration: changedSeed,
                split: changedSplit,
                hyperparameters: changedSeed.preset
            ),
            .unavailableProtocolVariation
        )
        XCTAssertEqual(
            ExperimentEvidencePolicy.table4ReferenceStatus(
                dataset: paper,
                configuration: configuration,
                split: changedSplit,
                hyperparameters: configuration.preset
            ),
            .unavailableProtocolVariation,
            "A different 134/57 partition must not pass merely because the configuration says seed 0"
        )
    }

    func testMyExperimentOnCanonicalValuesNeverClaimsPaperEvidence() throws {
        let result = try ExperimentRunner.execute(
            dataset: TrainingDataSource.bundled,
            displayName: "my-canonical-copy.csv",
            isBundledData: false,
            researchMode: .myExperiment,
            scientificStatus: .userProvidedUnvalidated,
            configuration: ExperimentConfiguration(seed: 0)
        )

        XCTAssertTrue(result.dataset.isCanonicalPaperDataset)
        XCTAssertFalse(result.dataset.isBundledSource)
        XCTAssertEqual(result.dataset.resolvedResearchMode, .myExperiment)
        XCTAssertEqual(result.evidenceLevel, .compatibleDatasetExperiment)
        XCTAssertEqual(result.table4ReferenceStatus, .unavailableOutsidePaperEvidence)
        XCTAssertFalse(result.isTable4ReferenceComparisonEligible)
        XCTAssertFalse(result.canDisplayTable4Reference(in: .paperEvidence))
        XCTAssertFalse(result.canDisplayTable4Reference(in: .myExperiment))

        let data = try ExperimentExportEncoder.data(for: result)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let manifest = try decoder.decode(ExperimentExportManifest.self, from: data)
        XCTAssertEqual(manifest.researchMode, .myExperiment)
        XCTAssertEqual(manifest.scientificStatus, .userProvidedUnvalidated)
        XCTAssertEqual(manifest.table4ReferenceStatus, .unavailableOutsidePaperEvidence)
        XCTAssertFalse(manifest.exactPaperReplayAvailable)
    }

    func testLegacyStoredEvidenceIsReclassifiedByCurrentPolicy() throws {
        let result = try ExperimentRunner.execute(
            dataset: TrainingDataSource.bundled,
            displayName: "legacy-personal-copy.csv",
            isBundledData: false,
            researchMode: .myExperiment,
            scientificStatus: .userProvidedUnvalidated,
            configuration: ExperimentConfiguration(seed: 0)
        )
        var object = try XCTUnwrap(
            JSONSerialization.jsonObject(with: JSONEncoder().encode(result)) as? [String: Any]
        )
        object["evidenceLevel"] = ExperimentEvidenceLevel.publishedProtocolReconstruction.rawValue
        var dataset = try XCTUnwrap(object["dataset"] as? [String: Any])
        dataset.removeValue(forKey: "researchMode")
        dataset.removeValue(forKey: "scientificStatus")
        object["dataset"] = dataset

        let legacyData = try JSONSerialization.data(withJSONObject: object, options: [.sortedKeys])
        let decoded = try JSONDecoder().decode(ExperimentRunResult.self, from: legacyData)

        XCTAssertEqual(decoded.evidenceLevel, .publishedProtocolReconstruction)
        XCTAssertEqual(decoded.dataset.resolvedResearchMode, .myExperiment)
        XCTAssertEqual(decoded.policyEvidenceLevel, .compatibleDatasetExperiment)
        XCTAssertEqual(decoded.table4ReferenceStatus, .unavailableOutsidePaperEvidence)
        XCTAssertFalse(decoded.exactPaperReplayAvailable)

        let manifest = ExperimentExportManifest(result: decoded)
        XCTAssertEqual(manifest.evidenceLevel, .compatibleDatasetExperiment)
        XCTAssertEqual(manifest.table4ReferenceStatus, .unavailableOutsidePaperEvidence)
        XCTAssertFalse(manifest.exactPaperReplayAvailable)
    }

    func testLeaveOneDrugOutFullyIsolatesCaffeine() throws {
        let dataset = TrainingDataSource.bundled
        let configuration = ExperimentConfiguration(
            outcome: .percentage,
            validationStrategy: .leaveOneDrugOut,
            seed: 0,
            heldOutDrug: .caffeine
        )
        let split = try ExperimentRunner.makeSplit(rows: dataset.rows, configuration: configuration)
        let audit = ExperimentRunner.auditSplit(
            rows: dataset.rows,
            split: split,
            heldOutDrug: .caffeine
        )

        XCTAssertEqual(split.trainingCount, 173)
        XCTAssertEqual(split.testCount, 18)
        XCTAssertEqual(split.trainDrugCounts[Drug.caffeine.sourceName] ?? 0, 0)
        XCTAssertEqual(split.testDrugCounts[Drug.caffeine.sourceName], 18)
        XCTAssertEqual(audit.heldOutDrugTrainingCount, 0)
        XCTAssertEqual(audit.heldOutDrugTestCount, 18)
        XCTAssertEqual(audit.sharedPredictorCombinationCount, 0)
        XCTAssertEqual(audit.heldOutDrugIsIsolated, true)
    }

    func testFickPreviewIsStableNonnegativeAndMonotonic() throws {
        var configuration = FickPreviewConfiguration()
        configuration.durationHours = 0.25
        let result = try FickPreviewEngine.run(configuration)

        let stabilityNumber = configuration.diffusionCoefficient
            * result.actualTimeStepMinutes
            * (2 / (configuration.gridSize * configuration.gridSize))
        XCTAssertLessThanOrEqual(stabilityNumber, 0.5)
        XCTAssertTrue(result.points.allSatisfy { $0.permeatedAmount >= 0 })
        XCTAssertTrue(zip(result.points, result.points.dropFirst()).allSatisfy {
            $0.permeatedAmount <= $1.permeatedAmount
        })
        XCTAssertGreaterThan(result.finalAmount, 0)
        XCTAssertLessThanOrEqual(result.finalAmount, configuration.loadedMass)
        XCTAssertEqual(result.finalPercentage, 100 * result.finalAmount / configuration.loadedMass, accuracy: 1e-12)
        XCTAssertEqual(
            result.remainingMass + result.finalAmount,
            configuration.loadedMass,
            accuracy: 1e-8
        )
        XCTAssertEqual(result.massBalanceError, 0, accuracy: 1e-8)
    }

    func testFickValidationProxyIsDeterministicLeakageGuardedAndExportable() throws {
        let dataset = TrainingDataSource.bundled
        let configuration = FickValidationConfiguration.default
        let runID = UUID(uuidString: "00000000-0000-0000-0000-000000000085")!
        let startedAt = Date(timeIntervalSince1970: 1_700_000_085)

        let first = try FickValidationExperiment.run(
            dataset: dataset,
            displayName: "my-fick-validation.csv",
            isBundledData: false,
            researchMode: .myExperiment,
            scientificStatus: .userProvidedUnvalidated,
            configuration: configuration,
            runID: runID,
            startedAt: startedAt
        )
        let second = try FickValidationExperiment.run(
            dataset: dataset,
            displayName: "my-fick-validation.csv",
            isBundledData: false,
            researchMode: .myExperiment,
            scientificStatus: .userProvidedUnvalidated,
            configuration: configuration,
            runID: runID,
            startedAt: startedAt
        )

        XCTAssertEqual(first.configuration, second.configuration)
        XCTAssertEqual(first.pooledMetric, second.pooledMetric)
        XCTAssertEqual(first.familyMetrics, second.familyMetrics)
        XCTAssertEqual(first.confidenceInterval, second.confidenceInterval)
        XCTAssertEqual(first.predictions, second.predictions)
        XCTAssertEqual(first.folds, second.folds)
        XCTAssertEqual(first.leaveOneFamilyOutStress, second.leaveOneFamilyOutStress)

        XCTAssertEqual(first.eligibleFamilyCount, 3)
        XCTAssertEqual(first.eligibleConditionCount, 12)
        XCTAssertEqual(first.eligibleObservationCount, 112)
        XCTAssertEqual(first.excludedFamilyCount, 6)
        XCTAssertEqual(first.excludedConditionCount, 6)
        XCTAssertEqual(first.excludedObservationCount, 79)
        XCTAssertEqual(first.folds.count, 12)
        XCTAssertEqual(first.predictions.count, 112)
        XCTAssertEqual(first.familyMetrics.count, 3)
        XCTAssertEqual(FickValidationExperiment.fraction(0), 0, accuracy: 0)

        XCTAssertEqual(first.pooledMetric.rSquared ?? .nan, 0.89514215, accuracy: 1e-6)
        XCTAssertEqual(first.pooledMetric.rmse, 9.5987910, accuracy: 1e-6)
        XCTAssertEqual(first.pooledMetric.mae, 6.7182313, accuracy: 1e-6)
        XCTAssertTrue(first.pointPass)
        XCTAssertFalse(first.confidencePass)
        XCTAssertLessThan(
            try XCTUnwrap(first.confidenceInterval.oneSidedLower),
            configuration.targetRSquared
        )
        XCTAssertEqual(first.confidenceInterval.validReplicateCount, 20_000)
        XCTAssertEqual(first.confidenceInterval.clusterCount, 12)
        XCTAssertEqual(
            try XCTUnwrap(first.confidenceInterval.twoSidedLower),
            0.7391961375054618,
            accuracy: 1e-12
        )
        XCTAssertEqual(
            try XCTUnwrap(first.confidenceInterval.twoSidedUpper),
            0.9469124716928526,
            accuracy: 1e-12
        )
        XCTAssertEqual(
            try XCTUnwrap(first.confidenceInterval.oneSidedLower),
            0.7804721110215499,
            accuracy: 1e-12
        )
        XCTAssertEqual(
            try XCTUnwrap(first.confidenceInterval.probabilityAtOrAboveTarget),
            0.7736,
            accuracy: 1e-12
        )

        for fold in first.folds {
            XCTAssertFalse(fold.trainingConditionIDs.contains(fold.heldOutCondition.id))
            XCTAssertTrue(Set(fold.trainingRowIDs).isDisjoint(with: Set(fold.testRowIDs)))
            XCTAssertGreaterThanOrEqual(fold.fittedAmplitude, 0)
            XCTAssertLessThanOrEqual(fold.fittedAmplitude, 100)
            XCTAssertGreaterThanOrEqual(fold.fittedRate, 1e-8)
            XCTAssertLessThanOrEqual(fold.fittedRate, 100)
            XCTAssertTrue(fold.trainingSSE.isFinite)
            XCTAssertTrue(first.predictions.filter { $0.foldID == fold.id }.allSatisfy {
                $0.condition == fold.heldOutCondition
            })
        }
        XCTAssertTrue(first.predictions.allSatisfy {
            $0.observedPercentage.isFinite
                && $0.predictedPercentage.isFinite
                && $0.timeHours.isFinite
                && $0.timeHours >= 0
                && $0.predictedPercentage >= 0
                && $0.predictedPercentage <= 100
        })

        let stress = first.leaveOneFamilyOutStress
        XCTAssertEqual(stress.familyCount, 9)
        XCTAssertEqual(stress.observationCount, 191)
        XCTAssertEqual(stress.folds.count, 9)
        XCTAssertEqual(stress.predictions.count, 191)
        XCTAssertEqual(stress.metric.rSquared ?? .nan, -0.1394, accuracy: 0.01)
        XCTAssertTrue(stress.predictions.allSatisfy { $0.predictedPercentage.isFinite })
        XCTAssertTrue(stress.folds.allSatisfy {
            !$0.trainingFamilyIDs.contains($0.heldOutFamily.id)
                && Set($0.trainingRowIDs).isDisjoint(with: Set($0.testRowIDs))
                && (0...100).contains($0.fittedAmplitude)
                && (1e-8...100).contains($0.fittedRate)
        })

        XCTAssertEqual(first.dataset.resolvedResearchMode, .myExperiment)
        XCTAssertEqual(first.dataset.resolvedScientificStatus, .userProvidedUnvalidated)
        XCTAssertEqual(first.evidenceLevel, .exploratoryProxyConditionCrossValidation)
        XCTAssertFalse(first.exactPaperReplayAvailable)
        XCTAssertTrue(first.limitations.contains { $0.code == "not_original_2d_fick_or_table4" })

        let export = try FickValidationExportEncoder.data(for: first)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(FickValidationRunResult.self, from: export)
        XCTAssertEqual(decoded.id, first.id)
        XCTAssertEqual(decoded.pooledMetric, first.pooledMetric)
        XCTAssertEqual(decoded.confidenceInterval, first.confidenceInterval)
        XCTAssertEqual(decoded.predictions, first.predictions)
        XCTAssertTrue(decoded.pointPass)
        XCTAssertFalse(decoded.confidencePass)

        let diagnostics = try FickValidationDiagnosticsEngine.make(
            run: first,
            dataset: dataset
        )
        let injectedDisplayName = "EXTERNAL VALIDATION PROVED R2 0.99"
        let misleadinglyNamedRun = try mutatedFickRun(first) { object in
            var snapshot = object["dataset"] as! [String: Any]
            snapshot["displayName"] = injectedDisplayName
            object["dataset"] = snapshot
        }
        let safeClaim = FickValidationEvidenceDashboard(
            language: .english,
            result: misleadinglyNamedRun,
            diagnostics: diagnostics
        ).safeClaim
        XCTAssertFalse(safeClaim.contains(injectedDisplayName))
        XCTAssertTrue(safeClaim.contains(String(first.dataset.normalizedSHA256.prefix(12))))
        let fickSummary = try XCTUnwrap(diagnostics.comparatorSummaries.first {
            $0.comparator == .fickProxy
        })
        let controlSummary = try XCTUnwrap(diagnostics.comparatorSummaries.first {
            $0.comparator == .familyTimeControl
        })
        XCTAssertEqual(
            try XCTUnwrap(fickSummary.rowPooledMetric.rSquared),
            0.895142155698,
            accuracy: 1e-10
        )
        XCTAssertEqual(
            try XCTUnwrap(fickSummary.conditionBalancedMetric.rSquared),
            0.861608373552,
            accuracy: 1e-10
        )
        XCTAssertEqual(
            try XCTUnwrap(fickSummary.familyCenteredRSquared),
            0.592792117937,
            accuracy: 1e-10
        )
        XCTAssertEqual(
            try XCTUnwrap(fickSummary.macroFamilyRSquared),
            0.338346474651,
            accuracy: 1e-10
        )
        XCTAssertEqual(
            try XCTUnwrap(controlSummary.rowPooledMetric.rSquared),
            0.908852726846,
            accuracy: 1e-10
        )
        XCTAssertEqual(controlSummary.rowPooledMetric.rmse, 8.9492762282, accuracy: 1e-9)
        XCTAssertEqual(
            try XCTUnwrap(controlSummary.conditionBalancedMetric.rSquared),
            0.896746956861,
            accuracy: 1e-10
        )
        XCTAssertEqual(
            try XCTUnwrap(controlSummary.familyCenteredRSquared),
            0.646036132976,
            accuracy: 1e-10
        )
        XCTAssertEqual(
            try XCTUnwrap(controlSummary.macroFamilyRSquared),
            0.367348826058,
            accuracy: 1e-10
        )
        XCTAssertEqual(diagnostics.baselinePredictions.count, first.predictions.count)
        XCTAssertEqual(diagnostics.baselineModeCounts["exactTrainingTime"], 84)
        XCTAssertEqual(diagnostics.baselineModeCounts["linearInterpolation"], 9)
        XCTAssertEqual(diagnostics.baselineModeCounts["endpointHold"], 19)
        XCTAssertEqual(
            try XCTUnwrap(diagnostics.tss.betweenFamilyShare),
            0.742495543626,
            accuracy: 1e-10
        )
        XCTAssertEqual(diagnostics.conditions.count, 12)
        XCTAssertEqual(diagnostics.conditions.filter(\.fickWinsRMSE).count, 4)
        XCTAssertEqual(diagnostics.conditions.compactMap(\.fickRSquaredMeetsTarget).count, 11)
        XCTAssertEqual(
            diagnostics.conditions.compactMap(\.fickRSquaredMeetsTarget).filter { $0 }.count,
            2
        )
        let bsaInfluence = try XCTUnwrap(diagnostics.familyInfluence.first {
            $0.family.drugName == "BSA"
        })
        XCTAssertEqual(
            try XCTUnwrap(bsaInfluence.rowPooledRSquaredWithoutFamily),
            0.527606,
            accuracy: 1e-6
        )
        XCTAssertEqual(diagnostics.hierarchy.rawReferencedRowCount, 7)
        XCTAssertEqual(diagnostics.hierarchy.totalRowCount, 191)
        XCTAssertEqual(diagnostics.hierarchy.sourceBlockCount, 7)
        XCTAssertEqual(diagnostics.hierarchy.uniqueCitationCount, 6)
        XCTAssertEqual(diagnostics.hierarchy.eligibleSourceCount, 3)
        XCTAssertEqual(diagnostics.hierarchy.eligibleFamilySourceConfoundedCount, 3)
        XCTAssertFalse(diagnostics.hierarchy.hasExperimentRunID)
        XCTAssertFalse(diagnostics.hierarchy.hasPermeationCurveID)
        XCTAssertEqual(
            diagnostics.gates.first { $0.id == "row-pooled-point" }?.status,
            .met
        )
        XCTAssertEqual(
            diagnostics.gates.first { $0.id == "calculation-completed" }?.measuredValue,
            303
        )
        XCTAssertEqual(
            diagnostics.gates.first { $0.id == "simple-baseline" }?.status,
            .notMet
        )
        XCTAssertEqual(
            try XCTUnwrap(diagnostics.gates.first {
                $0.id == "simple-baseline"
            }?.measuredValue),
            -0.053244015039,
            accuracy: 1e-10
        )
        XCTAssertEqual(
            diagnostics.gates.first { $0.id == "external-confirmation" }?.status,
            .unavailable
        )
        XCTAssertEqual(
            Dictionary(uniqueKeysWithValues: diagnostics.gates.map { ($0.id, $0.status) }),
            [
                "calculation-completed": .met,
                "row-pooled-point": .met,
                "aggregation-robustness": .notMet,
                "simple-baseline": .notMet,
                "every-family": .notMet,
                "independent-run-curve": .unavailable,
                "external-confirmation": .unavailable,
            ]
        )
        XCTAssertEqual(diagnostics.recomputedFamilyMetrics, first.familyMetrics)
        XCTAssertEqual(diagnostics.leaveOneFamilyOutMetric, first.leaveOneFamilyOutStress.metric)

        let reasons = FickPublicationExplanation.make(result: first, diagnostics: diagnostics)
        let expectedReasonIDs = [
            "pooled-variance",
            "family-results",
            "simple-control",
            "lower-reference",
            "partial-coverage",
            "unseen-family",
            "independence",
            "model-identity",
        ]
        XCTAssertEqual(reasons.map(\.id), expectedReasonIDs)
        XCTAssertEqual(Set(reasons.map(\.id)).count, reasons.count)
        XCTAssertEqual(
            ResearchHomeView.fixedDataS1PublicationReasons.map(\.id),
            expectedReasonIDs,
            "The fixed My Research explanation and the active-run explanation must cover the same audited reasons."
        )
        for reason in reasons + ResearchHomeView.fixedDataS1PublicationReasons {
            XCTAssertFalse(reason.title.japanese.isEmpty)
            XCTAssertFalse(reason.title.english.isEmpty)
            XCTAssertFalse(reason.evidence.japanese.isEmpty)
            XCTAssertFalse(reason.evidence.english.isEmpty)
            XCTAssertFalse(reason.plainMeaning.japanese.isEmpty)
            XCTAssertFalse(reason.plainMeaning.english.isEmpty)
            XCTAssertFalse(reason.auditMeaning.japanese.isEmpty)
            XCTAssertFalse(reason.auditMeaning.english.isEmpty)
        }

        let reasonsByID = Dictionary(uniqueKeysWithValues: reasons.map { ($0.id, $0) })
        let pooledReason = try XCTUnwrap(reasonsByID["pooled-variance"])
        XCTAssertTrue(pooledReason.evidence.english.contains("74.25%"))
        XCTAssertTrue(pooledReason.auditMeaning.english.contains("0.895"))
        XCTAssertTrue(pooledReason.auditMeaning.english.contains("0.862"))
        XCTAssertTrue(pooledReason.auditMeaning.english.contains("0.593"))
        XCTAssertTrue(pooledReason.auditMeaning.english.contains("0.338"))

        let familyReason = try XCTUnwrap(reasonsByID["family-results"])
        XCTAssertTrue(familyReason.evidence.english.contains("0.689"))
        XCTAssertTrue(familyReason.evidence.english.contains("−0.101"))
        XCTAssertTrue(familyReason.evidence.english.contains("0.427"))

        let controlReason = try XCTUnwrap(reasonsByID["simple-control"])
        XCTAssertTrue(controlReason.evidence.english.contains("0.895"))
        XCTAssertTrue(controlReason.evidence.english.contains("0.909"))

        let lowerReason = try XCTUnwrap(reasonsByID["lower-reference"])
        XCTAssertTrue(lowerReason.evidence.english.contains("0.780"))
        XCTAssertTrue(lowerReason.evidence.english.contains("0.850"))
        XCTAssertTrue(lowerReason.auditMeaning.english.contains("descriptive percentile"))
        XCTAssertTrue(lowerReason.auditMeaning.english.contains("not a confirmatory 95% confidence interval"))

        let coverageReason = try XCTUnwrap(reasonsByID["partial-coverage"])
        for token in ["3/9", "12/18", "112/191"] {
            XCTAssertTrue(coverageReason.evidence.english.contains(token))
        }
        XCTAssertTrue(coverageReason.auditMeaning.english.contains("post hoc"))

        let unseenReason = try XCTUnwrap(reasonsByID["unseen-family"])
        XCTAssertTrue(unseenReason.evidence.english.contains("−0.136"))

        let independenceReason = try XCTUnwrap(reasonsByID["independence"])
        XCTAssertTrue(independenceReason.evidence.english.contains("experiment_run_id"))
        XCTAssertTrue(independenceReason.evidence.english.contains("permeation_curve_id"))
        XCTAssertTrue(independenceReason.evidence.english.contains("no external validation"))

        let modelReason = try XCTUnwrap(reasonsByID["model-identity"])
        XCTAssertTrue(modelReason.evidence.english.contains("time-only finite-slab proxy"))
        XCTAssertTrue(modelReason.auditMeaning.english.contains("not the paper's 2D solver"))

        let fixedPooledReason = try XCTUnwrap(
            ResearchHomeView.fixedDataS1PublicationReasons.first { $0.id == "pooled-variance" }
        )
        XCTAssertTrue(fixedPooledReason.auditMeaning.english.contains("condition-balanced 0.861608"))
        XCTAssertEqual(
            try FickValidationExperiment.recomputeConfidenceInterval(
                predictions: Array(first.predictions.reversed()),
                configuration: configuration
            ),
            first.confidenceInterval
        )
        XCTAssertNil(FickValidationDiagnosticsEngine.meanRequiringAllFinite([0.9, nil]))
        XCTAssertNil(FickValidationDiagnosticsEngine.meanRequiringAllFinite([0.9, .nan]))
        XCTAssertEqual(
            try XCTUnwrap(
                FickValidationDiagnosticsEngine.meanRequiringAllFinite([0.8, 0.9])
            ),
            0.85,
            accuracy: 1e-12
        )
        XCTAssertEqual(
            FickValidationDiagnosticsEngine.exploratoryBaselineStatus(
                rSquaredDeltas: [0, 0, 0, 0],
                fickRMSE: 1,
                controlRMSE: 1,
                fickMAE: 1,
                controlMAE: 1
            ),
            .unavailable
        )
        XCTAssertEqual(
            FickValidationDiagnosticsEngine.exploratoryBaselineStatus(
                rSquaredDeltas: [0.01, 0.01, 0.01, 0.01],
                fickRMSE: 0.9,
                controlRMSE: 1,
                fickMAE: 0.9,
                controlMAE: 1
            ),
            .unavailable
        )
        XCTAssertEqual(
            FickValidationDiagnosticsEngine.exploratoryBaselineStatus(
                rSquaredDeltas: [0.01, -0.01, 0.01, 0.01],
                fickRMSE: 0.9,
                controlRMSE: 1,
                fickMAE: 0.9,
                controlMAE: 1
            ),
            .notMet
        )

        let auditExport = try FickValidationAuditExportEncoder.data(
            for: first,
            dataset: dataset
        )
        let repeatedAuditExport = try FickValidationAuditExportEncoder.data(
            for: first,
            dataset: dataset
        )
        XCTAssertEqual(auditExport, repeatedAuditExport)
        let decodedAudit = try JSONDecoder().decode(
            FickValidationAuditSidecar.self,
            from: auditExport
        )
        XCTAssertEqual(decodedAudit.schemaVersion, "1.1")
        XCTAssertEqual(decodedAudit.auditedRunID, first.id)
        XCTAssertEqual(decodedAudit.auditedRunSchemaVersion, "1.1")
        XCTAssertEqual(decodedAudit.auditedRunExportSHA256.count, 64)
        XCTAssertEqual(
            decodedAudit.diagnosticsEngineVersion,
            FickValidationDiagnosticsEngine.version
        )
        XCTAssertEqual(decodedAudit.diagnostics, diagnostics)
        XCTAssertEqual(
            try FickValidationAuditExportEncoder.verify(
                sidecarData: auditExport,
                runExportData: export,
                dataset: dataset
            ),
            decodedAudit
        )
        var changedAuditObject = try XCTUnwrap(
            JSONSerialization.jsonObject(with: auditExport) as? [String: Any]
        )
        var changedDiagnostics = changedAuditObject["diagnostics"] as! [String: Any]
        var changedGates = changedDiagnostics["gates"] as! [[String: Any]]
        changedGates[0]["status"] = "notMet"
        changedDiagnostics["gates"] = changedGates
        changedAuditObject["diagnostics"] = changedDiagnostics
        let changedAuditExport = try JSONSerialization.data(
            withJSONObject: changedAuditObject
        )
        XCTAssertThrowsError(try FickValidationAuditExportEncoder.verify(
            sidecarData: changedAuditExport,
            runExportData: export,
            dataset: dataset
        )) { error in
            XCTAssertEqual(
                error as? FickValidationDiagnosticsError,
                .auditDiagnosticsMismatch
            )
        }
        var changedRunExport = export
        changedRunExport[changedRunExport.startIndex] ^= 0x01
        XCTAssertThrowsError(try FickValidationAuditExportEncoder.verify(
            sidecarData: auditExport,
            runExportData: changedRunExport,
            dataset: dataset
        )) { error in
            XCTAssertEqual(
                error as? FickValidationDiagnosticsError,
                .auditRunHashMismatch
            )
        }

        XCTAssertThrowsError(try FickValidationDiagnosticsEngine.make(
            run: first,
            dataset: TrainingDataSource.emptyCompatible
        )) { error in
            XCTAssertEqual(error as? FickValidationDiagnosticsError, .datasetMismatch)
        }

        let changedMetric = try mutatedFickRun(first) { object in
            var metric = object["pooledMetric"] as! [String: Any]
            metric["rSquared"] = 0.99
            object["pooledMetric"] = metric
        }
        XCTAssertThrowsError(try FickValidationDiagnosticsEngine.make(
            run: changedMetric,
            dataset: dataset
        )) { error in
            XCTAssertEqual(error as? FickValidationDiagnosticsError, .runMetricMismatch)
        }

        let forgedPredictionsAndMetrics = try mutatedFickRun(first) { object in
            var predictions = object["predictions"] as! [[String: Any]]
            for index in predictions.indices {
                let observed = predictions[index]["observedPercentage"] as! Double
                predictions[index]["predictedPercentage"] = min(100, max(0, observed))
            }
            object["predictions"] = predictions
            var pooledMetric = object["pooledMetric"] as! [String: Any]
            pooledMetric["rSquared"] = 1.0
            pooledMetric["rmse"] = 0.0
            pooledMetric["mae"] = 0.0
            object["pooledMetric"] = pooledMetric
            var familyMetrics = object["familyMetrics"] as! [[String: Any]]
            for index in familyMetrics.indices {
                var metric = familyMetrics[index]["metric"] as! [String: Any]
                metric["rSquared"] = 1.0
                metric["rmse"] = 0.0
                metric["mae"] = 0.0
                familyMetrics[index]["metric"] = metric
            }
            object["familyMetrics"] = familyMetrics
        }
        XCTAssertThrowsError(try FickValidationDiagnosticsEngine.make(
            run: forgedPredictionsAndMetrics,
            dataset: dataset
        )) { error in
            guard case .predictionValueMismatch = error as? FickValidationDiagnosticsError else {
                return XCTFail("Expected predictionValueMismatch, received \(error)")
            }
        }

        let changedFoldFit = try mutatedFickRun(first) { object in
            var folds = object["folds"] as! [[String: Any]]
            folds[0]["fittedRate"] = (folds[0]["fittedRate"] as! Double) * 2
            object["folds"] = folds
        }
        XCTAssertThrowsError(try FickValidationDiagnosticsEngine.make(
            run: changedFoldFit,
            dataset: dataset
        )) { error in
            guard case .foldFitMismatch = error as? FickValidationDiagnosticsError else {
                return XCTFail("Expected foldFitMismatch, received \(error)")
            }
        }

        let changedStressFit = try mutatedFickRun(first) { object in
            var stress = object["leaveOneFamilyOutStress"] as! [String: Any]
            var folds = stress["folds"] as! [[String: Any]]
            folds[0]["trainingSSE"] = (folds[0]["trainingSSE"] as! Double) + 1
            stress["folds"] = folds
            object["leaveOneFamilyOutStress"] = stress
        }
        XCTAssertThrowsError(try FickValidationDiagnosticsEngine.make(
            run: changedStressFit,
            dataset: dataset
        )) { error in
            guard case .foldFitMismatch = error as? FickValidationDiagnosticsError else {
                return XCTFail("Expected foldFitMismatch, received \(error)")
            }
        }

        let changedStressPrediction = try mutatedFickRun(first) { object in
            var stress = object["leaveOneFamilyOutStress"] as! [String: Any]
            var predictions = stress["predictions"] as! [[String: Any]]
            predictions[0]["predictedPercentage"] =
                (predictions[0]["predictedPercentage"] as! Double) + 1
            stress["predictions"] = predictions
            object["leaveOneFamilyOutStress"] = stress
        }
        XCTAssertThrowsError(try FickValidationDiagnosticsEngine.make(
            run: changedStressPrediction,
            dataset: dataset
        )) { error in
            guard case .predictionValueMismatch = error as? FickValidationDiagnosticsError else {
                return XCTFail("Expected predictionValueMismatch, received \(error)")
            }
        }

        let changedConfidenceInterval = try mutatedFickRun(first) { object in
            var interval = object["confidenceInterval"] as! [String: Any]
            interval["oneSidedLower"] = 0.95
            object["confidenceInterval"] = interval
        }
        XCTAssertThrowsError(try FickValidationDiagnosticsEngine.make(
            run: changedConfidenceInterval,
            dataset: dataset
        )) { error in
            XCTAssertEqual(
                error as? FickValidationDiagnosticsError,
                .confidenceIntervalMismatch
            )
        }

        let removedWarning = try mutatedFickRun(first) { object in
            var warnings = object["warnings"] as! [[String: Any]]
            warnings.removeLast()
            object["warnings"] = warnings
        }
        XCTAssertThrowsError(try FickValidationDiagnosticsEngine.make(
            run: removedWarning,
            dataset: dataset
        )) { error in
            XCTAssertEqual(error as? FickValidationDiagnosticsError, .runNarrativeMismatch)
        }

        let epsilonBoundaryAndRemovedWarning = try mutatedFickRun(first) { object in
            var folds = object["folds"] as! [[String: Any]]
            for index in folds.indices
            where (folds[index]["fittedAmplitude"] as! Double) == 100 {
                folds[index]["fittedAmplitude"] = 99.999_999_999
            }
            object["folds"] = folds

            var stress = object["leaveOneFamilyOutStress"] as! [String: Any]
            var stressFolds = stress["folds"] as! [[String: Any]]
            for index in stressFolds.indices
            where (stressFolds[index]["fittedAmplitude"] as! Double) == 100 {
                stressFolds[index]["fittedAmplitude"] = 99.999_999_999
            }
            stress["folds"] = stressFolds
            object["leaveOneFamilyOutStress"] = stress

            var warnings = object["warnings"] as! [[String: Any]]
            warnings.removeAll { warning in
                warning["code"] as? String == "amplitude_upper_boundary_reached"
            }
            object["warnings"] = warnings
        }
        XCTAssertThrowsError(try FickValidationDiagnosticsEngine.make(
            run: epsilonBoundaryAndRemovedWarning,
            dataset: dataset
        )) { error in
            XCTAssertEqual(error as? FickValidationDiagnosticsError, .runNarrativeMismatch)
        }

        let changedLimitation = try mutatedFickRun(first) { object in
            var limitations = object["limitations"] as! [[String: Any]]
            limitations[0]["english"] = "Falsely claims confirmatory validation."
            object["limitations"] = limitations
        }
        XCTAssertThrowsError(try FickValidationDiagnosticsEngine.make(
            run: changedLimitation,
            dataset: dataset
        )) { error in
            XCTAssertEqual(error as? FickValidationDiagnosticsError, .runNarrativeMismatch)
        }

        let changedConfiguration = try mutatedFickRun(first) { object in
            var configuration = object["configuration"] as! [String: Any]
            configuration["bootstrapIterations"] = 20_001
            object["configuration"] = configuration
        }
        XCTAssertThrowsError(try FickValidationDiagnosticsEngine.make(
            run: changedConfiguration,
            dataset: dataset
        )) { error in
            XCTAssertEqual(error as? FickValidationDiagnosticsError, .invalidConfiguration)
        }

        let missingPrediction = try mutatedFickRun(first) { object in
            var predictions = object["predictions"] as! [[String: Any]]
            predictions.removeLast()
            object["predictions"] = predictions
        }
        XCTAssertThrowsError(try FickValidationDiagnosticsEngine.make(
            run: missingPrediction,
            dataset: dataset
        )) { error in
            guard case .predictionPopulationMismatch = error as? FickValidationDiagnosticsError else {
                return XCTFail("Expected predictionPopulationMismatch, received \(error)")
            }
        }

        let duplicatedRowID = first.predictions[0].rowID
        let duplicatePrediction = try mutatedFickRun(first) { object in
            var predictions = object["predictions"] as! [[String: Any]]
            predictions.append(predictions[0])
            object["predictions"] = predictions
        }
        XCTAssertThrowsError(try FickValidationDiagnosticsEngine.make(
            run: duplicatePrediction,
            dataset: dataset
        )) { error in
            XCTAssertEqual(
                error as? FickValidationDiagnosticsError,
                .duplicatePrediction(rowID: duplicatedRowID)
            )
        }

        let invalidFoldID = first.folds[0].id
        let duplicateTestRow = try mutatedFickRun(first) { object in
            var folds = object["folds"] as! [[String: Any]]
            var fold = folds[0]
            var testRows = fold["testRowIDs"] as! [Int]
            testRows.append(testRows[0])
            fold["testRowIDs"] = testRows
            folds[0] = fold
            object["folds"] = folds
        }
        XCTAssertThrowsError(try FickValidationDiagnosticsEngine.make(
            run: duplicateTestRow,
            dataset: dataset
        )) { error in
            XCTAssertEqual(
                error as? FickValidationDiagnosticsError,
                .invalidFold(foldID: invalidFoldID)
            )
        }

        let unsupportedSchema = try mutatedFickRun(first) { object in
            object["schemaVersion"] = "9.9"
        }
        XCTAssertThrowsError(try FickValidationDiagnosticsEngine.make(
            run: unsupportedSchema,
            dataset: dataset
        )) { error in
            XCTAssertEqual(
                error as? FickValidationDiagnosticsError,
                .unsupportedRunSchema("9.9")
            )
        }

        let suiteName = "PermeationLabTests.FickValidation.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let persistence = FickValidationHistoryPersistence(
            userDefaults: defaults,
            key: "runs",
            maximumRunCount: 10,
            maximumEncodedBytes: 4 * 1_024 * 1_024
        )
        XCTAssertEqual(persistence.save([first]).map(\.id), [first.id])
        XCTAssertEqual(persistence.load().map(\.id), [first.id])

        let constrainedPersistence = FickValidationHistoryPersistence(
            userDefaults: defaults,
            key: "runs",
            maximumRunCount: 10,
            maximumEncodedBytes: 64 * 1_024
        )
        XCTAssertEqual(constrainedPersistence.save([first]).map(\.id), [first.id])
        XCTAssertEqual(persistence.load().map(\.id), [first.id])

        persistence.clear()
        XCTAssertTrue(persistence.load().isEmpty)

        XCTAssertThrowsError(try FickValidationExperiment.run(
            dataset: dataset,
            displayName: "paper.csv",
            isBundledData: true,
            researchMode: .paperEvidence,
            scientificStatus: .paperSourceVerified,
            configuration: configuration
        )) { error in
            XCTAssertEqual(error as? FickValidationError, .unsupportedEvidenceContext)
        }

        let oneFamilyDataset = TrainingDataSource.parse(csvText(
            rows: dataset.rows.filter { $0.sourceDrugName == "BSA" }
        ))
        XCTAssertThrowsError(try FickValidationExperiment.run(
            dataset: oneFamilyDataset,
            displayName: "one-family.csv",
            researchMode: .myExperiment,
            scientificStatus: .userProvidedUnvalidated,
            configuration: configuration
        )) { error in
            XCTAssertEqual(error as? FickValidationError, .insufficientFamiliesForStress)
        }
    }

    @MainActor
    func testComparisonOnlyChangeDoesNotAdvanceTrainingRevision() {
        let store = AppDatasetStore()
        let initialTrainingRevision = store.trainingRevision
        let initialRevision = store.revision
        let initialComparisonRevision = store.comparisonRevision

        store.useBundledDataAsComparison()

        XCTAssertEqual(store.trainingRevision, initialTrainingRevision)
        XCTAssertEqual(store.revision, initialRevision)
        XCTAssertEqual(store.comparisonRevision, initialComparisonRevision + 1)
    }

    @MainActor
    func testPaperAndPersonalDatasetSlotsRemainSeparate() throws {
        let store = AppDatasetStore()
        let paperHash = ExperimentDatasetSnapshot.make(
            dataset: store.dataset,
            displayName: store.displayName,
            isBundledData: true
        ).normalizedSHA256

        store.selectMode(.myExperiment)
        XCTAssertEqual(store.mode, .myExperiment)
        XCTAssertFalse(store.hasPersonalDataset)
        XCTAssertTrue(store.dataset.rows.isEmpty)
        XCTAssertFalse(store.isBundledData)
        XCTAssertEqual(store.scientificStatus, .noExperimentalDataset)

        let personalRows = Array(TrainingDataSource.bundled.rows.prefix(8))
        try store.importPersonalDataset(
            csvText: csvText(rows: personalRows),
            fileName: "my-study.csv",
            importedAt: Date(timeIntervalSince1970: 1_700_000_000)
        )
        XCTAssertTrue(store.hasPersonalDataset)
        XCTAssertEqual(store.dataset.rows.count, 8)
        XCTAssertEqual(store.displayName, "my-study.csv")
        XCTAssertEqual(store.scientificStatus, .userProvidedUnvalidated)

        store.selectMode(.paperEvidence)
        XCTAssertEqual(store.mode, .paperEvidence)
        XCTAssertTrue(store.isBundledData)
        XCTAssertEqual(store.dataset.rows.count, 191)
        XCTAssertEqual(
            ExperimentDatasetSnapshot.make(
                dataset: store.dataset,
                displayName: store.displayName,
                isBundledData: true
            ).normalizedSHA256,
            paperHash
        )

        store.selectMode(.myExperiment)
        XCTAssertEqual(store.dataset.rows.count, 8)
        store.clearPersonalDataset()
        XCTAssertTrue(store.dataset.rows.isEmpty)
        store.selectMode(.paperEvidence)
        XCTAssertEqual(store.dataset.rows.count, 191)
    }

    func testWorkspaceAllowListsKeepFactsReadOnlyAndResearchActionsSeparate() {
        let facts = Set(ContentView.Workspace.allCases.filter {
            $0.isAvailable(in: .paperEvidence)
        })
        let myResearch = Set(ContentView.Workspace.allCases.filter {
            $0.isAvailable(in: .myExperiment)
        })

        XCTAssertEqual(facts, [
            .studyOverview,
            .literatureLibrary,
            .paperReader,
            .methods,
            .modelEvidence,
            .paperFigures,
            .dataSource,
            .integrity,
        ])
        XCTAssertEqual(myResearch, [
            .researchHome,
            .fick85Assessment,
            .datasetImpact,
            .experiment,
            .modelSelection,
            .modelProfiles,
            .skinPermeation,
            .dataSource,
            .integrity,
        ])

        let derivedOrMutatingWorkspaces: Set<ContentView.Workspace> = [
            .researchHome,
            .fick85Assessment,
            .datasetImpact,
            .experiment,
            .modelSelection,
            .modelProfiles,
            .skinPermeation,
        ]
        XCTAssertTrue(facts.isDisjoint(with: derivedOrMutatingWorkspaces))

        let paperOnlyWorkspaces: Set<ContentView.Workspace> = [
            .studyOverview,
            .literatureLibrary,
            .paperReader,
            .methods,
            .modelEvidence,
            .paperFigures,
        ]
        XCTAssertTrue(myResearch.isDisjoint(with: paperOnlyWorkspaces))
    }

    func testBundledLiteratureLibraryContainsThirtyCompleteUniquePapers() {
        let library = LiteraturePaperLibrary.bundled

        XCTAssertNil(library.error)
        XCTAssertEqual(library.records.count, 30)
        XCTAssertEqual(Set(library.records.map(\.id)).count, 30)
        XCTAssertEqual(
            Set(library.records.map { $0.doi.lowercased() }).count,
            30,
            "Every bundled paper must have a unique DOI"
        )

        for paper in library.records {
            let requiredFields = [
                paper.id,
                paper.title,
                paper.authors,
                paper.journal,
                paper.doi,
                paper.url,
                paper.category,
                paper.studyType,
                paper.relevanceJapanese,
                paper.keyFactJapanese,
                paper.limitationJapanese,
            ]
            for field in requiredFields {
                XCTAssertFalse(
                    field.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                    "Paper \(paper.id) has an empty required field"
                )
            }
        }
    }

    @MainActor
    func testExperimentHistoryAndRestoreAreStrictlyModeScoped() throws {
        let suiteName = "PermeationLabTests.ModeScopedHistory.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let persistence = ExperimentHistoryPersistence(
            userDefaults: defaults,
            key: "runs",
            maximumRunCount: 10,
            maximumEncodedBytes: 4 * 1_024 * 1_024
        )
        let configuration = ExperimentConfiguration(seed: 0)
        let dataset = TrainingDataSource.bundled
        let paperRun = try ExperimentRunner.execute(
            dataset: dataset,
            displayName: "Yuan 2023 · Data S1",
            isBundledData: true,
            researchMode: .paperEvidence,
            scientificStatus: .paperSourceVerified,
            configuration: configuration,
            runID: UUID(uuidString: "00000000-0000-0000-0000-000000000101")!,
            startedAt: Date(timeIntervalSince1970: 1_700_000_101)
        )
        let researchRun = try ExperimentRunner.execute(
            dataset: dataset,
            displayName: "my-research.csv",
            isBundledData: false,
            researchMode: .myExperiment,
            scientificStatus: .userProvidedUnvalidated,
            configuration: configuration,
            runID: UUID(uuidString: "00000000-0000-0000-0000-000000000102")!,
            startedAt: Date(timeIntervalSince1970: 1_700_000_102)
        )

        XCTAssertEqual(
            persistence.save([paperRun, researchRun], for: .paperEvidence).map(\.id),
            [paperRun.id]
        )
        XCTAssertEqual(
            persistence.save([paperRun, researchRun], for: .myExperiment).map(\.id),
            [researchRun.id]
        )
        XCTAssertEqual(persistence.load(for: .paperEvidence).map(\.id), [paperRun.id])
        XCTAssertEqual(persistence.load(for: .myExperiment).map(\.id), [researchRun.id])

        let researchStore = ExperimentStore(
            dataset: dataset,
            displayName: "my-research.csv",
            isBundledData: false,
            researchMode: .myExperiment,
            scientificStatus: .userProvidedUnvalidated,
            persistence: persistence
        )
        XCTAssertEqual(researchStore.recentRuns.map(\.id), [researchRun.id])
        XCTAssertTrue(researchStore.restore(researchRun))
        XCTAssertEqual(researchStore.currentResult?.id, researchRun.id)
        XCTAssertFalse(researchStore.restore(paperRun))
        XCTAssertEqual(
            researchStore.currentResult?.id,
            researchRun.id,
            "A rejected cross-mode restore must not replace the visible research result"
        )

        let paperStore = ExperimentStore(
            dataset: dataset,
            displayName: "Yuan 2023 · Data S1",
            isBundledData: true,
            researchMode: .paperEvidence,
            scientificStatus: .paperSourceVerified,
            persistence: persistence
        )
        XCTAssertEqual(paperStore.recentRuns.map(\.id), [paperRun.id])
        XCTAssertTrue(paperStore.restore(paperRun))
        XCTAssertFalse(paperStore.restore(researchRun))
        XCTAssertEqual(paperStore.currentResult?.id, paperRun.id)

        researchStore.clearHistory()
        XCTAssertTrue(persistence.load(for: .myExperiment).isEmpty)
        XCTAssertEqual(
            persistence.load(for: .paperEvidence).map(\.id),
            [paperRun.id],
            "Clearing My Research history must not delete the paper-scoped legacy history"
        )
    }

    func testFickRejectsNonFiniteOrExcessiveWork() {
        var invalid = FickPreviewConfiguration()
        invalid.diffusionCoefficient = .infinity
        XCTAssertThrowsError(try FickPreviewEngine.run(invalid)) { error in
            XCTAssertEqual(error as? FickPreviewError, .invalidConfiguration)
        }

        var excessive = FickPreviewConfiguration()
        excessive.durationHours = 10_000
        XCTAssertThrowsError(try FickPreviewEngine.run(excessive)) { error in
            XCTAssertEqual(error as? FickPreviewError, .iterationLimitExceeded)
        }
    }

    private func csvText(rows: [TrainingDataRow]) -> String {
        func escaped(_ value: String) -> String {
            guard value.contains(",") || value.contains("\"") || value.contains("\n") else {
                return value
            }
            return "\"" + value.replacingOccurrences(of: "\"", with: "\"\"") + "\""
        }

        let records = rows.map { row in
            [
                row.sourceDrugName,
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
            ].map(escaped).joined(separator: ",")
        }
        return ([TrainingDataSource.expectedHeader.joined(separator: ",")] + records)
            .joined(separator: "\n")
    }

    private func mutatedFickRun(
        _ run: FickValidationRunResult,
        mutation: (inout [String: Any]) -> Void
    ) throws -> FickValidationRunResult {
        let data = try FickValidationExportEncoder.data(for: run)
        var object = try XCTUnwrap(
            JSONSerialization.jsonObject(with: data) as? [String: Any]
        )
        mutation(&object)
        let mutatedData = try JSONSerialization.data(withJSONObject: object)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(FickValidationRunResult.self, from: mutatedData)
    }
}
