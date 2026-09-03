import Foundation

enum AppLanguage: String, CaseIterable, Identifiable, Sendable {
    case english = "en"
    case japanese = "ja"

    static let defaultLanguage: Self = .english

    var id: Self { self }

    var locale: Locale {
        Locale(identifier: rawValue)
    }

    func displayName(in interfaceLanguage: AppLanguage) -> String {
        switch self {
        case .english:
            interfaceLanguage.text("英語", "English")
        case .japanese:
            interfaceLanguage.text("日本語", "Japanese")
        }
    }

    func text(_ japanese: String, _ english: String) -> String {
        switch self {
        case .english: english
        case .japanese: japanese
        }
    }
}

struct BiText: Hashable, Sendable {
    let japanese: String
    let english: String

    init(_ japanese: String, _ english: String) {
        self.japanese = japanese
        self.english = english
    }

    func resolve(_ language: AppLanguage) -> String {
        language.text(japanese, english)
    }
}
