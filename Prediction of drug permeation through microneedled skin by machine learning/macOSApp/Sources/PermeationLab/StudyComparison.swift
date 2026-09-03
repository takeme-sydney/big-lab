import Foundation

struct ComparableStudyRow: Identifiable, Equatable, Sendable {
    let id: Int
    let drugName: String
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

    init(_ row: TrainingDataRow) {
        id = row.id
        drugName = row.sourceDrugName
        loading = row.loading
        molecularWeight = row.molecularWeight
        needleLength = row.needleLength
        skin = row.skin
        needle = row.needle
        surfaceArea = row.surfaceArea
        permeationTime = row.permeationTime
        percentage = row.percentage
        amount = row.amount
        reference = row.reference
    }

    init(fields: [String], id: Int) throws {
        func number(_ index: Int, positive: Bool = false) throws -> Double {
            let text = fields[index].trimmingCharacters(in: .whitespacesAndNewlines)
            guard let value = Double(text), value.isFinite, positive ? value > 0 : value >= 0 else {
                throw ComparableStudyError.invalidValue(row: id + 1, column: index + 1, value: fields[index])
            }
            return value
        }

        let name = fields[0].trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { throw ComparableStudyError.missingDrugName(row: id + 1) }
        guard let parsedSkin = SkinType(sourceCode: fields[4]) else {
            throw ComparableStudyError.invalidValue(row: id + 1, column: 5, value: fields[4])
        }
        guard let parsedNeedle = NeedleType(sourceCode: fields[5]) else {
            throw ComparableStudyError.invalidValue(row: id + 1, column: 6, value: fields[5])
        }

        self.id = id
        drugName = name
        loading = try number(1, positive: true)
        molecularWeight = try number(2, positive: true)
        needleLength = try number(3, positive: true)
        skin = parsedSkin
        needle = parsedNeedle
        surfaceArea = try number(6, positive: true)
        permeationTime = try number(7)
        percentage = try number(8)
        amount = try number(9)
        reference = fields[10].trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func value(for metric: DatasetComparisonMetric) -> Double {
        switch metric {
        case .loading: loading
        case .molecularWeight: molecularWeight
        case .needleLength: needleLength
        case .surfaceArea: surfaceArea
        case .permeationTime: permeationTime
        case .amount: amount
        case .percentage: percentage
        }
    }

    /// Returns true only when the observation belongs to the experimental
    /// condition represented by the profile controls. Time is deliberately
    /// excluded because a profile contains multiple sampling times.
    func matchesExperimentalCondition(_ scenario: Scenario) -> Bool {
        let acceptedDrugNames = [scenario.drug.sourceName, scenario.drug.rawValue]
            .map { $0.lowercased() }
        return acceptedDrugNames.contains(drugName.lowercased())
            && skin == scenario.skin
            && needle == scenario.needle
            && approximatelyEqual(loading, scenario.loading)
            && approximatelyEqual(needleLength, scenario.length)
            && approximatelyEqual(surfaceArea, scenario.surfaceArea)
    }

    private func approximatelyEqual(_ lhs: Double, _ rhs: Double) -> Bool {
        let scale = max(abs(lhs), abs(rhs), 1)
        return abs(lhs - rhs) <= scale * 1e-6
    }
}

struct ComparableStudyDataset: Equatable, Sendable {
    let name: String
    let rows: [ComparableStudyRow]

    var drugNames: [String] { Array(Set(rows.map(\.drugName))).sorted() }
    var references: [String] { Array(Set(rows.map(\.reference).filter { !$0.isEmpty })).sorted() }

    static let yuan = ComparableStudyDataset(
        name: "Yuan 2023 · Data S1",
        rows: TrainingDataSource.rows.map(ComparableStudyRow.init)
    )

    static func parse(name: String, csvText: String) throws -> Self {
        let generic = try GenericDataset.parse(name: name, text: csvText)
        guard generic.headers == TrainingDataSource.expectedHeader else {
            throw ComparableStudyError.schema
        }
        guard !generic.rows.isEmpty else { throw ComparableStudyError.empty }
        let rows = try generic.rows.enumerated().map { offset, fields in
            try ComparableStudyRow(fields: fields, id: offset + 1)
        }
        return Self(name: name, rows: rows)
    }
}

enum ComparableStudyError: LocalizedError {
    case schema
    case empty
    case missingDrugName(row: Int)
    case invalidValue(row: Int, column: Int, value: String)

    var errorDescription: String? {
        switch self {
        case .schema: "The CSV header must exactly match the 11-column Data S1 schema."
        case .empty: "The CSV contains no observations."
        case .missingDrugName(let row): "Drug name is missing at CSV row \(row)."
        case .invalidValue(let row, let column, let value): "Invalid value at CSV row \(row), column \(column): \(value)"
        }
    }
}

struct StudyMetricSummary: Equatable, Sendable {
    let count: Int
    let minimum: Double
    let median: Double
    let maximum: Double

    static func make(rows: [ComparableStudyRow], metric: DatasetComparisonMetric) -> Self? {
        let values = rows.map { $0.value(for: metric) }.sorted()
        guard let minimum = values.first, let maximum = values.last else { return nil }
        let middle = values.count / 2
        let median = values.count.isMultiple(of: 2)
            ? (values[middle - 1] + values[middle]) / 2
            : values[middle]
        return Self(count: values.count, minimum: minimum, median: median, maximum: maximum)
    }
}
