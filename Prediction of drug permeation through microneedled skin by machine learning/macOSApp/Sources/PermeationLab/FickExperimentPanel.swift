import Charts
import SwiftUI

struct FickExperimentPanel: View {
    let language: AppLanguage

    @State private var configuration = FickPreviewConfiguration()
    @State private var result: FickPreviewResult?
    @State private var isRunning = false
    @State private var errorMessage: String?
    @State private var runTask: Task<Void, Never>?

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            LabNotice(
                title: language.text("数値法の再構成", "Numerical-method reconstruction"),
                message: language.text(
                    "Data S2の2次元有限差分更新、対称境界、perfect receptor sinkを再構成しています。25 µm粗視格子でも質量が変わらないよう離散初期質量とsink流束を正規化し、安定なdtを自動選択します。原著の2 µm格子によるTable 4予測ではありません。",
                    "This reconstructs the Data S2 two-dimensional update, symmetry boundary, and perfect receptor sink. It normalizes discrete initial mass and sink flux so the 25 µm preview grid remains mass-consistent, and selects a stable time step automatically. It is not the paper's 2 µm-grid prediction behind Table 4."
                ),
                kind: .limitation
            )

            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 220), spacing: 16)],
                alignment: .leading,
                spacing: 14
            ) {
                numericField(
                    language.text("拡散係数 D (µm²/min)", "Diffusivity D (µm²/min)"),
                    value: $configuration.diffusionCoefficient,
                    range: 50...1_000,
                    identifier: "experiment.fick.diffusivity"
                )
                numericField(
                    language.text("MN長 (µm)", "MN length (µm)"),
                    value: $configuration.needleLength,
                    range: 700...1_250,
                    identifier: "experiment.fick.length"
                )
                numericField(
                    language.text("搭載量 (µg)", "Loaded mass (µg)"),
                    value: $configuration.loadedMass,
                    range: 50...70_940,
                    identifier: "experiment.fick.mass"
                )
                numericField(
                    language.text("時間 (h)", "Duration (h)"),
                    value: $configuration.durationHours,
                    range: 0.25...50,
                    identifier: "experiment.fick.duration"
                )

                VStack(alignment: .leading, spacing: 7) {
                    Text(language.text("MN数", "MN count"))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Picker(language.text("MN数", "MN count"), selection: $configuration.needleCount) {
                        Text("64").tag(64)
                        Text("351").tag(351)
                    }
                    .labelsHidden()
                    .pickerStyle(.segmented)
                    .accessibilityIdentifier("experiment.fick.needle-count")
                    .onChange(of: configuration.needleCount) { _, _ in
                        result = nil
                    }
                }

                VStack(alignment: .leading, spacing: 7) {
                    Text(language.text("固定プレビュー条件", "Fixed preview settings"))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text("skin 1,000 µm · half-domain 250 µm · grid 25 µm")
                        .font(.callout.monospacedDigit())
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            HStack(spacing: 12) {
                Button {
                    run()
                } label: {
                    Label(
                        language.text("Fickプレビューを実行", "Run Fick preview"),
                        systemImage: "waveform.path.ecg"
                    )
                }
                .buttonStyle(.borderedProminent)
                .disabled(isRunning)
                .accessibilityIdentifier("experiment.fick.run")

                Button {
                    runTask?.cancel()
                    configuration = FickPreviewConfiguration()
                    result = nil
                    errorMessage = nil
                } label: {
                    Label(
                        language.text("Data S2例へ戻す", "Reset to Data S2 example"),
                        systemImage: "arrow.counterclockwise"
                    )
                }
                .disabled(isRunning)
                .accessibilityIdentifier("experiment.fick.reset")

                if isRunning {
                    ProgressView()
                        .controlSize(.small)
                    Text(language.text("有限差分を計算中…", "Solving finite differences…"))
                        .foregroundStyle(.secondary)
                }
            }

            if let result {
                resultView(result)
            }

            DisclosureGroup(language.text("原著の完全Fick評価に不足する情報", "Missing inputs for the paper-wide Fick evaluation")) {
                VStack(alignment: .leading, spacing: 7) {
                    missingItem(language.text("薬物ごとの拡散係数対応", "Per-drug diffusivity mapping"))
                    missingItem(language.text("全実験のMN数・断面幅・境界条件", "MN count, cross-section width, and boundaries for every experiment"))
                    missingItem(language.text("テスト行ごとのFick予測出力", "Per-test-row Fick predictions"))
                    missingItem(language.text("Table 4に用いた分割行ID", "Split row IDs used for Table 4"))
                    missingItem(language.text(
                        "Data S2例は50 hだが、本文の範囲上限は48 h",
                        "The Data S2 example uses 50 h, while the paper's stated range ends at 48 h"
                    ))
                }
                .padding(.top, 8)
            }
        }
        .onDisappear {
            runTask?.cancel()
        }
        .alert(
            language.text("Fickプレビューを実行できません", "Unable to run Fick preview"),
            isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private func numericField(
        _ title: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        identifier: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            TextField(title, value: value, format: .number)
                .textFieldStyle(.roundedBorder)
                .accessibilityIdentifier(identifier)
                .onSubmit {
                    result = nil
                }
                .onChange(of: value.wrappedValue) { _, _ in
                    result = nil
                }
            Text(language.text("入力範囲", "Range") + ": "
                + range.lowerBound.formatted() + "–" + range.upperBound.formatted())
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
    }

    private func missingItem(_ text: String) -> some View {
        Label(text, systemImage: "questionmark.diamond")
            .font(.callout)
            .foregroundStyle(.secondary)
    }

    @ViewBuilder
    private func resultView(_ result: FickPreviewResult) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 190), spacing: 14)],
                alignment: .leading,
                spacing: 14
            ) {
                LabMetricCard(
                    title: language.text("最終透過量", "Final amount"),
                    value: result.finalAmount.formatted(.number.precision(.fractionLength(2))) + " µg",
                    detail: language.text("半断面を対称化した数値結果", "Symmetry-expanded numerical result"),
                    systemImage: "sum"
                )
                LabMetricCard(
                    title: language.text("最終透過率", "Final percentage"),
                    value: result.finalPercentage.formatted(.number.precision(.fractionLength(2))) + "%",
                    detail: language.text("搭載量に対する割合", "Share of loaded mass"),
                    systemImage: "percent"
                )
                LabMetricCard(
                    title: language.text("数値計算", "Numerical run"),
                    value: result.iterationCount.formatted(),
                    detail: "dt \(result.actualTimeStepMinutes.formatted(.number.precision(.significantDigits(4)))) min · \(result.gridRows)×\(result.gridColumns)",
                    systemImage: "square.grid.3x3"
                )
                LabMetricCard(
                    title: language.text("質量収支誤差", "Mass-balance error"),
                    value: result.massBalanceError.formatted(
                        .number.precision(.significantDigits(4))
                    ) + " µg",
                    detail: language.text(
                        "クランプなしで初期質量−残存質量−透過量",
                        "Initial − remaining − permeated, without clipping"
                    ),
                    systemImage: "scalemass"
                )
            }

            Chart(result.points) { point in
                LineMark(
                    x: .value(language.text("時間 (h)", "Time (h)"), point.timeHours),
                    y: .value(language.text("累積透過量 (µg)", "Cumulative amount (µg)"), point.permeatedAmount)
                )
                .interpolationMethod(.monotone)
                .foregroundStyle(.blue)
            }
            .chartXAxisLabel(language.text("時間 (h)", "Time (h)"))
            .chartYAxisLabel(language.text("累積透過量 (µg)", "Cumulative amount (µg)"))
            .frame(height: 260)
            .accessibilityLabel(language.text("Fickプレビュー累積透過曲線", "Fick preview cumulative-permeation curve"))
            .accessibilityValue(language.text(
                "最終値\(result.finalAmount.formatted(.number.precision(.fractionLength(2))))マイクログラム",
                "Final value \(result.finalAmount.formatted(.number.precision(.fractionLength(2)))) micrograms"
            ))

            Text(language.text(
                "実行時間 \(result.elapsedSeconds.formatted(.number.precision(.fractionLength(3))))秒 · 陽解法安定条件 D·dt·(1/dx²+1/dy²) ≤ 0.5 を満たすdtを使用",
                "Elapsed \(result.elapsedSeconds.formatted(.number.precision(.fractionLength(3)))) s · dt satisfies the explicit-solver condition D·dt·(1/dx²+1/dy²) ≤ 0.5"
            ))
            .font(.caption.monospacedDigit())
            .foregroundStyle(.secondary)
        }
        .accessibilityIdentifier("experiment.fick.result")
    }

    private func run() {
        runTask?.cancel()
        result = nil
        errorMessage = nil
        guard configurationIsInPreviewRange else {
            errorMessage = language.text(
                "値は各フィールドに表示した範囲内で入力してください。値は自動補正されません。",
                "Enter each value within its displayed range. Values are not corrected automatically."
            )
            return
        }
        isRunning = true
        let snapshot = configuration
        runTask = Task {
            defer { isRunning = false }
            do {
                let worker = Task.detached(priority: .userInitiated) {
                    try FickPreviewEngine.run(snapshot)
                }
                let preview = try await withTaskCancellationHandler {
                    try await worker.value
                } onCancel: {
                    worker.cancel()
                }
                guard !Task.isCancelled else { return }
                result = preview
            } catch is CancellationError {
                // Navigating away is an expected cancellation path.
            } catch FickPreviewError.cancelled {
                // Navigating away is an expected cancellation path.
            } catch {
                errorMessage = language.text("設定値を確認してください。", "Check the preview parameters.")
            }
        }
    }

    private var configurationIsInPreviewRange: Bool {
        configuration.diffusionCoefficient.isFinite
            && (50...1_000).contains(configuration.diffusionCoefficient)
            && configuration.needleLength.isFinite
            && (700...1_250).contains(configuration.needleLength)
            && configuration.loadedMass.isFinite
            && (50...70_940).contains(configuration.loadedMass)
            && configuration.durationHours.isFinite
            && (0.25...50).contains(configuration.durationHours)
    }
}
