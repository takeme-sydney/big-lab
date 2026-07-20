[HTML版を開く](README.html)

# Microneedle Notes

このフォルダには、microneedle drug deliveryに関するノートと研究案を保存する。Markdownを正本とし、同じbasenameのHTMLを閲覧用レンダリングとして同期する。

## 文書一覧

| Markdown（正本） | HTML | 内容 |
| --- | --- | --- |
| [`2026-07-20-microneedle-research-examples.md`](2026-07-20-microneedle-research-examples.md) | [`2026-07-20-microneedle-research-examples.html`](2026-07-20-microneedle-research-examples.html) | Yunong Yuan氏の2026-07-17メールと共有文献を起点にした、取り組むべき研究内容の例 |

## MarkdownからHTMLへの変換

このフォルダのHTMLは、同名MarkdownからPandocで生成する。内容を更新した場合は次のコマンドをリポジトリrootで実行し、両形式を同じtask内で更新する。

```sh
microneedle-drug-delivery/Notes/build-notes.sh
```
