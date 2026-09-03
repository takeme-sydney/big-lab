import Foundation
import SwiftUI

/// Beginner-facing entry point for calculations owned by this project.
/// Published/source-backed material is intentionally absent from this screen.
struct ResearchHomeView: View {
    let language: AppLanguage
    @ObservedObject var dataStore: AppDatasetStore
    let importAction: () -> Void
    let openFickAudit: () -> Void
    let openResearchData: () -> Void
    let openModelLab: () -> Void

    private let evidenceSteps: [ResearchEvidenceStep] = [
        .init(
            number: 1,
            title: BiText("計算を再現", "Reproduce calculation"),
            value: BiText("計算一致", "REPLAY MATCH"),
            detail: BiText("独立Python実装とSwift出力が一致", "Independent Python and Swift outputs agree"),
            status: .met
        ),
        .init(
            number: 2,
            title: BiText("事後的な集約点推定", "Post-hoc aggregation point estimates"),
            value: BiText("0.895 / 0.862", "0.895 / 0.862"),
            detail: BiText(
                "row-pooledとcondition等重みは0.85超。ただし確認ではない",
                "Row-pooled and condition-balanced values exceed 0.85, but are not confirmatory"
            ),
            status: .exploratory
        ),
        .init(
            number: 3,
            title: BiText("頑健性を確認", "Check robustness"),
            value: BiText("未達", "NOT MET"),
            detail: BiText("下側参考値0.780・単純対照R² 0.909", "Lower reference 0.780; simple control R² 0.909"),
            status: .notMet
        ),
        .init(
            number: 4,
            title: BiText("外部データで確認", "Confirm externally"),
            value: BiText("未検証", "NOT TESTED"),
            detail: BiText("独立run・curveの結果がまだない", "No independent run/curve outcome is available"),
            status: .unavailable
        )
    ]

    /// Canonical, audited explanation shown only in My Research. Keeping the
    /// evidence in structured data lets tests detect a missing reason or a
    /// silently changed value before a release is built.
    static let fixedDataS1PublicationReasons: [FickPublicationReason] = [
        .init(
            id: "pooled-variance",
            number: 1,
            category: .statistics,
            title: BiText("全体R²はfamily間の差で高く見え得る", "Pooled R² can look high because families differ"),
            evidence: BiText("全分散の74.25%がfamily間", "74.25% of total variation is between families"),
            plainMeaning: BiText(
                "低い群・中くらいの群・高い群を見分けるだけでも、全行をまとめたR²は上がります。同じfamily内の曲線を正確に当てた証明にはなりません。",
                "Separating low-, medium-, and high-level families can raise pooled R² even when curves within each family are not predicted accurately."
            ),
            auditMeaning: BiText(
                "row-pooled 0.895142とcondition等重み0.861608は0.85超ですが、family平均を除くと0.592792、3 familyを等重みにすると0.338346です。2つの高い集約点だけでは確認になりません。",
                "Row-pooled 0.895142 and condition-balanced 0.861608 exceed 0.85, but removing family means gives 0.592792 and equal weighting of three families gives 0.338346. Two high aggregation points do not establish confirmation."
            )
        ),
        .init(
            id: "family-results",
            number: 2,
            category: .statistics,
            title: BiText("個々のfamilyは1つも0.85に届かない", "No individual family reaches 0.85"),
            evidence: BiText("BSA 0.689 · caffeine −0.101 · lidocaine 0.427", "BSA 0.689 · caffeine −0.101 · lidocaine 0.427"),
            plainMeaning: BiText(
                "3つをまとめた数字は高くても、薬物familyを1つずつ見るとすべて未達です。負のR²は、そのfamilyの平均だけを使う予測より悪いことを表します。",
                "Although the pooled number is high, every family misses the target. A negative R² means performance is worse than predicting that family's mean."
            ),
            auditMeaning: BiText(
                "family別達成を示さないため、全薬物・全皮膚・全MNで85%以上という主張へ一般化できません。",
                "Because family-level attainment is absent, the result cannot support an at-least-0.85 claim across drugs, skin types, or microneedles."
            )
        ),
        .init(
            id: "simple-control",
            number: 3,
            category: .comparison,
            title: BiText("単純な時間補間がFickを上回る", "A simple time interpolation outperforms Fick"),
            evidence: BiText("R² 0.909 > 0.895 · RMSE 8.949 < 9.599 pp", "R² 0.909 > 0.895 · RMSE 8.949 < 9.599 pp"),
            plainMeaning: BiText(
                "複雑なFick形状を使わず、同じfamilyのtraining時系列を補間するだけの対照の方が、主要R²とRMSEで良い結果でした。",
                "A control that simply interpolates training-time curves within each family performs better on the primary R² and RMSE without using the Fick shape."
            ),
            auditMeaning: BiText(
                "この比較はtest outcomeを使いません。したがって0.895をFick式に固有の増分予測性能として解釈できません。",
                "The control does not use test outcomes, so 0.895 cannot be interpreted as incremental predictive value specific to the Fick equation."
            )
        ),
        .init(
            id: "lower-reference",
            number: 4,
            category: .uncertainty,
            title: BiText("下側の参考値が0.85を下回る", "The lower reference value falls below 0.85"),
            evidence: BiText("固定OOF 5 percentile = 0.780 < 0.850", "Fixed-OOF fifth percentile = 0.780 < 0.850"),
            plainMeaning: BiText(
                "データのcondition構成を変えると、85%を下回る結果が無視できません。高い一点だけでは『不確実性を考えても85%以上』とは言えません。",
                "Changing the mix of conditions produces non-negligible results below 0.85. One high point estimate does not establish at least 0.85 under uncertainty."
            ),
            auditMeaning: BiText(
                "20,000回の再標本化は12個の固定済みOOF conditionを並べ替えただけで、モデル再fit・family層別・重複training foldの共分散を扱いません。一般的な95%信頼区間ではありません。",
                "The 20,000 resamples rearrange 12 already-fixed OOF conditions; they do not refit the model, stratify by family, or model covariance from overlapping training folds. This is not a generic 95% confidence interval."
            )
        ),
        .init(
            id: "partial-coverage",
            number: 5,
            category: .scope,
            title: BiText("評価対象はデータ全体ではない", "The evaluation does not cover the full dataset"),
            evidence: BiText("3/9 family · 12/18 condition · 112/191 row", "3/9 families · 12/18 conditions · 112/191 rows"),
            plainMeaning: BiText(
                "0.895は条件を満たした部分集合の数字です。79行、6 condition、6 familyを含む全体性能ではありません。",
                "The 0.895 value belongs to an eligible subset, not performance over the full data; 79 rows, six conditions, and six families are excluded."
            ),
            auditMeaning: BiText(
                "適格条件・family構成・0.85閾値はData S1を見た後の探索です。事前固定した対象集団での確認試験ではありません。",
                "Eligibility, family composition, and the 0.85 threshold were explored after viewing Data S1; this is not a confirmation study in a prespecified population."
            )
        ),
        .init(
            id: "unseen-family",
            number: 6,
            category: .generalization,
            title: BiText("未知familyへの移送に失敗する", "Transport to an unseen family fails"),
            evidence: BiText("Leave-one-family-out R² = −0.136", "Leave-one-family-out R² = −0.136"),
            plainMeaning: BiText(
                "新しいdrug × skin × MN familyを丸ごと隠すと、平均だけを使う予測より悪くなりました。未知薬物で85%以上という証拠はありません。",
                "When an entire drug × skin × MN family is hidden, performance is worse than a mean-only prediction. There is no evidence of at least 0.85 for an unseen drug family."
            ),
            auditMeaning: BiText(
                "主評価は既知family内のcondition補間です。未知family外挿という別のestimandへ0.895を移せません。",
                "The primary estimand is condition interpolation inside known families; 0.895 cannot be transported to the distinct estimand of unseen-family extrapolation."
            )
        ),
        .init(
            id: "independence",
            number: 7,
            category: .validation,
            title: BiText("独立実験単位と外部データがない", "Independent experimental units and external data are missing"),
            evidence: BiText("run/curve/donor/batch/site IDなし · 外部検証0件", "No run/curve/donor/batch/site IDs · zero external validations"),
            plainMeaning: BiText(
                "同じ曲線の複数時点を、別々の独立実験として数えてよいか確認できません。また、別施設・別batchの新しいデータでは一度も試していません。",
                "The data cannot show whether repeated time points come from independent experiments, and the model has never been tested on new data from another site or batch."
            ),
            auditMeaning: BiText(
                "別実装で同じ数値を再現できることは計算再現性です。sampling independence、risk of bias、external validityの証明ではありません。",
                "Agreement between independent implementations establishes computational repeatability, not sampling independence, low risk of bias, or external validity."
            )
        ),
        .init(
            id: "model-identity",
            number: 8,
            category: .model,
            title: BiText("原著2D Fickモデルの再現ではない", "This is not a replay of the paper's 2D Fick model"),
            evidence: BiText("family別A・kのtime-only finite-slab proxy", "Family-specific A/k time-only finite-slab proxy"),
            plainMeaning: BiText(
                "画面の式は時間だけで曲線を作る簡略proxyです。原著の2次元solverやTable 4の予測を再現した値ではありません。",
                "The displayed equation is a simplified, time-only curve proxy. Its value does not reproduce the paper's two-dimensional solver or Table 4 predictions."
            ),
            auditMeaning: BiText(
                "Aとkはtraining outcomeからfitした有効parameterで、拡散係数・分配係数・皮膚厚を個別同定していません。原著Fick R²との差分として報告できません。",
                "A and k are effective parameters fitted from training outcomes; they do not separately identify diffusivity, partitioning, or skin thickness. The result cannot be reported as an improvement over the paper's Fick R²."
            )
        ),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                LabWorkspaceHeader(
                    title: language.text("自分の研究", "My Research"),
                    subtitle: language.text(
                        "計算・CSV・run履歴を確認済み事実から分離して進める",
                        "Keep calculations, CSVs, and run history separate from verified facts"
                    ),
                    systemImage: "scope"
                )

                LabNotice(
                    title: language.text("このタブは研究用です", "This tab is for research"),
                    message: language.text(
                        "ここで作る数値は、論文に書かれた事実へ自動昇格しません。確認済み事実は緑の「事実」タブにだけ表示され、このタブのデータと履歴はオレンジの研究領域にだけ保存されます。",
                        "Numbers produced here are never promoted to paper facts. Verified facts appear only in the green Facts area; this tab's data and history stay in the orange research area."
                    ),
                    kind: .information
                )
                .accessibilityIdentifier("research-home.separation")

                currentDataSection
                auditedResultSection
                whyNotConfirmedSection
                metricPrimerSection
                nextActionSection
            }
            .frame(maxWidth: LabTheme.contentWidth, alignment: .leading)
            .padding(LabTheme.pagePadding)
            .frame(maxWidth: .infinity, alignment: .top)
        }
        .accessibilityIdentifier("screen.research-home")
    }

    private var whyNotConfirmedSection: some View {
        LabSection(language.text(
            "なぜ0.895でも『確認済み85%』ではないのか",
            "Why 0.895 is not a confirmed 0.85 result"
        )) {
            VStack(alignment: .leading, spacing: 16) {
                FickDecisionEquationView(language: language)
                    .accessibilityIdentifier("research-home.reason-summary")

                Text(language.text(
                    "Row-pooled 0.895とcondition等重み0.862は、選ばれた3つの既知family・12 conditions・112時点に対する2つの事後的集約点です。下の8項目は、それらを『確認済み85%』へ広げることを止める独立した理由です。",
                    "Row-pooled 0.895 and condition-balanced 0.862 are two post hoc aggregation points for three selected known families, 12 conditions, and 112 time points. Each item below independently blocks promotion to a ‘confirmed 0.85’ claim."
                ))
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 330), spacing: 14)],
                    alignment: .leading,
                    spacing: 14
                ) {
                    ForEach(Self.fixedDataS1PublicationReasons) { reason in
                        FickPublicationReasonCard(
                            language: language,
                            reason: reason,
                            accessibilityPrefix: "research-home.reason"
                        )
                    }
                }

                LabNotice(
                    title: language.text("現在の正しい判定", "Correct current decision"),
                    message: language.text(
                        "探索的row-pooled点推定はPASS。確認的R² ≥ 0.85、未知family一般化、独立外部検証はNO-GOです。この2つを同じ『成功』へまとめません。",
                        "The exploratory row-pooled point estimate passes. Confirmatory R² ≥ 0.85, unseen-family generalization, and independent external validation are NO-GO. These are not merged into one ‘success’ label."
                    ),
                    kind: .warning
                )
            }
        }
        .accessibilityIdentifier("research-home.why-not-confirmed")
    }

    private var currentDataSection: some View {
        LabSection(language.text("現在の研究データ", "Current research data")) {
            LabResponsiveActionHeader {
                VStack(alignment: .leading, spacing: 6) {
                    Label(
                        dataStore.hasPersonalDataset
                            ? language.text("CSV読込済み", "CSV loaded")
                            : language.text("CSV未読込", "No CSV loaded"),
                        systemImage: dataStore.hasPersonalDataset ? "checkmark.circle.fill" : "tray"
                    )
                    .font(.headline)
                    .foregroundStyle(dataStore.hasPersonalDataset ? .green : .secondary)

                    Text(dataStore.hasPersonalDataset
                        ? language.text(
                            "\(dataStore.displayName) · \(dataStore.dataset.rows.count)行 · 科学的妥当性は未確認",
                            "\(dataStore.displayName) · \(dataStore.dataset.rows.count) rows · scientific validity unverified"
                        )
                        : language.text(
                            "論文Data S1へ自動的に切り替わることはありません。",
                            "The app never falls back to Paper Data S1."
                        ))
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                }
            } actions: {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 10) { currentDataActions }
                    VStack(alignment: .leading, spacing: 8) { currentDataActions }
                }
            }
        }
    }

    @ViewBuilder private var currentDataActions: some View {
        Button(action: openModelLab) {
            Label(language.text("機械学習を始める", "Start machine learning"), systemImage: "wand.and.stars.inverse")
        }
        .buttonStyle(.borderedProminent)
        .accessibilityIdentifier("research-home.open-model-lab")

        Button(action: importAction) {
            Label(
                dataStore.hasPersonalDataset
                    ? language.text("CSVを入れ替える", "Replace CSV")
                    : language.text("CSVを読み込む", "Import CSV"),
                systemImage: "square.and.arrow.down"
            )
        }
        .accessibilityIdentifier("research-home.import")

        Button(action: openResearchData) {
            Label(language.text("データを見る", "View data"), systemImage: "tablecells")
        }
        .accessibilityIdentifier("research-home.open-data")
    }

    private var auditedResultSection: some View {
        LabSection(language.text(
            "固定Data S1研究コピーの再現例",
            "Fixed Data S1 research-copy example"
        )) {
            VStack(alignment: .leading, spacing: 16) {
                LabNotice(
                    title: language.text("現在のCSVの結果ではありません", "Not a result from the active CSV"),
                    message: language.text(
                        "2026-08-30に固定したData S1探索コピー（normalized SHA-256: a0f8cd81f236…）の112/191行を使う事後解析です。別のCSVを読み込んでも、この参考例の値は変わりません。",
                        "This is a post-hoc analysis of 112/191 rows from the Data S1 exploratory copy frozen on 2026-08-30 (normalized SHA-256: a0f8cd81f236…). Importing another CSV does not change these reference values."
                    ),
                    kind: .limitation
                )

                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    Text("R² 0.895")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .monospacedDigit()
                    Text(language.text("点推定は0.85超", "point estimate exceeds 0.85"))
                        .font(.headline)
                        .foregroundStyle(.orange)
                    Spacer()
                    Label(
                        language.text("論文用の確証は未達", "publication claim not confirmed"),
                        systemImage: "xmark.shield.fill"
                    )
                    .font(.headline)
                    .foregroundStyle(.red)
                }

                Text(language.text(
                    "Data S1を見た後に作ったfamily別・time-only Fick proxyの探索的再解析です。R²は正解率でも、85%の薬物が透過した意味でもありません。",
                    "This is a post-hoc exploratory reanalysis of a family-specific, time-only Fick proxy on Data S1. R² is neither classification accuracy nor the fraction of drug permeated."
                ))
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 220), spacing: 14)],
                    alignment: .leading,
                    spacing: 14
                ) {
                    ForEach(evidenceSteps) { step in
                        ResearchEvidenceStepCard(language: language, step: step)
                    }
                }

                Button(action: openFickAudit) {
                    Label(
                        language.text("全指標と条件別グラフを開く", "Open all metrics and condition charts"),
                        systemImage: "chart.xyaxis.line"
                    )
                }
                .buttonStyle(.borderedProminent)
                .accessibilityIdentifier("research-home.open-fick-audit")
            }
        }
        .accessibilityIdentifier("research-home.audited-result")
    }

    private var metricPrimerSection: some View {
        LabSection(language.text("3つの数字だけ先に理解", "Understand these three numbers first")) {
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 250), spacing: 14)],
                alignment: .leading,
                spacing: 14
            ) {
                LabMetricCard(
                    title: "R²",
                    value: language.text("説明したばらつき", "Explained variation"),
                    detail: language.text("1に近いほど良い。%正解率ではない。", "Closer to 1 is better; it is not percent accuracy."),
                    systemImage: "function"
                )
                LabMetricCard(
                    title: "RMSE",
                    value: language.text("大きな誤差を重視", "Weights large errors"),
                    detail: language.text("0に近いほど良い。目的変数と同じ単位。", "Closer to 0 is better; same unit as the outcome."),
                    systemImage: "arrow.up.and.down"
                )
                LabMetricCard(
                    title: "MAE",
                    value: language.text("平均的なずれ", "Typical absolute error"),
                    detail: language.text("0に近いほど良い。外れ値の影響はRMSEより小さい。", "Closer to 0 is better; less outlier-sensitive than RMSE."),
                    systemImage: "ruler"
                )
            }
        }
    }

    private var nextActionSection: some View {
        LabSection(language.text("論文発表へ進む順序", "Path toward publication")) {
            VStack(alignment: .leading, spacing: 12) {
                researchActionRow(
                    "1",
                    language.text("独立run・curve ID付きデータを集める", "Collect data with independent run and curve IDs")
                )
                researchActionRow(
                    "2",
                    language.text("outcomeを見る前にモデル・除外規則・主要指標を固定", "Freeze the model, exclusions, and primary metric before viewing outcomes")
                )
                researchActionRow(
                    "3",
                    language.text("Fickを単純baselineと同じ外部データで比較", "Compare Fick with simple baselines on the same external data")
                )
                researchActionRow(
                    "4",
                    language.text("point R²と片側95%下限の両方が0.85以上か判定", "Require both point R² and the one-sided 95% lower bound to reach 0.85")
                )
            }
        }
    }

    private func researchActionRow(_ number: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(.caption.bold())
                .foregroundStyle(.white)
                .frame(width: 24, height: 24)
                .background(Circle().fill(Color.orange))
                .accessibilityHidden(true)
            Text(text)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

enum FickPublicationReasonCategory: String, Sendable {
    case statistics
    case comparison
    case uncertainty
    case scope
    case generalization
    case validation
    case model

    var color: Color {
        switch self {
        case .statistics: .purple
        case .comparison: .blue
        case .uncertainty: .orange
        case .scope: .indigo
        case .generalization: .pink
        case .validation: .red
        case .model: .teal
        }
    }

    var symbol: String {
        switch self {
        case .statistics: "function"
        case .comparison: "arrow.left.arrow.right"
        case .uncertainty: "chart.line.downtrend.xyaxis"
        case .scope: "square.dashed"
        case .generalization: "arrow.up.right"
        case .validation: "checkmark.shield"
        case .model: "cube.transparent"
        }
    }

    func title(_ language: AppLanguage) -> String {
        switch self {
        case .statistics: language.text("集約", "Aggregation")
        case .comparison: language.text("対照比較", "Comparator")
        case .uncertainty: language.text("不確実性", "Uncertainty")
        case .scope: language.text("対象範囲", "Coverage")
        case .generalization: language.text("一般化", "Generalization")
        case .validation: language.text("独立検証", "Validation")
        case .model: language.text("モデル同一性", "Model identity")
        }
    }
}

struct FickPublicationReason: Identifiable, Sendable {
    let id: String
    let number: Int
    let category: FickPublicationReasonCategory
    let title: BiText
    let evidence: BiText
    let plainMeaning: BiText
    let auditMeaning: BiText
}

/// Builds the same decision explanation from a completed audited run. Unlike
/// the fixed example on Research Home, these values follow the active result.
enum FickPublicationExplanation {
    static func make(
        result: FickValidationRunResult,
        diagnostics: FickValidationDiagnostics
    ) -> [FickPublicationReason] {
        let fick = diagnostics.comparatorSummaries.first { $0.comparator == .fickProxy }
        let control = diagnostics.comparatorSummaries.first { $0.comparator == .familyTimeControl }
        let target = number(result.configuration.targetRSquared)
        let point = number(fick?.rowPooledMetric.rSquared)
        let conditionBalanced = number(fick?.conditionBalancedMetric.rSquared)
        let controlR2 = number(control?.rowPooledMetric.rSquared)
        let lower = number(result.confidenceInterval.oneSidedLower)
        let familyCentered = number(fick?.familyCenteredRSquared)
        let macroFamily = number(fick?.macroFamilyRSquared)
        let unseen = number(diagnostics.leaveOneFamilyOutMetric.rSquared)
        let share = percent(diagnostics.tss.betweenFamilyShare)
        let familyEvidence = diagnostics.recomputedFamilyMetrics.map {
            "\($0.family.drugName) \(number($0.metric.rSquared))"
        }.joined(separator: " · ")
        let missingHierarchy = [
            diagnostics.hierarchy.hasExperimentRunID ? nil : "experiment_run_id",
            diagnostics.hierarchy.hasPermeationCurveID ? nil : "permeation_curve_id",
            diagnostics.hierarchy.hasDonorID ? nil : "donor_id",
            diagnostics.hierarchy.hasBatchID ? nil : "batch_id",
            diagnostics.hierarchy.hasSiteID ? nil : "site_id",
        ].compactMap { $0 }.joined(separator: ", ")

        return [
            .init(
                id: "pooled-variance",
                number: 1,
                category: .statistics,
                title: BiText("全体R²はfamily間の差で高く見え得る", "Pooled R² can look high because families differ"),
                evidence: BiText("全分散の\(share)がfamily間", "\(share) of total variation is between families"),
                plainMeaning: BiText(
                    "familyの水準差だけでも全行をまとめたR²は上がり得ます。同じfamily内の曲線精度とは別の問いです。",
                    "Differences in family levels can raise pooled R². That is a different question from curve accuracy within a family."
                ),
                auditMeaning: BiText(
                    "row-pooled \(point)とcondition等重み\(conditionBalanced)に対し、family内中心化R²は\(familyCentered)、macro-family R²は\(macroFamily)。集約方法で結論が変わるため、高い2集約点だけを確認値にできません。",
                    "Against row-pooled \(point) and condition-balanced \(conditionBalanced), family-centered R² is \(familyCentered) and macro-family R² is \(macroFamily). Because the conclusion changes with aggregation, the two high aggregation points are not confirmatory."
                )
            ),
            .init(
                id: "family-results",
                number: 2,
                category: .statistics,
                title: BiText("family別の達成を別に確認する必要がある", "Family-level attainment must be checked separately"),
                evidence: BiText(familyEvidence, familyEvidence),
                plainMeaning: BiText(
                    "全体をまとめた値が高くても、各薬物familyで同じ性能とは限りません。負のR²は平均だけの予測より悪いことを示します。",
                    "A high pooled value does not imply the same performance in each drug family. A negative R² is worse than a mean-only prediction."
                ),
                auditMeaning: BiText(
                    "全familyでR² ≥ \(target)というgateを満たさなければ、全薬物・全皮膚・全MNへ一般化しません。",
                    "Unless every-family R² reaches \(target), the result is not generalized across drugs, skin types, or microneedles."
                )
            ),
            .init(
                id: "simple-control",
                number: 3,
                category: .comparison,
                title: BiText("Fickを単純対照と比較する", "Compare Fick against a simple control"),
                evidence: BiText("Fick \(point) · simple control \(controlR2)", "Fick \(point) · simple control \(controlR2)"),
                plainMeaning: BiText(
                    "複雑な式は、時間補間だけの方法より明確に役立つことを示す必要があります。",
                    "A more complex equation must show that it adds clear value beyond simple time interpolation."
                ),
                auditMeaning: BiText(
                    "同一foldのtraining rowsだけを使う対照との比較です。対照が同等以上なら、Fick固有の増分性能は確認できません。",
                    "The control uses training rows from the same folds. If it is equal or better, incremental value specific to Fick is not confirmed."
                )
            ),
            .init(
                id: "lower-reference",
                number: 4,
                category: .uncertainty,
                title: BiText("下側の感度値も目標以上か確認する", "Check whether the lower sensitivity value also reaches target"),
                evidence: BiText("固定OOF 5 percentile \(lower) · 目標 \(target)", "Fixed-OOF fifth percentile \(lower) · target \(target)"),
                plainMeaning: BiText(
                    "一点が高くても、condition構成への感度を考えると目標を下回る可能性があります。",
                    "A high point estimate can still fall below target when sensitivity to the condition mix is considered."
                ),
                auditMeaning: BiText(
                    "これは固定済みOOF予測の記述percentileです。モデルを再fitしないため、確認的95%信頼区間や将来成功確率ではありません。",
                    "This is a descriptive percentile of fixed OOF predictions. Because the model is not refitted, it is not a confirmatory 95% confidence interval or future-success probability."
                )
            ),
            .init(
                id: "partial-coverage",
                number: 5,
                category: .scope,
                title: BiText("評価した範囲を全データから分ける", "Separate evaluated scope from the full dataset"),
                evidence: BiText(
                    "\(result.eligibleFamilyCount)/\(result.eligibleFamilyCount + result.excludedFamilyCount) family · \(result.eligibleConditionCount)/\(result.eligibleConditionCount + result.excludedConditionCount) condition · \(result.eligibleObservationCount)/\(result.eligibleObservationCount + result.excludedObservationCount) row",
                    "\(result.eligibleFamilyCount)/\(result.eligibleFamilyCount + result.excludedFamilyCount) families · \(result.eligibleConditionCount)/\(result.eligibleConditionCount + result.excludedConditionCount) conditions · \(result.eligibleObservationCount)/\(result.eligibleObservationCount + result.excludedObservationCount) rows"
                ),
                plainMeaning: BiText(
                    "表示値は適格な部分集合の性能で、除外されたfamily・condition・rowを含む全体性能ではありません。",
                    "The displayed value is subset performance, not performance over excluded families, conditions, and rows."
                ),
                auditMeaning: BiText(
                    "同じデータを見た後に決めたpost-hoc subsetです。対象集団と除外規則をoutcome前に固定した確認試験ではありません。",
                    "This is a post hoc subset selected after viewing the data, not a confirmation study with population and exclusions frozen before outcomes."
                )
            ),
            .init(
                id: "unseen-family",
                number: 6,
                category: .generalization,
                title: BiText("未知familyへ移せるか別に試す", "Test transport to an unseen family separately"),
                evidence: BiText("Leave-one-family-out R² \(unseen)", "Leave-one-family-out R² \(unseen)"),
                plainMeaning: BiText(
                    "既知family内でconditionを隠す試験と、新しいfamily全体を隠す試験は違います。",
                    "Hiding a condition within a known family is not the same as hiding an entirely new family."
                ),
                auditMeaning: BiText(
                    "既知family内のrow-pooled \(point)を、未知drug × skin × MN familyの性能へ外挿できません。",
                    "Known-family row-pooled \(point) cannot be extrapolated to an unseen drug × skin × microneedle family."
                )
            ),
            .init(
                id: "independence",
                number: 7,
                category: .validation,
                title: BiText("独立run・curveと外部データを必要とする", "Independent runs, curves, and external data are required"),
                evidence: BiText("欠落ID: \(missingHierarchy) · 外部検証なし", "Missing IDs: \(missingHierarchy) · no external validation"),
                plainMeaning: BiText(
                    "反復時点を独立実験として数えてよいか確認できず、新しい施設・batchのデータでも試していません。",
                    "It is unclear whether repeated time points are independent experiments, and no new site or batch has been tested."
                ),
                auditMeaning: BiText(
                    "計算再現性はsampling independence、risk of bias、external validityを保証しません。",
                    "Computational repeatability does not establish sampling independence, low risk of bias, or external validity."
                )
            ),
            .init(
                id: "model-identity",
                number: 8,
                category: .model,
                title: BiText("proxyと原著2D Fickを区別する", "Distinguish the proxy from the paper's 2D Fick model"),
                evidence: BiText("family別A・kのtime-only finite-slab proxy", "Family-specific A/k time-only finite-slab proxy"),
                plainMeaning: BiText(
                    "この曲線は時間だけを使う簡略proxyで、原著Table 4の予測再現ではありません。",
                    "This curve is a simplified time-only proxy, not a replay of the paper's Table 4 predictions."
                ),
                auditMeaning: BiText(
                    "fitしたA・kは有効parameterです。原著2D solver、未公開の行設定、物理的Dの同定と同一視できません。",
                    "Fitted A and k are effective parameters; they are not the paper's 2D solver, unpublished row settings, or an identified physical diffusivity."
                )
            ),
        ]
    }

    private static func number(_ value: Double?) -> String {
        guard let value, value.isFinite else { return "undefined" }
        let formatted = String(format: "%.3f", value)
        return formatted.hasPrefix("-") ? "−" + formatted.dropFirst() : formatted
    }

    private static func percent(_ value: Double?) -> String {
        guard let value, value.isFinite else { return "undefined" }
        return String(format: "%.2f%%", value * 100)
    }
}

struct FickDecisionEquationView: View {
    let language: AppLanguage
    let pointValue: String
    let targetValue: String

    init(
        language: AppLanguage,
        pointValue: String = "R² 0.895",
        targetValue: String = "R² ≥ 0.85"
    ) {
        self.language = language
        self.pointValue = pointValue
        self.targetValue = targetValue
    }

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 12) {
                equationPill(
                    title: language.text("探索的な一点", "Exploratory point"),
                    value: pointValue,
                    color: .orange,
                    symbol: "info.circle.fill"
                )
                Text("≠")
                    .font(.title.bold())
                    .accessibilityLabel(language.text("同じ意味ではない", "does not equal"))
                equationPill(
                    title: language.text("確認済みの主張", "Confirmed claim"),
                    value: targetValue,
                    color: .red,
                    symbol: "xmark.shield.fill"
                )
                Spacer(minLength: 0)
            }
            VStack(alignment: .leading, spacing: 10) {
                equationPill(
                    title: language.text("探索的な一点", "Exploratory point"),
                    value: pointValue,
                    color: .orange,
                    symbol: "info.circle.fill"
                )
                Label(
                    language.text("同じ意味ではありません", "These are not equivalent"),
                    systemImage: "not.circle"
                )
                .font(.headline)
                equationPill(
                    title: language.text("確認済みの主張", "Confirmed claim"),
                    value: targetValue,
                    color: .red,
                    symbol: "xmark.shield.fill"
                )
            }
        }
        .padding(16)
        .background(Color.orange.opacity(0.08), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.orange.opacity(0.30), lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(language.text(
            "探索的\(pointValue)と確認済み\(targetValue)は同じ意味ではありません",
            "Exploratory \(pointValue) does not equal confirmed \(targetValue)"
        ))
    }

    private func equationPill(
        title: String,
        value: String,
        color: Color,
        symbol: String
    ) -> some View {
        HStack(spacing: 10) {
            Image(systemName: symbol)
                .foregroundStyle(color)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.caption).foregroundStyle(.secondary)
                Text(value).font(.title2.bold().monospacedDigit())
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(color.opacity(0.08), in: RoundedRectangle(cornerRadius: 11, style: .continuous))
    }
}

struct FickPublicationReasonCard: View {
    let language: AppLanguage
    let reason: FickPublicationReason
    let accessibilityPrefix: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 10) {
                Text(reason.number.formatted())
                    .font(.caption.bold().monospacedDigit())
                    .foregroundStyle(.white)
                    .frame(width: 26, height: 26)
                    .background(Circle().fill(reason.category.color))
                    .accessibilityHidden(true)

                Label(reason.category.title(language), systemImage: reason.category.symbol)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(reason.category.color)

                Spacer(minLength: 0)
                Image(systemName: "xmark.shield.fill")
                    .foregroundStyle(.red)
                    .accessibilityHidden(true)
            }

            Text(reason.title.resolve(language))
                .font(.headline)
                .fixedSize(horizontal: false, vertical: true)

            Text(reason.evidence.resolve(language))
                .font(.title3.bold().monospacedDigit())
                .foregroundStyle(reason.category.color)
                .fixedSize(horizontal: false, vertical: true)

            Text(reason.plainMeaning.resolve(language))
                .font(.callout)
                .fixedSize(horizontal: false, vertical: true)

            Divider()

            VStack(alignment: .leading, spacing: 4) {
                Label(
                    language.text("査読で問題になる理由", "Why reviewers care"),
                    systemImage: "doc.text.magnifyingglass"
                )
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                Text(reason.auditMeaning.resolve(language))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(15)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .labCard(radius: 12)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(reason.title.resolve(language))
        .accessibilityValue(
            reason.evidence.resolve(language)
                + ". " + reason.plainMeaning.resolve(language)
                + " " + reason.auditMeaning.resolve(language)
        )
        .accessibilityIdentifier("\(accessibilityPrefix).\(reason.id)")
    }
}

private struct ResearchEvidenceStep: Identifiable {
    enum Status {
        case met
        case exploratory
        case notMet
        case unavailable

        var symbol: String {
            switch self {
            case .met: "checkmark.circle.fill"
            case .exploratory: "info.circle.fill"
            case .notMet: "xmark.circle.fill"
            case .unavailable: "minus.circle.fill"
            }
        }

        var color: Color {
            switch self {
            case .met: .green
            case .exploratory: .orange
            case .notMet: .red
            case .unavailable: .secondary
            }
        }
    }

    let number: Int
    let title: BiText
    let value: BiText
    let detail: BiText
    let status: Status
    var id: Int { number }
}

private struct ResearchEvidenceStepCard: View {
    let language: AppLanguage
    let step: ResearchEvidenceStep

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("\(step.number)")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                Spacer()
                Image(systemName: step.status.symbol)
                    .foregroundStyle(step.status.color)
                    .accessibilityHidden(true)
            }
            Text(step.title.resolve(language))
                .font(.headline)
            Text(step.value.resolve(language))
                .font(.title2.bold().monospacedDigit())
                .foregroundStyle(step.status.color)
            Text(step.detail.resolve(language))
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, minHeight: 145, alignment: .topLeading)
        .padding(14)
        .labCard(radius: 12)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("research-home.gate.\(step.number)")
    }
}
