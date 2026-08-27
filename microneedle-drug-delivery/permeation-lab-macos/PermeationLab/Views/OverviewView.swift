import Charts
import SwiftUI

struct OverviewView: View {
    let repository: StudyRepository

    private var skinCounts: (rat: Int, human: Int) {
        (
            repository.records.filter { $0.skin == .rat }.count,
            repository.records.filter { $0.skin == .human }.count
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                PageHeader(
                    eyebrow: "Paper-grounded research companion",
                    title: PaperContent.titleJapanese,
                    subtitle: "原著本文・Data S1・Data S2・Figures S1–S2を、予測値を捏造しないオフライン macOS アプリに統合しました。",
                    symbol: "doc.text.magnifyingglass"
                )
                PaperOnlyNotice()

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 14), count: 4), spacing: 14) {
                    MetricTile(value: "\(repository.records.count)", label: "実測点", detail: "Data S1 の全行")
                    MetricTile(value: "6", label: "薬物", detail: "BSA から銅イオンまで", color: StudyTheme.secondaryAccent)
                    MetricTile(value: "4", label: "比較手法", detail: "Fick・MLR・RF・XGBoost", color: StudyTheme.warning)
                    MetricTile(value: "10", label: "原著・補足図", detail: "Figure 1–8, S1–S2", color: .purple)
                }

                if let loadingError = repository.loadingError {
                    Label(loadingError, systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                        .studyCard()
                }

                HStack(alignment: .top, spacing: 18) {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Text("Data S1 の薬物別件数").font(.title3.weight(.semibold))
                            Spacer()
                            EvidenceBadge(evidence: .init(location: "Data S1", note: "全191行を直接集計"))
                        }
                        Chart(repository.countByDrug(), id: \.drug) { item in
                            BarMark(
                                x: .value("件数", item.count),
                                y: .value("薬物", item.drug)
                            )
                            .foregroundStyle(StudyTheme.accent.gradient)
                            .annotation(position: .trailing) {
                                Text("\(item.count)")
                                    .font(.caption.monospacedDigit())
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .chartXAxisLabel("観測点数")
                        .frame(height: 260)
                        .accessibilityIdentifier("drug-count-chart")
                    }
                    .frame(maxWidth: .infinity)
                    .studyCard()

                    VStack(alignment: .leading, spacing: 17) {
                        Text("Data S1 観測点の構成").font(.title3.weight(.semibold))
                        CompositionRow(label: "ラット皮膚", value: skinCounts.rat, total: repository.records.count, color: StudyTheme.secondaryAccent)
                        CompositionRow(label: "ヒト皮膚", value: skinCounts.human, total: repository.records.count, color: StudyTheme.accent)
                        Divider()
                        CompositionRow(
                            label: "ヒドロゲル MN",
                            value: repository.records.filter { $0.needle == .hydrogel }.count,
                            total: repository.records.count,
                            color: .purple
                        )
                        CompositionRow(
                            label: "プラスチック MN",
                            value: repository.records.filter { $0.needle == .plastic }.count,
                            total: repository.records.count,
                            color: StudyTheme.warning
                        )
                        Text("件数は図中の丸めた比率ではなく Data S1 を直接集計しています。")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(width: 340)
                    .studyCard()
                }

                Text("研究の全体像")
                    .font(.title2.weight(.bold))
                ForEach(PaperContent.overviewTopics) { topic in
                    TopicCard(topic: topic)
                }

                VStack(alignment: .leading, spacing: 16) {
                    Text("原著の比較設計").font(.title3.weight(.semibold))
                    HStack(alignment: .top, spacing: 14) {
                        FlowStep(number: "01", title: "収集", detail: "6薬物・191実測点を手動清掃")
                        FlowArrow()
                        FlowStep(number: "02", title: "モデル化", detail: "Fick、MLR、RF、XGBoost")
                        FlowArrow()
                        FlowStep(number: "03", title: "7:3分割", detail: "原著の無作為 train / test")
                        FlowArrow()
                        FlowStep(number: "04", title: "評価", detail: "RMSE と R²で比較")
                    }
                    Text("注：Data S2 には set.seed(0) がありますが、無作為分割処理は掲載されず、既成の train / test CSV を読むだけです。固定行割当と学習済みモデルは未公開のため、本アプリは Table 4 の値を再現値として計算しません。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .studyCard()
            }
            .frame(maxWidth: StudyTheme.contentWidth)
            .padding(28)
            .frame(maxWidth: .infinity)
        }
        .accessibilityIdentifier("overview-screen")
    }
}

private struct CompositionRow: View {
    let label: String
    let value: Int
    let total: Int
    let color: Color

    private var fraction: Double {
        guard total > 0 else { return 0 }
        return Double(value) / Double(total)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                Text(label).font(.callout.weight(.medium))
                Spacer()
                Text("\(value) / \(total)")
                    .font(.callout.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule().fill(.quaternary)
                    Capsule().fill(color).frame(width: geometry.size.width * fraction)
                }
            }
            .frame(height: 7)
        }
    }
}

private struct FlowStep: View {
    let number: String
    let title: String
    let detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(number).font(.caption.bold()).foregroundStyle(StudyTheme.accent)
            Text(title).font(.headline)
            Text(detail).font(.caption).foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct FlowArrow: View {
    var body: some View {
        Image(systemName: "chevron.right")
            .foregroundStyle(.tertiary)
            .padding(.top, 24)
            .accessibilityHidden(true)
    }
}
