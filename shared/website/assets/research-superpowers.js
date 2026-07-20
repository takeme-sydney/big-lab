(() => {
  const capabilities = {
    ai: {
      number: "01",
      label: "REPRODUCIBLE IMPLEMENTATION",
      title: "AI Research Ops",
      summary: "Claude Codeで解析を実装し、Claude Scienceで計画・実行・Artifact・Provenanceをつなぐ。",
      input: "研究の問い／承認済みデータ",
      transform: "schema検証・解析・test・記録",
      output: "再実行可能なcode＋figure＋method",
      example: "角膜constructの画像からradius / thicknessを定量化し、全sampleのoverlay、QC flag、method versionを同時に出す。",
      guardrail: "研究者がmetric、除外、解釈、共有範囲を承認する。"
    },
    agents: {
      number: "02",
      label: "PARALLEL SPECIALISTS, ONE SYNTHESIS",
      title: "Multi-agent Systems",
      summary: "探索、抽出、解析、批判的レビューを役割分担し、複雑な仕事を並行化する。",
      input: "研究課題／論文群／分析計画",
      transform: "専門分担・相互検証・統合",
      output: "evidence map＋claim matrix＋audit trail",
      example: "photopolymer biomaterial文献を、材料・光・力学・cell safety担当に分け、共通schemaで統合してevidence gapを見つける。",
      guardrail: "agent同士の一致を正解とみなさず、原典と研究者レビューへ戻す。"
    },
    data: {
      number: "03",
      label: "MAKE THE DECISION VISIBLE",
      title: "Data Visualisation",
      summary: "平均値だけでなく、ばらつき、uncertainty、batch、failure modeを判断できる図へ変える。",
      input: "測定値／条件／QC情報",
      transform: "比較設計・統計表現・視覚階層",
      output: "publication figure＋decision plot",
      example: "print条件ごとの形状誤差を、個々のsample、batch、信頼区間、失敗例を失わずに比較できるfigureへする。",
      guardrail: "見栄えより正確さを優先し、軸・分母・欠損・除外を明記する。"
    },
    "three-d": {
      number: "04",
      label: "CONNECT DESIGN TO MEASUREMENT",
      title: "3D Design",
      summary: "設計形状、印刷条件、実測constructを同じ空間で結び、形状品質を測定可能にする。",
      input: "CAD／mesh／scan／image stack",
      transform: "alignment・section・geometry metric",
      output: "3D overlay＋deviation / thickness map",
      example: "理想的な角膜曲面と印刷後constructをregistrationし、radius、厚み、局所偏差を位置情報つきで示す。",
      guardrail: "校正、座標系、単位、registration errorを記録し、3D表現を測定値と混同しない。"
    },
    poster: {
      number: "05",
      label: "ONE PAGE, ONE RESEARCH STORY",
      title: "Poster Data Visualisation",
      summary: "問い・方法・主要結果・限界・次の実験を、一目でたどれる視覚ストーリーへ統合する。",
      input: "validated figures／methods／claims",
      transform: "narrative・layout・visual hierarchy",
      output: "conference poster＋graphical abstract",
      example: "geometry QC pilotを、problem → method → result → limitation → next experimentの一方向で読めるA0 posterへまとめる。",
      guardrail: "情報を削る時も不都合な結果と限界を残し、装飾で確実性を誇張しない。"
    }
  };

  const tabs = [...document.querySelectorAll("[data-capability]")];
  const fields = {
    number: document.querySelector("[data-panel-number]"),
    label: document.querySelector("[data-panel-label]"),
    title: document.querySelector("[data-panel-title]"),
    summary: document.querySelector("[data-panel-summary]"),
    input: document.querySelector("[data-panel-input]"),
    transform: document.querySelector("[data-panel-transform]"),
    output: document.querySelector("[data-panel-output]"),
    example: document.querySelector("[data-panel-example]"),
    guardrail: document.querySelector("[data-panel-guardrail]")
  };

  const localize = (value) => {
    if (document.documentElement.lang !== "en") return value;
    const page = window.BIG_LAB_ENGLISH?.["research-superpowers.html"];
    return page?.[value] || value;
  };

  const selectCapability = (key, animate = true) => {
    const capability = capabilities[key];
    if (!capability) return;

    tabs.forEach((tab) => {
      const active = tab.dataset.capability === key;
      tab.classList.toggle("is-active", active);
      tab.setAttribute("aria-selected", String(active));
      tab.tabIndex = active ? 0 : -1;
    });

    Object.entries(fields).forEach(([name, element]) => {
      if (element) element.textContent = localize(capability[name]);
    });

    const panel = document.querySelector(".capability-panel");
    panel?.setAttribute("data-active", key);
    if (animate) {
      panel?.animate(
        [{ opacity: 0.55, transform: "translateY(8px)" }, { opacity: 1, transform: "translateY(0)" }],
        { duration: 260, easing: "ease-out" }
      );
    }
  };

  tabs.forEach((tab, index) => {
    tab.addEventListener("click", () => selectCapability(tab.dataset.capability));
    tab.addEventListener("keydown", (event) => {
      if (!['ArrowLeft', 'ArrowRight', 'Home', 'End'].includes(event.key)) return;
      event.preventDefault();
      let next = index;
      if (event.key === 'ArrowLeft') next = (index - 1 + tabs.length) % tabs.length;
      if (event.key === 'ArrowRight') next = (index + 1) % tabs.length;
      if (event.key === 'Home') next = 0;
      if (event.key === 'End') next = tabs.length - 1;
      tabs[next].focus();
      selectCapability(tabs[next].dataset.capability);
    });
  });

  window.addEventListener("biglab:languagechange", () => {
    const active = document.querySelector("[data-capability].is-active");
    selectCapability(active?.dataset.capability || "ai", false);
  });

  document.querySelector("[data-print]")?.addEventListener("click", () => window.print());

  const restoreDeepLink = () => {
    if (!window.location.hash) return;
    const target = document.querySelector(window.location.hash);
    if (target) {
      const header = document.querySelector(".site-header");
      const offset = header ? header.getBoundingClientRect().height : 0;
      window.scrollTo(0, target.getBoundingClientRect().top + window.scrollY - offset);
    }
  };
  window.addEventListener("load", () => window.requestAnimationFrame(restoreDeepLink), { once: true });
})();
