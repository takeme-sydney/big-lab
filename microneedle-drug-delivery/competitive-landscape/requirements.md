[HTML版を開く](requirements.html)

# 要件定義 — Microneedle ML: 競合・関連研究マップとギャップ分析

文書版: 1.0
作成日: 2026-07-20
対象: `big-lab/microneedle-drug-delivery/competitive-landscape/competitive-landscape.md`
根拠資料: deep-researchハーネスによる調査結果(このタスクの直前に実行、`research/` プロジェクトとの比較で競合・関連研究を洗い出したもの)+ `microneedle-drug-delivery/research/` の既存資料

## 1. 目的

`microneedle-drug-delivery/research/` で進めているマイクロニードル薬物送達のsmall-data MLアプローチについて、competing/関連する学術・商用の研究・ツール・製品をリサーチし、現在のアプローチとの差分(強み・弱み・見落とし)を特定した上で、`research/` プロジェクトの計画(`RESEARCH_PLAN.md`, `CLAUDE.md`)と今後書く成果物(`small-data-ml-paper/`)に反映できる、具体的でactionableなギャップ分析文書を完成させる。

## 2. これまでに完了している作業(Sonnet 5 が直接実施済み)

- deep-researchハーネスによる調査(6検索角度、26件一次資料取得、113件の主張抽出、25件をadversarial verificationで検証)。
- 調査結果に基づく `competitive-landscape.md` の起草(§1〜11、確認済み事実・棄却された主張・未解決の問いを明確に区別)。
- `research/RESEARCH_PLAN.md` への具体的なチェックリスト項目の追加(Asgarkhanova et al.本文入手、HuskinDB件数の確認、Stevens et al. 2024データの検討、MAMLスタイルメタ学習の言及、Abdallah et al.との方法論比較)。
- `research/CLAUDE.md`「データ出典」節への重要な注記追加(214化合物データセットがAsgarkhanova et al.のデータセットの再利用である可能性)。

**Fable 5の役割はゼロから作ることではなく、上記を批判的にレビューし、可能な範囲で未解決の問いにさらに取り組み、仕上げることである。**

## 3. 必須コンテンツ・タスク

### 3.1 レビュー(必須)

- `competitive-landscape.md` の全ての「確認済み」記述を、deep-research結果(このセッションのタスク通知に含まれる `findings`/`refuted`/`caveats`/`openQuestions`)と突き合わせ、過大解釈や誤帰属がないか確認する。
- 特に §4(Asgarkhanova et al.)の記述が、実際に確認できた事実(データセット組成の一致、本文入手不可という事実)と、推測(「本プロジェクトが再利用している可能性が高い」という推論)を混同していないか確認する。confidence表現が適切か見直す。
- `RESEARCH_PLAN.md` / `CLAUDE.md` への追記が、既存の記述と矛盾していないか確認する。

### 3.2 未解決の問いへの追加調査(できる範囲で)

以下は `competitive-landscape.md` §8 に記載した未解決の問い。WebSearch/WebFetchツールを用いて、可能な範囲で追加調査し、確認できた事実は明記して追記し、確認できなかった場合はその旨を正直に記録する(捏造しない):

1. **[最優先]** 美容成分(美白剤・レチノイド・ビタミンC誘導体・保湿剤等)への機械学習ベースの皮膚透過性予測応用の先行事例。日本語圏を含む。
2. Asgarkhanova et al. (2026, doi:10.1002/minf.70030) の本文入手の再試行(プレプリントサーバ、著者の所属機関リポジトリ、ResearchGate等、Wiley本体以外の経路を試す)。
3. §9に記載した小林製薬のリード(https://skincare.kobayashi.co.jp/field/skincare/penetration02.html)を実際にfetchして内容を確認する。
4. `research/skin_permeability_training_set.csv` および `research/RESEARCH_PLAN.md` の記述を再確認し、129件(HuskinDB)という数字の由来(2020年論文記載の251化合物・546測定値との関係)についてローカル資料から手がかりがないか確認する。

### 3.3 仕上げ

- `README.md`(このモジュールの索引、他モジュールと同じ構成)を完成させる。
- `notes/decision-log.md`(調査・レビューの経緯と主要判断)を完成させる。
- 全Markdownファイルの先頭本文行に `[HTML版を開く](同名.html)` を付与する。
- `shared/scripts/build-website.sh` を実行し、エラーなく完走することを確認する。

## 4. 使用可能な情報源

- このセッションのdeep-researchタスク通知に含まれる調査結果一式(`findings`, `refuted`, `caveats`, `openQuestions`, `sources`)— 全て実在するURL/DOI付き
- `microneedle-drug-delivery/research/` 配下の全資料(RESEARCH_PLAN.md, CLAUDE.md, README.md, literature_map_report.md, 各CSV)
- `microneedle-drug-delivery/small-data-ml-paper/paper.md`(既存の論文原稿。§11で言及した影響を確認する参考として読んでよいが、**このタスクでは編集しない** — 別ブランチ・別PRの管轄)
- WebSearch/WebFetchツール(§3.2の追加調査用)

## 5. 制約(捏造防止・Task 1と同じ規律)

- confidence(確信度)の低い主張、単一ソースの主張、adversarial verificationで棄却された主張を「確認済みの事実」として書かない。
- 追加のWeb調査で確認できなかった場合は「確認できなかった」と明記する。確認できないからといって存在しないと断定しない。
- `small-data-ml-paper/` (Task 1のブランチ・PR)のファイルは編集しない。影響がある場合は本文書(§11)で言及するに留める。
- 実在しないDOI・URLを作らない。

## 6. Acceptance checklist

- [ ] `competitive-landscape.md` の全記述がdeep-research結果またはこのタスクでの追加調査結果のいずれかに遡れる
- [ ] §8の未解決の問いのうち、少なくとも(1)美容成分応用の独自性、(3)小林製薬リードの確認、について追加調査を試み、結果(確認できた/できなかった)を記録している
- [ ] `RESEARCH_PLAN.md` / `CLAUDE.md` への追記に矛盾がない
- [ ] `README.md`, `notes/decision-log.md` が完成している
- [ ] 全Markdownに `[HTML版を開く]` リンクがある
- [ ] `shared/scripts/build-website.sh` がエラーなく完走する
