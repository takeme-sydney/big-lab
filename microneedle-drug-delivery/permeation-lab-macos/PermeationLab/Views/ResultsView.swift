import Charts
import SwiftUI

struct ResultsView: View {
    @State private var outcome: PermeationOutcome = .amount

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                PageHeader(
                    eyebrow: "Results · Table 4 · Figures 4–8",
                    title: "結果・モデル比較",
                    subtitle: "原著が報告したテストセット性能、機構モデルの挙動、特徴量重要度と未知薬物への限界を分離して表示します。",
                    symbol: "chart.bar.xaxis"
                )
                ReportedResultNotice()

                HStack {
                    Text("Table 4 · 原著報告値").font(.title2.weight(.bold))
                    Spacer()
                    Picker("アウトカム", selection: $outcome) {
                        ForEach(PermeationOutcome.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 320)
                }

                HStack(alignment: .top, spacing: 18) {
                    MetricChart(
                        title: "RMSE · 小さいほど良い",
                        outcome: outcome,
                        value: { metric in
                            outcome == .amount ? metric.amountRMSE : metric.percentageRMSE
                        },
                        yLabel: outcome == .amount ? "RMSE（µg）" : "RMSE（%）"
                    )
                    MetricChart(
                        title: "R² · 1に近いほど良い",
                        outcome: outcome,
                        value: { metric in
                            outcome == .amount ? metric.amountR2 : metric.percentageR2
                        },
                        yLabel: "R²",
                        fixedDomain: 0...1.05
                    )
                }

                ReportedMetricsTable()

                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Text("原著の順位").font(.title3.weight(.semibold))
                        Spacer()
                        EvidenceBadge(evidence: .init(location: "3.4・Table 4", note: "ランダム7:3分割のテスト結果"))
                    }
                    HStack(spacing: 14) {
                        RankCard(rank: 1, model: .xgboost, detail: "両アウトカムで最良")
                        RankCard(rank: 2, model: outcome == .amount ? .fick : .randomForest, detail: outcome == .amount ? "透過量の次点" : "透過率の次点")
                        RankCard(rank: 4, model: .mlr, detail: "両アウトカムで最低")
                    }
                    Text("RF と Fick の順位はアウトカムで入れ替わります。Figures 6・7は混雑回避のため MLR を表示していません。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .studyCard()

                Text("結果の読み方").font(.title2.weight(.bold))
                ForEach(PaperContent.resultTopics) { topic in
                    TopicCard(topic: topic)
                }

                ModelInterpretationGrid()

                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Text("XGBoost の未知薬物検証").font(.title2.weight(.bold))
                        Spacer()
                        EvidenceBadge(evidence: .init(location: "4.2・Figures S1, S2", note: "new-drug prediction 追加検証"))
                    }
                    Text("著者らは XGBoost をさらに検証するため、ある薬物を意図的に学習データから除外して新規薬物として評価すると、透過量・透過率の双方で実測から大きく外れることを示しました。")
                        .font(.headline)
                        .fixedSize(horizontal: false, vertical: true)
                    ForEach(Array(PaperContent.limitations.enumerated()), id: \.offset) { index, limitation in
                        NumberedPoint(number: index + 1, text: limitation)
                    }
                    Divider()
                    Text("したがって、本アプリの実測データ画面は観測点の探索に限定し、未公開モデルを再構成した予測機能を提供しません。")
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(StudyTheme.warning)
                }
                .studyCard()
            }
            .frame(maxWidth: StudyTheme.contentWidth)
            .padding(28)
            .frame(maxWidth: .infinity)
        }
        .accessibilityIdentifier("results-screen")
    }
}

private struct ReportedResultNotice: View {
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "quote.bubble.fill")
                .font(.title3)
                .foregroundStyle(StudyTheme.secondaryAccent)
            VStack(alignment: .leading, spacing: 5) {
                Text("掲載値であり、本アプリの再計算値ではありません").font(.headline)
                Text("Table 4 の固定分割データと学習済みモデルは補足資料に含まれません。以下は原著に掲載された RMSE / R²を忠実に転記したものです。")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
        .studyCard(padding: 16)
    }
}

private struct MetricChart: View {
    let title: String
    let outcome: PermeationOutcome
    let value: (ReportedMetric) -> Double
    let yLabel: String
    var fixedDomain: ClosedRange<Double>?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title).font(.headline)
            Chart(PaperContent.reportedMetrics) { metric in
                BarMark(
                    x: .value("モデル", metric.model.shortLabel),
                    y: .value(yLabel, value(metric))
                )
                .foregroundStyle(StudyTheme.modelColor(metric.model).gradient)
                .annotation(position: .top) {
                    Text(value(metric).formatted(.number.precision(.fractionLength(0...2))))
                        .font(.caption2.monospacedDigit())
                }
            }
            .chartYScale(domain: fixedDomain ?? automaticDomain)
            .frame(height: 260)
        }
        .frame(maxWidth: .infinity)
        .studyCard()
    }

    private var automaticDomain: ClosedRange<Double> {
        let maximum = PaperContent.reportedMetrics.map(value).max() ?? 1
        return 0...(maximum * 1.15)
    }
}

private struct ReportedMetricsTable: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Grid(alignment: .leading, horizontalSpacing: 32, verticalSpacing: 11) {
                GridRow {
                    Text("モデル").font(.caption.bold()).foregroundStyle(.secondary)
                    Text("透過量 RMSE（µg）").font(.caption.bold()).foregroundStyle(.secondary)
                    Text("透過量 R²").font(.caption.bold()).foregroundStyle(.secondary)
                    Text("透過率 RMSE").font(.caption.bold()).foregroundStyle(.secondary)
                    Text("透過率 R²").font(.caption.bold()).foregroundStyle(.secondary)
                }
                Divider().gridCellColumns(5)
                ForEach(PaperContent.reportedMetrics) { metric in
                    GridRow {
                        Label(metric.model.rawValue, systemImage: "circle.fill")
                            .symbolRenderingMode(.monochrome)
                            .foregroundStyle(StudyTheme.modelColor(metric.model))
                            .font(.callout.weight(.semibold))
                        Text(number(metric.amountRMSE)).monospacedDigit()
                        Text(number(metric.amountR2)).monospacedDigit()
                        Text(number(metric.percentageRMSE)).monospacedDigit()
                        Text(number(metric.percentageR2)).monospacedDigit()
                    }
                }
            }
            Text("透過量の単位は Data S1 では µg/cm²、本文の図表では1 cm²へ正規化した µg と記載されます。ここでは相違を埋めず、原著の指標名として示します。")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .studyCard()
        .accessibilityIdentifier("reported-metrics-table")
    }

    private func number(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(0...2)))
    }
}

private struct RankCard: View {
    let rank: Int
    let model: PaperModel
    let detail: String

    var body: some View {
        HStack(spacing: 12) {
            Text("\(rank)")
                .font(.title2.bold().monospacedDigit())
                .foregroundStyle(.white)
                .frame(width: 42, height: 42)
                .background(StudyTheme.modelColor(model), in: RoundedRectangle(cornerRadius: 11))
            VStack(alignment: .leading, spacing: 2) {
                Text(model.rawValue).font(.headline)
                Text(detail).font(.caption).foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 12))
    }
}

private struct ModelInterpretationGrid: View {
    private let rows: [(PaperModel, String)] = [
        (.fick, "薬物放出・皮膚透過の基礎機序を理解し、任意時点を計算できる。一方、主要パラメータの拡散係数は容易に入手できず、皮膚深度・周囲温度・皮膚種に依存する。"),
        (.mlr, "一次線形関係を仮定し、本研究では両アウトカムで最も低い性能だった。"),
        (.randomForest, "複数の独立した決定木の回帰平均を用い、透過率で次点となった。"),
        (.xgboost, "前の木の結果を次の木へ反映し、本研究のランダム分割では両アウトカムで最良となった。")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("原著 Discussion のモデル対比").font(.title2.weight(.bold))
                Spacer()
                EvidenceBadge(evidence: .init(location: "4.1–4.2", note: "機構論的・統計的モデリングの比較"))
            }
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 240), spacing: 12)], spacing: 12) {
                ForEach(rows, id: \.0) { model, detail in
                    VStack(alignment: .leading, spacing: 8) {
                        Label(model.rawValue, systemImage: "circle.fill")
                            .font(.headline)
                            .foregroundStyle(StudyTheme.modelColor(model))
                        Text(detail)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, minHeight: 100, alignment: .topLeading)
                    .padding(14)
                    .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .studyCard()
    }
}
