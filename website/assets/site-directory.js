(() => {
  "use strict";

  if (document.querySelector("[data-big-directory]")) return;

  const groups = [
    {
      label: "入口",
      pages: [
        { id: "00", file: "index.html", title: "Papers & Evidence", detail: "論文レビュー・研究者別エビデンス索引" },
        { id: "WS", file: "workspace.html", title: "Research Workspace", detail: "タスク・ノート・週間計画" }
      ]
    },
    {
      label: "研究を知る",
      pages: [
        { id: "01", file: "intern-overview.html", title: "BiG Labとは何か", detail: "研究領域とWet / Dry lab" },
        { id: "02", file: "photopolymer-biomaterials-review.html", title: "光重合性バイオマテリアル", detail: "指定4論文の統合レビュー" },
        { id: "03", file: "microneedle-small-data-ml-review.html", title: "Microneedle × Small-data ML", detail: "共有5文献と次の研究設計" },
        { id: "04", file: "intern-yunong-yuan.html", title: "Yunong Yuan氏の研究", detail: "研究の発展と公開成果" }
      ]
    },
    {
      label: "参加を準備する",
      pages: [
        { id: "05", file: "intern-contribution-map.html", title: "最初の役割とpilot", detail: "貢献候補の要点版" },
        { id: "06", file: "role-fit-atlas.html", title: "BIG Role Fit Atlas", detail: "18の仕事・適合度・参加経路" },
        { id: "07", file: "intern-meeting.html", title: "研究面談の準備", detail: "質問・英語スクリプト・実行順" },
        { id: "08", file: "intern-contribution-strategy.html", title: "研究貢献戦略", detail: "評価・実装案を含む詳細版" },
        { id: "09", file: "intern-roadmap.html", title: "12週間ロードマップ", detail: "学習・実装・発表の順序" }
      ]
    },
    {
      label: "AIを研究で使う",
      pages: [
        { id: "10", file: "claude-code.html", title: "Claude Code", detail: "再現可能な実装を支える" },
        { id: "11", file: "claude-science-overview.html", title: "Claude Science概要", detail: "役割と読むページを選ぶ" },
        { id: "12", file: "getting-started.html", title: "導入する", detail: "要件・権限・最初の解析" },
        { id: "13", file: "workflow.html", title: "研究を進める", detail: "問い・計画・証拠をつなぐ" },
        { id: "14", file: "claude-science-big-lab.html", title: "BiG Labで試す", detail: "Geometry QCの4週間pilot" },
        { id: "15", file: "safety.html", title: "安全に使う", detail: "データ分類・権限・人間レビュー" }
      ]
    },
    {
      label: "成果を見る",
      pages: [
        { id: "16", file: "research-superpowers.html", title: "5 Research Superpowers", detail: "5つの強みを研究成果へ" },
        { id: "17", file: "research-portfolio.html", title: "Research Portfolio", detail: "Geometry QCの実働ケース" },
        { id: "18", file: "geometry-qc-poster.html", title: "Geometry QC Poster", detail: "印刷可能な合成データ例" }
      ]
    }
  ];

  const pages = groups.flatMap((group) => group.pages);
  const currentFile = decodeURIComponent(location.pathname.split("/").pop() || "index.html");
  const currentIndex = Math.max(0, pages.findIndex((page) => page.file.split("#")[0] === currentFile));
  const currentPage = pages[currentIndex] || pages[0];
  const previousPage = pages[currentIndex - 1];
  const nextPage = pages[currentIndex + 1];

  const escapeHtml = (value) => value.replace(/[&<>"']/g, (character) => ({
    "&": "&amp;",
    "<": "&lt;",
    ">": "&gt;",
    '"': "&quot;",
    "'": "&#039;"
  })[character]);

  const groupMarkup = groups.map((group) => `
    <section class="big-directory-group" aria-labelledby="big-directory-${escapeHtml(group.label)}">
      <h2 id="big-directory-${escapeHtml(group.label)}">${escapeHtml(group.label)}</h2>
      <ol class="big-directory-list">
        ${group.pages.map((page) => {
          const isCurrent = page.file.split("#")[0] === currentFile;
          return `
            <li>
              <a href="${page.file}"${isCurrent ? ' aria-current="page"' : ""}>
                <span class="big-directory-index">${page.id}</span>
                <span class="big-directory-copy">
                  <strong>${escapeHtml(page.title)}</strong>
                  <small>${escapeHtml(page.detail)}</small>
                </span>
                <span class="big-directory-arrow" aria-hidden="true">${isCurrent ? "●" : "→"}</span>
              </a>
            </li>`;
        }).join("")}
      </ol>
    </section>
  `).join("");

  const adjacentLink = (page, direction) => page
    ? `<a href="${page.file}"><span>${direction === "previous" ? "← 前の資料" : "次の資料 →"}</span><strong>${escapeHtml(page.title)}</strong></a>`
    : "<span aria-hidden=\"true\"></span>";

  const launcher = document.createElement("button");
  launcher.type = "button";
  launcher.className = "big-directory-launcher";
  launcher.dataset.bigDirectory = "launcher";
  launcher.setAttribute("aria-controls", "big-directory-dialog");
  launcher.setAttribute("aria-expanded", "false");
  launcher.innerHTML = `
    <svg viewBox="0 0 20 20" aria-hidden="true">
      <path d="M3 4.25h14M3 10h14M3 15.75h14"/>
    </svg>
    <span>全資料</span>
    <span class="big-directory-count">${pages.length}</span>`;

  const shell = document.createElement("div");
  shell.id = "big-directory-dialog";
  shell.className = "big-directory-shell";
  shell.dataset.bigDirectory = "dialog";
  shell.hidden = true;
  shell.innerHTML = `
    <div class="big-directory-backdrop" data-big-directory-close></div>
    <aside class="big-directory-panel" role="dialog" aria-modal="true" aria-labelledby="big-directory-title">
      <header class="big-directory-head">
        <p class="big-directory-title">
          <strong id="big-directory-title">BiG Lab 全資料</strong>
          <small>${currentPage.id} / ${escapeHtml(currentPage.title)}</small>
        </p>
        <button class="big-directory-close" type="button" aria-label="資料メニューを閉じる" data-big-directory-close>×</button>
      </header>
      <nav class="big-directory-scroll" aria-label="全HTMLページ">
        ${groupMarkup}
      </nav>
      <footer class="big-directory-foot">
        ${adjacentLink(previousPage, "previous")}
        <span class="big-directory-position">${currentIndex + 1} / ${pages.length}</span>
        ${adjacentLink(nextPage, "next")}
      </footer>
    </aside>`;

  document.body.append(launcher, shell);

  const closeButton = shell.querySelector(".big-directory-close");
  let returnFocus = launcher;

  const focusableElements = () => Array.from(shell.querySelectorAll("a[href], button:not([disabled])"))
    .filter((element) => !element.hidden && element.getClientRects().length);

  const openDirectory = () => {
    returnFocus = document.activeElement instanceof HTMLElement ? document.activeElement : launcher;
    shell.hidden = false;
    launcher.setAttribute("aria-expanded", "true");
    document.body.classList.add("big-directory-open");
    closeButton.focus();
  };

  const closeDirectory = () => {
    shell.hidden = true;
    launcher.setAttribute("aria-expanded", "false");
    document.body.classList.remove("big-directory-open");
    returnFocus.focus();
  };

  launcher.addEventListener("click", () => {
    if (shell.hidden) openDirectory();
    else closeDirectory();
  });

  shell.addEventListener("click", (event) => {
    if (event.target.closest("[data-big-directory-close]")) closeDirectory();
  });

  document.addEventListener("keydown", (event) => {
    if (shell.hidden) return;

    if (event.key === "Escape") {
      event.preventDefault();
      closeDirectory();
      return;
    }

    if (event.key !== "Tab") return;
    const focusable = focusableElements();
    if (!focusable.length) return;
    const first = focusable[0];
    const last = focusable[focusable.length - 1];

    if (event.shiftKey && document.activeElement === first) {
      event.preventDefault();
      last.focus();
    } else if (!event.shiftKey && document.activeElement === last) {
      event.preventDefault();
      first.focus();
    }
  });
})();
