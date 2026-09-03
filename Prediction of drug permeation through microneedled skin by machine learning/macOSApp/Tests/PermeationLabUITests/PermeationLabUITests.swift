import XCTest

final class PermeationLabUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        launchApp(arguments: ["-ui-testing"])
    }

    private func launchApp(arguments: [String]) {
        if app.state != .notRunning {
            app.terminate()
            XCTAssertTrue(
                app.wait(for: .notRunning, timeout: 10),
                "Permeation Lab did not finish terminating before relaunch"
            )
        }

        // A fresh proxy avoids carrying stale process state across the custom
        // argument relaunches exercised by the compact and Fick entry tests.
        app = XCUIApplication()
        app.launchArguments = arguments
        app.launch()
        XCTAssertTrue(
            app.wait(for: .runningForeground, timeout: 10),
            "Permeation Lab did not reach the foreground after launch"
        )
        ensureWindow()
    }

    private func ensureWindow() {
        if app.windows.firstMatch.waitForExistence(timeout: 5) {
            app.activate()
            return
        }

        for _ in 0..<2 {
            app.activate()
            guard app.wait(for: .runningForeground, timeout: 5) else { continue }

            // Use the app's AX menu instead of a focus-dependent global shortcut
            // whenever it is available. The keyboard fallback covers the brief
            // interval before the macOS menu hierarchy is published.
            let fileMenu = app.menuBars.menuBarItems["File"]
            if fileMenu.waitForExistence(timeout: 2) {
                fileMenu.click()
                let newWindow = app.menuItems["New Permeation Lab Window"]
                if newWindow.waitForExistence(timeout: 2) {
                    newWindow.click()
                } else {
                    app.typeKey(XCUIKeyboardKey.escape.rawValue, modifierFlags: [])
                    app.typeKey("n", modifierFlags: .command)
                }
            } else {
                app.typeKey("n", modifierFlags: .command)
            }

            if app.windows.firstMatch.waitForExistence(timeout: 8) {
                app.activate()
                return
            }
        }

        XCTFail("Permeation Lab did not create a window after launch or two New Window requests")
    }

    private func waitUntilHittable(_ element: XCUIElement, timeout: TimeInterval = 5) -> Bool {
        let predicate = NSPredicate(format: "exists == true AND hittable == true")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        return XCTWaiter.wait(for: [expectation], timeout: timeout) == .completed
    }

    private func scrollUntilHittable(
        _ element: XCUIElement,
        in scrollView: XCUIElement,
        maximumScrolls: Int = 12
    ) -> Bool {
        for _ in 0..<maximumScrolls {
            if element.exists, element.isHittable { return true }
            scrollView.scroll(byDeltaX: 0, deltaY: -520)
        }
        return element.exists && element.isHittable
    }

    func testPrimaryWorkspaceNavigation() {
        let destinations: [(navigation: String, screen: String)] = [
            ("nav.study-overview", "screen.study-overview"),
            ("nav.literature-library", "screen.literature-library"),
            ("nav.paper-reader", "screen.paper-reader"),
            ("nav.methods", "screen.methods"),
            ("nav.model-evidence", "screen.model-evidence"),
            ("nav.paper-figures", "screen.paper-figures"),
            ("nav.data-source", "screen.data-source"),
            ("nav.integrity", "screen.integrity")
        ]

        for destination in destinations {
            let navigationItem = app.descendants(matching: .any)[destination.navigation]
            XCTAssertTrue(
                navigationItem.waitForExistence(timeout: 5),
                "Missing navigation item: \(destination.navigation)"
            )
            navigationItem.click()

            XCTAssertTrue(
                app.descendants(matching: .any)[destination.screen].waitForExistence(timeout: 5),
                "Destination did not appear: \(destination.screen)"
            )
        }

        for forbiddenNavigation in [
            "nav.research-home",
            "nav.fick-85-assessment",
            "nav.dataset-impact",
            "nav.experiment",
            "nav.model-selection",
            "nav.model-profiles",
            "nav.skin-permeation",
        ] {
            XCTAssertFalse(
                app.descendants(matching: .any)[forbiddenNavigation].exists,
                "Facts exposed a research-only destination: \(forbiddenNavigation)"
            )
        }
    }

    func testMyResearchWorkspaceNavigationExcludesPaperOnlyDestinations() {
        let myResearch = app.buttons.matching(identifier: "mode.myExperiment").firstMatch
        XCTAssertTrue(myResearch.waitForExistence(timeout: 5))
        XCTAssertTrue(waitUntilHittable(myResearch))
        myResearch.click()

        let destinations: [(navigation: String, screen: String)] = [
            ("nav.research-home", "screen.research-home"),
            ("nav.fick-85-assessment", "screen.fick-85-assessment"),
            ("nav.dataset-impact", "screen.dataset-impact"),
            ("nav.experiment", "screen.experiment"),
            ("nav.model-selection", "screen.model-selection"),
            ("nav.model-profiles", "screen.model-profiles"),
            ("nav.skin-permeation", "screen.skin-permeation"),
            ("nav.data-source", "screen.data-source"),
            ("nav.integrity", "screen.integrity"),
        ]

        for destination in destinations {
            let navigationItem = app.descendants(matching: .any)[destination.navigation]
            XCTAssertTrue(
                navigationItem.waitForExistence(timeout: 5),
                "Missing My Research destination: \(destination.navigation)"
            )
            navigationItem.click()
            XCTAssertTrue(
                app.descendants(matching: .any)[destination.screen].waitForExistence(timeout: 5),
                "My Research destination did not appear: \(destination.screen)"
            )

            if destination.screen == "screen.research-home" {
                let researchScrollView = app.scrollViews.matching(
                    identifier: "screen.research-home"
                ).firstMatch
                XCTAssertTrue(researchScrollView.exists)
                let reasonSummary = app.descendants(matching: .any)[
                    "research-home.reason-summary"
                ]
                XCTAssertTrue(
                    scrollUntilHittable(reasonSummary, in: researchScrollView),
                    "The My Research page must explain why 0.895 is not a confirmed result."
                )

                let pooledReason = app.descendants(matching: .any)[
                    "research-home.reason.pooled-variance"
                ]
                XCTAssertTrue(scrollUntilHittable(pooledReason, in: researchScrollView))
                let pooledSpokenText = pooledReason.label
                    + " " + String(describing: pooledReason.value ?? "")
                for token in ["74.25%", "0.895142", "0.861608", "0.592792", "0.338346"] {
                    XCTAssertTrue(pooledSpokenText.contains(token), pooledSpokenText)
                }

                let modelReason = app.descendants(matching: .any)[
                    "research-home.reason.model-identity"
                ]
                XCTAssertTrue(scrollUntilHittable(modelReason, in: researchScrollView))
                let modelSpokenText = modelReason.label
                    + " " + String(describing: modelReason.value ?? "")
                XCTAssertTrue(modelSpokenText.contains("time-only finite-slab proxy"))
                XCTAssertTrue(modelSpokenText.contains("2D solver"))
            }
        }

        for forbiddenNavigation in [
            "nav.study-overview",
            "nav.literature-library",
            "nav.paper-reader",
            "nav.methods",
            "nav.model-evidence",
            "nav.paper-figures",
        ] {
            XCTAssertFalse(
                app.descendants(matching: .any)[forbiddenNavigation].exists,
                "My Research exposed a paper-only destination: \(forbiddenNavigation)"
            )
        }
    }

    func testResearchModeSwitchSeparatesPaperAndPersonalData() {
        let selector = app.descendants(matching: .any)["mode.selector"]
        XCTAssertTrue(selector.waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons.matching(identifier: "toolbar.reported-metrics").firstMatch.exists)

        let myExperiment = app.buttons.matching(identifier: "mode.myExperiment").firstMatch
        XCTAssertTrue(myExperiment.waitForExistence(timeout: 5), app.debugDescription)
        XCTAssertEqual(myExperiment.label, "My Research")
        XCTAssertEqual(String(describing: myExperiment.value ?? ""), "Not selected")
        XCTAssertTrue(waitUntilHittable(myExperiment))
        myExperiment.click()

        XCTAssertTrue(
            app.descendants(matching: .any)["screen.research-home"].waitForExistence(timeout: 5)
        )
        XCTAssertTrue(app.descendants(matching: .any)["mode.context"].exists)
        XCTAssertTrue(
            app.buttons.matching(identifier: "mode.import-experiment-data").firstMatch.exists
        )
        XCTAssertTrue(app.descendants(matching: .any)["nav.fick-85-assessment"].exists)
        XCTAssertTrue(app.descendants(matching: .any)["nav.experiment"].exists)
        XCTAssertTrue(app.descendants(matching: .any)["nav.model-selection"].exists)
        XCTAssertTrue(app.descendants(matching: .any)["nav.dataset-impact"].exists)
        XCTAssertTrue(app.descendants(matching: .any)["nav.model-profiles"].exists)
        XCTAssertFalse(app.descendants(matching: .any)["nav.paper-reader"].exists)
        XCTAssertFalse(app.buttons.matching(identifier: "toolbar.reported-metrics").firstMatch.exists)

        let observedData = app.descendants(matching: .any)["nav.data-source"]
        XCTAssertTrue(observedData.waitForExistence(timeout: 5))
        observedData.click()
        XCTAssertTrue(app.descendants(matching: .any)["data.empty-personal"].waitForExistence(timeout: 5))

        let paperEvidence = app.buttons.matching(identifier: "mode.paperEvidence").firstMatch
        XCTAssertTrue(paperEvidence.waitForExistence(timeout: 5))
        XCTAssertTrue(waitUntilHittable(paperEvidence))
        paperEvidence.click()

        XCTAssertTrue(app.descendants(matching: .any)["nav.paper-reader"].waitForExistence(timeout: 5))
        XCTAssertTrue(
            app.buttons.matching(identifier: "toolbar.reported-metrics").firstMatch.waitForExistence(timeout: 5)
        )
        for researchOnlyNavigation in [
            "nav.fick-85-assessment",
            "nav.experiment",
            "nav.model-selection",
            "nav.dataset-impact",
            "nav.model-profiles",
        ] {
            XCTAssertFalse(app.descendants(matching: .any)[researchOnlyNavigation].exists)
        }
    }

    func testReportedMetricsSheetCanOpenAndClose() {
        let button = app.buttons.matching(identifier: "toolbar.reported-metrics").firstMatch
        XCTAssertTrue(button.waitForExistence(timeout: 5))
        button.click()

        let sheet = app.descendants(matching: .any)["sheet.reported-metrics"]
        XCTAssertTrue(sheet.waitForExistence(timeout: 5))

        let closeButton = app.buttons.matching(identifier: "reported-metrics.close").firstMatch
        XCTAssertTrue(closeButton.waitForExistence(timeout: 5))
        if closeButton.isHittable {
            closeButton.click()
        } else {
            // SwiftUI macOS sheets can briefly expose toolbar-adjacent controls
            // as existing but non-hittable. The button declares cancelAction, so
            // Escape exercises the same user-facing dismissal path.
            app.typeKey(XCUIKeyboardKey.escape.rawValue, modifierFlags: [])
        }
        XCTAssertFalse(sheet.waitForExistence(timeout: 2))
    }

    func testExperimentWorkspaceExposesReproducibilityControls() {
        launchApp(arguments: ["-ui-testing", "-fick-85-my-experiment"])

        let destination = app.descendants(matching: .any)["nav.experiment"]
        XCTAssertTrue(destination.waitForExistence(timeout: 5))
        destination.click()

        for identifier in [
            "screen.experiment",
            "experiment.dataset",
            "experiment.protocol",
            "experiment.outcome",
            "experiment.validation",
            "experiment.seed",
            "experiment.run",
            "experiment.history",
            "experiment.fick.run",
        ] {
            XCTAssertTrue(
                app.descendants(matching: .any)[identifier].waitForExistence(timeout: 5),
                "Missing Experiment control: \(identifier)"
            )
        }
    }

    func testExperimentCanRunEndToEnd() {
        launchApp(arguments: ["-ui-testing", "-fick-85-my-experiment"])

        let destination = app.descendants(matching: .any)["nav.experiment"]
        XCTAssertTrue(destination.waitForExistence(timeout: 5))
        destination.click()

        let runButton = app.buttons.matching(identifier: "experiment.run").firstMatch
        XCTAssertTrue(runButton.waitForExistence(timeout: 5))
        XCTAssertTrue(runButton.isEnabled)
        app.typeKey(XCUIKeyboardKey.return.rawValue, modifierFlags: .command)

        XCTAssertTrue(
            app.descendants(matching: .any)["experiment.results"].waitForExistence(timeout: 20),
            "The reconstructed result did not appear"
        )
        XCTAssertTrue(app.descendants(matching: .any)["experiment.split-audit"].exists)
        XCTAssertTrue(app.descendants(matching: .any)["experiment.prediction-chart"].exists)
        XCTAssertTrue(app.buttons.matching(identifier: "experiment.export").firstMatch.exists)
    }

    func testLocalMachineLearningWorkflowCanTrainAndPredictEndToEnd() {
        launchApp(arguments: ["-ui-testing", "-local-ml-e2e"])

        let screen = app.descendants(matching: .any)["screen.model-selection"]
        XCTAssertTrue(screen.waitForExistence(timeout: 5))
        let screenScrollView = app.scrollViews.matching(
            identifier: "screen.model-selection"
        ).firstMatch
        XCTAssertTrue(screenScrollView.waitForExistence(timeout: 5))
        XCTAssertTrue(
            app.staticTexts["Data S1 practice copy · Local ML"]
                .waitForExistence(timeout: 5),
            "The local ML workflow must use the personal, unvalidated Data S1 copy"
        )

        let evaluateButton = app.buttons.matching(identifier: "selector.evaluate").firstMatch
        XCTAssertTrue(evaluateButton.waitForExistence(timeout: 5))
        XCTAssertTrue(
            scrollUntilHittable(evaluateButton, in: screenScrollView),
            "The internal-CV action was not reachable"
        )
        XCTAssertTrue(evaluateButton.isEnabled)
        evaluateButton.click()

        let report = app.descendants(matching: .any)["selector.report"]
        XCTAssertTrue(
            report.waitForExistence(timeout: 60),
            "The on-device internal-CV report did not appear"
        )

        let trainButton = app.buttons.matching(identifier: "selector.train").firstMatch
        XCTAssertTrue(trainButton.waitForExistence(timeout: 5))
        XCTAssertTrue(
            scrollUntilHittable(trainButton, in: screenScrollView),
            "The final-fit action was not reachable after internal CV"
        )
        XCTAssertTrue(trainButton.isEnabled)
        trainButton.click()

        let modelCard = app.descendants(matching: .any)["selector.model-card"]
        XCTAssertTrue(
            modelCard.waitForExistence(timeout: 60),
            "The locally trained model card did not appear"
        )
        XCTAssertTrue(
            scrollUntilHittable(modelCard, in: screenScrollView),
            "The trained model card was not reachable"
        )

        let practiceButton = app.buttons.matching(
            identifier: "selector.practice-prediction"
        ).firstMatch
        XCTAssertTrue(practiceButton.waitForExistence(timeout: 5))
        XCTAssertTrue(
            scrollUntilHittable(practiceButton, in: screenScrollView),
            "The practice-prediction action was not reachable"
        )
        XCTAssertTrue(practiceButton.isEnabled)
        practiceButton.click()

        let predictionReport = app.descendants(matching: .any)["selector.prediction-report"]
        XCTAssertTrue(
            predictionReport.waitForExistence(timeout: 10),
            "The local prediction report did not appear"
        )
        XCTAssertTrue(
            scrollUntilHittable(predictionReport, in: screenScrollView),
            "The local prediction report was not reachable"
        )
    }

    func testLanguagePickerLabelsFollowInterfaceLanguage() {
        let languagePicker = app.descendants(matching: .any)["language.picker"]
        XCTAssertTrue(languagePicker.waitForExistence(timeout: 5))

        app.activate()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 5))
        XCTAssertTrue(waitUntilHittable(app.radioButtons["Japanese"], timeout: 10))
        XCTAssertFalse(app.radioButtons["日本語"].exists)
        // Re-query immediately before each click. Changing locale replaces the
        // segmented control's AX descendants and invalidates identity-bound snapshots.
        app.radioButtons["Japanese"].click()
        XCTAssertTrue(app.staticTexts["論文の概要"].waitForExistence(timeout: 5))

        app.activate()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 5))
        XCTAssertTrue(waitUntilHittable(app.radioButtons["英語"], timeout: 10))
        XCTAssertTrue(app.radioButtons["日本語"].exists)
        XCTAssertFalse(app.radioButtons["English"].exists)
        app.radioButtons["英語"].click()

        XCTAssertTrue(app.staticTexts["Paper overview"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.descendants(matching: .any)["toolbar.dataset-status"].exists)
    }

    func testPercentageReproductionLearningCardsAreAvailable() {
        let modelEvidence = app.descendants(matching: .any)["nav.model-evidence"]
        XCTAssertTrue(modelEvidence.waitForExistence(timeout: 5))
        app.activate()
        if modelEvidence.isHittable {
            modelEvidence.click()
        } else {
            modelEvidence.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).click()
        }

        XCTAssertTrue(
            app.descendants(matching: .any)["evidence.percentage-reproduction"]
                .waitForExistence(timeout: 5)
        )

        for model in ["fick", "mlr", "random-forest", "xgboost"] {
            XCTAssertTrue(
                app.descendants(matching: .any)["evidence.percentage-reproduction.\(model)"]
                    .waitForExistence(timeout: 5),
                "Missing percentage-reproduction card for \(model)"
            )
        }
    }

    func testCompactWindowKeepsCoreControlsReachable() {
        launchApp(arguments: ["-ui-testing", "-ui-testing-compact-window"])

        XCTAssertTrue(app.descendants(matching: .any)["language.picker"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.descendants(matching: .any)["mode.selector"].exists)
        XCTAssertTrue(app.buttons.matching(identifier: "mode.paperEvidence").firstMatch.exists)
        XCTAssertTrue(app.buttons.matching(identifier: "mode.myExperiment").firstMatch.exists)
        XCTAssertTrue(app.buttons.matching(identifier: "toolbar.reported-metrics").firstMatch.exists)
        XCTAssertTrue(app.descendants(matching: .any)["nav.data-source"].exists)

        // Relaunch the documented My Research entry point so this compact-layout
        // test checks both modes without depending on state from the first launch.
        launchApp(arguments: [
            "-ui-testing",
            "-ui-testing-compact-window",
            "-fick-85-my-experiment",
        ])
        app.activate()
        XCTAssertTrue(app.descendants(matching: .any)["mode.selector"].waitForExistence(timeout: 5))
        XCTAssertTrue(
            waitUntilHittable(app.buttons.matching(identifier: "mode.myExperiment").firstMatch)
        )
        XCTAssertTrue(app.descendants(matching: .any)["screen.fick-85-assessment"].waitForExistence(timeout: 5))
        XCTAssertTrue(
            waitUntilHittable(
                app.buttons.matching(identifier: "experiment.fick-validation.run").firstMatch
            )
        )
        XCTAssertTrue(
            waitUntilHittable(
                app.buttons.matching(identifier: "mode.import-experiment-data").firstMatch
            )
        )
    }

    func testFick85LaunchRunsInMyExperimentAndKeepsCriteriaSeparate() {
        launchApp(arguments: [
            "-ui-testing",
            "-fick-85-my-experiment",
            "-fick-85-auto-run",
            "-ui-testing-expanded-fick-audit",
        ])

        XCTAssertTrue(app.descendants(matching: .any)["screen.fick-85-assessment"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.descendants(matching: .any)["experiment.fick-validation"].waitForExistence(timeout: 5))
        XCTAssertTrue(
            app.descendants(matching: .any)["experiment.fick-validation.result"]
                .waitForExistence(timeout: 60),
            "The Fick proxy run did not complete independent replay audit"
        )
        XCTAssertTrue(
            app.descendants(matching: .any)["experiment.fick-validation.verdict"]
                .waitForExistence(timeout: 30),
            app.debugDescription
        )
        let screenScrollView = app.scrollViews.matching(
            identifier: "screen.fick-85-assessment"
        ).firstMatch
        XCTAssertTrue(screenScrollView.exists)
        let verdict = app.descendants(matching: .any)["experiment.fick-validation.verdict"]
        let verdictValue = String(describing: verdict.value ?? "")
        XCTAssertEqual(verdict.label, "Overall verdict")
        XCTAssertTrue(verdictValue.contains("R²"))
        XCTAssertTrue(verdictValue.contains("0.85"))
        XCTAssertTrue(
            verdictValue.contains("not confirmed") || verdictValue.contains("未確認"),
            "The first-screen verdict must reject a publication-level 85% claim: \(verdictValue)"
        )

        let reasonContainer = app.descendants(matching: .any)[
            "experiment.fick-validation.verdict-reasons"
        ]
        XCTAssertTrue(reasonContainer.waitForExistence(timeout: 10))
        let reasonTokens: [(id: String, tokens: [String])] = [
            ("pooled-variance", ["74.25%", "0.895", "0.862", "0.593", "0.338"]),
            ("family-results", ["0.689", "−0.101", "0.427"]),
            ("simple-control", ["0.895", "0.909"]),
            ("lower-reference", ["0.780", "0.850", "not a confirmatory 95% confidence interval"]),
            ("partial-coverage", ["3/9", "12/18", "112/191", "post hoc"]),
            ("unseen-family", ["−0.136"]),
            ("independence", ["experiment_run_id", "permeation_curve_id", "no external validation"]),
            ("model-identity", ["time-only finite-slab proxy", "not the paper's 2D solver"]),
        ]
        for item in reasonTokens {
            let reason = app.descendants(matching: .any)[
                "experiment.fick-validation.verdict-reason.\(item.id)"
            ]
            XCTAssertTrue(
                scrollUntilHittable(reason, in: screenScrollView, maximumScrolls: 5),
                "Missing visible decision reason \(item.id): \(app.debugDescription)"
            )
            let spokenText = reason.label + " " + String(describing: reason.value ?? "")
            for token in item.tokens {
                XCTAssertTrue(
                    spokenText.localizedCaseInsensitiveContains(token),
                    "Reason \(item.id) must expose \(token) to VoiceOver: \(spokenText)"
                )
            }
        }

        let coverage = app.descendants(matching: .any)["experiment.fick-validation.coverage-chart"]
        XCTAssertTrue(coverage.exists)
        let coverageSummary = app.staticTexts
            .matching(identifier: "experiment.fick-validation.coverage-summary")
            .firstMatch
        XCTAssertTrue(coverageSummary.exists)
        let coverageValue = coverageSummary.label
            + " "
            + String(describing: coverageSummary.value ?? "")
        for expectedScope in ["3/9", "12/18", "112/191"] {
            XCTAssertTrue(
                coverageValue.replacingOccurrences(of: " ", with: "").contains(expectedScope),
                "Coverage must expose \(expectedScope) to non-visual users: \(coverageValue)"
            )
        }

        let pointGate = app.descendants(matching: .any)["experiment.fick-validation.gate.row-pooled-point"]
        let baselineGate = app.descendants(matching: .any)["experiment.fick-validation.gate.simple-baseline"]
        let externalGate = app.descendants(matching: .any)["experiment.fick-validation.gate.external-confirmation"]
        XCTAssertTrue(pointGate.exists)
        XCTAssertTrue(baselineGate.exists)
        XCTAssertTrue(externalGate.exists)
        XCTAssertTrue(
            String(describing: pointGate.value ?? "").contains("Point above threshold (exploratory)")
                || String(describing: pointGate.value ?? "").contains("点推定が閾値超過（探索的）")
        )
        XCTAssertTrue(
            String(describing: baselineGate.value ?? "").contains("Not met")
                || String(describing: baselineGate.value ?? "").contains("未達")
        )
        XCTAssertTrue(
            String(describing: externalGate.value ?? "").contains("Not tested")
                || String(describing: externalGate.value ?? "").contains("未検証")
        )
        XCTAssertTrue(app.descendants(matching: .any)["experiment.fick-validation.baseline-chart"].exists)
        XCTAssertTrue(app.descendants(matching: .any)["experiment.fick-validation.advanced"].exists)
        let conditionChart = app.descendants(matching: .any)[
            "experiment.fick-validation.condition-chart"
        ]
        XCTAssertTrue(conditionChart.waitForExistence(timeout: 10))
        let conditionValuesDisclosure = app.disclosureTriangles.matching(
            NSPredicate(format: "label CONTAINS %@", "Read values for each condition")
        ).firstMatch
        XCTAssertTrue(conditionValuesDisclosure.waitForExistence(timeout: 5))
        XCTAssertTrue(
            scrollUntilHittable(conditionValuesDisclosure, in: screenScrollView),
            app.debugDescription
        )
        let conditionValues = app.descendants(matching: .any).matching(
            identifier: "experiment.fick-validation.condition-value"
        )
        if conditionValues.count == 0 {
            conditionValuesDisclosure.click()
            XCTAssertTrue(conditionValues.firstMatch.waitForExistence(timeout: 5))
        }
        XCTAssertEqual(conditionValues.count, 12)
        for index in 0..<conditionValues.count {
            let row = conditionValues.element(boundBy: index)
            let spokenText = row.label + " " + String(describing: row.value ?? "")
            XCTAssertTrue(spokenText.contains("Fick RMSE"), spokenText)
            XCTAssertTrue(spokenText.contains("Control RMSE"), spokenText)
            XCTAssertTrue(spokenText.contains("Fick R²"), spokenText)
        }
        XCTAssertTrue(conditionValues.firstMatch.label.contains("BSA"))
        XCTAssertTrue(app.descendants(matching: .any)["experiment.fick-validation.export-audit"].exists)
        XCTAssertFalse(app.buttons.matching(identifier: "toolbar.reported-metrics").firstMatch.exists)
    }
}
