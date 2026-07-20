# BiG Lab Workspace

BiG Labの調査資料、文献レビュー、研究参加案、ポートフォリオ、閲覧用Webサイトをまとめたワークスペースです。

最初に見るページ: [BiG Lab Papers & Evidence](website/index.html)

`website/index.html` が正式な入口です。論文・エビデンスをメイン画面とする
`website/pages/index.html` を開きます。タスク・ノート用の従来のダッシュボードは
`website/pages/workspace.html` にあります。ダッシュボードのHTMLノートでは、
Visual編集、HTMLソース編集、sandboxプレビュー、`.html`の読み込み・書き出しを
ローカルブラウザ内だけで利用できます。

テーマ別の**研究ロードマップモジュール**（`drug-release-profile/`、`corneal-geometry-qc/` など）は、
それぞれ独立したスタンドアロンHTMLです。一覧・入口は [html/index.html](html/index.html) にまとめています。

## フォルダ構成

| フォルダ | 内容 |
|---|---|
| `docs/` | ラボ概要、面談準備、学習計画、貢献案のMarkdown原稿 |
| `html/` | 研究ロードマップモジュールの一覧ハブ。各モジュールの`site/`へのカード型入口 |
| `drug-release-profile/` | Drug release profile研究の作業領域、補足資料、ノート、テンプレート、ロードマップサイト（`site/`） |
| `corneal-geometry-qc/` | Corneal geometry QC研究の作業領域、補足資料、ノート、テンプレート、ロードマップサイト（`site/`） |
| `reviews/` | テーマ別の文献レビューと図版 |
| `references/papers/` | 論文PDFと入手元・権利情報の索引。Yunong Yuan氏の論文は研究分野別（microneedle、3D printing、biomaterials、biomedical research policy）に分類 |
| `references/correspondence/` | 研究相談に関するメール画像 |
| `portfolio/` | Geometry QC pilotのデータ・ログ・成果物索引 |
| `outputs/` | PDFなどの生成済み成果物 |
| `website/index.html` | Webサイトの正式な入口（論文・エビデンス） |
| `website/pages/` | ダッシュボード本体と各コンテンツHTML |
| `website/assets/` | WebサイトのCSS、JavaScript、画像、翻訳データ |
| `website/templates/` | Pandoc用HTMLテンプレート |
| `scripts/` | Webサイト生成と翻訳データ生成のスクリプト |

## 主な原稿

- [BiG Lab概要](docs/lab-overview.md)
- [研究面談の準備](docs/meeting-preparation.md)
- [12週間の学習ロードマップ](docs/learning-roadmap.md)
- [Yunong Yuan氏の研究ガイド](docs/yunong-yuan-research-guide.md)
- [研究貢献マップ](docs/contribution-map.md)
- [研究貢献戦略](docs/contribution-strategy.md)

## HTMLを再生成する

Pandocが利用できる環境で、次を実行します。

```sh
./scripts/build-website.sh
```

生成先は `website/pages/` です。

## 命名ルール

- ファイル・フォルダ名は原則として小文字の `kebab-case`
- 日付を含む資料は `YYYY-MM-DD-description.ext`
- 論文PDFは `連番-著者-年-短い題名.pdf`
- 原稿、参考資料、生成物、Webサイト素材を別フォルダに保存

## 取り扱い上の注意

`references/correspondence/` には個人間のメール画像が含まれます。公開サイトや共有リポジトリへ含める前に、共有範囲と個人情報を確認してください。論文PDFは各索引に記載された入手元・利用条件に従って扱います。
