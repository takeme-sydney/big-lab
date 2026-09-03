import SwiftUI

/// Dedicated entry point for the 0.85 evidence question. Keeping this separate
/// from generic ML experiments and the 2D mass-transfer simulator reduces the
/// chance that R² is confused with permeated mass or with a paper metric.
struct Fick85AssessmentView: View {
    let language: AppLanguage
    @ObservedObject var dataStore: AppDatasetStore
    @ObservedObject var experimentStore: ExperimentStore
    let importAction: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                LabWorkspaceHeader(
                    title: language.text("Fick 85% エビデンス判定", "Fick 85% evidence assessment"),
                    subtitle: language.text(
                        "1つのR²が示すこと・示さないことを、7段階の証拠で確認",
                        "Use seven evidence steps to see what one R² does and does not establish"
                    ),
                    systemImage: "checkmark.shield"
                )

                if dataStore.dataset.rows.isEmpty {
                    VStack(alignment: .leading, spacing: 14) {
                        LabNotice(
                            title: language.text("最初にCSVを読み込んでください", "Import a CSV to begin"),
                            message: language.text(
                                "確認済みData S1へ自動的に切り替えず、自分の研究データだけを探索的に監査します。",
                                "The audit uses only My Research data and never silently falls back to Verified Data S1."
                            ),
                            kind: .information
                        )
                        Button(action: importAction) {
                            Label(language.text("実験CSVを読み込む", "Import experiment CSV"), systemImage: "square.and.arrow.down")
                        }
                        .buttonStyle(.borderedProminent)
                        .accessibilityIdentifier("fick85.import-data")
                    }
                } else {
                    FickValidationPanel(
                        language: language,
                        dataset: dataStore.dataset,
                        datasetSnapshot: experimentStore.datasetSnapshot
                    )
                }

                LabNotice(
                    title: language.text("研究用途のみ", "Research use only"),
                    message: language.text(
                        "この判定は診断、投与量、治療効果、毒性、患者安全性には使用できません。0.85はR²目標であり、正解率や透過質量割合ではありません。",
                        "Do not use this assessment for diagnosis, dosing, efficacy, toxicity, or patient safety. The 0.85 target is R², not accuracy or a permeated-mass fraction."
                    ),
                    kind: .warning
                )
            }
            .frame(maxWidth: LabTheme.contentWidth, alignment: .leading)
            .padding(LabTheme.pagePadding)
            .frame(maxWidth: .infinity, alignment: .top)
        }
        .accessibilityIdentifier("screen.fick-85-assessment")
    }
}
