import SwiftUI

struct MethodsView: View {
    @State private var codeText = "補足コードを読み込んでいます…"

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                PageHeader(
                    eyebrow: "Methods · Equations 1–11 · Tables 1–3",
                    title: "方法・数式",
                    subtitle: "データ収集、Fick の第2法則、MLR、RF、XGBoost、評価指標と原著設定を一続きに確認できます。",
                    symbol: "function"
                )
                PaperOnlyNotice()

                ForEach(PaperContent.methodTopics) { topic in
                    TopicCard(topic: topic)
                }

                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Fick モデルの5仮定").font(.title2.weight(.bold))
                        Spacer()
                        EvidenceBadge(evidence: .init(location: "2.3", note: "原著に列挙された仮定"))
                    }
                    ForEach(Array(PaperContent.assumptions.enumerated()), id: \.offset) { index, assumption in
                        NumberedPoint(number: index + 1, text: assumption)
                    }
                }
                .studyCard()

                VStack(alignment: .leading, spacing: 16) {
                    Text("原著の全数式").font(.title2.weight(.bold))
                    Text("記号と説明は原著の番号付き式 (1)–(11) に対応します。")
                        .foregroundStyle(.secondary)
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 350), spacing: 14)], spacing: 14) {
                        ForEach(PaperContent.equations) { equation in
                            EquationCard(equation: equation)
                        }
                    }

                    Text("原著の番号なし計算例")
                        .font(.title3.weight(.semibold))
                        .padding(.top, 6)
                    Text("式 (11) の直後に掲載された2つの数値代入例です。原著にない式番号を付けません。")
                        .foregroundStyle(.secondary)
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 350), spacing: 14)], spacing: 14) {
                        ForEach(PaperContent.calculationExamples) { example in
                            CalculationExampleCard(example: example)
                        }
                    }
                }

                HStack(alignment: .top, spacing: 18) {
                    ParameterTableView(
                        title: "Table 1 · Fick 入力",
                        rows: PaperContent.fickParameters,
                        evidence: .init(location: "Table 1", note: "拡散モデルの入力範囲")
                    )
                    ParameterTableView(
                        title: "Table 2 · ML パラメータ",
                        rows: PaperContent.machineLearningFeatures,
                        evidence: .init(location: "Table 2", note: "7入力特徴量＋掲載アウトカム範囲")
                    )
                }

                HyperparameterTableView()

                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Text("Data S2 · 掲載コード").font(.title2.weight(.bold))
                        Spacer()
                        EvidenceBadge(evidence: .init(location: "Data S2", note: "補足DOCXからのプレーンテキスト転記"))
                    }
                    Text("下欄は補足資料の R / C コードをそのまま読める形にしたものです。原著は train set.csv / test set.csv や固定分割、学習済みモデルを同梱しておらず、Cコードにも掲載上の構文欠落があります。本アプリはそれらを推測補完しません。")
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    ScrollView([.horizontal, .vertical]) {
                        Text(codeText)
                            .font(.system(.caption, design: .monospaced))
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(14)
                    }
                    .frame(height: 360)
                    .background(Color(nsColor: .textBackgroundColor), in: RoundedRectangle(cornerRadius: 10))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(.quaternary))
                }
                .studyCard()
            }
            .frame(maxWidth: StudyTheme.contentWidth)
            .padding(28)
            .frame(maxWidth: .infinity)
        }
        .accessibilityIdentifier("methods-screen")
        .task { loadCode() }
    }

    private func loadCode() {
        guard let url = StudyResourceLocator.url(
            name: "yuan2023-supplementary-code",
            extension: "txt"
        ) else {
            codeText = "同梱された Data S2 テキストが見つかりません。"
            return
        }
        do {
            codeText = try String(contentsOf: url, encoding: .utf8)
        } catch {
            codeText = "Data S2 テキストを読み込めません: \(error.localizedDescription)"
        }
    }
}

private struct CalculationExampleCard: View {
    let example: CalculationExample

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text("番号なし計算例")
                    .font(.caption.bold())
                    .foregroundStyle(StudyTheme.accent)
                Text(example.title).font(.headline)
                Spacer()
                EvidenceBadge(evidence: example.evidence)
            }
            Text(example.expression)
                .font(.system(.title3, design: .serif, weight: .medium))
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 8)
            Text(example.explanation)
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .studyCard(padding: 16)
    }
}

private struct EquationCard: View {
    let equation: EquationItem

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text("式 (\(equation.number))")
                    .font(.caption.bold())
                    .foregroundStyle(StudyTheme.accent)
                Text(equation.title).font(.headline)
                Spacer()
                EvidenceBadge(evidence: equation.evidence)
            }
            Text(equation.expression)
                .font(.system(.title3, design: .serif, weight: .medium))
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 8)
            Text(equation.explanation)
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .studyCard(padding: 16)
    }
}

private struct HyperparameterTableView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Table 3 · 最適化ハイパーパラメータ").font(.title3.weight(.semibold))
                Spacer()
                EvidenceBadge(evidence: .init(location: "Table 3", note: "原著の選択値"))
            }
            Grid(alignment: .leading, horizontalSpacing: 28, verticalSpacing: 11) {
                GridRow {
                    Text("アウトカム").font(.caption.bold()).foregroundStyle(.secondary)
                    Text("XGBoost").font(.caption.bold()).foregroundStyle(.secondary)
                    Text("Random Forest").font(.caption.bold()).foregroundStyle(.secondary)
                }
                Divider().gridCellColumns(3)
                ForEach(PaperContent.hyperparameters) { row in
                    GridRow(alignment: .top) {
                        Text(row.outcome).font(.callout.weight(.medium))
                        Text(row.xgboost).font(.callout.monospacedDigit())
                        Text(row.randomForest).font(.callout.monospacedDigit())
                    }
                }
            }
            Text("補足 Data S2 の R コードは透過率用設定のみを掲載しています。")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .studyCard()
    }
}
