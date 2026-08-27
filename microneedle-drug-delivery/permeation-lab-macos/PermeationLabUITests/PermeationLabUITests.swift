import XCTest

@MainActor
final class PermeationLabUITests: XCTestCase {
    private func launchApp() -> XCUIApplication {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments += ["-ApplePersistenceIgnoreState", "YES"]
        app.launch()
        return app
    }

    func testAppLaunchesIntoTheStudyOverview() {
        let app = launchApp()
        defer { app.terminate() }

        XCTAssertTrue(app.windows.firstMatch.waitForExistence(timeout: 10))
        XCTAssertTrue(element(in: app, identifier: "app-shell").waitForExistence(timeout: 5))
        XCTAssertTrue(element(in: app, identifier: "overview-screen").waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Permeation Lab"].firstMatch.exists)
    }

    func testEveryStudySectionCanBeOpenedFromTheSidebar() {
        let app = launchApp()
        defer { app.terminate() }

        let destinations = [
            (navigation: "overview", screen: "overview-screen"),
            (navigation: "methods", screen: "methods-screen"),
            (navigation: "dataset", screen: "dataset-screen"),
            (navigation: "skinPermeation", screen: "skin-permeation-screen"),
            (navigation: "results", screen: "results-screen"),
            (navigation: "figures", screen: "figures-screen"),
            (navigation: "paper", screen: "paper-screen"),
            (navigation: "integrity", screen: "integrity-screen")
        ]

        for destination in destinations {
            let navigationItem = element(in: app, identifier: "navigation-\(destination.navigation)")
            XCTAssertTrue(
                navigationItem.waitForExistence(timeout: 5),
                "Missing sidebar item navigation-\(destination.navigation)"
            )
            navigationItem.click()
            XCTAssertTrue(
                element(in: app, identifier: destination.screen).waitForExistence(timeout: 5),
                "Navigation did not reveal \(destination.screen)"
            )
            XCTAssertTrue(app.windows.firstMatch.exists)
        }
    }

    func testSkinPermeationScreenKeepsObservedDataAndConceptualMechanismDistinct() {
        let app = launchApp()
        defer { app.terminate() }

        let navigationItem = element(in: app, identifier: "navigation-skinPermeation")
        XCTAssertTrue(navigationItem.waitForExistence(timeout: 5))
        navigationItem.click()

        XCTAssertTrue(element(in: app, identifier: "skin-permeation-screen").waitForExistence(timeout: 5))
        XCTAssertTrue(element(in: app, identifier: "permeation-truth-boundary").waitForExistence(timeout: 5))
        XCTAssertTrue(element(in: app, identifier: "permeation-skin-illustration").waitForExistence(timeout: 5))
        XCTAssertTrue(element(in: app, identifier: "permeation-illustration-observation").waitForExistence(timeout: 5))
        XCTAssertTrue(element(in: app, identifier: "permeation-observed-chart").waitForExistence(timeout: 5))
        XCTAssertTrue(element(in: app, identifier: "permeation-observation-detail").waitForExistence(timeout: 5))
        XCTAssertTrue(element(in: app, identifier: "permeation-science-boundary").waitForExistence(timeout: 5))
        XCTAssertTrue(element(in: app, identifier: "permeation-play").waitForExistence(timeout: 5))
        XCTAssertTrue(element(in: app, identifier: "permeation-step").waitForExistence(timeout: 5))
        XCTAssertTrue(element(in: app, identifier: "permeation-reset-motion").waitForExistence(timeout: 5))
    }

    private func element(in app: XCUIApplication, identifier: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: identifier).firstMatch
    }
}
