import AppKit
import SwiftUI

struct FiguresView: View {
    @State private var selectedID = PaperContent.figures.first?.id ?? "figure-1"

    private var selectedFigure: PaperFigure {
        PaperContent.figures.first { $0.id == selectedID } ?? PaperContent.figures[0]
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    PageHeader(
                        eyebrow: "Figures 1–8 · Supporting Figures S1–S2",
                        title: "原著図アトラス",
                        subtitle: "研究フロー、濃度分布、モデル比較、特徴量重要度、未知薬物検証を掲載図そのもので確認します。",
                        symbol: "photo.on.rectangle.angled"
                    )

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(PaperContent.figures) { figure in
                                Button {
                                    selectedID = figure.id
                                } label: {
                                    Text(figure.label)
                                        .font(.callout.weight(selectedID == figure.id ? .bold : .medium))
                                        .padding(.horizontal, 13)
                                        .padding(.vertical, 8)
                                        .foregroundStyle(selectedID == figure.id ? .white : .primary)
                                        .background(
                                            selectedID == figure.id ? StudyTheme.accent : Color.clear,
                                            in: Capsule()
                                        )
                                        .overlay(Capsule().stroke(selectedID == figure.id ? Color.clear : Color.secondary.opacity(0.25)))
                                }
                                .buttonStyle(.plain)
                                .accessibilityIdentifier("select-\(figure.id)")
                            }
                        }
                        .padding(.vertical, 2)
                    }

                    FigureDetail(figure: selectedFigure)
                        .id(selectedFigure.id)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("図の収録範囲").font(.title3.weight(.semibold))
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 260), spacing: 10)], spacing: 10) {
                            ForEach(PaperContent.figures) { figure in
                                Button {
                                    selectedID = figure.id
                                } label: {
                                    HStack(alignment: .top, spacing: 10) {
                                        Text(figure.label)
                                            .font(.caption.bold())
                                            .foregroundStyle(StudyTheme.accent)
                                            .frame(width: 63, alignment: .leading)
                                        Text(figure.caption)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .multilineTextAlignment(.leading)
                                            .lineLimit(3)
                                        Spacer(minLength: 0)
                                    }
                                    .frame(maxWidth: .infinity, minHeight: 52, alignment: .topLeading)
                                    .padding(11)
                                    .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 10))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .studyCard()
                }
                .frame(maxWidth: StudyTheme.contentWidth)
                .padding(28)
                .frame(maxWidth: .infinity)
            }
        }
        .accessibilityIdentifier("figures-screen")
    }
}

private struct FigureDetail: View {
    let figure: PaperFigure

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline) {
                Text(figure.label).font(.title2.weight(.bold))
                Spacer()
                EvidenceBadge(evidence: figure.evidence)
            }

            PaperFigureImage(figure: figure)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 300, maxHeight: 650)
                .background(Color.white, in: RoundedRectangle(cornerRadius: 12))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(.quaternary))

            VStack(alignment: .leading, spacing: 8) {
                Text("キャプション").font(.caption.bold()).foregroundStyle(StudyTheme.accent)
                Text(figure.caption)
                    .font(.body)
                    .fixedSize(horizontal: false, vertical: true)
                Text("読み方").font(.caption.bold()).foregroundStyle(StudyTheme.secondaryAccent)
                    .padding(.top, 4)
                Text(figure.readingGuide)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .studyCard()
        .accessibilityIdentifier("figure-detail-\(figure.id)")
    }
}

private struct PaperFigureImage: View {
    let figure: PaperFigure

    private var image: NSImage? {
        guard let url = StudyResourceLocator.url(
            name: figure.resourceName,
            extension: figure.fileExtension
        ) else { return nil }
        return NSImage(contentsOf: url)
    }

    var body: some View {
        Group {
            if let image {
                Image(nsImage: image)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .padding(12)
                    .accessibilityLabel("\(figure.label): \(figure.caption)")
            } else {
                ContentUnavailableView(
                    "図を読み込めません",
                    systemImage: "photo.badge.exclamationmark",
                    description: Text("\(figure.resourceName).\(figure.fileExtension) が見つかりません。")
                )
            }
        }
    }
}
