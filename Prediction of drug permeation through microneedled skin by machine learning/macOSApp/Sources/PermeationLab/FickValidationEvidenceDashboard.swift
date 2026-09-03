import AppKit
import Charts
import SwiftUI

/// A fail-closed, beginner-facing interpretation layer for the exploratory
/// Fick proxy result. It deliberately separates a point estimate from evidence
/// that would be needed for a publication claim at the configured R² target.
struct FickValidationEvidenceDashboard: View {
    @Environment(\.colorScheme) private var colorScheme

    let language: AppLanguage
    let result: FickValidationRunResult
    let diagnostics: FickValidationDiagnostics

    @State private var selectedComparator: FickValidationComparator = .fickProxy
    @State private var isAdvancedExpanded = ProcessInfo.processInfo.arguments.contains(
        "-ui-testing-expanded-fick-audit"
    )
    @State private var isConditionValuesExpanded = ProcessInfo.processInfo.arguments.contains(
        "-ui-testing-expanded-fick-audit"
    )
    @State private var copiedClaim = false
    @State private var copiedRequiredIDs = false

    private struct CoverageDatum: Identifiable {
        let id: String
        let title: String
        let included: Int
        let total: Int
    }

    private struct AggregationDatum: Identifiable {
        let id: String
        let metric: String
        let comparator: FickValidationComparator
        let value: Double
    }

    private struct CalibrationPoint: Identifiable {
        let id: String
        let observed: Double
        let predicted: Double
    }

    private struct BaselineChartDatum: Identifiable {
        let id: FickValidationComparator
        let title: String
        let value: Double
        let color: Color
    }

    private struct ApplicabilityDatum: Identifiable {
        let id: String
        let title: String
        let value: Double
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            verdictCard
            publicationReasonMap
            coverageCard
            evidenceLadder
            baselineComparisonCard

            DisclosureGroup(isExpanded: $isAdvancedExpanded) {
                VStack(alignment: .leading, spacing: 20) {
                    aggregationCard
                    varianceCard
                    applicabilityCard
                    calibrationCard
                    conditionCard
                    hierarchyCard
                    influenceCard
                    publicationClaimCard
                }
                .padding(.top, 14)
            } label: {
                Label(
                    language.text(
                        "詳細監査を見る（集約・較正・条件・データ階層）",
                        "Show detailed audit (aggregation, calibration, conditions, hierarchy)"
                    ),
                    systemImage: "chart.xyaxis.line"
                )
                .font(.headline)
                .accessibilityIdentifier("experiment.fick-validation.advanced")
            }
        }
    }

    private var publicationReasonMap: some View {
        let point = format(summary(.fickProxy)?.rowPooledMetric.rSquared)
        let conditionBalanced = format(summary(.fickProxy)?.conditionBalancedMetric.rSquared)
        let target = format(result.configuration.targetRSquared)
        let reasons = FickPublicationExplanation.make(result: result, diagnostics: diagnostics)

        return VStack(alignment: .leading, spacing: 16) {
            sectionHeading(
                language.text(
                    "なぜ点R²が高くても確認判定にならないのか",
                    "Why a high point R² does not establish confirmation"
                ),
                language.text(
                    "緑の一点は1つの問いだけに答えます。下の理由は、集約・対照・不確実性・対象範囲・一般化・独立検証を別々に監査します。",
                    "The green point estimate answers one question only. The reasons below audit aggregation, comparison, uncertainty, scope, generalization, and independent validation separately."
                )
            )

            FickDecisionEquationView(
                language: language,
                pointValue: "R² \(point)",
                targetValue: "R² ≥ \(target)"
            )

            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 330), spacing: 14)],
                alignment: .leading,
                spacing: 14
            ) {
                ForEach(reasons) { reason in
                    FickPublicationReasonCard(
                        language: language,
                        reason: reason,
                        accessibilityPrefix: "experiment.fick-validation.verdict-reason"
                    )
                }
            }

            LabNotice(
                title: language.text("判定はNO-GO", "Decision: NO-GO"),
                message: language.text(
                    "限定subsetでは事後的row-pooled \(point)とcondition等重み \(conditionBalanced)の2集約点が閾値を超えました。ただし確認的R² ≥ \(target)、未知family一般化、独立外部検証は支持されません。",
                    "In the limited subset, the post hoc row-pooled value of \(point) and condition-balanced value of \(conditionBalanced) both exceed the numerical threshold. Confirmatory R² ≥ \(target), unseen-family generalization, and independent external validation are not supported."
                ),
                kind: .warning
            )
        }
        .padding(16)
        .labCard()
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("experiment.fick-validation.verdict-reasons")
    }

    private var verdictCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .center, spacing: 14) {
                    verdictIcon
                    verdictText
                    Spacer(minLength: 12)
                    Text(language.text("結論", "VERDICT"))
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.secondary)
                }
                VStack(alignment: .leading, spacing: 10) {
                    verdictIcon
                    verdictText
                }
            }

            Divider()

            Text(language.text(
                "部分集合の点推定、単純対照、family別成績を分けて示します。独立runと外部データによる確認がないため、論文では探索的結果としてのみ記載できます。",
                "The subset point estimate, simple control, and family-level results are shown separately. Without confirmation on independent runs and external data, the result can only be reported as exploratory."
            ))
            .font(.callout)
            .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.orange.opacity(0.10), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.orange.opacity(0.35), lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(language.text("総合判定", "Overall verdict"))
        .accessibilityValue(language.text(
            "R² ≥ \(format(result.configuration.targetRSquared)) の主張は未確認",
            "The R² ≥ \(format(result.configuration.targetRSquared)) claim is not confirmed"
        ))
        .accessibilityIdentifier("experiment.fick-validation.verdict")
    }

    private var verdictIcon: some View {
        Image(systemName: "exclamationmark.shield.fill")
            .font(.system(size: 34))
            .foregroundStyle(.orange)
            .accessibilityHidden(true)
    }

    private var verdictText: some View {
        let point = summary(.fickProxy).flatMap { $0.rowPooledMetric.rSquared }
        return VStack(alignment: .leading, spacing: 4) {
            Text(language.text(
                "R² ≥ \(format(result.configuration.targetRSquared)) の主張は未確認",
                "R² ≥ \(format(result.configuration.targetRSquared)) claim is not confirmed"
            ))
                .font(.title2.bold())
            Text(language.text(
                "\(format(point))は「この部分集合での探索的R²」です",
                "\(format(point)) is an exploratory R² for this subset"
            ))
            .font(.headline)
            .foregroundStyle(.secondary)
        }
    }

    private var coverageData: [CoverageDatum] {
        [
            CoverageDatum(
                id: "families",
                title: language.text("family", "Families"),
                included: result.eligibleFamilyCount,
                total: result.eligibleFamilyCount + result.excludedFamilyCount
            ),
            CoverageDatum(
                id: "conditions",
                title: language.text("condition", "Conditions"),
                included: result.eligibleConditionCount,
                total: result.eligibleConditionCount + result.excludedConditionCount
            ),
            CoverageDatum(
                id: "rows",
                title: language.text("時点row", "Time-point rows"),
                included: result.eligibleObservationCount,
                total: result.eligibleObservationCount + result.excludedObservationCount
            ),
        ]
    }

    private var coverageCard: some View {
        let point = summary(.fickProxy).flatMap { $0.rowPooledMetric.rSquared }
        return VStack(alignment: .leading, spacing: 12) {
            sectionHeading(
                language.text("最初に、何を評価したか", "First: what was evaluated"),
                language.text(
                    "色付き部分だけが主な\(format(point))の計算対象です。除外されたデータを含む性能ではありません。",
                    "Only the colored portion contributes to the primary \(format(point)) result; it is not performance over all data."
                )
            )

            Chart {
                ForEach(coverageData) { item in
                    BarMark(
                        x: .value("Total", item.total),
                        y: .value("Level", item.title)
                    )
                    .foregroundStyle(Color.secondary.opacity(0.15))

                    BarMark(
                        x: .value("Included", item.included),
                        y: .value("Level", item.title)
                    )
                    .foregroundStyle(Color.accentColor.gradient)
                    .annotation(position: .trailing, alignment: .leading) {
                        Text("\(item.included) / \(item.total)")
                            .font(.caption.bold().monospacedDigit())
                            .foregroundStyle(.primary)
                    }
                }
            }
            .chartXScale(domain: 0...(coverageData.map(\.total).max() ?? 1))
            .chartXAxisLabel(language.text("全データ中の評価対象数", "Evaluated count out of all data"))
            .frame(height: 170)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(language.text("評価範囲チャート", "Evaluation coverage chart"))
            .accessibilityValue(coverageAccessibilityValue)
            .accessibilityIdentifier("experiment.fick-validation.coverage-chart")

            Text(language.text(
                "family \(result.eligibleFamilyCount)/\(result.eligibleFamilyCount + result.excludedFamilyCount)、condition \(result.eligibleConditionCount)/\(result.eligibleConditionCount + result.excludedConditionCount)、row \(result.eligibleObservationCount)/\(result.eligibleObservationCount + result.excludedObservationCount)。時点数が多いconditionほどrow-pooled R²への影響が大きくなります。",
                "\(result.eligibleFamilyCount)/\(result.eligibleFamilyCount + result.excludedFamilyCount) families, \(result.eligibleConditionCount)/\(result.eligibleConditionCount + result.excludedConditionCount) conditions, and \(result.eligibleObservationCount)/\(result.eligibleObservationCount + result.excludedObservationCount) rows. Conditions with more time points exert more influence on row-pooled R²."
            ))
            .font(.caption)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityIdentifier("experiment.fick-validation.coverage-summary")
        }
        .padding(16)
        .labCard()
    }

    private var evidenceLadder: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeading(
                language.text(
                    "R² ≥ \(format(result.configuration.targetRSquared)) を論文で主張するまでの7段階",
                    "Seven steps before a publication-level R² ≥ \(format(result.configuration.targetRSquared)) claim"
                ),
                language.text(
                    "上から順に証拠が強くなります。緑1つだけでは最終確認になりません。",
                    "Evidence strengthens from top to bottom. One green step does not establish the final claim."
                )
            )

            ForEach(Array(diagnostics.gates.enumerated()), id: \.element.id) { index, gate in
                gateRow(number: index + 1, gate: gate)
                if index < diagnostics.gates.count - 1 {
                    Divider().padding(.leading, 43)
                }
            }
        }
        .padding(16)
        .labCard()
    }

    private func gateRow(number: Int, gate: FickValidationEvidenceGate) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle().fill(gateColor(gate).opacity(0.13))
                Text(number.formatted())
                    .font(.caption.bold().monospacedDigit())
                    .foregroundStyle(gateColor(gate))
            }
            .frame(width: 30, height: 30)
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text(gateTitle(gate.id))
                    .font(.headline)
                Text(gateExplanation(gate.id))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 12)
            VStack(alignment: .trailing, spacing: 3) {
                Label(gateStatusText(gate), systemImage: gateSymbol(gate.status))
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(gateColor(gate))
                if let value = gate.measuredValue {
                    Text(gateValue(gate.id, value: value))
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(number). \(gateTitle(gate.id))")
        .accessibilityValue(gateStatusText(gate) + measuredAccessibility(gate))
        .accessibilityIdentifier("experiment.fick-validation.gate.\(gate.id)")
    }

    private var baselineComparisonCard: some View {
        let fick = summary(.fickProxy)
        let control = summary(.familyTimeControl)
        let fickR2 = finite(fick.flatMap { $0.rowPooledMetric.rSquared })
        let controlR2 = finite(control.flatMap { $0.rowPooledMetric.rSquared })
        let fickRMSE = fick?.rowPooledMetric.rmse ?? 0
        let controlRMSE = control?.rowPooledMetric.rmse ?? 0
        let baselineStatus = diagnostics.gates.first {
            $0.id == "simple-baseline"
        }?.status ?? .unavailable
        let chartData = [
            fickR2.map { value in BaselineChartDatum(
                id: .fickProxy,
                title: language.text("Fick proxy", "Fick proxy"),
                value: value,
                color: .accentColor
            ) },
            controlR2.map { value in BaselineChartDatum(
                id: .familyTimeControl,
                title: language.text("単純対照", "Simple control"),
                value: value,
                color: .orange
            ) },
        ].compactMap { $0 }
        let accessibilityValue = language.text(
            "Fick \(format(fickR2))、単純対照 \(format(controlR2))。",
            "Fick \(format(fickR2)); simple control \(format(controlR2))."
        )
        let conclusion: String
        if let fickR2, let controlR2 {
            switch baselineStatus {
            case .met:
                conclusion = language.text(
                    "Fickのrow-pooled R²は単純対照より \(signed(fickR2 - controlR2))、RMSEは \(format(fickRMSE)) pp 対 \(format(controlRMSE)) ppです。この内部比較で増分予測性能の基準を満たしますが、独立外部検証の代わりにはなりません。",
                    "Fick minus control is \(signed(fickR2 - controlR2)) in row-pooled R²; RMSE is \(format(fickRMSE)) pp versus \(format(controlRMSE)) pp. It meets the incremental-prediction criterion in this internal comparison, but does not replace independent external validation."
                )
            case .notMet:
                conclusion = language.text(
                    "Fickのrow-pooled R²は単純対照より \(signed(fickR2 - controlR2))。RMSEは \(format(fickRMSE)) pp 対 \(format(controlRMSE)) ppで、単純対照に対する増分予測性能は示されません。",
                    "Fick minus control is \(signed(fickR2 - controlR2)) in row-pooled R². RMSE is \(format(fickRMSE)) pp versus \(format(controlRMSE)) pp, so incremental predictive performance over the simple control is not shown."
                )
            case .unavailable:
                conclusion = language.text(
                    "Fickのrow-pooled R²は単純対照より \(signed(fickR2 - controlR2))、RMSEは \(format(fickRMSE)) pp 対 \(format(controlRMSE)) ppです。これは監査時に追加した探索的比較で、封印済みの改善幅がないため、同等以上でも増分性能を『確認』とは判定しません。",
                    "Fick minus control is \(signed(fickR2 - controlR2)) in row-pooled R²; RMSE is \(format(fickRMSE)) pp versus \(format(controlRMSE)) pp. This comparison was added during exploratory audit; without a sealed improvement margin, equal or better performance is not marked as confirmed."
                )
            }
        } else {
            conclusion = language.text(
                "Fickまたは単純対照のR²が未定義のため、増分予測性能は判定できません。",
                "Incremental predictive performance cannot be assessed because the Fick or simple-control R² is undefined."
            )
        }

        return VStack(alignment: .leading, spacing: 12) {
            sectionHeading(
                language.text("探索的比較：Fickと単純対照", "Exploratory comparison: Fick vs simple control"),
                language.text(
                    "対照は各foldのtraining rowsだけからfamily別の平均time curveを作ります。test outcomeは使いません。",
                    "The control builds a family-specific mean time curve from training rows in each fold only; it does not use test outcomes."
                )
            )

            Chart(chartData) { item in
                BarMark(
                    x: .value("R squared", item.value),
                    y: .value("Comparator", item.title)
                )
                .foregroundStyle(item.color.gradient)
                .annotation(position: .trailing, alignment: .leading) {
                    Text(format(item.value))
                        .font(.caption.bold().monospacedDigit())
                }
            }
            .chartXScale(domain: rSquaredDomain(chartData.map(\.value)))
            .chartXAxisLabel("R²")
            .chartLegend(.hidden)
            .frame(height: 135)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(language.text("Fickと単純対照のR二乗比較", "R-squared comparison of Fick and the simple control"))
            .accessibilityValue(accessibilityValue)
            .accessibilityIdentifier("experiment.fick-validation.baseline-chart")

            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "arrow.down.right.circle.fill")
                    .foregroundStyle(.orange)
                    .accessibilityHidden(true)
                Text(conclusion)
                .font(.callout)
                .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .labCard()
    }

    private var aggregationCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeading(
                language.text(
                    "集約方法を変えてもR² ≥ \(format(result.configuration.targetRSquared)) か",
                    "Does R² stay at or above \(format(result.configuration.targetRSquared)) under other aggregations?"
                ),
                language.text(
                    "同じ予測を4通りに集約します。左ほど悪いとは限らず、各値が別の問いに答えます。",
                    "The same predictions are summarized four ways. Each value answers a different question."
                )
            )

            Chart(aggregationData) { item in
                PointMark(
                    x: .value("R squared", item.value),
                    y: .value("Aggregation", item.metric)
                )
                .foregroundStyle(by: .value("Comparator", comparatorTitle(item.comparator)))
                .symbol(by: .value("Comparator", comparatorTitle(item.comparator)))
                .annotation(position: .trailing, alignment: .leading) {
                    Text(format(item.value))
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.secondary)
                }

                RuleMark(x: .value("Target", result.configuration.targetRSquared))
                    .foregroundStyle(Color.red.opacity(0.7))
                    .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
            }
            .chartXScale(domain: aggregationDomain)
            .chartXAxisLabel("R²")
            .chartLegend(position: .top, alignment: .leading)
            .frame(height: 250)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(language.text("4集約法のR二乗比較", "R-squared comparison across four aggregation methods"))
            .accessibilityValue(aggregationAccessibilityValue)
            .accessibilityIdentifier("experiment.fick-validation.aggregation-chart")

            if !undefinedAggregationLabels.isEmpty {
                Label(
                    language.text("未定義: ", "Undefined: ")
                        + undefinedAggregationLabels.joined(separator: ", "),
                    systemImage: "questionmark.circle"
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Text(language.text(
                "Fick: row-pooled \(format(summary(.fickProxy)?.rowPooledMetric.rSquared))、condition等重み \(format(summary(.fickProxy)?.conditionBalancedMetric.rSquared))、family内中心化 \(format(summary(.fickProxy)?.familyCenteredRSquared))、macro-family \(format(summary(.fickProxy)?.macroFamilyRSquared))。",
                "Fick: row-pooled \(format(summary(.fickProxy)?.rowPooledMetric.rSquared)), condition-balanced \(format(summary(.fickProxy)?.conditionBalancedMetric.rSquared)), family-centered \(format(summary(.fickProxy)?.familyCenteredRSquared)), and macro-family \(format(summary(.fickProxy)?.macroFamilyRSquared))."
            ))
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(16)
        .labCard()
    }

    private var varianceCard: some View {
        let share = finite(diagnostics.tss.betweenFamilyShare)
        return VStack(alignment: .leading, spacing: 12) {
            sectionHeading(
                language.text("R²の分母は何でできているか", "What contributes to the R² denominator?"),
                language.text(
                    "family間の水準差が大きいほど、各family内の曲線を十分に当てなくてもpooled R²が高く見えることがあります。",
                    "Large differences between family levels can make pooled R² look high even when within-family curves are not predicted well."
                )
            )

            if let share {
                GeometryReader { proxy in
                    HStack(spacing: 2) {
                        Rectangle()
                            .fill(Color.orange.gradient)
                            .frame(width: max(0, proxy.size.width * share))
                        Rectangle()
                            .fill(Color.accentColor.opacity(0.45).gradient)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .frame(height: 28)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(language.text("全分散の構成", "Composition of total variation"))
                .accessibilityValue(language.text(
                    "family間 \(percent(share))、family内 \(percent(1 - share))",
                    "Between-family \(percent(share)); within-family \(percent(1 - share))"
                ))

                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 18) { varianceLegend(share: share); withinVarianceLegend(share: share) }
                    VStack(alignment: .leading, spacing: 8) { varianceLegend(share: share); withinVarianceLegend(share: share) }
                }
            } else {
                Label(
                    language.text("family間分散の割合は未定義です。", "The between-family variance share is undefined."),
                    systemImage: "questionmark.circle"
                )
                .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .labCard()
        .accessibilityIdentifier("experiment.fick-validation.variance")
    }

    private var applicabilityCard: some View {
        let knownFamily = finite(summary(.fickProxy)?.rowPooledMetric.rSquared)
        let unseenFamily = finite(diagnostics.leaveOneFamilyOutMetric.rSquared)
        let scenarios = [
            knownFamily.map { ApplicabilityDatum(
                id: "known-family",
                title: language.text("既知family内の新condition", "New condition in known families"),
                value: $0
            ) },
            unseenFamily.map { ApplicabilityDatum(
                id: "unseen-family",
                title: language.text("未知family", "Unseen family"),
                value: $0
            ) },
        ].compactMap { $0 }

        return VStack(alignment: .leading, spacing: 12) {
            sectionHeading(
                language.text("どこまで外挿できるか", "How far can the result be transported?"),
                language.text(
                    "適用範囲を変えると同じモデルでも性能が変わります。未知familyは、既知family内のcondition補間より厳しい問いです。",
                    "Performance changes with the applicability domain. An unseen family is a harder question than interpolation among conditions in known families."
                )
            )

            Chart(scenarios) { scenario in
                BarMark(
                    x: .value("R squared", scenario.value),
                    y: .value("Scenario", scenario.title)
                )
                .foregroundStyle(scenario.value >= result.configuration.targetRSquared ? Color.accentColor.gradient : Color.orange.gradient)
                .annotation(position: .trailing, alignment: .leading) {
                    Text(format(scenario.value)).font(.caption.bold().monospacedDigit())
                }
                RuleMark(x: .value("Target", result.configuration.targetRSquared))
                    .foregroundStyle(Color.red.opacity(0.7))
                    .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
            }
            .chartXScale(domain: rSquaredDomain(scenarios.map(\.value)))
            .chartXAxisLabel("R²")
            .frame(height: 145)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(language.text("適用範囲別R二乗", "R-squared by applicability domain"))
            .accessibilityValue(language.text(
                "既知family内 \(format(knownFamily))、未知family \(format(unseenFamily))",
                "Known-family conditions \(format(knownFamily)); unseen family \(format(unseenFamily))"
            ))
            .accessibilityIdentifier("experiment.fick-validation.applicability-chart")

            if scenarios.count < 2 {
                Label(
                    language.text(
                        "表示できない適用範囲のR²は未定義です。",
                        "R² is undefined for the applicability domain not shown."
                    ),
                    systemImage: "questionmark.circle"
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Text(language.text(
                "このproxyの各foldは、同じfamilyの他conditionから振幅とrateをfitし、予測式では時間だけを変えます。loading・分子量・針長・表面積はconditionの区別には使われますが、予測式へ直接入りません。既知family内の\(format(knownFamily))を未知薬物・皮膚・MNへ外挿できません。",
                "Each fold fits amplitude and rate from other conditions in the same family, then varies only time in the prediction equation. Loading, molecular weight, needle length, and surface area distinguish conditions but do not enter the prediction equation directly. The known-family value of \(format(knownFamily)) cannot be extrapolated to unseen drugs, skin, or microneedles."
            ))
            .font(.caption)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .labCard()
    }

    private func varianceLegend(share: Double) -> some View {
        Label {
            Text(language.text("family間 \(percent(share))", "Between families \(percent(share))"))
        } icon: {
            Image(systemName: "square.fill").foregroundStyle(.orange)
        }
        .font(.callout.weight(.semibold))
    }

    private func withinVarianceLegend(share: Double) -> some View {
        Label {
            Text(language.text("family内 \(percent(1 - share))", "Within families \(percent(1 - share))"))
        } icon: {
            Image(systemName: "square.fill").foregroundStyle(Color.accentColor.opacity(0.55))
        }
        .font(.callout.weight(.semibold))
    }

    private var calibrationCard: some View {
        let selected = summary(selectedComparator)
        return VStack(alignment: .leading, spacing: 12) {
            sectionHeading(
                language.text("予測と実測のずれを見る", "Inspect predicted versus observed values"),
                language.text(
                    "点が斜めの基準線に近いほど予測と実測が一致します。これは較正の診断で、R²だけでは見えない偏りを示します。",
                    "Points closer to the diagonal agree better with observations. This calibration diagnostic reveals bias that R² alone can hide."
                )
            )

            Picker(language.text("比較対象", "Comparator"), selection: $selectedComparator) {
                ForEach(FickValidationComparator.allCases) { comparator in
                    Text(comparatorTitle(comparator)).tag(comparator)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .accessibilityIdentifier("experiment.fick-validation.calibration-picker")

            Chart {
                ForEach([calibrationDomain.lowerBound, calibrationDomain.upperBound], id: \.self) { value in
                    LineMark(
                        x: .value("Predicted", value),
                        y: .value("Ideal observation", value),
                        series: .value("Reference", "Ideal")
                    )
                    .foregroundStyle(Color.secondary.opacity(0.6))
                    .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                }
                ForEach(calibrationPoints) { point in
                    PointMark(
                        x: .value("Predicted", point.predicted),
                        y: .value("Observed", point.observed)
                    )
                    .foregroundStyle(selectedComparator == .fickProxy ? Color.accentColor.opacity(0.62) : Color.orange.opacity(0.62))
                    .symbolSize(25)
                }
            }
            .chartXScale(domain: calibrationDomain)
            .chartYScale(domain: calibrationDomain)
            .chartXAxisLabel(language.text("予測透過率 (%)", "Predicted permeation (%)"))
            .chartYAxisLabel(language.text("実測透過率 (%)", "Observed permeation (%)"))
            .chartLegend(.hidden)
            .frame(height: 330)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(language.text("予測実測較正チャート", "Predicted-versus-observed calibration chart"))
            .accessibilityValue(language.text(
                "較正切片 \(format(selected?.calibration.intercept))、傾き \(format(selected?.calibration.slope))、平均誤差 \(format(selected?.calibration.meanErrorPercentagePoints))パーセントポイント",
                "Calibration intercept \(format(selected?.calibration.intercept)), slope \(format(selected?.calibration.slope)), mean error \(format(selected?.calibration.meanErrorPercentagePoints)) percentage points"
            ))
            .accessibilityIdentifier("experiment.fick-validation.calibration-chart")

            Text(language.text(
                "較正切片 \(format(selected?.calibration.intercept))（理想0）・傾き \(format(selected?.calibration.slope))（理想1）・平均誤差 \(signedOptional(selected?.calibration.meanErrorPercentagePoints)) pp（予測−実測）。",
                "Calibration intercept \(format(selected?.calibration.intercept)) (ideal 0), slope \(format(selected?.calibration.slope)) (ideal 1), and mean error \(signedOptional(selected?.calibration.meanErrorPercentagePoints)) pp (predicted minus observed)."
            ))
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(16)
        .labCard()
    }

    private var conditionCard: some View {
        let fickWins = diagnostics.conditions.filter(\.fickWinsRMSE).count
        let defined = diagnostics.conditions.compactMap(\.fickRSquaredMeetsTarget)
        let targetWins = defined.filter { $0 }.count
        return VStack(alignment: .leading, spacing: 12) {
            sectionHeading(
                language.text("どのconditionで失敗するか", "Where does the model fail by condition?"),
                language.text(
                    "RMSEは小さいほど良い指標です。各conditionを同じ高さで並べ、時点数の差を隠さず比較します。",
                    "Lower RMSE is better. Conditions are given equal visual height so differences in time-point counts do not dominate."
                )
            )

            Chart(conditionChartData, id: \.id) { item in
                BarMark(
                    x: .value("RMSE", item.value),
                    y: .value("Condition", item.condition)
                )
                .position(by: .value("Comparator", comparatorTitle(item.comparator)))
                .foregroundStyle(by: .value("Comparator", comparatorTitle(item.comparator)))
            }
            .chartXAxisLabel("RMSE (pp) · " + language.text("小さいほど良い", "lower is better"))
            .chartLegend(position: .top, alignment: .leading)
            .frame(height: 410)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(language.text("condition別RMSE比較", "RMSE comparison by condition"))
            .accessibilityValue(conditionChartSummaryAccessibilityValue)
            .accessibilityIdentifier("experiment.fick-validation.condition-chart")

            DisclosureGroup(isExpanded: $isConditionValuesExpanded) {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(diagnostics.conditions) { audit in
                        conditionValueRow(audit)
                    }
                }
                .padding(.top, 8)
            } label: {
                Label(
                    language.text(
                        "condition別の数値を読む（\(diagnostics.conditions.count)件）",
                        "Read values for each condition (\(diagnostics.conditions.count))"
                    ),
                    systemImage: "list.bullet.rectangle"
                )
                .font(.callout.weight(.semibold))
            }

            Text(language.text(
                "Fick勝ち \(fickWins)/\(diagnostics.conditions.count)。condition別R² ≥ \(format(result.configuration.targetRSquared)) は \(targetWins)/\(defined.count)（1点だけのconditionはR²未定義）。",
                "Fick has lower RMSE in \(fickWins)/\(diagnostics.conditions.count) conditions. Condition-level R² is at least \(format(result.configuration.targetRSquared)) in \(targetWins)/\(defined.count); R² is undefined for a one-point condition."
            ))
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(16)
        .labCard()
    }

    private func conditionValueRow(_ audit: FickValidationConditionAudit) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(shortCondition(audit.condition))
                .font(.callout.weight(.semibold))
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 14) {
                    Text("Fick RMSE \(format(audit.fickMetric.rmse)) pp")
                    Text("Control RMSE \(format(audit.controlMetric.rmse)) pp")
                    Text("Fick R² \(format(audit.fickMetric.rSquared)) · \(conditionTargetStatus(audit))")
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text("Fick RMSE \(format(audit.fickMetric.rmse)) pp")
                    Text("Control RMSE \(format(audit.controlMetric.rmse)) pp")
                    Text("Fick R² \(format(audit.fickMetric.rSquared)) · \(conditionTargetStatus(audit))")
                }
            }
            .font(.caption.monospacedDigit())
            .foregroundStyle(.secondary)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(LabTheme.tile(colorScheme), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            shortCondition(audit.condition) + ". " + conditionRowAccessibilityValue(audit)
        )
        .accessibilityValue(conditionRowAccessibilityValue(audit))
        .accessibilityIdentifier("experiment.fick-validation.condition-value")
    }

    private var hierarchyCard: some View {
        let allSourcesExplicit = diagnostics.hierarchy.totalRowCount > 0
            && diagnostics.hierarchy.rawReferencedRowCount == diagnostics.hierarchy.totalRowCount
        return VStack(alignment: .leading, spacing: 12) {
            sectionHeading(
                language.text("独立した実験単位を識別できるか", "Can independent experimental units be identified?"),
                language.text(
                    "同じ曲線の時点を独立データとして数えないため、run・curve・donor・batch・site IDが必要です。",
                    "Run, curve, donor, batch, and site IDs are needed so repeated time points from one curve are not counted as independent data."
                )
            )

            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 205), spacing: 10)],
                alignment: .leading,
                spacing: 10
            ) {
                hierarchyTile(
                    title: language.text("source（明示）", "Source (explicit)"),
                    value: "\(diagnostics.hierarchy.rawReferencedRowCount)/\(diagnostics.hierarchy.totalRowCount)",
                    available: allSourcesExplicit,
                    detail: allSourcesExplicit
                        ? language.text("全rowで明示", "Explicit for every row")
                        : language.text("merged cell補完は探索的", "Merged-cell fill is heuristic")
                )
                hierarchyTile(title: "experiment_run_id", value: availabilityValue(diagnostics.hierarchy.hasExperimentRunID), available: diagnostics.hierarchy.hasExperimentRunID, detail: language.text("独立run", "Independent run"))
                hierarchyTile(title: "permeation_curve_id", value: availabilityValue(diagnostics.hierarchy.hasPermeationCurveID), available: diagnostics.hierarchy.hasPermeationCurveID, detail: language.text("時系列curve", "Time-series curve"))
                hierarchyTile(title: "donor_id", value: availabilityValue(diagnostics.hierarchy.hasDonorID), available: diagnostics.hierarchy.hasDonorID, detail: language.text("皮膚donor", "Skin donor"))
                hierarchyTile(title: "skin/mn_batch_id", value: availabilityValue(diagnostics.hierarchy.hasBatchID), available: diagnostics.hierarchy.hasBatchID, detail: language.text("製造・組織batch", "Manufacturing/tissue batch"))
                hierarchyTile(title: "site_id", value: availabilityValue(diagnostics.hierarchy.hasSiteID), available: diagnostics.hierarchy.hasSiteID, detail: language.text("施設間移送", "Across-site transport"))
            }

            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                    .accessibilityHidden(true)
                Text(sourceFamilyRelationshipText)
                .font(.caption)
                .fixedSize(horizontal: false, vertical: true)
            }

            Button {
                copyRequiredIDs()
            } label: {
                Label(
                    copiedRequiredIDs
                        ? language.text("必須IDをコピーしました", "Required IDs copied")
                        : language.text("次回収集する必須IDをコピー", "Copy required IDs for the next study"),
                    systemImage: copiedRequiredIDs ? "checkmark" : "doc.on.doc"
                )
            }
            .accessibilityIdentifier("experiment.fick-validation.external-template")
        }
        .padding(16)
        .labCard()
    }

    private var influenceCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeading(
                language.text("1つのfamilyを外すと結論は変わるか", "Does the conclusion change when one family is removed?"),
                language.text(
                    "これは因果効果ではなく、既存OOF予測の構成感度です。点がR² = \(format(result.configuration.targetRSquared)) 線をまたぐ場合、全体値は構成に敏感です。",
                    "This is composition sensitivity of fixed OOF predictions, not a causal effect. Crossing the R² = \(format(result.configuration.targetRSquared)) line indicates that the pooled result is composition-sensitive."
                )
            )

            Chart(diagnostics.familyInfluence) { item in
                if let value = item.rowPooledRSquaredWithoutFamily {
                    BarMark(
                        x: .value("R squared", value),
                        y: .value("Excluded family", shortFamily(item.family))
                    )
                    .foregroundStyle(value >= result.configuration.targetRSquared ? Color.accentColor.gradient : Color.orange.gradient)
                    .annotation(position: .trailing, alignment: .leading) {
                        Text(format(value)).font(.caption.monospacedDigit())
                    }
                    RuleMark(x: .value("Target", result.configuration.targetRSquared))
                        .foregroundStyle(Color.red.opacity(0.7))
                        .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                }
            }
            .chartXScale(domain: rSquaredDomain(
                diagnostics.familyInfluence.compactMap { finite($0.rowPooledRSquaredWithoutFamily) }
            ))
            .chartXAxisLabel("R²")
            .frame(height: 175)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(language.text("family除外感度", "Family-exclusion sensitivity"))
            .accessibilityValue(familyInfluenceAccessibilityValue)
            .accessibilityIdentifier("experiment.fick-validation.influence-chart")
        }
        .padding(16)
        .labCard()
    }

    private var publicationClaimCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeading(
                language.text("現時点で安全な論文表現", "Publication wording supported at present"),
                language.text(
                    "数値と限界を同じ段落に残します。「R² ≥ \(format(result.configuration.targetRSquared)) を確認した」と短縮しないでください。",
                    "Keep the number and its limitations in the same paragraph. Do not shorten this to ‘confirmed R² ≥ \(format(result.configuration.targetRSquared)).’"
                )
            )

            Text(safeClaim)
                .font(.callout)
                .textSelection(.enabled)
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(LabTheme.tile(colorScheme), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

            Button {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(safeClaim, forType: .string)
                copiedClaim = true
            } label: {
                Label(
                    copiedClaim
                        ? language.text("コピーしました", "Copied")
                        : language.text("この表現をコピー", "Copy this wording"),
                    systemImage: copiedClaim ? "checkmark" : "doc.on.doc"
                )
            }
            .accessibilityIdentifier("experiment.fick-validation.claim-copy")
        }
        .padding(16)
        .labCard()
    }

    private func sectionHeading(_ title: String, _ caption: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.title3.bold())
            Text(caption)
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func summary(_ comparator: FickValidationComparator) -> FickValidationComparatorSummary? {
        diagnostics.comparatorSummaries.first { $0.comparator == comparator }
    }

    private var aggregationData: [AggregationDatum] {
        diagnostics.comparatorSummaries.flatMap { summary in
            let values: [(String, Double?)] = [
                (language.text("row-pooled", "Row-pooled"), summary.rowPooledMetric.rSquared),
                (language.text("condition等重み", "Condition-balanced"), summary.conditionBalancedMetric.rSquared),
                (language.text("family内中心化", "Family-centered"), summary.familyCenteredRSquared),
                (language.text("macro-family", "Macro-family"), summary.macroFamilyRSquared),
            ]
            return values.compactMap { item -> AggregationDatum? in
                guard let value = finite(item.1) else { return nil }
                return AggregationDatum(
                    id: "\(summary.comparator.rawValue)|\(item.0)",
                    metric: item.0,
                    comparator: summary.comparator,
                    value: value
                )
            }
        }
    }

    private var undefinedAggregationLabels: [String] {
        diagnostics.comparatorSummaries.flatMap { summary -> [String] in
            let values: [(String, Double?)] = [
                (language.text("row-pooled", "Row-pooled"), summary.rowPooledMetric.rSquared),
                (language.text("condition等重み", "Condition-balanced"), summary.conditionBalancedMetric.rSquared),
                (language.text("family内中心化", "Family-centered"), summary.familyCenteredRSquared),
                (language.text("macro-family", "Macro-family"), summary.macroFamilyRSquared),
            ]
            return values.compactMap { label, value in
                finite(value) == nil
                    ? "\(comparatorTitle(summary.comparator)) / \(label)"
                    : nil
            }
        }
    }

    private var aggregationDomain: ClosedRange<Double> {
        rSquaredDomain(aggregationData.map(\.value))
    }

    private var calibrationPoints: [CalibrationPoint] {
        switch selectedComparator {
        case .fickProxy:
            result.predictions.map {
                CalibrationPoint(
                    id: $0.id,
                    observed: $0.observedPercentage,
                    predicted: $0.predictedPercentage
                )
            }
        case .familyTimeControl:
            diagnostics.baselinePredictions.map {
                CalibrationPoint(
                    id: $0.id,
                    observed: $0.observedPercentage,
                    predicted: $0.predictedPercentage
                )
            }
        }
    }

    private var calibrationDomain: ClosedRange<Double> {
        let values = calibrationPoints.flatMap { [$0.predicted, $0.observed] }
            .filter(\.isFinite)
        guard let minimum = values.min(), let maximum = values.max() else {
            return 0...1
        }
        let rawLower = min(0, minimum)
        let rawUpper = max(0, maximum)
        let span = max(1, rawUpper - rawLower)
        let padding = max(1, span * 0.05)
        let lower = rawLower < 0 ? rawLower - padding : 0
        return lower...(rawUpper + padding)
    }

    private struct ConditionChartDatum: Identifiable {
        let id: String
        let condition: String
        let comparator: FickValidationComparator
        let value: Double
    }

    private var conditionChartData: [ConditionChartDatum] {
        diagnostics.conditions.flatMap { audit in
            let title = shortCondition(audit.condition)
            return [
                ConditionChartDatum(
                    id: audit.id + "|fick",
                    condition: title,
                    comparator: .fickProxy,
                    value: audit.fickMetric.rmse
                ),
                ConditionChartDatum(
                    id: audit.id + "|control",
                    condition: title,
                    comparator: .familyTimeControl,
                    value: audit.controlMetric.rmse
                ),
            ]
        }
    }

    /// Internal so regression tests can ensure unverified local filenames never
    /// enter copy-ready manuscript wording.
    var safeClaim: String {
        let model = summary(.fickProxy)
        let control = summary(.familyTimeControl)
        let auditedDatasetID = String(result.dataset.normalizedSHA256.prefix(12))
        let finiteFamilyValues = diagnostics.recomputedFamilyMetrics.compactMap {
            finite($0.metric.rSquared)
        }
        let familyFloor = finiteFamilyValues.count == diagnostics.recomputedFamilyMetrics.count
            ? finiteFamilyValues.min() : nil
        return language.text(
            "科学的妥当性未検証のユーザー提供dataset（normalized SHA-256 \(auditedDatasetID)…）に対する計算監査済みの事後的部分解析で、\(result.eligibleFamilyCount) family・\(result.eligibleConditionCount) proxy condition・\(result.eligibleObservationCount) time-point rowsを用いたFick proxyのrow-pooled OOF R²は\(format(model?.rowPooledMetric.rSquared))だった。ただし独立外部検証ではなく、最小family別R²は\(format(familyFloor))で、同一foldのtraining rowsだけから作成した単純family-time controlのR²は\(format(control?.rowPooledMetric.rSquared))だった。",
            "In a computation-audited post hoc subset analysis of a user-provided dataset whose scientific validity has not been established (normalized SHA-256 \(auditedDatasetID)…), the row-pooled OOF R² of the Fick proxy was \(format(model?.rowPooledMetric.rSquared)) across \(result.eligibleFamilyCount) families, \(result.eligibleConditionCount) proxy conditions, and \(result.eligibleObservationCount) time-point rows. This was not an independent external validation; the minimum family-level R² was \(format(familyFloor)), and the R² of a simple family-time control built only from training rows in the same folds was \(format(control?.rowPooledMetric.rSquared))."
        )
    }

    private var sourceFamilyRelationshipText: String {
        let hierarchy = diagnostics.hierarchy
        let exactConfounding = result.eligibleFamilyCount > 0
            && hierarchy.eligibleFamilySourceConfoundedCount == result.eligibleFamilyCount
            && hierarchy.eligibleSourceCount == result.eligibleFamilyCount
        if exactConfounding {
            let sourceSummary = hierarchy.canonicalMergedCellForwardFillApplied
                ? language.text(
                    "source空欄のmerged-cell補完後は\(hierarchy.sourceBlockCount) blockに見えます。",
                    "Merged-cell filling of blank source cells yields \(hierarchy.sourceBlockCount) apparent blocks."
                )
                : language.text(
                    "明示sourceから\(hierarchy.sourceBlockCount) groupを識別しました。",
                    "Explicit source values identify \(hierarchy.sourceBlockCount) groups."
                )
            return sourceSummary + language.text(
                "主評価の\(hierarchy.eligibleSourceCount) sourceと\(result.eligibleFamilyCount) familyは1対1に完全交絡しているため、独立source検証とは扱いません。",
                " The \(hierarchy.eligibleSourceCount) sources and \(result.eligibleFamilyCount) families in the primary analysis are completely confounded one-to-one, so this is not independent-source validation."
            )
        }
        return language.text(
            "主評価で解決できたsourceは\(hierarchy.eligibleSourceCount)、familyは\(result.eligibleFamilyCount)です。1つの専属sourceと1対1に交絡するfamilyは\(hierarchy.eligibleFamilySourceConfoundedCount)/\(result.eligibleFamilyCount)であり、独立source検証は確認できません。",
            "The primary analysis resolves \(hierarchy.eligibleSourceCount) sources across \(result.eligibleFamilyCount) families. \(hierarchy.eligibleFamilySourceConfoundedCount)/\(result.eligibleFamilyCount) families map one-to-one to a single exclusive source; independent-source validation is not established."
        )
    }

    private func hierarchyTile(
        title: String,
        value: String,
        available: Bool,
        detail: String
    ) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: available ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundStyle(available ? .green : .orange)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.callout.weight(.semibold)).monospaced()
                Text(value).font(.headline.monospacedDigit())
                Text(detail).font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(11)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(LabTheme.tile(colorScheme), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    private func availabilityValue(_ available: Bool) -> String {
        language.text(available ? "あり" : "なし", available ? "Available" : "Missing")
    }

    private func copyRequiredIDs() {
        let text = [
            "study_id", "site_id", "experiment_run_id", "permeation_curve_id",
            "replicate_id", "donor_id", "skin_batch_id", "mn_batch_id",
            "drug_id", "source_doi", "source_table_or_figure",
        ].joined(separator: ",")
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        copiedRequiredIDs = true
    }

    private func comparatorTitle(_ comparator: FickValidationComparator) -> String {
        switch comparator {
        case .fickProxy: language.text("Fick proxy", "Fick proxy")
        case .familyTimeControl: language.text("単純対照", "Simple control")
        }
    }

    private func gateTitle(_ id: String) -> String {
        switch id {
        case "calculation-completed": language.text("独立再計算とデータ整合", "Independent replay and data integrity")
        case "row-pooled-point": language.text("row-pooled点推定", "Row-pooled point estimate")
        case "aggregation-robustness": language.text("集約方法に対する頑健性", "Robustness to aggregation")
        case "simple-baseline": language.text(
            "探索的simple-control比較",
            "Exploratory simple-control comparison"
        )
        case "every-family": language.text(
            "全familyでR² ≥ \(format(result.configuration.targetRSquared))",
            "R² ≥ \(format(result.configuration.targetRSquared)) in every family"
        )
        case "independent-run-curve": language.text("独立run・curve単位", "Independent run and curve units")
        case "external-confirmation": language.text("凍結モデルの独立外部検証", "Independent external validation of a frozen model")
        default: id
        }
    }

    private func gateExplanation(_ id: String) -> String {
        switch id {
        case "calculation-completed": language.text(
            "全foldを再fitし、A・k・SSE・全予測・percentileを照合",
            "Refits every fold and checks A, k, SSE, every prediction, and percentiles"
        )
        case "row-pooled-point": language.text(
            "\(result.eligibleObservationCount)時点rowを等重みで集約",
            "\(result.eligibleObservationCount) time-point rows receive equal weight"
        )
        case "aggregation-robustness": language.text("condition・familyを等しく扱っても維持", "Must persist when conditions and families receive balanced weight")
        case "simple-baseline": language.text(
            "監査時追加の対照。劣れば未達、改善しても事前封印marginなしでは未確認",
            "Audit-added control: worse is not met; improvement remains unconfirmed without a prespecified sealed margin"
        )
        case "every-family": language.text("特定family間の水準差に依存しない", "Avoids relying on level differences among selected families")
        case "independent-run-curve": language.text("反復時点を独立例として数えない", "Does not count repeated time points as independent cases")
        case "external-confirmation": language.text("開発データと異なる新規データで一度だけ評価", "Evaluate once on new data separate from development")
        default: ""
        }
    }

    private func gateStatusText(_ gate: FickValidationEvidenceGate) -> String {
        switch gate.status {
        case .met:
            gate.id == "row-pooled-point"
                ? language.text("点推定が閾値超過（探索的）", "Point above threshold (exploratory)")
                : language.text("確認", "Checked")
        case .notMet: language.text("未達", "Not met")
        case .unavailable: language.text("未検証", "Not tested")
        }
    }

    private func gateSymbol(_ status: FickValidationGateStatus) -> String {
        switch status {
        case .met: "checkmark.circle.fill"
        case .notMet: "xmark.circle.fill"
        case .unavailable: "questionmark.circle.fill"
        }
    }

    private func gateColor(_ gate: FickValidationEvidenceGate) -> Color {
        if gate.id == "row-pooled-point", gate.status == .met {
            return .orange
        }
        switch gate.status {
        case .met: return .green
        case .notMet: return .orange
        case .unavailable: return .secondary
        }
    }

    private func gateValue(_ id: String, value: Double) -> String {
        if id == "calculation-completed" { return "n = \(Int(value))" }
        if id == "simple-baseline" { return "ΔR² " + signed(value) }
        return "R² " + format(value)
    }

    private func measuredAccessibility(_ gate: FickValidationEvidenceGate) -> String {
        guard let value = gate.measuredValue else { return "" }
        return ", " + gateValue(gate.id, value: value)
    }

    private func shortFamily(_ family: FickValidationFamily) -> String {
        "\(family.drugName) · S\(family.skinCode) · MN\(family.needleTypeCode)"
    }

    private func shortCondition(_ condition: FickValidationCondition) -> String {
        "\(condition.family.drugName) · \(format(condition.loading))µg · \(format(condition.needleLength))mm · A\(format(condition.surfaceArea))"
    }

    private func finite(_ value: Double?) -> Double? {
        guard let value, value.isFinite else { return nil }
        return value
    }

    private func rSquaredDomain(_ values: [Double]) -> ClosedRange<Double> {
        let finiteValues = values.filter(\.isFinite) + [result.configuration.targetRSquared]
        let rawLower = min(0, finiteValues.min() ?? 0)
        let rawUpper = max(0, finiteValues.max() ?? 0)
        let span = max(0.1, rawUpper - rawLower)
        let padding = span * 0.08
        let lower = rawLower < 0 ? rawLower - padding : 0
        return lower...(rawUpper + padding)
    }

    private func format(_ value: Double?) -> String {
        guard let value, value.isFinite else { return language.text("未定義", "Undefined") }
        return value.formatted(.number.precision(.fractionLength(3)))
    }

    private func signed(_ value: Double) -> String {
        let sign = value >= 0 ? "+" : ""
        return sign + value.formatted(.number.precision(.fractionLength(3)))
    }

    private func signedOptional(_ value: Double?) -> String {
        guard let value = finite(value) else { return language.text("未定義", "Undefined") }
        return signed(value)
    }

    private func percent(_ value: Double) -> String {
        value.formatted(.percent.precision(.fractionLength(1)))
    }

    private var coverageAccessibilityValue: String {
        coverageData.map { "\($0.title) \($0.included) of \($0.total)" }
            .joined(separator: "; ")
    }

    private var aggregationAccessibilityValue: String {
        aggregationData.map {
            "\(comparatorTitle($0.comparator)) \($0.metric) \(format($0.value))"
        }.joined(separator: "; ")
    }

    private var conditionChartSummaryAccessibilityValue: String {
        let defined = diagnostics.conditions.filter { $0.fickMetric.rSquared != nil }
        let targetWins = defined.filter { $0.fickRSquaredMeetsTarget == true }.count
        let fickWins = diagnostics.conditions.filter(\.fickWinsRMSE).count
        return language.text(
            "\(diagnostics.conditions.count) condition中、FickのRMSEが低いのは\(fickWins)。定義可能な\(defined.count) conditionのうちR² ≥ \(format(result.configuration.targetRSquared)) は\(targetWins)。",
            "Fick has lower RMSE in \(fickWins) of \(diagnostics.conditions.count) conditions. R² is at least \(format(result.configuration.targetRSquared)) in \(targetWins) of \(defined.count) conditions where it is defined."
        )
    }

    private func conditionTargetStatus(_ audit: FickValidationConditionAudit) -> String {
        switch audit.fickRSquaredMeetsTarget {
        case true:
            language.text("この条件の点推定のみ0.85以上", "point estimate at least 0.85 for this condition only")
        case false:
            language.text("目標未達", "target not met")
        case nil:
            language.text("R²未定義", "R² undefined")
        }
    }

    private func conditionRowAccessibilityValue(_ audit: FickValidationConditionAudit) -> String {
        language.text(
            "Fick RMSE \(format(audit.fickMetric.rmse)) pp、control RMSE \(format(audit.controlMetric.rmse)) pp、Fick R² \(format(audit.fickMetric.rSquared))、\(conditionTargetStatus(audit))",
            "Fick RMSE \(format(audit.fickMetric.rmse)) pp, Control RMSE \(format(audit.controlMetric.rmse)) pp, Fick R² \(format(audit.fickMetric.rSquared)), \(conditionTargetStatus(audit))"
        )
    }

    private var familyInfluenceAccessibilityValue: String {
        diagnostics.familyInfluence.compactMap { item in
            item.rowPooledRSquaredWithoutFamily.map {
                "\(shortFamily(item.family)) excluded, R squared \(format($0))"
            }
        }.joined(separator: "; ")
    }
}
