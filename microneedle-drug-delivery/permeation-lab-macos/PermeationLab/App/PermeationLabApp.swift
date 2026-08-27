import SwiftUI

@main
struct PermeationLabApp: App {
    private let repository = StudyRepository()

    var body: some Scene {
        WindowGroup {
            AppShellView(repository: repository)
                .frame(minWidth: 1_040, minHeight: 700)
        }
        .defaultSize(width: 1_320, height: 860)
        .windowToolbarStyle(.unified)
    }
}
