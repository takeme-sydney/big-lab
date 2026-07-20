(() => {
  "use strict";

  const STORAGE_KEY = "big-lab-research-idea-lab-v1";
  const PENDING_TASK_KEY = "big-lab-dashboard-pending-task-v1";
  const app = document.querySelector("[data-idea-app]");
  if (!app) return;

  const fields = Array.from(app.querySelectorAll("[data-field]"));
  const saveState = document.querySelector("[data-save-state]");
  const toast = document.querySelector("[data-toast]");
  let saveTimer;
  let toastTimer;

  const todayISO = () => {
    const date = new Date();
    const offset = date.getTimezoneOffset();
    return new Date(date.getTime() - offset * 60000).toISOString().slice(0, 10);
  };

  const examples = {
    sampling: {
      topic: "Microneedle drug release profile — sampling補正とkinetic model",
      fact: "反復samplingでreceptor液を採取し同量を置換する試験では、過去に取り出した薬物量を累積量へ加える補正が必要である。現在のData S1にはtime-point観測があるが、補正手順とcurve IDは明示されていない。",
      source: "Data S1 / sampling plan / Yuan et al. (2023)",
      evidenceStatus: "文献で確認",
      gap: "sampling / replacement補正の有無が、累積profile、kinetic parameter、model selectionへどの程度影響するか分からない。",
      gapType: "測定・解析方法",
      decision: "再解析パイプラインへ補正を必須実装するか、原著者への確認を先行するか",
      question: "同じraw concentration seriesにおいて、sampling / replacementを補正した累積量と未補正値では、kinetic modelの順位とparameter推定はどの程度変わるか？",
      checkTarget: true,
      checkCompare: true,
      checkOutcome: true,
      checkScope: true,
      hypothesis: "補正後は後半時点の累積量が増え、少なくとも一部のcurveでmodel順位またはparameter推定が変わる。採取割合が大きい条件ほど差が大きい。",
      alternative: "採取量がreceptor volumeに対して十分小さければ、補正の影響は実務上小さい可能性がある。",
      falsifier: "全curveで補正前後のparameter差が事前基準内に収まり、model順位も変わらない。",
      change: "同じ濃度系列に対する累積量の計算法（未補正 / replacement補正）",
      control: "raw concentration、sampling time、receptor volume、採取量、fitting範囲、model実装",
      measure: "累積量、amount / area、AICc、RMSE、parameter差、model順位",
      unit: "独立したrelease / permeation curve（curve ID確認が前提）",
      criterion: "Go：必要なvolume情報とcurve IDを復元できる / Revise：情報不足なら感度分析として範囲を示す / Stop：実験単位を復元できず比較が誤解を生む",
      nextAction: "Data S1とsupplementary fileから、sampling volume・receptor volume・curve IDの有無を一覧にする",
      dueDate: todayISO(),
      deliverable: "列名・単位・欠損・確認先をまとめた1枚の監査表"
    },
    separation: {
      topic: "Microneedleにおけるreleaseとskin permeationの分離",
      fact: "Microneedle matrixから媒体へのreleaseと、皮膚を通過してreceptorへ到達するpermeationは異なる過程である。既存研究の主要outcomeはmicroneedle処理皮膚を通過した累積permeationである。",
      source: "drug-release-profile requirements / Yuan et al. (2023)",
      evidenceStatus: "文献で確認",
      gap: "formulation条件の順位がrelease-onlyとskin permeationで一致するか、皮膚側の抵抗がどの条件で支配的か分からない。",
      gapType: "現象の違い",
      decision: "次のpilotでrelease-only assayとskin permeation assayのどちらを優先するか",
      question: "同一formulation条件において、release-onlyの累積profileとskin permeation profileでは条件順位が一致し、lag timeとrateはどの程度異なるか？",
      checkTarget: true,
      checkCompare: true,
      checkOutcome: true,
      checkScope: true,
      hypothesis: "release-onlyで速い条件が必ずしもpermeationでも速いとは限らず、皮膚を含む条件ではlagと順位の変化が生じる。",
      alternative: "検討範囲ではmatrixからのreleaseが主な律速となり、両assayの順位がほぼ一致する可能性がある。",
      falsifier: "事前に定めた誤差範囲内で全条件の順位、rate、profile形状が一致する。",
      change: "barrier条件（release-only membrane / skin）",
      control: "formulation、loading、exposed area、receptor medium、temperature、sampling schedule",
      measure: "累積量 / area、lag time、初期rate、終点回収量、mass balance",
      unit: "diffusion cell / curve。batchとskin donorをgroupとして記録",
      criterion: "Go：両assayを同一条件で比較できる / Revise：assay性能が不足なら先にvalidation / Stop：承認・組織・SOPが整わない",
      nextAction: "release-onlyとskin permeationで共通化できる条件と別管理する条件を2列表にする",
      dueDate: todayISO(),
      deliverable: "assay比較表とPIへ確認する質問3つ"
    },
    validation: {
      topic: "Microneedle small-data ML — group-aware validation",
      fact: "既存Data S1は191 time-point rowsを含むが、time pointは独立したexperimental unitとは限らず、run_id・curve_id・batch_id・skin_donor_idが明示されていない。",
      source: "Data S1 structure audit / microneedle-small-data-ml review",
      evidenceStatus: "自分の実測",
      gap: "time-point random splitで得た予測性能が、curveまたはpayload単位の未知条件への一般化性能をどの程度楽観的に見積もるか分からない。",
      gapType: "再現性・一般化",
      decision: "再解析で報告できるvalidation単位と、追加で必要なmetadata",
      question: "同じfeature setとmodelにおいて、time-point random splitとpayload / curve単位のgrouped validationでは、予測誤差と不確実性がどの程度変わるか？",
      checkTarget: true,
      checkCompare: true,
      checkOutcome: true,
      checkScope: true,
      hypothesis: "grouped validationでは情報漏洩が減るため誤差が増え、特に未知payloadへの外挿で不確実性が大きくなる。",
      alternative: "timeと分子記述子が十分な説明力を持ち、split方法による差が限定的な可能性がある。",
      falsifier: "同じ反復設計で、誤差分布と順位が事前基準内でほぼ一致する。",
      change: "data split単位（row random / payload grouped / 復元可能ならcurve grouped）",
      control: "前処理、feature、model、hyperparameter search budget、metric、random seed集合",
      measure: "MAE、RMSE、予測区間coverage、split間の性能差",
      unit: "primary split unitはpayloadまたはcurve。time point単独ではsplitしない",
      criterion: "Go：group IDを定義できる / Revise：curve ID不明ならpayload単位を主解析にする / Stop：比較不能なsplit結果を一般化性能として報告しない",
      nextAction: "Data S1で復元可能なgroup候補を列挙し、各候補のrow数と重複を集計する",
      dueDate: todayISO(),
      deliverable: "group候補ごとの件数表とvalidation設計図"
    },
    recovery: {
      topic: "Microneedle assayのmass balance / recovery",
      fact: "receptorへ到達した量だけでは、skin、残存patch、donor、washに残る薬物を説明できない。nominal loadingとassay-confirmed loadingも分ける必要がある。",
      source: "drug-release-profile requirements / analysis plan",
      evidenceStatus: "文献で確認",
      gap: "回収率の不足が真の損失、抽出効率、吸着、sampling、assay誤差のどこから生じるか分からない。",
      gapType: "原因・mechanism",
      decision: "次のpilotで必須とする回収画分とmethod validation項目",
      question: "receptor、skin、残存patch、donor、washの各画分を分けて回収したとき、総回収率の不足を最も説明する工程要因は何か？",
      checkTarget: true,
      checkCompare: true,
      checkOutcome: true,
      checkScope: true,
      hypothesis: "主要な未回収分はskin extractionまたは装置表面への吸着に由来し、画分別のspike recoveryで一部を説明できる。",
      alternative: "nominal loadingのばらつき、分解、定量下限付近の誤差が主要因である可能性がある。",
      falsifier: "全画分で回収・安定性・吸着が許容範囲にあり、不足を説明できない。",
      change: "回収画分と工程control（spike recovery / blank / surface rinse）",
      control: "assay method、extraction時間、温度、標準曲線、nominalおよびassay-confirmed loading",
      measure: "画分別回収量、総回収率、spike recovery、CV、検出下限",
      unit: "diffusion cell / patch。batchを記録",
      criterion: "Go：全画分とcontrolを定量できる / Revise：抽出効率が不足ならmethod改善 / Stop：安全・SOP・assay validationが未完了",
      nextAction: "想定する全回収画分を工程順に並べ、各画分の採取容器・保存・定量法を空欄付きで表にする",
      dueDate: todayISO(),
      deliverable: "mass balance採取フローと未決事項リスト"
    }
  };

  const questionTemplates = {
    compare: (topic) => `${topic}において、条件Aと条件Bで主要アウトカムはどの程度変わるか？`,
    separate: (topic) => `${topic}で一つに扱われている現象を分けて測ると、各過程の寄与はどの程度異なるか？`,
    mechanism: (topic) => `${topic}で観察される変化を、どの要因が最もよく説明するか？`,
    measure: (topic) => `${topic}の結論は、測定指標・補正方法・単位を変えても維持されるか？`,
    boundary: (topic) => `${topic}の関係は、どの条件範囲まで成立し、どこで崩れるか？`,
    reproduce: (topic) => `${topic}で得た結果は、別run・batch・donorでも同じ方向と大きさで再現するか？`
  };

  const showToast = (message) => {
    if (!toast) return;
    toast.textContent = message;
    toast.classList.add("is-visible");
    clearTimeout(toastTimer);
    toastTimer = setTimeout(() => toast.classList.remove("is-visible"), 2200);
  };

  const getState = () => Object.fromEntries(fields.map((field) => [
    field.dataset.field,
    field.type === "checkbox" ? field.checked : field.value
  ]));

  const applyState = (state) => {
    fields.forEach((field) => {
      const value = state[field.dataset.field];
      if (field.type === "checkbox") field.checked = Boolean(value);
      else field.value = value ?? "";
    });
    updateUI();
  };

  const readState = () => {
    try {
      const parsed = JSON.parse(localStorage.getItem(STORAGE_KEY));
      return parsed && typeof parsed === "object" ? parsed : null;
    } catch {
      return null;
    }
  };

  const persist = () => {
    if (saveState) {
      saveState.classList.add("is-saving");
      saveState.lastChild.textContent = " 保存中…";
    }
    clearTimeout(saveTimer);
    saveTimer = setTimeout(() => {
      try {
        localStorage.setItem(STORAGE_KEY, JSON.stringify(getState()));
        if (saveState) {
          saveState.classList.remove("is-saving");
          saveState.lastChild.textContent = " 保存済み";
        }
      } catch {
        if (saveState) saveState.lastChild.textContent = " 保存できません";
      }
    }, 260);
  };

  const valueOf = (name) => {
    const field = fields.find((item) => item.dataset.field === name);
    return field?.type === "checkbox" ? field.checked : field?.value.trim() || "";
  };

  const stepComplete = {
    1: () => Boolean(valueOf("topic") && valueOf("fact")),
    2: () => Boolean(valueOf("gap")),
    3: () => Boolean(valueOf("question")),
    4: () => Boolean(valueOf("hypothesis")),
    5: () => Boolean(valueOf("change") && valueOf("measure") && valueOf("criterion")),
    6: () => Boolean(valueOf("nextAction"))
  };

  const setSummary = (name, value, fallback) => {
    const target = document.querySelector(`[data-summary="${name}"]`);
    if (target) target.textContent = value || fallback;
  };

  const updateUI = () => {
    const completed = Object.keys(stepComplete).filter((step) => stepComplete[step]());
    const percent = Math.round((completed.length / 6) * 100);
    const ring = document.querySelector("[data-progress-ring]");
    const progressValue = document.querySelector("[data-progress-value]");
    const completeCount = document.querySelector("[data-complete-count]");
    if (ring) ring.style.setProperty("--progress", `${percent * 3.6}deg`);
    if (progressValue) progressValue.textContent = `${percent}%`;
    if (completeCount) completeCount.textContent = `${completed.length} / 6`;

    Object.keys(stepComplete).forEach((step) => {
      const isComplete = stepComplete[step]();
      const section = document.querySelector(`[data-step="${step}"]`);
      const nav = document.querySelector(`[data-step-nav="${step}"]`);
      section?.classList.toggle("is-complete", isComplete);
      nav?.classList.toggle("is-complete", isComplete);
      const state = section?.querySelector("[data-step-state]");
      if (state) state.textContent = isComplete ? "記入済み" : "未記入";
    });

    const testParts = [];
    if (valueOf("change")) testParts.push(`${valueOf("change")}を変える`);
    if (valueOf("measure")) testParts.push(`${valueOf("measure")}を測る`);
    if (valueOf("criterion")) testParts.push(`判定：${valueOf("criterion")}`);
    setSummary("topic", valueOf("topic"), "テーマを入力してください");
    setSummary("question", valueOf("question"), "研究質問がここに表示されます");
    setSummary("hypothesis", valueOf("hypothesis"), "仮説がここに表示されます");
    setSummary("test", testParts.join("。"), "最小検証がここに表示されます");
    setSummary("nextAction", valueOf("nextAction"), "次の一歩がここに表示されます");

    const briefDate = document.querySelector("[data-brief-date]");
    if (briefDate) {
      briefDate.textContent = new Intl.DateTimeFormat("ja-JP", {
        year: "numeric",
        month: "2-digit",
        day: "2-digit"
      }).format(new Date());
    }
  };

  const hasMeaningfulState = () => ["topic", "fact", "gap", "question", "hypothesis", "nextAction"]
    .some((name) => Boolean(valueOf(name)));

  const loadExample = (id) => {
    const example = examples[id];
    if (!example) return;
    if (hasMeaningfulState() && !window.confirm("現在の入力をこの記入例で置き換えますか？")) return;
    applyState(example);
    try {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(getState()));
    } catch {
      // The canvas still works for this session if storage is unavailable.
    }
    document.querySelector("#canvas")?.scrollIntoView({ behavior: "smooth" });
    showToast("研究案をキャンバスへ読み込みました");
  };

  const briefMarkdown = () => {
    const state = getState();
    const quality = [
      ["対象が明確", state.checkTarget],
      ["比較または変数がある", state.checkCompare],
      ["測る指標がある", state.checkOutcome],
      ["一つの検証に収まる", state.checkScope]
    ].map(([label, checked]) => `- [${checked ? "x" : " "}] ${label}`).join("\n");
    return `# Research brief — ${state.topic || "Untitled"}

更新日: ${todayISO()}

## 1. 現在地

**確認できている事実**

${state.fact || "—"}

- 根拠: ${state.source || "—"}
- 証拠の状態: ${state.evidenceStatus || "—"}

## 2. 重要なギャップ

${state.gap || "—"}

- 種類: ${state.gapType || "—"}
- 埋まると決められること: ${state.decision || "—"}

## 3. 研究質問

${state.question || "—"}

${quality}

## 4. 仮説

**主仮説:** ${state.hypothesis || "—"}

**別の説明:** ${state.alternative || "—"}

**仮説に反する結果:** ${state.falsifier || "—"}

## 5. 最小検証

- 変えるもの: ${state.change || "—"}
- 固定するもの: ${state.control || "—"}
- 測るもの: ${state.measure || "—"}
- 実験単位: ${state.unit || "—"}
- 判定基準: ${state.criterion || "—"}

## 6. 次の一歩

- 行動: ${state.nextAction || "—"}
- 期限: ${state.dueDate || "—"}
- 成果物: ${state.deliverable || "—"}

> 研究案・作業メモ。事実、推測、提案を区別し、実行前にPI・指導者・所属機関の手順を確認する。
`;
  };

  const copyText = async (text) => {
    if (navigator.clipboard && window.isSecureContext) {
      await navigator.clipboard.writeText(text);
      return;
    }
    const helper = document.createElement("textarea");
    helper.value = text;
    helper.setAttribute("readonly", "");
    helper.style.position = "fixed";
    helper.style.opacity = "0";
    document.body.append(helper);
    helper.select();
    document.execCommand("copy");
    helper.remove();
  };

  fields.forEach((field) => {
    const eventName = field.type === "checkbox" || field.tagName === "SELECT" ? "change" : "input";
    field.addEventListener(eventName, () => {
      updateUI();
      persist();
    });
  });

  document.querySelectorAll("[data-load-example]").forEach((button) => {
    button.addEventListener("click", () => loadExample(button.dataset.loadExample));
  });

  document.querySelectorAll("[data-lens]").forEach((button) => {
    button.addEventListener("click", () => {
      const topic = valueOf("topic") || "この研究テーマ";
      const questionField = fields.find((field) => field.dataset.field === "question");
      if (!questionField) return;
      if (questionField.value.trim() && !window.confirm("現在の研究質問を、この視点のたたき台で置き換えますか？")) return;
      questionField.value = questionTemplates[button.dataset.lens](topic);
      document.querySelectorAll("[data-lens]").forEach((item) => item.classList.toggle("is-used", item === button));
      updateUI();
      persist();
      document.querySelector("#step-3")?.scrollIntoView({ behavior: "smooth", block: "center" });
      setTimeout(() => questionField.focus(), 450);
      showToast("研究質問のたたき台を作りました");
    });
  });

  document.querySelector("[data-reset]")?.addEventListener("click", () => {
    if (hasMeaningfulState() && !window.confirm("キャンバスの入力をすべて消しますか？")) return;
    applyState({ dueDate: todayISO() });
    try {
      localStorage.removeItem(STORAGE_KEY);
    } catch {
      // No action required when storage is unavailable.
    }
    showToast("キャンバスを白紙に戻しました");
  });

  document.querySelector("[data-copy-brief]")?.addEventListener("click", async () => {
    try {
      await copyText(briefMarkdown());
      showToast("研究ブリーフをコピーしました");
    } catch {
      showToast("コピーできませんでした");
    }
  });

  document.querySelector("[data-export]")?.addEventListener("click", () => {
    const topic = valueOf("topic") || "research-brief";
    const slug = topic.toLowerCase()
      .normalize("NFKD")
      .replace(/[^\p{Letter}\p{Number}]+/gu, "-")
      .replace(/^-+|-+$/g, "")
      .slice(0, 48) || "research-brief";
    const blob = new Blob([briefMarkdown()], { type: "text/markdown;charset=utf-8" });
    const url = URL.createObjectURL(blob);
    const link = document.createElement("a");
    link.href = url;
    link.download = `${todayISO()}-${slug}.md`;
    document.body.append(link);
    link.click();
    link.remove();
    setTimeout(() => URL.revokeObjectURL(url), 1000);
    showToast("Markdownを書き出しました");
  });

  document.querySelector("[data-add-task]")?.addEventListener("click", () => {
    const title = valueOf("nextAction");
    if (!title) {
      fields.find((field) => field.dataset.field === "nextAction")?.focus();
      showToast("先に「次の一歩」を入力してください");
      return;
    }
    try {
      localStorage.setItem(PENDING_TASK_KEY, JSON.stringify({
        title,
        due: valueOf("dueDate"),
        createdAt: Date.now()
      }));
      location.href = "workspace.html#tasks";
    } catch {
      showToast("タスクを送れませんでした");
    }
  });

  document.querySelector("[data-print]")?.addEventListener("click", () => window.print());

  const savedState = readState();
  applyState(savedState || { dueDate: todayISO() });
})();
