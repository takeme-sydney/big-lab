import Foundation

enum PaperContent {
    static let titleJapanese = "機械学習によるマイクロニードル処理皮膚を介した薬物透過の予測"
    static let titleEnglish = "Prediction of drug permeation through microneedled skin by machine learning"
    static let citation = "Yuan Y, Han Y, Yap CW, et al. Bioeng Transl Med. 2023;8(6):e10512."
    static let doi = "10.1002/btm2.10512"
    static let pmid = "38023708"
    static let pmcid = "PMC10658566"
    static let license = "Creative Commons Attribution 4.0 International (CC BY 4.0)"

    static let authors = [
        "Yunong Yuan", "Yiting Han", "Chun Wei Yap", "Jaspreet S. Kochhar",
        "Hairui Li", "Xiaoqiang Xiang", "Lifeng Kang"
    ]

    static let affiliations = [
        "シドニー大学 医学・健康学部 薬学部（オーストラリア）",
        "復旦大学 薬学院 臨床薬学・薬事管理学科（中国）",
        "Harvard T.H. Chan School of Public Health（米国）",
        "National Healthcare Group（シンガポール）",
        "Procter & Gamble（シンガポール）",
        "MGI Tech（シンガポール）"
    ]

    static let overviewTopics: [StudyTopic] = [
        .init(
            id: "problem",
            title: "研究課題",
            summary: "角質層を貫くマイクロニードルは薬物透過を促進するが、Franz 型拡散装置を用いる in vitro 皮膚透過試験には費用と時間を要する。",
            bullets: [
                "MN パッチは長さ数百 µm の針状突起の配列で、皮膚に微小経路を形成する。",
                "透過試験は、動物またはヒトの摘出皮膚を介してレセプター液へ移行した薬物濃度を複数時点で測定する。"
            ],
            evidence: .init(location: "要旨・1. はじめに", note: "研究背景と課題設定")
        ),
        .init(
            id: "aim",
            title: "目的と比較",
            summary: "既報の同系統実験を統合し、累積透過量と累積透過率について Fick の法則、一次 MLR、RF、XGBoost の4手法を比較した。",
            bullets: [
                "手動クリーニング後の191実測点を7:3で無作為に学習・テストへ分割。",
                "統計モデルは7特徴量を使用し、Fick モデルの拡散係数は文献値を使用。",
                "評価指標は RMSE と R²。"
            ],
            evidence: .init(location: "1. はじめに・2.2・2.7・2.8", note: "研究目的、比較手法、評価設計")
        ),
        .init(
            id: "finding",
            title: "主要結果",
            summary: "原著のランダム分割評価では、XGBoost が透過量・透過率の両方で最良だった。",
            bullets: [
                "透過率では MN 表面積と透過時間、透過量では薬物搭載量と透過時間が主要特徴量。",
                "透過量の次点は Fick、透過率の次点は RF。MLR は両アウトカムで最も低い性能。",
                "XGBoost で、ある薬物を意図的に学習データから除外する追加検証では大きな偏差が生じた。"
            ],
            evidence: .init(location: "Table 4・Figure 8・4.2", note: "報告性能、特徴量重要度、未知薬物検証")
        )
    ]

    static let methodTopics: [StudyTopic] = [
        .init(
            id: "collection",
            title: "データ収集",
            summary: "著者らの既報の Franz 型 in vitro 皮膚透過実験から、6薬物・ヒト/ラット皮膚・2種類の MN に関する観測を統合した。",
            bullets: [
                "BSA、ローダミンB、カフェインはヒドロゲル MN、銅イオンと GHK はプラスチック MN。",
                "リドカインにはヒドロゲル MN とプラスチック MN の両方が含まれる。",
                "垂直装置の拡散面積1 cm²と水平装置の1.13 cm²を、1 cm²当たりの累積量へ正規化した。"
            ],
            evidence: .init(location: "2.1・2.3・Data S1", note: "データ来歴と正規化")
        ),
        .init(
            id: "fick",
            title: "Fick の法則",
            summary: "MN と皮膚の中央断面を2次元メッシュとして扱い、Fick の第2法則を Taylor 展開で逐次更新する機構モデル。",
            bullets: [
                "各 MN–皮膚ユニットを独立した反復単位とし、角・下隅・端・下端・内部の5要素に異なる境界条件を設定。",
                "対称性を利用して半分のモデルだけを計算し、レセプター濃度からパッチ全体の累積量を求めた。",
                "Figure 4 では初期の加速、中期の拡散、濃度平衡による最終 plateau を示した。"
            ],
            evidence: .init(location: "2.3・3.2・Figures 1, 4, 5", note: "数値モデル、仮定、感度")
        ),
        .init(
            id: "ml",
            title: "MLR・RF・XGBoost",
            summary: "同じ7特徴量から透過量または透過率を推定する統計モデルを比較した。",
            bullets: [
                "MLR は従属変数と特徴量の一次線形関係を仮定。",
                "RF は独立した多数の決定木の回帰平均。",
                "XGBoost は前の木の結果を次の木へ反映し、学習損失と木の複雑度を含む目的関数を最小化。"
            ],
            evidence: .init(location: "2.4–2.6・Figure 1", note: "3統計モデルの定義")
        ),
        .init(
            id: "process",
            title: "学習と評価",
            summary: "191点を無作為に7:3分割し、テストセットの予測と実測を RMSE・R²で比較した。",
            bullets: [
                "R 4.1.2 / RStudio、XGBoost 1.5.0.2、randomForest 4.7.1。",
                "Fick の C コードは Microsoft Visual Studio 2022 で作成。",
                "補足 Data S2 はモデルコードを示すが、参照する train set.csv / test set.csv と学習済みモデルは補足に含まれない。"
            ],
            evidence: .init(location: "2.8・Table 3・Data S2", note: "ソフトウェア、分割、再現性境界")
        )
    ]

    static let assumptions = [
        "MN の形状は非圧縮性で、挿入後も非分解・非圧縮とする。",
        "MN 内の薬物と各メッシュ要素内の濃度は均一で、薬物は2次元の X・Y 方向にのみ拡散する。",
        "皮膚内の拡散係数は一定で、通常体温で行うため温度の影響を無視する。",
        "薬物は皮膚–レセプター界面を閉塞せず、攪拌されたレセプター液へ直ちに分散する。",
        "すべての実験で皮膚厚を1 mmとする。"
    ]

    static let equations: [EquationItem] = [
        .init(number: 1, title: "Fick の第2法則", expression: "∂C/∂t = D(∂²C/∂x² + ∂²C/∂y²)", explanation: "C は時刻 t の薬物濃度、D は拡散係数。", evidence: .init(location: "式 (1)", note: "2次元拡散")),
        .init(number: 2, title: "累積透過率", expression: "透過率 = (mₜ / m_total) × 100%", explanation: "mₜ は時刻0から t までの累積透過量、m_total は MN 内の総搭載量。", evidence: .init(location: "式 (2)", note: "透過率の定義")),
        .init(number: 3, title: "単回帰", expression: "y = kx + b", explanation: "応答 y、変数 x、傾き k、切片 b。", evidence: .init(location: "式 (3)", note: "線形回帰")),
        .init(number: 4, title: "重回帰", expression: "y = k₁x₁ + k₂x₂ + … + kₙxₙ + b", explanation: "複数の独立変数を一次結合する。", evidence: .init(location: "式 (4)", note: "MLR")),
        .init(number: 5, title: "XGBoost 目的関数", expression: "Obj = Σᵢ l(yᵢ, ŷᵢ) + Σₖ Ω(fₖ)", explanation: "第1項は学習損失、第2項は木の複雑度。", evidence: .init(location: "式 (5)", note: "XGBoost")),
        .init(number: 6, title: "木の複雑度", expression: "Ω(fₖ) = γT + ½λΣⱼwⱼ²", explanation: "γ は最小損失減少量、T は葉数、w は葉スコア、λ は重み。", evidence: .init(location: "式 (6)", note: "正則化")),
        .init(number: 7, title: "RMSE", expression: "RMSE = √[(1/n)Σᵢ(yᵢ − ŷᵢ)²]", explanation: "小さいほど予測と実測が近い。", evidence: .init(location: "式 (7)", note: "評価指標")),
        .init(number: 8, title: "決定係数", expression: "R² = 1 − Σᵢ(ŷᵢ − yᵢ)² / Σᵢ(ȳᵢ − yᵢ)²", explanation: "1に近いほど良いと原著は説明する。", evidence: .init(location: "式 (8)", note: "評価指標")),
        .init(number: 9, title: "ヒドロゲル MN 表面積", expression: "S = πr² + π(Rl + rl)", explanation: "円錐台近似。r は上面半径、R は底面半径、l は母線長。", evidence: .init(location: "式 (9)", note: "単一 MN")),
        .init(number: 10, title: "プラスチック MN 表面積", expression: "S = 4 × ½a × √((a/2)² + h²)", explanation: "正四角錐近似。a は底辺、h は高さ。", evidence: .init(location: "式 (10)", note: "単一 MN")),
        .init(number: 11, title: "パッチ総表面積", expression: "S_total = S × n", explanation: "n はパッチ内の MN 本数。", evidence: .init(location: "式 (11)", note: "総表面積"))
    ]

    static let calculationExamples: [CalculationExample] = [
        .init(id: "plastic-single", title: "プラスチック MN の計算例", expression: "S = 4 × ½ × 0.075 × √((0.075/2)² + 0.7²) = 0.105 mm²", explanation: "原著例の底辺 a=0.075 mm、高さ h=0.7 mmを式 (10)へ代入。原著ではこの行に式番号はない。", evidence: .init(location: "3.3・式 (11) 後", note: "番号なし計算例")),
        .init(id: "plastic-patch", title: "351本パッチの計算例", expression: "S_total = S × n = 0.105 × 351 = 36.855 mm²", explanation: "原著例の単一 MN 表面積と本数 n=351を式 (11)へ代入。原著ではこの行に式番号はない。", evidence: .init(location: "3.3・式 (11) 後", note: "番号なし計算例"))
    ]

    static let fickParameters: [ParameterRow] = [
        .init(name: "拡散係数 D", value: "50–1,000 µm²/min"),
        .init(name: "MN 本数 N", value: "64, 351"),
        .init(name: "MN 長 L", value: "700, 820, 876, 889, 999, 1,250, 1,063 µm"),
        .init(name: "放出時間 t", value: "15 min–48 h"),
        .init(name: "薬物搭載量 m", value: "50–70,940 µg"),
        .init(name: "格子 dx, dy", value: "2 × 2"),
        .init(name: "時間刻み dt", value: "0.00001–0.001 min")
    ]

    static let machineLearningFeatures: [ParameterRow] = [
        .init(name: "皮膚種", value: "ラット (R), ヒト (H)"),
        .init(name: "MN 種", value: "ヒドロゲル, solid"),
        .init(name: "MN 長", value: "700, 820, 889, 1,250, 875.97, 998.62, 1,062.97 µm"),
        .init(name: "MN 表面積", value: "26.76, 28.54, 29.97, 32.13, 32.43, 34.49, 36.86 mm²"),
        .init(name: "薬物搭載量", value: "50–70,940 µg"),
        .init(name: "透過時間", value: "0.08333–48 h"),
        .init(name: "分子量", value: "64, 194, 234, 340, 479, 66,430 Da"),
        .init(name: "透過量", value: "0–30,000 µg")
    ]

    static let hyperparameters: [HyperparameterRow] = [
        .init(outcome: "透過量", xgboost: "max_depth 4 / eta 0.4 / nround 100", randomForest: "500 trees / mtry 5"),
        .init(outcome: "透過率", xgboost: "max_depth 3 / eta 0.2 / nround 45", randomForest: "500 trees / mtry 6")
    ]

    static let reportedMetrics: [ReportedMetric] = [
        .init(model: .xgboost, amountRMSE: 4_447.23, amountR2: 0.98, percentageRMSE: 28.24, percentageR2: 0.98),
        .init(model: .randomForest, amountRMSE: 7_043.97, amountR2: 0.95, percentageRMSE: 34.33, percentageR2: 0.97),
        .init(model: .fick, amountRMSE: 6_778.17, amountR2: 0.95, percentageRMSE: 85.58, percentageR2: 0.82),
        .init(model: .mlr, amountRMSE: 23_398.91, amountR2: 0.46, percentageRMSE: 120.33, percentageR2: 0.65)
    ]

    static let resultTopics: [StudyTopic] = [
        .init(
            id: "fick-result",
            title: "機構モデルの挙動",
            summary: "拡散係数、MN 長、搭載量の増加で透過が増え、同じ総搭載量なら MN 本数は曲線へ影響しなかった。",
            bullets: [
                "Figure 5: D=250/500/750/1,000、n=50/100/200/400、L=250/500/750/1,000、m=100/1,000/10,000/50,000 を比較。",
                "薬物搭載量の影響は MN 長より大きいと報告。",
                "ヒドロゲル向けの拡散モデルを、薬物水溶液が微小経路を満たす近似によりプラスチック MN にも適用。"
            ],
            evidence: .init(location: "3.2・Figures 4, 5", note: "Fick シミュレーション結果")
        ),
        .init(
            id: "comparison",
            title: "4手法の比較",
            summary: "XGBoost は両アウトカムで最小 RMSE・最大 R²。透過量の次点は Fick、透過率の次点は RF。",
            bullets: [
                "Figures 6・7 は実測（赤）、Fick（緑）、RF（青）、XGBoost（黒）を9条件群で比較。",
                "MLR は最も低い性能で、混雑回避のため Figures 6・7から除外。",
                "20点未満のローダミンBとカフェインでは大きな偏差が見られた。"
            ],
            evidence: .init(location: "3.4・Table 4・Figures 6, 7", note: "モデル性能")
        ),
        .init(
            id: "importance",
            title: "特徴量重要度",
            summary: "透過率では MN 表面積と時間、透過量では搭載量と時間が主要特徴量だった。",
            bullets: [
                "RF の透過率では、MW・搭載量・MN 長・皮膚種・MN 種が各12%未満。",
                "RF の透過量では、表面積・MN 長/種・皮膚種・MWが各7%未満。",
                "XGBoost の透過率では搭載量が3%未満で、主要2項以外は関連が小さい。"
            ],
            evidence: .init(location: "3.5・Figure 8", note: "RF/XGBoost の重要度")
        )
    ]

    static let limitations = [
        "データは191点・6薬物で、特にローダミンBとカフェインは20点未満。",
        "XGBoost モデルで、ある薬物を意図的に学習データから除外する検証では、透過量・透過率とも大きな偏差が生じた。",
        "薬物搭載量が50–70,940 µgと広く、XGBoost で重みが大きいため、未知薬物の予測が搭載量に支配されたと著者らは解釈した。",
        "MW、MN 長、MN 種、皮膚種の低い重要度は、小標本により薬物搭載量へ過大な重みが置かれた可能性がある。",
        "著者らが現状で有用とする範囲は、対象薬物が学習セットに含まれる場合の、搭載量や表面積を変えた MN 設計評価。",
        "将来は薬物候補、各薬物の搭載量範囲、MN の種類・形状・本数・間隔を増やす必要がある。"
    ]

    static let figures: [PaperFigure] = [
        .init(id: "figure-1", label: "Figure 1", resourceName: "figure-1", fileExtension: "jpg", caption: "皮膚を介した薬物透過の予測に用いた4手法：Fick の法則、MLR、RF、XGBoost。", readingGuide: "機構モデル、線形モデル、独立木の集合、逐次 boosting の構造を対比する。", evidence: .init(location: "Figure 1", note: "4手法の模式図")),
        .init(id: "figure-2", label: "Figure 2", resourceName: "figure-2", fileExtension: "jpg", caption: "4モデルの学習・予測プロセス。", readingGuide: "データ清掃、分割、統計モデルの学習・hyperparameter 最適化、Fick モデル、テスト評価の順序を示す。", evidence: .init(location: "Figure 2", note: "研究フロー")),
        .init(id: "figure-3", label: "Figure 3", resourceName: "figure-3", fileExtension: "jpg", caption: "6薬物のデータ分布と分子構造。", readingGuide: "Data S1の正確な件数は BSA 33、リドカイン73、ローダミンB19、カフェイン18、GHK24、銅24。", evidence: .init(location: "Figure 3・Data S1", note: "データ構成")),
        .init(id: "figure-4", label: "Figure 4", resourceName: "figure-4", fileExtension: "jpg", caption: "Fick 予測曲線と実測、および15 min・1・3・6・24 hの MN–皮膚内濃度分布。", readingGuide: "有限 reservoir から濃度勾配が消失するまでの拡散と plateau を読む。", evidence: .init(location: "Figure 4", note: "濃度発展")),
        .init(id: "figure-5", label: "Figure 5", resourceName: "figure-5", fileExtension: "jpg", caption: "Fick シミュレーションにおける D、MN 本数、MN 長、搭載量の影響。", readingGuide: "同じ総搭載量では MN 本数の4曲線が重なる。搭載量は MN 長より大きな影響を示す。", evidence: .init(location: "Figure 5", note: "パラメータ感度")),
        .init(id: "figure-6", label: "Figure 6", resourceName: "figure-6", fileExtension: "jpg", caption: "9条件群における累積透過量の実測と Fick・RF・XGBoost 予測の比較。", readingGuide: "MLR は混雑回避のため図から除外。ローダミンBとカフェインで偏差が目立つ。", evidence: .init(location: "Figure 6", note: "透過量比較")),
        .init(id: "figure-7", label: "Figure 7", resourceName: "figure-7", fileExtension: "jpg", caption: "9条件群における累積透過率の実測と Fick・RF・XGBoost 予測の比較。", readingGuide: "Figure 6と同じ条件群で、縦軸を総搭載量に対する割合として比較する。", evidence: .init(location: "Figure 7", note: "透過率比較")),
        .init(id: "figure-8", label: "Figure 8", resourceName: "figure-8", fileExtension: "jpg", caption: "RF と XGBoost における透過率・透過量の特徴量重要度。", readingGuide: "透過率は表面積と時間、透過量は搭載量と時間が主要。", evidence: .init(location: "Figure 8", note: "特徴量重要度")),
        .init(id: "figure-s1", label: "Figure S1", resourceName: "figure-s1", fileExtension: "png", caption: "ある薬物を学習データから除外した、XGBoost による新規薬物の透過量予測。", readingGuide: "9条件群で XGBoost の新規薬物予測に大きな偏差を示す補足検証。", evidence: .init(location: "4.2・Supporting Information Figure S1", note: "XGBoost new-drug prediction・透過量")),
        .init(id: "figure-s2", label: "Figure S2", resourceName: "figure-s2", fileExtension: "png", caption: "ある薬物を学習データから除外した、XGBoost による新規薬物の透過率予測。", readingGuide: "原著が XGBoost の新規薬物予測の限界を述べる根拠。", evidence: .init(location: "4.2・Supporting Information Figure S2", note: "XGBoost new-drug prediction・透過率"))
    ]

    static let contributions: [AuthorContribution] = [
        .init(name: "Yunong Yuan", contribution: "形式解析・調査・方法論・ソフトウェア（主担当）、検証・可視化・執筆（同等）"),
        .init(name: "Yiting Han", contribution: "概念化、データキュレーション、調査、方法論、レビュー・編集（同等）"),
        .init(name: "Chun Wei Yap", contribution: "調査、方法論、監督、レビュー・編集（同等）"),
        .init(name: "Jaspreet S. Kochhar", contribution: "データキュレーション、調査、方法論、レビュー・編集（同等）"),
        .init(name: "Hairui Li", contribution: "データキュレーション、調査、方法論、レビュー・編集（同等）"),
        .init(name: "Xiaoqiang Xiang", contribution: "概念化、資金獲得、調査、方法論、リソース、レビュー・編集（同等）"),
        .init(name: "Lifeng Kang", contribution: "概念化、データキュレーション、形式解析、資金獲得、調査、方法論、プロジェクト管理、リソース、監督、可視化、レビュー・編集（同等）")
    ]
}
