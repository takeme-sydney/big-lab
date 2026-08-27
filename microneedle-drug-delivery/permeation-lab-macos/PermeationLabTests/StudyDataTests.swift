import XCTest
@testable import PermeationLab

final class StudyDataTests: XCTestCase {
    func testDataS1ContainsAllReportedRowsAndCategories() throws {
        let records = try loadRecords()

        XCTAssertEqual(records.count, 191)
        XCTAssertEqual(Set(records.map(\.id)).count, 191)

        let expectedDrugCounts = [
            "BSA": 33,
            "lidocaine": 73,
            "Rhodamine B": 19,
            "caffeine": 18,
            "copper ions": 24,
            "GHK peptide": 24
        ]
        XCTAssertEqual(Dictionary(grouping: records, by: \.drug).mapValues(\.count), expectedDrugCounts)

        XCTAssertEqual(Dictionary(grouping: records, by: \.skin).mapValues(\.count), [
            .rat: 137,
            .human: 54
        ])
        XCTAssertEqual(Dictionary(grouping: records, by: \.needle).mapValues(\.count), [
            .hydrogel: 131,
            .plastic: 60
        ])
    }

    func testDataS1PreservesExactObservedRangesIncludingPercentageAboveOneHundred() throws {
        let records = try loadRecords()

        assertRange(records.map(\.loadingMicrograms), minimum: 50, maximum: 70_940)
        assertRange(records.map(\.molecularWeightDalton), minimum: 63.5, maximum: 66_000)
        assertRange(records.map(\.needleLengthMillimeters), minimum: 0.7, maximum: 1.25)
        assertRange(
            records.map(\.surfaceAreaSquareMillimeters),
            minimum: 26.76103315,
            maximum: 36.855
        )
        assertRange(records.map(\.timeHours), minimum: 0.083333333, maximum: 48)
        assertRange(records.map(\.percentage), minimum: 0.0198437, maximum: 108.3982246)
        assertRange(
            records.map(\.amountMicrogramsPerSquareCentimeter),
            minimum: 1.0537,
            maximum: 29_009.78801
        )

        let maximumPercentage = try XCTUnwrap(records.max(by: { $0.percentage < $1.percentage }))
        XCTAssertEqual(maximumPercentage.drug, "BSA")
        XCTAssertGreaterThan(maximumPercentage.percentage, 100)
    }

    func testEveryDataS1AmountMatchesLoadingTimesPercentage() throws {
        for record in try loadRecords() {
            let expectedAmount = record.loadingMicrograms * record.percentage / 100
            XCTAssertEqual(
                record.amountMicrogramsPerSquareCentimeter,
                expectedAmount,
                accuracy: 0.0001,
                "Data S1 row \(record.id), \(record.drug)"
            )
        }
    }

    func testTable4ReportedMetricsAreExact() throws {
        let expected: [(
            model: PaperModel,
            amountRMSE: Double,
            amountR2: Double,
            percentageRMSE: Double,
            percentageR2: Double
        )] = [
            (.xgboost, 4_447.23, 0.98, 28.24, 0.98),
            (.randomForest, 7_043.97, 0.95, 34.33, 0.97),
            (.fick, 6_778.17, 0.95, 85.58, 0.82),
            (.mlr, 23_398.91, 0.46, 120.33, 0.65)
        ]

        XCTAssertEqual(PaperContent.reportedMetrics.count, expected.count)
        for item in expected {
            let metric = try XCTUnwrap(
                PaperContent.reportedMetrics.first { $0.model.rawValue == item.model.rawValue },
                "Missing Table 4 row for \(item.model.rawValue)"
            )
            XCTAssertEqual(metric.amountRMSE, item.amountRMSE, accuracy: 0.000_001)
            XCTAssertEqual(metric.amountR2, item.amountR2, accuracy: 0.000_001)
            XCTAssertEqual(metric.percentageRMSE, item.percentageRMSE, accuracy: 0.000_001)
            XCTAssertEqual(metric.percentageR2, item.percentageR2, accuracy: 0.000_001)
        }
    }

    func testPaperInventoryContainsElevenNumberedEquationsTwoUnnumberedExamplesAndAllFigures() {
        XCTAssertEqual(PaperContent.equations.map(\.number), Array(1...11))
        XCTAssertEqual(PaperContent.calculationExamples.count, 2)
        XCTAssertTrue(PaperContent.calculationExamples.allSatisfy { $0.evidence.note == "番号なし計算例" })
        XCTAssertEqual(
            PaperContent.equations.first { $0.number == 10 }?.expression,
            "S = 4 × ½a × √((a/2)² + h²)"
        )
        XCTAssertEqual(
            PaperContent.calculationExamples.first?.expression,
            "S = 4 × ½ × 0.075 × √((0.075/2)² + 0.7²) = 0.105 mm²"
        )

        let mainFigures = PaperContent.figures.filter { !$0.label.hasPrefix("Figure S") }
        let supplementaryFigures = PaperContent.figures.filter { $0.label.hasPrefix("Figure S") }
        XCTAssertEqual(mainFigures.count, 8)
        XCTAssertEqual(supplementaryFigures.count, 2)
        XCTAssertEqual(PaperContent.figures.count, 10)
        XCTAssertEqual(
            Set(PaperContent.figures.map(\.id)),
            Set((1...8).map { "figure-\($0)" } + ["figure-s1", "figure-s2"])
        )
    }

    func testSkinPermeationPresentationUsesOnlyUnconnectedObservedPoints() throws {
        let records = try loadRecords()
        let points = SkinPermeationPresentation.observedPoints(records: records, outcome: .percentage)

        XCTAssertEqual(SkinPermeationPresentation.observedTopology, .unconnectedPoints)
        XCTAssertEqual(points.count, 191)
        XCTAssertEqual(Set(points.map(\.recordID)).count, 191)
        let maximum = try XCTUnwrap(points.map(\.value).max())
        XCTAssertEqual(maximum, 108.3982246, accuracy: 0.000_000_001)
        XCTAssertEqual(SkinPermeationPresentation.dataS1AmountUnit, "µg/cm²")
    }

    func testHydrogelAndPlasticConceptStepsDescribeDifferentSourceMechanisms() {
        let hydrogel = SkinPermeationPresentation.mechanismSteps(for: .hydrogel)
        let plastic = SkinPermeationPresentation.mechanismSteps(for: .plastic)

        XCTAssertEqual(hydrogel.count, 4)
        XCTAssertEqual(plastic.count, 4)
        XCTAssertNotEqual(hydrogel, plastic)
        XCTAssertTrue(hydrogel.map(\.detail).joined().contains("挿入したまま"))
        XCTAssertTrue(plastic.map(\.detail).joined().contains("取り外し"))
        XCTAssertTrue(plastic.map(\.detail).joined().contains("passage"))
    }

    func testFilteredSkinPermeationSelectionIsDeterministic() throws {
        let repository = StudyRepository(records: try loadRecords())
        let filtered = repository.filtered(drug: "lidocaine", skin: .rat, needle: .hydrogel)

        XCTAssertFalse(filtered.isEmpty)
        XCTAssertEqual(filtered, filtered.sorted { $0.id < $1.id })
        XCTAssertTrue(filtered.allSatisfy { $0.drug == "lidocaine" && $0.skin == .rat && $0.needle == .hydrogel })
    }

    private func loadRecords(file: StaticString = #filePath, line: UInt = #line) throws -> [PermeationRecord] {
        let testBundle = Bundle(for: Self.self)
        let hostAppURL = testBundle.bundleURL
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let resourceBundle = Bundle(url: hostAppURL) ?? .main
        let repository = StudyRepository(bundle: resourceBundle)
        XCTAssertNil(repository.loadingError, repository.loadingError ?? "", file: file, line: line)
        XCTAssertFalse(repository.records.isEmpty, "Data S1 produced no records", file: file, line: line)
        return repository.records
    }

    private func assertRange(
        _ values: [Double],
        minimum expectedMinimum: Double,
        maximum expectedMaximum: Double,
        accuracy: Double = 0.000_000_001,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        guard let actualMinimum = values.min(), let actualMaximum = values.max() else {
            XCTFail("Expected a non-empty numeric column", file: file, line: line)
            return
        }
        XCTAssertEqual(actualMinimum, expectedMinimum, accuracy: accuracy, file: file, line: line)
        XCTAssertEqual(actualMaximum, expectedMaximum, accuracy: accuracy, file: file, line: line)
    }
}
