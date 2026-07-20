[HTML版を開く](competitive-landscape.html)

# 競合・関連研究マップ — Microneedle Drug Permeation ML

作成日: 2026-07-20
根拠: deep-research harness による多角的調査(6検索角度、26件一次資料取得、113件の主張抽出、25件を3票制adversarial verificationで検証 — 15件確認・10件棄却)
比較対象: `microneedle-drug-delivery/research/` で進めているアプローチ(Yuan et al. 2023の191点・6薬剤データセット再現、HuskinDB+SkinPiX+INRS統合214化合物データセットとのtransfer learning計画、Fick則物理モデル併用データ拡張計画、leave-one-drug-out交差検証、美容成分48件への応用)

## 1. 競合構図の全体像

皮膚/経皮透過性予測の競合は大きく2陣営に分かれる。

- **商用PBPK/メカニスティック系ツール**(Certara Simcyp MPML MechDermA、Simulations Plus GastroPlus TCAT、VeriSIM Life BIOiSIM)— 純粋なMLベンチマーク競争ではなく、メカニスティックな多層コンパートメントモデルの精度で競っている。
- **学術QSAR/ML系研究**(Abdallah et al. 2024が最も近い)— 本プロジェクトと似た規模のデータで似た手法(boosted trees)を使い、同種の外挿弱点を抱えている。

**最重要の発見**: 本プロジェクトが使用計画中の統合皮膚透過性データセット(HuskinDB+SkinPiX+INRS)と実質的に同一の組成のデータセットに対し、CNRS-Strasbourg/INRSのグループがすでにQSPRモデルを発表している(§4)。本文入手不可のため詳細は不明だが、優先度の高いフォローアップ事項である。

## 2. 商用PBPK/メカニスティックツール(確認済み・直接競合ではない)

| ツール | 提供元 | 手法 | 本プロジェクトとの違い |
| --- | --- | --- | --- |
| MPML MechDermA | Certara (Simcyp) | 多相・多層メカニスティック皮膚吸収モデル(doi:10.1002/psp4.12814) | 純粋にメカニスティック。ML言語なし |
| GastroPlus TCAT | Simulations Plus | コンパートメントモデル(角質層・表皮・真皮・皮脂腺・毛包脂質・毛包芯) | 同上 |
| BIOiSIM | VeriSIM Life | 16コンパートメントのメカニスティックODEモデル + MLはパラメータフィッティングのみ | ハイブリッドだがMLは補助的 |

**結論**: これらは「メカニスティック忠実度」で競争しており、本プロジェクトの「Fick則+MLR/RF/XGBoost」という純データ駆動アプローチとは競争軸が異なる。直接のベンチマーク比較対象ではないが、Discussion/Related Workで「メカニスティック系との違い」として言及する価値はある。

*(棄却済み: Simulations PlusがTCAT向けにFDAから研究助成金を得たという主張は3票中0票で不成立。引用しないこと。)*

## 3. 最も近い学術的ML類似研究: Abdallah et al. (2024)

Abdallah, Hasan & Hammad. "Predictive modeling of skin permeability for molecules: Investigating FDA-approved drug permeability with various AI algorithms." *PLOS Digital Health*, 2024. doi:10.1371/journal.pdig.0000483

- 441レコード・140化合物(本プロジェクトの214化合物と近い規模)、85/15分割。
- LightGBM(R²=0.819)とGradient Boosting(R²=0.818)が上位。MLR(0.338)・ANN(0.797)を上回る。
- 記述子のみでDrugBank全2326化合物へ適用(約16.6倍の外挿)。
- **マイクロニードルへの言及なし**。バリデーションはランダム85/15分割のみで、leave-one-drug-out等のapplicability domain評価は行っていない。

**本プロジェクトとの比較で言えること**:
- 本プロジェクトが計画しているleave-one-drug-out交差検証は、Abdallah et al.のランダム分割よりも一般化性能の評価として厳格である。これは正当にアピールできる方法論的な強み。
- 逆に言えば、Abdallah et al.は既に「記述子ベースで大規模外挿(16倍)を試みる」実践例であり、本プロジェクトが美容成分48件への外挿(訓練データの214件に対し48件、倍率は小さい)を計画する上での前例・比較対象になる。

*(棄却済み: 「LightGBMが単独の最良モデルとして報告された」という比較の強さ自体は3票中0票で不成立 — 実際はGradient Boostingとほぼ同率。「マイクロニードルに全く言及がなく、ランダム分割のみで方法論的に劣る」という統合主張も2票中1票の僅差で不成立と判定されている。個別の事実 [441件/140化合物、85/15分割、LGBM R²=0.819、DrugBank 2326化合物への適用] は3票中0票で確認済みなので、これらは使ってよい。)*

## 4. 直接の先行研究の疑い: Asgarkhanova et al. (2026) — 最優先フォローアップ

**CNRS-Strasbourg(Laboratory of Chemoinformatics UMR7140, Alexandre Varnek研究室)+ INRS** による論文:

> Asgarkhanova et al., *Molecular Informatics* (Wiley), doi:10.1002/minf.70030, オンライン公開2026年4月22日(受理2026年3月25日、投稿2026年1月17日)

本文は購読制(HTTP 403、Unpaywallでも closed access を確認済み)のため、実際の手法・R²/RMSE等の性能指標は**不明**。しかし、公開されている再現用データセット(Recherche Data Gouv, doi:10.57745/ZUU1DH — **本プロジェクトのCLAUDE.mdが「統合QSPRデータセット」の出典として既に引用しているのと同じDOI**)を確認したところ、内訳は次の通り:

- `huskin_depot.tab`: 129件
- `skinpix_depot.tab`: 103件
- `inrs_depot.tab`: 3件
- Crossrefの抄録記載: 209件のキュレーション済み化合物(3件の新規実測データと突き合わせ)

本プロジェクトの214化合物データセットの内訳(HuskinDB 129 + SkinPiX 103 + INRS 3)と**完全に一致**する。

**重要な位置づけの確認**: 本プロジェクトの `research/CLAUDE.md`「データ出典」節は、この Asgarkhanova et al. のデータリポジトリ(doi:10.57745/ZUU1DH)を最初から「統合QSPRデータセットの出典」として引用している。つまり本プロジェクトの214化合物データセットは、HuskinDB・SkinPiXから独立にゼロから統合したものではなく、**Asgarkhanova et al.がすでに統合・公開したデータセットを直接re-useしている**可能性が高い。これは隠されたことではなく元々出典明記されているが、**「本プロジェクトが214化合物を統合した」という表現は、実際には「Asgarkhanova et al.が統合したデータセットを再利用した」という表現に修正すべき**である。

**未解決点**:
- Asgarkhanova et al.が実際にどのようなQSPRモデル(手法・性能指標)を報告しているかは不明(本文入手が最優先)。
- 209件(Asgarkhanova) vs 214件(本プロジェクト)の差分5件の原因は未確認。

**推奨アクション**:
1. 図書館アクセス等でAsgarkhanova et al.の本文を入手し、実際の手法・性能を確認する。
2. 入手できるまでは、本プロジェクトの成果物(論文含む)で「214化合物データセットを本プロジェクトが構築した」という表現を避け、「Asgarkhanova et al. (2026) が構築・公開した統合データセットを本プロジェクトで再利用している」という表現に統一する。
3. 本プロジェクトの新規性は「統合データセットの構築」ではなく、**「その統合データセットをマイクロニードル文脈への転移学習のソースドメインとして使う」という橋渡し**にあることを明確にする(Asgarkhanova et al.はマイクロニードルへの言及があるかどうか自体が未確認)。

## 5. 補完的データ資源: Stevens et al. (2024, EPA)

Stevens, Prockter, Fisher, Tran & Evans. *Scientific Data* 11:755 (2024), doi:10.1038/s41597-024-03588-3

- 73化合物について、角質層・表皮・真皮の**層別**diffusion係数・partition係数(+約47記述子)を提供。
- HuskinDBは透過係数(Kp)のみで、層別のdiffusion/partition係数は含まない — 本プロジェクトが計画しているFick則ベースの物理モデル併用データ拡張に**直接使える**補完データ。
- EPA所属著者を含み、目的は毒性評価・httkツールキット連携であり、マイクロニードルへの言及はない(競合ではなく取り込むべきリソース)。

**推奨アクション**: RESEARCH_PLAN.mdフェーズ4Bの「物理モデル併用データ拡張」にこのデータセットを追加候補として明記する。

## 6. 転移学習の手法的フロンティア(参考、皮膚特化ではない)

- MAMLスタイルのメタ学習によるGNN初期化が、マルチタスク事前学習より16/20のin-distributionタスクと**全て**のout-of-distributionタスクで上回った(平均AUPRC改善: in-distribution 11.2%、out-of-distribution 26.9%)(arXiv 2003.05996)。out-of-distribution(=本プロジェクトのleave-one-drug-out的弱点)で優位性が大きい点が示唆的。
- Merck/NVIDIAのKERMT基盤モデル研究(arXiv 2510.12719)は、マルチタスクファインチューニングの恩恵は6万データ点超の大規模データで最大化されると報告 — 本プロジェクトの小規模データ(191点・214化合物)には直接当てはまらない可能性を示唆。

**確信度**: 中(皮膚透過性に特化した研究ではなく、一般的な分子ML研究からの推論)。本プロジェクトが「単純なpretrain→fine-tune」型のtransfer learningを計画している箇所(RESEARCH_PLAN.mdフェーズ4B)に対し、「より洗練されたメタ学習アプローチも検討候補として言及する」程度の弱い推奨に留める。

## 7. 見送ってよい/競合ではないと確認できたもの

- **ACD/Labs Percepta ADME Suite**: BBB・CYP450・経口バイオアベイラビリティ等は扱うが、皮膚/経皮透過性のエンドポイントが**存在しない**。競合ではない。
- **OECD QSAR Toolbox の Skin Permeability Profiler**: 188化合物のルールベース分類木で、High/Moderate/Lowの3分類のみ。ツール自体が「予測用途には非推奨」と明記。定量的なMLツールではない。

## 8. 未解決の問い(捏造せず、明示的にオープンとして扱うこと)

1. **美容成分への応用の独自性は未確認。** 今回の調査ではこの問い(ユーザーの元の質問4)に答える十分な証拠が得られなかった。次回調査での最優先事項とすべき。
2. Asgarkhanova et al.の実際の手法・性能指標は不明(本文入手が必要)。
3. HuskinDBの現行フル公開データが129化合物より多い可能性(2020年時点の論文記載では251化合物・546測定値)との整合性は未確認 — 「129件は最新かつ十分な部分集合である」という前提を検証する価値がある(ただし「使われていないデータが大量にある」という主張自体は検証で不成立と判定されているため、断定はしない)。
4. 高分子量・biologics領域(microneedleが受動透過に対して優位性を発揮しやすい化学空間)を競合ツールがカバーしているかどうかは未確認。

## 9. 未検証だが具体的なリード(ファブリケーションではなく、要フォローアップとして記録)

- **小林製薬**(日本企業)がラマン分光×機械学習(MCR-ALSアルゴリズム)により、3次元培養皮膚モデル内部への美容成分(トラネキサム酸=美白成分。本プロジェクトの48件リストと重なるカテゴリ)の浸透を可視化する技術を開発している(https://skincare.kobayashi.co.jp/field/skincare/penetration02.html)。手法は構造記述子からの透過係数予測ではなく実測スペクトル分析であり、本プロジェクトの記述子ベースQSARアプローチとは異なる。**この情報はadversarial verificationの対象外(検索結果段階の情報)であり、確認済みの事実としては扱わないこと。** ただし「ML×皮膚透過×美容成分」という同じ問題設定に日本企業が取り組んでいる具体例として、直接確認する価値がある。

## 10. 推奨アクション(優先順位順)

1. **[最優先]** Asgarkhanova et al. (2026) の本文入手を試み、本プロジェクトの214化合物データセットとの関係(再利用か独自統合か)を明確化する。入手できるまでは、本プロジェクトの成果物で「データセットを構築した」ではなく「Asgarkhanova et al.が構築したデータセットを再利用している」という表現に統一する。
2. 美容成分への応用の独自性について、追加の的を絞った調査(日本語圏含む)を行う。
3. Stevens et al. (2024) の層別diffusion/partitionデータをRESEARCH_PLAN.mdフェーズ4Bの物理モデル併用データ拡張の候補データ源として追加する。
4. Abdallah et al. (2024) との方法論比較(leave-one-drug-out vs ランダム分割)を、本プロジェクトの方法論的な強みとして明記する。
5. MAMLスタイルのメタ学習を、単純なpretrain→fine-tuneの代替候補として弱く言及する(確信度: 中、皮膚特化の実証なし)。
6. 小林製薬のリードを直接確認し、確認できれば美容成分への応用の独自性の議論に反映する。

## 11. `microneedle-small-data-ml-paper` への影響(要ユーザー判断)

このタスク(競合分析)は別ブランチ・別PRとして独立に扱っているため、既存のPR #1(`microneedle-small-data-ml-paper`)の内容には直接手を加えていない。ただし、§4の発見は同PRの論文原稿(`paper.md` §5.2, Reference #11)の「we assembled a training resource of 214 unique compounds」という表現に関わる — 実際にはAsgarkhanova et al. (2026)がほぼ同一の統合データセットをすでに公開している可能性が高い。ユーザーには別途、PR #1への追加コミット(表現の修正、Related Workへの言及追加)を推奨する。
