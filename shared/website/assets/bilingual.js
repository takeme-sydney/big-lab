(function () {
  "use strict";

  var STORAGE_KEY = "big-lab-language";
  var JAPANESE = /[\u3040-\u30ff\u3400-\u9fff々〆ヵヶ]/;
  var ATTRIBUTE_NAMES = ["alt", "aria-label", "content", "placeholder", "title"];
  var pageName = decodeURIComponent(window.location.pathname.split("/").pop() || "index.html");
  var translations = (window.BIG_LAB_ENGLISH && window.BIG_LAB_ENGLISH[pageName]) || {};
  var entries = [];
  var controls;
  var status;

  function splitWhitespace(value) {
    var match = value.match(/^(\s*)([\s\S]*?)(\s*)$/);
    return match || [value, "", value, ""];
  }

  function registerTextNodes() {
    var walker = document.createTreeWalker(document.documentElement, NodeFilter.SHOW_TEXT, {
      acceptNode: function (node) {
        var parent = node.parentElement;
        if (!parent || parent.closest("script, style, noscript, [data-no-translate]")) {
          return NodeFilter.FILTER_REJECT;
        }
        var source = node.nodeValue.trim();
        if (!source || !JAPANESE.test(source) || !translations[source]) {
          return NodeFilter.FILTER_REJECT;
        }
        return NodeFilter.FILTER_ACCEPT;
      }
    });
    var nodes = [];
    while (walker.nextNode()) nodes.push(walker.currentNode);
    nodes.forEach(function (node) {
      var original = node.nodeValue;
      var parts = splitWhitespace(original);
      entries.push({
        type: "text",
        node: node,
        original: original,
        english: parts[1] + translations[parts[2]] + parts[3]
      });
    });
  }

  function registerAttributes() {
    document.querySelectorAll("*").forEach(function (element) {
      if (element.closest("[data-no-translate]")) return;
      ATTRIBUTE_NAMES.forEach(function (name) {
        var original = element.getAttribute(name);
        if (!original) return;
        var source = original.trim();
        if (!JAPANESE.test(source) || !translations[source]) return;
        var parts = splitWhitespace(original);
        entries.push({
          type: "attribute",
          node: element,
          name: name,
          original: original,
          english: parts[1] + translations[parts[2]] + parts[3]
        });
      });
    });
  }

  function preferredLanguage() {
    var requested = new URLSearchParams(window.location.search).get("lang");
    if (requested === "en" || requested === "ja") return requested;
    try {
      return localStorage.getItem(STORAGE_KEY) === "en" ? "en" : "ja";
    } catch (error) {
      return "ja";
    }
  }

  function saveLanguage(language) {
    try { localStorage.setItem(STORAGE_KEY, language); } catch (error) {}
  }

  function applyLanguage(language, persist) {
    var isEnglish = language === "en";
    entries.forEach(function (entry) {
      var value = isEnglish ? entry.english : entry.original;
      if (entry.type === "text") entry.node.nodeValue = value;
      else entry.node.setAttribute(entry.name, value);
    });
    document.documentElement.lang = isEnglish ? "en" : "ja";
    document.documentElement.dataset.language = isEnglish ? "en" : "ja";
    controls.querySelectorAll("button[data-language]").forEach(function (button) {
      button.setAttribute("aria-pressed", button.dataset.language === language ? "true" : "false");
    });
    controls.setAttribute(
      "aria-label",
      isEnglish ? "Choose display language" : "表示言語を選択"
    );
    status.textContent = isEnglish ? "Displayed in English" : "日本語で表示しています";
    if (persist !== false) saveLanguage(language);
    window.dispatchEvent(new CustomEvent("biglab:languagechange", { detail: { language: language } }));
  }

  function createControls() {
    controls = document.createElement("div");
    controls.className = "language-switcher";
    controls.dataset.noTranslate = "";
    controls.setAttribute("role", "group");
    controls.innerHTML =
      '<button type="button" data-language="ja" lang="ja">日本語</button>' +
      '<button type="button" data-language="en" lang="en">English</button>' +
      '<span class="language-switcher-status" aria-live="polite"></span>';
    status = controls.querySelector(".language-switcher-status");
    controls.addEventListener("click", function (event) {
      var button = event.target.closest("button[data-language]");
      if (button) applyLanguage(button.dataset.language, true);
    });
    document.body.appendChild(controls);
  }

  registerTextNodes();
  registerAttributes();
  createControls();
  applyLanguage(preferredLanguage(), false);

  window.addEventListener("storage", function (event) {
    if (event.key === STORAGE_KEY && (event.newValue === "ja" || event.newValue === "en")) {
      applyLanguage(event.newValue, false);
    }
  });
})();
