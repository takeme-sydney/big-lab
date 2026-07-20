[HTML版を開く](README.html)

# BiG Lab Workspace

BiG Labの調査資料、文献レビュー、研究参加案、ポートフォリオ、閲覧用Webサイトをまとめたワークスペースです。
フォルダは**研究分野ごと**（microneedle drug delivery、corneal 3D bioprinting、photopolymer biomaterials）に分け、
分野をまたいで使う資料・サイト基盤は `shared/` にまとめています。

最初に見るページ: [BiG Lab Papers & Evidence](shared/website/index.html)

`shared/website/index.html` が正式な入口です。論文・エビデンスをメイン画面とする
`shared/website/pages/index.html` を開きます。タスク・ノート用の従来のダッシュボードは
`shared/website/pages/workspace.html` にあります。ダッシュボードのHTMLノートでは、
Visual編集、HTMLソース編集、sandboxプレビュー、`.html`の読み込み・書き出しを
ローカルブラウザ内だけで利用できます。

テーマ別の**研究ロードマップモジュール**（`microneedle-drug-delivery/drug-release-profile/`、
`corneal-3d-bioprinting/corneal-geometry-qc/` など）は、それぞれ独立したスタンドアロンHTMLです。
一覧・入口は [shared/html/index.html](shared/html/index.html) にまとめています。

## フォルダ構成

### 研究分野別フォルダ

| フォルダ | 分野 | 内容 |
|---|---|---|
| `microneedle-drug-delivery/` | Microneedle drug delivery | `drug-release-profile/`（作業領域・ロードマップサイト）、`review/`（文献レビュー原稿）、`references/`（論文PDF・メール）、`website-pages/` / `website-templates/`（サイトHTML） |
| `corneal-3d-bioprinting/` | Corneal geometry QC / 3D bioprinting | `corneal-geometry-qc/`（作業領域・ロードマップサイト）、`portfolio/`（synthetic demoポートフォリオ）、`posters/`、`website-pages/` / `website-assets/`（サイトHTML・CSS・JS） |
| `photopolymer-biomaterials/` | Photopolymer biomaterials | `review/`（文献レビュー原稿・図版）、`references/`（論文PDF・メール）、`website-pages/` / `website-templates/`（サイトHTML）、`scripts/`（pandoc lua filter） |

各分野フォルダの内部構成は揃えています: `references/papers/`（論文PDF）、`references/correspondence/`（関連メール画像）、
`website-pages/`（生成済みHTML）。研究ロードマップモジュール（`drug-release-profile/`、`corneal-geometry-qc/`）は
従来どおり `requirements.md`、`implementation-prompt.md`、`templates/`、`notes/decision-log.md`、`references/README.md`、`site/` を持ちます。

### 分野横断フォルダ

| フォルダ | 内容 |
|---|---|
| `shared/docs/` | ラボ概要、面談準備、学習計画、貢献案など分野を横断するMarkdown原稿 |
| `shared/html/` | 研究ロードマップモジュールの一覧ハブ。各モジュールの`site/`へのカード型入口 |
| `shared/website/index.html` | Webサイトの正式な入口（論文・エビデンス） |
| `shared/website/pages/` | 分野非依存のダッシュボード・ガイドHTML（分野固有のレビューHTMLは各分野フォルダの`website-pages/`） |
| `shared/website/assets/` | 共通CSS、JavaScript、画像、翻訳データ |
| `shared/website/templates/` | 分野非依存ページ用Pandocテンプレート（`intern.html`） |
| `shared/review-assets/` | 文献レビューHTML共通のCSS/JS（複数分野のレビューpage から参照） |
| `shared/scripts/` | Webサイト生成と翻訳データ生成のスクリプト |
| `shared/references/papers/yunong-yuan/` | Yunong Yuan氏の論文索引。氏の研究テーマ別（microneedle、3d-printing、biomaterials、biomedical-research-policy）に分類 |
| `shared/references/correspondence/` | 分野を特定しない研究相談メール画像 |
| `tmp/` | 作業用スクラッチ（gitignore対象、分野分けの対象外） |

## 主な原稿

- [BiG Lab概要](shared/docs/lab-overview.md)
- [研究面談の準備](shared/docs/meeting-preparation.md)
- [12週間の学習ロードマップ](shared/docs/learning-roadmap.md)
- [Yunong Yuan氏の研究ガイド](shared/docs/yunong-yuan-research-guide.md)
- [研究貢献マップ](shared/docs/contribution-map.md)
- [研究貢献戦略](shared/docs/contribution-strategy.md)

## HTMLを再生成する

Pandocが利用できる環境で、次を実行します。

```sh
./shared/scripts/build-website.sh
```

分野非依存ページの生成先は `shared/website/pages/`、文献レビューHTML（microneedle / photopolymer）の生成先は
各分野フォルダの `website-pages/` です。専用テンプレートのない単独ノート、文献索引、通信記録は、
`shared/website/templates/research-document.html` と `shared/website/assets/research-document.css` を使って
同名HTMLへ変換します。
専用の生成先を持たないMarkdownは、同じフォルダへ同じベース名のHTMLとして生成されます。
生成後、全Markdownの先頭リンクとHTMLファイルの存在も自動検証されます。

## ノート・調査資料の記録ルール

- BiG Labに関するノートと調査資料は、必ずMarkdown（`.md`）を正本として保存する
- 各Markdownの本文先頭に、対応HTMLへのリンクを `[HTML版を開く](相対パス)` の形式で置く
- YAML front matterがある場合は、先頭の`---`より前ではなく、front matterを閉じる`---`の直後にリンクを置く
- 同じ作業内で、同内容を読めるHTML（`.html`）も生成または更新する
- 既存の生成スクリプトに登録済みの資料は、定められたHTML生成先とテンプレートを使う
- 新規資料に既存の対応関係がない場合は、可能な限りMarkdownとHTMLを同じフォルダ・同じベース名にする
- HTMLのファイル名または保存先がMarkdownと異なる場合は、最寄りのREADMEにも対応関係を記載する
- 固定ページ組版でHTMLとPDFを同時生成する翻訳論文は、本文レイアウトを守るため先頭リンク検証の対象外とし、同名HTMLの存在を専用ビルドで確認する
- MarkdownとHTMLの内容が同期していない状態では、そのノート・調査更新を完了扱いにしない
- `./shared/scripts/build-website.sh`で全HTMLの生成と先頭リンクの検証を行う

## 命名ルール

- ファイル・フォルダ名は原則として小文字の `kebab-case`
- 日付を含む資料は `YYYY-MM-DD-description.ext`
- 論文PDFは `連番-著者-年-短い題名.pdf`
- 原稿、参考資料、生成物、Webサイト素材を別フォルダに保存
- トップレベルは研究分野ごとのフォルダ（`microneedle-drug-delivery/`、`corneal-3d-bioprinting/`、`photopolymer-biomaterials/`）に分け、分野をまたぐ資料・サイト基盤のみ `shared/` に置く

## 取り扱い上の注意

`references/correspondence/`（各分野フォルダおよび`shared/`配下）には個人間のメール画像が含まれます。公開サイトや共有リポジトリへ含める前に、共有範囲と個人情報を確認してください。論文PDFは各索引に記載された入手元・利用条件に従って扱います。
