import Foundation

enum LeakageSeverity: Int, Comparable, Sendable {
    case information
    case warning
    case blocker

    static func < (lhs: LeakageSeverity, rhs: LeakageSeverity) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

struct LeakageFinding: Equatable, Identifiable, Sendable {
    let id: String
    let severity: LeakageSeverity
    let columnIndex: Int?
    let title: BiText
    let detail: BiText
}

struct DataLeakageAudit: Equatable, Sendable {
    let findings: [LeakageFinding]

    var blockers: [LeakageFinding] { findings.filter { $0.severity == .blocker } }
    var warnings: [LeakageFinding] { findings.filter { $0.severity == .warning } }
    var canTrain: Bool { blockers.isEmpty }

    static func review(
        dataset: GenericDataset,
        target: Int,
        group: Int?,
        features: Set<Int>
    ) -> DataLeakageAudit {
        guard dataset.headers.indices.contains(target) else {
            return DataLeakageAudit(findings: [
                LeakageFinding(
                    id: "invalid-target",
                    severity: .blocker,
                    columnIndex: nil,
                    title: BiText("目的変数が不正です", "Invalid target"),
                    detail: BiText("数値の目的変数を選び直してください。", "Choose a numeric target again.")
                )
            ])
        }

        let targetHeader = dataset.headers[target]
        var findings: [LeakageFinding] = []
        if isIdentifier(targetHeader) {
            findings.append(
                LeakageFinding(
                    id: "identifier-target",
                    severity: .blocker,
                    columnIndex: target,
                    title: BiText("ID列は目的変数にできません", "An ID cannot be the target"),
                    detail: BiText(
                        "「\(targetHeader)」は行や試料を識別する列に見えます。実際に予測したい有限数値の測定値を選んでください。",
                        "“\(targetHeader)” looks like a row or sample identifier. Choose the finite numeric measurement you actually want to predict."
                    )
                )
            )
        }
        for index in features.sorted() where dataset.headers.indices.contains(index) {
            let header = dataset.headers[index]
            if isPairedOutcome(feature: header, target: targetHeader) {
                findings.append(
                    LeakageFinding(
                        id: "paired-outcome-\(index)",
                        severity: .blocker,
                        columnIndex: index,
                        title: BiText("目的変数から作れる列を除外してください", "Remove the derived outcome column"),
                        detail: BiText(
                            "「\(header)」は「\(targetHeader)」と数式で結び付く可能性があります。この研究では透過量 ≈ 薬物負荷量 × 透過率 / 100 のため、透過量と透過率を同時に目的・説明変数へ置くと答えを先に見せるデータ漏洩になります。",
                            "“\(header)” may be mathematically linked to “\(targetHeader)”. In this study, amount ≈ loading × percentage / 100, so using one outcome to predict the other leaks the answer."
                        )
                    )
                )
            }
            if isIdentifier(header) {
                findings.append(
                    LeakageFinding(
                        id: "identifier-\(index)",
                        severity: .blocker,
                        columnIndex: index,
                        title: BiText("ID列を説明変数にしないでください", "Do not use an ID as a predictor"),
                        detail: BiText(
                            "「\(header)」は識別子に見えます。説明変数から外し、同じrun・curve・患者・batchを同じfoldに保つ分割グループとして使ってください。",
                            "“\(header)” looks like an identifier. Remove it from predictors and use it as the split group so the same run, curve, patient, or batch stays in one fold."
                        )
                    )
                )
            }
        }

        if group == nil {
            findings.append(
                LeakageFinding(
                    id: "no-group",
                    severity: .warning,
                    columnIndex: nil,
                    title: BiText("行単位CVになっています", "Row-wise CV is selected"),
                    detail: BiText(
                        "同じ実験曲線の複数時点がある場合、run_idやcurve_idを分割グループにしてください。未知薬物が目的なら薬物名を選びます。",
                        "If one experimental curve contributes several time points, select run_id or curve_id as the split group. Select drug name when the goal is an unseen drug."
                    )
                )
            )
        }

        if features.count > max(1, dataset.rows.count / 10) {
            findings.append(
                LeakageFinding(
                    id: "feature-count",
                    severity: .warning,
                    columnIndex: nil,
                    title: BiText("行数に対して説明変数が多めです", "Many predictors for the available rows"),
                    detail: BiText(
                        "目安の10行/説明変数を下回ります。不要な列を減らすか、独立した実験runを追加してください。",
                        "This is below the rough guide of 10 rows per predictor. Remove unnecessary columns or add independent experimental runs."
                    )
                )
            )
        }

        return DataLeakageAudit(findings: findings.sorted { $0.severity > $1.severity })
    }

    static func recommendedFeatures(
        dataset: GenericDataset,
        target: Int,
        group: Int?
    ) -> Set<Int> {
        Set(dataset.headers.indices.filter { index in
            index != target
                && index != group
                && !isIdentifier(dataset.headers[index])
                && !isPairedOutcome(feature: dataset.headers[index], target: dataset.headers[target])
        })
    }

    static func suggestedGroup(in dataset: GenericDataset, excluding target: Int) -> Int? {
        let candidates = dataset.headers.indices.filter { $0 != target }
        if let identifier = candidates.first(where: { isGroupingIdentifier(dataset.headers[$0]) }) {
            return identifier
        }
        return candidates.first { index in
            let normalized = normalize(dataset.headers[index])
            return normalized == "drug"
                || normalized.contains("drugname")
                || normalized.contains("compound")
                || normalized.contains("permeant")
        }
    }

    static func suggestedTarget(in dataset: GenericDataset) -> Int? {
        let candidates = dataset.numericColumns.filter { !isIdentifier(dataset.headers[$0]) }
        let priorityTerms = [
            "permeationamount", "permeationpercentage", "outcome", "response", "target",
            "透過量", "透過率", "目的変数",
        ]
        if let named = candidates.first(where: { index in
            let normalized = normalize(dataset.headers[index])
            return priorityTerms.contains(where: normalized.contains)
        }) {
            return named
        }
        return candidates.last
    }

    private static func isIdentifier(_ header: String) -> Bool {
        let lowered = header.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let compact = normalize(header)
        if ["id", "uuid", "index", "row", "rowid", "reference", "references"].contains(compact) {
            return true
        }
        if lowered.hasSuffix("_id") || lowered.hasSuffix(" id") || lowered.contains("identifier") {
            return true
        }
        return ["runid", "curveid", "patientid", "batchid", "sampleid", "donorid", "siteid"]
            .contains(where: compact.contains)
    }

    private static func isGroupingIdentifier(_ header: String) -> Bool {
        let compact = normalize(header)
        return [
            "groupid", "runid", "curveid", "patientid", "batchid", "donorid", "siteid",
        ].contains(where: compact.contains)
    }

    private static func isPairedOutcome(feature: String, target: String) -> Bool {
        let feature = normalize(feature)
        let target = normalize(target)
        let featureIsAmount = feature.contains("amount") || feature.contains("mass") || feature.contains("透過量")
        let targetIsAmount = target.contains("amount") || target.contains("mass") || target.contains("透過量")
        let featureIsPercentage = feature.contains("percentage") || feature.contains("percent") || feature.contains("ratio") || feature.contains("rate") || feature.contains("透過率")
        let targetIsPercentage = target.contains("percentage") || target.contains("percent") || target.contains("ratio") || target.contains("rate") || target.contains("透過率")
        return (featureIsAmount && targetIsPercentage) || (featureIsPercentage && targetIsAmount)
    }

    private static func normalize(_ source: String) -> String {
        source.lowercased().filter { $0.isLetter || $0.isNumber }
    }
}

enum LocalModelArtifactError: LocalizedError, Equatable {
    case noUsableRows
    case noUsableFeatures
    case missingColumns([String])
    case incompatibleArtifact(String)

    var errorDescription: String? {
        switch self {
        case .noUsableRows:
            "At least 20 rows with a finite target value are required."
        case .noUsableFeatures:
            "No usable predictors remain after preprocessing."
        case .missingColumns(let names):
            "Prediction data are missing required columns: \(names.joined(separator: ", "))."
        case .incompatibleArtifact(let reason):
            "The model artifact is incompatible or damaged: \(reason)"
        }
    }

    func message(_ language: AppLanguage) -> String {
        switch self {
        case .noUsableRows:
            language.text("有限な目的変数を持つ行が20件以上必要です。", "At least 20 rows with a finite target value are required.")
        case .noUsableFeatures:
            language.text("前処理後に使える説明変数がありません。", "No usable predictors remain after preprocessing.")
        case .missingColumns(let names):
            language.text("予測CSVに必要な列がありません: \(names.joined(separator: ", "))", "Prediction data are missing required columns: \(names.joined(separator: ", ")).")
        case .incompatibleArtifact(let reason):
            language.text("モデルJSONが非対応または破損しています: \(reason)", "The model artifact is incompatible or damaged: \(reason)")
        }
    }
}

/// Import limits are deliberately above every model produced by the local
/// trainer (36 forest trees of depth 6, or 48 boosting trees of depth 3), while
/// keeping an untrusted JSON file from allocating unbounded model structures.
enum LocalModelArtifactImportLimits {
    static let maximumEncodedByteCount = 4 * 1_024 * 1_024
    static let maximumJSONNestingDepth = 64
    static let maximumStringUTF8ByteCount = 4_096
    static let maximumTotalStringUTF8ByteCount = 1_024 * 1_024
    static let maximumSourceHeaderCount = 1_024
    static let maximumSelectedFeatureCount = 512
    static let maximumFeatureProfileCount = 512
    static let maximumTrainingRowCount = 5_000
    static let maximumEncodedFeatureCount = 8_192
    static let maximumCategoryLevelCount = 12
    static let maximumForestTreeCount = 128
    static let maximumBoostingTreeCount = 256
    static let maximumTreeDepth = 16
    static let maximumNodesPerTree = 4_095
    static let maximumTotalTreeNodeCount = 32_768
}

struct ModelValidationSnapshot: Codable, Equatable, Sendable {
    let configurationSHA256: String
    let foldCount: Int
    let groupColumn: String?
    let selectedFamily: CandidateFamily
    let selectedRMSE: Double
    let selectedMAE: Double
    let selectedRSquared: Double
    let baselineRMSE: Double
    let selectedWasCVWinner: Bool
}

struct ModelFeatureProfile: Codable, Equatable, Identifiable, Sendable {
    enum Kind: String, Codable, Sendable {
        case numeric
        case categorical
    }

    let name: String
    let kind: Kind
    let missingTrainingCount: Int
    let numericMinimum: Double?
    let numericMaximum: Double?
    let numericMedian: Double?
    let categoricalLevels: [String]

    var id: String { name }
}

enum LocalRegressor: Codable, Equatable, Sendable {
    case ridge(RidgeRegressor)
    case randomForest(ForestRegressor)
    case gradientBoosting(BoostingRegressor)

    func predict(_ row: [Double]) -> Double {
        switch self {
        case .ridge(let model): model.predict(row)
        case .randomForest(let model): model.predict(row)
        case .gradientBoosting(let model): model.predict(row)
        }
    }
}

struct LocalModelArtifact: Codable, Equatable, Identifiable, Sendable {
    static let currentSchemaVersion = 1
    static let engineVersion = "PermeationLab Native Tabular Regression 1.0"

    let schemaVersion: Int
    let id: UUID
    let trainedAt: Date
    let engineVersion: String
    let datasetName: String
    let datasetNormalizedSHA256: String
    let sourceHeaders: [String]
    let targetName: String
    let groupName: String?
    let selectedFeatureNames: [String]
    let trainingRowCount: Int
    let encodedFeatureCount: Int
    let family: CandidateFamily
    let featureProfiles: [ModelFeatureProfile]
    let preprocessor: FoldPreprocessor
    let normalizer: Normalizer
    let regressor: LocalRegressor
    let validation: ModelValidationSnapshot

    func encodedData(prettyPrinted: Bool = true) throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = prettyPrinted ? [.prettyPrinted, .sortedKeys] : [.sortedKeys]
        return try encoder.encode(self)
    }

    static func decode(_ data: Data) throws -> LocalModelArtifact {
        try validateJSONEnvelope(data)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let artifact: LocalModelArtifact
        do {
            artifact = try decoder.decode(LocalModelArtifact.self, from: data)
        } catch {
            let reason = String(error.localizedDescription.prefix(512))
            throw LocalModelArtifactError.incompatibleArtifact(reason)
        }
        try artifact.validate()
        try validateDecodedJSONStructure(originalData: data, artifact: artifact)
        return artifact
    }

    func validate() throws {
        guard schemaVersion == Self.currentSchemaVersion else {
            throw LocalModelArtifactError.incompatibleArtifact("unsupported schema version \(schemaVersion)")
        }
        guard engineVersion == Self.engineVersion else {
            throw LocalModelArtifactError.incompatibleArtifact("unsupported engine \(engineVersion)")
        }
        guard trainedAt.timeIntervalSinceReferenceDate.isFinite else {
            throw LocalModelArtifactError.incompatibleArtifact("invalid training date")
        }
        guard trainingRowCount >= 20,
              trainingRowCount <= LocalModelArtifactImportLimits.maximumTrainingRowCount else {
            throw LocalModelArtifactError.incompatibleArtifact("invalid training row count")
        }

        try validateMetadata()

        guard encodedFeatureCount > 0,
              encodedFeatureCount <= LocalModelArtifactImportLimits.maximumEncodedFeatureCount else {
            throw LocalModelArtifactError.incompatibleArtifact("encoded feature count is outside the allowed range")
        }

        let preprocessorDimension: Int
        do {
            preprocessorDimension = try preprocessor.validatedOutputDimensionForArtifact(
                sourceColumnCount: sourceHeaders.count,
                maximumColumnCount: LocalModelArtifactImportLimits.maximumFeatureProfileCount,
                maximumCategoryLevelCount: LocalModelArtifactImportLimits.maximumCategoryLevelCount,
                maximumStringUTF8ByteCount: LocalModelArtifactImportLimits.maximumStringUTF8ByteCount,
                maximumOutputDimension: LocalModelArtifactImportLimits.maximumEncodedFeatureCount
            )
            try normalizer.validateForArtifact(featureCount: encodedFeatureCount)
        } catch let error as ModelPayloadValidationError {
            throw LocalModelArtifactError.incompatibleArtifact(error.localizedDescription)
        }
        guard encodedFeatureCount == preprocessorDimension else {
            throw LocalModelArtifactError.incompatibleArtifact("preprocessing dimensions do not match")
        }

        let modelMatchesFamily: Bool
        switch (family, regressor) {
        case (.linear, .ridge), (.randomForest, .randomForest), (.gradientBoosting, .gradientBoosting):
            modelMatchesFamily = true
        default:
            modelMatchesFamily = false
        }
        guard modelMatchesFamily else {
            throw LocalModelArtifactError.incompatibleArtifact("model family does not match payload")
        }

        do {
            switch regressor {
            case .ridge(let model):
                try model.validateForArtifact(featureCount: encodedFeatureCount)
            case .randomForest(let model):
                try model.validateForArtifact(
                    featureCount: encodedFeatureCount,
                    maximumTreeCount: LocalModelArtifactImportLimits.maximumForestTreeCount,
                    maximumTreeDepth: LocalModelArtifactImportLimits.maximumTreeDepth,
                    maximumNodesPerTree: LocalModelArtifactImportLimits.maximumNodesPerTree,
                    maximumTotalNodeCount: LocalModelArtifactImportLimits.maximumTotalTreeNodeCount
                )
            case .gradientBoosting(let model):
                try model.validateForArtifact(
                    featureCount: encodedFeatureCount,
                    maximumTreeCount: LocalModelArtifactImportLimits.maximumBoostingTreeCount,
                    maximumTreeDepth: LocalModelArtifactImportLimits.maximumTreeDepth,
                    maximumNodesPerTree: LocalModelArtifactImportLimits.maximumNodesPerTree,
                    maximumTotalNodeCount: LocalModelArtifactImportLimits.maximumTotalTreeNodeCount
                )
            }
        } catch let error as ModelPayloadValidationError {
            throw LocalModelArtifactError.incompatibleArtifact(error.localizedDescription)
        }
    }

    private func validateMetadata() throws {
        let limits = LocalModelArtifactImportLimits.self
        guard sourceHeaders.count >= 2,
              sourceHeaders.count <= limits.maximumSourceHeaderCount,
              !selectedFeatureNames.isEmpty,
              selectedFeatureNames.count <= limits.maximumSelectedFeatureCount,
              !featureProfiles.isEmpty,
              featureProfiles.count <= limits.maximumFeatureProfileCount,
              featureProfiles.count == preprocessor.columns.count,
              featureProfiles.allSatisfy({ $0.categoricalLevels.count <= limits.maximumCategoryLevelCount }) else {
            throw LocalModelArtifactError.incompatibleArtifact("artifact arrays are outside the allowed bounds")
        }

        var strings: [String] = [datasetName, datasetNormalizedSHA256, engineVersion, targetName]
        strings.append(contentsOf: sourceHeaders)
        strings.append(contentsOf: selectedFeatureNames)
        for profile in featureProfiles {
            strings.append(profile.name)
            strings.append(contentsOf: profile.categoricalLevels)
        }
        if let groupName { strings.append(groupName) }
        if let validationGroup = validation.groupColumn { strings.append(validationGroup) }
        guard strings.allSatisfy({ !$0.isEmpty && $0.utf8.count <= limits.maximumStringUTF8ByteCount }),
              strings.reduce(0, { $0 + $1.utf8.count }) <= limits.maximumTotalStringUTF8ByteCount else {
            throw LocalModelArtifactError.incompatibleArtifact("artifact strings are empty or exceed the allowed size")
        }
        guard datasetNormalizedSHA256.utf8.count == 64,
              datasetNormalizedSHA256.utf8.allSatisfy({
                  ($0 >= 0x30 && $0 <= 0x39) || ($0 >= 0x61 && $0 <= 0x66)
              }) else {
            throw LocalModelArtifactError.incompatibleArtifact("dataset hash must be 64 lowercase hexadecimal characters")
        }

        let sourceHeaderSet = Set(sourceHeaders)
        let selectedFeatureSet = Set(selectedFeatureNames)
        let profileNames = featureProfiles.map(\.name)
        guard sourceHeaderSet.count == sourceHeaders.count,
              selectedFeatureSet.count == selectedFeatureNames.count,
              Set(profileNames).count == profileNames.count,
              sourceHeaderSet.contains(targetName),
              selectedFeatureSet.isSubset(of: sourceHeaderSet),
              Set(profileNames).isSubset(of: selectedFeatureSet),
              !selectedFeatureSet.contains(targetName) else {
            throw LocalModelArtifactError.incompatibleArtifact("column metadata are inconsistent")
        }
        if let groupName {
            guard sourceHeaderSet.contains(groupName),
                  groupName != targetName,
                  !selectedFeatureSet.contains(groupName) else {
                throw LocalModelArtifactError.incompatibleArtifact("group column metadata are inconsistent")
            }
        }
        guard groupName == validation.groupColumn else {
            throw LocalModelArtifactError.incompatibleArtifact("validation group does not match the artifact")
        }

        let selectedIndices = Set(selectedFeatureNames.compactMap { sourceHeaders.firstIndex(of: $0) })
        for (column, profile) in zip(preprocessor.columns, featureProfiles) {
            guard sourceHeaders.indices.contains(column.index),
                  selectedIndices.contains(column.index),
                  profile.name == sourceHeaders[column.index],
                  (0...trainingRowCount).contains(profile.missingTrainingCount) else {
                throw LocalModelArtifactError.incompatibleArtifact("feature profile does not match the preprocessor")
            }

            switch (column, profile.kind) {
            case (.numeric(_, let median), .numeric):
                guard profile.categoricalLevels.isEmpty,
                      let minimum = profile.numericMinimum,
                      let maximum = profile.numericMaximum,
                      let profileMedian = profile.numericMedian,
                      minimum.isFinite,
                      maximum.isFinite,
                      profileMedian.isFinite,
                      minimum <= profileMedian,
                      profileMedian <= maximum,
                      profileMedian == median else {
                    throw LocalModelArtifactError.incompatibleArtifact("numeric feature profile is invalid")
                }

            case (.categorical(_, let levels), .categorical):
                guard profile.numericMinimum == nil,
                      profile.numericMaximum == nil,
                      profile.numericMedian == nil,
                      profile.categoricalLevels == levels else {
                    throw LocalModelArtifactError.incompatibleArtifact("categorical feature profile is invalid")
                }

            default:
                throw LocalModelArtifactError.incompatibleArtifact("feature profile kind does not match the preprocessor")
            }
        }

        guard validation.configurationSHA256.utf8.count == 64,
              validation.configurationSHA256.utf8.allSatisfy({
                  ($0 >= 0x30 && $0 <= 0x39) || ($0 >= 0x61 && $0 <= 0x66)
              }),
              validation.foldCount >= 2,
              validation.foldCount <= 5,
              validation.selectedFamily == family,
              validation.selectedRMSE.isFinite,
              validation.selectedRMSE >= 0,
              validation.selectedMAE.isFinite,
              validation.selectedMAE >= 0,
              validation.selectedRSquared.isFinite,
              validation.baselineRMSE.isFinite,
              validation.baselineRMSE >= 0 else {
            throw LocalModelArtifactError.incompatibleArtifact("validation metrics are invalid")
        }
    }

    private static func validateJSONEnvelope(_ data: Data) throws {
        guard !data.isEmpty,
              data.count <= LocalModelArtifactImportLimits.maximumEncodedByteCount else {
            throw LocalModelArtifactError.incompatibleArtifact("model JSON exceeds the allowed file size")
        }

        var delimiters: [UInt8] = []
        var isInsideString = false
        var isEscaped = false
        for byte in data {
            if isInsideString {
                if isEscaped {
                    isEscaped = false
                } else if byte == 0x5C {
                    isEscaped = true
                } else if byte == 0x22 {
                    isInsideString = false
                }
                continue
            }

            switch byte {
            case 0x22:
                isInsideString = true
            case 0x7B, 0x5B:
                delimiters.append(byte)
                guard delimiters.count <= LocalModelArtifactImportLimits.maximumJSONNestingDepth else {
                    throw LocalModelArtifactError.incompatibleArtifact("model JSON exceeds the nesting limit")
                }
            case 0x7D:
                guard delimiters.popLast() == 0x7B else {
                    throw LocalModelArtifactError.incompatibleArtifact("model JSON has mismatched delimiters")
                }
            case 0x5D:
                guard delimiters.popLast() == 0x5B else {
                    throw LocalModelArtifactError.incompatibleArtifact("model JSON has mismatched delimiters")
                }
            default:
                break
            }
        }
        guard !isInsideString, delimiters.isEmpty else {
            throw LocalModelArtifactError.incompatibleArtifact("model JSON is incomplete")
        }
    }

    /// Synthesized `Decodable` ignores unknown object keys. Comparing the
    /// decoded value's JSON shape with the imported shape closes that gap while
    /// still ignoring whitespace, key ordering, and equivalent number syntax.
    private static func validateDecodedJSONStructure(
        originalData: Data,
        artifact: LocalModelArtifact
    ) throws {
        do {
            let original = try JSONSerialization.jsonObject(with: originalData)
            let canonical = try JSONSerialization.jsonObject(with: artifact.encodedData(prettyPrinted: false))
            guard (original as AnyObject).isEqual(canonical) else {
                throw LocalModelArtifactError.incompatibleArtifact("model JSON contains unknown or non-canonical fields")
            }
        } catch let error as LocalModelArtifactError {
            throw error
        } catch {
            throw LocalModelArtifactError.incompatibleArtifact("model JSON structure could not be verified")
        }
    }
}

enum ModelTrainingEngine {
    static func train(
        dataset: GenericDataset,
        target: Int,
        group: Int?,
        features: Set<Int>,
        family: CandidateFamily,
        report: ModelSelectionReport,
        id: UUID = UUID(),
        trainedAt: Date = Date()
    ) throws -> LocalModelArtifact {
        let audit = DataLeakageAudit.review(dataset: dataset, target: target, group: group, features: features)
        if let blocker = audit.blockers.first {
            throw SelectionError.invalidConfiguration(blocker.detail)
        }
        let expectedConfigurationSHA256 = ModelSelectionEngine.configurationSHA256(
            dataset: dataset,
            target: target,
            group: group,
            features: features
        )
        guard report.configurationSHA256 == expectedConfigurationSHA256 else {
            throw LocalModelArtifactError.incompatibleArtifact(
                "the validation report does not match this dataset and feature configuration"
            )
        }

        let validRows = dataset.rows.filter { finiteDouble($0[target]) != nil }
        guard validRows.count >= 20 else { throw LocalModelArtifactError.noUsableRows }
        let y = validRows.compactMap { finiteDouble($0[target]) }
        let featureIndices = dataset.headers.indices.filter {
            features.contains($0) && $0 != target && $0 != group
        }
        let allIndices = Array(validRows.indices)
        let preprocessor = FoldPreprocessor.fit(
            rows: validRows,
            featureIndices: featureIndices,
            trainingIndices: allIndices
        )
        guard preprocessor.outputDimension > 0 else { throw LocalModelArtifactError.noUsableFeatures }
        let raw = preprocessor.transform(rows: validRows)
        let normalizer = Normalizer.fit(raw, indices: allIndices)
        let x = normalizer.transform(raw)

        let regressor: LocalRegressor
        switch family {
        case .linear:
            regressor = .ridge(RidgeRegressor.fit(x: x, y: y, indices: allIndices))
        case .randomForest:
            regressor = .randomForest(
                ForestRegressor.fit(x: x, y: y, indices: allIndices, seed: 2_026_090_2)
            )
        case .gradientBoosting:
            regressor = .gradientBoosting(BoostingRegressor.fit(x: x, y: y, indices: allIndices))
        }

        let profiles = preprocessor.columns.map { column -> ModelFeatureProfile in
            switch column {
            case .numeric(let index, let median):
                let values = validRows.compactMap { finiteDouble($0[index]) }
                return ModelFeatureProfile(
                    name: dataset.headers[index],
                    kind: .numeric,
                    missingTrainingCount: validRows.count - values.count,
                    numericMinimum: values.min(),
                    numericMaximum: values.max(),
                    numericMedian: median,
                    categoricalLevels: []
                )
            case .categorical(let index, let levels):
                let values = validRows.map { $0[index].trimmingCharacters(in: .whitespacesAndNewlines) }
                return ModelFeatureProfile(
                    name: dataset.headers[index],
                    kind: .categorical,
                    missingTrainingCount: values.filter(\.isEmpty).count,
                    numericMinimum: nil,
                    numericMaximum: nil,
                    numericMedian: nil,
                    categoricalLevels: levels
                )
            }
        }
        guard let selectedMetric = report.metrics.first(where: { $0.family == family }) else {
            throw LocalModelArtifactError.incompatibleArtifact("selected family is absent from validation report")
        }
        let validation = ModelValidationSnapshot(
            configurationSHA256: expectedConfigurationSHA256,
            foldCount: report.foldCount,
            groupColumn: group.map { dataset.headers[$0] },
            selectedFamily: family,
            selectedRMSE: selectedMetric.rmse,
            selectedMAE: selectedMetric.mae,
            selectedRSquared: selectedMetric.rSquared,
            baselineRMSE: report.baselineRMSE,
            selectedWasCVWinner: report.winner == family
        )

        let artifact = LocalModelArtifact(
            schemaVersion: LocalModelArtifact.currentSchemaVersion,
            id: id,
            trainedAt: trainedAt,
            engineVersion: LocalModelArtifact.engineVersion,
            datasetName: dataset.name,
            datasetNormalizedSHA256: dataset.normalizedSHA256,
            sourceHeaders: dataset.headers,
            targetName: dataset.headers[target],
            groupName: group.map { dataset.headers[$0] },
            selectedFeatureNames: featureIndices.map { dataset.headers[$0] },
            trainingRowCount: validRows.count,
            encodedFeatureCount: preprocessor.outputDimension,
            family: family,
            featureProfiles: profiles,
            preprocessor: preprocessor,
            normalizer: normalizer,
            regressor: regressor,
            validation: validation
        )
        try artifact.validate()
        return artifact
    }
}

struct PredictionDataDiagnostics: Equatable, Sendable {
    let missingValueCounts: [String: Int]
    let unseenCategoryCounts: [String: Int]
    let outsideTrainingRangeCounts: [String: Int]

    var hasWarnings: Bool {
        !missingValueCounts.isEmpty || !unseenCategoryCounts.isEmpty || !outsideTrainingRangeCounts.isEmpty
    }
}

struct PredictionEvaluation: Equatable, Sendable {
    let observationCount: Int
    let missingOutcomeCount: Int
    let rmse: Double
    let mae: Double
    let rSquared: Double?
}

struct LocalPrediction: Equatable, Identifiable, Sendable {
    let rowNumber: Int
    let predicted: Double
    let actual: Double?

    var id: Int { rowNumber }
    var residual: Double? { actual.map { $0 - predicted } }
}

struct LocalPredictionReport: Equatable, Sendable {
    let datasetName: String
    let modelID: UUID
    let targetName: String
    let sourceHeaders: [String]
    let sourceRows: [[String]]
    let predictions: [LocalPrediction]
    let diagnostics: PredictionDataDiagnostics
    let evaluation: PredictionEvaluation?
    let isPracticeData: Bool

    func csvData() -> Data {
        var headers = ["Source CSV row"] + sourceHeaders
        let predictionName = "Predicted \(targetName)"
        headers.append(predictionName)
        if sourceHeaders.contains(targetName) { headers.append("Residual (actual - predicted)") }
        headers.append("Model artifact ID")

        var lines = [headers.map(csvEscaped).joined(separator: ",")]
        for (offset, prediction) in predictions.enumerated() {
            var values = [String(prediction.rowNumber)] + sourceRows[offset]
            values.append(Self.number(prediction.predicted))
            if sourceHeaders.contains(targetName) {
                values.append(prediction.residual.map(Self.number) ?? "")
            }
            values.append(modelID.uuidString)
            lines.append(values.map(csvEscaped).joined(separator: ","))
        }
        return Data((lines.joined(separator: "\n") + "\n").utf8)
    }

    private func csvEscaped(_ source: String) -> String {
        guard source.contains(",") || source.contains("\"") || source.contains("\n") || source.contains("\r") else {
            return source
        }
        return "\"" + source.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }

    private static func number(_ value: Double) -> String {
        String(format: "%.12g", locale: Locale(identifier: "en_US_POSIX"), value)
    }
}

enum LocalPredictionEngine {
    static func predict(
        dataset: GenericDataset,
        with artifact: LocalModelArtifact,
        isPracticeData: Bool = false
    ) throws -> LocalPredictionReport {
        try artifact.validate()
        let inputIndexByHeader = Dictionary(uniqueKeysWithValues: dataset.headers.enumerated().map { ($1, $0) })
        let requiredNames = artifact.featureProfiles.map(\.name)
        let missing = requiredNames.filter { inputIndexByHeader[$0] == nil }
        guard missing.isEmpty else { throw LocalModelArtifactError.missingColumns(missing) }

        var normalizedRows: [[String]] = []
        normalizedRows.reserveCapacity(dataset.rows.count)
        for inputRow in dataset.rows {
            var sourceRow = Array(repeating: "", count: artifact.sourceHeaders.count)
            for name in requiredNames {
                guard let sourceIndex = artifact.sourceHeaders.firstIndex(of: name),
                      let inputIndex = inputIndexByHeader[name] else { continue }
                sourceRow[sourceIndex] = inputRow[inputIndex]
            }
            normalizedRows.append(sourceRow)
        }

        let encoded = artifact.preprocessor.transform(rows: normalizedRows)
        let x = artifact.normalizer.transform(encoded)
        let targetIndex = inputIndexByHeader[artifact.targetName]
        let predictions = x.enumerated().map { offset, row -> LocalPrediction in
            LocalPrediction(
                rowNumber: offset + 2,
                predicted: artifact.regressor.predict(row),
                actual: targetIndex.flatMap { finiteDouble(dataset.rows[offset][$0]) }
            )
        }

        var missingValueCounts: [String: Int] = [:]
        var unseenCategoryCounts: [String: Int] = [:]
        var outsideTrainingRangeCounts: [String: Int] = [:]
        for profile in artifact.featureProfiles {
            guard let inputIndex = inputIndexByHeader[profile.name] else { continue }
            let values = dataset.rows.map { $0[inputIndex].trimmingCharacters(in: .whitespacesAndNewlines) }
            switch profile.kind {
            case .numeric:
                let missingCount = values.filter { finiteDouble($0) == nil }.count
                if missingCount > 0 { missingValueCounts[profile.name] = missingCount }
                if let minimum = profile.numericMinimum, let maximum = profile.numericMaximum {
                    let outside = values.compactMap(finiteDouble).filter { $0 < minimum || $0 > maximum }.count
                    if outside > 0 { outsideTrainingRangeCounts[profile.name] = outside }
                }
            case .categorical:
                let emptyCount = values.filter(\.isEmpty).count
                if emptyCount > 0 { missingValueCounts[profile.name] = emptyCount }
                let known = Set(profile.categoricalLevels)
                let unseen = values.filter { !$0.isEmpty && !known.contains($0) }.count
                if unseen > 0 { unseenCategoryCounts[profile.name] = unseen }
            }
        }

        let actualPairs = predictions.compactMap { prediction -> (Double, Double)? in
            prediction.actual.map { ($0, prediction.predicted) }
        }
        let evaluation: PredictionEvaluation?
        if !actualPairs.isEmpty {
            let actual = actualPairs.map(\.0)
            let predicted = actualPairs.map(\.1)
            let errors = zip(actual, predicted).map { $0 - $1 }
            let squared = errors.reduce(0) { $0 + $1 * $1 }
            let mean = actual.reduce(0, +) / Double(actual.count)
            let total = actual.reduce(0) { $0 + pow($1 - mean, 2) }
            evaluation = PredictionEvaluation(
                observationCount: actual.count,
                missingOutcomeCount: predictions.count - actual.count,
                rmse: sqrt(squared / Double(actual.count)),
                mae: errors.reduce(0) { $0 + abs($1) } / Double(actual.count),
                rSquared: total > 0 ? 1 - squared / total : nil
            )
        } else {
            evaluation = nil
        }

        return LocalPredictionReport(
            datasetName: dataset.name,
            modelID: artifact.id,
            targetName: artifact.targetName,
            sourceHeaders: dataset.headers,
            sourceRows: dataset.rows,
            predictions: predictions,
            diagnostics: PredictionDataDiagnostics(
                missingValueCounts: missingValueCounts,
                unseenCategoryCounts: unseenCategoryCounts,
                outsideTrainingRangeCounts: outsideTrainingRangeCounts
            ),
            evaluation: evaluation,
            isPracticeData: isPracticeData
        )
    }
}

@MainActor
final class ModelWorkspaceStore: ObservableObject {
    private static let persistenceKey = "modelLab.artifact.v1"

    @Published private(set) var artifact: LocalModelArtifact?

    init(loadPersisted: Bool = true) {
        guard loadPersisted,
              let data = UserDefaults.standard.data(forKey: Self.persistenceKey),
              let decoded = try? LocalModelArtifact.decode(data) else {
            artifact = nil
            return
        }
        artifact = decoded
    }

    func install(_ newArtifact: LocalModelArtifact) throws {
        try newArtifact.validate()
        artifact = newArtifact
        UserDefaults.standard.set(try newArtifact.encodedData(prettyPrinted: false), forKey: Self.persistenceKey)
    }

    func clear() {
        artifact = nil
        UserDefaults.standard.removeObject(forKey: Self.persistenceKey)
    }

    static func clearPersistedModel() {
        UserDefaults.standard.removeObject(forKey: persistenceKey)
    }
}
