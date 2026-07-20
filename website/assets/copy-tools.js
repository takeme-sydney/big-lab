(function () {
  "use strict";

  if (window.BIG_LAB_COPY_TOOLS_LOADED) return;
  window.BIG_LAB_COPY_TOOLS_LOADED = true;

  var RESET_DELAY = 1600;
  var labels = {
    ja: {
      page: "本文をコピー",
      pageCopied: "本文をコピーしました",
      block: "コピー",
      table: "表をコピー",
      quote: "引用をコピー",
      copied: "コピー済み",
      failed: "コピー失敗",
      statusSuccess: "クリップボードへコピーしました",
      statusFailed: "コピーできませんでした。テキストを選択してコピーしてください"
    },
    en: {
      page: "Copy page",
      pageCopied: "Page copied",
      block: "Copy",
      table: "Copy table",
      quote: "Copy quote",
      copied: "Copied",
      failed: "Copy failed",
      statusSuccess: "Copied to clipboard",
      statusFailed: "Copy failed. Select the text and copy it manually"
    }
  };

  var pageButton;
  var status;

  function language() {
    return document.documentElement.lang === "en" ? "en" : "ja";
  }

  function text(key) {
    return labels[language()][key];
  }

  function normalize(value) {
    return value
      .replace(/\u00a0/g, " ")
      .replace(/[ \t]+\n/g, "\n")
      .replace(/\n[ \t]+/g, "\n")
      .replace(/\n{3,}/g, "\n\n")
      .trim();
  }

  function fallbackCopy(value) {
    return new Promise(function (resolve, reject) {
      var area = document.createElement("textarea");
      area.value = value;
      area.setAttribute("readonly", "");
      area.setAttribute("aria-hidden", "true");
      area.style.position = "fixed";
      area.style.top = "0";
      area.style.left = "-100000px";
      area.style.opacity = "0";
      document.body.appendChild(area);
      area.focus({ preventScroll: true });
      area.select();
      area.setSelectionRange(0, area.value.length);

      var copied = false;
      try {
        copied = document.execCommand("copy");
      } catch (error) {
        copied = false;
      }
      area.remove();

      if (copied) resolve();
      else reject(new Error("Clipboard copy was rejected"));
    });
  }

  function writeClipboard(value) {
    if (navigator.clipboard && window.isSecureContext) {
      return navigator.clipboard.writeText(value).catch(function () {
        return fallbackCopy(value);
      });
    }
    return fallbackCopy(value);
  }

  function setButtonState(button, state, idleLabel) {
    var activeLabel = state === "success" ? text("copied") : text("failed");
    button.dataset.copyState = state;
    button.textContent = activeLabel;
    button.setAttribute("aria-label", activeLabel);
    window.setTimeout(function () {
      delete button.dataset.copyState;
      button.textContent = idleLabel();
      button.setAttribute("aria-label", idleLabel());
    }, RESET_DELAY);
  }

  function announce(message) {
    if (status) status.textContent = "";
    window.setTimeout(function () {
      if (status) status.textContent = message;
    }, 20);
  }

  function copy(value, button, idleLabel) {
    var cleanValue = normalize(value);
    if (!cleanValue) {
      setButtonState(button, "error", idleLabel);
      announce(text("statusFailed"));
      return;
    }

    writeClipboard(cleanValue).then(function () {
      setButtonState(button, "success", idleLabel);
      announce(text("statusSuccess"));
    }).catch(function () {
      setButtonState(button, "error", idleLabel);
      announce(text("statusFailed"));
    });
  }

  function prepareClone(root) {
    var clone = root.cloneNode(true);
    clone.classList.add("copy-tools-offscreen");
    clone.setAttribute("aria-hidden", "true");

    clone.querySelectorAll(
      ".copy-tools, .copy-block-actions, .copy-button, " +
      ".language-switcher, script, style, noscript"
    ).forEach(function (element) {
      element.remove();
    });

    clone.querySelectorAll("[hidden]").forEach(function (element) {
      element.removeAttribute("hidden");
    });
    clone.querySelectorAll("details").forEach(function (details) {
      details.open = true;
    });
    clone.querySelectorAll("img[alt]").forEach(function (image) {
      if (!image.alt.trim()) {
        image.remove();
        return;
      }
      var description = document.createElement("p");
      description.textContent = image.alt;
      image.replaceWith(description);
    });

    return clone;
  }

  function pageText() {
    var root = document.querySelector("main") ||
      document.querySelector('[role="main"]') ||
      document.querySelector("article") ||
      document.body;
    var clone = prepareClone(root);
    document.body.appendChild(clone);
    var value = clone.innerText || clone.textContent || "";
    clone.remove();
    return value;
  }

  function tableText(table) {
    return Array.prototype.map.call(table.rows, function (row) {
      return Array.prototype.map.call(row.cells, function (cell) {
        return normalize(cell.innerText || cell.textContent || "").replace(/\n+/g, " ");
      }).join("\t");
    }).join("\n");
  }

  function blockText(block) {
    var clone = block.cloneNode(true);
    clone.querySelectorAll(".copy-button, .copy-block-actions").forEach(function (element) {
      element.remove();
    });
    return clone.innerText || clone.textContent || "";
  }

  function addBlockButton(block, type) {
    if (block.dataset.copyToolsEnhanced === "true") return;
    if (block.closest("[data-copy]")) return;
    block.dataset.copyToolsEnhanced = "true";

    var actions = document.createElement("div");
    actions.className = "copy-block-actions";
    actions.dataset.noTranslate = "";

    var button = document.createElement("button");
    button.className = "copy-block-button";
    button.type = "button";

    function idleLabel() {
      if (type === "table") return text("table");
      if (type === "quote") return text("quote");
      return text("block");
    }

    button.textContent = idleLabel();
    button.setAttribute("aria-label", idleLabel());
    button.addEventListener("click", function () {
      copy(type === "table" ? tableText(block) : blockText(block), button, idleLabel);
    });

    actions.appendChild(button);
    var hasManagedWrapper = block.parentElement && (
      type === "table" && block.parentElement.classList.contains("table-scroll") ||
      type === "block" && block.parentElement.classList.contains("sourceCode")
    );
    var visualTarget = hasManagedWrapper
      ? block.parentElement
      : block;
    visualTarget.parentNode.insertBefore(actions, visualTarget);
  }

  function addBlockButtons() {
    document.querySelectorAll("main pre").forEach(function (block) {
      addBlockButton(block, "block");
    });
    document.querySelectorAll("main table").forEach(function (block) {
      addBlockButton(block, "table");
    });
    document.querySelectorAll("main blockquote").forEach(function (block) {
      addBlockButton(block, "quote");
    });
  }

  function createStatus() {
    status = document.getElementById("copy-status") ||
      document.querySelector("[data-status]");
    if (status) return;

    status = document.createElement("span");
    status.className = "copy-tools-status sr-only";
    status.setAttribute("role", "status");
    status.setAttribute("aria-live", "polite");
    status.dataset.copyToolsStatus = "";
    document.body.appendChild(status);
  }

  function pageIdleLabel() {
    return text("page");
  }

  function createPageButton() {
    var tools = document.createElement("div");
    tools.className = "copy-tools";
    tools.dataset.noTranslate = "";

    pageButton = document.createElement("button");
    pageButton.className = "copy-page-button";
    pageButton.type = "button";
    pageButton.setAttribute("aria-label", pageIdleLabel());
    pageButton.innerHTML =
      '<svg viewBox="0 0 24 24" aria-hidden="true">' +
      '<rect x="8" y="8" width="11" height="11" rx="2"></rect>' +
      '<path d="M16 8V6a2 2 0 0 0-2-2H6a2 2 0 0 0-2 2v8a2 2 0 0 0 2 2h2"></path>' +
      '</svg><span>' + pageIdleLabel() + "</span>";

    pageButton.addEventListener("click", function () {
      var span = pageButton.querySelector("span");
      var value = pageText();
      writeClipboard(normalize(value)).then(function () {
        pageButton.dataset.copyState = "success";
        span.textContent = text("pageCopied");
        pageButton.setAttribute("aria-label", text("pageCopied"));
        announce(text("statusSuccess"));
        window.setTimeout(function () {
          delete pageButton.dataset.copyState;
          span.textContent = pageIdleLabel();
          pageButton.setAttribute("aria-label", pageIdleLabel());
        }, RESET_DELAY);
      }).catch(function () {
        pageButton.dataset.copyState = "error";
        span.textContent = text("failed");
        pageButton.setAttribute("aria-label", text("failed"));
        announce(text("statusFailed"));
        window.setTimeout(function () {
          delete pageButton.dataset.copyState;
          span.textContent = pageIdleLabel();
          pageButton.setAttribute("aria-label", pageIdleLabel());
        }, RESET_DELAY);
      });
    });

    tools.appendChild(pageButton);
    document.body.appendChild(tools);
  }

  function refreshLabels() {
    if (pageButton && !pageButton.dataset.copyState) {
      pageButton.querySelector("span").textContent = pageIdleLabel();
      pageButton.setAttribute("aria-label", pageIdleLabel());
    }
    document.querySelectorAll(".copy-block-button:not([data-copy-state])").forEach(function (button) {
      var block = button.parentElement.nextElementSibling;
      var label = block && (block.matches("table") || block.querySelector("table"))
        ? text("table")
        : block && (block.matches("blockquote") || block.querySelector("blockquote"))
          ? text("quote")
          : text("block");
      button.textContent = label;
      button.setAttribute("aria-label", label);
    });
  }

  createStatus();
  addBlockButtons();
  createPageButton();
  window.addEventListener("biglab:languagechange", refreshLabels);
})();
