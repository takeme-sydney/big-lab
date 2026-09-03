import Foundation
import SwiftUI

enum ResearchMode: String, CaseIterable, Codable, Identifiable, Sendable {
    case paperEvidence
    case myExperiment

    var id: Self { self }
}

enum ScientificDataStatus: String, Codable, Sendable {
    case paperSourceVerified
    case userProvidedUnvalidated
    case noExperimentalDataset
    case legacyUnspecified

    func title(_ language: AppLanguage) -> String {
        switch self {
        case .paperSourceVerified:
            language.text("公開一次資料と照合済み", "Verified against public primary sources")
        case .userProvidedUnvalidated:
            language.text("ユーザー提供・科学的妥当性未検証", "User-provided · scientific validity unverified")
        case .noExperimentalDataset:
            language.text("実験データ未読込", "No experiment dataset loaded")
        case .legacyUnspecified:
            language.text("旧履歴・モード未記録", "Legacy history · mode unspecified")
        }
    }
}

@MainActor
final class AppDatasetStore: ObservableObject {
    private let paperDataset: TrainingDataset
    private let paperDisplayName: String

    @Published private(set) var mode: ResearchMode
    @Published private(set) var personalDataset: TrainingDataset?
    @Published private(set) var personalDisplayName: String?
    @Published private(set) var personalImportedAt: Date?
    @Published private(set) var revision = 0
    /// Changes only when the active training dataset or mode changes.
    /// Comparison-only edits must not invalidate a completed Experiment run.
    @Published private(set) var trainingRevision = 0
    @Published private(set) var comparisonRevision = 0
    @Published private(set) var comparisonDataset: ComparableStudyDataset?

    var dataset: TrainingDataset {
        switch mode {
        case .paperEvidence: paperDataset
        case .myExperiment: personalDataset ?? TrainingDataSource.emptyCompatible
        }
    }

    var displayName: String {
        switch mode {
        case .paperEvidence: paperDisplayName
        case .myExperiment: personalDisplayName ?? "—"
        }
    }

    var isBundledData: Bool { mode == .paperEvidence }
    var hasPersonalDataset: Bool { personalDataset != nil }

    var scientificStatus: ScientificDataStatus {
        switch mode {
        case .paperEvidence: .paperSourceVerified
        case .myExperiment:
            personalDataset == nil ? .noExperimentalDataset : .userProvidedUnvalidated
        }
    }

    init(
        dataset: TrainingDataset = TrainingDataSource.bundled,
        displayName: String = "Yuan 2023 · Data S1",
        isBundledData: Bool = true
    ) {
        if isBundledData {
            paperDataset = dataset
            paperDisplayName = displayName
            mode = .paperEvidence
            personalDataset = nil
            personalDisplayName = nil
        } else {
            paperDataset = TrainingDataSource.bundled
            paperDisplayName = "Yuan 2023 · Data S1"
            mode = .myExperiment
            personalDataset = dataset
            personalDisplayName = displayName
        }
        personalImportedAt = nil
    }

    /// Backwards-compatible entry point. Replacement data always enter the
    /// unverified personal slot; the immutable paper slot is never overwritten.
    func replace(csvText: String, fileName: String) throws {
        try importPersonalDataset(csvText: csvText, fileName: fileName)
        selectMode(.myExperiment)
    }

    func importPersonalDataset(csvText: String, fileName: String, importedAt: Date = Date()) throws {
        let replacement = TrainingDataSource.parse(csvText)
        guard replacement.audit.isValid else {
            throw DatasetReplacementError.invalidDataset(replacement.audit.parseErrors)
        }
        guard !replacement.rows.isEmpty else {
            throw DatasetReplacementError.emptyDataset
        }

        personalDataset = replacement
        personalDisplayName = fileName
        personalImportedAt = importedAt
        if mode == .myExperiment {
            advanceActiveDatasetRevision()
        }
    }

    func restoreBundledData() {
        selectMode(.paperEvidence)
    }

    func selectMode(_ newMode: ResearchMode) {
        guard mode != newMode else { return }
        mode = newMode
        advanceActiveDatasetRevision()
    }

    func clearPersonalDataset() {
        guard personalDataset != nil || personalDisplayName != nil else { return }
        personalDataset = nil
        personalDisplayName = nil
        personalImportedAt = nil
        if mode == .myExperiment {
            advanceActiveDatasetRevision()
        }
    }

    private func advanceActiveDatasetRevision() {
        revision += 1
        trainingRevision += 1
    }

    func importComparison(csvText: String, fileName: String) throws {
        comparisonDataset = try ComparableStudyDataset.parse(name: fileName, csvText: csvText)
        comparisonRevision += 1
    }

    func useBundledDataAsComparison() {
        comparisonDataset = .yuan
        comparisonRevision += 1
    }

    func removeComparison() {
        comparisonDataset = nil
        comparisonRevision += 1
    }
}

enum DatasetReplacementError: LocalizedError {
    case emptyDataset
    case invalidDataset([DatasetParseError])

    var errorDescription: String? {
        message(.english)
    }

    func message(_ language: AppLanguage) -> String {
        switch self {
        case .emptyDataset:
            language.text(
                "差し替えCSVに有効なデータ行がありません。",
                "The replacement CSV contains no valid data rows."
            )
        case .invalidDataset(let errors):
            ([language.text(
                "差し替えCSVは検証に失敗しました。行・列番号と値を確認してください。",
                "The replacement CSV failed validation. Check the reported row, column, and value."
            )] + errors.prefix(4).map { error in
                if language == .english { return error.message }
                let location = [
                    error.row.map { "行\($0)" },
                    error.column.map { "列\($0)" },
                ].compactMap { $0 }.joined(separator: "・")
                let value = error.value.map { "（値: \($0)）" } ?? ""
                return "\(error.kind.japaneseName)\(location.isEmpty ? "" : " — \(location)")\(value)"
            })
                .joined(separator: "\n")
        }
    }
}

private extension DatasetParseError.Kind {
    var japaneseName: String {
        switch self {
        case .resource: "リソースを読み込めません"
        case .malformedCSV: "CSVの形式が不正です"
        case .schema: "11列のヘッダーがData S1スキーマと一致しません"
        case .columnCount: "列数が11ではありません"
        case .unknownDrug: "原著6種以外の薬物名です"
        case .invalidNumber: "数値として解釈できません"
        case .invalidSkinCode: "skinコードは1または2が必要です"
        case .invalidNeedleCode: "MN typeコードは1または2が必要です"
        }
    }
}
