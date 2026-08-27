import AppKit
import CryptoKit
import SwiftUI

struct IntegrityView: View {
    let repository: StudyRepository
    @State private var digests: [String: String] = [:]

    private let expectedDigests: [String: String] = [
        "paper-pdf": "4641e97362f3cc545586879f2da3735e5487a50fe3cc6149076c87151e47c820",
        "data-s1": "a22cc32b4d461b1e65c2b29623186a0d0c1f984fc1935d8bd3b35ec0bc3c3a24",
        "data-csv": "03ff02276f333d06747efb7a625e9de1b4055b94b8736873f5e7cc389315b0f5",
        "data-s2": "9d6fe3da0127ba26469b7a1fe61a98f723a5547d8a666c92670bf30f31820c81",
        "figures-s1-s2": "49f953203a33dd6c781e2761011c8124a6bac891e07ceedf61de6c1289626031"
    ]

    private let discrepancies = [
        "本文は BSA / GHK / copper を33% / 24% / 24%と記す一方、Figure 3とData S1では33 / 24 / 24は件数です（Figure 3の比率は17% / 13% / 13%）。Figure 3の丸めた比率の合計は101%です。",
        "BSA の分子量は本文・Data S1で66,000 Da、Table 2で66,430 Daと記載されます。本アプリのデータ表示は Data S1 の66,000を保持します。",
        "累積透過量は Data S1 の列名で µg/cm²、本文図表で1 cm²へ正規化した µg と表記されます。両表記を明示して無言で統一しません。",
        "MN 種は Methods / Data S1で hydrogel / plastic、Table 2で hydrogel / solid と記載されます。",
        "Data S1 の BSA には108.3982246%の観測値があります。本アプリは100%へ clamp しません。",
        "Discussion の少数標本に関する文では caffeine と copper peptide と記す一方、参照パネル d・g と20点未満のデータはローダミンBとカフェインに対応します。",
        "MLR の式 (4) は切片 b を含みますが、Data S2 の R 式は `Results ~ . - 1` で切片を除外します。"
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                PageHeader(
                    eyebrow: "Provenance · Reproducibility · End matter",
                    title: "研究情報・完全性",
                    subtitle: "出典、研究末尾情報、補足資料、再現可能性の境界、原著内の表記差を監査できる形で示します。",
                    symbol: "checkmark.shield"
                )
                PaperOnlyNotice()

                CitationCard()
                ResearchEndMatterCard()
                BundledSourcesCard(digests: digests, expectedDigests: expectedDigests)
                ReproducibilityCard(recordCount: repository.records.count)

                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Text("原著・補足内の表記差").font(.title2.weight(.bold))
                        Spacer()
                        EvidenceBadge(evidence: .init(location: "本文・Tables 2, 4・Data S1, S2", note: "資料間照合"))
                    }
                    Text("相違をアプリ側で密かに“修正”せず、原記載と Data S1 の扱いを明示します。")
                        .foregroundStyle(.secondary)
                    ForEach(Array(discrepancies.enumerated()), id: \.offset) { index, discrepancy in
                        NumberedPoint(number: index + 1, text: discrepancy)
                    }
                }
                .studyCard()

                AuthorContributionsCard()
            }
            .frame(maxWidth: StudyTheme.contentWidth)
            .padding(28)
            .frame(maxWidth: .infinity)
        }
        .accessibilityIdentifier("integrity-screen")
        .task { calculateDigests() }
    }

    private func calculateDigests() {
        for resource in PaperContent.bundledSources {
            guard let url = StudyResourceLocator.url(
                name: resource.resourceName,
                extension: resource.fileExtension
            ), let data = try? Data(contentsOf: url) else { continue }
            digests[resource.id] = SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
        }
    }
}

private struct CitationCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("書誌情報").font(.title2.weight(.bold))
                Spacer()
                Text(PaperContent.license).font(.caption).foregroundStyle(.secondary)
            }
            Text(PaperContent.titleEnglish).font(.title3.weight(.semibold)).textSelection(.enabled)
            Text(PaperContent.citation).foregroundStyle(.secondary).textSelection(.enabled)
            Grid(alignment: .leading, horizontalSpacing: 28, verticalSpacing: 8) {
                metadata("DOI", PaperContent.doi)
                metadata("PMID", PaperContent.pmid)
                metadata("PMCID", PaperContent.pmcid)
                metadata("受領 / 改訂 / 採択", "2022-11-11 / 2023-02-22 / 2023-03-08")
                metadata("著者", PaperContent.authors.joined(separator: ", "))
                metadata("連絡先", "Xiaoqiang Xiang: xiangxq@fudan.edu.cn\nLifeng Kang: lifeng.kang@sydney.edu.au")
            }
            Divider()
            Text("所属").font(.caption.bold()).foregroundStyle(.secondary)
            ForEach(PaperContent.affiliations, id: \.self) { affiliation in
                Label(affiliation, systemImage: "building.2")
                    .font(.callout)
            }
        }
        .studyCard()
    }

    private func metadata(_ key: String, _ value: String) -> some View {
        GridRow(alignment: .top) {
            Text(key).font(.caption.bold()).foregroundStyle(.secondary)
            Text(value).font(.callout).textSelection(.enabled)
        }
    }
}

private struct ResearchEndMatterCard: View {
    private let items: [(String, String, String)] = [
        ("研究資金", "中国国家留学基金管理委員会（202008320366）；シドニー大学（PCA2019）。", "banknote"),
        ("謝辞", "2019年 University of Sydney–Fudan University Partnership Collaboration Awards の助成。Yunong Yuan は USYD–CSC 奨学金 No. 202008320366の支援。", "hands.sparkles"),
        ("利益相反", "著者らは利益相反がないことを宣言。", "checkmark.seal"),
        ("データ可用性", "データは本論文とともに公開された補足資料として入手可能。", "externaldrive"),
        ("倫理", "動物・ヒト皮膚組織試料について必要な倫理承認を得た著者らの既報研究の実験結果を使用。", "person.badge.shield.checkmark"),
        ("ORCID", "Lifeng Kang: 0000-0002-1676-7607", "person.text.rectangle")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("原著の末尾情報").font(.title2.weight(.bold))
                Spacer()
                EvidenceBadge(evidence: .init(location: "Acknowledgments–ORCID", note: "論文末尾の声明"))
            }
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 310), spacing: 12)], spacing: 12) {
                ForEach(items, id: \.0) { title, detail, symbol in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: symbol)
                            .foregroundStyle(StudyTheme.accent)
                            .frame(width: 24)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(title).font(.headline)
                            Text(detail).font(.callout).foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .frame(maxWidth: .infinity, minHeight: 78, alignment: .topLeading)
                    .padding(13)
                    .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 12))
                }
            }
            Text("査読履歴へのURLも原著に記載されています。全文画面の『ピアレビュー』節で原文どおり確認できます。")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .studyCard()
    }
}

private struct BundledSourcesCard: View {
    let digests: [String: String]
    let expectedDigests: [String: String]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("同梱された一次資料").font(.title2.weight(.bold))
                Spacer()
                EvidenceBadge(evidence: .init(location: "原著・Supporting Information", note: "すべてオフライン収録"))
            }
            ForEach(PaperContent.bundledSources) { resource in
                HStack(alignment: .center, spacing: 13) {
                    Image(systemName: icon(for: resource.fileExtension))
                        .font(.title3)
                        .foregroundStyle(StudyTheme.secondaryAccent)
                        .frame(width: 30)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(resource.title).font(.headline)
                        Text(resource.detail).font(.caption).foregroundStyle(.secondary)
                        if let digest = digests[resource.id] {
                            Text("SHA-256  \(digest)")
                                .font(.system(size: 9, design: .monospaced))
                                .foregroundStyle(.tertiary)
                                .textSelection(.enabled)
                        }
                    }
                    Spacer()
                    if let expected = expectedDigests[resource.id], let actual = digests[resource.id] {
                        Label(actual == expected ? "一致" : "不一致", systemImage: actual == expected ? "checkmark.circle.fill" : "xmark.octagon.fill")
                            .font(.caption.bold())
                            .foregroundStyle(actual == expected ? StudyTheme.accent : Color.red)
                    }
                    Button("開く") { open(resource) }
                        .disabled(resourceURL(resource) == nil)
                }
                .padding(.vertical, 5)
                if resource.id != PaperContent.bundledSources.last?.id { Divider() }
            }
        }
        .studyCard()
    }

    private func resourceURL(_ resource: SupplementaryResource) -> URL? {
        StudyResourceLocator.url(name: resource.resourceName, extension: resource.fileExtension)
    }

    private func open(_ resource: SupplementaryResource) {
        guard let url = resourceURL(resource) else { return }
        NSWorkspace.shared.open(url)
    }

    private func icon(for fileExtension: String) -> String {
        switch fileExtension {
        case "pdf": "doc.richtext"
        case "xlsx", "csv": "tablecells"
        case "docx": "doc.text"
        case "html": "text.book.closed"
        default: "doc.plaintext"
        }
    }
}

private struct ReproducibilityCard: View {
    let recordCount: Int

    private let gaps: [(String, String, Bool)] = [
        ("Data S1", "全191行×11列", true),
        ("無作為分割比", "本文に7:3と記載", true),
        ("train / test の行割当", "公開なし", false),
        ("分割生成コード", "公開なし", false),
        ("Data S2 の set.seed(0)", "記載あり。分割処理は掲載されず、既成CSVを読む", true),
        ("MLR / RF / XGBoost コード", "透過率用の掲載コードあり", true),
        ("学習済み係数・forest・booster", "公開なし", false),
        ("Fick の C コード", "掲載あり。ただし構文欠落を含む", true),
        ("Table 4", "報告値あり。再計算値ではない", true)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("再現可能性の境界").font(.title2.weight(.bold))
                Spacer()
                EvidenceBadge(evidence: .init(location: "2.8・Data S1, S2・Table 4", note: "公開物の有無"))
            }
            Grid(alignment: .leading, horizontalSpacing: 24, verticalSpacing: 9) {
                GridRow {
                    Text("項目").font(.caption.bold()).foregroundStyle(.secondary)
                    Text("公開状態").font(.caption.bold()).foregroundStyle(.secondary)
                    Text("判定").font(.caption.bold()).foregroundStyle(.secondary)
                }
                Divider().gridCellColumns(3)
                ForEach(gaps, id: \.0) { item, status, present in
                    GridRow(alignment: .top) {
                        Text(item).font(.callout.weight(.medium))
                        Text(status).font(.callout).foregroundStyle(.secondary)
                        Label(present ? "記載あり" : "未公開", systemImage: present ? "checkmark.circle.fill" : "minus.circle.fill")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(present ? StudyTheme.accent : StudyTheme.warning)
                    }
                }
            }
            if recordCount != 191 {
                Label("同梱 CSV の読込件数が191件ではありません（現在 \(recordCount)件）。", systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
            }
        }
        .studyCard()
    }
}

private struct AuthorContributionsCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("著者の貢献").font(.title2.weight(.bold))
                Spacer()
                EvidenceBadge(evidence: .init(location: "Author Contributions", note: "CRediT記載"))
            }
            ForEach(PaperContent.contributions) { contribution in
                VStack(alignment: .leading, spacing: 4) {
                    Text(contribution.name).font(.headline)
                    Text(contribution.contribution)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if contribution.id != PaperContent.contributions.last?.id { Divider() }
            }
        }
        .studyCard()
    }
}
