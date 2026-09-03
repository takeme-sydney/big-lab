import Foundation
import SwiftUI

enum ExperimentRunPhase: Equatable, Sendable {
    case idle
    case running
    case succeeded
    case failed(message: ExperimentMessage)
}

enum ExperimentStoreError: LocalizedError, Equatable, Sendable {
    case noResultToExport

    var errorDescription: String? {
        "No successful experiment result is available to export."
    }

    func message(_ language: AppLanguage) -> String {
        language.text(
            "エクスポートできる成功済み実行がありません。",
            "No successful experiment result is available to export."
        )
    }
}

/// Bounded, recoverable local persistence for complete successful run artifacts.
/// Corrupt data are discarded instead of blocking the Experiment workspace.
struct ExperimentHistoryPersistence {
    static let defaultKey = "permeationLab.experiment.recentRuns.v1"

    let userDefaults: UserDefaults
    let key: String
    let maximumRunCount: Int
    let maximumEncodedBytes: Int

    init(
        userDefaults: UserDefaults = .standard,
        key: String = Self.defaultKey,
        maximumRunCount: Int = 10,
        maximumEncodedBytes: Int = 4 * 1_024 * 1_024
    ) {
        self.userDefaults = userDefaults
        self.key = key
        self.maximumRunCount = max(1, maximumRunCount)
        self.maximumEncodedBytes = max(64 * 1_024, maximumEncodedBytes)
    }

    func scopedKey(for mode: ResearchMode) -> String {
        "\(key).\(mode.rawValue).v2"
    }

    var allKeys: [String] {
        [key] + ResearchMode.allCases.map(scopedKey(for:))
    }

    func load(for mode: ResearchMode) -> [ExperimentRunResult] {
        let destinationKey = scopedKey(for: mode)
        if let scopedData = userDefaults.data(forKey: destinationKey) {
            return decode(scopedData, keyToDiscardIfCorrupt: destinationKey)
                .filter { $0.dataset.resolvedResearchMode == mode }
        }

        // Read-only migration from the legacy shared key. Each mode receives only
        // its own runs; the legacy value is retained so this migration cannot erase
        // a user's history if an older build is opened later.
        guard let legacyData = userDefaults.data(forKey: key) else { return [] }
        let migrated = decode(legacyData, keyToDiscardIfCorrupt: nil)
            .filter { $0.dataset.resolvedResearchMode == mode }
        if !migrated.isEmpty {
            _ = save(migrated, for: mode)
        }
        return migrated
    }

    private func decode(
        _ data: Data,
        keyToDiscardIfCorrupt: String?
    ) -> [ExperimentRunResult] {
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return Array(
                try decoder.decode([ExperimentRunResult].self, from: data)
                    .sorted { $0.completedAt > $1.completedAt }
                    .prefix(maximumRunCount)
            )
        } catch {
            if let keyToDiscardIfCorrupt {
                userDefaults.removeObject(forKey: keyToDiscardIfCorrupt)
            }
            return []
        }
    }

    /// Returns the runs that actually fit within both configured bounds.
    @discardableResult
    func save(
        _ runs: [ExperimentRunResult],
        for mode: ResearchMode
    ) -> [ExperimentRunResult] {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        encoder.dateEncodingStrategy = .iso8601

        var seen = Set<UUID>()
        let candidates = runs
            .filter { $0.dataset.resolvedResearchMode == mode }
            .sorted { $0.completedAt > $1.completedAt }
            .filter { seen.insert($0.id).inserted }
            .prefix(maximumRunCount)
        var retained: [ExperimentRunResult] = []
        for candidate in candidates {
            let proposed = retained + [candidate]
            guard let data = try? encoder.encode(proposed), data.count <= maximumEncodedBytes else {
                break
            }
            retained = proposed
        }

        let destinationKey = scopedKey(for: mode)
        if retained.isEmpty {
            userDefaults.removeObject(forKey: destinationKey)
        } else if let data = try? encoder.encode(retained) {
            userDefaults.set(data, forKey: destinationKey)
        }
        return retained
    }

    func clear(for mode: ResearchMode) {
        userDefaults.removeObject(forKey: scopedKey(for: mode))
    }
}

@MainActor
final class ExperimentStore: ObservableObject {
    @Published var configuration: ExperimentConfiguration
    @Published private(set) var phase: ExperimentRunPhase = .idle
    @Published private(set) var datasetSnapshot: ExperimentDatasetSnapshot
    @Published private(set) var currentResult: ExperimentRunResult?
    @Published private(set) var recentRuns: [ExperimentRunResult]

    private var dataset: TrainingDataset
    private var displayName: String
    private var isBundledData: Bool
    private var researchMode: ResearchMode
    private var scientificStatus: ScientificDataStatus
    private var importedAt: Date?
    private var datasetRevision: Int
    private var runningToken: UUID?
    private var runningTask: Task<ExperimentRunResult, Error>?
    private let persistence: ExperimentHistoryPersistence

    init(
        dataset: TrainingDataset = TrainingDataSource.bundled,
        displayName: String = "Yuan 2023 · Data S1",
        isBundledData: Bool = true,
        researchMode: ResearchMode = .paperEvidence,
        scientificStatus: ScientificDataStatus = .paperSourceVerified,
        importedAt: Date? = nil,
        revision: Int = 0,
        configuration: ExperimentConfiguration = ExperimentConfiguration(),
        persistence: ExperimentHistoryPersistence = ExperimentHistoryPersistence()
    ) {
        self.dataset = dataset
        self.displayName = displayName
        self.isBundledData = isBundledData
        self.researchMode = researchMode
        self.scientificStatus = scientificStatus
        self.importedAt = importedAt
        datasetRevision = revision
        self.configuration = configuration
        self.persistence = persistence
        datasetSnapshot = ExperimentDatasetSnapshot.make(
            dataset: dataset,
            displayName: displayName,
            isBundledData: isBundledData,
            researchMode: researchMode,
            scientificStatus: scientificStatus,
            importedAt: importedAt
        )
        recentRuns = persistence.load(for: researchMode)
    }

    var isRunning: Bool {
        if case .running = phase { return true }
        return false
    }

    var canRun: Bool {
        guard !isRunning,
              datasetSnapshot.schemaIsValid,
              datasetSnapshot.auditErrorCount == 0,
              !dataset.rows.isEmpty else { return false }
        if configuration.validationStrategy == .leaveOneDrugOut {
            guard let drug = configuration.heldOutDrug else { return false }
            let testCount = dataset.rows.count { $0.drug == drug }
            let trainingCount = dataset.rows.count - testCount
            return testCount > 0 && trainingCount >= ExperimentPredictor.allCases.count
        }
        let trainingCount = Int((Double(dataset.rows.count) * 0.70).rounded())
        return trainingCount >= ExperimentPredictor.allCases.count
            && trainingCount < dataset.rows.count
    }

    /// Call from the view's dataset revision observer. A changed dataset makes any
    /// visible result stale immediately; an in-flight stale result is ignored.
    func updateDataset(
        _ dataset: TrainingDataset,
        displayName: String,
        isBundledData: Bool,
        revision: Int,
        researchMode: ResearchMode? = nil,
        scientificStatus: ScientificDataStatus? = nil,
        importedAt: Date? = nil
    ) {
        let resolvedMode = researchMode ?? (isBundledData ? .paperEvidence : .myExperiment)
        let resolvedStatus = scientificStatus ?? (
            isBundledData ? .paperSourceVerified : .userProvidedUnvalidated
        )
        let newSnapshot = ExperimentDatasetSnapshot.make(
            dataset: dataset,
            displayName: displayName,
            isBundledData: isBundledData,
            researchMode: resolvedMode,
            scientificStatus: resolvedStatus,
            importedAt: importedAt
        )
        let changed = revision != datasetRevision || newSnapshot != datasetSnapshot
        self.dataset = dataset
        self.displayName = displayName
        self.isBundledData = isBundledData
        self.researchMode = resolvedMode
        self.scientificStatus = resolvedStatus
        self.importedAt = importedAt
        datasetRevision = revision
        datasetSnapshot = newSnapshot
        guard changed else { return }
        runningTask?.cancel()
        runningTask = nil
        runningToken = nil
        currentResult = nil
        phase = .idle
        recentRuns = persistence.load(for: resolvedMode)
        if resolvedMode == .paperEvidence {
            configuration.validationStrategy = .publishedStyleRowSplit
            configuration.seed = 0
            configuration.heldOutDrug = nil
        }
        if configuration.validationStrategy == .leaveOneDrugOut,
           configuration.heldOutDrug.map({ heldOut in
               !dataset.rows.contains { $0.drug == heldOut }
           }) ?? true {
            configuration.heldOutDrug = Drug.allCases.first { candidate in
                dataset.rows.contains { $0.drug == candidate }
            }
        }
    }

    /// Runs away from the main actor through `ExperimentRunner`, then publishes a
    /// result only if the active dataset has not changed while computation ran.
    func run() async {
        guard canRun else {
            let error: ExperimentRunError
            if dataset.rows.isEmpty {
                error = .emptyDataset
            } else if !dataset.audit.isValid {
                error = .invalidDataset(errorCount: dataset.audit.parseErrors.count)
            } else if configuration.validationStrategy == .leaveOneDrugOut,
                      configuration.heldOutDrug == nil {
                error = .missingHeldOutDrug
            } else {
                error = .emptyTestPartition
            }
            phase = .failed(message: failureMessage(for: error))
            return
        }

        let token = UUID()
        runningToken = token
        phase = .running
        let capturedDataset = dataset
        let capturedDisplayName = displayName
        let capturedBundledState = isBundledData
        let capturedResearchMode = researchMode
        let capturedScientificStatus = scientificStatus
        let capturedImportedAt = importedAt
        let capturedConfiguration = configuration
        let capturedRevision = datasetRevision

        let worker = Task {
            try await ExperimentRunner.run(
                dataset: capturedDataset,
                displayName: capturedDisplayName,
                isBundledData: capturedBundledState,
                researchMode: capturedResearchMode,
                scientificStatus: capturedScientificStatus,
                importedAt: capturedImportedAt,
                configuration: capturedConfiguration
            )
        }
        runningTask = worker

        do {
            let result = try await worker.value
            guard runningToken == token, datasetRevision == capturedRevision else { return }
            currentResult = result
            phase = .succeeded
            runningToken = nil
            runningTask = nil
            recentRuns = persistence.save([result] + recentRuns, for: capturedResearchMode)
        } catch is CancellationError {
            guard runningToken == token else { return }
            runningToken = nil
            runningTask = nil
            phase = .idle
        } catch {
            guard runningToken == token, datasetRevision == capturedRevision else { return }
            runningToken = nil
            runningTask = nil
            // `currentResult` is deliberately preserved on failure.
            if let experimentError = error as? ExperimentRunError {
                phase = .failed(message: failureMessage(for: experimentError))
            } else {
                phase = .failed(message: ExperimentMessage(
                    code: "unexpected_run_error",
                    japanese: "予期しないエラーでrunを完了できませんでした。\(error.localizedDescription)",
                    english: "The run could not finish because of an unexpected error. \(error.localizedDescription)"
                ))
            }
        }
    }

    @discardableResult
    func restore(_ result: ExperimentRunResult) -> Bool {
        guard result.dataset.resolvedResearchMode == researchMode else {
            return false
        }
        cancel()
        currentResult = result
        configuration = result.configuration
        phase = .succeeded
        return true
    }

    func cancel() {
        let wasRunning = isRunning
        runningTask?.cancel()
        runningTask = nil
        runningToken = nil
        if wasRunning {
            phase = .idle
        }
    }

    func exportData(for result: ExperimentRunResult? = nil) throws -> Data {
        guard let result = result ?? currentResult else {
            throw ExperimentStoreError.noResultToExport
        }
        return try ExperimentExportEncoder.data(for: result)
    }

    func suggestedExportFileName(for result: ExperimentRunResult? = nil) -> String? {
        guard let result = result ?? currentResult else { return nil }
        return "permeation-experiment-\(result.configuration.outcome.rawValue)-\(result.id.uuidString.lowercased()).json"
    }

    func clearHistory() {
        persistence.clear(for: researchMode)
        recentRuns = []
    }

    private func failureMessage(for error: ExperimentRunError) -> ExperimentMessage {
        ExperimentMessage(
            code: "experiment_run_error",
            japanese: error.message(.japanese),
            english: error.message(.english)
        )
    }
}
