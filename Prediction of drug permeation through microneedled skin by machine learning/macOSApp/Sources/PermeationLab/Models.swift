import Foundation
import SwiftUI

enum Drug: String, CaseIterable, Identifiable, Sendable {
    case lidocaine = "Lidocaine"
    case bsa = "BSA"
    case copper = "Copper ions"
    case ghk = "GHK peptide"
    case rhodamine = "Rhodamine B"
    case caffeine = "Caffeine"

    var id: String { rawValue }

    /// Exact spelling and capitalization used in the paper's Data S1 workbook.
    var sourceName: String {
        switch self {
        case .lidocaine: "lidocaine"
        case .bsa: "BSA"
        case .copper: "copper ions"
        case .ghk: "GHK peptide"
        case .rhodamine: "Rhodamine B"
        case .caffeine: "caffeine"
        }
    }

    init?(sourceName: String) {
        guard let match = Self.allCases.first(where: { $0.sourceName == sourceName }) else {
            return nil
        }
        self = match
    }

    var molecularWeight: Double {
        switch self {
        case .lidocaine: 234.34
        case .bsa: 66_000
        case .copper: 63.5
        case .ghk: 340.38
        case .rhodamine: 479.02
        case .caffeine: 194.19
        }
    }
}

enum SkinType: String, CaseIterable, Identifiable, Sendable {
    case human = "Human"
    case rat = "Rat"

    var id: Self { self }
    var sourceCode: Int { self == .rat ? 1 : 2 }

    init?(sourceCode: String) {
        switch sourceCode.trimmingCharacters(in: .whitespacesAndNewlines) {
        case "1": self = .rat
        case "2": self = .human
        default: return nil
        }
    }
}

enum NeedleType: String, CaseIterable, Identifiable, Sendable {
    case hydrogel = "Hydrogel"
    case plastic = "Plastic"

    var id: Self { self }
    var sourceCode: Int { self == .hydrogel ? 1 : 2 }

    init?(sourceCode: String) {
        switch sourceCode.trimmingCharacters(in: .whitespacesAndNewlines) {
        case "1": self = .hydrogel
        case "2": self = .plastic
        default: return nil
        }
    }
}

enum Outcome: String, CaseIterable, Identifiable, Sendable {
    case amount = "透過量 (µg/cm²)"
    case percentage = "透過率 (%)"

    var id: Self { self }
}

struct Scenario: Equatable, Sendable {
    var drug: Drug = .lidocaine
    var skin: SkinType = .human
    var needle: NeedleType = .hydrogel
    var loading = 1_000.0
    var length = 0.82
    var surfaceArea = 26.76
    var duration = 24.0
}

struct TrainingDataRow: Identifiable, Equatable, Sendable {
    /// One-based row number within the Data S1 observations (the CSV header is excluded).
    let id: Int
    /// Exact source spelling is retained separately from the typed drug value.
    let sourceDrugName: String
    let drug: Drug
    let loading: Double
    let molecularWeight: Double
    let needleLength: Double
    let skin: SkinType
    let needle: NeedleType
    let surfaceArea: Double
    let permeationTime: Double
    let percentage: Double
    let amount: Double
    let reference: String
}

struct DatasetParseError: Identifiable, Equatable, Sendable, Error {
    enum Kind: String, Sendable {
        case resource
        case malformedCSV
        case schema
        case columnCount
        case unknownDrug
        case invalidNumber
        case invalidSkinCode
        case invalidNeedleCode
    }

    let kind: Kind
    /// One-based CSV record number, including the header record when applicable.
    let row: Int?
    /// One-based column number when the error applies to a particular field.
    let column: Int?
    let value: String?
    let message: String

    var id: String {
        [kind.rawValue, row.map(String.init), column.map(String.init), value, message]
            .compactMap { $0 }
            .joined(separator: "|")
    }
}

struct DatasetAudit: Equatable, Sendable {
    let rowCount: Int
    let columnCount: Int
    let drugCounts: [String: Int]
    let loadingRange: ClosedRange<Double>?
    let molecularWeightRange: ClosedRange<Double>?
    let needleLengthRange: ClosedRange<Double>?
    let surfaceAreaRange: ClosedRange<Double>?
    let permeationTimeRange: ClosedRange<Double>?
    let percentageRange: ClosedRange<Double>?
    let amountRange: ClosedRange<Double>?
    let percentageAbove100Count: Int
    /// Maximum absolute difference from amount = loading × percentage / 100, in µg/cm².
    let maxAmountPercentageResidual: Double
    let parseErrors: [DatasetParseError]

    var isValid: Bool { parseErrors.isEmpty }

    fileprivate static func make(
        rows: [TrainingDataRow],
        columnCount: Int,
        parseErrors: [DatasetParseError]
    ) -> Self {
        func range(_ values: [Double]) -> ClosedRange<Double>? {
            guard let lower = values.min(), let upper = values.max() else { return nil }
            return lower...upper
        }

        let counts = Dictionary(grouping: rows, by: \TrainingDataRow.sourceDrugName)
            .mapValues(\.count)
        let maximumResidual = rows.map {
            abs($0.amount - ($0.loading * $0.percentage / 100))
        }.max() ?? 0

        return Self(
            rowCount: rows.count,
            columnCount: columnCount,
            drugCounts: counts,
            loadingRange: range(rows.map(\.loading)),
            molecularWeightRange: range(rows.map(\.molecularWeight)),
            needleLengthRange: range(rows.map(\.needleLength)),
            surfaceAreaRange: range(rows.map(\.surfaceArea)),
            permeationTimeRange: range(rows.map(\.permeationTime)),
            percentageRange: range(rows.map(\.percentage)),
            amountRange: range(rows.map(\.amount)),
            percentageAbove100Count: rows.count(where: { $0.percentage > 100 }),
            maxAmountPercentageResidual: maximumResidual,
            parseErrors: parseErrors
        )
    }
}

struct TrainingDataset: Equatable, Sendable {
    let rows: [TrainingDataRow]
    let audit: DatasetAudit
}

enum TrainingDataSource {
    static let expectedHeader = [
        "Drug name",
        "Drug loading in MN patch (µg)",
        "Drug MW (Dalton)",
        "MN Length (mm)",
        "Skin type (rat =1; human = 2)",
        "MN type (hydrogel =1; plastic = 2)",
        "MN surface area (mm2)",
        "Permeation time (hour)",
        "Drug permeation percentage",
        "Drug permeation amounts (µg/cm2)",
        "References",
    ]

    static let bundled = loadBundled()
    /// A schema-valid, zero-row dataset used only while My Experiment is waiting
    /// for an import. It prevents any implicit fallback to the paper evidence.
    static let emptyCompatible = parse(expectedHeader.joined(separator: ",") + "\n")
    static var rows: [TrainingDataRow] { bundled.rows }
    static var audit: DatasetAudit { bundled.audit }

    static func loadBundled() -> TrainingDataset {
        loadBundled(from: resourceBundle)
    }

    static func loadBundled(from bundle: Bundle) -> TrainingDataset {
        guard let url = bundle.url(forResource: "yuan2023_training_data", withExtension: "csv") else {
            return failedDataset(message: "yuan2023_training_data.csv was not found in the resource bundle")
        }

        do {
            return parse(try String(contentsOf: url, encoding: .utf8))
        } catch {
            return failedDataset(message: "Unable to read yuan2023_training_data.csv: \(error.localizedDescription)")
        }
    }

    static func parse(_ text: String) -> TrainingDataset {
        let tokenized = tokenizeCSV(text)
        var errors = tokenized.errors

        guard var header = tokenized.records.first else {
            errors.append(
                DatasetParseError(
                    kind: .schema,
                    row: 1,
                    column: nil,
                    value: nil,
                    message: "CSV is empty; the 11-column Data S1 header is required"
                )
            )
            return makeDataset(rows: [], columnCount: 0, errors: errors)
        }

        if !header.isEmpty {
            header[0] = header[0].replacingOccurrences(of: "\u{feff}", with: "")
        }
        let columnCount = header.count
        guard header == expectedHeader else {
            errors.append(
                DatasetParseError(
                    kind: .schema,
                    row: 1,
                    column: nil,
                    value: header.joined(separator: ","),
                    message: "CSV header does not match the 11-column Data S1 schema"
                )
            )
            return makeDataset(rows: [], columnCount: columnCount, errors: errors)
        }

        var rows: [TrainingDataRow] = []
        for (offset, fields) in tokenized.records.dropFirst().enumerated() {
            let csvRow = offset + 2
            guard fields.count == expectedHeader.count else {
                errors.append(
                    DatasetParseError(
                        kind: .columnCount,
                        row: csvRow,
                        column: nil,
                        value: String(fields.count),
                        message: "Expected 11 columns but found \(fields.count)"
                    )
                )
                continue
            }

            var rowErrors: [DatasetParseError] = []
            func number(at index: Int, positive: Bool = false) -> Double? {
                let source = fields[index].trimmingCharacters(in: .whitespacesAndNewlines)
                guard let value = Double(source), value.isFinite,
                      positive ? value > 0 : value >= 0 else {
                    rowErrors.append(
                        DatasetParseError(
                            kind: .invalidNumber,
                            row: csvRow,
                            column: index + 1,
                            value: fields[index],
                            message: "Invalid numeric value for \(expectedHeader[index])"
                        )
                    )
                    return nil
                }
                return value
            }

            let sourceDrugName = fields[0]
            let drug = Drug(sourceName: sourceDrugName)
            if drug == nil {
                rowErrors.append(
                    DatasetParseError(
                        kind: .unknownDrug,
                        row: csvRow,
                        column: 1,
                        value: sourceDrugName,
                        message: "Drug name is not one of the six Data S1 source names"
                    )
                )
            }

            let skin = SkinType(sourceCode: fields[4])
            if skin == nil {
                rowErrors.append(
                    DatasetParseError(
                        kind: .invalidSkinCode,
                        row: csvRow,
                        column: 5,
                        value: fields[4],
                        message: "Skin type must be 1 (rat) or 2 (human)"
                    )
                )
            }

            let needle = NeedleType(sourceCode: fields[5])
            if needle == nil {
                rowErrors.append(
                    DatasetParseError(
                        kind: .invalidNeedleCode,
                        row: csvRow,
                        column: 6,
                        value: fields[5],
                        message: "MN type must be 1 (hydrogel) or 2 (plastic)"
                    )
                )
            }

            let loading = number(at: 1, positive: true)
            let molecularWeight = number(at: 2, positive: true)
            let needleLength = number(at: 3, positive: true)
            let surfaceArea = number(at: 6, positive: true)
            let permeationTime = number(at: 7)
            let percentage = number(at: 8)
            let amount = number(at: 9)

            if !rowErrors.isEmpty {
                errors.append(contentsOf: rowErrors)
                continue
            }

            rows.append(
                TrainingDataRow(
                    id: offset + 1,
                    sourceDrugName: sourceDrugName,
                    drug: drug!,
                    loading: loading!,
                    molecularWeight: molecularWeight!,
                    needleLength: needleLength!,
                    skin: skin!,
                    needle: needle!,
                    surfaceArea: surfaceArea!,
                    permeationTime: permeationTime!,
                    percentage: percentage!,
                    amount: amount!,
                    reference: fields[10]
                )
            )
        }

        return makeDataset(rows: rows, columnCount: columnCount, errors: errors)
    }

    /// Lightweight access for parser tests and non-domain CSV inspection.
    static func parseCSV(_ text: String) -> [[String]] {
        tokenizeCSV(text).records
    }

    private static var resourceBundle: Bundle {
        #if SWIFT_PACKAGE
        Bundle.module
        #else
        let candidates = [Bundle.main, Bundle(for: PermeationLabResourceBundleToken.self)]
        return candidates.first {
            $0.url(forResource: "yuan2023_training_data", withExtension: "csv") != nil
        } ?? Bundle.main
        #endif
    }

    private static func failedDataset(message: String) -> TrainingDataset {
        makeDataset(
            rows: [],
            columnCount: 0,
            errors: [
                DatasetParseError(
                    kind: .resource,
                    row: nil,
                    column: nil,
                    value: nil,
                    message: message
                )
            ]
        )
    }

    private static func makeDataset(
        rows: [TrainingDataRow],
        columnCount: Int,
        errors: [DatasetParseError]
    ) -> TrainingDataset {
        TrainingDataset(
            rows: rows,
            audit: DatasetAudit.make(rows: rows, columnCount: columnCount, parseErrors: errors)
        )
    }

    private struct CSVTokenization {
        var records: [[String]]
        var errors: [DatasetParseError]
    }

    private enum CSVState {
        case unquoted
        case quoted
        case closedQuote
    }

    private static func tokenizeCSV(_ text: String) -> CSVTokenization {
        var records: [[String]] = []
        var errors: [DatasetParseError] = []
        var record: [String] = []
        var field = ""
        var state = CSVState.unquoted
        var recordNumber = 1
        var index = text.startIndex

        func finishField() {
            record.append(field)
            field = ""
            state = .unquoted
        }

        func finishRecord() {
            finishField()
            if record.count > 1 || record.contains(where: { !$0.isEmpty }) {
                records.append(record)
            }
            record = []
            recordNumber += 1
        }

        while index < text.endIndex {
            let character = text[index]
            switch state {
            case .quoted:
                if character == "\"" {
                    let next = text.index(after: index)
                    if next < text.endIndex, text[next] == "\"" {
                        field.append("\"")
                        index = next
                    } else {
                        state = .closedQuote
                    }
                } else {
                    field.append(character)
                }

            case .unquoted:
                if character == "," {
                    finishField()
                } else if character == "\n" || character == "\r" || character == "\r\n" {
                    finishRecord()
                } else if character == "\"" {
                    if field.isEmpty {
                        state = .quoted
                    } else {
                        errors.append(
                            DatasetParseError(
                                kind: .malformedCSV,
                                row: recordNumber,
                                column: record.count + 1,
                                value: field,
                                message: "A quoted field must start with a quote"
                            )
                        )
                        field.append(character)
                    }
                } else {
                    field.append(character)
                }

            case .closedQuote:
                if character == "," {
                    finishField()
                } else if character == "\n" || character == "\r" || character == "\r\n" {
                    finishRecord()
                } else {
                    errors.append(
                        DatasetParseError(
                            kind: .malformedCSV,
                            row: recordNumber,
                            column: record.count + 1,
                            value: String(character),
                            message: "Unexpected character after a closing quote"
                        )
                    )
                    field.append(character)
                    state = .unquoted
                }
            }

            index = text.index(after: index)
        }

        if state == .quoted {
            errors.append(
                DatasetParseError(
                    kind: .malformedCSV,
                    row: recordNumber,
                    column: record.count + 1,
                    value: field,
                    message: "Unterminated quoted field"
                )
            )
        }
        if !field.isEmpty || !record.isEmpty || state == .closedQuote {
            finishRecord()
        }
        if var header = records.first, !header.isEmpty {
            header[0] = header[0].replacingOccurrences(of: "\u{feff}", with: "")
            records[0] = header
        }

        return CSVTokenization(records: records, errors: errors)
    }
}

/// Resolves the application bundle even when XCTest is launched without the
/// normal Xcode host process and `Bundle.main` belongs to the test runner.
private final class PermeationLabResourceBundleToken: NSObject {}

enum ModelKind: String, CaseIterable, Identifiable, Sendable {
    case fick = "Fick"
    case mlr = "MLR"
    case rf = "Random Forest"
    case xgboost = "XGBoost"

    var id: Self { self }

    var color: Color {
        switch self {
        case .fick: .cyan
        case .mlr: .orange
        case .rf: .mint
        case .xgboost: .purple
        }
    }

    var shortDescription: String {
        switch self {
        case .fick: "濃度勾配と拡散を表す機構モデル"
        case .mlr: "7特徴量を直線的に足し合わせる"
        case .rf: "多数の独立した決定木を平均"
        case .xgboost: "木を順番に追加して残差を補正"
        }
    }
}

struct PaperMetric: Identifiable, Equatable, Sendable {
    let model: ModelKind
    let amountRMSE: Double
    let amountR2: Double
    let percentageRMSE: Double
    let percentageR2: Double

    var id: ModelKind { model }

    var percentageExplainedVariation: Double { percentageR2 * 100 }
    var percentageUnexplainedVariation: Double { max(0, (1 - percentageR2) * 100) }

    /// Values transcribed from Yuan et al. (2023), Table 4.
    static let reported: [PaperMetric] = [
        .init(model: .xgboost, amountRMSE: 4_447.23, amountR2: 0.98, percentageRMSE: 28.24, percentageR2: 0.98),
        .init(model: .rf, amountRMSE: 7_043.97, amountR2: 0.95, percentageRMSE: 34.33, percentageR2: 0.97),
        .init(model: .fick, amountRMSE: 6_778.17, amountR2: 0.95, percentageRMSE: 85.58, percentageR2: 0.82),
        .init(model: .mlr, amountRMSE: 23_398.91, amountR2: 0.46, percentageRMSE: 120.33, percentageR2: 0.65),
    ]

    static var comparisonOrder: [PaperMetric] {
        ModelKind.allCases.compactMap { model in
            reported.first { $0.model == model }
        }
    }
}

struct MethodComparison: Identifiable, Equatable, Sendable {
    let model: ModelKind
    let category: BiText
    let mechanism: BiText
    let modelForm: BiText
    let prediction: BiText
    let training: BiText
    let strength: BiText
    let limitation: BiText
    let interpretation: BiText

    var id: ModelKind { model }

    static let paperMethods: [MethodComparison] = [
        .init(
            model: .fick,
            category: BiText("機構・物理モデル", "Mechanistic / physical"),
            mechanism: BiText("薬物は濃い場所から薄い場所へ拡散する、という物理則で時間変化を表す", "Represents change over time using the physical rule that drug diffuses from higher to lower concentration"),
            modelForm: BiText("拡散方程式 ∂C/∂t = D∇²C とフラックス J = −D∇C を、MNと皮膚の2次元格子上で数値的に解く", "Numerically solves the diffusion equation ∂C/∂t = D∇²C and flux J = −D∇C on a 2D MN–skin grid"),
            prediction: BiText("初期の薬物配置と境界条件を置き、短い時間刻みごとに隣接格子への移動を計算し、皮膚側の累積量を合計する", "Sets the initial drug distribution and boundary conditions, advances diffusion over small time steps, then sums cumulative drug reaching the skin side"),
            training: BiText("学習なし（文献の拡散係数を使用）", "No training; uses literature diffusivity"),
            strength: BiText("物理的な解釈とパラメータ感度解析", "Physical interpretation and parameter-sensitivity analysis"),
            limitation: BiText("一様な材料、既知の拡散係数などの仮定が外れると系統的にずれる", "Can be systematically wrong when assumptions such as homogeneous materials or valid diffusivity do not hold"),
            interpretation: BiText("「Dを上げたら」のような条件付きの仮想変更を追いやすいが、生体内で同じ変化が起こる保証ではない", "Supports conditional what-if reasoning such as increasing D, but does not guarantee the same change in vivo")
        ),
        .init(
            model: .mlr,
            category: BiText("線形統計モデル", "Linear statistical"),
            mechanism: BiText("各特徴量が予測値を一定量ずつ上げ下げするとみなし、7特徴量の寄与を足し合わせる", "Assumes each of seven features raises or lowers the prediction by a constant amount and adds those contributions"),
            modelForm: BiText("ŷ = β0 + β1x1 + … + β7x7。βの符号は上下方向、大きさは入力の単位当たりの変化を表す", "ŷ = β0 + β1x1 + … + β7x7; a coefficient's sign gives direction and its magnitude gives change per input unit"),
            prediction: BiText("新しい条件の7入力に学習済み係数を掛け、切片とともに1回加算して透過量または透過率を得る", "Multiplies the seven inputs for a new condition by fitted coefficients and adds them once with the intercept to obtain amount or percentage"),
            training: BiText("学習データから係数を推定", "Estimates coefficients from training data"),
            strength: BiText("係数と予測過程を説明しやすい", "Coefficients and predictions are easy to explain"),
            limitation: BiText("非線形性や複雑な相互作用を捕らえにくく、外挿で非現実的な値を返すことがある", "Struggles with nonlinearities and complex interactions and can return unrealistic values when extrapolating"),
            interpretation: BiText("係数は「他の入力が同じ」という条件付きで読む。相関した特徴量やカテゴリ符号化の影響を受け、因果効果ではない", "Read coefficients conditionally, holding other inputs fixed. Correlated features and category coding affect them; they are not causal effects")
        ),
        .init(
            model: .rf,
            category: BiText("バッグイング・アンサンブル", "Bagging ensemble"),
            mechanism: BiText("少しずつ異なるデータと特徴量で多数の決定木を作り、ばらつく予測を平均して安定化する", "Builds many decision trees from slightly different data and feature sets, then averages their varying predictions for stability"),
            modelForm: BiText("各木は「透過時間 < 12 h」のような閾値分岐を重ね、終端葉の学習値平均を返す。フォレストは全木の平均", "Each tree applies threshold splits such as permeation time < 12 h and returns the mean training value in a terminal leaf; the forest averages all trees"),
            prediction: BiText("新しい7入力をすべての木に通し、到達した葉の値を平均する。木ごとの誤差が打ち消される", "Passes the seven new inputs through every tree and averages the reached leaf values, allowing tree-specific errors to cancel"),
            training: BiText("ブートストラップ標本で複数木を学習", "Trains multiple trees on bootstrap samples"),
            strength: BiText("非線形性と特徴量間の相互作用を扱える", "Handles nonlinearities and feature interactions"),
            limitation: BiText("個々の予測根拠がMLRより追いにくく、学習範囲外の連続的な外挿は苦手", "Individual predictions are harder to trace than MLR, and continuous extrapolation beyond the training range is weak"),
            interpretation: BiText("特徴量重要度はフォレスト全体で予測に役立った度合い。効果の向きや因果、その患者・条件の個別理由はそれだけでは分からない", "Feature importance summarizes usefulness across the forest; by itself it gives neither effect direction, causality, nor the reason for one individual prediction")
        ),
        .init(
            model: .xgboost,
            category: BiText("ブースティング・アンサンブル", "Boosting ensemble"),
            mechanism: BiText("まず単純な予測から始め、まだ大きい誤差を減らす小さな木を1本ずつ追加する", "Starts from a simple prediction and adds small trees one at a time to reduce the errors that remain"),
            modelForm: BiText("ŷ = 初期値 + η×(f1(x) + … + fK(x))。学習率 η で各木の修正量を抑え、正則化で木の複雑さも罰す", "ŷ = initial value + η×(f1(x) + … + fK(x)); learning rate η shrinks each correction and regularization penalizes tree complexity"),
            prediction: BiText("新しい7入力に対し、全木が返す小さな修正値を順に加算する。RFの平均と異なり、木には追加順序と役割がある", "Adds the small corrections returned by all trees for the seven new inputs. Unlike RF averaging, tree order and each tree's corrective role matter"),
            training: BiText("損失と木の複雑度を同時に最適化", "Optimizes predictive loss and tree complexity"),
            strength: BiText("原著の7:3ランダム分割で両アウトカム最良", "Best for both outcomes in the paper's random 7:3 split"),
            limitation: BiText("木の深さ・本数・学習率の調整が必要で、小標本では過学習しやすく、未知薬物への外挿は未保証", "Needs tuning of depth, tree count, and learning rate; small samples invite overfitting, and extrapolation to unseen drugs is unproven"),
            interpretation: BiText("原著のGain重要度は、特徴量が分岐で損失を減らした度合い。高いGainは因果性や未知薬物での有効性を証明しない", "The paper's Gain importance measures how much a feature reduced loss in splits; high Gain proves neither causality nor usefulness for unseen drugs")
        ),
    ]
}

enum ReportedImportantFeature: String, CaseIterable, Identifiable, Sendable {
    case drugLoading
    case permeationTime
    case mnSurfaceArea

    var id: Self { self }

    var name: BiText {
        switch self {
        case .drugLoading:
            BiText("薬物充填量", "Drug loading")
        case .permeationTime:
            BiText("透過時間", "Permeation time")
        case .mnSurfaceArea:
            BiText("MN表面積", "MN surface area")
        }
    }
}

struct FeatureImportanceFinding: Identifiable, Equatable, Sendable {
    let feature: ReportedImportantFeature
    let amountIsMajor: Bool
    let percentageIsMajor: Bool

    var id: ReportedImportantFeature { feature }
}

enum FickSensitivityParameter: String, CaseIterable, Identifiable, Sendable {
    case diffusivity
    case needleCount
    case needleLength
    case drugLoading

    var id: Self { self }

    var name: BiText {
        switch self {
        case .diffusivity:
            BiText("拡散係数 D", "Diffusivity D")
        case .needleCount:
            BiText("MN本数 n", "MN count n")
        case .needleLength:
            BiText("MN長 l", "MN length l")
        case .drugLoading:
            BiText("薬物充填量 m", "Drug loading m")
        }
    }
}

enum FickSensitivityResponse: String, Equatable, Sendable {
    case fasterAndMore
    case unchangedAtFixedTotalLoading
    case morePermeation
    case morePermeationGreaterThanLength

    var description: BiText {
        switch self {
        case .fasterAndMore:
            BiText("透過が速くなり、透過量が増加", "Faster permeation and a greater amount")
        case .unchangedAtFixedTotalLoading:
            BiText(
                "総薬物充填量が一定なら、透過プロファイルは変化しない",
                "No change in the permeation profile when total drug loading is fixed"
            )
        case .morePermeation:
            BiText("透過量が増加", "Greater permeation amount")
        case .morePermeationGreaterThanLength:
            BiText(
                "透過量が増加し、同シミュレーションではMN長より影響が大きい",
                "Greater permeation, with a larger effect than MN length in the same simulation"
            )
        }
    }
}

struct FickSensitivityFinding: Identifiable, Equatable, Sendable {
    let parameter: FickSensitivityParameter
    let response: FickSensitivityResponse

    var id: FickSensitivityParameter { parameter }
}

enum PaperEvidence {
    /// Qualitative mapping supported by the paper text and Figure 8 for RF and XGBoost.
    static let importantFeatures: [FeatureImportanceFinding] = [
        .init(feature: .drugLoading, amountIsMajor: true, percentageIsMajor: false),
        .init(feature: .permeationTime, amountIsMajor: true, percentageIsMajor: true),
        .init(feature: .mnSurfaceArea, amountIsMajor: false, percentageIsMajor: true),
    ]

    /// Directional findings reported for the Fick-model parameter sweeps in Figure 5.
    static let fickSensitivity: [FickSensitivityFinding] = [
        .init(parameter: .diffusivity, response: .fasterAndMore),
        .init(parameter: .needleCount, response: .unchangedAtFixedTotalLoading),
        .init(parameter: .needleLength, response: .morePermeation),
        .init(parameter: .drugLoading, response: .morePermeationGreaterThanLength),
    ]
}
