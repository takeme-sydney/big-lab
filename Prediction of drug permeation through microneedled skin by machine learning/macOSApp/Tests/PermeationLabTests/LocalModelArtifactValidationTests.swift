import XCTest
@testable import PermeationLab

final class LocalModelArtifactValidationTests: XCTestCase {
    func testEveryLocallyTrainedFamilyPassesValidationAndStrictRoundTrip() throws {
        let dataset = GenericDataset(
            name: "local-training.csv",
            headers: ["dose", "response"],
            rows: (0..<24).map { [String($0), String(1.5 + 2 * Double($0))] }
        )
        let metrics = CandidateFamily.allCases.map {
            SelectionMetric(
                family: $0,
                rmse: 1,
                mae: 0.8,
                rSquared: 0.9,
                foldRMSEStandardDeviation: 0.1,
                groupBalancedRMSE: nil,
                groupBalancedMAE: nil
            )
        }
        let report = ModelSelectionReport(
            configurationSHA256: ModelSelectionEngine.configurationSHA256(
                dataset: dataset,
                target: 1,
                group: nil,
                features: [0]
            ),
            metrics: metrics,
            winner: .linear,
            foldCount: 2,
            usedGroupHoldout: false,
            observationCount: dataset.rows.count,
            featureCount: 1,
            excludedColumns: [],
            baselineRMSE: 2,
            warnings: []
        )

        for family in CandidateFamily.allCases {
            let artifact = try ModelTrainingEngine.train(
                dataset: dataset,
                target: 1,
                group: nil,
                features: [0],
                family: family,
                report: report,
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000101")!,
                trainedAt: Date(timeIntervalSince1970: 1_700_000_000)
            )

            XCTAssertNoThrow(try artifact.validate(), "\(family.rawValue)")
            let decoded = try LocalModelArtifact.decode(artifact.encodedData())
            XCTAssertEqual(decoded, artifact, "\(family.rawValue)")
        }
    }

    func testDecodeRejectsOversizedDeepAndUnknownJSON() throws {
        let oversized = Data(
            repeating: 0x20,
            count: LocalModelArtifactImportLimits.maximumEncodedByteCount + 1
        )
        assertDecodeRejects(oversized)

        let excessDepth = LocalModelArtifactImportLimits.maximumJSONNestingDepth + 1
        let deeplyNested = Data(
            (String(repeating: "[", count: excessDepth)
                + String(repeating: "]", count: excessDepth)).utf8
        )
        assertDecodeRejects(deeplyNested)

        let valid = makeArtifact()
        var object = try XCTUnwrap(
            JSONSerialization.jsonObject(with: valid.encodedData()) as? [String: Any]
        )
        object["unexpectedField"] = true
        let unknownFieldData = try JSONSerialization.data(withJSONObject: object)
        assertDecodeRejects(unknownFieldData)
    }

    func testRidgeWeightsAndNormalizerMustMatchDimensionsAndBeFinite() throws {
        assertDecodeRejects(
            try makeArtifact(regressor: .ridge(RidgeRegressor(weights: [1]))).encodedData()
        )
        assertInvalid(
            makeArtifact(regressor: .ridge(RidgeRegressor(weights: [0, .nan])))
        )
        assertInvalid(
            makeArtifact(normalizer: Normalizer(means: [.infinity], scales: [1]))
        )
        assertInvalid(
            makeArtifact(normalizer: Normalizer(means: [0], scales: [.nan]))
        )
        assertInvalid(
            makeArtifact(normalizer: Normalizer(means: [0], scales: [0]))
        )
    }

    func testRegressionTreesRejectInvalidFeaturesValuesDepthAndNodeCount() throws {
        let outOfRange = RegressionTree.node(
            feature: 1,
            threshold: 0,
            left: .leaf(0),
            right: .leaf(1)
        )
        assertDecodeRejects(
            try makeForestArtifact(trees: [outOfRange]).encodedData()
        )

        assertInvalid(makeForestArtifact(trees: [.leaf(.nan)]))
        assertInvalid(
            makeForestArtifact(trees: [
                .node(feature: 0, threshold: .infinity, left: .leaf(0), right: .leaf(1))
            ])
        )

        var tooDeep = RegressionTree.leaf(0)
        for _ in 0..<LocalModelArtifactImportLimits.maximumTreeDepth {
            tooDeep = .node(feature: 0, threshold: 0, left: tooDeep, right: .leaf(0))
        }
        assertDecodeRejects(
            try makeForestArtifact(trees: [tooDeep]).encodedData()
        )

        let tooManyNodes = fullTree(depth: 13)
        assertInvalid(makeForestArtifact(trees: [tooManyNodes]))
    }

    func testForestAndBoostingCountsAndBoostingScalarsAreBounded() throws {
        assertDecodeRejects(try makeForestArtifact(trees: []).encodedData())
        assertInvalid(
            makeForestArtifact(
                trees: Array(
                    repeating: .leaf(0),
                    count: LocalModelArtifactImportLimits.maximumForestTreeCount + 1
                )
            )
        )

        assertDecodeRejects(try makeBoostingArtifact(trees: []).encodedData())
        assertInvalid(makeBoostingArtifact(base: .infinity))
        assertInvalid(makeBoostingArtifact(rate: .nan))
        assertInvalid(makeBoostingArtifact(rate: 0))
        assertInvalid(
            makeBoostingArtifact(
                trees: Array(
                    repeating: .leaf(0),
                    count: LocalModelArtifactImportLimits.maximumBoostingTreeCount + 1
                )
            )
        )
    }

    func testArtifactMetadataStringsAndArraysAreBoundedAndConsistent() throws {
        let oversizedName = String(
            repeating: "x",
            count: LocalModelArtifactImportLimits.maximumStringUTF8ByteCount + 1
        )
        assertDecodeRejects(
            try makeArtifact(datasetName: oversizedName).encodedData()
        )

        let excessiveHeaders = (0...LocalModelArtifactImportLimits.maximumSourceHeaderCount)
            .map { "column-\($0)" }
        assertInvalid(makeArtifact(sourceHeaders: excessiveHeaders))

        let duplicateSelection = makeArtifact(selectedFeatureNames: ["dose", "dose"])
        assertDecodeRejects(try duplicateSelection.encodedData())

        let invalidProfile = ModelFeatureProfile(
            name: "dose",
            kind: .numeric,
            missingTrainingCount: 0,
            numericMinimum: 0,
            numericMaximum: 10,
            numericMedian: .infinity,
            categoricalLevels: []
        )
        assertInvalid(makeArtifact(featureProfiles: [invalidProfile]))
    }

    private func makeArtifact(
        datasetName: String = "model-input.csv",
        sourceHeaders: [String] = ["dose", "response"],
        selectedFeatureNames: [String] = ["dose"],
        featureProfiles: [ModelFeatureProfile]? = nil,
        preprocessor: FoldPreprocessor = FoldPreprocessor(columns: [.numeric(index: 0, median: 5)]),
        normalizer: Normalizer = Normalizer(means: [5], scales: [2]),
        family: CandidateFamily = .linear,
        regressor: LocalRegressor = .ridge(RidgeRegressor(weights: [0, 1]))
    ) -> LocalModelArtifact {
        let resolvedProfiles = featureProfiles ?? [
            ModelFeatureProfile(
                name: "dose",
                kind: .numeric,
                missingTrainingCount: 0,
                numericMinimum: 0,
                numericMaximum: 10,
                numericMedian: 5,
                categoricalLevels: []
            )
        ]
        return LocalModelArtifact(
            schemaVersion: LocalModelArtifact.currentSchemaVersion,
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000102")!,
            trainedAt: Date(timeIntervalSince1970: 1_700_000_000),
            engineVersion: LocalModelArtifact.engineVersion,
            datasetName: datasetName,
            datasetNormalizedSHA256: String(repeating: "a", count: 64),
            sourceHeaders: sourceHeaders,
            targetName: "response",
            groupName: nil,
            selectedFeatureNames: selectedFeatureNames,
            trainingRowCount: 20,
            encodedFeatureCount: 1,
            family: family,
            featureProfiles: resolvedProfiles,
            preprocessor: preprocessor,
            normalizer: normalizer,
            regressor: regressor,
            validation: ModelValidationSnapshot(
                configurationSHA256: String(repeating: "b", count: 64),
                foldCount: 2,
                groupColumn: nil,
                selectedFamily: family,
                selectedRMSE: 1,
                selectedMAE: 0.8,
                selectedRSquared: 0.9,
                baselineRMSE: 2,
                selectedWasCVWinner: true
            )
        )
    }

    private func makeForestArtifact(trees: [RegressionTree]) -> LocalModelArtifact {
        makeArtifact(
            family: .randomForest,
            regressor: .randomForest(ForestRegressor(trees: trees))
        )
    }

    private func makeBoostingArtifact(
        base: Double = 0,
        trees: [RegressionTree] = [.leaf(1)],
        rate: Double = 0.08
    ) -> LocalModelArtifact {
        makeArtifact(
            family: .gradientBoosting,
            regressor: .gradientBoosting(BoostingRegressor(base: base, trees: trees, rate: rate))
        )
    }

    private func fullTree(depth: Int) -> RegressionTree {
        guard depth > 1 else { return .leaf(0) }
        return .node(
            feature: 0,
            threshold: 0,
            left: fullTree(depth: depth - 1),
            right: fullTree(depth: depth - 1)
        )
    }

    private func assertInvalid(
        _ artifact: LocalModelArtifact,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertThrowsError(try artifact.validate(), file: file, line: line) { error in
            XCTAssertNotNil(error as? LocalModelArtifactError, file: file, line: line)
        }
    }

    private func assertDecodeRejects(
        _ data: Data,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertThrowsError(try LocalModelArtifact.decode(data), file: file, line: line) { error in
            XCTAssertNotNil(error as? LocalModelArtifactError, file: file, line: line)
        }
    }
}
