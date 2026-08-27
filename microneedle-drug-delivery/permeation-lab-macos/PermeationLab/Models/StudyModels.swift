import Foundation

enum AppSection: String, CaseIterable, Identifiable {
    case overview = "研究概要"
    case methods = "方法・数式"
    case dataset = "実測データ"
    case skinPermeation = "皮膚透過"
    case results = "結果・比較"
    case figures = "原著図"
    case paper = "全文"
    case integrity = "研究情報"

    var id: Self { self }

    var symbol: String {
        switch self {
        case .overview: "doc.text.magnifyingglass"
        case .methods: "function"
        case .dataset: "tablecells"
        case .skinPermeation: "cross.vial"
        case .results: "chart.bar.xaxis"
        case .figures: "photo.on.rectangle.angled"
        case .paper: "text.book.closed"
        case .integrity: "checkmark.shield"
        }
    }
}

enum PermeationOutcome: String, CaseIterable, Identifiable {
    case amount = "累積透過量"
    case percentage = "累積透過率"

    var id: Self { self }
    var unit: String { self == .amount ? "µg/cm²" : "%" }
}

enum SkinKind: Int, CaseIterable, Identifiable {
    case rat = 1
    case human = 2

    var id: Int { rawValue }
    var label: String { self == .rat ? "ラット" : "ヒト" }
}

enum MicroneedleKind: Int, CaseIterable, Identifiable {
    case hydrogel = 1
    case plastic = 2

    var id: Int { rawValue }
    var label: String { self == .hydrogel ? "ヒドロゲル" : "プラスチック" }
}

struct PermeationRecord: Identifiable, Hashable {
    let id: Int
    let drug: String
    let loadingMicrograms: Double
    let molecularWeightDalton: Double
    let needleLengthMillimeters: Double
    let skin: SkinKind
    let needle: MicroneedleKind
    let surfaceAreaSquareMillimeters: Double
    let timeHours: Double
    let percentage: Double
    let amountMicrogramsPerSquareCentimeter: Double
    let reference: String?

    func value(for outcome: PermeationOutcome) -> Double {
        outcome == .amount ? amountMicrogramsPerSquareCentimeter : percentage
    }
}

enum ObservedSeriesTopology: Equatable {
    case unconnectedPoints
}

struct ObservedPermeationPoint: Identifiable, Equatable {
    let recordID: Int
    let drug: String
    let timeHours: Double
    let value: Double

    var id: Int { recordID }
}

struct ConceptMechanismStep: Identifiable, Equatable {
    let index: Int
    let title: String
    let detail: String

    var id: Int { index }
}

enum SkinPermeationPresentation {
    static let observedTopology: ObservedSeriesTopology = .unconnectedPoints
    static let dataS1AmountUnit = "µg/cm²"

    static func observedPoints(
        records: [PermeationRecord],
        outcome: PermeationOutcome
    ) -> [ObservedPermeationPoint] {
        records.map {
            ObservedPermeationPoint(
                recordID: $0.id,
                drug: $0.drug,
                timeHours: $0.timeHours,
                value: $0.value(for: outcome)
            )
        }
    }

    static func mechanismSteps(for needle: MicroneedleKind) -> [ConceptMechanismStep] {
        switch needle {
        case .hydrogel:
            [
                .init(index: 0, title: "留置", detail: "薬物を含浸したhydrogel MNを皮膚膜へ挿入したままにします。"),
                .init(index: 1, title: "膨潤・放出", detail: "MNが水分を吸収し、有限reservoirから隣接する皮膚組織へ薬物を放出します。"),
                .init(index: 2, title: "皮膚膜内を移行", detail: "薬物が皮膚膜を通ってreceptor側へ向かいます。"),
                .init(index: 3, title: "receptorで測定・算出", detail: "receptor液中濃度から累積量を求め、搭載量に対する累積率を算出します。")
            ]
        case .plastic:
            [
                .init(index: 0, title: "前処置", detail: "plastic MNで皮膚膜を前処置します。"),
                .init(index: 1, title: "MNを除去", detail: "patchを取り外し、皮膚膜にmicron-sized passageを残します。"),
                .init(index: 2, title: "donor溶液を添加", detail: "donor側の薬物水溶液が残ったpassageを満たします。"),
                .init(index: 3, title: "receptorで測定・算出", detail: "receptor液中濃度から累積量を求め、搭載量に対する累積率を算出します。")
            ]
        }
    }
}

enum PaperModel: String, CaseIterable, Identifiable {
    case xgboost = "XGBoost"
    case randomForest = "Random Forest"
    case fick = "Fick の法則"
    case mlr = "MLR"

    var id: Self { self }
    var shortLabel: String {
        switch self {
        case .xgboost: "XGBoost"
        case .randomForest: "RF"
        case .fick: "Fick"
        case .mlr: "MLR"
        }
    }
}

struct ReportedMetric: Identifiable, Hashable {
    let model: PaperModel
    let amountRMSE: Double
    let amountR2: Double
    let percentageRMSE: Double
    let percentageR2: Double

    var id: PaperModel { model }
}

struct EvidenceLocator: Hashable {
    let location: String
    let note: String
}

struct EquationItem: Identifiable, Hashable {
    let number: Int
    let title: String
    let expression: String
    let explanation: String
    let evidence: EvidenceLocator

    var id: Int { number }
}

struct CalculationExample: Identifiable, Hashable {
    let id: String
    let title: String
    let expression: String
    let explanation: String
    let evidence: EvidenceLocator
}

struct PaperFigure: Identifiable, Hashable {
    let id: String
    let label: String
    let resourceName: String
    let fileExtension: String
    let caption: String
    let readingGuide: String
    let evidence: EvidenceLocator
}

struct StudyTopic: Identifiable, Hashable {
    let id: String
    let title: String
    let summary: String
    let bullets: [String]
    let evidence: EvidenceLocator
}

struct ParameterRow: Identifiable, Hashable {
    let name: String
    let value: String
    var id: String { "\(name)-\(value)" }
}

struct HyperparameterRow: Identifiable, Hashable {
    let outcome: String
    let xgboost: String
    let randomForest: String
    var id: String { outcome }
}

struct AuthorContribution: Identifiable, Hashable {
    let name: String
    let contribution: String
    var id: String { name }
}
