(() => {
  "use strict";

  const TARGET = { radius: 7.8, thickness: 0.55, radiusTolerance: 0.18 };
  const samples = [
    { id: "C01", batch: "B01", radius: 7.82, thickness: 0.56, surface: 0.08, registration: 0.04, status: "pass" },
    { id: "C02", batch: "B01", radius: 7.91, thickness: 0.54, surface: 0.11, registration: 0.05, status: "pass" },
    { id: "C03", batch: "B01", radius: 8.06, thickness: 0.57, surface: 0.18, registration: 0.08, status: "review" },
    { id: "C04", batch: "B01", radius: 7.76, thickness: 0.53, surface: 0.09, registration: 0.04, status: "pass" },
    { id: "C05", batch: "B02", radius: 7.68, thickness: 0.58, surface: 0.12, registration: 0.06, status: "pass" },
    { id: "C06", batch: "B02", radius: 7.55, thickness: 0.61, surface: 0.21, registration: 0.09, status: "review" },
    { id: "C07", batch: "B02", radius: 7.84, thickness: 0.55, surface: 0.07, registration: 0.04, status: "pass" },
    { id: "C08", batch: "B02", radius: 8.18, thickness: 0.59, surface: 0.27, registration: 0.13, status: "fail" },
    { id: "C09", batch: "B03", radius: 7.72, thickness: 0.54, surface: 0.10, registration: 0.05, status: "pass" },
    { id: "C10", batch: "B03", radius: 7.88, thickness: 0.56, surface: 0.09, registration: 0.05, status: "pass" },
    { id: "C11", batch: "B03", radius: 7.61, thickness: 0.52, surface: 0.16, registration: 0.08, status: "review" },
    { id: "C12", batch: "B03", radius: 7.80, thickness: 0.55, surface: 0.06, registration: 0.03, status: "pass" }
  ];

  const agents = {
    evidence: {
      number: "AGENT 01",
      title: "Evidence Registry",
      input: "承認済み論文・method note・metric definition",
      task: "各主張を原典、引用箇所、適用範囲へ接続する。",
      output: "evidence table / citation trail / unresolved gaps",
      stop: "原典を確認できない主張は推測で埋めず「未確認」として返す。"
    },
    schema: {
      number: "AGENT 02",
      title: "Data & Schema Auditor",
      input: "sample table・mesh metadata・calibration record",
      task: "sample ID、batch、単位、欠損、重複、参照切れを解析前に検証する。",
      output: "validated manifest / data dictionary / issue list",
      stop: "単位・階層・校正が不明なsampleは解析へ進めず、人間へ確認を返す。"
    },
    geometry: {
      number: "AGENT 03",
      title: "Geometry Analyst",
      input: "承認済みmesh・target geometry・fixed config",
      task: "registration、best-fit radius、thickness、surface RMSEを同一条件で計算する。",
      output: "metric table / overlay / deviation mesh / test result",
      stop: "個別sampleだけparameterを変えず、fit失敗と範囲外をQC flagとして残す。"
    },
    visual: {
      number: "AGENT 04",
      title: "Visual Evidence Designer",
      input: "validated metrics・QC flag・all-sample overlay",
      task: "effect、batch、uncertainty、failureを失わない比較図へ変換する。",
      output: "publication figure / dashboard / poster composition",
      stop: "軸・分母・欠損・除外を省略せず、装飾で確実性を誇張しない。"
    },
    review: {
      number: "AGENT 05",
      title: "Claim & Provenance Reviewer",
      input: "claim draft・figure・execution log・source registry",
      task: "各主張がsample、code version、figure、原典へ戻れるかを監査する。",
      output: "claim matrix / contradiction list / human review queue",
      stop: "解析を再実行した、方法が妥当、臨床的に有効とは自動的に保証しない。"
    }
  };

  const paperStages = {
    introduction: {
      index: "01 / INTRODUCTION",
      title: "Evidence gapを定義する",
      purpose: "curved corneal constructの形状再現性を、sample-levelかつ追跡可能に評価する必要性を整理。",
      ai: "文献探索を材料・造形・geometry QCへ分担し、主張ごとの原典と反証を整理。",
      output: "evidence table / citation trail / gap statement draft",
      human: "研究上のgap、採用する根拠、研究目的の最終表現。"
    },
    methods: {
      index: "02 / METHODS",
      title: "解析を再実行可能にする",
      purpose: "入力、校正、registration、metric、tolerance、failure ruleをversionとともに固定。",
      ai: "Claude Codeがloader・metric・testを実装し、Claude Science側で実行記録とArtifactを接続。",
      output: "code + config / method draft / test report / provenance",
      human: "方法の科学的妥当性、manual reference、分析計画の承認。"
    },
    results: {
      index: "03 / RESULTS",
      title: "全sampleと不確実性を見せる",
      purpose: "代表画像だけでなく、radius deviation、batch、failure、registration qualityを同時に提示。",
      ai: "承認済みplanを実行し、全sample plot、3D overlay、flag registryを同じoutputから生成。",
      output: "figure set / caption draft / sample-level source links",
      human: "統計的解釈、除外、追加解析、結果として報告する範囲。"
    },
    discussion: {
      index: "04 / DISCUSSION",
      title: "主張・反証・限界を分ける",
      purpose: "observed resultと機序の推測を混ぜず、代替説明と次の検証を明示。",
      ai: "主張を支持・反証・未確認のevidenceへ分類し、過剰表現と矛盾をレビュー。",
      output: "claim–evidence matrix / limitation register / next-test list",
      human: "生物学的意味、因果、一般化可能性、論文としての最終主張。"
    },
    poster: {
      index: "05 / POSTER",
      title: "一枚のレビュー経路へ統合",
      purpose: "問題 → 方法 → 全sample結果 → failure → 限界 → 次実験を一方向で読める構成へ。",
      ai: "validated figureとapproved claimだけを再配置し、source IDとmethod versionを残す。",
      output: "A0/A3 poster / graphical abstract / presentation figure",
      human: "何を強調するか、誤解がないか、著者性、公開・共有範囲。"
    }
  };

  const $ = (selector, root = document) => root.querySelector(selector);
  const $$ = (selector, root = document) => [...root.querySelectorAll(selector)];
  const signed = (value) => `${value >= 0 ? "+" : "−"}${Math.abs(value).toFixed(2)}`;

  let activeSample = samples[0];
  let activeMode = "deviation";

  const select = $("[data-sample-select]");
  if (select) {
    samples.forEach((sample) => {
      const option = document.createElement("option");
      option.value = sample.id;
      option.textContent = `${sample.id} / ${sample.batch} / ${sample.status.toUpperCase()}`;
      select.append(option);
    });
    select.addEventListener("change", () => setActiveSample(select.value));
  }

  function setText(selector, value) {
    const element = $(selector);
    if (element) element.textContent = value;
  }

  function reviewNote(sample) {
    if (sample.status === "fail") return "Registrationとsurface fitがdemo range外。source meshとalignmentを確認し、再測定／除外は研究者が決定。";
    if (sample.status === "review") return "少なくとも一つのQC triggerを検出。自動除外せず、overlay・校正・batch contextを人間レビューへ。";
    return "Demo tolerance内。overlayとsource meshを研究者が確認後に確定。";
  }

  function setActiveSample(id, options = {}) {
    const sample = samples.find((item) => item.id === id);
    if (!sample) return;
    activeSample = sample;
    if (select) select.value = id;

    const status = $("[data-sample-status]");
    if (status) {
      status.textContent = sample.status.toUpperCase();
      status.dataset.state = sample.status;
      const statusBox = status.closest(".inspector-status");
      if (statusBox) {
        statusBox.style.background = sample.status === "pass" ? "#b8ff74" : sample.status === "review" ? "#ffdf68" : "#ff715f";
      }
    }
    setText("[data-radius]", sample.radius.toFixed(2));
    setText("[data-radius-delta]", `Δ ${signed(sample.radius - TARGET.radius)}`);
    setText("[data-thickness]", sample.thickness.toFixed(2));
    setText("[data-thickness-delta]", `Δ ${signed(sample.thickness - TARGET.thickness)}`);
    setText("[data-surface]", sample.surface.toFixed(2));
    setText("[data-registration]", sample.registration.toFixed(2));
    setText("[data-review-note]", reviewNote(sample));

    renderRadiusChart();
    drawCornea();
    if (options.scroll) $("#geometry")?.scrollIntoView({ behavior: "smooth", block: "start" });
  }

  $$("[data-inspect-sample]").forEach((button) => {
    button.addEventListener("click", () => setActiveSample(button.dataset.inspectSample, { scroll: true }));
  });

  $$("[data-view-mode]").forEach((button) => {
    button.addEventListener("click", () => {
      activeMode = button.dataset.viewMode;
      $$("[data-view-mode]").forEach((item) => item.classList.toggle("is-active", item === button));
      setText("[data-model-mode]", `${activeMode.toUpperCase()} ${activeMode === "deviation" ? "MAP" : "SURFACE"}`);
      drawCornea();
    });
  });

  $$("[data-agent]").forEach((tab) => {
    tab.addEventListener("click", () => {
      const agent = agents[tab.dataset.agent];
      if (!agent) return;
      $$("[data-agent]").forEach((item) => {
        const selected = item === tab;
        item.classList.toggle("is-active", selected);
        item.setAttribute("aria-selected", String(selected));
      });
      setText("[data-agent-number]", agent.number);
      setText("[data-agent-title]", agent.title);
      setText("[data-agent-input]", agent.input);
      setText("[data-agent-task]", agent.task);
      setText("[data-agent-output]", agent.output);
      setText("[data-agent-stop]", agent.stop);
    });
  });

  $$("[data-paper-stage]").forEach((tab) => {
    tab.addEventListener("click", () => {
      const stage = paperStages[tab.dataset.paperStage];
      if (!stage) return;
      $$("[data-paper-stage]").forEach((item) => {
        const selected = item === tab;
        item.classList.toggle("is-active", selected);
        item.setAttribute("aria-selected", String(selected));
      });
      setText("[data-paper-index]", stage.index);
      setText("[data-paper-title]", stage.title);
      setText("[data-paper-purpose]", stage.purpose);
      setText("[data-paper-ai]", stage.ai);
      setText("[data-paper-output]", stage.output);
      setText("[data-paper-human]", stage.human);
    });
  });

  function median(values) {
    const sorted = [...values].sort((a, b) => a - b);
    const middle = Math.floor(sorted.length / 2);
    return sorted.length % 2 ? sorted[middle] : (sorted[middle - 1] + sorted[middle]) / 2;
  }

  ["pass", "review", "fail"].forEach((state) => {
    setText(`[data-count-${state}]`, String(samples.filter((sample) => sample.status === state).length));
  });
  setText("[data-median-error]", median(samples.map((sample) => Math.abs(sample.radius - TARGET.radius))).toFixed(2));

  const svgNS = "http://www.w3.org/2000/svg";
  function svgElement(name, attributes = {}, text = "") {
    const element = document.createElementNS(svgNS, name);
    Object.entries(attributes).forEach(([key, value]) => element.setAttribute(key, value));
    if (text) element.textContent = text;
    return element;
  }

  function renderRadiusChart() {
    const svg = $("[data-radius-chart]");
    if (!svg) return;
    const width = 760;
    const height = 390;
    const margin = { left: 76, right: 32, top: 24, bottom: 43 };
    const min = 7.45;
    const max = 8.25;
    const innerWidth = width - margin.left - margin.right;
    const rowHeight = (height - margin.top - margin.bottom) / samples.length;
    const x = (value) => margin.left + ((value - min) / (max - min)) * innerWidth;
    const colors = { pass: "#b8ff74", review: "#ffdf68", fail: "#ff715f" };
    svg.innerHTML = "";
    svg.setAttribute("viewBox", `0 0 ${width} ${height}`);

    const toleranceStart = x(TARGET.radius - TARGET.radiusTolerance);
    const toleranceEnd = x(TARGET.radius + TARGET.radiusTolerance);
    svg.append(svgElement("rect", { x: toleranceStart, y: margin.top - 9, width: toleranceEnd - toleranceStart, height: height - margin.top - margin.bottom + 18, fill: "#8ee9df", opacity: ".18" }));

    [7.5, 7.6, 7.7, 7.8, 7.9, 8.0, 8.1, 8.2].forEach((tick) => {
      svg.append(svgElement("line", { x1: x(tick), y1: margin.top - 9, x2: x(tick), y2: height - margin.bottom + 9, stroke: "rgba(13,28,26,.13)", "stroke-width": "1" }));
      svg.append(svgElement("text", { x: x(tick), y: height - 18, "text-anchor": "middle", fill: "rgba(13,28,26,.62)", "font-family": "SFMono-Regular, monospace", "font-size": "10" }, tick.toFixed(1)));
    });

    svg.append(svgElement("line", { x1: x(TARGET.radius), y1: margin.top - 15, x2: x(TARGET.radius), y2: height - margin.bottom + 10, stroke: "#0d1c1a", "stroke-width": "1.5", "stroke-dasharray": "4 4" }));
    svg.append(svgElement("text", { x: x(TARGET.radius) + 6, y: 12, fill: "#0d1c1a", "font-family": "SFMono-Regular, monospace", "font-size": "9" }, "TARGET"));

    samples.forEach((sample, index) => {
      const y = margin.top + rowHeight * index + rowHeight / 2;
      if (index === 4 || index === 8) {
        svg.append(svgElement("line", { x1: 0, y1: y - rowHeight / 2, x2: width, y2: y - rowHeight / 2, stroke: "rgba(13,28,26,.34)", "stroke-width": "1" }));
      }
      svg.append(svgElement("text", { x: margin.left - 13, y: y + 4, "text-anchor": "end", fill: sample.id === activeSample.id ? "#ff715f" : "rgba(13,28,26,.68)", "font-family": "SFMono-Regular, monospace", "font-size": "10", "font-weight": sample.id === activeSample.id ? "700" : "400" }, `${sample.id} · ${sample.batch}`));
      svg.append(svgElement("line", { x1: x(TARGET.radius), y1: y, x2: x(sample.radius), y2: y, stroke: colors[sample.status], "stroke-width": "2", opacity: ".9" }));
      const circle = svgElement("circle", { cx: x(sample.radius), cy: y, r: sample.id === activeSample.id ? 8 : 6, fill: colors[sample.status], stroke: "#0d1c1a", "stroke-width": sample.id === activeSample.id ? "2.5" : "1", tabindex: "0", role: "button", "aria-label": `${sample.id} radius ${sample.radius.toFixed(2)} mm, ${sample.status}` });
      circle.style.cursor = "pointer";
      circle.addEventListener("click", () => setActiveSample(sample.id, { scroll: true }));
      circle.addEventListener("keydown", (event) => {
        if (event.key === "Enter" || event.key === " ") setActiveSample(sample.id, { scroll: true });
      });
      svg.append(circle);
    });
    svg.append(svgElement("text", { x: width - margin.right, y: height - 2, "text-anchor": "end", fill: "rgba(13,28,26,.62)", "font-family": "SFMono-Regular, monospace", "font-size": "9" }, "BEST-FIT RADIUS (mm)"));
  }

  function renderBatchBars() {
    const root = $("[data-batch-bars]");
    if (!root) return;
    root.innerHTML = "";
    ["B01", "B02", "B03"].forEach((batch) => {
      const group = samples.filter((sample) => sample.batch === batch);
      const wrapper = document.createElement("div");
      wrapper.className = "batch-bar";
      const stack = document.createElement("div");
      stack.className = "batch-stack";
      ["pass", "review", "fail"].forEach((state) => {
        const count = group.filter((sample) => sample.status === state).length;
        if (!count) return;
        const segment = document.createElement("i");
        segment.className = state;
        segment.style.height = `${(count / group.length) * 100}%`;
        segment.title = `${state}: ${count}`;
        stack.append(segment);
      });
      const name = document.createElement("strong");
      name.textContent = batch;
      const label = document.createElement("small");
      label.textContent = `${group.filter((sample) => sample.status === "pass").length}/${group.length} pass`;
      wrapper.append(stack, name, label);
      root.append(wrapper);
    });
  }

  const canvas = $("#cornea-canvas");
  const context = canvas?.getContext("2d");
  let azimuth = -0.42;
  let tilt = 0.98;
  let dragging = false;
  let lastPointer = { x: 0, y: 0 };

  function deviationAt(sample, radius, angle) {
    const global = (sample.radius - TARGET.radius) * (0.18 + radius * 0.45);
    const ripple = Math.sin(angle * 3 + sample.id.charCodeAt(2)) * sample.surface * 0.38 * radius;
    const local = Math.cos(angle * 5 - 0.8) * sample.registration * 0.24 * radius * radius;
    return global + ripple + local;
  }

  function surfacePoint(sample, radius, angle, measured) {
    const x = radius * Math.cos(angle);
    const y = radius * Math.sin(angle);
    const idealZ = 0.82 * (1 - radius * radius * 0.72);
    const deviation = deviationAt(sample, radius, angle);
    return { x, y, z: idealZ + (measured ? deviation * 1.8 : 0), deviation };
  }

  function project(point, width, height) {
    const cosA = Math.cos(azimuth);
    const sinA = Math.sin(azimuth);
    const x1 = point.x * cosA - point.y * sinA;
    const y1 = point.x * sinA + point.y * cosA;
    const cosT = Math.cos(tilt);
    const sinT = Math.sin(tilt);
    const y2 = y1 * cosT - point.z * sinT;
    const depth = y1 * sinT + point.z * cosT;
    const perspective = 1 / (1.12 - depth * 0.16);
    const scale = Math.min(width, height) * 0.39;
    return {
      x: width * 0.5 + x1 * scale * perspective,
      y: height * 0.53 + y2 * scale * perspective,
      depth,
      deviation: point.deviation
    };
  }

  function deviationColor(value, alpha = .76) {
    const bounded = Math.max(-0.3, Math.min(0.3, value));
    if (bounded < -0.12) return `rgba(122,167,255,${alpha})`;
    if (bounded < -0.035) return `rgba(142,233,223,${alpha})`;
    if (bounded < 0.05) return `rgba(184,255,116,${alpha})`;
    if (bounded < 0.15) return `rgba(255,223,104,${alpha})`;
    return `rgba(255,113,95,${alpha})`;
  }

  function drawSurface(sample, measured, mode) {
    if (!canvas || !context) return;
    const width = canvas.clientWidth;
    const height = canvas.clientHeight;
    const rings = 12;
    const segments = 44;
    const cells = [];

    for (let ring = 0; ring < rings; ring += 1) {
      const r1 = ring / rings;
      const r2 = (ring + 1) / rings;
      for (let segment = 0; segment < segments; segment += 1) {
        const a1 = (segment / segments) * Math.PI * 2;
        const a2 = ((segment + 1) / segments) * Math.PI * 2;
        const points = [
          project(surfacePoint(sample, r1, a1, measured), width, height),
          project(surfacePoint(sample, r2, a1, measured), width, height),
          project(surfacePoint(sample, r2, a2, measured), width, height),
          project(surfacePoint(sample, r1, a2, measured), width, height)
        ];
        cells.push({
          points,
          depth: points.reduce((sum, point) => sum + point.depth, 0) / points.length,
          deviation: points.reduce((sum, point) => sum + point.deviation, 0) / points.length
        });
      }
    }

    cells.sort((a, b) => a.depth - b.depth);
    cells.forEach((cell) => {
      context.beginPath();
      context.moveTo(cell.points[0].x, cell.points[0].y);
      cell.points.slice(1).forEach((point) => context.lineTo(point.x, point.y));
      context.closePath();
      if (mode === "deviation") {
        context.fillStyle = deviationColor(cell.deviation, .7);
        context.strokeStyle = deviationColor(cell.deviation, .28);
      } else if (measured) {
        context.fillStyle = "rgba(255,113,95,.08)";
        context.strokeStyle = "rgba(255,113,95,.42)";
      } else {
        context.fillStyle = "rgba(142,233,223,.055)";
        context.strokeStyle = "rgba(142,233,223,.42)";
      }
      context.lineWidth = .75;
      context.fill();
      context.stroke();
    });
  }

  function drawCornea() {
    if (!canvas || !context) return;
    const rect = canvas.getBoundingClientRect();
    if (!rect.width || !rect.height) return;
    const dpr = Math.min(window.devicePixelRatio || 1, 2);
    const displayWidth = Math.round(rect.width * dpr);
    const displayHeight = Math.round(rect.height * dpr);
    if (canvas.width !== displayWidth || canvas.height !== displayHeight) {
      canvas.width = displayWidth;
      canvas.height = displayHeight;
    }
    context.setTransform(dpr, 0, 0, dpr, 0, 0);
    context.clearRect(0, 0, rect.width, rect.height);

    context.save();
    context.globalCompositeOperation = "source-over";
    if (activeMode === "ideal") drawSurface(activeSample, false, "ideal");
    if (activeMode === "measured") drawSurface(activeSample, true, "measured");
    if (activeMode === "deviation") drawSurface(activeSample, true, "deviation");
    context.restore();

    context.fillStyle = "rgba(255,255,255,.38)";
    context.font = "10px SFMono-Regular, monospace";
    context.fillText(`${activeSample.id} / ${activeSample.batch} / METHOD v0.3`, 92, 42);
  }

  if (canvas) {
    canvas.addEventListener("pointerdown", (event) => {
      dragging = true;
      lastPointer = { x: event.clientX, y: event.clientY };
      canvas.setPointerCapture(event.pointerId);
    });
    canvas.addEventListener("pointermove", (event) => {
      if (!dragging) return;
      const dx = event.clientX - lastPointer.x;
      const dy = event.clientY - lastPointer.y;
      azimuth += dx * 0.008;
      tilt = Math.max(0.28, Math.min(1.42, tilt + dy * 0.006));
      lastPointer = { x: event.clientX, y: event.clientY };
      drawCornea();
    });
    canvas.addEventListener("pointerup", () => { dragging = false; });
    canvas.addEventListener("pointercancel", () => { dragging = false; });
    if ("ResizeObserver" in window) new ResizeObserver(drawCornea).observe(canvas);
    else window.addEventListener("resize", drawCornea);
  }

  const menuButton = $("[data-menu]");
  const nav = $(".portfolio-nav");
  menuButton?.addEventListener("click", () => {
    const open = menuButton.getAttribute("aria-expanded") === "true";
    menuButton.setAttribute("aria-expanded", String(!open));
    nav?.classList.toggle("is-open", !open);
  });
  $$(".portfolio-nav a").forEach((link) => link.addEventListener("click", () => {
    menuButton?.setAttribute("aria-expanded", "false");
    nav?.classList.remove("is-open");
  }));

  $("[data-print-portfolio]")?.addEventListener("click", () => window.print());

  const navLinks = $$(".portfolio-nav a");
  if ("IntersectionObserver" in window && navLinks.length) {
    const observer = new IntersectionObserver((entries) => {
      const visible = entries.filter((entry) => entry.isIntersecting).sort((a, b) => b.intersectionRatio - a.intersectionRatio)[0];
      if (!visible) return;
      navLinks.forEach((link) => link.toggleAttribute("aria-current", link.hash === `#${visible.target.id}`));
    }, { rootMargin: "-18% 0px -68%", threshold: [0, .15, .45] });
    navLinks.map((link) => $(link.hash)).filter(Boolean).forEach((section) => observer.observe(section));
  }

  renderBatchBars();
  setActiveSample(samples[0].id);
})();
