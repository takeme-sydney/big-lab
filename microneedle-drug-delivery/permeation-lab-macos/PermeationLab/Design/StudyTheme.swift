import SwiftUI

enum StudyTheme {
    static let accent = Color(red: 0.07, green: 0.47, blue: 0.50)
    static let secondaryAccent = Color(red: 0.22, green: 0.37, blue: 0.72)
    static let warning = Color(red: 0.82, green: 0.42, blue: 0.08)
    static let contentWidth: CGFloat = 1_180

    static func modelColor(_ model: PaperModel) -> Color {
        switch model {
        case .xgboost: Color(red: 0.39, green: 0.24, blue: 0.73)
        case .randomForest: Color(red: 0.05, green: 0.53, blue: 0.52)
        case .fick: Color(red: 0.12, green: 0.42, blue: 0.78)
        case .mlr: Color(red: 0.86, green: 0.42, blue: 0.12)
        }
    }
}

private struct StudyCardModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    let padding: CGFloat

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(colorScheme == .dark ? Color.white.opacity(0.055) : Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(colorScheme == .dark ? Color.white.opacity(0.11) : Color.black.opacity(0.09))
            )
            .shadow(color: colorScheme == .dark ? .clear : .black.opacity(0.035), radius: 10, y: 3)
    }
}

extension View {
    func studyCard(padding: CGFloat = 20) -> some View {
        modifier(StudyCardModifier(padding: padding))
    }
}
