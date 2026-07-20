[HTML版を開く](README.html)

# 翻訳論文

このフォルダには、原論文の誌面構成を維持して作成した日本語訳を収録する。

## Yuan et al. (2023)

- 日本語訳 PDF: [`01-yuan-2023-drug-permeation-microneedled-skin-ml-ja.pdf`](01-yuan-2023-drug-permeation-microneedled-skin-ml-ja.pdf)
- 正本 Markdown: [`01-yuan-2023-drug-permeation-microneedled-skin-ml-ja.md`](01-yuan-2023-drug-permeation-microneedled-skin-ml-ja.md)
- HTML 版: [`01-yuan-2023-drug-permeation-microneedled-skin-ml-ja.html`](01-yuan-2023-drug-permeation-microneedled-skin-ml-ja.html)
- 原論文 PDF: [`../papers/2026-07-17-yunong-yuan-email/01-yuan-2023-drug-permeation-microneedled-skin-ml.pdf`](../papers/2026-07-17-yunong-yuan-email/01-yuan-2023-drug-permeation-microneedled-skin-ml.pdf)

日本語訳は原論文と同じ 15 ページ構成で、2 段組、見出し階層、図表、数式、ヘッダー、フッター、参考文献を再現している。本文、見出し、図表キャプション、表内テキスト、著者貢献、利益相反、データ可用性、倫理声明、補足情報案内を日本語化した。図中の軸、凡例、数式記号と参考文献の書誌情報は、識別性と原図の完全性を保つため原表記を維持している。

## Markdown からの生成

Markdown を正本とし、次のビルドスクリプトで同内容の HTML と PDF を生成する。

```bash
./build-yuan-2023-translation.sh
```

生成経路:

```text
01-yuan-2023-drug-permeation-microneedled-skin-ml-ja.md
  -> Pandoc
  -> 01-yuan-2023-drug-permeation-microneedled-skin-ml-ja.html
  -> Google Chrome print rendering
  -> 01-yuan-2023-drug-permeation-microneedled-skin-ml-ja.pdf
```

組版 CSS と図版は `01-yuan-2023-drug-permeation-microneedled-skin-ml-ja-assets/` に保存している。

## ライセンス

原論文: Yuan Y, Han Y, Yap CW, et al. *Prediction of drug permeation through microneedled skin by machine learning*. Bioengineering & Translational Medicine. 2023;8(6):e10512. DOI: 10.1002/btm2.10512.

原論文は Creative Commons Attribution License (CC BY) で公開されている。日本語訳でも原著者、出典、ライセンスを明記する。
