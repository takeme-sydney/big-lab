import SwiftUI
#if os(macOS)
import AppKit
import Darwin
#endif

@main
struct PermeationLabApp: App {
    private let usesUITesting: Bool
    private let usesCompactUITestWindow: Bool

    init() {
        let arguments = ProcessInfo.processInfo.arguments
        usesUITesting = arguments.contains("-ui-testing")
        usesCompactUITestWindow = arguments.contains("-ui-testing-compact-window")

        if LocalMLSelfTestCommand.isRequested(arguments: arguments) {
            do {
                let summary = try LocalMLSelfTestCommand.execute()
                FileHandle.standardOutput.write(try summary.jsonLineData())
                exit(EXIT_SUCCESS)
            } catch {
                FileHandle.standardError.write(LocalMLSelfTestCommand.failureJSONLine(for: error))
                exit(EXIT_FAILURE)
            }
        }

        if FickReproductionCommand.isRequested(arguments: arguments) {
            do {
                try FickReproductionCommand.execute(arguments: arguments)
                exit(EXIT_SUCCESS)
            } catch {
                let message = "Fick headless reproduction failed: \(error.localizedDescription)\n"
                FileHandle.standardError.write(Data(message.utf8))
                exit(EXIT_FAILURE)
            }
        }

        if usesUITesting {
            UserDefaults.standard.set(AppLanguage.defaultLanguage.rawValue, forKey: "appLanguage")
            for key in ExperimentHistoryPersistence().allKeys {
                UserDefaults.standard.removeObject(forKey: key)
            }
            UserDefaults.standard.removeObject(forKey: FickValidationHistoryPersistence.defaultKey)
            ModelWorkspaceStore.clearPersistedModel()
        }
    }

    var body: some Scene {
        WindowGroup("Permeation Lab") {
            ContentView()
#if os(macOS)
                .frame(minWidth: 1_050, minHeight: 700)
                .background(
                    UITestWindowSizeConfigurator(
                        requestedSize: usesUITesting
                            ? NSSize(
                                width: usesCompactUITestWindow ? 1_050 : 1_320,
                                height: usesCompactUITestWindow ? 700 : 860
                            )
                            : nil
                    )
                )
#endif
        }
#if os(macOS)
        .defaultSize(
            width: usesCompactUITestWindow ? 1_050 : 1_320,
            height: usesCompactUITestWindow ? 700 : 860
        )
        .commands {
            SidebarCommands()
        }
#endif
    }
}

#if os(macOS)
/// `.defaultSize` is only a first-launch preference and macOS window restoration can
/// override it. E2E launches use a stable viewport so responsive layouts are exercised
/// deterministically without changing normal launches.
private struct UITestWindowSizeConfigurator: NSViewRepresentable {
    let requestedSize: NSSize?

    func makeNSView(context: Context) -> NSView {
        let view = NSView(frame: .zero)
        applySize(through: view)
        return view
    }

    func updateNSView(_ view: NSView, context: Context) {
        applySize(through: view)
    }

    private func applySize(through view: NSView) {
        guard let requestedSize else { return }
        DispatchQueue.main.async {
            guard let window = view.window else { return }
            let current = window.contentLayoutRect.size
            if abs(current.width - requestedSize.width) > 1
                    || abs(current.height - requestedSize.height) > 1 {
                window.setContentSize(requestedSize)
            }

            // XCUITest hit testing is unreliable when a restored macOS window is
            // placed on a secondary display. Keep only the test window centered on
            // the primary display; normal application launches never enter here.
            let primaryScreen = NSScreen.screens.first(where: { $0.frame.contains(.zero) })
                ?? NSScreen.main
                ?? window.screen
            if let visibleFrame = primaryScreen?.visibleFrame {
                let windowSize = window.frame.size
                let origin = NSPoint(
                    x: visibleFrame.midX - windowSize.width / 2,
                    y: visibleFrame.midY - windowSize.height / 2
                )
                if abs(window.frame.origin.x - origin.x) > 1
                        || abs(window.frame.origin.y - origin.y) > 1 {
                    window.setFrameOrigin(origin)
                }
            }
            window.makeKeyAndOrderFront(nil)
            NSApplication.shared.activate(ignoringOtherApps: true)
        }
    }
}
#endif
