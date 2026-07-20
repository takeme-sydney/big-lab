---
title: Takumi Suehara が BiG Lab でできること — 研究貢献戦略
created: 2026-07-16
updated: 2026-07-16
status: discussion-draft
scope: Yunong Yuan 氏の研究との接点、初期プロジェクト、90日実行計画
---

# Takumi Suehara が BiG Lab でできること — 研究貢献戦略

関連資料:

- [研究面談：予習・準備メモ](meeting-preparation.md)
- [学習・研究参加ロードマップ](learning-roadmap.md)

## 0. 結論

Takumi が BiG Lab で最も価値を出しやすい役割は、最初から新しいバイオインクを独力で開発することでも、大規模なAIモデルを作ることでもない。

最も相性がよいのは、次の役割である。

> **角膜バイオプリンティングの実験結果を、追跡可能・比較可能・再現可能な定量データへ変換する Computational Research Enabler**

Yunong Yuan 氏の研究は、物理モデル、機械学習、材料、3Dプリンティング、実験検証をつなぐことに特徴がある。一方、Takumi の強みは、Medical Science、Visual Arts、Python・3D可視化への接点、プロダクト設計、フルスタック実装、AI支援ワークフローを横断できる点にある。

両者が最も強く接続する場所は、次の中間層である。

```text
実験・画像・装置出力
        ↓
データ定義・品質管理・形状／画像の定量化  ← Takumi の最初の主戦場
        ↓
統計解析・物理モデル・機械学習             ← Yuan 氏の方法論と接続
        ↓
次に試す印刷条件・材料条件の判断
        ↓
図、3Dモデル、ポスター、再現可能な報告
```

### 最優先の初期プロジェクト

第一候補は、以下の小規模パイロットである。

> **Curved Corneal Construct QC Pilot**  
> 既存の画像、スキャン、設計形状のうち利用可能なものを使い、バイオプリント角膜の曲率・厚さ・形状誤差・層の連続性のうち1〜2指標を、再現可能に測定する。

この案が有力な理由は、2025年の角膜3Dプリンティングレビューが、透明性、曲率、機械的強度、異方性、多層構造を角膜固有の重要要件として整理しており、2026年の二層角膜研究も、曲率、透明性、層間構造、細胞生存を主要な評価対象にしているためである。つまり、**「作れたか」だけでなく「目標形状・構造をどの程度再現できたか」を定量化する作業は、研究の中心課題に直接つながる。**

ただし、利用可能な画像・スキャン・CAD・測定装置がない場合は、第一段階を次へ切り替える。

> **Corneal Biofabrication Evidence & Experiment Registry Pilot**  
> 公開文献または承認済みメタデータから、材料、印刷条件、培養条件、形状、光学、力学、細胞評価を同じデータ定義で整理する。

## 1. この文書の前提と限界

この考察は、次の情報を基に作成した。

- 2026年7月16日に提供された Yunong Yuan 氏の研究調査
- BiG Lab フォルダ内の既存面談メモと学習ロードマップ
- Takumi のローカル履歴書、大学計画、ポートフォリオ説明
- 角膜3Dプリンティングレビュー、二層角膜論文、BIENCO公式サイトなどの公開一次情報

現時点では、BiG Lab の未公開データ、実験SOP、使用機器、倫理承認、プロジェクト優先順位、Takumi に期待される正式な担当範囲を確認していない。そのため、本書のプロジェクト案は**研究室へ提案するための仮説**であり、承認済みの研究計画ではない。

また、ローカル履歴書には Python 分析、3D可視化、Blender、bioink printing research の支援経験が記載されているが、このワークスペース内には、その研究の生データ、解析コード、検証結果は保存されていない。したがって、スキルを過大評価せず、最初のパイロットで再現性と精度を実証する必要がある。

## 2. Takumi の現在地を、証拠と推測に分けて評価する

### 2.1 現在の資料から確認できる強み

| 強み | 現在ある証拠 | BiG Lab での意味 |
| --- | --- | --- |
| Medical Science の学習 | University of Sydney の BSc、Medical Science major | 生物・医学の問いを、単なるソフトウェア課題として扱わずに学べる |
| Visual Arts と3D表現 | Visual Arts minor、Mixed Reality、映像・3D作品 | 曲面、多層構造、空間情報、科学図を視覚的に整理できる |
| 研究データへの接点 | SPring-8 データ解析、USyd research intern の履歴 | 科学データを処理し、技術レポートへまとめた経験がある |
| プロダクト実装 | MyPhrase、Totio、Web・モバイル・バックエンド・リリース | 試作品で終わらず、入力から出力まで使えるワークフローにできる |
| 情報設計とUX | ユーザーフロー、デザインシステム、情報構造 | 研究者が迷わず使える入力形式・レポート・内部ツールを設計できる |
| AI支援開発 | Claude Code、Codex、API、モデルの使い分け | 文書化、コードレビュー、テスト生成、探索を加速できる |
| 日英コミュニケーション | 日英の通訳・翻訳、豪州での学業・仕事 | 日英の共同研究、研究説明、図の注釈、手順書整備に活かせる |

参考となるローカル資料:

- [Takumi Suehara résumé](../../takumi-suehara/career/resume-cv/resume/Approved/takumi-suehara-resume.html)
- [USYD Master Plan](../../takumi-suehara/university/notes/usyd-master-plan.md)
- [Portfolio README](../../takumi-suehara/portofolio-website/README.md)

### 2.2 まだ実証されていない能力

次は「できる可能性が高い」が、研究成果としてはまだ実証されていない。

| 領域 | 現在の判断 | 実証方法 |
| --- | --- | --- |
| Pythonによる研究用パイプライン | 学習・使用経験はあるが、検証済みコードの証拠が不足 | 小さなデータから、再実行可能な解析とテストを1本完成させる |
| Computer vision | 研究への応用案はあるが、精度検証済みモデルは未確認 | 手動測定との一致、誤差、失敗例を報告する |
| 3D形状計測 | Blender・3D表現経験はあるが、計量学的な検証は未確認 | 既知寸法の対象で校正し、測定誤差を評価する |
| 統計・機械学習 | 基礎的な接点はあるが、研究設計能力は要強化 | 実験単位、反復、交差検証、信頼区間を指導者と設計する |
| 研究コードの品質保証 | プロダクト開発経験はあるが、研究再現性は別の技能 | raw data固定、環境固定、ログ、テスト、出力履歴を整備する |

### 2.3 現時点で独力担当すべきでないこと

- 細胞培養、バイオインク調製、3Dバイオプリンター操作を、正式な安全・機器トレーニングなしに行うこと
- 角膜組織の臨床的評価や診断を行うこと
- 新規の有限要素・流体・光学モデルを、境界条件や材料パラメータの指導なしに研究結果として提示すること
- 小規模データから深層学習モデルを作り、高い一般化性能を主張すること
- Blenderのレンダリング画像を、測定値や実験証拠の代わりに使うこと
- 未公開データを、許可なく個人GitHub、外部クラウド、外部AIサービスへ送ること

## 3. Yuan 氏の研究との本質的な接点

### 3.1 共通点は「3D」や「AI」ではなく、予測可能な研究工程である

表面的には、Yuan 氏と Takumi の接点は3D、AI、可視化に見える。しかし、より重要な共通点は、複雑な工程を分解し、入力・処理・出力を追跡可能にする姿勢である。

Yuan 氏の方法論は概ね次の形で整理できる。

```text
物理現象の分解
  → 数理・計算モデル
  → 実験条件の比較
  → 実験による検証
  → 医学用途への接続
```

Takumi のプロダクト・データ設計は次の形で接続できる。

```text
研究上の問いの定義
  → データ項目と取得方法の定義
  → 自動処理・品質確認
  → 人間が検証できる可視化
  → 次の実験判断へ戻す
```

そのため、Takumi は Yuan 氏の研究を置き換えるのではなく、**モデルと実験の間にある測定・データ品質・再現性の層を強くする**ことで貢献できる。

### 3.2 機械学習より前に、測定とラベルを標準化する価値が大きい

バイオプリンティングでは、データ数が少なく、材料、装置、担当者、細胞、培養日、画像条件が変わりやすい。その状態で機械学習を先に導入すると、モデルが本当の生物学・材料特性ではなく、撮影条件やバッチ差を学ぶ危険がある。

したがって、Takumi の最初の貢献は「AI予測モデル」よりも次であるべきだ。

1. 何を1サンプルと数えるかを定義する
2. 同じ意味の測定値を同じ単位で保存する
3. raw data、処理条件、出力を結び付ける
4. 人手の評価と自動評価を比較する
5. 失敗例を隠さず記録する

この基盤ができて初めて、Yuan 氏が得意とする物理モデル、機械学習、実験最適化が強くなる。

### 3.3 角膜は「見た目が透明」だけでは評価できない

透明な曲面構造は、一般的な写真測量や画像セグメンテーションにとって難しい対象である。

- 透明でテクスチャが少なく、輪郭抽出や特徴点対応が不安定になる
- 屈折により、写真上の位置と実際の形状がずれる
- 反射、照明、背景、液面によって見かけの透明度が変わる
- 湿潤状態、温度、培養時間で形状が変わる可能性がある
- 曲率、厚さ、透明性、屈折率は別の測定対象である

したがって、通常写真から「透明性」や「光学性能」を直接結論づけてはいけない。写真は、照明と背景を固定した相対的なQCには使える可能性があるが、光学的主張には、分光透過率、haze、屈折率、OCTなど、ラボが認める測定法が必要になる。

この制約を理解した上で、取得装置に合わせて解析を設計できることが、Takumi の3D・可視化スキルを研究価値へ変える条件である。

## 4. 角膜バイオプリンティングを測るための評価地図

人工角膜の成果を一つのスコアにまとめるのではなく、少なくとも次の5領域へ分ける。

| 評価領域 | 代表的な問い | 候補指標 | Takumi の関与 |
| --- | --- | --- | --- |
| Geometry | 目標の曲率・厚さ・輪郭を再現したか | 曲率誤差、厚さ誤差、体積変化、収縮率、表面偏差、層間ずれ | 画像・3Dデータ処理、誤差マップ、レポート自動化 |
| Optical | 光を適切に通し、散乱を抑えられるか | wavelength別透過率、haze、屈折率、空間均一性 | 装置出力の整理、空間マップ、条件比較。測定自体は要指導 |
| Mechanical | 培養・操作・移植を想定した負荷に耐えるか | Young's modulus、破断、圧縮、縫合保持、形状回復 | 機器データ整形、曲線解析、条件比較、動画追跡 |
| Biological | 細胞が生存し、正しい層・形態・機能を示すか | viability、密度、coverage、hexagonality、marker intensity、layer continuity | 顕微鏡画像解析、注釈、QC、統計単位の管理 |
| Process | 同じ条件で再現できるか | バッチ差、run差、operator差、欠損率、失敗率 | experiment registry、データ辞書、版管理、再現レポート |

重要なのは、これらを一度に全部自動化しないことである。最初は「現在ラボの判断に最も時間がかかっている指標」を一つ選ぶ。

## 5. 貢献可能なプロジェクトの優先順位

| 優先 | プロジェクト | 研究価値 | Takumiとの適合 | 前提データ | 初期成果まで |
| ---: | --- | --- | --- | --- | --- |
| 1 | 曲面角膜の形状・print fidelity QC | 高い | 高い | CAD、写真、scan、OCT等のいずれか | 2〜4週 |
| 2 | 顕微鏡・免疫蛍光画像の定量化 | 高い | 中〜高 | 承認済み画像と手動評価例 | 3〜6週 |
| 3 | Experiment registry とデータ辞書 | 非常に高い基盤価値 | 高い | 実験項目・ファイル構造 | 1〜3週 |
| 4 | 解釈可能な実験条件最適化 | 高い | 中 | 十分に整った複数runデータ | 6〜12週以降 |
| 5 | 3D科学図・研究ダッシュボード | 中 | 非常に高い | 確定した結果・公開範囲 | 1〜4週 |
| 6 | AI支援文献・プロトコル整理 | 中 | 高い | 公開文献または承認済み文書 | 1〜3週 |

「見栄えのよいダッシュボード」は作りやすいが、測定定義が不安定な状態では研究価値が低い。順番は、**測定定義 → 品質管理 → 解析 → 可視化UI**とする。

## 6. プロジェクト案1 — 曲面角膜の形状・Print Fidelity QC

### 6.1 研究上の問い

> 設計した角膜形状に対し、印刷直後および培養後のconstructは、どこで、どの程度、どの方向にずれているか。

この問いは、単に「形が似ているか」ではなく、次の判断へつながる。

- 印刷条件の変更が曲率維持に効いたか
- 収縮・膨潤がどの領域で起きたか
- curved support と最終constructのずれはどの程度か
- 層を重ねたときに位置ずれや境界の破綻が起きたか
- 培養日数による形状変化があるか

### 6.2 利用可能なデータ別の実装レベル

| Level | 入力 | できること | 主な限界 |
| --- | --- | --- | --- |
| 1 | 校正用スケール付き正面・側面写真 | 直径、輪郭、投影面積、高さ、簡易曲率、収縮率 | 3D表面全体や光学特性は測れない |
| 2 | 複数角度写真、structured light、surface scan | 3D表面再構築、target meshとのregistration、偏差マップ | 透明・湿潤試料では取得条件の工夫が必要 |
| 3 | OCT、confocal z-stack、profilometry等 | 厚さ、前後面、層境界、局所曲率の空間解析 | 装置校正、専門家による解釈が必要 |

最初からLevel 3を前提にせず、ラボがすでに取得しているデータを使う。

### 6.3 候補となる定量指標

- 直径・投影面積の相対誤差
- 中央厚・周辺厚と厚さ分布
- targetに対するpoint-to-surface distance
- surface RMS error
- Hausdorff distance。ただし外れ値への感度を併記する
- 曲率半径または局所曲率の誤差マップ
- 体積変化と収縮・膨潤率
- layer centroid offset、界面ギャップ、層厚の不均一性
- 印刷直後から培養後までの形状保持率

どの指標を採用するかは、現在の実験判断と測定精度に合わせ、指導者と事前に決める。

### 6.4 処理の流れ

```text
raw image / scan / OCT
  → sample ID・倍率・時点・撮影条件の確認
  → pixel / voxel size の校正
  → constructまたは層境界の抽出
  → target CAD / baselineとのregistration
  → 指標計算
  → overlay・偏差マップ・QC警告
  → CSV + 図 + 方法・失敗条件の自動レポート
```

### 6.5 技術候補

- 2D: Python、OpenCV、scikit-image、NumPy
- 3D: Open3D、trimesh、PyVista
- 画像確認: napari
- exploratory analysis: Jupyter
- 再現実行: Python scriptまたは小さなCLI
- 説明用3D図: Blender

Blenderは科学的な説明図には適しているが、測定の中心には、座標、単位、変換履歴を保持しやすいライブラリを使う。

### 6.6 検証方法

- 既知寸法のreference objectでpixel・voxel校正を確認する
- 一部サンプルを研究者が手動測定し、自動値と比較する
- segmentation overlayを全件保存し、目視QCできるようにする
- 可能なら複数評価者との一致を確認する
- 同じ入力を再処理して同じ出力が出ることをテストする
- 撮影条件、反射、気泡、欠損などのfailure modeを分類する

誤差は一つの相関係数だけで評価しない。連続値なら MAE、bias、Bland–Altman、ICCなどから目的に合うものを選び、画像分類・segmentationなら precision、recall、Dice、IoUなどを選ぶ。

## 7. プロジェクト案2 — 顕微鏡・免疫蛍光画像の定量化

### 7.1 最初に選べる3つの小課題

#### A. Live/dead viability の半自動計測

- live、dead、重なり、backgroundを分離する
- 面積比だけでなく、可能ならcell countとfield-level uncertaintyを出す
- thresholdや露光条件を固定・記録する
- 気泡、autofluorescence、重複細胞を失敗条件として記録する

#### B. Endothelial layer continuity の評価

- endothelial coverage
- gap areaとgap数
- cell density
- cell area distribution
- circularity、hexagonalityなどの形態指標
- 画像全体での空間的不均一性

角膜内皮では、画像内の細胞数をそのまま独立サンプル数にしてはいけない。construct、donor/batch、field、cellという階層を保存する。

#### C. Collagen／細胞配向の評価

- structure tensorまたはFFTによる方向分布
- alignment index
- 層別・領域別のorientation map
- printing directionとの角度差

この課題は、角膜実質の異方性・コラーゲン配向という研究課題に近い。ただし、どの染色・撮像法が配向を意味ある形で捉えるかは研究者の判断が必要である。

### 7.2 画像解析で守るべき原則

1. raw imageを上書きしない
2. channel、bit depth、pixel size、objective、exposureを保存する
3. cropやcontrast変更を処理履歴に残す
4. 学習用・評価用の画像を、同じconstructの別cropだけで分けない
5. test splitは可能ならbatchまたはprint run単位にする
6. 自動値だけでなくoverlayとconfidenceを返す
7. 人が修正した場合、その差分を残す
8. 「うまくいった代表画像」だけで精度を判断しない

### 7.3 最初はdeep learningを使わない可能性が高い

データが少ない場合、thresholding、morphology、watershed、classical feature extractionの方が、速く、説明可能で、修正しやすい。深層学習は、次の条件が揃った後に検討する。

- 研究者が確認したannotationが十分にある
- batch・装置・日付をまたいだ評価セットがある
- 既存手法より改善する必要性が明確である
- 誤検出が研究結論へ与える影響を評価できる

## 8. プロジェクト案3 — Experiment Registry とデータ辞書

### 8.1 なぜ地味でも価値が高いのか

機械学習やシミュレーションが失敗する原因は、アルゴリズムよりも、sample ID、単位、反復、欠損、条件名、ファイル対応が不明確なことにある場合が多い。

バイオプリンティングでは、少なくとも次の階層を区別する必要がある。

```text
study
└── experiment
    └── print run
        ├── bioink batch
        └── construct
            ├── timepoint
            ├── assay
            └── image / field
                └── cell-level measurements
```

この階層を保持しないと、1枚のconstructから1000細胞を測り、`n = 1000`として扱うpseudo-replicationが起こり得る。

### 8.2 最小データモデル

| テーブル | 主な項目 |
| --- | --- |
| `print_runs` | run ID、date、operator、printer、nozzle、speed、pressure、temperature、environment |
| `bioink_batches` | material、concentration、batch ID、rheology参照、cell type、cell density、preparation time |
| `constructs` | construct ID、run ID、target design、support、position、post-processing、culture condition |
| `assays` | assay ID、construct ID、timepoint、assay type、protocol version、instrument |
| `images` | image ID、assay ID、raw path、channel、pixel size、exposure、field location |
| `measurements` | measurement ID、source ID、metric、value、unit、method version、QC status |
| `exclusions` | source ID、reason、decided by、date、before/after analysis |

実際の項目はラボのSOPに合わせる。入力項目を増やしすぎず、次の研究判断に必要な最小集合から始める。

### 8.3 出力

- `data_dictionary.md`
- sample ID とファイル命名ルール
- unit validation
- missingness report
- raw → processed → figure のprovenance map
- 解析時に使用したデータ版のsnapshot
- 研究者向けの1ページQC summary

## 9. プロジェクト案4 — 解釈可能な実験条件最適化

### 9.1 進める順番

データ基盤が整った後は、次の順番で解析する。

1. 可視化とデータ品質確認
2. 単純なbaselineモデル
3. batch・runを考慮した統計モデル
4. response surfaceまたはDesign of Experiments
5. 十分なデータがある場合のみ、Random ForestやXGBoost
6. 物理制約を入れる価値が明確な場合に、physics-informed approach

最初からPINNや複雑なマルチエージェント最適化へ進む必要はない。

### 9.2 入力候補

- nozzle diameter
- extrusion pressure
- print speed
- layer height
- path spacing
- bioink concentration
- temperature
- crosslinking condition
- cell density
- culture time
- bioink batch、operator、printer

### 9.3 出力候補

- shape fidelity
- curvature retention
- thickness uniformity
- transparency／haze
- mechanical property
- cell viability
- endothelial continuity
- failure probability

### 9.4 多目的最適化として扱う

角膜バイオプリンティングには、単一の「最良条件」がない可能性が高い。

```text
形状精度 ↑
細胞生存率 ↑
透明性 ↑
機械的強度 ↑
印刷時間 ↓
```

これらは互いに競合し得るため、最終的には加重平均の1スコアだけでなく、Pareto frontやtrade-off plotで示す方が研究者の判断に役立つ。

### 9.5 Physics-informed の現実的な始め方

少量データに対して、いきなり高度なphysics-informed neural networkを作るのではなく、まず物理的に意味のある特徴量や制約を使う。

- pressure、nozzle径、速度、rheologyからshear stressのproxyを作る
- diffusion distanceとculture timeを別々の無関係変数として扱わない
- 対称性や非負制約を入れる
- 形状誤差と材料収縮を分けて考える
- 既知の単位・次元が一致しているか検査する
- 外挿領域では予測値だけでなくuncertaintyを出す

モデルの目的は「高いR²」ではなく、**次の実験条件を安全かつ情報量の多い形で選ぶこと**である。

## 10. プロジェクト案5 — 3D科学図、ダッシュボード、研究コミュニケーション

### 10.1 Takumi のVisual Artsを活かせる成果物

- stromal layerとendothelial layerの位置関係を示す3D cutaway
- target CADとprinted constructの偏差を示すcolor map
- print path、材料、細胞、培養、評価のworkflow figure
- condition → outcomeを示すsmall multiples
- timepointごとの曲率・厚さ・cell coverageの比較
- ポスター用graphical abstract
- 臨床研究者向けと工学研究者向けで情報密度を変えた説明図

### 10.2 可視化の役割を分ける

| 種類 | 目的 | 注意 |
| --- | --- | --- |
| Measurement figure | データを正確に示す | 軸、単位、n、uncertainty、除外条件が必要 |
| Explanatory schematic | 構造・機序・工程を説明する | 実測図と誤認されない表示が必要 |
| Interactive dashboard | 条件やsampleを探索する | 正式な統計結論の代わりにしない |
| Presentation render | 非専門家へ直感的に伝える | 色・形を科学的事実以上に見せない |

Takumi の強みは、これらを一つの「きれいな図」に混ぜず、用途ごとに作り分けられる点にある。

## 11. プロジェクト案6 — AI支援の文献・研究ワークフロー

### 11.1 AIを使ってよい作業の候補

- 公開論文から比較項目の候補を抽出する
- 用語集、データ辞書、READMEの下書きを作る
- コードのテストケースとdocstringを作る
- 解析コードを別モデルでレビューする
- 図のキャプション案を作る
- 文献間で定義が異なる項目を人間が確認するために並べる
- 会議メモから決定・未決事項・担当を抽出する

### 11.2 AIに任せてはいけない判断

- microscopy imageの生物学的意味を、専門家の確認なしに確定する
- 除外サンプルを自動決定する
- 統計的有意性と生物学的重要性を同一視する
- 出典を確認せず文献値をデータベースへ入れる
- 未公開結果から臨床的有効性を主張する
- 著者資格、倫理、患者データ利用をAI判断で決める

### 11.3 マルチエージェントの使い方

マルチエージェントは研究者の代わりではなく、役割分離に使う。

- Agent A: data schema・unit・missingnessの検査
- Agent B: code test・再現手順の検査
- Agent C: figure label・caption・sourceの検査
- Human researcher: 科学的妥当性と最終判断

複数AIが同じ答えを出しても、それは実験的な検証にはならない。

## 12. 推奨する最初の4週間 — Curved Corneal Construct QC Pilot

### 12.1 一文のproject charter

> 承認済みの既存データを用いて、一種類の角膜constructについて、一つの主要形状指標または層構造指標を再現可能に測定し、手動評価との一致・失敗条件・再実行手順を4週間で示す。

### 12.2 明確に範囲外とするもの

- 新規の臨床結論
- 新しいAIモデルの性能競争
- 全assayの統合
- wet-lab protocolの変更
- 患者データの利用
- 公開Webアプリへの未公開データ掲載
- 論文投稿を4週間の成功条件にすること

### 12.3 Week 1 — 問い・データ・評価方法を固定する

- 現在もっとも時間のかかる手動評価を一つ確認する
- 利用可能な画像、CAD、scan、OCT、測定表を確認する
- experimental unitとデータ階層を確認する
- primary metricを一つ、secondary metricを最大一つ選ぶ
- 手動referenceの作り方を決める
- データ保管場所、アクセス権、公開可否を記録する
- `project-charter.md` と `data_dictionary.md` をレビューしてもらう

### 12.4 Week 2 — 最小baselineを作る

- 少数の承認済みsampleでraw data loaderを作る
- 校正、segmentationまたはregistrationのbaselineを実装する
- 各sampleのoverlayを出す
- CSVにmetric、unit、method version、QC flagを保存する
- 失敗例を先に確認し、分類する

### 12.5 Week 3 — 手動評価と比較し、修正する

- 指導者が確認したreference subsetと比較する
- 誤差、bias、再現性を評価する
- うまくいかない画像条件を明示する
- parameterを後付けで個別調整しすぎない
- コードをnotebookだけに閉じず、再実行できるscriptへ分離する

### 12.6 Week 4 — 研究判断に使える形で渡す

- raw dataから図とCSVを再生成する
- 1ページのmethod・result・limitationを作る
- 研究者向けQC figureを1枚作る
- 5分デモを行う
- 「使える／条件付きで使える／まだ使えない」を判断してもらう
- 次の拡張を最大2案だけ提案する

### 12.7 成功基準

数値閾値はラボと合意するが、最低限次を満たす。

- raw inputとoutputがsample IDで追跡できる
- 単位、校正、method versionが記録される
- 他の人が文書どおりに再実行できる
- 自動値と手動referenceの差が示される
- 全sampleにoverlayまたはQC flagがある
- 失敗条件と適用範囲が明記される
- 「この図から言えること／言えないこと」が分かれている

## 13. データ状況による初期プロジェクトの分岐

| ラボにあるもの | 選ぶパイロット |
| --- | --- |
| target CAD + surface/OCT/scan | 3D形状registrationと偏差マップ |
| 校正済みの正面・側面写真 | 2D輪郭、高さ、簡易曲率、収縮率QC |
| 顕微鏡・免疫蛍光画像 + 手動評価 | viability、coverage、layer continuityの半自動解析 |
| instrument outputのExcel/CSV | データ辞書、QC、条件比較、再現レポート |
| 実験メタデータのみ | experiment registryと欠損・単位監査 |
| 公開文献しか使えない | evidence matrixと測定項目taxonomy |

これにより、データが足りないことを理由に大きなアプリを先に作る必要がなくなる。

## 14. 90日で到達すべき状態

既存の[学習・研究参加ロードマップ](learning-roadmap.md)は分野学習とオンボーディングを扱う。本節は、研究成果物側の90日計画である。

| 期間 | 研究上の焦点 | 成果物 | 次へ進む条件 |
| --- | --- | --- | --- |
| Days 1–14 | governance、問い、データ監査 | charter、data dictionary、sample hierarchy | 指導者が範囲と利用データを承認 |
| Days 15–30 | baseline測定 | script、overlay、metric CSV、QC report | 手動referenceとの差とfailure modeを説明可能 |
| Days 31–60 | validationと小規模適用 | method固定、batchをまたぐ確認、研究図1枚 | 解析が特定sampleだけに過適合していない |
| Days 61–90 | 実験判断への接続 | 条件比較、短い報告、次の実験候補 | ラボが次の意思決定に利用できる |

90日後の理想は「高度なAIを作った」ではない。

> **一つの研究評価を、誰が見ても追跡でき、再実行でき、限界を説明できる形にした。**

これができれば、その後に画像解析の拡張、統計モデル、DoE、物理モデル連携へ進める。

## 15. 推奨するリポジトリ構造

実際の保存場所とアクセス制御はラボの方針を優先する。概念上は次のように分ける。

```text
project/
├── README.md
├── project-charter.md
├── data_dictionary.md
├── environment.yml / requirements.txt
├── config/
│   └── analysis.yaml
├── src/
│   ├── io.py
│   ├── calibration.py
│   ├── segmentation.py
│   ├── metrics.py
│   └── reporting.py
├── tests/
├── notebooks/
│   └── exploration.ipynb
├── reports/
│   ├── figures/
│   └── qc/
└── data/
    ├── README.md
    ├── raw/       # read-only。ラボ承認環境のみ
    ├── interim/
    └── processed/
```

未公開データをGitへ入れるという意味ではない。コード、設定、データ参照、実データを分離し、ラボ指定の安全な保存場所を使う。

## 16. 統計・再現性で特に注意する点

### 16.1 experimental unitを最初に決める

「画像の枚数」「細胞の数」「constructの数」「print runの数」は同じではない。

例えば、一つのconstructから10視野を撮り、各視野に100細胞ある場合、独立した生物学的反復が1000あるとは限らない。解析表には、少なくともrun、construct、timepoint、field、cellのIDを保持する。

### 16.2 train/testを画像単位でランダム分割しない

同じconstructの近接fieldがtrainとtestに入ると、実際より高い性能が出る。可能ならholdoutをconstruct、batch、print run、撮影日などの上位単位で行う。

### 16.3 batch effectを「ノイズ」として消す前に理解する

bioink batch、operator、printer、温度、撮影設定は、単なる邪魔な変数ではなく、再現性の重要な情報である。まず可視化し、必要ならmixed-effects modelなどを指導のもとで検討する。

### 16.4 探索と確認を区別する

- exploratory analysis: 仮説を見つける
- confirmatory analysis: 事前に決めた仮説を検証する

同じデータで多数の指標を試し、最もよいものだけを「検証結果」としない。

### 16.5 uncertaintyを出す

平均だけでなく、sample数、ばらつき、confidence intervalまたは目的に合うuncertaintyを示す。小規模研究では、p値だけよりeffect sizeと個々のデータ点が重要になることが多い。

## 17. データ、倫理、AI、知的財産のガードレール

### Data

- patient、donor、cell line、未公開sampleの識別情報は、ラボの分類と保管ルールに従う
- raw dataを変更せず、派生データを別に保存する
- 外部ストレージ、個人GitHub、個人クラウドへ置かない
- ファイルの共有範囲を、内部、共同研究者、公開の3段階で確認する

### AI

- 公開論文と未公開実験データを同じ扱いにしない
- 未公開データを外部AIへ送る前に、大学・ラボの許可を確認する
- local modelも、自動的に安全とはみなさず、保存場所とログを確認する
- AIを使った箇所、モデル、日付、人間の確認者を必要に応じて記録する
- AI出力をraw evidenceとして保存しない

### Research integrity

- exclusion criteriaを結果を見た後に恣意的に変えない
- 代表画像だけで結論を作らない
- image enhancementは全群へ同じルールを適用する
- 図の加工履歴を保存する
- negative resultとfailure modeも記録する

### Authorship and IP

- 担当、期待成果、コード所有、公開可否をproject charterで確認する
- ポスター、論文、学位科目、個人ポートフォリオへの利用は別々に承認を得る
- 著者資格はツールを作ったことだけで自動的に得られるものではなく、研究への実質的貢献とラボ方針に従う

## 18. Takumi が学ぶべき順番

| 優先 | 学ぶ内容 | 理由 | 最初の到達基準 |
| ---: | --- | --- | --- |
| 1 | 角膜の層、透明性、内皮、実質の基礎 | 指標の生物学的意味を理解するため | 研究の問いを5分で説明できる |
| 2 | ラボのsample hierarchyとSOP | 誤ったnやデータ結合を避けるため | 1 sampleの履歴を図にできる |
| 3 | 画像校正・segmentation・registration | 最初のパイロットに直結 | 手動値との差を説明できる |
| 4 | 統計設計、DoE、mixed effects | 小規模・階層データへ対応するため | experimental unitとmodel choiceを説明できる |
| 5 | rheology、mass transport、mechanicsの基礎 | Yuan氏の物理モデルと接続するため | 各入力が結果へ影響する仮説を説明できる |
| 6 | advanced ML / physics-informed ML | 基盤ができた後の拡張 | baselineより必要な理由を示せる |

wet-lab trackへ進む場合は、安全、無菌操作、細胞培養、材料調製、プリンター操作を、必ずラボの正式トレーニング順で学ぶ。

## 19. 研究室にとっての価値を測るKPI

Takumi の成果を「コードを書いた量」ではなく、次で評価する。

| 観点 | KPI候補 |
| --- | --- |
| Reproducibility | 別の人が同じ入力から同じ図を再生成できるか |
| Traceability | 図の各点を元sample、run、method versionまで追えるか |
| Accuracy | 手動referenceまたは装置referenceとの差が許容範囲か |
| Robustness | batch・日付・撮影条件が変わった場合の性能を把握しているか |
| Efficiency | 手動作業時間、転記ミス、再解析時間を減らしたか |
| Decision value | 次の実験条件や追加測定の判断に使われたか |
| Communication | 研究者が結果と限界を短時間で理解できるか |
| Adoption | 指導者またはラボメンバーが実際に再利用したか |

## 20. 中長期に発展できる研究テーマ

最初の測定基盤が機能した後に、次を検討できる。

### 20.1 Multi-objective bioink／printing optimisation

材料濃度、pressure、speed、crosslinkingと、shape fidelity、cell viability、transparency、mechanicsを結び、trade-offを可視化する。

### 20.2 Active learningによる次実験の提案

予測値が最も高い条件だけでなく、モデルの不確実性を最も減らす条件を提案する。ただし、人間が安全性・実現可能性を確認する。

### 20.3 Geometry–biology統合解析

局所曲率、厚さ、layer interfaceと、細胞密度、形態、marker expressionの空間関係を調べる。

### 20.4 Culture timeを含む4D変化

同じconstructを複数timepointで追跡し、曲率、透明性、細胞層の変化を可視化する。破壊測定と非破壊測定を区別する。

### 20.5 Corneal endothelial characterization matrix

iPSC由来角膜内皮細胞のレビューで示される、分化方法・marker・形態・機能評価のばらつきを、比較可能なtaxonomyとして整理する。これは将来のprotocol comparisonやevidence mapにつながる。

### 20.6 Research digital twin

target geometry、printing parameters、material properties、measured outcomesをつなぐデジタル表現を作る。ただし、見た目の3Dモデルではなく、各値の出典・単位・uncertaintyを持つことを条件とする。

## 21. 面談で提案する英語スクリプト

> I think my strongest contribution would be at the interface between experiments and computational modelling. I would like to help turn corneal bioprinting images or geometry data into reproducible quantitative measurements, rather than starting with a large AI model. For example, I could begin with one small quality-control pilot that compares a printed construct with its target geometry, or quantifies one microscopy outcome such as endothelial coverage. The output would include the data definition, validated measurements, overlays, code, and limitations. Which current manual measurement or data bottleneck would be most useful for the group to improve first?

短く言う場合:

> I would like to build a small, reproducible QC pipeline that turns each corneal bioprint into traceable geometry or microscopy metrics, so the group can compare conditions and decide what to test next.

## 22. 面談で必ず確認する質問

### 研究判断

1. 現在、どの評価が最も手作業で、時間がかかり、評価者差が出やすいですか？
2. 次の1〜3か月で、ラボが決めたい実験上の判断は何ですか？
3. geometry、optical、mechanical、biologicalのうち、現在の最優先はどれですか？

### データ

4. target CAD、写真、OCT、confocal、z-stack、surface scan、instrument CSVのどれがありますか？
5. sample、construct、print run、bioink batch、fieldの関係はどのように管理されていますか？
6. 手動測定や専門家annotationなど、比較対象になるreferenceはありますか？
7. 過去データは撮影条件・倍率・pixel sizeが揃っていますか？

### 実務・ガバナンス

8. どのデータを使用でき、どこへ保存し、どのツールへ入力できますか？
9. 最初の4週間で、誰が方法と結果をレビューしますか？
10. MEDS3888、research internship、別プロジェクトのどの枠に位置づきますか？
11. コード、図、ポスター、外部発表、ポートフォリオの公開ルールは何ですか？
12. wet-labを行う場合、必要な安全・機器・細胞培養トレーニングは何ですか？

## 23. 面談後7日以内の具体的アクション

1. 面談内容を、decision、open question、owner、deadlineに分けて記録する
2. 指導者と、最初の問いを一文で合意する
3. 利用可能なsampleを少数だけ受け取り、データ構造と品質を監査する
4. experimental unitとprimary metricを決める
5. `project-charter.md` と `data_dictionary.md` を作る
6. 手作業のbaselineを再現してから、自動化へ進む
7. 1週間後に、完成アプリではなくoverlayとmeasurement tableを見せる

## 24. 最終評価

Takumi の希少性は、現時点で角膜、wet lab、数理モデルのどれか一つを深く極めていることではない。

希少性は、次を一つの研究工程に接続できる可能性にある。

> **Medical Scienceで問いを理解する**  
> ＋ **Python・データ設計で測定を再現可能にする**  
> ＋ **3D・Visual Artsで空間構造を伝える**  
> ＋ **Product Engineeringで他者が使える形にする**  
> ＋ **AIを補助として使い、検証を人間へ戻す**

Yuan 氏の研究が「バイオプリンティングを予測・制御可能な工学システムにする」方向であるなら、Takumi は「そのシステムが学習・検証できる、信頼できる測定とデータの基盤を作る」役割を担える。

最初に狙うべき成果は、大規模なAI、豪華なダッシュボード、独立したwet-lab成果ではない。

> **一つのconstruct、一つの評価指標、一つの再現可能なpipelineを、研究者が信頼して再利用できる状態にすること。**

これが成功すれば、形状解析から顕微鏡画像解析、実験条件最適化、physics-informed modelling、論文・ポスターへ自然に拡張できる。

## 参考資料

### ローカル資料

- [BiG Lab 研究面談：予習・準備メモ](meeting-preparation.md)
- [BiG Lab 学習・研究参加ロードマップ](learning-roadmap.md)
- [Takumi Suehara résumé](../../takumi-suehara/career/resume-cv/resume/Approved/takumi-suehara-resume.html)
- [USYD Master Plan](../../takumi-suehara/university/notes/usyd-master-plan.md)
- [Portfolio README](../../takumi-suehara/portofolio-website/README.md)

### 公開一次情報

- Yuan Y, et al. [3D Printing Strategies for Bioengineering Human Cornea](https://pmc.ncbi.nlm.nih.gov/articles/PMC12988584/). *Advanced Healthcare Materials*. Published online 2 October 2025.
- Huang H, Yuan Y, et al. [A New Bioprinted Dual-Layered Corneal Structure Using Collagen-Based Bioinks](https://journals.sagepub.com/doi/10.1177/19373341261424272). *Tissue Engineering Part A*. Published online 25 February 2026.
- Yuan Y, et al. [Principle-based multiphysics simulation for 3D bioprinting systems: modelling inkjet, extrusion, and DLP processes](https://pubmed.ncbi.nlm.nih.gov/42102834/). *Biofabrication*. 2026.
- Fang Y, Yuan Y, et al. [Advances in Differentiation of Induced Pluripotent Stem Cell–Derived Corneal Endothelial Cells](https://www.sciencedirect.com/science/article/pii/S0002944026001252). *The American Journal of Pathology*. Available online 4 May 2026.
- [BIENCO Vision — Product Pipeline](https://biencovision.com.au/). Accessed 16 July 2026.

### 出典の扱い

本書の研究内容の要約は、上記公開情報と提供された調査文を基にしている。Takumi の能力に関する記述はローカル資料上の自己申告・制作実績を基にしており、研究室での正式な技能認定を意味しない。実際のプロジェクト範囲、測定法、統計設計、データ利用、公開可否は、Yunong Yuan 氏、Jingjing You 先生、BiG Lab の承認を優先する。
