import AppKit
import SwiftUI

struct PaperReaderView: View {
    private let paperURL = StudyResourceLocator.url(
        name: "yuan2023-paper-ja",
        extension: "html"
    )

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("原著全文 · 日本語版")
                        .font(.headline)
                    Text("本文、式 (1)–(11)・番号なし計算例、Tables 1–4、Figures 1–8、謝辞・声明、参考文献1–51を収録")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Label("ネットワーク不使用", systemImage: "network.slash")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(StudyTheme.accent)
                Button("原著PDFを開く", systemImage: "doc.richtext") {
                    openBundledPDF()
                }
                .accessibilityIdentifier("open-paper-pdf")
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(.bar)

            Divider()

            if let paperURL {
                LocalPaperTextView(url: paperURL)
                    .accessibilityIdentifier("paper-document-view")
            } else {
                ContentUnavailableView(
                    "全文を読み込めません",
                    systemImage: "doc.badge.exclamationmark",
                    description: Text("同梱HTML yuan2023-paper-ja.html が見つかりません。")
                )
            }
        }
        .accessibilityIdentifier("paper-screen")
    }

    private func openBundledPDF() {
        guard let url = StudyResourceLocator.url(name: "yuan2023-paper", extension: "pdf") else { return }
        NSWorkspace.shared.open(url)
    }
}

private struct LocalPaperTextView: NSViewRepresentable {
    let url: URL

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.drawsBackground = true
        scrollView.backgroundColor = .textBackgroundColor

        let textView = NSTextView()
        textView.isEditable = false
        textView.isSelectable = true
        textView.isRichText = true
        textView.drawsBackground = true
        textView.backgroundColor = .textBackgroundColor
        textView.textContainerInset = NSSize(width: 32, height: 28)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.containerSize = NSSize(
            width: 0,
            height: CGFloat.greatestFiniteMagnitude
        )
        scrollView.documentView = textView

        load(into: textView, coordinator: context.coordinator)
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard context.coordinator.loadedURL != url else { return }
        guard let textView = scrollView.documentView as? NSTextView else { return }
        load(into: textView, coordinator: context.coordinator)
    }

    private func load(into textView: NSTextView, coordinator: Coordinator) {
        coordinator.loadedURL = url
        guard let data = try? Data(contentsOf: url),
              let imported = try? NSAttributedString(
                data: data,
                options: [
                    .documentType: NSAttributedString.DocumentType.html,
                    .characterEncoding: String.Encoding.utf8.rawValue,
                    .baseURL: url.deletingLastPathComponent()
                ],
                documentAttributes: nil
              ) else {
            textView.string = "同梱HTMLを読み込めません。"
            return
        }

        let readable = NSMutableAttributedString(attributedString: imported)
        let fullRange = NSRange(location: 0, length: readable.length)
        readable.removeAttribute(.link, range: fullRange)
        readable.enumerateAttribute(.font, in: fullRange) { value, range, _ in
            guard let font = value as? NSFont else { return }
            let readableSize = min(32, max(11, font.pointSize * 1.6))
            readable.addAttribute(
                .font,
                value: NSFontManager.shared.convert(font, toSize: readableSize),
                range: range
            )
        }
        textView.textStorage?.setAttributedString(readable)
        textView.scrollToBeginningOfDocument(nil)
    }

    final class Coordinator {
        var loadedURL: URL?
    }
}
