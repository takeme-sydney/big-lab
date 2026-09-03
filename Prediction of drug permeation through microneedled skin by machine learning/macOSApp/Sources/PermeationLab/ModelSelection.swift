import CryptoKit
import Foundation

/// Parses only finite values. `Double("nan")` and infinities are technically
/// valid Swift values, but they must never enter a scientific training run.
func finiteDouble(_ source: String) -> Double? {
    guard let value = Double(source.trimmingCharacters(in: .whitespacesAndNewlines)),
          value.isFinite else { return nil }
    return value
}

struct GenericDataset: Sendable {
    let name: String
    let headers: [String]
    let rows: [[String]]

    var numericColumns: [Int] {
        headers.indices.filter { index in
            let values = rows.map { $0[index].trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            guard !values.isEmpty else { return false }
            return Double(values.compactMap(finiteDouble).count) / Double(values.count) >= 0.9
        }
    }

    /// Stable identity for a parsed table. It intentionally hashes normalized
    /// parsed values rather than claiming identity with an original source file.
    var normalizedSHA256: String {
        let escaped = ([headers] + rows).map { row in
            row.map {
                $0.trimmingCharacters(in: .whitespacesAndNewlines)
                    .replacingOccurrences(of: "\\", with: "\\\\")
                    .replacingOccurrences(of: "\u{1F}", with: "\\u001F")
            }.joined(separator: "\u{1F}")
        }.joined(separator: "\u{1E}")
        return SHA256.hash(data: Data(escaped.utf8))
            .map { String(format: "%02x", $0) }
            .joined()
    }

    static func parse(
        name: String,
        text: String,
        minimumColumnCount: Int = 2
    ) throws -> GenericDataset {
        try validateCSVQuoteSyntax(text)
        let records = TrainingDataSource.parseCSV(text)
        guard let header = records.first, header.count >= minimumColumnCount else {
            throw SelectionError.invalidCSV(BiText(
                "\(minimumColumnCount)列以上のヘッダーを含むCSVが必要です。",
                "The CSV must contain a header with at least \(minimumColumnCount) column(s)."
            ))
        }
        let normalizedHeaders = header.enumerated().map { offset, value in
            let cleaned = value.trimmingCharacters(in: .whitespacesAndNewlines)
            return cleaned.isEmpty ? "Column \(offset + 1)" : cleaned
        }
        guard Set(normalizedHeaders).count == normalizedHeaders.count else {
            throw SelectionError.invalidCSV(BiText("列名は重複できません。", "Column names must be unique."))
        }
        let body = records.dropFirst().filter { $0.contains(where: { !$0.isEmpty }) }
        guard !body.isEmpty else { throw SelectionError.invalidCSV(BiText("データ行がありません。", "The CSV contains no data rows.")) }
        guard body.allSatisfy({ $0.count == normalizedHeaders.count }) else {
            throw SelectionError.invalidCSV(BiText("すべての行の列数をヘッダーと一致させてください。", "Every row must have the same number of columns as the header."))
        }
        guard body.count <= 5_000 else {
            throw SelectionError.invalidCSV(BiText("この端末内評価では5,000行までに制限しています。", "On-device evaluation is limited to 5,000 rows."))
        }
        return GenericDataset(name: name, headers: normalizedHeaders, rows: Array(body))
    }

    private enum CSVQuoteState {
        case fieldStart
        case unquoted
        case quoted
        case closedQuote
    }

    /// `TrainingDataSource.parseCSV` intentionally exposes records only, so
    /// generic uploads validate quote syntax before consuming those records.
    private static func validateCSVQuoteSyntax(_ text: String) throws {
        var state = CSVQuoteState.fieldStart
        var row = 1
        var index = text.startIndex

        func malformed() -> SelectionError {
            SelectionError.invalidCSV(
                BiText(
                    "CSVの引用符構文が不正です（行\(row)）。",
                    "Malformed CSV quoting at row \(row)."
                )
            )
        }

        while index < text.endIndex {
            let character = text[index]
            let isRecordSeparator = character == "\n" || character == "\r" || character == "\r\n"
            switch state {
            case .fieldStart:
                if character == "\"" {
                    state = .quoted
                } else if character == "," {
                    break
                } else if isRecordSeparator {
                    row += 1
                } else {
                    state = .unquoted
                }

            case .unquoted:
                if character == "\"" { throw malformed() }
                if character == "," {
                    state = .fieldStart
                } else if isRecordSeparator {
                    state = .fieldStart
                    row += 1
                }

            case .quoted:
                if character == "\"" {
                    let next = text.index(after: index)
                    if next < text.endIndex, text[next] == "\"" {
                        index = next
                    } else {
                        state = .closedQuote
                    }
                }

            case .closedQuote:
                if character == "," {
                    state = .fieldStart
                } else if isRecordSeparator {
                    state = .fieldStart
                    row += 1
                } else {
                    throw malformed()
                }
            }
            index = text.index(after: index)
        }

        if state == .quoted { throw malformed() }
    }

    static var paperData: GenericDataset {
        from(trainingDataset: TrainingDataSource.bundled, name: "Yuan 2023 · Data S1")
    }

    static func from(trainingDataset: TrainingDataset, name: String) -> GenericDataset {
        let headers = ["Drug", "Loading", "Molecular weight", "MN length", "Skin", "MN type", "Surface area", "Time", "Permeation percentage", "Permeation amount"]
        let rows = trainingDataset.rows.map { row in
            [row.sourceDrugName, String(row.loading), String(row.molecularWeight), String(row.needleLength), row.skin.rawValue, row.needle.rawValue, String(row.surfaceArea), String(row.permeationTime), String(row.percentage), String(row.amount)]
        }
        return GenericDataset(name: name, headers: headers, rows: rows)
    }
}

enum SelectionError: LocalizedError, Equatable {
    case invalidCSV(BiText)
    case invalidConfiguration(BiText)

    var errorDescription: String? {
        switch self {
        case .invalidCSV(let message), .invalidConfiguration(let message): message.english
        }
    }

    func message(_ language: AppLanguage) -> String {
        switch self {
        case .invalidCSV(let message), .invalidConfiguration(let message):
            message.resolve(language)
        }
    }
}

enum CandidateFamily: String, CaseIterable, Codable, Identifiable, Sendable {
    case linear = "Ridge regression"
    case randomForest = "Random Forest"
    case gradientBoosting = "Gradient Boosting"

    var id: Self { self }

    func displayName(_ language: AppLanguage) -> String {
        switch self {
        case .linear: language.text("線形回帰（Ridge）", "Ridge regression")
        case .randomForest: language.text("Random Forest系", "Random Forest")
        case .gradientBoosting: language.text("Gradient Boosting系", "Gradient Boosting")
        }
    }

    func detail(_ language: AppLanguage) -> String {
        switch self {
        case .linear: language.text("小標本・説明性・ほぼ加法的な関係に強い基準モデル", "A strong baseline for small samples, interpretability, and mostly additive relationships")
        case .randomForest: language.text("非線形・相互作用に強く、調整が比較的安定", "Handles nonlinearity and interactions with relatively stable tuning")
        case .gradientBoosting: language.text("複雑な表形式データに強いXGBoost候補。過学習の監視が必要", "An XGBoost candidate for complex tabular data; requires overfitting checks")
        }
    }
}

struct SelectionMetric: Codable, Equatable, Identifiable, Sendable {
    let family: CandidateFamily
    let rmse: Double
    let mae: Double
    let rSquared: Double
    let foldRMSEStandardDeviation: Double
    let groupBalancedRMSE: Double?
    let groupBalancedMAE: Double?
    var id: CandidateFamily { family }
}

struct ModelSelectionReport: Equatable, Sendable {
    let configurationSHA256: String
    let metrics: [SelectionMetric]
    let winner: CandidateFamily
    let foldCount: Int
    let usedGroupHoldout: Bool
    let observationCount: Int
    let featureCount: Int
    let excludedColumns: [String]
    let baselineRMSE: Double
    let warnings: [BiText]
}

enum ModelSelectionEngine {
    static func evaluate(dataset: GenericDataset, target: Int, group: Int?, features: Set<Int>? = nil) throws -> ModelSelectionReport {
        guard dataset.numericColumns.contains(target) else {
            throw SelectionError.invalidConfiguration(BiText("目的変数には90%以上が数値の列を選択してください。", "Choose a target column with at least 90% numeric values."))
        }
        if group == target { throw SelectionError.invalidConfiguration(BiText("目的変数とグループ列は分けてください。", "The target and group columns must be different.")) }

        let selectedFeatures = features ?? Set(dataset.headers.indices.filter { $0 != target && $0 != group })
        guard !selectedFeatures.isEmpty else {
            throw SelectionError.invalidConfiguration(BiText("説明変数を1列以上選択してください。", "Select at least one predictor column."))
        }
        let encoded = try encode(dataset: dataset, target: target, group: group, features: selectedFeatures)
        guard encoded.y.count >= 20 else {
            throw SelectionError.invalidConfiguration(BiText("交差検証には、有効な目的変数を持つ行が20件以上必要です。", "Cross-validation requires at least 20 rows with a valid target value."))
        }
        let assignments = makeFoldAssignments(groups: encoded.groups, rowCount: encoded.y.count)
        let foldCount = (assignments.max() ?? 0) + 1
        guard foldCount >= 2 else {
            throw SelectionError.invalidConfiguration(BiText("グループを2種類以上用意するか、グループ指定を解除してください。", "Provide at least two groups or disable group holdout."))
        }

        var predictions = Dictionary(uniqueKeysWithValues: CandidateFamily.allCases.map { ($0, Array(repeating: 0.0, count: encoded.y.count)) })
        var baselinePredictions = Array(repeating: 0.0, count: encoded.y.count)
        var maximumFeatureCount = 0
        var usedFeatureIndices = Set<Int>()
        for fold in 0..<foldCount {
            if Task.isCancelled { throw CancellationError() }
            let train = assignments.indices.filter { assignments[$0] != fold }
            let test = assignments.indices.filter { assignments[$0] == fold }
            guard !train.isEmpty, !test.isEmpty else { continue }

            // Fit every data-dependent transform on this fold's training rows only.
            // Validation rows are then projected into that immutable training schema.
            let preprocessor = FoldPreprocessor.fit(
                rows: encoded.rows,
                featureIndices: encoded.featureIndices,
                trainingIndices: train
            )
            maximumFeatureCount = max(maximumFeatureCount, preprocessor.outputDimension)
            usedFeatureIndices.formUnion(preprocessor.includedFeatureIndices)
            let x = preprocessor.transform(rows: encoded.rows)
            let normalizer = Normalizer.fit(x, indices: train)
            let normalized = normalizer.transform(x)

            let linear = RidgeRegressor.fit(x: normalized, y: encoded.y, indices: train)
            let forest = ForestRegressor.fit(x: normalized, y: encoded.y, indices: train, seed: UInt64(fold + 17))
            let boosting = BoostingRegressor.fit(x: normalized, y: encoded.y, indices: train)
            let trainingMean = train.reduce(0) { $0 + encoded.y[$1] } / Double(train.count)
            for index in test {
                baselinePredictions[index] = trainingMean
                predictions[.linear]![index] = linear.predict(normalized[index])
                predictions[.randomForest]![index] = forest.predict(normalized[index])
                predictions[.gradientBoosting]![index] = boosting.predict(normalized[index])
            }
        }
        guard maximumFeatureCount > 0 else {
            throw SelectionError.invalidConfiguration(BiText("評価に使える説明変数がありません。", "No usable predictor columns are available for evaluation."))
        }

        let metrics = CandidateFamily.allCases.map { family -> SelectionMetric in
            let predicted = predictions[family]!
            let aggregate = regressionMetrics(actual: encoded.y, predicted: predicted)
            let foldRMSEs = (0..<foldCount).compactMap { fold -> Double? in
                let indices = assignments.indices.filter { assignments[$0] == fold }
                guard !indices.isEmpty else { return nil }
                return regressionMetrics(
                    actual: indices.map { encoded.y[$0] },
                    predicted: indices.map { predicted[$0] }
                ).rmse
            }
            let foldMean = foldRMSEs.reduce(0, +) / Double(max(1, foldRMSEs.count))
            let foldSD = sqrt(
                foldRMSEs.reduce(0) { $0 + pow($1 - foldMean, 2) }
                    / Double(max(1, foldRMSEs.count))
            )
            let balanced = encoded.groups.map {
                groupBalancedMetrics(actual: encoded.y, predicted: predicted, groups: $0)
            }
            return SelectionMetric(
                family: family,
                rmse: aggregate.rmse,
                mae: aggregate.mae,
                rSquared: aggregate.rSquared,
                foldRMSEStandardDeviation: foldSD,
                groupBalancedRMSE: balanced?.rmse,
                groupBalancedMAE: balanced?.mae
            )
        }.sorted { $0.rmse < $1.rmse }
        let baselineRMSE = regressionMetrics(actual: encoded.y, predicted: baselinePredictions).rmse

        var warnings: [BiText] = []
        if group == nil { warnings.append(BiText("通常の行単位CVです。未知薬物・患者・バッチへの一般化を判断する場合はグループ列を指定してください。", "This is standard row-wise CV. Select a group column when assessing generalization to unseen drugs, patients, or batches.")) }
        if encoded.y.count < 100 { warnings.append(BiText("有効行が100件未満のため、順位の不確実性が大きい可能性があります。", "Fewer than 100 valid rows are available, so ranking uncertainty may be high.")) }
        if Double(encoded.y.count) / Double(maximumFeatureCount) < 10 { warnings.append(BiText("1特徴量あたりの行数が10未満です。特徴量削減または追加データを検討してください。", "There are fewer than 10 rows per feature. Consider feature reduction or additional data.")) }
        if metrics.first?.rSquared ?? 0 < 0 { warnings.append(BiText("最良候補でも平均値予測を下回っています。特徴量、分割、測定品質を見直してください。", "Even the best candidate underperforms mean prediction. Review the features, split, and measurement quality.")) }
        warnings.append(BiText("3候補から最小RMSEを選んだ同じCV結果は、選定後の性能をやや楽観的に示す可能性があります。最終モデルは未使用の外部データで評価してください。", "Choosing the minimum RMSE from the same CV can make post-selection performance optimistic. Evaluate the final model on untouched external data."))

        return ModelSelectionReport(
            configurationSHA256: configurationSHA256(
                dataset: dataset,
                target: target,
                group: group,
                features: selectedFeatures
            ),
            metrics: metrics,
            winner: metrics[0].family,
            foldCount: foldCount,
            usedGroupHoldout: group != nil,
            observationCount: encoded.y.count,
            featureCount: maximumFeatureCount,
            excludedColumns: encoded.featureIndices
                .filter { !usedFeatureIndices.contains($0) }
                .map { dataset.headers[$0] },
            baselineRMSE: baselineRMSE,
            warnings: warnings
        )
    }

    static func configurationSHA256(
        dataset: GenericDataset,
        target: Int,
        group: Int?,
        features: Set<Int>
    ) -> String {
        let fields = [
            dataset.normalizedSHA256,
            "target=\(target):\(dataset.headers.indices.contains(target) ? dataset.headers[target] : "invalid")",
            "group=\(group.map(String.init) ?? "none")",
            "features=\(features.sorted().map(String.init).joined(separator: ","))",
            "engine=\(LocalModelArtifact.engineVersion)",
        ]
        return SHA256.hash(data: Data(fields.joined(separator: "\u{1F}").utf8))
            .map { String(format: "%02x", $0) }
            .joined()
    }

    private struct Encoded {
        let rows: [[String]]
        let y: [Double]
        let groups: [String]?
        let featureIndices: [Int]
    }

    private static func encode(dataset: GenericDataset, target: Int, group: Int?, features: Set<Int>) throws -> Encoded {
        let validRows = dataset.rows.filter { finiteDouble($0[target]) != nil }
        if let group {
            let missingGroupCount = validRows.filter {
                $0[group].trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            }.count
            guard missingGroupCount == 0 else {
                throw SelectionError.invalidConfiguration(BiText(
                    "分割グループに空欄が\(missingGroupCount)行あります。各行へrun/curve/薬物などのグループIDを設定してください。",
                    "The split-group column is empty in \(missingGroupCount) row(s). Assign a run, curve, drug, or other group ID to every row."
                ))
            }
        }
        let featureIndices = dataset.headers.indices.filter {
            features.contains($0) && $0 != target && $0 != group
        }
        return Encoded(
            rows: validRows,
            y: validRows.compactMap { finiteDouble($0[target]) },
            groups: group.map { column in
                validRows.map { $0[column].trimmingCharacters(in: .whitespacesAndNewlines) }
            },
            featureIndices: featureIndices
        )
    }

    static func makeFoldAssignments(groups: [String]?, rowCount: Int) -> [Int] {
        if let groups {
            let frequencies = Dictionary(grouping: groups, by: { $0 }).mapValues(\.count)
            let unique = frequencies.keys.sorted {
                if frequencies[$0] == frequencies[$1] { return $0 < $1 }
                return frequencies[$0, default: 0] > frequencies[$1, default: 0]
            }
            let count = min(5, unique.count)
            var foldSizes = Array(repeating: 0, count: max(1, count))
            var map: [String: Int] = [:]
            for value in unique {
                let fold = foldSizes.indices.min {
                    if foldSizes[$0] == foldSizes[$1] { return $0 < $1 }
                    return foldSizes[$0] < foldSizes[$1]
                } ?? 0
                map[value] = fold
                foldSizes[fold] += frequencies[value, default: 0]
            }
            return groups.map { map[$0] ?? 0 }
        }
        let count = min(5, max(2, rowCount / 10))
        return (0..<rowCount).map { ($0 * 1_103 + 97) % count }
    }

    private static func regressionMetrics(
        actual: [Double],
        predicted: [Double]
    ) -> (rmse: Double, mae: Double, rSquared: Double) {
        let errors = zip(actual, predicted).map { $0 - $1 }
        let squared = errors.reduce(0) { $0 + $1 * $1 }
        let mean = actual.reduce(0, +) / Double(max(1, actual.count))
        let total = actual.reduce(0) { $0 + pow($1 - mean, 2) }
        return (
            sqrt(squared / Double(max(1, errors.count))),
            errors.reduce(0) { $0 + abs($1) } / Double(max(1, errors.count)),
            total > 0 ? 1 - squared / total : 0
        )
    }

    private static func groupBalancedMetrics(
        actual: [Double], predicted: [Double], groups: [String]
    ) -> (rmse: Double, mae: Double) {
        let indicesByGroup = Dictionary(grouping: groups.indices, by: { groups[$0] })
        let perGroup = indicesByGroup.values.map { indices -> (mse: Double, mae: Double) in
            let errors = indices.map { actual[$0] - predicted[$0] }
            return (
                errors.reduce(0) { $0 + $1 * $1 } / Double(errors.count),
                errors.reduce(0) { $0 + abs($1) } / Double(errors.count)
            )
        }
        return (
            sqrt(perGroup.reduce(0) { $0 + $1.mse } / Double(max(1, perGroup.count))),
            perGroup.reduce(0) { $0 + $1.mae } / Double(max(1, perGroup.count))
        )
    }
}

/// A fold-local schema for numeric imputation and categorical encoding.
/// Internal visibility lets the test target verify that held-out values never
/// participate in fitting the schema.
struct FoldPreprocessor: Codable, Equatable, Sendable {
    enum Column: Codable, Equatable, Sendable {
        case numeric(index: Int, median: Double)
        case categorical(index: Int, levels: [String])

        var index: Int {
            switch self {
            case .numeric(let index, _), .categorical(let index, _): index
            }
        }
    }

    let columns: [Column]

    var outputDimension: Int {
        columns.reduce(0) { count, column in
            switch column {
            case .numeric: count + 1
            case .categorical(_, let levels): count + max(0, levels.count - 1)
            }
        }
    }

    var includedFeatureIndices: Set<Int> { Set(columns.map(\.index)) }

    func validatedOutputDimensionForArtifact(
        sourceColumnCount: Int,
        maximumColumnCount: Int,
        maximumCategoryLevelCount: Int,
        maximumStringUTF8ByteCount: Int,
        maximumOutputDimension: Int
    ) throws -> Int {
        guard !columns.isEmpty, columns.count <= maximumColumnCount else {
            throw ModelPayloadValidationError.invalid("preprocessor column count is outside the allowed range")
        }

        var seenIndices = Set<Int>()
        var dimension = 0
        for column in columns {
            guard (0..<sourceColumnCount).contains(column.index) else {
                throw ModelPayloadValidationError.invalid("preprocessor column index is out of range")
            }
            guard seenIndices.insert(column.index).inserted else {
                throw ModelPayloadValidationError.invalid("preprocessor column indices must be unique")
            }

            switch column {
            case .numeric(_, let median):
                guard median.isFinite else {
                    throw ModelPayloadValidationError.invalid("numeric imputation median must be finite")
                }
                dimension += 1

            case .categorical(_, let levels):
                guard (2...maximumCategoryLevelCount).contains(levels.count) else {
                    throw ModelPayloadValidationError.invalid("categorical level count is outside the allowed range")
                }
                guard Set(levels).count == levels.count,
                      levels.allSatisfy({ !$0.isEmpty && $0.utf8.count <= maximumStringUTF8ByteCount }) else {
                    throw ModelPayloadValidationError.invalid("categorical levels must be unique, non-empty, and bounded")
                }
                dimension += levels.count - 1
            }

            guard dimension <= maximumOutputDimension else {
                throw ModelPayloadValidationError.invalid("preprocessor output exceeds the encoded feature limit")
            }
        }
        guard dimension > 0 else {
            throw ModelPayloadValidationError.invalid("preprocessor output dimension must be positive")
        }
        return dimension
    }

    static func fit(rows: [[String]], featureIndices: [Int], trainingIndices: [Int]) -> FoldPreprocessor {
        let columns = featureIndices.compactMap { index -> Column? in
            let values = trainingIndices
                .map { rows[$0][index].trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            guard !values.isEmpty else { return nil }

            let numericValues = values.compactMap(finiteDouble)
            let numericRatio = Double(numericValues.count) / Double(values.count)
            if numericRatio >= 0.9 {
                return .numeric(index: index, median: median(numericValues))
            }

            let levels = Array(Set(values)).sorted()
            guard levels.count >= 2, levels.count <= 12 else { return nil }
            return .categorical(index: index, levels: levels)
        }
        return FoldPreprocessor(columns: columns)
    }

    func transform(rows: [[String]]) -> [[Double]] { rows.map(transform(row:)) }

    func transform(row: [String]) -> [Double] {
        columns.flatMap { column -> [Double] in
            switch column {
            case .numeric(let index, let median):
                let value = row[index].trimmingCharacters(in: .whitespacesAndNewlines)
                return [finiteDouble(value) ?? median]
            case .categorical(let index, let levels):
                let value = row[index].trimmingCharacters(in: .whitespacesAndNewlines)
                return levels.dropLast().map { value == $0 ? 1 : 0 }
            }
        }
    }

    private static func median(_ values: [Double]) -> Double {
        let sorted = values.sorted()
        guard !sorted.isEmpty else { return 0 }
        let middle = sorted.count / 2
        if sorted.count.isMultiple(of: 2) {
            return (sorted[middle - 1] + sorted[middle]) / 2
        }
        return sorted[middle]
    }
}

struct Normalizer: Codable, Equatable, Sendable {
    let means: [Double]; let scales: [Double]
    static func fit(_ x: [[Double]], indices: [Int]) -> Normalizer {
        let count = x[0].count
        let means = (0..<count).map { column in indices.reduce(0) { $0 + x[$1][column] } / Double(indices.count) }
        let scales = (0..<count).map { column in
            let variance = indices.reduce(0) { $0 + pow(x[$1][column] - means[column], 2) } / Double(indices.count)
            return max(sqrt(variance), 1e-9)
        }
        return Normalizer(means: means, scales: scales)
    }
    func transform(_ x: [[Double]]) -> [[Double]] { x.map { row in row.indices.map { (row[$0] - means[$0]) / scales[$0] } } }

    func validateForArtifact(featureCount: Int) throws {
        guard means.count == featureCount, scales.count == featureCount else {
            throw ModelPayloadValidationError.invalid("normalizer dimensions do not match the encoded feature count")
        }
        guard means.allSatisfy(\.isFinite) else {
            throw ModelPayloadValidationError.invalid("normalizer means contain a non-finite value")
        }
        guard scales.allSatisfy({ $0.isFinite && $0 > 0 }) else {
            throw ModelPayloadValidationError.invalid("normalizer scales must be finite and positive")
        }
    }
}

struct RidgeRegressor: Codable, Equatable, Sendable {
    let weights: [Double]
    static func fit(x: [[Double]], y: [Double], indices: [Int]) -> RidgeRegressor {
        let p = x[0].count + 1
        var matrix = Array(repeating: Array(repeating: 0.0, count: p), count: p)
        var vector = Array(repeating: 0.0, count: p)
        for index in indices {
            let row = [1.0] + x[index]
            for a in 0..<p {
                vector[a] += row[a] * y[index]
                for b in 0..<p { matrix[a][b] += row[a] * row[b] }
            }
        }
        for index in 1..<p { matrix[index][index] += 1.0 }
        return RidgeRegressor(weights: solve(matrix, vector))
    }
    func predict(_ row: [Double]) -> Double { zip(weights, [1.0] + row).reduce(0) { $0 + $1.0 * $1.1 } }

    func validateForArtifact(featureCount: Int) throws {
        guard weights.count == featureCount + 1 else {
            throw ModelPayloadValidationError.invalid("ridge weight count does not match intercept plus encoded features")
        }
        guard weights.allSatisfy(\.isFinite) else {
            throw ModelPayloadValidationError.invalid("ridge weights contain a non-finite value")
        }
    }
}

private func solve(_ source: [[Double]], _ rhs: [Double]) -> [Double] {
    var a = source; var b = rhs; let n = b.count
    for pivot in 0..<n {
        let best = (pivot..<n).max { abs(a[$0][pivot]) < abs(a[$1][pivot]) } ?? pivot
        a.swapAt(pivot, best); b.swapAt(pivot, best)
        let divisor = abs(a[pivot][pivot]) < 1e-12 ? 1e-12 : a[pivot][pivot]
        for column in pivot..<n { a[pivot][column] /= divisor }; b[pivot] /= divisor
        for row in 0..<n where row != pivot {
            let factor = a[row][pivot]
            for column in pivot..<n { a[row][column] -= factor * a[pivot][column] }
            b[row] -= factor * b[pivot]
        }
    }
    return b
}

indirect enum RegressionTree: Codable, Equatable, Sendable {
    typealias Split = (loss: Double, feature: Int, threshold: Double, left: [Int], right: [Int])

    case leaf(Double)
    case node(feature: Int, threshold: Double, left: RegressionTree, right: RegressionTree)
    func predict(_ row: [Double]) -> Double {
        switch self {
        case .leaf(let value): value
        case .node(let feature, let threshold, let left, let right): row[feature] <= threshold ? left.predict(row) : right.predict(row)
        }
    }
    static func fit(x: [[Double]], y: [Double], indices: [Int], depth: Int, features: [Int]? = nil) -> RegressionTree {
        let mean = indices.reduce(0) { $0 + y[$1] } / Double(indices.count)
        guard depth > 0, indices.count >= 8 else { return .leaf(mean) }
        let candidates = features ?? Array(x[0].indices)
        guard let best = bestSplit(x: x, y: y, indices: indices, candidates: candidates) else { return .leaf(mean) }
        return .node(
            feature: best.feature,
            threshold: best.threshold,
            left: fit(x: x, y: y, indices: best.left, depth: depth - 1, features: features),
            right: fit(x: x, y: y, indices: best.right, depth: depth - 1, features: features)
        )
    }

    static func fitRandomSubspace(
        x: [[Double]],
        y: [Double],
        indices: [Int],
        depth: Int,
        featureCount: Int,
        rng: inout SeededGenerator
    ) -> RegressionTree {
        let mean = indices.reduce(0) { $0 + y[$1] } / Double(indices.count)
        guard depth > 0, indices.count >= 8, !x[0].isEmpty else { return .leaf(mean) }

        // A fresh subset is drawn at every node, matching Random Forest's
        // random-subspace rule rather than fixing one subset for the whole tree.
        let candidates = Array(
            x[0].indices.shuffled(using: &rng).prefix(min(featureCount, x[0].count))
        )
        guard let best = bestSplit(x: x, y: y, indices: indices, candidates: candidates) else { return .leaf(mean) }
        let left = fitRandomSubspace(
            x: x,
            y: y,
            indices: best.left,
            depth: depth - 1,
            featureCount: featureCount,
            rng: &rng
        )
        let right = fitRandomSubspace(
            x: x,
            y: y,
            indices: best.right,
            depth: depth - 1,
            featureCount: featureCount,
            rng: &rng
        )
        return .node(feature: best.feature, threshold: best.threshold, left: left, right: right)
    }

    private static func bestSplit(
        x: [[Double]],
        y: [Double],
        indices: [Int],
        candidates: [Int]
    ) -> Split? {
        var best: Split?
        for feature in candidates {
            let sorted = indices.sorted { x[$0][feature] < x[$1][feature] }
            for position in stride(from: 3, to: sorted.count - 3, by: max(1, sorted.count / 12)) {
                let threshold = (x[sorted[position - 1]][feature] + x[sorted[position]][feature]) / 2
                let left = sorted.filter { x[$0][feature] <= threshold }; let right = sorted.filter { x[$0][feature] > threshold }
                guard !left.isEmpty, !right.isEmpty else { continue }
                let lm = left.reduce(0) { $0 + y[$1] } / Double(left.count); let rm = right.reduce(0) { $0 + y[$1] } / Double(right.count)
                let loss = left.reduce(0) { $0 + pow(y[$1] - lm, 2) } + right.reduce(0) { $0 + pow(y[$1] - rm, 2) }
                if best == nil || loss < best!.loss { best = (loss, feature, threshold, left, right) }
            }
        }
        return best
    }


    /// Iterative validation avoids recursing through an imported tree before
    /// its depth is known to be safe.
    func validateForArtifact(
        featureCount: Int,
        maximumDepth: Int,
        maximumNodeCount: Int
    ) throws -> RegressionTreeValidationSummary {
        guard featureCount > 0, maximumDepth > 0, maximumNodeCount > 0 else {
            throw ModelPayloadValidationError.invalid("invalid tree validation limits")
        }

        var stack: [(tree: RegressionTree, depth: Int)] = [(self, 1)]
        var nodeCount = 0
        var observedDepth = 0
        while let current = stack.popLast() {
            nodeCount += 1
            guard nodeCount <= maximumNodeCount else {
                throw ModelPayloadValidationError.invalid("regression tree exceeds the node limit")
            }
            guard current.depth <= maximumDepth else {
                throw ModelPayloadValidationError.invalid("regression tree exceeds the depth limit")
            }
            observedDepth = max(observedDepth, current.depth)

            switch current.tree {
            case .leaf(let value):
                guard value.isFinite else {
                    throw ModelPayloadValidationError.invalid("regression tree contains a non-finite leaf value")
                }

            case .node(let feature, let threshold, let left, let right):
                guard (0..<featureCount).contains(feature) else {
                    throw ModelPayloadValidationError.invalid("regression tree feature index is out of range")
                }
                guard threshold.isFinite else {
                    throw ModelPayloadValidationError.invalid("regression tree contains a non-finite threshold")
                }
                stack.append((left, current.depth + 1))
                stack.append((right, current.depth + 1))
            }
        }
        return RegressionTreeValidationSummary(nodeCount: nodeCount, depth: observedDepth)
    }
}

struct RegressionTreeValidationSummary: Equatable, Sendable {
    let nodeCount: Int
    let depth: Int
}

enum ModelPayloadValidationError: LocalizedError, Equatable {
    case invalid(String)

    var errorDescription: String? {
        switch self {
        case .invalid(let reason): reason
        }
    }
}

struct SeededGenerator: RandomNumberGenerator {
    var state: UInt64
    mutating func next() -> UInt64 { state = state &* 6_364_136_223_846_793_005 &+ 1; return state }
}

struct ForestRegressor: Codable, Equatable, Sendable {
    let trees: [RegressionTree]
    static func fit(x: [[Double]], y: [Double], indices: [Int], seed: UInt64) -> ForestRegressor {
        var rng = SeededGenerator(state: seed); let featureCount = max(1, Int(sqrt(Double(x[0].count))))
        let trees = (0..<36).map { _ -> RegressionTree in
            let sample = (0..<indices.count).map { _ in indices[Int.random(in: 0..<indices.count, using: &rng)] }
            return RegressionTree.fitRandomSubspace(
                x: x,
                y: y,
                indices: sample,
                depth: 5,
                featureCount: featureCount,
                rng: &rng
            )
        }
        return ForestRegressor(trees: trees)
    }
    func predict(_ row: [Double]) -> Double { trees.reduce(0) { $0 + $1.predict(row) } / Double(trees.count) }

    func validateForArtifact(
        featureCount: Int,
        maximumTreeCount: Int,
        maximumTreeDepth: Int,
        maximumNodesPerTree: Int,
        maximumTotalNodeCount: Int
    ) throws {
        guard !trees.isEmpty else {
            throw ModelPayloadValidationError.invalid("random forest must contain at least one tree")
        }
        guard trees.count <= maximumTreeCount else {
            throw ModelPayloadValidationError.invalid("random forest exceeds the tree limit")
        }

        var totalNodeCount = 0
        for (index, tree) in trees.enumerated() {
            do {
                let summary = try tree.validateForArtifact(
                    featureCount: featureCount,
                    maximumDepth: maximumTreeDepth,
                    maximumNodeCount: maximumNodesPerTree
                )
                totalNodeCount += summary.nodeCount
                guard totalNodeCount <= maximumTotalNodeCount else {
                    throw ModelPayloadValidationError.invalid("random forest exceeds the total node limit")
                }
            } catch let error as ModelPayloadValidationError {
                throw error.prefixed("random forest tree \(index + 1)")
            }
        }
    }
}

struct BoostingRegressor: Codable, Equatable, Sendable {
    let base: Double
    let trees: [RegressionTree]
    let rate: Double
    static func fit(x: [[Double]], y: [Double], indices: [Int]) -> BoostingRegressor {
        let base = indices.reduce(0) { $0 + y[$1] } / Double(indices.count); var prediction = Array(repeating: base, count: y.count); var trees: [RegressionTree] = []
        for _ in 0..<48 {
            let residual = y.indices.map { y[$0] - prediction[$0] }
            let tree = RegressionTree.fit(x: x, y: residual, indices: indices, depth: 2)
            trees.append(tree)
            for index in indices { prediction[index] += 0.08 * tree.predict(x[index]) }
        }
        return BoostingRegressor(base: base, trees: trees, rate: 0.08)
    }
    func predict(_ row: [Double]) -> Double { base + rate * trees.reduce(0) { $0 + $1.predict(row) } }

    func validateForArtifact(
        featureCount: Int,
        maximumTreeCount: Int,
        maximumTreeDepth: Int,
        maximumNodesPerTree: Int,
        maximumTotalNodeCount: Int
    ) throws {
        guard base.isFinite else {
            throw ModelPayloadValidationError.invalid("gradient boosting base value must be finite")
        }
        guard rate.isFinite, rate > 0, rate <= 1 else {
            throw ModelPayloadValidationError.invalid("gradient boosting rate must be finite and in (0, 1]")
        }
        guard !trees.isEmpty else {
            throw ModelPayloadValidationError.invalid("gradient boosting must contain at least one tree")
        }
        guard trees.count <= maximumTreeCount else {
            throw ModelPayloadValidationError.invalid("gradient boosting exceeds the tree limit")
        }

        var totalNodeCount = 0
        for (index, tree) in trees.enumerated() {
            do {
                let summary = try tree.validateForArtifact(
                    featureCount: featureCount,
                    maximumDepth: maximumTreeDepth,
                    maximumNodeCount: maximumNodesPerTree
                )
                totalNodeCount += summary.nodeCount
                guard totalNodeCount <= maximumTotalNodeCount else {
                    throw ModelPayloadValidationError.invalid("gradient boosting exceeds the total node limit")
                }
            } catch let error as ModelPayloadValidationError {
                throw error.prefixed("gradient boosting tree \(index + 1)")
            }
        }
    }
}

private extension ModelPayloadValidationError {
    func prefixed(_ prefix: String) -> ModelPayloadValidationError {
        switch self {
        case .invalid(let reason): .invalid("\(prefix): \(reason)")
        }
    }
}

struct ExploratoryProfilePoint: Identifiable, Equatable, Sendable {
    let model: ModelKind
    let time: Double
    let value: Double

    var id: String { "\(model.rawValue)|\(time)" }
}

/// Produces an explicitly exploratory comparison from the currently loaded rows.
/// MLR, RF, and boosting are refitted locally; no unpublished paper model is implied.
enum ExploratoryProfileEngine {
    static func make(
        rows: [TrainingDataRow],
        scenario: Scenario,
        outcome: Outcome,
        stepCount: Int = 49
    ) -> [ExploratoryProfilePoint] {
        guard rows.count >= 8, stepCount >= 2 else { return [] }

        let x = rows.map(features)
        let y = rows.map { outcome == .amount ? $0.amount : $0.percentage }
        let indices = Array(rows.indices)
        let normalizer = Normalizer.fit(x, indices: indices)
        let normalized = normalizer.transform(x)
        let mlr = RidgeRegressor.fit(x: normalized, y: y, indices: indices)
        let forest = ForestRegressor.fit(x: normalized, y: y, indices: indices, seed: 2_023)
        let boosting = BoostingRegressor.fit(x: normalized, y: y, indices: indices)
        let fick = fittedFickCurve(rows: rows, scenario: scenario, outcome: outcome)
        let maximumTime = max(0.25, scenario.duration)

        return (0..<stepCount).flatMap { index -> [ExploratoryProfilePoint] in
            let time = maximumTime * Double(index) / Double(stepCount - 1)
            let raw = features(scenario: scenario, time: time)
            let input = normalizer.transform([raw])[0]
            return [
                ExploratoryProfilePoint(model: .fick, time: time, value: fick(time)),
                ExploratoryProfilePoint(model: .mlr, time: time, value: mlr.predict(input)),
                ExploratoryProfilePoint(model: .rf, time: time, value: forest.predict(input)),
                ExploratoryProfilePoint(model: .xgboost, time: time, value: boosting.predict(input)),
            ]
        }
    }

    private static func features(_ row: TrainingDataRow) -> [Double] {
        [
            row.loading,
            row.molecularWeight,
            row.needleLength,
            Double(row.skin.sourceCode),
            Double(row.needle.sourceCode),
            row.surfaceArea,
            row.permeationTime,
        ]
    }

    private static func features(scenario: Scenario, time: Double) -> [Double] {
        [
            scenario.loading,
            scenario.drug.molecularWeight,
            scenario.length,
            Double(scenario.skin.sourceCode),
            Double(scenario.needle.sourceCode),
            scenario.surfaceArea,
            time,
        ]
    }

    private static func fittedFickCurve(
        rows: [TrainingDataRow],
        scenario: Scenario,
        outcome: Outcome
    ) -> @Sendable (Double) -> Double {
        let exact = rows.filter {
            $0.drug == scenario.drug && $0.skin == scenario.skin && $0.needle == scenario.needle
        }
        let drugRows = rows.filter { $0.drug == scenario.drug }
        let fittingRows = exact.count >= 4 ? exact : (drugRows.count >= 4 ? drugRows : rows)
        let samples = fittingRows.map { row in
            (time: max(0, row.permeationTime), value: outcome == .amount ? row.amount : row.percentage)
        }

        var bestRate = 0.1
        var bestPlateau = samples.map(\.value).max() ?? 0
        var bestError = Double.infinity
        for step in 1...240 {
            let rate = Double(step) / 120
            let basis = samples.map { 1 - exp(-rate * $0.time) }
            let denominator = basis.reduce(0) { $0 + $1 * $1 }
            guard denominator > 1e-12 else { continue }
            let plateau = max(0, zip(basis, samples).reduce(0) { $0 + $1.0 * $1.1.value } / denominator)
            let error = zip(basis, samples).reduce(0) {
                $0 + pow($1.1.value - plateau * $1.0, 2)
            }
            if error < bestError {
                bestError = error
                bestRate = rate
                bestPlateau = plateau
            }
        }
        let fittedPlateau = bestPlateau
        let fittedRate = bestRate
        return { time in fittedPlateau * (1 - exp(-fittedRate * max(0, time))) }
    }
}
