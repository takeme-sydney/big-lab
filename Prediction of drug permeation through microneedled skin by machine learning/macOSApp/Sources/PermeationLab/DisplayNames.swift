import Foundation

extension Drug {
    func displayName(_ language: AppLanguage) -> String {
        switch self {
        case .lidocaine: language.text("リドカイン", "Lidocaine")
        case .bsa: language.text("ウシ血清アルブミン (BSA)", "Bovine serum albumin (BSA)")
        case .copper: language.text("銅イオン", "Copper ions")
        case .ghk: language.text("GHKペプチド", "GHK peptide")
        case .rhodamine: language.text("ローダミンB", "Rhodamine B")
        case .caffeine: language.text("カフェイン", "Caffeine")
        }
    }
}

extension SkinType {
    func displayName(_ language: AppLanguage) -> String {
        switch self {
        case .human: language.text("ヒト", "Human")
        case .rat: language.text("ラット", "Rat")
        }
    }
}

extension NeedleType {
    func displayName(_ language: AppLanguage) -> String {
        switch self {
        case .hydrogel: language.text("ハイドロゲル", "Hydrogel")
        case .plastic: language.text("プラスチック", "Plastic")
        }
    }
}

extension Outcome {
    func displayName(_ language: AppLanguage) -> String {
        switch self {
        case .amount: language.text("透過量", "Permeation amount")
        case .percentage: language.text("透過率", "Permeation percentage")
        }
    }

    var unit: String {
        switch self {
        case .amount: "µg/cm²"
        case .percentage: "%"
        }
    }

    func axisTitle(_ language: AppLanguage) -> String {
        "\(displayName(language)) (\(unit))"
    }

    func rmseUnit(_ language: AppLanguage) -> String {
        switch self {
        case .amount:
            language.text(
                "原著Table 4はµgと表記。Data S1は1 cm²に正規化されたµg/cm²。",
                "Table 4 labels this as µg; Data S1 is normalized to a 1 cm² window (µg/cm²)."
            )
        case .percentage:
            language.text("単位：パーセントポイント", "Unit: percentage points")
        }
    }
}

extension ModelKind {
    func localizedDescription(_ language: AppLanguage) -> String {
        switch self {
        case .fick:
            language.text(
                "Fickの第2法則を2次元有限差分で解く機構モデル",
                "Mechanistic 2D finite-difference solution of Fick's second law"
            )
        case .mlr:
            language.text(
                "7特徴量を一次式で結ぶ重回帰",
                "Multiple linear regression over seven features"
            )
        case .rf:
            language.text(
                "多数の回帰木を平均するRandom Forest",
                "Random Forest averaging many regression trees"
            )
        case .xgboost:
            language.text(
                "残差を順次補正する勾配ブースティング木",
                "Gradient-boosted trees that sequentially correct residuals"
            )
        }
    }
}
