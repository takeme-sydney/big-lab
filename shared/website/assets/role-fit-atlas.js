const roles = [
  {
    id: 1,
    title: "研究戦略・ラボ統括",
    category: "leadership",
    status: "expert",
    score: 28,
    work: "研究テーマ、資金、採用、指導、共同研究、品質・倫理の最終責任を持つ。",
    verdict: "CEO経験はあるが、医学研究のPI／supervisorとして必要な学位・論文・研究資金・監督実績がない。",
    gap: "PhD以降の専門研究実績、grant、supervision、research governance。",
    next: "主担当ではなく、明確なproject charterと週次報告でPIの判断負担を減らす。",
    evidence: "BIG leadとsupervisionはJingjing You氏の公開役割として確認。",
    sources: ["S1", "S2", "S6"]
  },
  {
    id: 2,
    title: "臨床ニーズ・眼科判断",
    category: "core",
    status: "expert",
    score: 30,
    work: "患者課題、角膜疾患、手術、臨床的有用性、評価指標を研究課題へ変換する。",
    verdict: "Medical Scienceの学習は入口になるが、医師資格・眼科訓練・患者診療経験はない。",
    gap: "corneal anatomy / pathology、clinical workflow、diagnostic validity、患者安全。",
    next: "臨床指標の意味を学び、眼科研究者が定義した問いとラベルを解析へ反映する。",
    evidence: "Save Sight InstituteとBIENCOの公開体制にはophthalmologist／clinical collaboratorsが含まれる。",
    sources: ["S4", "S5", "S6"]
  },
  {
    id: 3,
    title: "バイオマテリアル・collagen設計",
    category: "core",
    status: "train",
    score: 42,
    work: "collagen、hydrogel、bioinkの組成・架橋・透明性・力学・生体適合性を設計する。",
    verdict: "biochemistryとMedical Scienceの基礎、bioink研究支援への接点はあるが、材料設計の実証がない。",
    gap: "polymer / collagen chemistry、rheology、crosslinking、material characterisation。",
    next: "まず文献evidence matrixとrun schemaを担当し、材料調製は正式トレーニング後に限定して学ぶ。",
    evidence: "collagen biomaterialsとprintable bioinksはBIGの中心的研究領域。",
    sources: ["S1", "S2", "S6", "S8"]
  },
  {
    id: 4,
    title: "Protein engineering・持続可能なbiomanufacturing",
    category: "core",
    status: "expert",
    score: 35,
    work: "human collagen / proteinの生産、精製、characterisation、scale-up、green manufacturingを進める。",
    verdict: "データ・工程可視化は支援できるが、protein engineeringや製造プロセスを独力で設計できる証拠はない。",
    gap: "molecular biology、protein expression / purification、process development、manufacturing QC。",
    next: "team leadの下でbatch / process registry、yield・QCの可視化から関与する。",
    evidence: "Horizon projectと2026年公開更新でbiomanufacturing / protein engineering team leadを確認。",
    sources: ["S1", "S7"]
  },
  {
    id: 5,
    title: "細胞培養・tissue engineering",
    category: "core",
    status: "expert",
    score: 38,
    work: "corneal / retinal cells、stem cells、layer formation、phenotype、組織成熟を扱う。",
    verdict: "医学基礎はあるが、無菌操作、cell culture、passage、marker評価の実務証拠がない。",
    gap: "lab safety、aseptic technique、cell culture、assay、tissue-specific biology。",
    next: "正式な安全・細胞培養trainingを受けるまで、画像・metadata解析のみに限定する。",
    evidence: "角膜内皮再生、RPE、iPSC、tissue engineeringは公開研究・学生課題で確認。",
    sources: ["S1", "S3", "S5", "S7"]
  },
  {
    id: 6,
    title: "3D bioprinting・医療device engineering",
    category: "core",
    status: "train",
    score: 54,
    work: "print path、装置、曲面・多層construct、FixStem等のdelivery deviceを試作・改善する。",
    verdict: "Blender / 3D visualisationとbioink printing research支援は強い接点。ただし装置操作・造形条件の独立判断は未実証。",
    gap: "printer training、G-code / path、extrusion、sterility、device testing、calibration。",
    next: "既存printとtarget CADのgeometry QCから入り、装置操作はsupervised training後に進む。",
    evidence: "3D corneal printing、FixStem、handheld delivery deviceはBIGの公開活動で確認。",
    sources: ["S1", "S2", "S6", "S7", "S8"]
  },
  {
    id: 7,
    title: "Drug / cell delivery・microbiology",
    category: "core",
    status: "train",
    score: 43,
    work: "眼疾患向けdelivery system、antimicrobial device、release、感染・微生物評価を扱う。",
    verdict: "pharmacology / microbiologyの認定単位は接点になるが、delivery実験・microbial assayの実証がない。",
    gap: "release kinetics、microbiology、dose、bioactivity、安全性、device testing。",
    next: "承認済みデータのrelease curve・condition table・traceabilityから支援する。",
    evidence: "corneal drug delivery、antimicrobial contact lens、cell deliveryは公開プロジェクト。",
    sources: ["S1", "S2", "S3", "S7", "S8"]
  },
  {
    id: 8,
    title: "Microscopy・biological assay・安全性評価",
    category: "validation",
    status: "expert",
    score: 39,
    work: "LIVE/DEAD、marker、layer continuity、phenotype、toxicityなどを測定・解釈する。",
    verdict: "画像処理の支援は可能だが、assay設計・生物学的意味・除外判断を単独で担う段階ではない。",
    gap: "microscopy acquisition、staining、assay controls、cell biology、genotoxicity / biosafety。",
    next: "研究者が付けたmanual annotationとの一致を測る半自動image QCを小規模に実証する。",
    evidence: "細胞生存・層構造・組織評価はcorneal construct研究の主要validation。",
    sources: ["S5", "S6", "S8"]
  },
  {
    id: 9,
    title: "Computational modelling・simulation",
    category: "data",
    status: "train",
    score: 56,
    work: "材料・熱・流体・力学・transport・print geometryを数理モデルと実験で比較する。",
    verdict: "Python・科学データ・3Dの接点はあるが、境界条件や材料モデルを研究水準で設計した証拠がない。",
    gap: "mechanics、transport、numerical methods、parameter estimation、model validation。",
    next: "新規modelではなく、既存modelのinput / output、residual、assumptionを再現するところから始める。",
    evidence: "BIGの共同研究・cornea reviewにはsoftware、simulation、validationの役割が現れる。",
    sources: ["S1", "S6", "S8"]
  },
  {
    id: 10,
    title: "AI / machine learning・bioinformatics",
    category: "data",
    status: "collab",
    score: 68,
    work: "画像、疾患、材料、製造条件、drug discoveryの分類・予測・最適化を支援する。",
    verdict: "AI APIとproduct実装経験は強いが、研究MLのvalidation・bias・small-nへの実証は不足。",
    gap: "study design、cross-validation、leakage、uncertainty、biological validation、MLOps for research。",
    next: "baseline、data audit、grouped split、failure analysisを先に作り、必要性が示せた場合だけMLへ進む。",
    evidence: "machine learningはHorizon projectの方法、AIはHDR・角膜研究の公開領域。",
    sources: ["S1", "S3", "S6", "S8"]
  },
  {
    id: 11,
    title: "Research data engineering・reproducibility",
    category: "data",
    status: "now",
    score: 84,
    work: "sample・run・batch・raw・processed・method versionを結び、再実行可能な研究証拠を作る。",
    verdict: "full-stack / data / workflow / documentationの経験が直接活きる、最有力領域。",
    gap: "ラボ固有sample hierarchy、data policy、research code validation、instrument formats。",
    next: "1つのprojectでdata dictionary、registry、unit / missingness check、versioned reportを完成させる。",
    evidence: "BIGの多分野研究を比較可能にする基盤機能。Takumiのproduct engineeringと最も強く一致。",
    sources: ["S2", "S6", "S8"]
  },
  {
    id: 12,
    title: "Image / geometry QC・3D計測",
    category: "data",
    status: "now",
    score: 86,
    work: "OCT、scan、写真、顕微鏡、CADから曲率・厚さ・層・surface deviationを定量化する。",
    verdict: "3D visualisation、Blender、研究intern、科学データ、Visual Artsが交差する最適領域。",
    gap: "metrology、pixel / voxel calibration、registration、transparent object optics、manual-reference validation。",
    next: "Curved Corneal Construct Geometry QCを2〜4週間でpilotする。",
    evidence: "曲面・多層角膜とvisualisation / software / validationは公開研究に直接現れる。",
    sources: ["S6", "S8"]
  },
  {
    id: 13,
    title: "Statistics・DoE・validation",
    category: "validation",
    status: "train",
    score: 58,
    work: "experimental unit、反復、batch effect、uncertainty、多目的trade-off、比較設計を定義する。",
    verdict: "SPring-8とdata analysisの経験はあるが、biomedical research designを単独で決める段階ではない。",
    gap: "power、mixed effects、DoE、multiple testing、confirmatory analysis、reporting standard。",
    next: "指導者とn・unit・primary metricを固定し、探索／確認を分けた小規模解析を行う。",
    evidence: "BIGの材料・細胞・造形をつなぐ研究ではvalidationとcondition comparisonが必須。",
    sources: ["S2", "S6", "S8"]
  },
  {
    id: 14,
    title: "Lab operations・安全・倫理・QA",
    category: "ops",
    status: "train",
    score: 50,
    work: "SOP、training、在庫、機器、data access、biosafety、ethics、quality recordを維持する。",
    verdict: "業務設計・権限管理・チェックリスト経験は活きるが、lab safety / ethicsの正式資格・経験は未確認。",
    gap: "institutional policy、biosafety、human / animal ethics、GxP / ISO、incident reporting。",
    next: "ルールを設計する前にラボのtrainingを受け、承認済みSOPの記録・検索性改善から支援する。",
    evidence: "実験・臨床translationには不可欠だが、公開ラボ資料に専任者名は確認できないため機能として推定。",
    sources: ["S2", "S4", "S5", "S8"]
  },
  {
    id: 15,
    title: "Project coordination・研究documentation",
    category: "ops",
    status: "now",
    score: 90,
    work: "問い、担当、期限、decision、open question、meeting、handoff、成果物を運用する。",
    verdict: "CEO / product lead / workflow設計 / documentationの実績がそのまま使える。",
    gap: "academic authorship、lab meeting culture、research priority、研究者の時間に合わせた軽量運用。",
    next: "project charter、weekly 1-page update、decision log、review checklistを1 pilotだけで実証する。",
    evidence: "supervision記事はinitial trainingとprioritisationの重要性を明示。",
    sources: ["S2", "S8"]
  },
  {
    id: 16,
    title: "Scientific visualisation・研究communication",
    category: "translation",
    status: "now",
    score: 93,
    work: "figure、3D schematic、poster、graphical abstract、研究説明、public engagementを作る。",
    verdict: "Visual Arts、Mixed Reality、video、3D、UI / UX、日英説明が最も強く重なる。",
    gap: "figure integrity、n / unit / uncertainty、画像処理開示、journal style、scientific caption。",
    next: "実測figureと説明schematicを分け、出典・version・limitation付きの1枚を作る。",
    evidence: "論文author contributionのvisualisationとBIGの公開demonstration活動に直接対応。",
    sources: ["S6", "S7", "S8"]
  },
  {
    id: 17,
    title: "Commercialisation・IP・product development",
    category: "translation",
    status: "collab",
    score: 78,
    work: "臨床価値、製造性、market fit、IP、partner、spin-off、製品要件を研究と接続する。",
    verdict: "founder / product lead / B2B validation経験は強い。ただしmedtech規制・clinical evidence・tech transferは要専門家。",
    gap: "TGA / FDA pathway、QMS、clinical trial、freedom-to-operate、university IP、biomanufacturing scale。",
    next: "研究成果のclaim / evidence / user / workflow / riskを整理し、commercialisation officeと研究者の判断を支える。",
    evidence: "iFix、BIENCO、PERIscope、spin-off、patentはBIG周辺の公開活動の中心。",
    sources: ["S1", "S2", "S4", "S8"]
  },
  {
    id: 18,
    title: "学際・産学・日英collaboration",
    category: "translation",
    status: "collab",
    score: 79,
    work: "medicine、engineering、science、industry、他大学、学生、一般社会の間で情報を接続する。",
    verdict: "日英、豪州での学業、通訳、founder-led communication、複数専門の翻訳が活きる。",
    gap: "scientific terminology、stakeholder authority、confidentiality、研究成果の正確な要約。",
    next: "会議後のdecision / owner / evidence / open questionを日英で短く整理し、専門家確認を受ける。",
    evidence: "BIGとBIENCOは複数大学・臨床・industryをつなぐmultidisciplinary collaboration。",
    sources: ["S2", "S4", "S5", "S7", "S8"]
  }
];

const statusMap = {
  now: {
    label: "今すぐ価値を出せる",
    color: "#087d76",
    border: "rgba(8,125,118,.35)",
    background: "rgba(8,125,118,.09)"
  },
  collab: {
    label: "専門家と共同で可能",
    color: "#4b8e91",
    border: "rgba(75,142,145,.35)",
    background: "rgba(75,142,145,.09)"
  },
  train: {
    label: "限定範囲・訓練後",
    color: "#a57511",
    border: "rgba(165,117,17,.35)",
    background: "rgba(165,117,17,.09)"
  },
  expert: {
    label: "現時点では専門家領域",
    color: "#b65c4d",
    border: "rgba(182,92,77,.35)",
    background: "rgba(182,92,77,.09)"
  }
};

const roleGrid = document.querySelector("#role-grid");
const searchInput = document.querySelector("#role-search");
const filters = [...document.querySelectorAll(".filter")];
const resultsMeta = document.querySelector("#results-meta");
const emptyState = document.querySelector("#empty-state");
let activeFilter = "all";

function sourceLinks(sourceIds) {
  return sourceIds
    .map(id => `<a href="#source-${id.toLowerCase()}" aria-label="出典 ${id}">${id}</a>`)
    .join("");
}

function cardTemplate(role) {
  const status = statusMap[role.status];
  const searchText = [
    role.title,
    role.work,
    role.verdict,
    role.gap,
    role.next,
    role.category
  ].join(" ").toLowerCase();

  return `
    <article class="role-card" data-status="${role.status}" data-search="${searchText}">
      <header class="role-top">
        <div>
          <span class="role-index">${String(role.id).padStart(2, "0")} / 18 · ${role.category.toUpperCase()}</span>
          <h3 class="role-title">${role.title}</h3>
        </div>
        <span
          class="score-ring"
          style="--score:${role.score};--ring:${status.color}"
          data-score="${role.score}"
          aria-label="適合度 ${role.score} / 100"
        ></span>
      </header>
      <div
        class="role-body"
        style="--status-color:${status.color};--status-border:${status.border};--status-bg:${status.background}"
      >
        <span class="status-pill">${status.label}</span>
        <p><b>BIGでの仕事：</b>${role.work}</p>
        <p><b>Takumi判定：</b>${role.verdict}</p>
        <details>
          <summary>ギャップ・次の実証・根拠を見る</summary>
          <div class="detail-grid">
            <div><span>GAP</span><p>${role.gap}</p></div>
            <div><span>NEXT PROOF</span><p>${role.next}</p></div>
            <div><span>PUBLIC EVIDENCE</span><p>${role.evidence}</p></div>
          </div>
          <div class="source-refs">${sourceLinks(role.sources)}</div>
        </details>
      </div>
    </article>
  `;
}

roleGrid.innerHTML = roles.map(cardTemplate).join("");

function applyFilters() {
  const query = searchInput.value.trim().toLowerCase();
  const cards = [...roleGrid.querySelectorAll(".role-card")];
  let shown = 0;

  cards.forEach(card => {
    const statusMatch = activeFilter === "all" || card.dataset.status === activeFilter;
    const searchMatch = !query || card.dataset.search.includes(query);
    const visible = statusMatch && searchMatch;
    card.hidden = !visible;
    if (visible) shown += 1;
  });

  resultsMeta.textContent = `${shown} / ${roles.length} roles shown`;
  emptyState.hidden = shown !== 0;
}

filters.forEach(button => {
  button.addEventListener("click", () => {
    activeFilter = button.dataset.filter;
    filters.forEach(item => item.setAttribute("aria-pressed", String(item === button)));
    applyFilters();
  });
});

searchInput.addEventListener("input", applyFilters);
