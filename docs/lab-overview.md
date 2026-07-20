---
title: BiG Lab とは何か — 取り組みの全体像
created: 2026-07-16
updated: 2026-07-16
status: overview
---

# BiG Lab とは何か — 取り組みの全体像

## まず結論

BiG Lab は、University of Sydney の School of Medical Sciences にある **Biomedical Innovation Group（公式表記は BIG）** である。

一言でまとめると、次の研究グループである。

> **医学上の課題に対して、コラーゲンなどの生体材料、組織工学、3Dバイオプリンティング、医療デバイス、AIを組み合わせ、新しい治療法を研究・実用化するグループ。**

公開情報では特に、**角膜を修復・再生・置換する研究**が代表的である。ただし、BIG全体は角膜だけに限定されておらず、人の組織、薬剤送達、疾患の検出・モニタリング、創薬までを公式の研究範囲としている。

## BIGが解決しようとしていること

中心にあるのは、「技術を作ること」ではなく、次のような臨床上の問題を解決することである。

- 損傷・疾患で失われた組織を、どのように修復または置換するか
- ドナー角膜の不足に対して、人工的に作った組織を代替手段にできるか
- 薬や細胞を、必要な場所へ効果的に届けられるか
- 病気を早く見つけ、進行を予測・モニタリングできるか
- 研究室で得た成果を、実際の医療デバイスや治療へつなげられるか

つまりBIGは、医学、細胞生物学、材料科学、工学、データサイエンスを横断する **translational research（臨床応用を目指す橋渡し研究）** を行っている。

## 公式に示されている4つの研究領域

University of Sydney の[Biomedical Innovation Group 公式ページ](https://www.sydney.edu.au/medicine-health/our-research/research-centres/biomedical-innovation-group.html)では、研究領域を次の4つに整理している。

| 研究領域 | 平易な説明 | 公開情報で確認できる例 |
| --- | --- | --- |
| Human tissue bioengineering | 人の組織を人工的に再現・修復する | 角膜組織、曲面・多層のバイオプリント角膜 |
| Biomaterial production | 体内や細胞と共存できる材料を作る | コラーゲン、透明なbioink、Col-I / Col-IV bioink |
| Drug delivery devices | 薬や細胞を患部へ届ける仕組みを作る | 角膜修復材、抗菌デバイス、iFixのin-situ printing技術 |
| AI for disease and drug discovery | AIで病気の検出・経過観察・創薬を支援する | ケラトコーヌスの進行予測、機械学習による創薬研究 |

この4領域は別々ではなく、ひとつの治療開発プロセスとしてつながっている。

## 代表的な取り組み

### 1. コラーゲン系バイオマテリアルとbioinkの開発

コラーゲンは、人の組織を支える主要なタンパク質である。BIGでは、コラーゲンを治療材料や3Dプリンター用の **bioink** として利用する研究を進めている。

bioinkは、単なる「3Dプリンターのインク」ではない。目的に応じて、次の条件を両立させる必要がある。

- 印刷できること
- 目的の形を保てること
- 細胞が生存・機能できること
- 組織に適した構造と成分を持つこと
- 角膜用途では透明性や曲率なども満たすこと

現在の公開情報では、持続可能なコラーゲン製造、疾患治療用の生体材料、Col-I / IV bioinkなども重点領域として示されている。

### 2. 角膜の3Dバイオプリンティング

角膜は透明で、適切な曲率と複数の細胞層を持つ組織である。そのため、「細胞を含む材料を印刷できた」だけでは、角膜を再現したことにはならない。

BIGの研究者らによる2026年の研究では、次を組み合わせた曲面・二層の角膜モデルが報告されている。

- type I collagen内の角膜実質細胞
- type IV collagenで支えた角膜内皮細胞層
- 角膜の後面曲率を再現する曲面support
- 細胞生存、層構造、透明性、形状保持などの評価

これは、将来の角膜組織工学や細胞間相互作用の研究に使える、より生体に近いモデルを作る取り組みである。詳細は[A New Bioprinted Dual-Layered Corneal Structure Using Collagen-Based Bioinks](https://pubmed.ncbi.nlm.nih.gov/41742708/)を参照。

### 3. 角膜修復・薬剤／細胞送達デバイス

BIGは、組織そのものを作るだけでなく、治療材料、薬、細胞を患部へ届ける方法も研究している。

代表例として、角膜損傷部へ治癒材料を直接配置するin-situ printing技術があり、iFix Medicalというspin-offにもつながっている。また、角膜疾患向けの薬剤送達システムや抗菌デバイスの研究も公開されている。

この領域では、「材料の性能」だけでなく、実際に使えるデバイス、安全性、患者の使いやすさ、製造方法、事業化までが重要になる。

### 4. AI・機械学習・データ活用

BIGのAI研究は、AIそのものを目的にするのではなく、医学・材料研究の判断を支援するために使われる。

- 疾患の検出
- 疾患進行の予測とモニタリング
- 実験結果や画像の解析
- 新しい薬剤候補の探索
- 製造・実験条件の比較や最適化

公開情報では、ケラトコーヌスの進行予測モデルと、機械学習を使った創薬が紹介されている。研究で利用する際は、データ品質、評価単位、バイアス、再現性、人間による検証が前提になる。

### 5. 研究成果の臨床応用・事業化

BIGは大学内だけで完結するグループではない。Save Sight Institute、他大学、BIENCO、医療・バイオ系企業などと連携し、研究成果を治療や製品へ移すことを目指している。

具体的には、次の流れを重視していると理解できる。

```text
臨床上の課題
  ↓
材料・細胞・治療方法の設計
  ↓
bioink、3D printing、医療デバイスによる試作
  ↓
形状・光学・力学・細胞・安全性の評価
  ↓
データ解析・AI・再現性の確認
  ↓
共同研究、特許、spin-off、臨床応用
```

## Wet labとDry labはどうつながるか

| 領域 | 主な作業 |
| --- | --- |
| Wet lab | コラーゲン・bioink調製、細胞培養、3Dバイオプリント、染色、各種assay |
| Engineering / manufacturing | プリンター、造形経路、デバイス、製造条件、自動化の設計 |
| Dry lab / computational | 実験データ管理、画像・3D形状解析、統計、simulation、機械学習、可視化 |
| Translation | 臨床ニーズ確認、共同研究、知的財産、製品化、研究発表 |

実際の研究は、これらを繰り返す形で進む。Dry labはWet labの結果を「測定・比較・再利用できるデータ」に変え、その結果を次の実験設計へ戻す役割を持つ。

## BIGとBIENCOの違い

混同しやすいが、両者は同じ組織ではない。

| 名称 | 位置づけ |
| --- | --- |
| BIG | University of Sydney の School of Medical Sciencesにある研究グループ。人組織、バイオマテリアル、薬剤送達、AIを扱う |
| BIENCO | Bioengineering Human Cornea。複数大学が参加し、ドナー角膜不足に対するbioengineered corneaの開発を進めるオーストラリアの共同研究initiative |

BIGのメンバーはBIENCOと協働して角膜研究を進めているが、**「BIG = BIENCO」ではない**。BIENCOはBIGの角膜研究を支える重要な共同研究ネットワークの一つである。詳細は[NSW Tissue Bank — Corneal bioengineering with BIENCO](https://www.sydney.edu.au/save-sight-institute/our-research/nsw-tissue-bank.html)を参照。

## Takumiの参加案との関係

既存資料で提案しているTakumiの役割は、BIG全体の研究を置き換えることではなく、Wet labと研究判断の間にあるデータ層を支援することである。

```text
実験・画像・3D scan・装置出力
  ↓
データ定義、品質確認、画像／形状の定量化
  ↓
統計・simulation・機械学習
  ↓
次の実験条件の判断
  ↓
再現可能な図、レポート、研究発表
```

具体的な候補は次のとおりである。

- constructの曲率・厚さ・形状誤差などのQC
- 顕微鏡画像の細胞生存率・層連続性などの定量化
- sample、print run、bioink batchを追跡するexperiment registry
- Pythonによる再現可能な解析と可視化
- 研究図、3D図、ポスターの作成

ただし、これは現時点の**提案**であり、正式に決まった担当ではない。実際の役割は、BIGの現在の優先課題、利用可能なデータ、指導者の期待、安全・倫理・公開ルールを確認して決める。

## これだけ覚えておけばよい5点

1. BIGは、Biomedical Innovation Groupの略である。
2. 目的は、医学的課題を新しい治療へつなげることである。
3. 主要手段は、人組織のbioengineering、コラーゲン／bioink、薬剤送達デバイス、AIである。
4. 公開研究の中心的な具体例は、角膜修復とbioengineered corneaである。
5. Wet lab、工学、Dry lab、臨床・事業化を連携させる研究グループである。

## 現時点で未確認のこと

公開情報だけでは、次は確定できない。

- 2026年7月時点でラボが最優先している個別プロジェクト
- Takumiに正式に期待される作業と成果物
- 使用できる未公開データ、装置、SOP
- wet labとdry labの実際の担当範囲
- データ、AI、著者資格、知的財産、外部公開のルール

これらは、Yunong Yuan氏・Jingjing You先生との面談で確認する。

## このフォルダ内で次に読むもの

1. [研究面談：予習・準備メモ](meeting-preparation.md) — 面談前に読む論文と質問
2. [Takumiの研究貢献戦略](contribution-strategy.md) — 具体的に何を担当できるか
3. [学習・研究参加ロードマップ](learning-roadmap.md) — 面談前から12週間の進め方

## 主な情報源

- [University of Sydney — Biomedical Innovation Group](https://www.sydney.edu.au/medicine-health/our-research/research-centres/biomedical-innovation-group.html)
- [University of Sydney — Horizon Fellows: Jingjing You](https://www.sydney.edu.au/research/our-research/horizon-fellows.html)
- [University of Sydney — Mentor and me: Yuan Fang and Jingjing You](https://www.sydney.edu.au/news-opinion/news/2024/12/10/mentor-and-me-yuan-fang-and-jingjing-you.html)
- [NSW Tissue Bank — Corneal bioengineering with BIENCO](https://www.sydney.edu.au/save-sight-institute/our-research/nsw-tissue-bank.html)
- Huang H, Yuan Y, et al. [A New Bioprinted Dual-Layered Corneal Structure Using Collagen-Based Bioinks](https://pubmed.ncbi.nlm.nih.gov/41742708/). *Tissue Engineering Part A*. 2026.

## 出典と表現上の注意

本書は、2026年7月16日時点のUniversity of Sydney公式情報、公開論文、このフォルダ内の既存資料を要約したものである。公式ページで確認できる活動と、Takumi向けの参加提案を分けて記述した。未公開の研究計画や正式な担当範囲を示すものではない。
