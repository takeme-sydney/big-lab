import Charts
import Foundation
import SwiftUI

struct PaperFiguresView: View {
    let language: AppLanguage
    @ObservedObject var dataStore: AppDatasetStore

    private let articleURL = URL(string: "https://pmc.ncbi.nlm.nih.gov/articles/PMC10658566/")!
    private let pubMedURL = URL(string: "https://pubmed.ncbi.nlm.nih.gov/38023708/")!
    private let licenseURL = URL(string: "https://creativecommons.org/licenses/by/4.0/")!
    private let supplementURL = URL(string: "https://www.ebi.ac.uk/europepmc/webservices/rest/PMC10658566/supplementaryFiles")!

    private let figureURLs: [Int: URL] = [
        1: URL(string: "https://cdn.ncbi.nlm.nih.gov/pmc/blobs/baaf/10658566/f3aa8ca4f2ca/BTM2-8-e10512-g008.jpg")!,
        2: URL(string: "https://cdn.ncbi.nlm.nih.gov/pmc/blobs/baaf/10658566/d3b366770365/BTM2-8-e10512-g001.jpg")!,
        3: URL(string: "https://cdn.ncbi.nlm.nih.gov/pmc/blobs/baaf/10658566/80db2a636b21/BTM2-8-e10512-g002.jpg")!,
        4: URL(string: "https://cdn.ncbi.nlm.nih.gov/pmc/blobs/baaf/10658566/a5a6cae40f30/BTM2-8-e10512-g005.jpg")!,
        5: URL(string: "https://cdn.ncbi.nlm.nih.gov/pmc/blobs/baaf/10658566/7d5653c8c00c/BTM2-8-e10512-g007.jpg")!,
        6: URL(string: "https://cdn.ncbi.nlm.nih.gov/pmc/blobs/baaf/10658566/fb89281b3870/BTM2-8-e10512-g004.jpg")!,
        7: URL(string: "https://cdn.ncbi.nlm.nih.gov/pmc/blobs/baaf/10658566/6a2126c87998/BTM2-8-e10512-g003.jpg")!,
        8: URL(string: "https://cdn.ncbi.nlm.nih.gov/pmc/blobs/baaf/10658566/a877742ea701/BTM2-8-e10512-g006.jpg")!
    ]

    private let figureAspectRatios: [Int: CGFloat] = [
        1: 709 / 499,
        2: 709 / 557,
        3: 709 / 397,
        4: 709 / 689,
        5: 709 / 558,
        6: 709 / 553,
        7: 709 / 568,
        8: 709 / 722
    ]

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 24) {
                LabWorkspaceHeader(
                    title: t("原著の全図を読む", "Read every paper figure"),
                    subtitle: t(
                        "Yuan et al. (2023) · 一次ソースと Data S1 を相互照合",
                        "Yuan et al. (2023) · cross-checked against the primary sources and Data S1"
                    ),
                    systemImage: "doc.richtext"
                )

                sourceLinks

                LabNotice(
                    title: t("表示ルール", "Reading rule"),
                    message: t(
                        "原著画像、Data S1 から再計算した値、画像から読める定性的傾向を区別します。画像だけから正確な座標を推定した値は掲載しません。",
                        "Original artwork, values recalculated from Data S1, and qualitative visual readings are kept distinct. Coordinates estimated only from raster pixels are never presented as exact data."
                    ),
                    kind: .information
                )

                figure1
                figure2
                figure3
                figure4
                figure5
                figure6
                figure7
                figure8
                supplementalAudit
            }
            .frame(maxWidth: LabTheme.contentWidth, alignment: .leading)
            .padding(LabTheme.pagePadding)
            .frame(maxWidth: .infinity, alignment: .top)
        }
        .accessibilityIdentifier("screen.paper-figures")
    }

    private var sourceLinks: some View {
        LabSection(t("一次ソース", "Primary sources")) {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 16) {
                    sourceLink(t("PubMed 書誌", "PubMed record"), systemImage: "cross.case", url: pubMedURL)
                    sourceLink(t("PMC 全文", "PMC full text"), systemImage: "doc.text", url: articleURL)
                    sourceLink(t("補足資料一式", "Supplementary files"), systemImage: "archivebox", url: supplementURL)
                }
                VStack(alignment: .leading, spacing: 10) {
                    sourceLink(t("PubMed 書誌", "PubMed record"), systemImage: "cross.case", url: pubMedURL)
                    sourceLink(t("PMC 全文", "PMC full text"), systemImage: "doc.text", url: articleURL)
                    sourceLink(t("補足資料一式", "Supplementary files"), systemImage: "archivebox", url: supplementURL)
                }
            }
        }
    }

    private var figure1: some View {
        figureCard(
            number: 1,
            title: t("4つの予測法", "Four prediction methods"),
            purpose: t(
                "機構モデル1種と統計・機械学習モデル3種の考え方を並べた概念図です。性能比較のグラフではありません。",
                "A conceptual comparison of one mechanistic model and three statistical or machine-learning models; it is not a performance chart."
            )
        ) {
            panelGrid([
                PanelNote(
                    panel: "(a)",
                    title: "Fick",
                    body: t(
                        "MNと皮膚の対称な2次元断面を格子化し、濃度 C を隣接要素間で拡散させます。本文の支配式は ∂C/∂t = D(∂²C/∂x² + ∂²C/∂y²)。",
                        "The symmetric 2-D MN–skin section is meshed and concentration C diffuses between neighboring elements. The governing equation in the text is ∂C/∂t = D(∂²C/∂x² + ∂²C/∂y²)."
                    )
                ),
                PanelNote(
                    panel: "(b)",
                    title: "MLR",
                    body: t(
                        "7特徴量の線形和で透過量または透過率を表す基準モデル。散布点と直線は説明用で、191点の実測散布図ではありません。",
                        "A baseline that expresses amount or percentage as a linear sum of seven features. The dots and line are illustrative, not a plot of the 191 observations."
                    )
                ),
                PanelNote(
                    panel: "(c)",
                    title: "Random Forest",
                    body: t(
                        "独立に作った多数の決定木を回帰では平均します。図中の “Majority-voting / Final Class” は分類の説明図で、本研究の連続値回帰そのものではありません。",
                        "Many independently grown trees are averaged for regression. The figure’s “Majority-voting / Final Class” labels describe classification, not this study’s continuous regression target."
                    )
                ),
                PanelNote(
                    panel: "(d)",
                    title: "XGBoost",
                    body: t(
                        "前の木の誤差を次の木が補正し、損失と木の複雑さを合わせた目的関数を最小化します。",
                        "Successive trees correct earlier errors while minimizing an objective combining training loss and tree complexity."
                    )
                )
            ])

            LabNotice(
                title: t("読み方", "How to read it"),
                message: t(
                    "4法の出力は累積透過量または累積透過率です。ML側の入力は皮膚種、MN種、長さ、表面積、薬物負荷量、時間、分子量の7項目です。",
                    "All four methods output cumulative amount or cumulative percentage. The ML inputs are skin type, MN type, length, surface area, loading, time, and molecular weight."
                )
            )
        }
    }

    private var figure2: some View {
        figureCard(
            number: 2,
            title: t("学習と評価の流れ", "Training and evaluation flow"),
            purpose: t(
                "191行を手作業で整え、70:30に無作為分割して学習・評価した手順を示します。Fickモデルだけは学習せず、文献の拡散係数を使います。",
                "The figure shows manual cleaning of 191 rows followed by a random 70:30 training/test split. Fick’s model is not trained and instead uses literature diffusivities."
            )
        ) {
            VStack(alignment: .leading, spacing: 10) {
                flowStep("1", t("初期データ → 手作業クリーニング", "Initial data → manual cleaning"))
                flowStep("2", t("191点を学習70%・テスト30%へ行単位で無作為分割", "Random row-level split of 191 points: 70% training / 30% test"))
                flowStep("3", t("MLR・RF・XGBoostを学習／Fickは文献値で計算", "Train MLR, RF, and XGBoost / compute Fick from literature values"))
                flowStep("4", t("テスト点で RMSE と R² を報告", "Report RMSE and R² on the test points"))
            }

            LabSection(t("報告されたハイパーパラメータ", "Reported hyperparameters")) {
                keyValueGrid([
                    (t("透過量 XGBoost", "Amount XGBoost"), "depth 4 · eta 0.4 · 100 rounds"),
                    (t("透過率 XGBoost", "Percentage XGBoost"), "depth 3 · eta 0.2 · 45 rounds"),
                    (t("透過量 RF", "Amount RF"), "500 trees · mtry 5"),
                    (t("透過率 RF", "Percentage RF"), "500 trees · mtry 6")
                ])
            }

            LabNotice(
                title: t("再現不能な分割", "Unreproducible split"),
                message: t(
                    "SI2コードは既に分割済みの “train set.csv” と “test set.csv” を読むだけで、その2ファイルも行番号も公開されていません。Data S1の191行には104通りの固有入力しかなく、53組は同じ入力の反復測定です。行単位分割では同一実験系列が学習・テスト双方へ入る危険があります。",
                    "The SI2 code only reads pre-split “train set.csv” and “test set.csv”; neither those files nor row indices are supplied. The 191 Data S1 rows contain only 104 unique input combinations, with 53 replicated combinations, so a row-level split risks placing the same experimental series in both training and test sets."
                ),
                kind: .limitation
            )
        }
    }

    private var figure3: some View {
        figureCard(
            number: 3,
            title: t("データ構成と薬物", "Dataset composition and drugs"),
            purpose: dataStore.isBundledData
                ? t(
                    "6種の透過物について、Data S1の件数と分子構造を示します。下の横棒はアプリがData S1から再集計した監査表示です。",
                    "The figure presents the counts and molecular structures for six permeants. The horizontal bars below are independently recomputed from Data S1 by the app."
                )
                : t(
                    "原図はData S1の6種と分子構造を示します。下の横棒だけは、差し替え後の現在データを再集計した比較表示です。",
                    "The source figure shows the six Data S1 permeants and molecular structures. Only the bars below are recomputed from the current replacement dataset for comparison."
                )
        ) {
            if drugCounts.isEmpty {
                LabNotice(
                    title: t("現在のデータを集計できません", "Current data could not be summarized"),
                    message: t("読み込まれたCSVを確認してください。", "Check the loaded CSV."),
                    kind: .warning
                )
            } else {
                Chart(drugCounts) { item in
                    BarMark(
                        x: .value(t("件数", "Count"), item.count),
                        y: .value(t("薬物", "Drug"), item.drug)
                    )
                    .foregroundStyle(item.color.gradient)
                    .annotation(position: .trailing, alignment: .leading) {
                        Text("\(item.count) · \(percent(item.share))")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                }
                .chartXAxisLabel(
                    dataStore.isBundledData
                        ? t("Data S1の行数", "Rows in Data S1")
                        : t("現在データの行数", "Rows in current data")
                )
                .chartYAxisLabel(t("薬物", "Drug"))
                .frame(height: 280)
                .accessibilityLabel(t("薬物別データ件数", "Data counts by drug"))

                Text(currentDrugCountSummary)
                .font(.callout)
                .foregroundStyle(.secondary)

                if !dataStore.isBundledData {
                    LabNotice(
                        title: t("原著Data S1の基準値", "Original Data S1 reference"),
                        message: t(
                            "原著Data S1はLidocaine 73、BSA 33、GHK 24、Cu 24、Rhodamine B 19、Caffeine 18（計191行）です。Figure 3の整数比率は丸めにより101%になります。",
                            "Original Data S1 contains Lidocaine 73, BSA 33, GHK 24, Cu 24, Rhodamine B 19, and Caffeine 18 (191 rows). Figure 3's rounded integer shares sum to 101%."
                        )
                    )
                }
            }

            LabNotice(
                title: t("本文の明白な誤記", "Clear error in the article text"),
                message: t(
                    "本文はBSAを33%、GHKとcopperを各24%と記載していますが、33・24・24は件数です。正しい比率はそれぞれ17.28%、12.57%、12.57%です。",
                    "The text calls BSA 33% and GHK and copper 24% each, but 33, 24, and 24 are counts. The correct shares are 17.28%, 12.57%, and 12.57%, respectively."
                ),
                kind: .warning
            )

            LabNotice(
                title: t("分子量の表記差", "Molecular-weight discrepancy"),
                message: t(
                    "本文とData S1はBSAを66,000 Daとして学習に使用しますが、Table 2は66,430 Daと記載します。モデル再現には66,000を使い、生物学的な厳密値として両者を混同しないでください。",
                    "The text and Data S1 use 66,000 Da for BSA in modeling, while Table 2 lists 66,430 Da. Use 66,000 to reproduce the supplied data, but do not silently treat the two as the same biological value."
                ),
                kind: .limitation
            )
        }
    }

    private var figure4: some View {
        figureCard(
            number: 4,
            title: t("Fickモデルの時間発展", "Time evolution of the Fick model"),
            purpose: t(
                "Lidocaineの実測点とFick曲線、およびMN–皮膚断面内のモデル濃度が時間とともに均される様子を対応させます。",
                "Lidocaine observations and a Fick curve are paired with the modeled concentration field evolving across an MN–skin cross-section."
            )
        ) {
            panelGrid([
                PanelNote(
                    panel: "(a)",
                    title: t("装置と累積曲線", "Device and cumulative curve"),
                    body: t(
                        "左: 半分のMN、隣接皮膚、下端のreceptor。右: x=時間(h)、y=累積透過量(µg)。灰四角/線がFick、赤丸が実測で、初期加速後に約2.2万µgへ飽和する形です。",
                        "Left: half an MN, adjacent skin, and the receptor boundary. Right: x=time (h), y=cumulative amount (µg); gray squares/line are Fick and red circles are observations, with acceleration followed by a visual plateau near 22,000 µg."
                    )
                ),
                PanelNote(panel: "(b)", title: "15 min", body: t("薬物は主にMN内。皮膚側に急な濃度勾配が生じます。", "Drug remains mainly in the MN, producing a steep gradient into skin.")),
                PanelNote(panel: "(c)", title: "1 h", body: t("MNから皮膚へ高濃度域が広がります。", "The higher-concentration region spreads from MN into skin.")),
                PanelNote(panel: "(d)", title: "3 h", body: t("皮膚深部へ拡散し、受容相への流出が増えます。", "Diffusion advances deeper and flux into the receptor increases.")),
                PanelNote(panel: "(e)", title: "6 h", body: t("空間差が小さくなり、曲線の傾きが緩み始めます。", "Spatial differences shrink and the cumulative slope starts to ease.")),
                PanelNote(panel: "(f)", title: "24 h", body: t("ほぼ一様な低濃度となり、有限リザーバーの平衡に近づきます。", "A nearly uniform lower field indicates approach to equilibrium of a finite reservoir."))
            ])

            LabNotice(
                title: t("カラーバーの注意", "Color-bar caveat"),
                message: t(
                    "共通カラーバーは0–0.002400ですが、論文は単位を明示していません。赤=高、緑/青=低という相対読解に留め、モル濃度などの単位を付け足してはいけません。破線はMNと皮膚の境界です。",
                    "The shared color bar runs from 0 to 0.002400, but the article gives no unit. Read red as higher and green/blue as lower; do not invent a molar or volumetric unit. The dashed line separates MN and skin."
                ),
                kind: .limitation
            )

            LabNotice(
                title: t("再現範囲", "Reproducibility boundary"),
                message: t(
                    "図(a)はlidocaineとだけ記載され、皮膚種、MN種、負荷量、採用した実測反復は特定されません。SI2のCコード例の既定値とも一致を確認できないため、赤点や曲線の座標を正確値として再作図できません。",
                    "Panel (a) is identified only as lidocaine; skin, MN type, loading, and selected replicates are not specified. It cannot be matched unambiguously to the SI2 C-code defaults, so its marker and curve coordinates cannot be recreated as exact values."
                ),
                kind: .warning
            )
        }
    }

    private var figure5: some View {
        figureCard(
            number: 5,
            title: t("Fick感度解析", "Fick sensitivity analysis"),
            purpose: t(
                "1つのパラメータを変えたときの累積透過量の変化を0–24 hで比較します。系列値は凡例から確定できますが、曲線座標の表は公開されていません。",
                "Cumulative amount over 0–24 h is compared while varying one parameter at a time. Legend settings are explicit, but no numerical table of curve coordinates is supplied."
            )
        ) {
            panelGrid([
                PanelNote(
                    panel: "(a)",
                    title: t("拡散係数 D", "Diffusivity D"),
                    body: t(
                        "D=250, 500, 750, 1000 µm²/min。大きいほど立ち上がりと飽和が早く、24 h付近の上限はほぼ共通です。",
                        "D=250, 500, 750, and 1000 µm²/min. Larger D accelerates onset and saturation while the late plateau is broadly shared."
                    )
                ),
                PanelNote(
                    panel: "(b)",
                    title: t("針数 n", "Needle count n"),
                    body: t(
                        "n=50, 100, 200, 400。パッチ総負荷量を固定する仮定では4線が完全に重なり、針数単独の効果はありません。",
                        "n=50, 100, 200, and 400. With total patch loading fixed, all four curves overlap and needle count alone has no effect."
                    )
                ),
                PanelNote(
                    panel: "(c)",
                    title: t("MN長 l", "MN length l"),
                    body: t(
                        "l=250, 500, 750, 1000 µm。長いMNほど深部から拡散を開始し、同じ時刻の透過量が増えます。",
                        "l=250, 500, 750, and 1000 µm. Longer MNs start diffusion deeper and increase amount at a given time."
                    )
                ),
                PanelNote(
                    panel: "(d)",
                    title: t("負荷量 m", "Loaded mass m"),
                    body: t(
                        "m=100, 1,000, 10,000, 50,000 µg。負荷量の増加が透過量を大きく押し上げ、本文はMN長より影響が大きいと結論します。",
                        "m=100, 1,000, 10,000, and 50,000 µg. Increasing load strongly raises amount; the text concludes its effect exceeds that of MN length."
                    )
                )
            ])

            LabNotice(
                title: t("実験範囲ではなく仮想感度", "Hypothetical sensitivity, not the observed design"),
                message: t(
                    "(b)の50/100/200/400本はTable 1の実験値64/351本と異なり、(c)の250/500 µmはData S1の最小700 µmより短い値です。他の固定条件も十分に記載されないため、曲線を実測結果として扱わないでください。",
                    "The 50/100/200/400 needles in (b) differ from the Table 1 experimental counts of 64/351, and 250/500 µm in (c) are below the 700 µm minimum in Data S1. Other held-constant settings are incompletely reported, so these curves must not be treated as observations."
                ),
                kind: .limitation
            )
        }
    }

    private var figure6: some View {
        figureCard(
            number: 6,
            title: t("予測と実測 — 透過量", "Predicted vs observed — amount"),
            purpose: t(
                "9つのdrug×skin群でテスト点を比較します。原図のx軸は時間(h)、y軸は累積透過量(µg)。黒四角=XGBoost、赤丸=実測、青上三角=RF、緑下三角=Fickで、MLRは混雑回避のため省略されています。",
                "Test points are compared across nine drug×skin groups. In the source, x=time (h) and y=cumulative amount (µg): black square=XGBoost, red circle=observed, blue up-triangle=RF, green down-triangle=Fick. MLR is omitted to reduce crowding."
            )
        ) {
            rawRangeSection(outcome: .amount)

            LabNotice(
                title: t("透過量の単位は表記が揺れます", "Amount units are labeled inconsistently"),
                message: t(
                    "Figure 4/6とTable 2/4はµg、Data S1列名はµg/cm²です。本文はFranzセルの値を1 cm²の透過窓へ正規化したと説明します。数値を総投与量とみなさず、「1 cm²へ正規化した累積量」と明記してください。",
                    "Figures 4/6 and Tables 2/4 use µg, while the Data S1 column header uses µg/cm². The text says Franz-cell values were normalized to a 1 cm² diffusion window. Do not present the number as an unqualified total dose; label it cumulative amount normalized to 1 cm²."
                ),
                kind: .limitation
            )

            LabSection(t("Table 4の報告値 — 透過量", "Table 4 reported values — amount")) {
                Chart(PaperMetric.reported) { metric in
                    BarMark(
                        x: .value(t("モデル", "Model"), metric.model.rawValue),
                        y: .value("RMSE (µg)", metric.amountRMSE)
                    )
                    .foregroundStyle(metric.model.color.gradient)
                    .annotation(position: .top) {
                        VStack(spacing: 1) {
                            Text(metric.amountRMSE.formatted(.number.precision(.fractionLength(0))))
                            Text("R² \(metric.amountR2.formatted(.number.precision(.fractionLength(2))))")
                                .foregroundStyle(.secondary)
                        }
                        .font(.caption2.monospacedDigit())
                    }
                }
                .chartYAxisLabel("RMSE (µg)")
                .frame(height: 260)
                .accessibilityLabel(t("Table 4の透過量RMSEとR二乗", "Table 4 amount RMSE and R-squared"))
            }

            LabNotice(
                title: t("Table 4は内部整合しません", "Table 4 is internally inconsistent"),
                message: t(
                    "論文式では RMSE²=(1−R²)×テスト実測値の分散です。XGBoostのRMSE 4,447.23 µgとR²=0.98は標準偏差約31,447 µgを要求しますが、論文が示す全範囲0–30,000 µgを超えます。両値を同じテスト集合・同じ定義の検証済み指標として扱えません。",
                    "Under the paper’s equations, RMSE²=(1−R²)×the variance of observed test values. XGBoost RMSE 4,447.23 µg with R²=0.98 would require a test SD of about 31,447 µg, larger than the paper’s entire 0–30,000 µg range. The two values cannot both be treated as validated metrics from the same test set and definitions."
                ),
                kind: .warning
            )

            LabNotice(
                title: t("原図と監査チャートの違い", "Source figure vs audit chart"),
                message: dataStore.isBundledData
                    ? t(
                        "原図は非公開の無作為テスト部分集合です。上のレンジはData S1全191点の実測値を再集計したもので、予測点を再現したものではありません。小標本のRhodamine B (n=19) とCaffeine (n=18) では原図でも偏差が目立ちます。",
                        "The source uses an undisclosed random test subset. The ranges above are recomputed from all 191 observed Data S1 rows and do not recreate prediction markers. The paper itself notes conspicuous deviations for the small Rhodamine B (n=19) and Caffeine (n=18) groups."
                    )
                    : t(
                        "原図は非公開のData S1テスト部分集合です。上のレンジだけは現在の差し替えデータ全行から再集計した比較表示で、原著の予測点を再現しません。原著ではRhodamine B (n=19) とCaffeine (n=18) の偏差が目立ちます。",
                        "The source uses an undisclosed Data S1 test subset. Only the ranges above are recomputed from every row of the current replacement data; they do not recreate the paper's prediction markers. The source shows conspicuous deviations for Rhodamine B (n=19) and Caffeine (n=18)."
                    ),
                kind: .limitation
            )
        }
    }

    private var figure7: some View {
        figureCard(
            number: 7,
            title: t("予測と実測 — 透過率", "Predicted vs observed — percentage"),
            purpose: t(
                dataStore.isBundledData
                    ? "Figure 6と同じ9群・同じ記号を、y軸だけ累積透過率(%)へ変えた比較です。下の監査チャートはData S1全行の実測レンジです。"
                    : "原図はFigure 6と同じ9群・同じ記号で累積透過率(%)を比較します。下の監査チャートだけは現在の差し替えデータの全群を示します。",
                dataStore.isBundledData
                    ? "The same nine groups and symbols as Figure 6 are shown with cumulative percentage (%) on the y-axis. The audit chart below uses observed ranges from all Data S1 rows."
                    : "The source compares cumulative percentage (%) for the same nine groups and symbols as Figure 6. Only the audit chart below shows every group in the current replacement data."
            )
        ) {
            rawRangeSection(outcome: .percentage)

            LabSection(t("Table 4の報告値 — 透過率", "Table 4 reported values — percentage")) {
                Chart(PaperMetric.reported) { metric in
                    BarMark(
                        x: .value(t("モデル", "Model"), metric.model.rawValue),
                        y: .value(t("RMSE（ポイント）", "RMSE (points)"), metric.percentageRMSE)
                    )
                    .foregroundStyle(metric.model.color.gradient)
                    .annotation(position: .top) {
                        VStack(spacing: 1) {
                            Text(metric.percentageRMSE.formatted(.number.precision(.fractionLength(1))))
                            Text("R² \(metric.percentageR2.formatted(.number.precision(.fractionLength(2))))")
                                .foregroundStyle(.secondary)
                        }
                        .font(.caption2.monospacedDigit())
                    }
                }
                .chartYAxisLabel(t("RMSE（パーセントポイント）", "RMSE (percentage points)"))
                .frame(height: 260)
                .accessibilityLabel(t("Table 4の透過率RMSEとR二乗", "Table 4 percentage RMSE and R-squared"))
            }

            LabNotice(
                title: t("透過量と透過率は独立ではありません", "Amount and percentage are not independent"),
                message: t(
                    "Data S1の全191行で amount = loading × percentage / 100 が丸め誤差内で成立します。したがってFigure 6と7は独立な2アウトカムではなく、負荷量を介した決定的変換です。amountモデルでloadingが重要になることの一部はこの定義自体によります。",
                    "For all 191 Data S1 rows, amount = loading × percentage / 100 within rounding error. Figures 6 and 7 are therefore not independent outcomes but deterministic transforms through loading. Part of loading’s importance in the amount model follows directly from that definition."
                ),
                kind: .warning
            )

            LabNotice(
                title: t("100%を超える実測値", "An observed value above 100%"),
                message: t(
                    "BSA、負荷量1,087 µg、48 hの1行は108.3982%です。測定・正規化のばらつきの可能性がありますが、一次データに理由はありません。黙って100%へ切り詰めず、品質フラグ付きで保持すべきです。",
                    "One BSA row at loading 1,087 µg and 48 h is 108.3982%. Measurement or normalization variation is plausible, but the primary data give no explanation. Preserve it with a quality flag rather than silently clipping to 100%."
                ),
                kind: .limitation
            )

            LabNotice(
                title: t("透過率指標も両立不能", "Percentage metrics are also incompatible"),
                message: t(
                    "XGBoostのRMSE 28.24ポイントとR²=0.98は実測標準偏差約199.7ポイントを要求しますが、Data S1の全範囲は0.0198–108.3982%です。R²を「98%精度」と言い換えてはいけません。",
                    "XGBoost RMSE 28.24 points with R²=0.98 would require an observed SD of about 199.7 points, while the full Data S1 range is 0.0198–108.3982%. R² must not be relabeled as “98% accuracy.”"
                ),
                kind: .warning
            )
        }
    }

    private var figure8: some View {
        figureCard(
            number: 8,
            title: t("特徴量重要度", "Feature importance"),
            purpose: t(
                "RFとXGBoostについて、透過率と透過量の各モデルでどの入力が予測に寄与したかを示します。補助チャートは原図と本文の順位だけを符号化し、棒の高さを正確な割合として転記しません。",
                "For RF and XGBoost, the figure shows which inputs contributed to percentage and amount prediction. The audit charts encode only the rank supported by the image and text; raster bar heights are not transcribed as exact percentages."
            )
        ) {
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 310), spacing: 16)],
                alignment: .leading,
                spacing: 16
            ) {
                ForEach(featurePanels) { panel in
                    qualitativeImportanceChart(panel)
                }
            }

            LabNotice(
                title: t("原著が支持する結論", "Conclusion supported by the source"),
                message: t(
                    "透過率ではMN表面積と時間、透過量では薬物負荷量と時間が主要です。本文はRFのその他特徴を透過率で12%未満、透過量で7%未満、XGBoost透過率のdrug contentを3%未満と記載します。",
                    "MN surface area and time are key for percentage; loading and time are key for amount. The text says other RF features are below 12% for percentage and below 7% for amount, and XGBoost drug content is below 3% for percentage."
                )
            )

            LabNotice(
                title: t("“%”を共通の構成比と解釈しない", "Do not read every “%” as a common share"),
                message: t(
                    "RFの(a)の棒は目視合計が100%を超え、SI2はrandomForestのimportance/varImpPlotを使用します。XGBoostのGainと同じ正規化構成比とは確認できません。また本文の「3%未満」と原図のdrug contents棒にも視覚的不一致があります。正確値は公開出力なしに復元できません。",
                    "The RF bars in (a) visually sum above 100%, and SI2 calls randomForest importance/varImpPlot; they are not shown to be the same normalized shares as XGBoost Gain. The text’s “below 3%” also appears visually inconsistent with the drug-contents bar. Exact values cannot be recovered without the missing model output."
                ),
                kind: .warning
            )

            LabNotice(
                title: t("重要度は因果や方向ではありません", "Importance is neither causality nor direction"),
                message: t(
                    "重要度だけでは「表面積を増やせば透過率が上がる」という符号や因果を証明できません。分子量は6薬物をほぼ識別し、表面積・長さ・MN種も薬物/研究条件と強く交絡します。未見薬物への一般化根拠には使えません。",
                    "Importance alone does not establish the sign or causal claim that increasing area raises percentage. Molecular weight nearly identifies the six drugs, while area, length, and MN type are strongly confounded with drug and study conditions. This is not evidence of generalization to unseen drugs."
                ),
                kind: .limitation
            )
        }
    }

    private var supplementalAudit: some View {
        LabSection(t("補足資料の再現性監査", "Supplementary reproducibility audit")) {
            VStack(alignment: .leading, spacing: 12) {
                LabNotice(
                    title: "SI2 · " + t("コード", "code"),
                    message: t(
                        "公開Rコードは分割済みCSVを必要とし、Table 4のRMSE/R²を計算しません。掲載Cコードは複数の宣言末尾セミコロンが欠け、文字列の改行が /n で、pf3を開くものの使用・closeしないため、そのままではコンパイルできません。透過量用ハイパーパラメータの完全なRコードもありません。",
                        "The R listing requires missing pre-split CSVs and does not compute Table 4 RMSE/R². The published C listing lacks semicolons after multiple declarations, uses /n instead of newline escapes, and opens pf3 without use or close, so it does not compile verbatim. Complete R code for the amount hyperparameters is also absent."
                    ),
                    kind: .warning
                )

                LabNotice(
                    title: "SI3 · " + t("未見薬物テスト", "unseen-drug test"),
                    message: t(
                        "薬物を丸ごと学習から外すFigure S1/S2ではRF・XGBoostが大きく外れ、負値など物理的に不可能な予測も出ます。著者自身も、対象薬物が学習集合に含まれる場合に限って設計比較へ使えると結論します。",
                        "When an entire drug is removed from training in Figures S1/S2, RF and XGBoost miss badly and sometimes predict physically impossible negative values. The authors themselves limit design use to cases where the target drug is represented in training."
                    ),
                    kind: .warning
                )

                LabNotice(
                    title: t("Figure S1の組版不整合", "Figure S1 assembly inconsistencies"),
                    message: t(
                        "Data S1と照合すると、S1(c)の赤点レンジはGHK(R)の194.20–916.94 µgと一致しません。またS1(h)/(i)の赤点はCu(R)/Cu(H)のレンジと逆に対応して見えます。補足図の点を薬物別の正確値として再利用しないでください。",
                        "Against Data S1, the red range in S1(c) does not match GHK(R), 194.20–916.94 µg. The red series in S1(h)/(i) also appear to correspond to the opposite Cu(R)/Cu(H) ranges. Do not reuse supplementary markers as exact drug-specific values."
                    ),
                    kind: .limitation
                )

                Link(destination: supplementURL) {
                    Label(t("Europe PMCからData S1・SI2・SI3を開く", "Open Data S1, SI2, and SI3 at Europe PMC"), systemImage: "arrow.up.right.square")
                }
            }
        }
    }

    // MARK: - Shared figure presentation

    private func figureCard<Content: View>(
        number: Int,
        title: String,
        purpose: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(t("図\(number)", "Figure \(number)"))
                    .font(.caption.bold())
                    .foregroundStyle(.tint)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(Color.accentColor.opacity(0.10), in: Capsule())
                Text(title)
                    .font(.title2.bold())
                Spacer(minLength: 0)
            }

            Text(purpose)
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            if let url = figureURLs[number] {
                paperImage(number: number, url: url)
                    .aspectRatio(figureAspectRatios[number] ?? 1.3, contentMode: .fit)
            }

            VStack(alignment: .leading, spacing: 16) {
                content()
            }

            Divider()

            VStack(alignment: .leading, spacing: 4) {
                Text(
                    t(
                        "出典: Yuan et al., Bioengineering & Translational Medicine 8(6), e10512 (2023), Figure \(number).",
                        "Source: Yuan et al., Bioengineering & Translational Medicine 8(6), e10512 (2023), Figure \(number)."
                    )
                )
                .font(.caption)
                .foregroundStyle(.secondary)
                Link("CC BY 4.0", destination: licenseURL)
                    .font(.caption)
            }
        }
        .padding(20)
        .labCard(radius: 18)
        .accessibilityIdentifier("figure.card.\(number)")
    }

    private func paperImage(number: Int, url: URL) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white)

            AsyncImage(url: url, transaction: Transaction(animation: .easeInOut)) { phase in
                switch phase {
                case .empty:
                    VStack(spacing: 10) {
                        ProgressView()
                        Text(t("原著画像を読み込み中", "Loading original figure"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                case let .success(image):
                    image
                        .resizable()
                        .interpolation(.high)
                        .scaledToFit()
                case .failure:
                    VStack(spacing: 10) {
                        Image(systemName: "photo.badge.exclamationmark")
                            .font(.title)
                            .foregroundStyle(.secondary)
                        Text(t("画像を取得できません", "Could not load the figure"))
                            .font(.callout)
                        Link(t("NCBIで画像を開く", "Open image at NCBI"), destination: url)
                    }
                    .padding()
                @unknown default:
                    EmptyView()
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.black.opacity(0.10), lineWidth: 1)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(t("原著の図\(number)", "Original Figure \(number)"))
        .accessibilityHint(t("各パネルの説明は画像の下にあります", "Panel descriptions follow below the image"))
    }

    private func panelGrid(_ panels: [PanelNote]) -> some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 280), spacing: 12)],
            alignment: .leading,
            spacing: 12
        ) {
            ForEach(panels) { panel in
                VStack(alignment: .leading, spacing: 7) {
                    HStack(alignment: .firstTextBaseline, spacing: 7) {
                        Text(panel.panel)
                            .font(.caption.bold())
                            .foregroundStyle(.tint)
                        Text(panel.title)
                            .font(.headline)
                    }
                    Text(panel.body)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(Color.secondary.opacity(0.06), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .accessibilityElement(children: .combine)
            }
        }
    }

    private func flowStep(_ number: String, _ label: String) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Text(number)
                .font(.caption.bold().monospacedDigit())
                .foregroundStyle(.white)
                .frame(width: 26, height: 26)
                .background(Color.accentColor, in: Circle())
            Text(label)
                .font(.callout)
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
    }

    private func keyValueGrid(_ items: [(String, String)]) -> some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 220), spacing: 12)],
            alignment: .leading,
            spacing: 10
        ) {
            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                VStack(alignment: .leading, spacing: 3) {
                    Text(item.0)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(item.1)
                        .font(.callout.monospacedDigit())
                }
                .accessibilityElement(children: .combine)
            }
        }
    }

    private func sourceLink(_ title: String, systemImage: String, url: URL) -> some View {
        Link(destination: url) {
            Label(title, systemImage: systemImage)
        }
    }

    // MARK: - Data S1 audit views

    private var observations: [PaperObservation] {
        dataStore.dataset.rows.compactMap { row -> PaperObservation? in
            guard
                let loading = number(row.loading),
                let time = number(row.permeationTime),
                let percentage = number(row.percentage),
                let amount = number(row.amount)
            else { return nil }

            return PaperObservation(
                drug: normalizedDrug(String(describing: row.drug)),
                skin: normalizedSkin(String(describing: row.skin)),
                loading: loading,
                time: time,
                percentage: percentage,
                amount: amount
            )
        }
    }

    private var drugCounts: [DrugCount] {
        let total = observations.count
        guard total > 0 else { return [] }
        let grouped = Dictionary(grouping: observations, by: \.drug)

        return drugOrder.compactMap { drug in
            guard let count = grouped[drug]?.count else { return nil }
            return DrugCount(
                drug: drug,
                count: count,
                share: Double(count) / Double(total),
                color: drugColor(drug)
            )
        }
    }

    private var currentDrugCountSummary: String {
        let prefix = dataStore.isBundledData
            ? t("Data S1再計算", "Data S1 recomputation")
            : t("現在データ再計算", "Current-data recomputation")
        let values = drugCounts.map { item in
            "\(item.drug) \(item.count) (\(item.share.formatted(.percent.precision(.fractionLength(2)).locale(language.locale))))"
        }.joined(separator: ", ")
        let roundingNote = dataStore.isBundledData
            ? t("。原図の整数比率は丸めにより101%になります。", ". Rounded integer shares in the source sum to 101%.")
            : ""
        return "\(prefix): \(values)\(roundingNote)"
    }

    private var observedGroups: [ObservedGroup] {
        let descriptors: [(panel: String, drug: String, skin: String)]
        if dataStore.isBundledData {
            descriptors = panelOrder
        } else {
            let pairs = Set(observations.map { "\($0.drug)|\($0.skin)" })
            descriptors = pairs.sorted().map { pair in
                let values = pair.split(separator: "|", maxSplits: 1).map(String.init)
                return ("", values[0], values[1])
            }
        }

        return descriptors.compactMap { descriptor in
            let values = observations.filter { $0.drug == descriptor.drug && $0.skin == descriptor.skin }
            guard
                !values.isEmpty,
                let timeMin = values.map(\.time).min(),
                let timeMax = values.map(\.time).max(),
                let amountMin = values.map(\.amount).min(),
                let amountMax = values.map(\.amount).max(),
                let percentageMin = values.map(\.percentage).min(),
                let percentageMax = values.map(\.percentage).max()
            else { return nil }

            return ObservedGroup(
                panel: descriptor.panel,
                drug: descriptor.drug,
                skin: descriptor.skin,
                count: values.count,
                timeMin: timeMin,
                timeMax: timeMax,
                amountMin: amountMin,
                amountMax: amountMax,
                percentageMin: percentageMin,
                percentageMax: percentageMax
            )
        }
    }

    @ViewBuilder
    private func rawRangeSection(outcome: AuditedOutcome) -> some View {
        let groups = observedGroups
        if groups.isEmpty {
            LabNotice(
                title: t("現在のデータを読み込めません", "Current data could not be loaded"),
                message: t("実測レンジを作成できませんでした。", "Observed ranges could not be generated."),
                kind: .warning
            )
        } else {
            LabSection(
                dataStore.isBundledData
                    ? t("Data S1全行の実測レンジ", "Observed ranges across all Data S1 rows")
                    : t("現在データ全行の実測レンジ", "Observed ranges across all current rows")
            ) {
                VStack(alignment: .leading, spacing: 12) {
                    Text(
                        t(
                            "横軸は桁差を読みつつ0を正確に保つlog10(1+x)表示です。正確な最小–最大値は下段に併記します。",
                            "The horizontal axis uses log10(1+x) to show orders of magnitude while preserving zero exactly. Exact minimum–maximum values are listed below."
                        )
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)

                    Chart(groups) { group in
                        BarMark(
                            xStart: .value("log10(1+x) minimum", PaperFigureScale.transformed(group.minimum(for: outcome))),
                            xEnd: .value("log10(1+x) maximum", PaperFigureScale.transformed(group.maximum(for: outcome))),
                            y: .value(t("群", "Group"), group.label)
                        )
                        .foregroundStyle(by: .value(t("皮膚", "Skin"), localizedSkin(group.skin)))
                        .cornerRadius(3)

                        PointMark(
                            x: .value("log10(1+x) minimum", PaperFigureScale.transformed(group.minimum(for: outcome))),
                            y: .value(t("群", "Group"), group.label)
                        )
                        .foregroundStyle(by: .value(t("皮膚", "Skin"), localizedSkin(group.skin)))

                        PointMark(
                            x: .value("log10(1+x) maximum", PaperFigureScale.transformed(group.maximum(for: outcome))),
                            y: .value(t("群", "Group"), group.label)
                        )
                        .foregroundStyle(by: .value(t("皮膚", "Skin"), localizedSkin(group.skin)))
                    }
                    .chartXAxisLabel(outcome.axisTitle(language))
                    .chartForegroundStyleScale([
                        t("ラット", "Rat"): Color.indigo,
                        t("ヒト", "Human"): Color.teal
                    ])
                    .frame(height: 320)
                    .accessibilityLabel(outcome.rangeAccessibility(language))

                    LazyVGrid(
                        columns: [GridItem(.adaptive(minimum: 255), spacing: 10)],
                        alignment: .leading,
                        spacing: 8
                    ) {
                        ForEach(groups) { group in
                            VStack(alignment: .leading, spacing: 3) {
                                Text(group.label)
                                    .font(.caption.bold())
                                Text(
                                    t(
                                        "n=\(group.count) · \(short(group.timeMin))–\(short(group.timeMax)) h · \(rangeText(group, outcome: outcome))",
                                        "n=\(group.count) · \(short(group.timeMin))–\(short(group.timeMax)) h · \(rangeText(group, outcome: outcome))"
                                    )
                                )
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.secondary)
                            }
                            .accessibilityElement(children: .combine)
                        }
                    }
                }
            }
        }
    }

    private func qualitativeImportanceChart(_ panel: ImportancePanel) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(panel.panel + " " + panel.title.resolve(language))
                .font(.headline)

            Chart(panel.features) { feature in
                BarMark(
                    x: .value(t("定性的順位", "Qualitative rank"), feature.rank),
                    y: .value(t("特徴量", "Feature"), feature.name.resolve(language))
                )
                .foregroundStyle(rankColor(feature.rank).gradient)
                .annotation(position: .trailing) {
                    Text(rankName(feature.rank))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .chartXScale(domain: 0...3.45)
            .chartXAxis(.hidden)
            .frame(height: 215)
            .accessibilityLabel(panel.accessibility.resolve(language))

            Text(t("長さは順位カテゴリであり、原著の%値ではありません。", "Bar length is an ordinal category, not a percentage from the paper."))
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(12)
        .background(Color.secondary.opacity(0.06), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    // MARK: - Formatting and normalization

    private func t(_ japanese: String, _ english: String) -> String {
        language.text(japanese, english)
    }

    private func number<T>(_ value: T) -> Double? {
        let text = String(describing: value)
            .replacingOccurrences(of: ",", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return Double(text)
    }

    private func normalizedDrug(_ source: String) -> String {
        let value = source.lowercased()
        if value.contains("lido") { return "Lidocaine" }
        if value.contains("bsa") { return "BSA" }
        if value.contains("ghk") { return "GHK" }
        if value.contains("rhod") { return "Rhodamine B" }
        if value.contains("caff") { return "Caffeine" }
        if value.contains("copper") || value == "cu" { return "Cu" }
        return source
    }

    private func normalizedSkin(_ source: String) -> String {
        source.lowercased().contains("rat") ? "Rat" : "Human"
    }

    private func localizedSkin(_ skin: String) -> String {
        skin == "Rat" ? t("ラット", "Rat") : t("ヒト", "Human")
    }

    private func percent(_ ratio: Double) -> String {
        ratio.formatted(
            .percent
                .precision(.fractionLength(1))
                .locale(language.locale)
        )
    }

    private func short(_ value: Double) -> String {
        value.formatted(
            .number
                .precision(.fractionLength(0...4))
                .locale(language.locale)
        )
    }

    private func rangeText(_ group: ObservedGroup, outcome: AuditedOutcome) -> String {
        let minimum = group.minimum(for: outcome)
        let maximum = group.maximum(for: outcome)
        return "\(short(minimum))–\(short(maximum)) \(outcome.unit)"
    }

    private func drugColor(_ drug: String) -> Color {
        switch drug {
        case "Lidocaine": .orange
        case "BSA": .blue
        case "GHK": .red
        case "Cu": .green
        case "Rhodamine B": .gray
        case "Caffeine": .yellow
        default: .accentColor
        }
    }

    private func rankColor(_ rank: Int) -> Color {
        switch rank {
        case 3: .indigo
        case 2: .teal
        case 1: .gray
        default: Color.secondary.opacity(0.35)
        }
    }

    private func rankName(_ rank: Int) -> String {
        switch rank {
        case 3: t("主要", "Key")
        case 2: t("次点", "Secondary")
        case 1: t("低い", "Low")
        default: t("ごく低い", "Minimal")
        }
    }

    private var drugOrder: [String] {
        ["Lidocaine", "BSA", "GHK", "Cu", "Rhodamine B", "Caffeine"]
    }

    private var panelOrder: [(panel: String, drug: String, skin: String)] {
        [
            ("(a)", "BSA", "Rat"),
            ("(b)", "GHK", "Human"),
            ("(c)", "GHK", "Rat"),
            ("(d)", "Rhodamine B", "Rat"),
            ("(e)", "Lidocaine", "Human"),
            ("(f)", "Lidocaine", "Rat"),
            ("(g)", "Caffeine", "Human"),
            ("(h)", "Cu", "Rat"),
            ("(i)", "Cu", "Human")
        ]
    }

    private var featurePanels: [ImportancePanel] {
        let surface = BiText("MN表面積", "MN surface area")
        let loading = BiText("薬物負荷量", "Drug loading")
        let time = BiText("透過時間", "Permeation time")
        let mw = BiText("分子量", "Molecular weight")
        let length = BiText("MN長", "MN length")
        let skin = BiText("皮膚種", "Skin type")
        let method = BiText("MN種（原図: Method）", "MN type (source: Method)")

        return [
            ImportancePanel(
                panel: "(a)",
                title: BiText("RF · 透過率", "RF · percentage"),
                accessibility: BiText("RF透過率では表面積と時間が主要", "For RF percentage, surface area and time rank highest"),
                features: [
                    FeatureRank(name: surface, rank: 3), FeatureRank(name: time, rank: 3),
                    FeatureRank(name: mw, rank: 2), FeatureRank(name: loading, rank: 1),
                    FeatureRank(name: length, rank: 1), FeatureRank(name: skin, rank: 1),
                    FeatureRank(name: method, rank: 1)
                ]
            ),
            ImportancePanel(
                panel: "(b)",
                title: BiText("RF · 透過量", "RF · amount"),
                accessibility: BiText("RF透過量では負荷量と時間が主要", "For RF amount, loading and time rank highest"),
                features: [
                    FeatureRank(name: loading, rank: 3), FeatureRank(name: time, rank: 3),
                    FeatureRank(name: surface, rank: 1), FeatureRank(name: length, rank: 1),
                    FeatureRank(name: method, rank: 1), FeatureRank(name: skin, rank: 1),
                    FeatureRank(name: mw, rank: 1)
                ]
            ),
            ImportancePanel(
                panel: "(c)",
                title: BiText("XGBoost · 透過率", "XGBoost · percentage"),
                accessibility: BiText("XGBoost透過率では表面積が主要、時間が次点", "For XGBoost percentage, surface area is key and time is secondary"),
                features: [
                    FeatureRank(name: surface, rank: 3), FeatureRank(name: time, rank: 2),
                    FeatureRank(name: loading, rank: 1), FeatureRank(name: mw, rank: 0),
                    FeatureRank(name: length, rank: 0), FeatureRank(name: skin, rank: 0),
                    FeatureRank(name: method, rank: 0)
                ]
            ),
            ImportancePanel(
                panel: "(d)",
                title: BiText("XGBoost · 透過量", "XGBoost · amount"),
                accessibility: BiText("XGBoost透過量では負荷量と時間が主要", "For XGBoost amount, loading and time rank highest"),
                features: [
                    FeatureRank(name: loading, rank: 3), FeatureRank(name: time, rank: 3),
                    FeatureRank(name: surface, rank: 0), FeatureRank(name: mw, rank: 0),
                    FeatureRank(name: length, rank: 0), FeatureRank(name: skin, rank: 0),
                    FeatureRank(name: method, rank: 0)
                ]
            )
        ]
    }
}

private struct PanelNote: Identifiable {
    let panel: String
    let title: String
    let body: String
    var id: String { panel + title }
}

private struct PaperObservation {
    let drug: String
    let skin: String
    let loading: Double
    let time: Double
    let percentage: Double
    let amount: Double
}

private struct DrugCount: Identifiable {
    let drug: String
    let count: Int
    let share: Double
    let color: Color
    var id: String { drug }
}

enum PaperFigureScale {
    static func transformed(_ value: Double) -> Double {
        log10(1 + max(value, 0))
    }
}

private enum AuditedOutcome {
    case amount
    case percentage

    var unit: String {
        switch self {
        case .amount: "µg/cm²"
        case .percentage: "%"
        }
    }

    func axisTitle(_ language: AppLanguage) -> String {
        switch self {
        case .amount:
            language.text(
                "log10(1+x) 累積透過量 (µg/cm²、Data S1表記)",
                "log10(1+x) cumulative amount (µg/cm², Data S1 label)"
            )
        case .percentage:
            language.text("log10(1+x) 累積透過率 (%)", "log10(1+x) cumulative percentage (%)")
        }
    }

    func rangeAccessibility(_ language: AppLanguage) -> String {
        switch self {
        case .amount:
            language.text("薬物と皮膚別の実測透過量レンジ", "Observed amount ranges by drug and skin")
        case .percentage:
            language.text("薬物と皮膚別の実測透過率レンジ", "Observed percentage ranges by drug and skin")
        }
    }
}

private struct ObservedGroup: Identifiable {
    let panel: String
    let drug: String
    let skin: String
    let count: Int
    let timeMin: Double
    let timeMax: Double
    let amountMin: Double
    let amountMax: Double
    let percentageMin: Double
    let percentageMax: Double

    var id: String { "\(drug)|\(skin)" }
    var label: String {
        let group = "\(drug) (\(skin == "Rat" ? "R" : "H"))"
        return panel.isEmpty ? group : "\(panel) \(group)"
    }

    func minimum(for outcome: AuditedOutcome) -> Double {
        switch outcome {
        case .amount: amountMin
        case .percentage: percentageMin
        }
    }

    func maximum(for outcome: AuditedOutcome) -> Double {
        switch outcome {
        case .amount: amountMax
        case .percentage: percentageMax
        }
    }
}

private struct ImportancePanel: Identifiable {
    let panel: String
    let title: BiText
    let accessibility: BiText
    let features: [FeatureRank]
    var id: String { panel }
}

private struct FeatureRank: Identifiable {
    let name: BiText
    let rank: Int
    var id: String { name.english }
}
