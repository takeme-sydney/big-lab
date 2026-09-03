import Foundation

enum ExperimentalDataField: Int, CaseIterable, Identifiable, Sendable {
    case drugName
    case loading
    case molecularWeight
    case needleLength
    case skinType
    case needleType
    case surfaceArea
    case permeationTime
    case percentage
    case amount
    case references

    var id: String { sourceHeader }

    var sourceHeader: String {
        TrainingDataSource.expectedHeader[rawValue]
    }

    var shortLabel: BiText {
        switch self {
        case .drugName: BiText("薬物名", "Drug name")
        case .loading: BiText("薬物負荷量", "Drug loading")
        case .molecularWeight: BiText("分子量", "Molecular weight")
        case .needleLength: BiText("MN長", "MN length")
        case .skinType: BiText("皮膚種", "Skin type")
        case .needleType: BiText("MN種", "MN type")
        case .surfaceArea: BiText("MN表面積", "MN surface area")
        case .permeationTime: BiText("透過時間", "Permeation time")
        case .percentage: BiText("累積透過率", "Cumulative percentage")
        case .amount: BiText("累積透過量", "Cumulative amount")
        case .references: BiText("実験出典", "Experimental source")
        }
    }

    var role: BiText {
        switch self {
        case .drugName:
            BiText("識別子（学習特徴量ではない）", "Identifier (not a model feature)")
        case .loading, .molecularWeight, .needleLength, .skinType, .needleType, .surfaceArea, .permeationTime:
            BiText("入力特徴量", "Input feature")
        case .percentage, .amount:
            BiText("実測結果", "Observed outcome")
        case .references:
            BiText("出典", "Provenance")
        }
    }

    var meaning: BiText {
        switch self {
        case .drugName:
            BiText(
                "透過させた物質のデータ上の名称です。薬物名そのものは7つの学習特徴量には含まれません。",
                "The dataset name of the permeant. Drug identity itself is not one of the seven model features."
            )
        case .loading:
            BiText(
                "実験開始時の薬物負荷量（µg）です。原著ではhydrogel MNはパッチ内含浸量、plastic MNはdonor cellへ加えた水溶液中の量で、透過後の測定量ではありません。",
                "Drug loading at the start (µg): drug impregnated in a hydrogel MN patch, or drug in the aqueous solution added to the donor cell for a plastic MN—not the amount later measured as permeated."
            )
        case .molecularWeight:
            BiText(
                "モデル入力に用いる薬物の分子量（Da）です。表示値は現在読み込まれている行の値です。",
                "Molecular weight used as a model input (Da). The displayed value comes from the current row."
            )
        case .needleLength:
            BiText(
                "マイクロニードルの幾何学的な長さ（mm）です。皮膚へ実際に挿入された深さではありません。",
                "Geometric microneedle length (mm); it is not a measured insertion depth in skin."
            )
        case .skinType:
            BiText(
                "実験に使った皮膚のカテゴリです。原データのコードは1=ラット、2=ヒトで、連続量ではありません。",
                "Categorical skin used in the experiment. Source codes are 1=rat and 2=human; this is not continuous."
            )
        case .needleType:
            BiText(
                "MN材料のカテゴリです。原データのコードは1=ハイドロゲル、2=プラスチックです。",
                "Categorical MN material. Source codes are 1=hydrogel and 2=plastic."
            )
        case .surfaceArea:
            BiText(
                "入力特徴量として記録された、パッチ内の全MNの総表面積（mm²）です。単針の面積でも1 cm²の皮膚透過窓でもありません。",
                "Total surface area of all MNs in the patch, recorded as an input feature (mm²). It is neither a single-needle area nor the 1 cm² skin diffusion window."
            )
        case .permeationTime:
            BiText(
                "実験開始から累積結果を読み取った時点（hour）です。各行はその時点の観測であり、粒子軌跡ではありません。",
                "Elapsed time at which the cumulative outcome was read (hours). Each row is a time-point observation, not a particle trajectory."
            )
        case .percentage:
            BiText(
                "負荷量に対する累積透過量の割合（%）です。100%超を含む入力値も暗黙に削除・上限クリップしません。",
                "Cumulative permeated amount relative to loading (%). Input values above 100% are not silently deleted or clipped."
            )
        case .amount:
            BiText(
                "1 cm²の透過窓へ正規化された累積透過量です。JSONでは11列スキーマの見出しどおりµg/cm²を保持します。",
                "Cumulative permeated amount normalized to a 1 cm² window. JSON preserves the 11-column schema unit, µg/cm²."
            )
        case .references:
            BiText(
                "この観測の実験値を報告した文献です。原セルが空欄なら、欠損を文字列化せずJSONのnullで示します。",
                "Publication reporting the experiment. A blank source cell is represented as JSON null, not as an invented string."
            )
        }
    }

    func displayValue(for row: TrainingDataRow, language: AppLanguage) -> String {
        switch self {
        case .drugName:
            row.sourceDrugName
        case .loading:
            "\(ExperimentalRecordCode.sourceNumber(row.loading)) µg"
        case .molecularWeight:
            "\(ExperimentalRecordCode.sourceNumber(row.molecularWeight)) Da"
        case .needleLength:
            "\(ExperimentalRecordCode.sourceNumber(row.needleLength)) mm"
        case .skinType:
            "\(row.skin.sourceCode) — \(row.skin.displayName(language))"
        case .needleType:
            "\(row.needle.sourceCode) — \(row.needle.displayName(language))"
        case .surfaceArea:
            "\(ExperimentalRecordCode.sourceNumber(row.surfaceArea)) mm²"
        case .permeationTime:
            "\(ExperimentalRecordCode.sourceNumber(row.permeationTime)) h"
        case .percentage:
            "\(ExperimentalRecordCode.sourceNumber(row.percentage)) %"
        case .amount:
            "\(ExperimentalRecordCode.sourceNumber(row.amount)) µg/cm²"
        case .references:
            row.reference.isEmpty ? language.text("未記載（null）", "Not supplied (null)") : row.reference
        }
    }

    fileprivate func jsonValue(for row: TrainingDataRow) -> String {
        switch self {
        case .drugName:
            ExperimentalRecordCode.quoted(row.sourceDrugName)
        case .loading:
            ExperimentalRecordCode.sourceNumber(row.loading)
        case .molecularWeight:
            ExperimentalRecordCode.sourceNumber(row.molecularWeight)
        case .needleLength:
            ExperimentalRecordCode.sourceNumber(row.needleLength)
        case .skinType:
            String(row.skin.sourceCode)
        case .needleType:
            String(row.needle.sourceCode)
        case .surfaceArea:
            ExperimentalRecordCode.sourceNumber(row.surfaceArea)
        case .permeationTime:
            ExperimentalRecordCode.sourceNumber(row.permeationTime)
        case .percentage:
            ExperimentalRecordCode.sourceNumber(row.percentage)
        case .amount:
            ExperimentalRecordCode.sourceNumber(row.amount)
        case .references:
            row.reference.isEmpty ? "null" : ExperimentalRecordCode.quoted(row.reference)
        }
    }
}

enum ExperimentalRecordCode {
    static func json(for row: TrainingDataRow) -> String {
        let members = ExperimentalDataField.allCases.map { field in
            "  \(quoted(field.sourceHeader)): \(field.jsonValue(for: row))"
        }
        return "{\n\(members.joined(separator: ",\n"))\n}"
    }

    static func summary(for row: TrainingDataRow, language: AppLanguage) -> String {
        let time = sourceNumber(row.permeationTime)
        let loading = sourceNumber(row.loading)
        let percentage = sourceNumber(row.percentage)
        let amount = sourceNumber(row.amount)

        return language.text(
            "観測 #\(row.id): \(row.sourceDrugName)を\(row.skin.displayName(language))皮膚と\(row.needle.displayName(language))MNで評価。\(time) h時点の累積透過量は\(amount) µg/cm²で、\(loading) µgの負荷量に対する累積透過率は\(percentage)%です。",
            "Observation #\(row.id): \(row.sourceDrugName) was evaluated with \(row.skin.displayName(language).lowercased()) skin and a \(row.needle.displayName(language).lowercased()) MN. At \(time) h, the cumulative amount is \(amount) µg/cm² and the cumulative percentage of the \(loading) µg loading is \(percentage)%."
        )
    }

    static func sourceNumber(_ value: Double) -> String {
        let roundTripValue = String(value)
        return roundTripValue.hasSuffix(".0") ? String(roundTripValue.dropLast(2)) : roundTripValue
    }

    fileprivate static func quoted(_ value: String) -> String {
        guard
            let data = try? JSONEncoder().encode(value),
            let encoded = String(data: data, encoding: .utf8)
        else {
            return "\"\""
        }
        return encoded
    }
}
