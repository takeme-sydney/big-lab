import SwiftUI

struct StudyOverviewView: View {
    let language: AppLanguage
    @ObservedObject var dataStore: AppDatasetStore

    private let articleURL = URL(string: "https://pmc.ncbi.nlm.nih.gov/articles/PMC10658566/")!
    private let pubMedURL = URL(string: "https://pubmed.ncbi.nlm.nih.gov/38023708/")!

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                LabWorkspaceHeader(
                    title: language.text("論文の概要", "Paper overview"),
                    subtitle: language.text(
                        "一次資料で確認できる内容だけを読み取り専用で確認",
                        "Read-only material supported by primary sources"
                    ),
                    systemImage: "books.vertical"
                )

                LabNotice(
                    title: language.text("ここは確認済み事実だけ", "Verified facts only"),
                    message: language.text(
                        "原著、公開補足資料、確認済みData S1に基づく内容を表示します。任意CSV、再学習、探索的Fick値、run履歴はこの領域へ入りません。",
                        "This area contains only the paper, public supplements, and verified Data S1. Imported CSVs, refits, exploratory Fick values, and run history cannot enter it."
                    ),
                    kind: .information
                )

                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 210), spacing: 14)],
                    alignment: .leading,
                    spacing: 14
                ) {
                    LabMetricCard(
                        title: language.text("実測値", "Observations"),
                        value: "\(dataStore.dataset.rows.count)",
                        detail: dataStore.displayName,
                        systemImage: "point.3.connected.trianglepath.dotted"
                    )
                    LabMetricCard(
                        title: language.text("薬物", "Drugs"),
                        value: "\(Set(dataStore.dataset.rows.map(\.drug)).count)",
                        detail: language.text("既知薬物内の評価", "Evaluation within known drugs"),
                        systemImage: "pills"
                    )
                    LabMetricCard(
                        title: language.text("比較モデル", "Reported models"),
                        value: "4",
                        detail: "Fick · MLR · RF · XGBoost",
                        systemImage: "chart.bar.xaxis"
                    )
                    LabMetricCard(
                        title: language.text("原著図", "Paper figures"),
                        value: "8",
                        detail: language.text("一次ソースと照合", "Cross-checked with sources"),
                        systemImage: "doc.richtext"
                    )
                }

                LabSection(language.text("研究の問い", "Research question")) {
                    Text(language.text(
                        "マイクロニードル処置した皮膚を通る累積薬物透過量・透過率を、機構モデルと表形式機械学習でどこまで説明できるかを検討した研究です。",
                        "The study asks how well mechanistic modelling and tabular machine learning can explain cumulative drug amount and percentage permeated through microneedled skin."
                    ))
                    .fixedSize(horizontal: false, vertical: true)
                }

                LabSection(language.text("方法と評価設計", "Methods and validation design")) {
                    VStack(alignment: .leading, spacing: 14) {
                        methodRow(
                            number: "1",
                            title: language.text("入力", "Inputs"),
                            detail: language.text(
                                "皮膚種、MN種、MN長、MN表面積、薬物負荷量、透過時間、分子量の7特徴量。",
                                "Seven features: skin type, MN type, MN length, MN surface area, drug loading, permeation time, and molecular weight."
                            )
                        )
                        methodRow(
                            number: "2",
                            title: language.text("出力", "Outcomes"),
                            detail: language.text(
                                "累積透過量と累積透過率。Data S1では透過量が1 cm²に正規化されています。",
                                "Cumulative permeation amount and percentage. Data S1 normalizes amount to a 1 cm² window."
                            )
                        )
                        methodRow(
                            number: "3",
                            title: language.text("原著の分割", "Paper split"),
                            detail: language.text(
                                "191行を70:30に無作為分割。公開資料には分割済み行番号と予測出力がありません。",
                                "A random 70:30 split of 191 rows. Released materials omit split row indices and prediction outputs."
                            )
                        )
                        methodRow(
                            number: "4",
                            title: language.text("公開資料の限界", "Released-material boundary"),
                            detail: language.text(
                                "原著の分割済み行、学習済みモデル、個別予測は未公開のため、Table 4の値を独立再計算した事実とは扱いません。",
                                "The paper's split rows, fitted models, and individual predictions are unavailable, so Table 4 is not presented as independently reproduced fact."
                            )
                        )
                    }
                }

                LabNotice(
                    title: language.text("科学的境界", "Scientific boundary"),
                    message: language.text(
                        "原著モデルの学習済み係数・forest・boosterは公開されていません。報告値を再現済み性能として扱わず、臨床、投与量、安全性判断には使用しないでください。",
                        "The trained coefficients, forest, and booster are not public. Do not treat reported metrics as independently reproduced performance, and do not use this app for clinical, dosing, or safety decisions."
                    ),
                    kind: .limitation
                )

                LabSection(language.text("一次ソース", "Primary sources")) {
                    HStack(spacing: 18) {
                        Link(language.text("PubMedを開く", "Open PubMed"), destination: pubMedURL)
                        Link(language.text("全文を開く", "Open full text"), destination: articleURL)
                    }
                }
            }
            .frame(maxWidth: LabTheme.contentWidth, alignment: .leading)
            .padding(LabTheme.pagePadding)
            .frame(maxWidth: .infinity, alignment: .top)
        }
        .accessibilityIdentifier("screen.study-overview")
    }

    private func methodRow(number: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(.caption.bold())
                .foregroundStyle(.white)
                .frame(width: 24, height: 24)
                .background(Circle().fill(.tint))
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.headline)
                Text(detail)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
