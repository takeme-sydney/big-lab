import Charts
import SwiftUI

struct ModelEvidenceView: View {
    let language: AppLanguage

    private let modelDomain = ModelKind.allCases.map(\.rawValue)

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                LabWorkspaceHeader(
                    title: language.text("モデル評価", "Model evidence"),
                    subtitle: language.text(
                        "4モデルの報告性能・重要パラメータ・物理感度を分けて比較",
                        "Compare reported performance, important features, and physical sensitivity separately"
                    ),
                    systemImage: "chart.bar.xaxis"
                )

                LabNotice(
                    title: language.text("重要な変更", "Scientific integrity update"),
                    message: language.text(
                        "旧版の曲線は原著モデルではない独自式でした。本版では誤認を避けるため削除し、原著Table 4の転記値とData S1の実測値だけを可視化します。",
                        "The previous curves came from undocumented surrogate equations, not the published models. They have been removed; this version visualizes only transcribed Table 4 metrics and observed Data S1 values."
                    ),
                    kind: .information
                )

                percentageReproductionSection
                methodComparisonSection

                VStack(alignment: .leading, spacing: 6) {
                    Text(language.text("4モデルの報告性能", "Reported performance of four models"))
                        .font(.title2.bold())
                    Text(
                        language.text(
                            "原著Table 4 · 191点・6薬物 · 7:3ランダム分割。4パネルは単位と良い方向が異なるため、別々の尺度で表示します。",
                            "Paper Table 4 · 191 points across six drugs · random 7:3 split. The four panels use separate scales because their units and preferred directions differ."
                        )
                    )
                    .font(.callout)
                    .foregroundStyle(.secondary)
                }

                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 430), spacing: 20)],
                    alignment: .leading,
                    spacing: 20
                ) {
                    ForEach(Outcome.allCases) { selectedOutcome in
                        rmseChart(for: selectedOutcome)
                        rSquaredChart(for: selectedOutcome)
                    }
                }
                .accessibilityIdentifier("evidence.performance-panels")

                LabSection(language.text("Table 4 数値比較", "Table 4 values")) {
                    reportedMetricsTable
                }
                .accessibilityIdentifier("evidence.metrics-table")

                LabSection(language.text("原著が報告した順位", "Ranking reported by the paper")) {
                    LazyVGrid(
                        columns: [GridItem(.adaptive(minimum: 240), spacing: 18)],
                        alignment: .leading,
                        spacing: 18
                    ) {
                        evidencePoint(
                            icon: "1.circle.fill",
                            title: "XGBoost",
                            text: language.text(
                                "原著のランダム分割内で、量・率の両方が最良。",
                                "Best for both amount and percentage within the paper's random split."
                            )
                        )
                        evidencePoint(
                            icon: "2.circle.fill",
                            title: language.text("次点", "Runner-up"),
                            text: language.text(
                                "透過量はFick、透過率はRandom Forest。",
                                "Fick for amount; Random Forest for percentage."
                            )
                        )
                        evidencePoint(
                            icon: "exclamationmark.arrow.triangle.2.circlepath",
                            title: language.text("未知薬物", "Unseen drugs"),
                            text: language.text(
                                "薬物を丸ごと除外した補足検証では大きく逸脱。",
                                "Leave-one-drug-out supplementary tests showed large deviations."
                            )
                        )
                    }
                }

                featureImportanceSection
                fickSensitivitySection

                LabNotice(
                    title: language.text("Table 4の整合性監査", "Table 4 consistency audit"),
                    message: language.text(
                        "値は原著から正確に転記されていますが、式(7)のRMSE・式(8)のR²・Data S1の全範囲を同時に使うと数学的に整合しません。例：透過量の実測範囲は1.05–29,009.79 µg/cm²で、XGBoost RMSE 4,447.23ならR²の理論上限は約0.906ですが、表は0.98です。公開補足には分割済みtrain/testや予測出力がなく再計算できません。したがって「報告値」であり、独立検証済みの性能とは扱いません。",
                        "The values are transcribed correctly, but Equation (7) RMSE, Equation (8) R², and the full Data S1 range cannot all hold simultaneously. For example, observed amount spans 1.05–29,009.79 µg/cm²; with XGBoost RMSE 4,447.23, the theoretical upper bound for R² is about 0.906, yet Table 4 reports 0.98. The released supplements omit the split train/test files and prediction outputs, so the metrics cannot be recomputed. Treat them as reported, not independently verified performance."
                    ),
                    kind: .warning
                )

                LabNotice(
                    title: language.text("適用範囲", "Scope"),
                    message: language.text(
                        "191点・6薬物の7:3ランダム分割は、同じ薬物・近い条件への補間を主に評価します。新規薬物、臨床投与、用量決定への外挿には使えません。R² = 0.98は正解率ではありません。",
                        "A random 7:3 split of 191 points across six drugs mainly evaluates interpolation among known drugs and nearby conditions. It does not support extrapolation to new drugs, clinical delivery, or dose decisions. R² = 0.98 is not 98% accuracy."
                    ),
                    kind: .limitation
                )
            }
            .frame(maxWidth: LabTheme.contentWidth, alignment: .leading)
            .padding(LabTheme.pagePadding)
            .frame(maxWidth: .infinity, alignment: .top)
        }
        .accessibilityIdentifier("screen.model-evidence")
    }

    private var percentageReproductionSection: some View {
        LabSection(language.text(
            "透過率をどの程度再現できたと報告されたか",
            "How much permeation-percentage variation was reported as reproduced?"
        )) {
            VStack(alignment: .leading, spacing: 16) {
                Text(language.text(
                    "原著Table 4の透過率R²を100倍し、分散説明率として読みやすく表示します。例えばR² = 0.98は、原著の評価分割内で観測された透過率のばらつきの98%をモデルが説明した、という報告です。個々の予測が98%正解という意味ではありません。",
                    "The percentage-permeation R² values from Table 4 are multiplied by 100 and shown as reported explained variation. For example, R² = 0.98 reports that the model explained 98% of the observed percentage variation within the paper's evaluation split. It does not mean that individual predictions were 98% accurate."
                ))
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 230), spacing: 16)],
                    alignment: .leading,
                    spacing: 16
                ) {
                    ForEach(PaperMetric.comparisonOrder) { metric in
                        percentageReproductionCard(metric)
                    }
                }

                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "function")
                        .foregroundStyle(.tint)
                        .accessibilityHidden(true)
                    Text(language.text(
                        "読み方：R² × 100 = 報告された分散説明率。RMSEは予測と実測の典型的なずれを透過率ポイントで示し、小さいほど良好です。両方を一緒に比較してください。",
                        "How to read this: R² × 100 = reported explained variation. RMSE describes typical prediction error in percentage points; lower is better. Compare both metrics together."
                    ))
                    .font(.callout)
                    .fixedSize(horizontal: false, vertical: true)
                }
                .padding(14)
                .background(Color.accentColor.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))

                Label(
                    language.text(
                        "原著報告値・独立再現未了：分割済みデータと予測出力が公開されていないため、このアプリでは再計算していません。",
                        "Paper-reported, not independently reproduced: this app cannot recompute the values because split data and prediction outputs were not released."
                    ),
                    systemImage: "exclamationmark.shield"
                )
                .font(.caption)
                .foregroundStyle(.orange)
                .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityIdentifier("evidence.percentage-reproduction")
    }

    private func percentageReproductionCard(_ metric: PaperMetric) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Label {
                    Text(metric.model.rawValue).font(.headline)
                } icon: {
                    Circle().fill(metric.model.color).frame(width: 10, height: 10)
                }
                Spacer(minLength: 8)
                Text(metric.percentageExplainedVariation.formatted(.number.precision(.fractionLength(0))) + "%")
                    .font(.system(size: 30, weight: .semibold, design: .rounded))
                    .monospacedDigit()
            }

            ProgressView(value: metric.percentageR2, total: 1)
                .tint(metric.model.color)
                .accessibilityHidden(true)

            Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 5) {
                GridRow {
                    Text("R²")
                    Text(metric.percentageR2.formatted(.number.precision(.fractionLength(2))))
                        .monospacedDigit()
                }
                GridRow {
                    Text(language.text("RMSE", "RMSE"))
                    Text(metric.percentageRMSE.formatted(.number.precision(.fractionLength(2))) + " pt")
                        .monospacedDigit()
                }
                GridRow {
                    Text(language.text("未説明", "Unexplained"))
                    Text(metric.percentageUnexplainedVariation.formatted(.number.precision(.fractionLength(0))) + "%")
                        .monospacedDigit()
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            Divider()
            Text(percentageInterpretation(for: metric.model))
                .font(.caption)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .labCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel(language.text(
            "\(metric.model.rawValue)。報告された透過率の分散説明率\(metric.percentageExplainedVariation.formatted(.number.precision(.fractionLength(0))))%。RMSE \(metric.percentageRMSE.formatted(.number.precision(.fractionLength(2))))ポイント。",
            "\(metric.model.rawValue). Reported percentage-permeation explained variation \(metric.percentageExplainedVariation.formatted(.number.precision(.fractionLength(0))))%. RMSE \(metric.percentageRMSE.formatted(.number.precision(.fractionLength(2)))) points."
        ))
        .accessibilityIdentifier("evidence.percentage-reproduction.\(metric.model.rawValue.lowercased().replacingOccurrences(of: " ", with: "-"))")
    }

    private func percentageInterpretation(for model: ModelKind) -> String {
        switch model {
        case .fick:
            language.text(
                "物理則だけで比較的多くのばらつきを捉えましたが、点ごとの誤差はRF・XGBoostより大きい報告です。",
                "The physical model captured substantial variation, but its point-level error was reported as larger than RF and XGBoost."
            )
        case .mlr:
            language.text(
                "直線的な関係だけでは捉えにくく、4手法中で説明率が最も低くRMSEが最も大きい報告です。",
                "Linear relationships alone captured less of the pattern; this method had the lowest explained variation and largest RMSE."
            )
        case .rf:
            language.text(
                "非線形な条件の組み合わせを捉え、XGBoostに次ぐ高い説明率と低いRMSEが報告されました。",
                "It captured nonlinear combinations of conditions and was reported second to XGBoost in explained variation and RMSE."
            )
        case .xgboost:
            language.text(
                "4手法中で説明率が最も高くRMSEが最も小さいため、原著では透過率予測の最良モデルとされました。",
                "It had the highest explained variation and lowest RMSE, so the paper ranked it best for percentage prediction."
            )
        }
    }

    private var methodComparisonSection: some View {
        LabSection(language.text("4手法の違い", "How the four methods differ")) {
            VStack(alignment: .leading, spacing: 14) {
                Text(language.text(
                    "4手法は同じ透過量・透過率を目標にしますが、Fickは物理パラメータと拡散則、他の3手法は7特徴量と実測値から学んだ関係を使います。「考え方 → モデルの形 → 1件の予測」の順に読むと違いが分かります。",
                    "All four target the same permeation amount or percentage. Fick uses physical parameters and diffusion laws; the other three use relationships learned from seven features and observations. Read each card as intuition → model form → one prediction."
                ))
                .font(.callout)
                .foregroundStyle(.secondary)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 300), spacing: 16)], spacing: 16) {
                    ForEach(MethodComparison.paperMethods) { method in
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Circle().fill(method.model.color).frame(width: 10, height: 10)
                                Text(method.model.rawValue).font(.title3.bold())
                            }
                            comparisonRow(language.text("分類", "Type"), method.category.resolve(language))
                            comparisonRow(language.text("考え方", "Intuition"), method.mechanism.resolve(language))
                            comparisonRow(language.text("モデルの形", "Model form"), method.modelForm.resolve(language))
                            comparisonRow(language.text("1件の予測", "One prediction"), method.prediction.resolve(language))
                            comparisonRow(language.text("学習", "Training"), method.training.resolve(language))
                            comparisonRow(language.text("強み", "Strength"), method.strength.resolve(language))
                            comparisonRow(language.text("限界", "Limitation"), method.limitation.resolve(language))
                            comparisonRow(language.text("解釈の注意", "Interpretation caution"), method.interpretation.resolve(language))
                        }
                        .padding(16)
                        .labCard()
                        .accessibilityElement(children: .combine)
                        .accessibilityIdentifier("evidence.method.\(method.model.rawValue.lowercased().replacingOccurrences(of: " ", with: "-"))")
                    }
                }
            }
        }
        .accessibilityIdentifier("evidence.method-comparison")
    }

    private func comparisonRow(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label.uppercased())
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.callout)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func rmseChart(for outcome: Outcome) -> some View {
        metricChartCard(
            title: language.text(
                "\(outcome.displayName(language)) · RMSE\n（小さいほど良い）",
                "\(outcome.displayName(language)) · RMSE\n(lower is better)"
            ),
            caption: outcome.rmseUnit(language),
            identifier: "evidence.\(outcome.identifierComponent).rmse-chart"
        ) {
            Chart(PaperMetric.comparisonOrder) { metric in
                BarMark(
                    x: .value("RMSE", metric.rmse(for: outcome)),
                    y: .value("Model", metric.model.rawValue)
                )
                .foregroundStyle(metric.model.color)
                .annotation(position: .trailing, alignment: .leading) {
                    Text(metric.rmse(for: outcome).formatted(.number.precision(.fractionLength(2))))
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.primary)
                }
            }
            .chartXScale(domain: 0...rmseMaximum(for: outcome))
            .chartYScale(domain: modelDomain)
            .chartLegend(.hidden)
            .accessibilityLabel(
                language.text(
                    "原著Table 4の\(outcome.displayName(language))RMSE、Fick、MLR、Random Forest、XGBoostの比較",
                    "Table 4 \(outcome.displayName(language)) RMSE for Fick, MLR, Random Forest, and XGBoost"
                )
            )
        }
    }

    private func rSquaredChart(for outcome: Outcome) -> some View {
        metricChartCard(
            title: language.text(
                "\(outcome.displayName(language)) · R²\n（1に近いほど良い）",
                "\(outcome.displayName(language)) · R²\n(closer to 1 is better)"
            ),
            caption: language.text("単位なし。正解率ではありません。", "Unitless; this is not accuracy."),
            identifier: "evidence.\(outcome.identifierComponent).r2-chart"
        ) {
            Chart(PaperMetric.comparisonOrder) { metric in
                BarMark(
                    x: .value("R squared", metric.rSquared(for: outcome)),
                    y: .value("Model", metric.model.rawValue)
                )
                .foregroundStyle(metric.model.color)
                .annotation(position: .trailing, alignment: .leading) {
                    Text(metric.rSquared(for: outcome).formatted(.number.precision(.fractionLength(2))))
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.primary)
                }
            }
            .chartXScale(domain: 0...1.10)
            .chartYScale(domain: modelDomain)
            .chartLegend(.hidden)
            .accessibilityLabel(
                language.text(
                    "原著Table 4の\(outcome.displayName(language))R二乗、Fick、MLR、Random Forest、XGBoostの比較",
                    "Table 4 \(outcome.displayName(language)) R-squared for Fick, MLR, Random Forest, and XGBoost"
                )
            )
        }
    }

    private var reportedMetricsTable: some View {
        Grid(alignment: .leading, horizontalSpacing: 18, verticalSpacing: 12) {
            GridRow {
                Text(language.text("モデル", "Model")).bold()
                Text(language.text("量 RMSE", "Amount RMSE")).bold()
                Text(language.text("量 R²", "Amount R²")).bold()
                Text(language.text("率 RMSE", "Percent RMSE")).bold()
                Text(language.text("率 R²", "Percent R²")).bold()
            }
            Divider().gridCellColumns(5)
            ForEach(PaperMetric.comparisonOrder) { metric in
                GridRow {
                    Text(metric.model.rawValue)
                        .fontWeight(.medium)
                    metricValue(metric.amountRMSE)
                    metricValue(metric.amountR2)
                    metricValue(metric.percentageRMSE)
                    metricValue(metric.percentageR2)
                }
                .accessibilityElement(children: .combine)
            }
            Divider().gridCellColumns(5)
            GridRow {
                Text(language.text("単位", "Unit"))
                Text("µg")
                Text("—")
                Text(language.text("ポイント", "points"))
                Text("—")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 8)
    }

    private var featureImportanceSection: some View {
        LabSection(language.text("重要パラメータ（RF・XGBoost）", "Important features (RF and XGBoost)")) {
            VStack(alignment: .leading, spacing: 14) {
                Text(
                    language.text(
                        "原著本文とFigure 8が主要とした組み合わせだけを定性的に表示します。",
                        "This qualitative matrix shows only the combinations identified as important by the paper text and Figure 8."
                    )
                )
                .font(.callout)
                .foregroundStyle(.secondary)

                Grid(alignment: .leading, horizontalSpacing: 24, verticalSpacing: 14) {
                    GridRow {
                        Text(language.text("パラメータ", "Parameter")).bold()
                        Text(language.text("透過量", "Amount")).bold()
                        Text(language.text("透過率", "Percentage")).bold()
                    }
                    Divider().gridCellColumns(3)
                    ForEach(PaperEvidence.importantFeatures) { finding in
                        GridRow {
                            Text(finding.feature.name.resolve(language))
                                .fontWeight(.medium)
                            importanceCell(isMajor: finding.amountIsMajor)
                            importanceCell(isMajor: finding.percentageIsMajor)
                        }
                        .accessibilityElement(children: .combine)
                    }
                }

                Label(
                    language.text(
                        "両アウトカムに共通：透過時間",
                        "Common to both outcomes: Permeation time"
                    ),
                    systemImage: "arrow.triangle.branch"
                )
                .font(.headline)

                Text(
                    language.text(
                        "正確な重要度割合は公開出力から復元できないため表示しません。「主要とは報告されず」は影響がないという意味ではなく、特徴量重要度は因果効果も示しません。",
                        "Exact importance percentages cannot be recovered from the released output and are not shown. ‘Not reported as major’ does not mean no effect, and feature importance does not establish causation."
                    )
                )
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityIdentifier("evidence.feature-importance-matrix")
    }

    private var fickSensitivitySection: some View {
        LabSection(language.text("Fickモデルのパラメータ感度", "Fick-model parameter sensitivity")) {
            VStack(alignment: .leading, spacing: 12) {
                Text(
                    language.text(
                        "Figure 5の物理シミュレーションで報告された方向です。機械学習の特徴量重要度とは異なる尺度です。",
                        "These are directions reported by the Figure 5 physical simulations, not machine-learning feature-importance scores."
                    )
                )
                .font(.callout)
                .foregroundStyle(.secondary)

                ForEach(Array(PaperEvidence.fickSensitivity.enumerated()), id: \.element.id) { index, finding in
                    HStack(alignment: .top, spacing: 12) {
                        HStack(spacing: 6) {
                            Text(finding.parameter.name.resolve(language))
                                .fontWeight(.medium)
                            Text("↑")
                                .fontWeight(.semibold)
                                .accessibilityLabel(language.text("増加", "increases"))
                        }
                        .frame(width: 180, alignment: .leading)

                        Image(
                            systemName: finding.response == .unchangedAtFixedTotalLoading
                                ? "equal.circle.fill"
                                : "arrow.up.right.circle.fill"
                        )
                        .foregroundStyle(
                            finding.response == .unchangedAtFixedTotalLoading
                                ? Color.secondary
                                : Color.accentColor
                        )
                        .accessibilityHidden(true)

                        Text(finding.response.description.resolve(language))
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 0)
                    }
                    .accessibilityElement(children: .combine)

                    if index < PaperEvidence.fickSensitivity.count - 1 {
                        Divider()
                    }
                }
            }
        }
        .accessibilityIdentifier("evidence.fick-sensitivity")
    }

    private func rmseMaximum(for outcome: Outcome) -> Double {
        let maximum = PaperMetric.reported.map { $0.rmse(for: outcome) }.max() ?? 1
        return maximum * 1.22
    }

    private func metricChartCard<Content: View>(
        title: String,
        caption: String,
        identifier: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
            content()
                .frame(height: 220)
            Text(caption)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .labCard()
        .accessibilityIdentifier(identifier)
    }

    private func evidencePoint(icon: String, title: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.tint)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(text)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private func importanceCell(isMajor: Bool) -> some View {
        if isMajor {
            Label(language.text("主要", "Major"), systemImage: "checkmark.circle.fill")
                .foregroundStyle(.green)
        } else {
            Label(
                language.text("主要とは報告されず", "Not reported as major"),
                systemImage: "minus.circle"
            )
            .foregroundStyle(.secondary)
        }
    }

    private func metricValue(_ value: Double) -> some View {
        Text(value.formatted(.number.precision(.fractionLength(2))))
            .monospacedDigit()
    }
}

extension PaperMetric {
    func rmse(for outcome: Outcome) -> Double {
        switch outcome {
        case .amount: amountRMSE
        case .percentage: percentageRMSE
        }
    }

    func rSquared(for outcome: Outcome) -> Double {
        switch outcome {
        case .amount: amountR2
        case .percentage: percentageR2
        }
    }
}

private extension Outcome {
    var identifierComponent: String {
        switch self {
        case .amount: "amount"
        case .percentage: "percentage"
        }
    }
}
