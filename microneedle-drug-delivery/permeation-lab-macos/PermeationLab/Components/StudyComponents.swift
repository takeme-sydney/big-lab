import SwiftUI

struct PageHeader: View {
    let eyebrow: String
    let title: String
    let subtitle: String
    let symbol: String

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: symbol)
                .font(.system(size: 25, weight: .semibold))
                .foregroundStyle(StudyTheme.accent)
                .frame(width: 52, height: 52)
                .background(StudyTheme.accent.opacity(0.11), in: RoundedRectangle(cornerRadius: 14))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 5) {
                Text(eyebrow.uppercased())
                    .font(.caption.weight(.bold))
                    .tracking(1.1)
                    .foregroundStyle(StudyTheme.accent)
                Text(title).font(.largeTitle.weight(.bold))
                Text(subtitle)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct EvidenceBadge: View {
    let evidence: EvidenceLocator

    var body: some View {
        Label(evidence.location, systemImage: "scope")
            .font(.caption.weight(.medium))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(.quaternary.opacity(0.55), in: Capsule())
            .help(evidence.note)
    }
}

struct MetricTile: View {
    let value: String
    let label: String
    let detail: String
    var color: Color = StudyTheme.accent

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(color)
            Text(label).font(.headline)
            Text(detail).font(.caption).foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .studyCard(padding: 16)
    }
}

struct TopicCard: View {
    let topic: StudyTopic

    var body: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack(alignment: .firstTextBaseline) {
                Text(topic.title).font(.title3.weight(.semibold))
                Spacer()
                EvidenceBadge(evidence: topic.evidence)
            }
            Text(topic.summary)
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)
            VStack(alignment: .leading, spacing: 8) {
                ForEach(topic.bullets, id: \.self) { bullet in
                    HStack(alignment: .top, spacing: 9) {
                        Image(systemName: "circle.fill")
                            .font(.system(size: 5))
                            .foregroundStyle(StudyTheme.accent)
                            .padding(.top, 7)
                            .accessibilityHidden(true)
                        Text(bullet).foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .studyCard()
    }
}

struct PaperOnlyNotice: View {
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "checkmark.shield.fill")
                .foregroundStyle(StudyTheme.accent)
                .font(.title3)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text("原著限定モード").font(.headline)
                Text("表示する科学的内容は Yuan et al. (2023) 本文と同論文の補足資料だけです。未公開の学習済みモデルを推測せず、独自の予測値を生成しません。")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .studyCard(padding: 16)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("paper-only-notice")
    }
}

struct NumberedPoint: View {
    let number: Int
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 11) {
            Text("\(number)")
                .font(.caption.bold())
                .foregroundStyle(.white)
                .frame(width: 23, height: 23)
                .background(StudyTheme.secondaryAccent, in: Circle())
            Text(text).fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }
}

struct ParameterTableView: View {
    let title: String
    let rows: [ParameterRow]
    let evidence: EvidenceLocator

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(title).font(.headline)
                Spacer()
                EvidenceBadge(evidence: evidence)
            }
            Grid(alignment: .leading, horizontalSpacing: 22, verticalSpacing: 10) {
                GridRow {
                    Text("項目").font(.caption.bold()).foregroundStyle(.secondary)
                    Text("原著記載値").font(.caption.bold()).foregroundStyle(.secondary)
                }
                Divider().gridCellColumns(2)
                ForEach(rows) { row in
                    GridRow(alignment: .top) {
                        Text(row.name).font(.callout.weight(.medium))
                        Text(row.value).font(.callout.monospacedDigit()).textSelection(.enabled)
                    }
                }
            }
        }
        .studyCard()
    }
}
