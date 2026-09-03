import Foundation

enum ExperimentRunError: LocalizedError, Equatable, Sendable {
    case emptyDataset
    case invalidDataset(errorCount: Int)
    case duplicateRowID(Int)
    case missingHeldOutDrug
    case heldOutDrugNotPresent(String)
    case emptyTrainingPartition
    case emptyTestPartition
    case rankDeficientLinearModel
    case nonFinitePrediction(model: ExperimentModelKind, rowID: Int)

    var errorDescription: String? { message(.english) }

    func message(_ language: AppLanguage) -> String {
        switch self {
        case .emptyDataset:
            language.text("実行できるデータ行がありません。", "There are no data rows to run.")
        case .invalidDataset(let errorCount):
            language.text(
                "データ監査エラーが\(errorCount)件あります。先にデータを修正してください。",
                "The dataset has \(errorCount) audit errors. Correct the data before running."
            )
        case .duplicateRowID(let rowID):
            language.text("行ID \(rowID) が重複しています。", "Row ID \(rowID) is duplicated.")
        case .missingHeldOutDrug:
            language.text("除外する薬物を選択してください。", "Select a drug to hold out.")
        case .heldOutDrugNotPresent(let drug):
            language.text("選択した薬物（\(drug)）はデータにありません。", "The selected drug (\(drug)) is not present in the dataset.")
        case .emptyTrainingPartition:
            language.text("学習パーティションが空です。", "The training partition is empty.")
        case .emptyTestPartition:
            language.text("テストパーティションが空です。", "The test partition is empty.")
        case .rankDeficientLinearModel:
            language.text(
                "7説明変数の行列がランク不足のため、切片なしOLSを推定できません。",
                "The seven-predictor matrix is rank deficient, so no-intercept OLS cannot be fitted."
            )
        case .nonFinitePrediction(let model, let rowID):
            language.text(
                "\(model.engineLabel) が行\(rowID)で有限でない予測値を返しました。",
                "\(model.engineLabel) returned a non-finite prediction for row \(rowID)."
            )
        }
    }
}

/// Dependency-free, deterministic reconstruction of the three disclosed
/// statistical workflows. It does not claim binary or numerical equivalence with
/// R randomForest or XGBoost.
enum ExperimentRunner {
    static let engineVersion = "PermeationLab.NativeExperiment/1.0"

    static func run(
        dataset: TrainingDataset,
        displayName: String,
        isBundledData: Bool = false,
        researchMode: ResearchMode? = nil,
        scientificStatus: ScientificDataStatus? = nil,
        importedAt: Date? = nil,
        configuration: ExperimentConfiguration,
        runID: UUID = UUID(),
        startedAt: Date = Date()
    ) async throws -> ExperimentRunResult {
        let worker = Task.detached(priority: .userInitiated) {
            try execute(
                dataset: dataset,
                displayName: displayName,
                isBundledData: isBundledData,
                researchMode: researchMode,
                scientificStatus: scientificStatus,
                importedAt: importedAt,
                configuration: configuration,
                runID: runID,
                startedAt: startedAt
            )
        }
        return try await withTaskCancellationHandler {
            try await worker.value
        } onCancel: {
            worker.cancel()
        }
    }

    /// Synchronous entry point for deterministic unit tests and command-line QA.
    static func execute(
        dataset: TrainingDataset,
        displayName: String,
        isBundledData: Bool = false,
        researchMode: ResearchMode? = nil,
        scientificStatus: ScientificDataStatus? = nil,
        importedAt: Date? = nil,
        configuration: ExperimentConfiguration,
        runID: UUID = UUID(),
        startedAt: Date = Date()
    ) throws -> ExperimentRunResult {
        let uptime = ProcessInfo.processInfo.systemUptime
        try validate(dataset)
        try Task.checkCancellation()

        let partitions = try partition(rows: dataset.rows, configuration: configuration)
        let trainRows = partitions.train.sorted { $0.id < $1.id }
        let testRows = partitions.test.sorted { $0.id < $1.id }
        let split = ExperimentSplit(
            trainRowIDs: trainRows.map(\.id),
            testRowIDs: testRows.map(\.id),
            trainDrugCounts: drugCounts(trainRows),
            testDrugCounts: drugCounts(testRows)
        )
        let leakageAudit = leakageAudit(
            trainRows: trainRows,
            testRows: testRows,
            heldOutDrug: configuration.validationStrategy == .leaveOneDrugOut
                ? configuration.heldOutDrug
                : nil
        )

        let xTrain = trainRows.map(features)
        let yTrain = trainRows.map { configuration.outcome.value(in: $0) }
        let xTest = testRows.map(features)
        let yTest = testRows.map { configuration.outcome.value(in: $0) }
        let preset = configuration.preset

        let linear = try NoInterceptOLS.fit(x: xTrain, y: yTrain)
        let linearPredictions = xTest.map(linear.predict)
        try validatePredictions(linearPredictions, rows: testRows, model: .multipleLinearRegression)
        try Task.checkCancellation()

        let forest = try SeededRandomForest.fit(
            x: xTrain,
            y: yTrain,
            treeCount: preset.randomForestTrees,
            mtry: preset.randomForestMtry,
            maximumDepth: preset.randomForestMaximumDepth,
            minimumNodeSize: preset.randomForestMinimumNodeSize,
            seed: configuration.seed ^ 0xA076_1D64_78BD_642F
        )
        let forestPredictions = xTest.map(forest.predict)
        try validatePredictions(forestPredictions, rows: testRows, model: .randomForest)
        try Task.checkCancellation()

        let boosting = try NativeGradientTreeBoosting.fit(
            x: xTrain,
            y: yTrain,
            maximumDepth: preset.boostingMaxDepth,
            learningRate: preset.boostingLearningRate,
            rounds: preset.boostingRounds
        )
        let boostingPredictions = xTest.map(boosting.predict)
        try validatePredictions(boostingPredictions, rows: testRows, model: .nativeGradientTreeBoosting)
        try Task.checkCancellation()

        let outputs: [(ExperimentModelKind, [Double])] = [
            (.multipleLinearRegression, linearPredictions),
            (.randomForest, forestPredictions),
            (.nativeGradientTreeBoosting, boostingPredictions),
        ]
        let metrics = outputs.map { model, values in
            makeMetric(model: model, observed: yTest, predicted: values)
        }
        let predictions = outputs.flatMap { model, values in
            zip(testRows, zip(yTest, values)).map { row, pair in
                ExperimentPrediction(
                    rowID: row.id,
                    drugName: row.sourceDrugName,
                    model: model,
                    observed: pair.0,
                    predicted: pair.1
                )
            }
        }

        var warnings: [ExperimentMessage] = []
        let snapshot = ExperimentDatasetSnapshot.make(
            dataset: dataset,
            displayName: displayName,
            isBundledData: isBundledData,
            researchMode: researchMode,
            scientificStatus: scientificStatus,
            importedAt: importedAt
        )
        if snapshot.resolvedResearchMode == .myExperiment {
            warnings.append(.init(
                code: "unvalidated_personal_experiment",
                japanese: "このrunは自分の研究の未検証データで実行されました。スキーマ検証の成功は、実験設計・測定・科学的妥当性を保証しません。",
                english: "This run used unvalidated My Research data. Passing schema checks does not validate the study design, measurements, or scientific conclusions."
            ))
        } else if configuration.validationStrategy == .publishedStyleRowSplit,
           !snapshot.isCanonicalPaperDataset {
            warnings.append(.init(
                code: "noncanonical_paper_reconstruction",
                japanese: "現在のデータは同梱Data S1と一致しません。この結果は原著プロトコルの追試ではなく、互換データでの新規実験です。",
                english: "The active data do not match bundled Data S1. This is a new experiment on compatible data, not a paper reconstruction."
            ))
        }
        if leakageAudit.hasCrossPartitionConditionOverlap {
            warnings.append(.init(
                code: "cross_partition_condition_overlap",
                japanese: "同一の7説明変数条件が学習・テストの両方にあります。行単位分割の性能が楽観的になる可能性があります。",
                english: "Identical seven-predictor conditions occur in both partitions. Row-split performance may be optimistic."
            ))
        }
        if dataset.audit.percentageAbove100Count > 0 {
            warnings.append(.init(
                code: "percentage_above_100_retained",
                japanese: "透過率100%超の原値を\(dataset.audit.percentageAbove100Count)件保持しています。論文忠実性のためクリップしません。",
                english: "\(dataset.audit.percentageAbove100Count) source value(s) above 100% are retained and not clipped."
            ))
        }
        if totalSumOfSquares(yTest) <= 1e-20 {
            warnings.append(.init(
                code: "constant_test_target",
                japanese: "テスト目的変数が一定のため、通常のR²は未定義です。JSONではnullとして記録します。",
                english: "The test target is constant, so conventional R² is undefined; the JSON records null."
            ))
        }

        let limitations: [ExperimentMessage] = [
            .init(
                code: "original_split_and_models_unavailable",
                japanese: "原著のtrain/test行割当、学習済みモデル、行別予測は公開されていないため、Table 4の完全再生はできません。",
                english: "The paper's train/test assignments, fitted models, and row-level predictions are unpublished, so exact Table 4 replay is unavailable."
            ),
            .init(
                code: "native_boosting_is_not_xgboost",
                japanese: "ブースティングは決定論的なSwiftネイティブ再構成であり、原著のxgboost 1.5.0.2ではありません。",
                english: "Boosting is a deterministic native Swift reconstruction, not the paper's xgboost 1.5.0.2 booster."
            ),
            .init(
                code: "native_forest_is_not_r_randomforest",
                japanese: "Random ForestはSwiftネイティブ再構成であり、原著のR randomForest 4.7-1と数値同一ではありません。",
                english: "Random Forest is a native Swift reconstruction and is not numerically identical to R randomForest 4.7-1."
            ),
            .init(
                code: "amount_is_derived_from_percentage",
                japanese: "Data S1の透過量は loading × percentage / 100 から導出され、2つのアウトカムは独立ではありません。",
                english: "In Data S1, permeation amount is derived from loading × percentage / 100, so the two outcomes are not independent."
            ),
            .init(
                code: "fick_inputs_unavailable",
                japanese: "全191実験のFick法入力が未公開のため、論文全体のFick指標は再計算できません。",
                english: "Per-experiment Fick inputs for all 191 rows are unpublished, so the paper-wide Fick metric cannot be recomputed."
            ),
            .init(
                code: "amount_unit_ambiguity",
                japanese: "Data S1の透過量単位はµg/cm²ですが、原著Table 4はµgと表記しています。本アプリはData S1単位を保持します。",
                english: "Data S1 labels amount as µg/cm² while Table 4 labels it µg; this app retains the Data S1 unit."
            ),
        ]

        let evidenceLevel = ExperimentEvidencePolicy.evidenceLevel(
            dataset: snapshot,
            configuration: configuration,
            split: split,
            hyperparameters: preset
        )

        let completedAt = Date()
        return ExperimentRunResult(
            id: runID,
            startedAt: startedAt,
            completedAt: completedAt,
            elapsedSeconds: max(0, ProcessInfo.processInfo.systemUptime - uptime),
            engineVersion: engineVersion,
            evidenceLevel: evidenceLevel,
            dataset: snapshot,
            configuration: configuration,
            hyperparameters: preset,
            split: split,
            leakageAudit: leakageAudit,
            metrics: metrics,
            predictions: predictions,
            warnings: warnings,
            limitations: limitations
        )
    }

    static func makeSplit(
        rows: [TrainingDataRow],
        configuration: ExperimentConfiguration
    ) throws -> ExperimentSplit {
        let partitions = try partition(rows: rows, configuration: configuration)
        let train = partitions.train.sorted { $0.id < $1.id }
        let test = partitions.test.sorted { $0.id < $1.id }
        return ExperimentSplit(
            trainRowIDs: train.map(\.id),
            testRowIDs: test.map(\.id),
            trainDrugCounts: drugCounts(train),
            testDrugCounts: drugCounts(test)
        )
    }

    static func auditSplit(
        rows: [TrainingDataRow],
        split: ExperimentSplit,
        heldOutDrug: Drug? = nil
    ) -> ExperimentLeakageAudit {
        let trainIDs = Set(split.trainRowIDs)
        let testIDs = Set(split.testRowIDs)
        return leakageAudit(
            trainRows: rows.filter { trainIDs.contains($0.id) },
            testRows: rows.filter { testIDs.contains($0.id) },
            heldOutDrug: heldOutDrug
        )
    }

    private static func validate(_ dataset: TrainingDataset) throws {
        guard !dataset.rows.isEmpty else { throw ExperimentRunError.emptyDataset }
        guard dataset.audit.isValid else {
            throw ExperimentRunError.invalidDataset(errorCount: dataset.audit.parseErrors.count)
        }
        var seen = Set<Int>()
        for row in dataset.rows where !seen.insert(row.id).inserted {
            throw ExperimentRunError.duplicateRowID(row.id)
        }
    }

    private static func partition(
        rows: [TrainingDataRow],
        configuration: ExperimentConfiguration
    ) throws -> (train: [TrainingDataRow], test: [TrainingDataRow]) {
        guard !rows.isEmpty else { throw ExperimentRunError.emptyDataset }
        let result: (train: [TrainingDataRow], test: [TrainingDataRow])
        switch configuration.validationStrategy {
        case .publishedStyleRowSplit:
            guard rows.count >= 2 else { throw ExperimentRunError.emptyTestPartition }
            var shuffled = rows
            var generator = ExperimentSeededGenerator(seed: configuration.seed)
            if shuffled.count > 1 {
                for upper in stride(from: shuffled.count - 1, through: 1, by: -1) {
                    let replacement = generator.index(upperBound: upper + 1)
                    shuffled.swapAt(upper, replacement)
                }
            }
            let roundedTrainingCount = Int((Double(rows.count) * 0.70).rounded())
            let trainingCount = min(rows.count - 1, max(1, roundedTrainingCount))
            result = (Array(shuffled.prefix(trainingCount)), Array(shuffled.dropFirst(trainingCount)))

        case .leaveOneDrugOut:
            guard let heldOutDrug = configuration.heldOutDrug else {
                throw ExperimentRunError.missingHeldOutDrug
            }
            let test = rows.filter { $0.drug == heldOutDrug }
            guard !test.isEmpty else {
                throw ExperimentRunError.heldOutDrugNotPresent(heldOutDrug.sourceName)
            }
            result = (rows.filter { $0.drug != heldOutDrug }, test)
        }
        guard !result.train.isEmpty else { throw ExperimentRunError.emptyTrainingPartition }
        guard !result.test.isEmpty else { throw ExperimentRunError.emptyTestPartition }
        return result
    }

    private static func features(_ row: TrainingDataRow) -> [Double] {
        ExperimentPredictor.allCases.map { $0.value(in: row) }
    }

    private static func drugCounts(_ rows: [TrainingDataRow]) -> [String: Int] {
        Dictionary(grouping: rows, by: \.sourceDrugName).mapValues(\.count)
    }

    private static func leakageAudit(
        trainRows: [TrainingDataRow],
        testRows: [TrainingDataRow],
        heldOutDrug: Drug?
    ) -> ExperimentLeakageAudit {
        let trainKeys = Dictionary(grouping: trainRows, by: PredictorCombination.init)
        let testKeys = Dictionary(grouping: testRows, by: PredictorCombination.init)
        let shared = Set(trainKeys.keys).intersection(testKeys.keys)
        return ExperimentLeakageAudit(
            sharedPredictorCombinationCount: shared.count,
            trainingRowsInSharedConditions: shared.reduce(0) { $0 + (trainKeys[$1]?.count ?? 0) },
            testRowsInSharedConditions: shared.reduce(0) { $0 + (testKeys[$1]?.count ?? 0) },
            heldOutDrugTrainingCount: heldOutDrug.map { drug in trainRows.count { $0.drug == drug } },
            heldOutDrugTestCount: heldOutDrug.map { drug in testRows.count { $0.drug == drug } }
        )
    }

    private static func validatePredictions(
        _ predictions: [Double],
        rows: [TrainingDataRow],
        model: ExperimentModelKind
    ) throws {
        for (index, prediction) in predictions.enumerated() where !prediction.isFinite {
            throw ExperimentRunError.nonFinitePrediction(model: model, rowID: rows[index].id)
        }
    }

    private static func makeMetric(
        model: ExperimentModelKind,
        observed: [Double],
        predicted: [Double]
    ) -> ExperimentMetric {
        let residuals = zip(observed, predicted).map(-)
        let squaredError = residuals.reduce(0) { $0 + $1 * $1 }
        let rootSumSquaredError = sqrt(squaredError)
        let rmse = rootSumSquaredError / sqrt(Double(residuals.count))
        let mae = residuals.reduce(0) { $0 + abs($1) } / Double(residuals.count)
        let total = totalSumOfSquares(observed)
        return ExperimentMetric(
            model: model,
            rmse: rmse,
            rootSumSquaredError: rootSumSquaredError,
            mae: mae,
            rSquared: total > 1e-20 ? 1 - squaredError / total : nil,
            observationCount: observed.count
        )
    }

    private static func totalSumOfSquares(_ values: [Double]) -> Double {
        guard !values.isEmpty else { return 0 }
        let mean = values.reduce(0, +) / Double(values.count)
        return values.reduce(0) { $0 + ($1 - mean) * ($1 - mean) }
    }
}

private struct PredictorCombination: Hashable {
    let loading: UInt64
    let molecularWeight: UInt64
    let needleLength: UInt64
    let skinCode: Int
    let needleTypeCode: Int
    let surfaceArea: UInt64
    let permeationTime: UInt64

    init(_ row: TrainingDataRow) {
        loading = row.loading.bitPattern
        molecularWeight = row.molecularWeight.bitPattern
        needleLength = row.needleLength.bitPattern
        skinCode = row.skin.sourceCode
        needleTypeCode = row.needle.sourceCode
        surfaceArea = row.surfaceArea.bitPattern
        permeationTime = row.permeationTime.bitPattern
    }
}

private struct ExperimentSeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed &+ 0x9E37_79B9_7F4A_7C15
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var value = state
        value = (value ^ (value >> 30)) &* 0xBF58_476D_1CE4_E5B9
        value = (value ^ (value >> 27)) &* 0x94D0_49BB_1331_11EB
        return value ^ (value >> 31)
    }

    mutating func index(upperBound: Int) -> Int {
        precondition(upperBound > 0)
        return Int(next() % UInt64(upperBound))
    }
}

private struct NoInterceptOLS {
    let coefficients: [Double]
    let scales: [Double]

    static func fit(x: [[Double]], y: [Double]) throws -> Self {
        guard let featureCount = x.first?.count,
              featureCount == ExperimentPredictor.allCases.count,
              x.count == y.count,
              x.count >= featureCount else {
            throw ExperimentRunError.rankDeficientLinearModel
        }
        let scales = (0..<featureCount).map { column in
            max(1, x.map { abs($0[column]) }.max() ?? 1)
        }
        var matrix = x.map { row in
            row.indices.map { row[$0] / scales[$0] }
        }
        var transformedTarget = y
        let rowCount = matrix.count

        // Householder QR solves least squares without forming XᵀX. Scaling is
        // multiplicative only: no centering or implicit intercept is introduced.
        for column in 0..<featureCount {
            let norm = sqrt((column..<rowCount).reduce(0) {
                $0 + matrix[$1][column] * matrix[$1][column]
            })
            guard norm > 1e-12 else { throw ExperimentRunError.rankDeficientLinearModel }
            let alpha = matrix[column][column] >= 0 ? -norm : norm
            var vector = (column..<rowCount).map { matrix[$0][column] }
            vector[0] -= alpha
            let vectorNormSquared = vector.reduce(0) { $0 + $1 * $1 }
            guard vectorNormSquared > 1e-24 else { throw ExperimentRunError.rankDeficientLinearModel }
            let beta = 2 / vectorNormSquared

            for targetColumn in column..<featureCount {
                let projection = beta * vector.indices.reduce(0) { partial, offset in
                    partial + vector[offset] * matrix[column + offset][targetColumn]
                }
                for offset in vector.indices {
                    matrix[column + offset][targetColumn] -= projection * vector[offset]
                }
            }
            let targetProjection = beta * vector.indices.reduce(0) { partial, offset in
                partial + vector[offset] * transformedTarget[column + offset]
            }
            for offset in vector.indices {
                transformedTarget[column + offset] -= targetProjection * vector[offset]
            }
        }

        var scaledCoefficients = Array(repeating: 0.0, count: featureCount)
        for row in stride(from: featureCount - 1, through: 0, by: -1) {
            let diagonal = matrix[row][row]
            guard abs(diagonal) > 1e-11 else { throw ExperimentRunError.rankDeficientLinearModel }
            let known = ((row + 1)..<featureCount).reduce(0) {
                $0 + matrix[row][$1] * scaledCoefficients[$1]
            }
            scaledCoefficients[row] = (transformedTarget[row] - known) / diagonal
        }
        return Self(
            coefficients: zip(scaledCoefficients, scales).map { $0 / $1 },
            scales: scales
        )
    }

    func predict(_ row: [Double]) -> Double {
        zip(coefficients, row).reduce(0) { $0 + $1.0 * $1.1 }
    }
}

private indirect enum ExperimentRegressionTree: Sendable {
    case leaf(Double)
    case node(
        feature: Int,
        threshold: Double,
        left: ExperimentRegressionTree,
        right: ExperimentRegressionTree
    )

    func predict(_ row: [Double]) -> Double {
        switch self {
        case .leaf(let value): value
        case .node(let feature, let threshold, let left, let right):
            row[feature] <= threshold ? left.predict(row) : right.predict(row)
        }
    }

    static func fitRandomForestNode(
        x: [[Double]],
        y: [Double],
        samples: [Int],
        depthRemaining: Int,
        minimumNodeSize: Int,
        mtry: Int,
        generator: inout ExperimentSeededGenerator
    ) -> Self {
        let mean = samples.reduce(0) { $0 + y[$1] } / Double(samples.count)
        guard depthRemaining > 0, samples.count > minimumNodeSize else { return .leaf(mean) }
        var allFeatures = Array(x[0].indices)
        if allFeatures.count > 1 {
            for upper in stride(from: allFeatures.count - 1, through: 1, by: -1) {
                allFeatures.swapAt(upper, generator.index(upperBound: upper + 1))
            }
        }
        let candidates = Array(allFeatures.prefix(min(mtry, allFeatures.count))).sorted()
        guard let split = bestSplit(x: x, y: y, samples: samples, features: candidates) else {
            return .leaf(mean)
        }
        return .node(
            feature: split.feature,
            threshold: split.threshold,
            left: fitRandomForestNode(
                x: x,
                y: y,
                samples: split.left,
                depthRemaining: depthRemaining - 1,
                minimumNodeSize: minimumNodeSize,
                mtry: mtry,
                generator: &generator
            ),
            right: fitRandomForestNode(
                x: x,
                y: y,
                samples: split.right,
                depthRemaining: depthRemaining - 1,
                minimumNodeSize: minimumNodeSize,
                mtry: mtry,
                generator: &generator
            )
        )
    }

    static func fitBoostingTree(
        x: [[Double]],
        residuals: [Double],
        samples: [Int],
        depthRemaining: Int
    ) -> Self {
        let mean = samples.reduce(0) { $0 + residuals[$1] } / Double(samples.count)
        guard depthRemaining > 0, samples.count > 2 else { return .leaf(mean) }
        guard let split = bestSplit(
            x: x,
            y: residuals,
            samples: samples,
            features: Array(x[0].indices)
        ) else {
            return .leaf(mean)
        }
        return .node(
            feature: split.feature,
            threshold: split.threshold,
            left: fitBoostingTree(
                x: x,
                residuals: residuals,
                samples: split.left,
                depthRemaining: depthRemaining - 1
            ),
            right: fitBoostingTree(
                x: x,
                residuals: residuals,
                samples: split.right,
                depthRemaining: depthRemaining - 1
            )
        )
    }

    private struct Split {
        let loss: Double
        let feature: Int
        let threshold: Double
        let left: [Int]
        let right: [Int]
    }

    private static func bestSplit(
        x: [[Double]],
        y: [Double],
        samples: [Int],
        features: [Int]
    ) -> Split? {
        let totalSum = samples.reduce(0) { $0 + y[$1] }
        let totalSquares = samples.reduce(0) { $0 + y[$1] * y[$1] }
        var best: (loss: Double, feature: Int, threshold: Double)?

        for feature in features {
            let ordered = samples.sorted {
                if x[$0][feature] == x[$1][feature] { return $0 < $1 }
                return x[$0][feature] < x[$1][feature]
            }
            var leftSum = 0.0
            var leftSquares = 0.0
            for position in 0..<(ordered.count - 1) {
                let row = ordered[position]
                leftSum += y[row]
                leftSquares += y[row] * y[row]
                let currentValue = x[row][feature]
                let nextValue = x[ordered[position + 1]][feature]
                guard currentValue < nextValue else { continue }
                let leftCount = position + 1
                let rightCount = ordered.count - leftCount
                let rightSum = totalSum - leftSum
                let rightSquares = totalSquares - leftSquares
                let leftLoss = max(0, leftSquares - leftSum * leftSum / Double(leftCount))
                let rightLoss = max(0, rightSquares - rightSum * rightSum / Double(rightCount))
                let loss = leftLoss + rightLoss
                let threshold = currentValue + (nextValue - currentValue) / 2
                if best == nil
                    || loss < best!.loss - 1e-12
                    || (abs(loss - best!.loss) <= 1e-12
                        && (feature < best!.feature
                            || (feature == best!.feature && threshold < best!.threshold))) {
                    best = (loss, feature, threshold)
                }
            }
        }
        guard let best else { return nil }
        let left = samples.filter { x[$0][best.feature] <= best.threshold }
        let right = samples.filter { x[$0][best.feature] > best.threshold }
        guard !left.isEmpty, !right.isEmpty else { return nil }
        return Split(
            loss: best.loss,
            feature: best.feature,
            threshold: best.threshold,
            left: left,
            right: right
        )
    }
}

private struct SeededRandomForest: Sendable {
    let trees: [ExperimentRegressionTree]

    static func fit(
        x: [[Double]],
        y: [Double],
        treeCount: Int,
        mtry: Int,
        maximumDepth: Int,
        minimumNodeSize: Int,
        seed: UInt64
    ) throws -> Self {
        guard !x.isEmpty, !x[0].isEmpty, x.count == y.count else {
            throw ExperimentRunError.emptyTrainingPartition
        }
        var generator = ExperimentSeededGenerator(seed: seed)
        var trees: [ExperimentRegressionTree] = []
        trees.reserveCapacity(treeCount)
        for treeIndex in 0..<treeCount {
            if treeIndex.isMultiple(of: 25) { try Task.checkCancellation() }
            let bootstrap = (0..<x.count).map { _ in generator.index(upperBound: x.count) }
            trees.append(.fitRandomForestNode(
                x: x,
                y: y,
                samples: bootstrap,
                depthRemaining: maximumDepth,
                minimumNodeSize: minimumNodeSize,
                mtry: mtry,
                generator: &generator
            ))
        }
        return Self(trees: trees)
    }

    func predict(_ row: [Double]) -> Double {
        trees.reduce(0) { $0 + $1.predict(row) } / Double(trees.count)
    }
}

private struct NativeGradientTreeBoosting: Sendable {
    let base: Double
    let trees: [ExperimentRegressionTree]
    let learningRate: Double

    static func fit(
        x: [[Double]],
        y: [Double],
        maximumDepth: Int,
        learningRate: Double,
        rounds: Int
    ) throws -> Self {
        guard !x.isEmpty, !x[0].isEmpty, x.count == y.count else {
            throw ExperimentRunError.emptyTrainingPartition
        }
        let base = y.reduce(0, +) / Double(y.count)
        var fitted = Array(repeating: base, count: y.count)
        var trees: [ExperimentRegressionTree] = []
        trees.reserveCapacity(rounds)
        let samples = Array(y.indices)
        for round in 0..<rounds {
            if round.isMultiple(of: 10) { try Task.checkCancellation() }
            let residuals = zip(y, fitted).map(-)
            let tree = ExperimentRegressionTree.fitBoostingTree(
                x: x,
                residuals: residuals,
                samples: samples,
                depthRemaining: maximumDepth
            )
            trees.append(tree)
            for index in fitted.indices {
                fitted[index] += learningRate * tree.predict(x[index])
            }
        }
        return Self(base: base, trees: trees, learningRate: learningRate)
    }

    func predict(_ row: [Double]) -> Double {
        base + learningRate * trees.reduce(0) { $0 + $1.predict(row) }
    }
}
