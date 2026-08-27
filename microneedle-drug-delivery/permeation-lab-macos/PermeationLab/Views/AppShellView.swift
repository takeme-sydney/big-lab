import SwiftUI

struct AppShellView: View {
    let repository: StudyRepository
    @State private var selection: AppSection? = .overview

    var body: some View {
        NavigationSplitView {
            List(AppSection.allCases, selection: $selection) { section in
                NavigationLink(value: section) {
                    Label(section.rawValue, systemImage: section.symbol)
                        .accessibilityIdentifier("navigation-\(section.id)")
                }
            }
            .navigationTitle("Permeation Lab")
            .navigationSplitViewColumnWidth(min: 190, ideal: 220, max: 270)
            .safeAreaInset(edge: .bottom) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Yuan et al. (2023)")
                        .font(.caption.weight(.semibold))
                    Text("PMID 38023708 · オフライン")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
            }
        } detail: {
            Group {
                switch selection ?? .overview {
                case .overview:
                    OverviewView(repository: repository)
                case .methods:
                    MethodsView()
                case .dataset:
                    DatasetExplorerView(repository: repository)
                case .skinPermeation:
                    SkinPermeationView(repository: repository)
                case .results:
                    ResultsView()
                case .figures:
                    FiguresView()
                case .paper:
                    PaperReaderView()
                case .integrity:
                    IntegrityView(repository: repository)
                }
            }
            .background(Color(nsColor: .windowBackgroundColor))
            .navigationTitle(selection?.rawValue ?? "研究概要")
        }
        .accessibilityIdentifier("app-shell")
    }
}
