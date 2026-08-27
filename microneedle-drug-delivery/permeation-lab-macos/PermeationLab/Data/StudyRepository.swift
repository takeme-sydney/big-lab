import Foundation

enum StudyDataError: LocalizedError, Equatable {
    case missingResource(String)
    case unreadableText
    case invalidHeader
    case invalidColumnCount(row: Int, count: Int)
    case invalidNumber(row: Int, column: String, value: String)
    case invalidCategory(row: Int, column: String, value: String)

    var errorDescription: String? {
        switch self {
        case .missingResource(let name): "同梱資料 \(name) が見つかりません。"
        case .unreadableText: "同梱 CSV を UTF-8 として読み込めません。"
        case .invalidHeader: "Data S1 の列構成が想定と一致しません。"
        case .invalidColumnCount(let row, let count): "CSV \(row) 行目の列数が不正です（\(count)列）。"
        case .invalidNumber(let row, let column, let value): "CSV \(row) 行目の \(column) が数値ではありません: \(value)"
        case .invalidCategory(let row, let column, let value): "CSV \(row) 行目の \(column) が未定義です: \(value)"
        }
    }
}

enum StudyResourceLocator {
    static func url(
        name: String,
        extension fileExtension: String,
        subdirectory: String? = nil,
        bundle: Bundle = .main
    ) -> URL? {
        if let url = bundle.url(forResource: name, withExtension: fileExtension, subdirectory: subdirectory) {
            return url
        }
        if let url = bundle.url(forResource: name, withExtension: fileExtension) {
            return url
        }
        guard let root = bundle.resourceURL,
              let enumerator = FileManager.default.enumerator(
                at: root,
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles]
              ) else { return nil }

        let target = "\(name).\(fileExtension)"
        for case let candidate as URL in enumerator where candidate.lastPathComponent == target {
            return candidate
        }
        return nil
    }
}

enum TrainingDataParser {
    static let expectedHeaders = [
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
        "References"
    ]

    static func parse(data: Data) throws -> [PermeationRecord] {
        guard let text = String(data: data, encoding: .utf8) else {
            throw StudyDataError.unreadableText
        }
        return try parse(text: text)
    }

    static func parse(text: String) throws -> [PermeationRecord] {
        let rawRows = parseCSV(text)
        guard let rawHeader = rawRows.first else { throw StudyDataError.invalidHeader }
        var header = rawHeader
        if !header.isEmpty {
            header[0] = header[0].replacingOccurrences(of: "\u{feff}", with: "")
        }
        guard header == expectedHeaders else { throw StudyDataError.invalidHeader }

        return try rawRows.dropFirst().enumerated().map { offset, fields in
            let sourceRow = offset + 2
            guard fields.count == expectedHeaders.count else {
                throw StudyDataError.invalidColumnCount(row: sourceRow, count: fields.count)
            }

            func number(_ index: Int) throws -> Double {
                guard let value = Double(fields[index]), value.isFinite else {
                    throw StudyDataError.invalidNumber(
                        row: sourceRow,
                        column: expectedHeaders[index],
                        value: fields[index]
                    )
                }
                return value
            }

            let skinCode = try number(4)
            guard let skin = SkinKind(rawValue: Int(skinCode)), skinCode.rounded() == skinCode else {
                throw StudyDataError.invalidCategory(row: sourceRow, column: expectedHeaders[4], value: fields[4])
            }
            let needleCode = try number(5)
            guard let needle = MicroneedleKind(rawValue: Int(needleCode)), needleCode.rounded() == needleCode else {
                throw StudyDataError.invalidCategory(row: sourceRow, column: expectedHeaders[5], value: fields[5])
            }

            return PermeationRecord(
                id: offset + 1,
                drug: fields[0],
                loadingMicrograms: try number(1),
                molecularWeightDalton: try number(2),
                needleLengthMillimeters: try number(3),
                skin: skin,
                needle: needle,
                surfaceAreaSquareMillimeters: try number(6),
                timeHours: try number(7),
                percentage: try number(8),
                amountMicrogramsPerSquareCentimeter: try number(9),
                reference: fields[10].isEmpty ? nil : fields[10]
            )
        }
    }

    static func parseCSV(_ text: String) -> [[String]] {
        var result: [[String]] = []
        var row: [String] = []
        var field = ""
        var isQuoted = false
        var index = text.startIndex

        func appendRow() {
            row.append(field.trimmingCharacters(in: .whitespacesAndNewlines))
            if !row.allSatisfy(\.isEmpty) { result.append(row) }
            row = []
            field = ""
        }

        while index < text.endIndex {
            let character = text[index]
            if character == "\"" {
                let next = text.index(after: index)
                if isQuoted, next < text.endIndex, text[next] == "\"" {
                    field.append("\"")
                    index = next
                } else {
                    isQuoted.toggle()
                }
            } else if character == ",", !isQuoted {
                row.append(field)
                field = ""
            } else if character == "\n", !isQuoted {
                appendRow()
            } else if character != "\r" {
                field.append(character)
            }
            index = text.index(after: index)
        }

        if !field.isEmpty || !row.isEmpty { appendRow() }
        return result
    }
}

final class StudyRepository {
    let records: [PermeationRecord]
    let loadingError: String?

    init(bundle: Bundle = .main) {
        do {
            guard let url = StudyResourceLocator.url(
                name: "yuan2023-training-data",
                extension: "csv",
                bundle: bundle
            ) else {
                throw StudyDataError.missingResource("yuan2023-training-data.csv")
            }
            records = try TrainingDataParser.parse(data: Data(contentsOf: url))
            loadingError = nil
        } catch {
            records = []
            loadingError = error.localizedDescription
        }
    }

    init(records: [PermeationRecord]) {
        self.records = records
        loadingError = nil
    }

    var drugs: [String] { Array(Set(records.map(\.drug))).sorted() }

    func filtered(
        drug: String?,
        skin: SkinKind?,
        needle: MicroneedleKind?
    ) -> [PermeationRecord] {
        records.filter { record in
            (drug == nil || record.drug == drug)
                && (skin == nil || record.skin == skin)
                && (needle == nil || record.needle == needle)
        }
    }

    func countByDrug() -> [(drug: String, count: Int)] {
        Dictionary(grouping: records, by: \.drug)
            .map { ($0.key, $0.value.count) }
            .sorted { lhs, rhs in
                lhs.count == rhs.count ? lhs.drug < rhs.drug : lhs.count > rhs.count
            }
    }
}

struct SupplementaryResource: Identifiable, Hashable {
    let id: String
    let title: String
    let detail: String
    let resourceName: String
    let fileExtension: String
    let evidence: String
}

extension PaperContent {
    static let bundledSources: [SupplementaryResource] = [
        .init(id: "paper-pdf", title: "原著 PDF", detail: "Bioengineering & Translational Medicine 掲載版", resourceName: "yuan2023-paper", fileExtension: "pdf", evidence: "原著"),
        .init(id: "data-s1", title: "Data S1", detail: "191実測点の原補足ワークブック", resourceName: "yuan2023-data-s1", fileExtension: "xlsx", evidence: "Supporting Information Data S1"),
        .init(id: "data-csv", title: "Data S1 CSV", detail: "アプリが厳格に読み込む191行×11列の転記", resourceName: "yuan2023-training-data", fileExtension: "csv", evidence: "Supporting Information Data S1"),
        .init(id: "data-s2", title: "Data S2", detail: "MLR・RF・XGBoost の R コードと Fick の C コード", resourceName: "yuan2023-code-si2", fileExtension: "docx", evidence: "Supporting Information Data S2"),
        .init(id: "figures-s1-s2", title: "Figures S1–S2", detail: "薬物除外検証の透過量・透過率図", resourceName: "yuan2023-new-drug-figures-si3", fileExtension: "docx", evidence: "Supporting Information Figures S1–S2"),
        .init(id: "code-text", title: "補足コード（テキスト）", detail: "Data S2をアプリ内で読みやすくした転記", resourceName: "yuan2023-supplementary-code", fileExtension: "txt", evidence: "Supporting Information Data S2"),
        .init(id: "paper-ja", title: "日本語全文 HTML", detail: "本文・図表・参考文献・末尾声明を含むオフライン版", resourceName: "yuan2023-paper-ja", fileExtension: "html", evidence: "原著全文の日本語版")
    ]
}
