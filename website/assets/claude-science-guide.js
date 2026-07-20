(function () {
  var status = document.getElementById("copy-status");

  function fallbackCopy(value, button) {
    var area = document.createElement("textarea");
    area.value = value;
    area.style.position = "fixed";
    area.style.opacity = "0";
    document.body.appendChild(area);
    area.select();
    document.execCommand("copy");
    area.remove();
    showCopied(button);
  }

  function showCopied(button) {
    var previous = button.textContent;
    button.textContent = "COPIED";
    if (status) {
      status.textContent = document.documentElement.lang === "en"
        ? "Text copied"
        : "テキストをコピーしました";
    }
    window.setTimeout(function () { button.textContent = previous; }, 1400);
  }

  function copyText(value, button) {
    if (navigator.clipboard && window.isSecureContext) {
      navigator.clipboard.writeText(value).then(function () {
        showCopied(button);
      }).catch(function () {
        fallbackCopy(value, button);
      });
    } else {
      fallbackCopy(value, button);
    }
  }

  document.querySelectorAll("[data-copy]").forEach(function (block) {
    var button = block.querySelector(".copy-button");
    if (!button) return;
    button.addEventListener("click", function () {
      var clone = block.cloneNode(true);
      var cloneButton = clone.querySelector(".copy-button");
      if (cloneButton) cloneButton.remove();
      copyText(clone.textContent.trim(), button);
    });
  });

  document.querySelectorAll("[data-tabs]").forEach(function (tabsRoot) {
    var tabs = Array.prototype.slice.call(tabsRoot.querySelectorAll('[role="tab"]'));
    tabs.forEach(function (tab) {
      function selectTab() {
        tabs.forEach(function (item) {
          var selected = item === tab;
          var panel = document.getElementById(item.getAttribute("aria-controls"));
          item.setAttribute("aria-selected", selected ? "true" : "false");
          panel.hidden = !selected;
        });
      }
      tab.addEventListener("click", selectTab);
      tab.addEventListener("keydown", function (event) {
        if (event.key !== "ArrowLeft" && event.key !== "ArrowRight") return;
        event.preventDefault();
        var current = tabs.indexOf(tab);
        var next = event.key === "ArrowRight"
          ? (current + 1) % tabs.length
          : (current - 1 + tabs.length) % tabs.length;
        tabs[next].focus();
        tabs[next].click();
      });
    });
  });

  document.querySelectorAll("[data-prompt]").forEach(function (item) {
    var toggle = item.querySelector(".prompt-summary");
    var body = item.querySelector(".prompt-body");
    var symbol = item.querySelector(".prompt-toggle");
    if (!toggle || !body) return;
    toggle.addEventListener("click", function () {
      var open = toggle.getAttribute("aria-expanded") === "true";
      toggle.setAttribute("aria-expanded", open ? "false" : "true");
      body.hidden = open;
      if (symbol) symbol.textContent = open ? "+" : "−";
    });
  });

  document.querySelectorAll("[data-checklist]").forEach(function (root) {
    var inputs = Array.prototype.slice.call(root.querySelectorAll('input[type="checkbox"]'));
    var count = root.querySelector("[data-progress-count]");
    var fill = root.querySelector("[data-progress-fill]");
    var reset = root.querySelector("[data-reset]");
    var key = root.getAttribute("data-storage-key") || "claude-science-checklist";

    function update() {
      var complete = inputs.filter(function (input) { return input.checked; }).length;
      if (count) count.textContent = complete;
      if (fill) fill.style.width = (complete / inputs.length * 100) + "%";
      try {
        localStorage.setItem(key, JSON.stringify(inputs.map(function (input) { return input.checked; })));
      } catch (error) {}
    }

    try {
      var saved = JSON.parse(localStorage.getItem(key) || "[]");
      inputs.forEach(function (input, index) { input.checked = Boolean(saved[index]); });
    } catch (error) {}

    inputs.forEach(function (input) { input.addEventListener("change", update); });
    if (reset) {
      reset.addEventListener("click", function () {
        inputs.forEach(function (input) { input.checked = false; });
        update();
      });
    }
    update();
  });

  var tocLinks = Array.prototype.slice.call(document.querySelectorAll(".toc a"));
  if (tocLinks.length && "IntersectionObserver" in window) {
    var sections = tocLinks.map(function (link) {
      if (!link.hash) return null;
      try {
        return document.getElementById(decodeURIComponent(link.hash.slice(1)));
      } catch (error) {
        return document.getElementById(link.hash.slice(1));
      }
    }).filter(Boolean);
    var observer = new IntersectionObserver(function (entries) {
      var visible = entries.filter(function (entry) { return entry.isIntersecting; })
        .sort(function (a, b) { return b.intersectionRatio - a.intersectionRatio; })[0];
      if (!visible) return;
      tocLinks.forEach(function (link) { link.removeAttribute("aria-current"); });
      var active = tocLinks.find(function (link) {
        try {
          return decodeURIComponent(link.hash.slice(1)) === visible.target.id;
        } catch (error) {
          return link.hash.slice(1) === visible.target.id;
        }
      });
      if (active) active.setAttribute("aria-current", "true");
    }, { rootMargin: "-18% 0px -68%", threshold: [0, .2, .6] });
    sections.forEach(function (section) { observer.observe(section); });
  }
})();
