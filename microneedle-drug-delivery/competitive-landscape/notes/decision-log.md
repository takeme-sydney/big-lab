[HTML版を開く](decision-log.html)

# 判断記録 — competitive-landscape

## 2026-07-20: deep-research調査の実行とスコープ

**決定**: 「競合サービス」の比較対象を「microneedle ML予測アプローチそのもの」とした
(ユーザー指定)。big-lab全体のWebサイト/ポータルツールとの比較ではない。

**実施**: deep-researchハーネスを実行(6検索角度、26件一次資料取得、113件の主張抽出、
25件を3票制adversarial verificationで検証 — 15件確認・10件棄却)。所要: 約70分、
109エージェント呼び出し、約437万トークン。

## 2026-07-20: 最重要発見とその扱い

**発見**: CNRS-Strasbourg/INRSのグループ(Asgarkhanova et al. 2026, *Molecular
Informatics*, doi:10.1002/minf.70030)が、本プロジェクトのHuskinDB+SkinPiX+INRS
統合データセット(214化合物)と実質的に同一組成(209化合物、HuskinDB129+SkinPiX103+
INRS3)のデータセットで既にQSPRモデルを発表している。本文は購読制(HTTP 403、
Unpaywallでも確認)のため手法・性能指標は不明。

**判断**: この発見は`research/CLAUDE.md`が最初から「統合QSPRデータセット」の出典として
Asgarkhanova et al.のデータリポジトリ(doi:10.57745/ZUU1DH)を引用していたことと
整合する — つまり本プロジェクトは元々この関係性を知っていたが、その論文自体が
QSPRモデリングを行っていることまでは明示的に認識・記録していなかった可能性が高い。
`RESEARCH_PLAN.md`と`CLAUDE.md`に、データセットの出典表現を正確化する注記を追加した。

**Task 1 (`small-data-ml-paper`, PR #1) への影響**: 別ブランチ・別PRのため、
このタスクでは`small-data-ml-paper/paper.md`を直接編集していない。
`competitive-landscape.md` §11 に、ユーザーへの推奨事項として記録した。

## 2026-07-20: Fable-5利用制限によりSonnet 5が仕上げ段階を代行

**発生事象**: Fable-5への実行指示(implementation-prompt.md)を2回試みたが、いずれも
"You've reached your Fable 5 limit" というAPIエラーで即座に失敗し、実質的な作業
(レビュー・追加調査)は行われなかった。ユーザーに状況を報告し選択肢を提示した結果、
「/usage-credits を確認・補充してから再試行」を選択されたが、2回目の再試行も同じ
制限エラーで失敗した。ユーザーから続行の指示があったため、このセッション
(Claude Sonnet 5)が直接、fable-5に依頼予定だった仕上げ作業を代行した
(独立モデルによるレビューという設計意図は一部失われるが、作業自体は完遂する判断)。

**実施した追加調査(requirements.md §3.2 の4項目)**:
1. **美容成分への応用の独自性**: WebSearchで「skin permeability cosmetic ingredients
   QSAR」「microneedle cosmetic ingredient machine learning permeation prediction」を
   検索。一般的な皮膚透過性QSAR研究は化粧品応用にしばしば言及するが、
   「microneedle特化+化粧品成分+構造ベースQSAR」に一致する先行研究は見つからなかった。
   結論: 未確認のまま(存在しないとは断定しない)。§8-1に反映。
2. **Asgarkhanova et al.の代替アクセス経路**: WebSearchで著者名・所属機関を検索。
   Wiley抄録ページから「209化合物・Kp値・メタデータ」という抄録レベルの情報は
   再確認できたが、プレプリントや本文PDFへの経路は見つからなかった。本文入手は未達成。
3. **小林製薬リードの直接確認**: WebFetchで実際にページを取得し、内容を確認した
   (ラマン分光×ML、トラネキサム酸、IFSCC Congress 2025)。§9で「未検証のリード」から
   「直接確認した事実」に格上げした。
4. **HuskinDB 129 vs 251件の差分**: `research/`配下の全ファイルをgrepしたが、
   この差分を説明する記述は見つからなかった。未解決のまま。§8-3に反映。

**成果物への反映**: `competitive-landscape.md` §8・§9・§10 を上記の結果で更新した。
confidenceの低い主張を確認済みとして書き直すことはしていない — 「見つからなかった」
という結果自体を正直に記録した。

### requirements.md §6 Acceptance checklistの自己採点

- [x] `competitive-landscape.md` の全記述がdeep-research結果またはこのタスクでの
      追加調査結果のいずれかに遡れる
- [x] §8の未解決の問いのうち、(1)美容成分応用の独自性、(3)小林製薬リードの確認、
      について追加調査を行い、結果(確認できた/できなかった)を記録した
- [x] `RESEARCH_PLAN.md` / `CLAUDE.md` への追記に矛盾がない(Sonnet 5が前段階で追記済み、
      本段階では変更していない)
- [x] `README.md`, `notes/decision-log.md` が完成している
- [x] 全Markdownに `[HTML版を開く]` リンクがある
- [x] `shared/scripts/build-website.sh` がエラーなく完走する(「Validated Markdown-to-HTML links.」を確認)

## 2026-07-21: 独立QA監査(Sonnet 5)

**実施**: 別ワークツリーでの独立監査として、`competitive-landscape.md`の主要な主張を
再検証した。手法: (1) `research/*.csv`を実際に読み込み、行数・`sources`列の内訳を
集計して本文の数字と突き合わせ、(2) WebFetch/WebSearchで一次資料(Abdallah et al. 2024
のPLOS本文、Asgarkhanova et al. 2026のWileyページ、小林製薬ページ、HuskinDB 2020論文)
に直接アクセスして本文の記述と照合した。

**確認できたこと(修正不要)**:
- 214化合物データセットの内訳(`sources`列: HuskinDB単独108 + SkinPiX単独82 +
  HuskinDB∩SkinPiX重複21 + INRS_new 3 = 214)は、§4が引用するAsgarkhanova et al.データ
  リポジトリの生ファイル内訳(129+103+3)と整合する(129=108+21, 103=82+21)。214 vs 209の
  差分5件は本当に未解決のまま(捏造・誤帰属なし)。
- Asgarkhanova et al. (doi:10.1002/minf.70030) は実在の論文(Wiley, 2026年オンライン公開)。
  WileyページはこちらのWebFetchでもHTTP 403 — 本文購読制の記述通り。
- `research/CLAUDE.md`の統合QSPRデータセットDOI引用(doi:10.57745/ZUU1DH, Asgarkhanova et
  al.)は、競合分析タスク(commit 8219674, 21:57)より前のコミット(6401e82, 20:32)で
  既に存在していた。「最初から引用していた」という§4の記述は循環論法ではない。
- 小林製薬ページ(§9)を直接fetchし、ラマン分光+MCR-ALS・トラネキサム酸・3D皮膚モデル・
  IFSCC Congress 2025の全要素を確認 — decision-logが「直接確認済み」とする記述は正確。
- HuskinDB 2020論文は実際に251化合物・546測定値を報告している(WebSearchで確認) —
  §8-3の未解決の問い自体は実在する数字に基づく妥当な問いである。
- §8・§9・§10の「未確認」「未解決」表現は、`RESEARCH_PLAN.md`・`CLAUDE.md`を含め
  リポジトリ全体で確認済みの事実として書き換えられている箇所は見つからなかった。

**修正した誤り**: §3(Abdallah et al. 2024)の「**マイクロニードルへの言及なし**」という
太字の断定は誤り。PLOS本文をWebFetchで直接確認したところ、参考文献リスト内に
Yuan et al. 2023(本プロジェクトの前身論文)が"microneedled skin"を含むタイトルで
1件引用されており、本文中の言及がゼロというのは事実に反する(本文・手法・考察に登場
しないという点は正しい)。これは同じ§3の脚注が「マイクロニードルに全く言及がなく…
という統合主張も2票中1票の僅差で不成立」とadversarial verificationの結果を報告して
いた箇所と整合していなかった — 本文の断定的な太字表現が、脚注自身が示す「不成立」判定
と矛盾していた。該当箇所を「本文中での実質的な言及・応用はない(参考文献リストに
Yuan et al. 2023が1件引用されているのみ)」という正確な表現に修正した。

**修正しなかった懸念点(要人間レビュー)**: §3のLightGBM R²=0.819 / Gradient Boosting
R²=0.818 / ANN R²=0.797という数字は、WebFetchによるPLOS本文の2回の再抽出で
0.823 / 0.820 / 0.795という近いが完全には一致しない値が返った(MLRの0.338は両方で
一致)。WebFetchは要約に小型モデルを使うため抽出誤差の可能性があり、どちらが正確か
断定できないためこの数字自体は変更していない。人間が論文Table 1を直接確認することを
推奨する。

## (このセクションは各ステージ完了時に追記される)
