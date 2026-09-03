import Foundation

enum FickReproductionCommandError: LocalizedError, Equatable {
    case missingArgument(String)
    case pathMustBeAbsolute(String)
    case inputDoesNotExist(String)
    case outputAlreadyExists(String)
    case invalidDataset(errorCount: Int)

    var errorDescription: String? {
        switch self {
        case .missingArgument(let flag):
            "Missing value after \(flag)."
        case .pathMustBeAbsolute(let flag):
            "The value after \(flag) must be an absolute path."
        case .inputDoesNotExist(let path):
            "The input CSV does not exist: \(path)"
        case .outputAlreadyExists(let path):
            "The headless reproduction will not overwrite an existing file: \(path)"
        case .invalidDataset(let errorCount):
            "The explicit reproduction CSV failed schema validation with \(errorCount) error(s)."
        }
    }
}

/// Direct, non-UI reproduction entry point for manuscript supplementary use.
/// It does not instantiate `ContentView`, read/write UserDefaults, or depend on
/// SwiftUI visibility. The same tested scientific engine used by the UI is called.
enum FickReproductionCommand {
    static let inputFlag = "-fick-85-headless-input"
    static let outputFlag = "-fick-85-headless-output"

    static func isRequested(arguments: [String]) -> Bool {
        arguments.contains(inputFlag) || arguments.contains(outputFlag)
    }

    @discardableResult
    static func execute(arguments: [String]) throws -> FickValidationRunResult {
        let inputPath = try absolutePath(after: inputFlag, arguments: arguments)
        let outputPath = try absolutePath(after: outputFlag, arguments: arguments)
        guard FileManager.default.fileExists(atPath: inputPath) else {
            throw FickReproductionCommandError.inputDoesNotExist(inputPath)
        }
        guard !FileManager.default.fileExists(atPath: outputPath) else {
            throw FickReproductionCommandError.outputAlreadyExists(outputPath)
        }

        let inputURL = URL(fileURLWithPath: inputPath)
        let csvText = try String(contentsOf: inputURL, encoding: .utf8)
        let dataset = TrainingDataSource.parse(csvText)
        guard dataset.audit.isValid, !dataset.rows.isEmpty else {
            throw FickReproductionCommandError.invalidDataset(
                errorCount: dataset.audit.parseErrors.count
            )
        }

        let result = try FickValidationExperiment.run(
            dataset: dataset,
            displayName: inputURL.lastPathComponent,
            isBundledData: false,
            researchMode: .myExperiment,
            scientificStatus: .userProvidedUnvalidated,
            configuration: .default
        )
        try FickValidationExportEncoder.data(for: result)
            .write(to: URL(fileURLWithPath: outputPath), options: .atomic)
        return result
    }

    private static func absolutePath(after flag: String, arguments: [String]) throws -> String {
        guard let index = arguments.firstIndex(of: flag),
              arguments.indices.contains(index + 1) else {
            throw FickReproductionCommandError.missingArgument(flag)
        }
        let path = arguments[index + 1]
        guard (path as NSString).isAbsolutePath else {
            throw FickReproductionCommandError.pathMustBeAbsolute(flag)
        }
        return path
    }
}
