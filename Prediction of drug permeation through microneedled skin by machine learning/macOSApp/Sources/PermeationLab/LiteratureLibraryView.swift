import Charts
import Foundation
import SwiftUI

struct LiteratureLibraryView: View {
    let language: AppLanguage

    @State private var searchText = ""
    @State private var selectedCategory = Self.allCategory

    private static let allCategory = "__all__"
    private let library = LiteraturePaperLibrary.bundled

    private var records: [LiteraturePaper] {
        library.records
    }

    private var categories: [String] {
        Array(Set(records.map(\.category))).sorted()
    }

    private var filteredRecords: [LiteraturePaper] {
        records.filter { record in
            let categoryMatches = selectedCategory == Self.allCategory
                || record.category == selectedCategory
            let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return categoryMatches }
            let needle = trimmed.folding(
                options: [.caseInsensitive, .diacriticInsensitive],
                locale: .current
            )
            let haystack = [
                record.title,
                record.authors,
                record.journal,
                record.doi,
                record.category,
                record.studyType,
                record.relevanceJapanese,
                record.keyFactJapanese,
                record.limitationJapanese,
            ]
                .joined(separator: " ")
                .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            return categoryMatches && haystack.contains(needle)
        }
    }

    private var yearCounts: [LiteratureYearCount] {
        Dictionary(grouping: records, by: \.year)
            .map { LiteratureYearCount(year: $0.key, count: $0.value.count) }
            .sorted { $0.year < $1.year }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                LabWorkspaceHeader(
                    title: language.text("関連論文30報", "30-paper literature library"),
                    subtitle: language.text(
                        "マイクロニードル皮膚透過・Fick・機械学習の検証済み文献ストック",
                        "Verified literature on microneedled-skin transport, Fick modelling, and machine learning"
                    ),
                    systemImage: "books.vertical.fill"
                )

                LabNotice(
                    title: language.text("文献事実の領域", "Literature-fact area"),
                    message: language.text(
                        "書誌情報、論文が直接支持する要点、各研究の限界を表示します。このプロジェクトの予測値や仮説は混ぜていません。選定基準と検証記録の正本はMarkdown文献レビューです。",
                        "This view contains bibliographic facts, directly supported findings, and each study's limitations. Project predictions and hypotheses are excluded. The canonical selection and verification record is the Markdown literature review."
                    ),
                    kind: .information
                )

                if let error = library.error {
                    LabNotice(
                        title: language.text("文献データを読み込めません", "Unable to load the literature library"),
                        message: error,
                        kind: .warning
                    )
                } else {
                    summarySection
                    filterSection
                    paperList
                }
            }
            .frame(maxWidth: LabTheme.contentWidth, alignment: .leading)
            .padding(LabTheme.pagePadding)
            .frame(maxWidth: .infinity, alignment: .top)
        }
        .accessibilityIdentifier("screen.literature-library")
    }

    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 210), spacing: 14)],
                alignment: .leading,
                spacing: 14
            ) {
                LabMetricCard(
                    title: language.text("検証済み文献", "Verified papers"),
                    value: "\(records.count)",
                    detail: language.text("2026-08-30検索・DOI/一次情報照合", "Searched 2026-08-30; DOI/primary records checked"),
                    systemImage: "checkmark.seal"
                )
                LabMetricCard(
                    title: language.text("最新年", "Newest year"),
                    value: records.map(\.year).max().map(String.init) ?? "—",
                    detail: language.text("online-firstを含む書誌年", "Bibliographic year, including online-first"),
                    systemImage: "calendar"
                )
                LabMetricCard(
                    title: language.text("テーマ", "Topics"),
                    value: "\(categories.count)",
                    detail: language.text("直接関連性で分類", "Grouped by direct relevance"),
                    systemImage: "square.grid.2x2"
                )
            }

            LabSection(language.text("出版年の分布", "Publication-year distribution")) {
                Chart(yearCounts) { item in
                    BarMark(
                        x: .value(language.text("年", "Year"), String(item.year)),
                        y: .value(language.text("論文数", "Papers"), item.count)
                    )
                    .foregroundStyle(Color.green.gradient)
                    .annotation(position: .top) {
                        Text("\(item.count)")
                            .font(.caption.monospacedDigit())
                    }
                }
                .chartYAxisLabel(language.text("論文数", "Papers"))
                .frame(height: 210)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(language.text("30報の出版年分布", "Publication-year distribution of 30 papers"))
                .accessibilityValue(yearCounts.map { "\($0.year): \($0.count)" }.joined(separator: ", "))
                .accessibilityIdentifier("literature.year-chart")
            }
        }
    }

    private var filterSection: some View {
        LabSection(language.text("検索・絞り込み", "Search and filter")) {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 12) {
                    searchField
                    categoryPicker
                    resultCount
                }
                VStack(alignment: .leading, spacing: 10) {
                    searchField
                    HStack {
                        categoryPicker
                        resultCount
                    }
                }
            }
        }
    }

    private var searchField: some View {
        TextField(
            language.text("題名・著者・DOI・要点を検索", "Search title, author, DOI, or finding"),
            text: $searchText
        )
        .textFieldStyle(.roundedBorder)
        .frame(minWidth: 280)
        .accessibilityIdentifier("literature.search")
    }

    private var categoryPicker: some View {
        Picker(language.text("分類", "Category"), selection: $selectedCategory) {
            Text(language.text("すべて", "All")).tag(Self.allCategory)
            ForEach(categories, id: \.self) { category in
                Text(LiteraturePaper.categoryTitle(category, language: language)).tag(category)
            }
        }
        .frame(minWidth: 190)
        .accessibilityIdentifier("literature.category")
    }

    private var resultCount: some View {
        Text(language.text(
            "\(filteredRecords.count) / \(records.count)報",
            "\(filteredRecords.count) of \(records.count)"
        ))
        .font(.callout.monospacedDigit())
        .foregroundStyle(.secondary)
        .accessibilityIdentifier("literature.result-count")
    }

    private var paperList: some View {
        LazyVStack(alignment: .leading, spacing: 14) {
            if filteredRecords.isEmpty {
                ContentUnavailableView(
                    language.text("該当文献がありません", "No matching papers"),
                    systemImage: "magnifyingglass",
                    description: Text(language.text(
                        "検索語または分類を変更してください。",
                        "Change the search term or category."
                    ))
                )
                .frame(height: 220)
            } else {
                ForEach(filteredRecords) { paper in
                    LiteraturePaperCard(language: language, paper: paper)
                }
            }
        }
        .accessibilityIdentifier("literature.list")
    }
}

private struct LiteraturePaperCard: View {
    let language: AppLanguage
    let paper: LiteraturePaper

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(String(paper.year))
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(.green)
                Text(paper.categoryTitle(language))
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.green.opacity(0.10), in: Capsule())
                Text(paper.studyTypeTitle(language))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer(minLength: 8)
                Text(paper.id)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.tertiary)
            }

            Text(paper.title)
                .font(.title3.bold())
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)

            Text("\(paper.authors) · \(paper.journal)")
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Divider()

            literatureRow(
                language.text("直接関係", "Direct relevance"),
                paper.relevanceJapanese,
                "scope"
            )
            literatureRow(
                language.text("論文が支持する事実", "Supported finding"),
                paper.keyFactJapanese,
                "checkmark.seal"
            )
            literatureRow(
                language.text("限界", "Limitation"),
                paper.limitationJapanese,
                "exclamationmark.triangle"
            )

            HStack(spacing: 16) {
                if let url = URL(string: paper.url) {
                    Link(destination: url) {
                        Label(language.text("一次情報を開く", "Open primary record"), systemImage: "arrow.up.right.square")
                    }
                }
                if !paper.doi.isEmpty,
                   let doiURL = URL(string: "https://doi.org/\(paper.doi)") {
                    Link("DOI \(paper.doi)", destination: doiURL)
                        .font(.caption.monospaced())
                }
            }
        }
        .padding(16)
        .labCard()
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("literature.paper.\(paper.id)")
    }

    private func literatureRow(_ title: String, _ value: String, _ symbol: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: symbol)
                .foregroundStyle(.secondary)
                .frame(width: 18)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.callout)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

struct LiteraturePaper: Identifiable, Equatable {
    let id: String
    let year: Int
    let title: String
    let authors: String
    let journal: String
    let doi: String
    let url: String
    let category: String
    let studyType: String
    let relevanceJapanese: String
    let keyFactJapanese: String
    let limitationJapanese: String

    func categoryTitle(_ language: AppLanguage) -> String {
        Self.categoryTitle(category, language: language)
    }

    static func categoryTitle(_ category: String, language: AppLanguage) -> String {
        let japanese: [String: String] = [
            "ai_qbd_experiment": "AI・QbD実験",
            "biophysical_pk": "生物物理・PK",
            "diffusivity_measurement": "拡散係数測定",
            "dissolving_transport": "溶解型MN輸送",
            "experiment_optimization": "実験最適化",
            "fick_fem": "Fick・有限要素",
            "foundational_qspr": "基礎QSPR",
            "geometry_optimization": "形状最適化",
            "geometry_strain": "形状・皮膚ひずみ",
            "hydrogel_transport": "ハイドロゲルMN輸送",
            "mechanistic_transport": "機構輸送モデル",
            "micropore_flux": "微小孔フラックス",
            "ml_fick": "ML・Fick比較",
            "ml_permeation": "ML透過予測",
            "ml_qspr": "ML・QSPR",
            "multiphysics": "マルチフィジックス",
            "multiphysics_pkpd": "マルチフィジックス・PK/PD",
            "non_fickian_transport": "非Fick輸送",
            "particle_transport": "粒子輸送",
            "passive_qspr": "受動透過QSPR",
            "pbpk": "PBPK",
            "physics_informed": "物理情報ML",
            "polymer_transport": "ポリマー輸送",
            "reaction_diffusion": "反応拡散",
            "review": "レビュー",
        ]
        if language == .japanese, let title = japanese[category] { return title }
        return category
            .split(separator: "_")
            .map { token in
                let raw = String(token)
                return ["ai", "fick", "fem", "ml", "mn", "pbpk", "pk", "pkpd", "qbd", "qspr"]
                    .contains(raw) ? raw.uppercased() : raw.capitalized
            }
            .joined(separator: " ")
    }

    func studyTypeTitle(_ language: AppLanguage) -> String {
        let japanese: [String: String] = [
            "primary_experiment": "一次実験",
            "primary_experiment_model": "一次実験＋モデル",
            "primary_experiment_simulation": "一次実験＋simulation",
            "primary_ml": "一次ML研究",
            "primary_modeling": "一次モデル研究",
            "primary_pbpk": "一次PBPK研究",
            "primary_qspr": "一次QSPR研究",
            "review": "査読レビュー",
        ]
        if language == .japanese, let title = japanese[studyType] { return title }
        let english: [String: String] = [
            "primary_experiment": "Primary experiment",
            "primary_experiment_model": "Primary experiment + model",
            "primary_experiment_simulation": "Primary experiment + simulation",
            "primary_ml": "Primary ML study",
            "primary_modeling": "Primary modelling study",
            "primary_pbpk": "Primary PBPK study",
            "primary_qspr": "Primary QSPR study",
            "review": "Peer-reviewed review",
        ]
        return english[studyType] ?? studyType
    }
}

struct LiteraturePaperLibrary {
    let records: [LiteraturePaper]
    let error: String?

    static var bundled: LiteraturePaperLibrary {
        guard let url = Bundle.main.url(
            forResource: "latest_30_papers",
            withExtension: "csv"
        ) else {
            return .init(records: [], error: "latest_30_papers.csv is missing from the app bundle.")
        }

        do {
            let text = try String(contentsOf: url, encoding: .utf8)
            let rows = try RFC4180Reader.parse(text)
            guard let header = rows.first else {
                return .init(records: [], error: "The literature CSV is empty.")
            }
            let normalizedHeader = header.map {
                $0.trimmingCharacters(in: .whitespacesAndNewlines)
                    .lowercased()
                    .replacingOccurrences(of: "\u{feff}", with: "")
            }
            var index: [String: Int] = [:]
            var duplicateHeaders: Set<String> = []
            for (offset, name) in normalizedHeader.enumerated() {
                if index.updateValue(offset, forKey: name) != nil {
                    duplicateHeaders.insert(name)
                }
            }
            guard duplicateHeaders.isEmpty else {
                return .init(
                    records: [],
                    error: "The literature CSV contains duplicate columns: "
                        + duplicateHeaders.sorted().joined(separator: ", ")
                )
            }
            let required = [
                "id", "year", "title", "authors", "journal", "doi", "url",
                "category", "study_type", "relevance_ja", "key_fact_ja", "limitation_ja",
            ]
            guard required.allSatisfy({ index[$0] != nil }) else {
                return .init(records: [], error: "The literature CSV schema is incomplete.")
            }

            func field(_ row: [String], _ name: String) -> String {
                guard let column = index[name], row.indices.contains(column) else { return "" }
                return row[column].trimmingCharacters(in: .whitespacesAndNewlines)
            }

            guard rows.dropFirst().allSatisfy({ $0.count == header.count }) else {
                return .init(records: [], error: "The literature CSV contains a malformed row.")
            }

            let records = rows.dropFirst().compactMap { row -> LiteraturePaper? in
                let id = field(row, "id")
                guard !id.isEmpty,
                      let year = Int(field(row, "year")),
                      !field(row, "title").isEmpty else { return nil }
                return LiteraturePaper(
                    id: id,
                    year: year,
                    title: field(row, "title"),
                    authors: field(row, "authors"),
                    journal: field(row, "journal"),
                    doi: field(row, "doi"),
                    url: field(row, "url"),
                    category: field(row, "category"),
                    studyType: field(row, "study_type"),
                    relevanceJapanese: field(row, "relevance_ja"),
                    keyFactJapanese: field(row, "key_fact_ja"),
                    limitationJapanese: field(row, "limitation_ja")
                )
            }
                .sorted { lhs, rhs in
                    lhs.year == rhs.year ? lhs.id < rhs.id : lhs.year > rhs.year
                }

            guard records.count == 30, Set(records.map(\.id)).count == 30 else {
                return .init(
                    records: records,
                    error: "The verified literature library must contain exactly 30 unique records; found \(records.count)."
                )
            }
            return .init(records: records, error: nil)
        } catch {
            return .init(records: [], error: error.localizedDescription)
        }
    }
}

private struct LiteratureYearCount: Identifiable {
    let year: Int
    let count: Int
    var id: Int { year }
}

private enum RFC4180Reader {
    private struct ParseError: LocalizedError {
        let errorDescription: String?
    }

    static func parse(_ text: String) throws -> [[String]] {
        var rows: [[String]] = []
        var row: [String] = []
        var field = ""
        var insideQuotes = false
        var index = text.startIndex

        func finishField() {
            row.append(field)
            field = ""
        }

        func finishRow() {
            finishField()
            if !row.allSatisfy({ $0.isEmpty }) {
                rows.append(row)
            }
            row = []
        }

        while index < text.endIndex {
            let character = text[index]
            if character == "\"" {
                let next = text.index(after: index)
                if insideQuotes, next < text.endIndex, text[next] == "\"" {
                    field.append("\"")
                    index = text.index(after: next)
                    continue
                }
                insideQuotes.toggle()
            } else if character == ",", !insideQuotes {
                finishField()
            } else if character.isNewline, !insideQuotes {
                finishRow()
            } else {
                field.append(character)
            }
            index = text.index(after: index)
        }

        guard !insideQuotes else {
            throw ParseError(errorDescription: "The literature CSV contains an unterminated quoted field.")
        }

        if !field.isEmpty || !row.isEmpty {
            finishRow()
        }
        return rows
    }
}
