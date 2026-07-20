(() => {
  "use strict";

  const STORAGE_KEY = "bigLabDrugReleaseRoadmap:v1";
  const checkboxes = Array.from(document.querySelectorAll("[data-roadmap-check]"));
  const progressLabels = Array.from(document.querySelectorAll("[data-progress-label]"));
  const progressWidgets = Array.from(document.querySelectorAll("[data-progress-widget]"));
  const statusRegion = document.querySelector("[data-status]");

  const announce = (message) => {
    if (!statusRegion) return;
    statusRegion.textContent = "";
    window.setTimeout(() => {
      statusRegion.textContent = message;
    }, 30);
  };

  const readState = () => {
    try {
      return JSON.parse(window.localStorage.getItem(STORAGE_KEY) || "{}");
    } catch {
      return {};
    }
  };

  const writeState = (state) => {
    try {
      window.localStorage.setItem(STORAGE_KEY, JSON.stringify(state));
    } catch {
      announce("このブラウザでは進捗を保存できません。");
    }
  };

  const updateProgress = () => {
    const completed = checkboxes.filter((checkbox) => checkbox.checked).length;
    const total = checkboxes.length;
    const percentage = total ? Math.round((completed / total) * 100) : 0;

    progressLabels.forEach((label) => {
      label.textContent = `${completed}/${total} · ${percentage}%`;
    });

    progressWidgets.forEach((widget) => {
      widget.value = completed;
      widget.setAttribute("aria-valuenow", String(completed));
      widget.setAttribute("aria-valuetext", `${completed}/${total}、${percentage}%完了`);
      widget.textContent = `${completed}/${total}`;
    });
  };

  const state = readState();

  checkboxes.forEach((checkbox) => {
    if (state[checkbox.id] === true) {
      checkbox.checked = true;
    }

    checkbox.addEventListener("change", () => {
      state[checkbox.id] = checkbox.checked;
      writeState(state);
      updateProgress();
      announce(
        checkbox.checked
          ? `${checkbox.dataset.label || "タスク"}を完了にしました。`
          : `${checkbox.dataset.label || "タスク"}を未完了に戻しました。`
      );
    });
  });

  updateProgress();

  const tableWraps = Array.from(document.querySelectorAll(".table-wrap"));

  const updateScrollableTables = () => {
    tableWraps.forEach((wrapper) => {
      const isScrollable = wrapper.scrollWidth > wrapper.clientWidth + 2;
      wrapper.classList.toggle("is-scrollable", isScrollable);
      wrapper.dataset.scrollHint = isScrollable
        ? "左右にスクロールして表全体を確認できます"
        : "";
    });
  };

  tableWraps.forEach((wrapper, index) => {
    const caption = wrapper.querySelector("caption");
    wrapper.setAttribute("role", "region");
    wrapper.setAttribute("tabindex", "0");
    wrapper.setAttribute(
      "aria-label",
      caption
        ? `${caption.textContent.trim()}（横スクロール可能）`
        : `データ表 ${index + 1}（横スクロール可能）`
    );
  });

  window.addEventListener("resize", updateScrollableTables);
  window.addEventListener("load", updateScrollableTables);
  window.requestAnimationFrame(updateScrollableTables);

  const resetButton = document.querySelector("[data-reset-progress]");
  if (resetButton) {
    resetButton.addEventListener("click", () => {
      const shouldReset = window.confirm("このページに保存された進捗をすべてリセットしますか？");
      if (!shouldReset) return;

      checkboxes.forEach((checkbox) => {
        checkbox.checked = false;
        state[checkbox.id] = false;
      });
      writeState(state);
      updateProgress();
      announce("進捗をリセットしました。");
    });
  }

  const filterButtons = Array.from(document.querySelectorAll("[data-phase-filter]"));
  const filterTargets = Array.from(document.querySelectorAll("[data-phase]"));

  filterButtons.forEach((button) => {
    button.addEventListener("click", () => {
      const selected = button.dataset.phaseFilter;

      filterButtons.forEach((item) => {
        item.setAttribute("aria-pressed", item === button ? "true" : "false");
      });

      filterTargets.forEach((target) => {
        target.hidden = selected !== "all" && target.dataset.phase !== selected;
      });

      announce(`${button.textContent.trim()}のphaseを表示しています。`);
    });
  });

  const copyText = async (text) => {
    if (navigator.clipboard && window.isSecureContext) {
      await navigator.clipboard.writeText(text);
      return;
    }

    const textarea = document.createElement("textarea");
    textarea.value = text;
    textarea.setAttribute("readonly", "");
    textarea.style.position = "fixed";
    textarea.style.opacity = "0";
    document.body.appendChild(textarea);
    textarea.select();
    const copied = document.execCommand("copy");
    textarea.remove();

    if (!copied) {
      throw new Error("copy command failed");
    }
  };

  const copyButton = document.querySelector("[data-copy-prompt]");
  const prompt = document.querySelector("#implementation-prompt");

  if (copyButton && prompt) {
    copyButton.addEventListener("click", async () => {
      const original = copyButton.textContent;
      try {
        await copyText(prompt.textContent.trim());
        copyButton.textContent = "コピーしました";
        announce("実行用指示文をclipboardへコピーしました。");
      } catch {
        copyButton.textContent = "選択してコピー";
        prompt.focus();
        const selection = window.getSelection();
        const range = document.createRange();
        range.selectNodeContents(prompt);
        selection.removeAllRanges();
        selection.addRange(range);
        announce("自動コピーできなかったため、指示文を選択しました。");
      }

      window.setTimeout(() => {
        copyButton.textContent = original;
      }, 1800);
    });
  }

  const printButton = document.querySelector("[data-print-page]");
  if (printButton) {
    printButton.addEventListener("click", () => window.print());
  }

  const progressBar = document.querySelector("[data-reading-progress]");
  const updateReadingProgress = () => {
    if (!progressBar) return;
    const scrollable = document.documentElement.scrollHeight - window.innerHeight;
    const percentage = scrollable > 0 ? (window.scrollY / scrollable) * 100 : 0;
    progressBar.style.width = `${Math.min(100, Math.max(0, percentage))}%`;
  };

  window.addEventListener("scroll", updateReadingProgress, { passive: true });
  window.addEventListener("resize", updateReadingProgress);
  updateReadingProgress();

  const navToggle = document.querySelector("[data-nav-toggle]");
  const nav = document.querySelector("[data-primary-nav]");

  if (navToggle && nav) {
    navToggle.addEventListener("click", () => {
      const open = navToggle.getAttribute("aria-expanded") === "true";
      navToggle.setAttribute("aria-expanded", String(!open));
      nav.dataset.open = String(!open);
    });

    nav.addEventListener("click", (event) => {
      if (!event.target.closest("a")) return;
      navToggle.setAttribute("aria-expanded", "false");
      nav.dataset.open = "false";
    });
  }

  const navLinks = Array.from(document.querySelectorAll("[data-nav-link]"));
  const sections = navLinks
    .map((link) => document.querySelector(link.getAttribute("href")))
    .filter(Boolean);

  if ("IntersectionObserver" in window && navLinks.length && sections.length) {
    const observer = new IntersectionObserver(
      (entries) => {
        const visible = entries
          .filter((entry) => entry.isIntersecting)
          .sort((a, b) => b.intersectionRatio - a.intersectionRatio)[0];

        if (!visible) return;

        navLinks.forEach((link) => {
          const active = link.getAttribute("href") === `#${visible.target.id}`;
          if (active) {
            link.setAttribute("aria-current", "true");
          } else {
            link.removeAttribute("aria-current");
          }
        });
      },
      { rootMargin: "-20% 0px -65% 0px", threshold: [0.05, 0.2, 0.5] }
    );

    sections.forEach((section) => observer.observe(section));
  }
})();
