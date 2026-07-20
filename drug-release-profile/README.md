# Microneedle Drug Release Profile Research

更新日: 2026-07-17  
状態: 研究計画ドラフト / PI・指導者レビュー前

## Start here

1. 研究ロードマップHTML（ユーザー指定path）: [`../html/index.html`](../html/index.html)
2. HTML実体: [`site/index.html`](site/index.html)
3. 要件定義: [`requirements.md`](requirements.md)
4. 実行用指示文: [`implementation-prompt.md`](implementation-prompt.md)
5. 参考資料索引: [`references/README.md`](references/README.md)
6. 研究計画テンプレート: [`templates/study-charter.md`](templates/study-charter.md)
7. 解析計画テンプレート: [`templates/analysis-plan.md`](templates/analysis-plan.md)

## 研究の中心

このプロジェクトでは、次の3つを別の測定対象として扱う。

1. **Release:** microneedle matrix / coating / reservoir から媒体へ薬物が放出される過程
2. **Permeation:** 放出された薬物が皮膚を通過し、receptor compartmentへ到達する過程
3. **Retention / recovery:** 皮膚、残存patch、donor、receptor、洗浄画分を含む回収・mass balance

Yuan et al. (2023) の主要outcomeは、厳密にはmicroneedle処理皮膚を通過した**累積permeation**であり、microneedle単体からのreleaseだけではない。最初の研究設計では、この区別を固定してから実験・解析を始める。

## フォルダ構成

```text
drug-release-profile/
├── README.md
├── requirements.md
├── implementation-prompt.md
├── references/
│   ├── papers/           # 論文PDFとmetadata-only記録
│   ├── supplementary/    # Data S1、SI 2、SI 3
│   └── correspondence/   # 依頼メール画像
├── templates/        # charter、data dictionary、sampling、実験log、解析計画
├── notes/            # 研究判断を残すdecision log
└── site/             # standalone HTMLと専用asset
```

HTML実体は `site/` にある。画像・CSS・JavaScriptを含むstandalone local siteとして実装しており、`big-lab/html/index.html`（研究ロードマップ一覧ハブ）からもリンクされている。

## 公開元データの初期監査

`references/supplementary/06-yuan-2023-data-s1.xlsx` を読み取り専用で確認した。

- 191 time-point rows
- 6 payloads
- 18 unique feature signatures
- 140 rowsは、説明変数 + timeが同一の別観測と重なる
- `run_id`、`curve_id`、`batch_id`、`skin_donor_id`は含まれない

したがって、191行を191独立実験としてrandom splitする解釈は避ける。再解析前に原著者へ実験単位と曲線対応を確認し、復元できない場合はその不確実性を明示する。

## 利用上の境界

- wet-labの条件、組織利用、薬物、安全、廃棄は、ラボSOP、risk assessment、training、ethics / biosafety approvalを優先する。
- FDAのIVRT / IVPT文書は主に特定のtopical generic productを対象とし、microneedle専用規格ではない。方法開発の原則を参考にする場合も、直接適用とは記載しない。
- 探索的なkinetic modelの高い `R²` だけでrelease mechanismを確定しない。
- 既存の購読資料は個人研究利用の範囲を守り、再配布しない。
