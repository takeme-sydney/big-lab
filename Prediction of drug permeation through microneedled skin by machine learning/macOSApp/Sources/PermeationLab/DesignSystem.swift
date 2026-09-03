import SwiftUI

#if os(macOS)
import AppKit
#elseif os(iOS)
import UIKit
#endif

enum LabTheme {
    static let contentWidth: CGFloat = 1_080
    static let pagePadding: CGFloat = 24
    static let action = Color.accentColor

    static func canvas(_ colorScheme: ColorScheme) -> Color {
        #if os(macOS)
        Color(nsColor: .windowBackgroundColor)
        #elseif os(iOS)
        Color(uiColor: .systemBackground)
        #else
        colorScheme == .dark ? .black : .white
        #endif
    }

    static func surface(_ colorScheme: ColorScheme) -> Color {
        #if os(macOS)
        Color(nsColor: .controlBackgroundColor)
        #elseif os(iOS)
        Color(uiColor: .secondarySystemBackground)
        #else
        colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.04)
        #endif
    }

    static func tile(_ colorScheme: ColorScheme) -> Color {
        #if os(macOS)
        Color(nsColor: .textBackgroundColor)
        #elseif os(iOS)
        Color(uiColor: .tertiarySystemBackground)
        #else
        colorScheme == .dark ? Color.white.opacity(0.06) : Color.black.opacity(0.03)
        #endif
    }

    static func border(_ colorScheme: ColorScheme) -> Color {
        #if os(macOS)
        Color(nsColor: .separatorColor)
        #elseif os(iOS)
        Color(uiColor: .separator)
        #else
        colorScheme == .dark ? Color.white.opacity(0.12) : Color.black.opacity(0.12)
        #endif
    }
}

struct LabAppIcon: View {
    var size: CGFloat = 42

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.22, style: .continuous)
                .fill(LabTheme.action.opacity(0.10))
            Image(systemName: "syringe.fill")
                .font(.system(size: size * 0.44, weight: .semibold))
                .foregroundStyle(.tint)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

struct LabWorkspaceHeader: View {
    let title: String
    let subtitle: String
    let systemImage: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Image(systemName: systemImage)
                .font(.title2)
                .foregroundStyle(.tint)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.largeTitle.bold())
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                Text(subtitle)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .layoutPriority(1)
            Spacer(minLength: 16)
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("workspace.header")
    }
}

struct LabMetricCard: View {
    @Environment(\.colorScheme) private var colorScheme

    let title: String
    let value: String
    let detail: String
    let systemImage: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: systemImage)
                .font(.headline)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
            Text(value)
                .font(.system(size: 30, weight: .semibold, design: .rounded))
                .monospacedDigit()
            Text(detail)
                .font(.caption)
                .foregroundStyle(.tertiary)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            LabTheme.surface(colorScheme),
            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
        )
        .accessibilityElement(children: .combine)
    }
}

struct LabResponsiveActionHeader<Summary: View, Actions: View>: View {
    private let summary: Summary
    private let actions: Actions

    init(
        @ViewBuilder summary: () -> Summary,
        @ViewBuilder actions: () -> Actions
    ) {
        self.summary = summary()
        self.actions = actions()
    }

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .center, spacing: 16) {
                summary
                    .fixedSize(horizontal: true, vertical: false)
                Spacer(minLength: 16)
                actions
                    .fixedSize(horizontal: true, vertical: false)
            }

            VStack(alignment: .leading, spacing: 12) {
                summary
                    .fixedSize(horizontal: false, vertical: true)
                actions
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct LabSection<Content: View>: View {
    let title: String
    private let content: Content

    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        GroupBox(title) {
            content
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 4)
        }
    }
}

enum LabNoticeKind {
    case information
    case limitation
    case warning

    fileprivate var symbol: String {
        switch self {
        case .information: "info.circle.fill"
        case .limitation: "exclamationmark.triangle.fill"
        case .warning: "xmark.octagon.fill"
        }
    }

    fileprivate var color: Color {
        switch self {
        case .information: .accentColor
        case .limitation: .orange
        case .warning: .red
        }
    }
}

struct LabNotice: View {
    let title: String
    let message: String
    var kind: LabNoticeKind = .information

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: kind.symbol)
                .foregroundStyle(kind.color)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                Text(message)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(
            kind.color.opacity(0.08),
            in: RoundedRectangle(cornerRadius: 10, style: .continuous)
        )
        .accessibilityElement(children: .combine)
    }
}

private struct LabCardModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    let radius: CGFloat

    func body(content: Content) -> some View {
        content
            .background(
                LabTheme.surface(colorScheme),
                in: RoundedRectangle(cornerRadius: radius, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(LabTheme.border(colorScheme).opacity(0.7), lineWidth: 0.5)
            }
    }
}

extension View {
    func labCard(radius: CGFloat = 14) -> some View {
        modifier(LabCardModifier(radius: radius))
    }
}
