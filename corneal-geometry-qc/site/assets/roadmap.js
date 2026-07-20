(() => {
  "use strict";

  const STORAGE_KEY = "bigLabCornealGeometryRoadmap:v1";
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
      const parsed = JSON.parse(window.localStorage.getItem(STORAGE_KEY) || "{}");
      return parsed && typeof parsed === "object" && !Array.isArray(parsed) ? parsed : {};
    } catch {
      return {};
    }
  };

  const writeState = (state) => {
    try {
      window.localStorage.setItem(STORAGE_KEY, JSON.stringify(state));
      return true;
    } catch {
      return false;
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
      widget.max = total;
      widget.value = completed;
      widget.setAttribute("aria-valuenow", String(completed));
      widget.setAttribute("aria-valuetext", `${completed}/${total}、${percentage}%完了`);
      widget.textContent = `${completed}/${total}`;
    });
  };

  const state = readState();

  checkboxes.forEach((checkbox) => {
    if (checkbox.id && state[checkbox.id] === true) {
      checkbox.checked = true;
    }

    checkbox.addEventListener("change", () => {
      if (checkbox.id) {
        state[checkbox.id] = checkbox.checked;
      }

      const saved = writeState(state);
      updateProgress();
      announce(
        saved
          ? checkbox.checked
            ? `${checkbox.dataset.label || "タスク"}を完了にしました。`
            : `${checkbox.dataset.label || "タスク"}を未完了に戻しました。`
          : `${checkbox.dataset.label || "タスク"}の表示を更新しましたが、このブラウザでは進捗を保存できません。`
      );
    });
  });

  updateProgress();

  const scrollableTables = Array.from(document.querySelectorAll("[data-scrollable-table]"));
  const scrollableFigures = Array.from(document.querySelectorAll("[data-scrollable-figure]"));

  const updateScrollableTables = () => {
    scrollableTables.forEach((wrapper) => {
      const isScrollable = wrapper.scrollWidth > wrapper.clientWidth + 2;
      wrapper.classList.toggle("is-scrollable", isScrollable);
      wrapper.dataset.scrollHint = isScrollable
        ? "左右にスクロールして表全体を確認できます"
        : "";
    });
  };

  const updateScrollableFigures = () => {
    scrollableFigures.forEach((figure) => {
      const isScrollable = figure.scrollWidth > figure.clientWidth + 2;
      figure.classList.toggle("is-scrollable", isScrollable);

      if (isScrollable) {
        figure.setAttribute("tabindex", "0");
        figure.setAttribute("aria-keyshortcuts", "ArrowLeft ArrowRight");
      } else {
        figure.removeAttribute("tabindex");
        figure.removeAttribute("aria-keyshortcuts");
      }
    });
  };

  const updateScrollableContent = () => {
    updateScrollableTables();
    updateScrollableFigures();
  };

  scrollableTables.forEach((wrapper, index) => {
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

  window.addEventListener("resize", updateScrollableContent);
  window.addEventListener("load", updateScrollableContent);
  window.requestAnimationFrame(updateScrollableContent);

  const resetButton = document.querySelector("[data-reset-progress]");

  if (resetButton) {
    resetButton.addEventListener("click", () => {
      const shouldReset = window.confirm("このページに保存された進捗をすべてリセットしますか？");
      if (!shouldReset) return;

      checkboxes.forEach((checkbox) => {
        checkbox.checked = false;
        if (checkbox.id) state[checkbox.id] = false;
      });

      const saved = writeState(state);
      updateProgress();
      announce(
        saved
          ? "進捗をリセットしました。"
          : "進捗の表示をリセットしましたが、このブラウザでは変更を保存できません。"
      );
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
      updateScrollableContent();
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
    textarea.style.pointerEvents = "none";
    document.body.appendChild(textarea);
    textarea.select();
    const copied = document.execCommand("copy");
    textarea.remove();

    if (!copied) {
      throw new Error("copy command failed");
    }
  };

  const copyButton = document.querySelector("[data-copy-prompt]");
  const prompt = document.querySelector("[data-prompt-source]");

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
    const setNavOpen = (open, moveFocus = false) => {
      navToggle.setAttribute("aria-expanded", String(open));
      navToggle.setAttribute(
        "aria-label",
        open ? "ナビゲーションを閉じる" : "ナビゲーションを開く"
      );
      nav.dataset.open = String(open);

      if (open && moveFocus) {
        window.requestAnimationFrame(() => {
          nav.querySelector("[data-nav-link]")?.focus();
        });
      }
    };

    navToggle.addEventListener("click", (event) => {
      const open = navToggle.getAttribute("aria-expanded") === "true";
      setNavOpen(!open, event.detail === 0);
    });

    nav.addEventListener("click", (event) => {
      const link = event.target.closest("[data-nav-link]");
      if (!link) return;

      setNavOpen(false);
    });

    nav.addEventListener("keydown", (event) => {
      if (event.key !== "Escape") return;

      event.preventDefault();
      setNavOpen(false);
      navToggle.focus();
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
      { rootMargin: "-20% 0px -65% 0px", threshold: [0, 0.05, 0.2, 0.5] }
    );

    sections.forEach((section) => observer.observe(section));
  }
})();
