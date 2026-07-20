# BiG Lab 研究面談：予習・準備メモ

更新日: 2026-07-15  
面談相手: Yunong Yuan さん、Jingjing You 先生

関連: [学習・研究参加ロードマップ](learning-roadmap.md)

## 結論

来週の面談までに、すべての技術を広く学ぶ必要はない。以下の3点を準備する。

1. 研究室の主要テーマを理解する
2. 最初の小さな貢献案を1つ用意する
3. 面談で研究の範囲・期待値・トレーニングを確認する

この面談は技術試験ではなく、研究プロジェクトを一緒に定義するための最初の打合せとして臨む。

## 研究室との接点

Jingjing You 先生の研究は、コラーゲン系バイオマテリアル、角膜の再生医療・3Dバイオプリンティング、ケラトコーヌスに対する機械学習などを横断している。

- [University of Sydney: Jingjing You — Horizon Fellows](https://www.sydney.edu.au/research/our-research/horizon-fellows.html)
- [研究実績・出版物一覧](https://www.unsw.edu.au/staff/jingjing-you)

自分の Claude Code、マルチエージェント、データ可視化、3D デザインの経験は、研究そのものを置き換えるものではなく、以下の補助として活かす。

- 文献・実験メタデータの整理
- 再現可能なデータ処理と可視化
- ポスターや研究説明用の図・3Dモデル
- 研究者による検証を前提にしたAI支援ワークフロー

## 読むもの（優先順）

### 1. 必読

[A New Bioprinted Dual-Layered Corneal Structure Using Collagen-Based Bioinks (2026)](https://pubmed.ncbi.nlm.nih.gov/41742708/)

- Yunong Yuan さんと Jingjing You 先生が共著
- コラーゲン系バイオインクを使った二層角膜構造が主題
- 面談の共通言語に最もなりやすい論文

### 2. 次に読む

[3D Printing Strategies for Bioengineering Human Cornea (2026)](https://doi.org/10.1002/adhm.202502767)

### 3. 背景を補うために読む

[Application of Collagen I and IV in Bioengineering Transparent Ocular Tissues (2021)](https://doi.org/10.3389/fsurg.2021.639500)

## 論文ノートのテンプレート

各論文について、全文を完璧に理解しようとせず、以下の5点を箇条書きで記録する。

1. どの臨床課題を解決したいのか
2. 何を作成・比較・評価したのか
3. 成功をどの指標で評価したのか
4. 限界と次の研究課題は何か
5. AI・データ可視化・3Dデザインが役立ちそうな箇所はどこか

## 面談で示す小さな初期プロジェクト案

### 案: Bioink / corneal research evidence visualisation pilot

**目的**  
許可された公開文献またはラボ承認済みの実験メタデータを、再現可能な形で整理・可視化する。

**最初の4週間の成果物**

- データ項目と出典を明記したデータ辞書
- 実験条件・評価指標・結果を比較できる整理表
- 再現可能な可視化ノートブックまたは小さなダッシュボード
- 研究発表・ポスターに使える図を1枚

**注意**

- 患者データや未公開ラボデータは、倫理承認・権限・保管ルールを確認するまで扱わない
- AIの出力を研究結果として扱わず、必ず研究者が検証する
- 最初の範囲は小さくし、ラボの最優先課題に合わせて変更する

## 面談で確認する質問

1. 現在、研究室で最も優先度が高い研究課題は何ですか？
2. 私は wet lab、データ解析、可視化のどこから始めるのが最も役立ちますか？
3. 最初の1か月で期待される成果物は何ですか？
4. 必要な安全・実験・データ管理トレーニングは何ですか？
5. 週あたりの期待時間、連絡方法、成果共有の頻度はどの程度ですか？
6. データ利用、倫理承認、知的財産・発表に関するルールはありますか？

## 面談での英語スクリプト

> I read the recent work on bioprinted corneal structures and was especially interested in how a computational or visualisation workflow could help make research evidence and experimental results easier to compare. I would like to begin with a small, supervised project that supports the group’s current priority. What would be the most useful first problem for me to work on?

## 返信メール案

```text
Dear Yunong,

Thank you very much for your encouraging email. I would be very happy to meet next week to discuss the research project.

I am available at [time option 1], [time option 2], or [time option 3] (Sydney time). I have started reading about the group’s corneal bioengineering and bioprinting work, and I look forward to discussing how I could contribute.

Best regards,
Takumi
```

## 今週の実行順

1. 今日: 返信メールを送り、Sydney time で候補時間を2〜3枠示す
2. 明日: 必読論文の要約を5点テンプレートで作る
3. 面談前: 上の初期プロジェクト案をA4一枚または3スライドにする
4. 面談当日: 質問リストと既存の可視化プロジェクトを1つだけ持参する

## やらないこと

- 面談前に大規模なアプリやマルチエージェントシステムを作り始めない
- 許可なく患者データ・未公開データを使わない
- AI生成内容を検証なしで研究上の結論にしない
- 3Dデザインや可視化を目的化せず、研究上の問いと評価指標を先に決める
