(() => {
  "use strict";

  const STORAGE = {
    tasks: "big-lab-dashboard-tasks-v1",
    focus: "big-lab-dashboard-focus-v1",
    memo: "big-lab-dashboard-memo-v1",
    favorites: "big-lab-dashboard-favorites-v1",
    weekly: "big-lab-dashboard-weekly-v1",
    recent: "big-lab-dashboard-recent-v1",
    path: "big-lab-dashboard-path-v1",
    htmlNotes: "big-lab-html-notes-v1",
    activeHtmlNote: "big-lab-html-note-active-v1",
    pendingTask: "big-lab-dashboard-pending-task-v1"
  };

  const categoryLabels = {
    research: "研究",
    meeting: "面談",
    reading: "読む",
    build: "実装",
    admin: "その他"
  };
  const statusLabels = { todo: "これから", doing: "進行中", done: "完了" };
  const priorityLabels = { high: "優先", normal: "通常", low: "低め" };

  const todayISO = () => {
    const date = new Date();
    const offset = date.getTimezoneOffset();
    return new Date(date.getTime() - offset * 60000).toISOString().slice(0, 10);
  };

  const offsetDate = (days) => {
    const date = new Date();
    date.setDate(date.getDate() + days);
    const offset = date.getTimezoneOffset();
    return new Date(date.getTime() - offset * 60000).toISOString().slice(0, 10);
  };

  const defaultTasks = [
    { id: "seed-1", title: "BiG Labの全体像を読む", category: "reading", priority: "high", status: "doing", due: todayISO(), createdAt: Date.now() - 6000 },
    { id: "seed-2", title: "指定4論文から重要な根拠を3つ抜き出す", category: "research", priority: "normal", status: "todo", due: offsetDate(1), createdAt: Date.now() - 5000 },
    { id: "seed-3", title: "面談で確認する質問を3問に絞る", category: "meeting", priority: "high", status: "todo", due: offsetDate(2), createdAt: Date.now() - 4000 },
    { id: "seed-4", title: "Geometry QC pilotの対象指標を決める", category: "research", priority: "normal", status: "todo", due: offsetDate(4), createdAt: Date.now() - 3000 },
    { id: "seed-5", title: "データとAIの利用境界を確認する", category: "admin", priority: "normal", status: "done", due: offsetDate(-1), createdAt: Date.now() - 2000 },
    { id: "seed-6", title: "解析repoの構成案を作る", category: "build", priority: "low", status: "done", due: "", createdAt: Date.now() - 1000 }
  ];

  const readJSON = (key, fallback) => {
    try {
      const value = JSON.parse(localStorage.getItem(key));
      return value ?? fallback;
    } catch {
      return fallback;
    }
  };

  const saveJSON = (key, value) => localStorage.setItem(key, JSON.stringify(value));
  const escapeHTML = (value) => String(value).replace(/[&<>"']/g, (character) => ({
    "&": "&amp;",
    "<": "&lt;",
    ">": "&gt;",
    '"': "&quot;",
    "'": "&#039;"
  })[character]);

  let tasks = readJSON(STORAGE.tasks, null);
  if (!Array.isArray(tasks)) {
    tasks = defaultTasks;
    saveJSON(STORAGE.tasks, tasks);
  }
  const pendingTask = readJSON(STORAGE.pendingTask, null);
  if (pendingTask?.title) {
    const alreadyAdded = tasks.some((task) => task.title === pendingTask.title && task.due === (pendingTask.due || ""));
    if (!alreadyAdded) {
      tasks.push({
        id: `idea-${pendingTask.createdAt || Date.now()}`,
        title: pendingTask.title,
        category: "research",
        priority: "high",
        status: "todo",
        due: pendingTask.due || "",
        createdAt: pendingTask.createdAt || Date.now()
      });
      saveJSON(STORAGE.tasks, tasks);
    }
    localStorage.removeItem(STORAGE.pendingTask);
  }
  let taskView = "all";
  let noteFilter = "all";
  let noteQuery = "";
  let toastTimer;

  const showToast = (message) => {
    const toast = document.querySelector("[data-toast]");
    if (!toast) return;
    toast.textContent = message;
    toast.classList.add("is-visible");
    clearTimeout(toastTimer);
    toastTimer = setTimeout(() => toast.classList.remove("is-visible"), 1800);
  };

  const formatDate = (value) => {
    if (!value) return "";
    const date = new Date(`${value}T00:00:00`);
    const today = todayISO();
    if (value === today) return "今日";
    if (value === offsetDate(1)) return "明日";
    return new Intl.DateTimeFormat("ja-JP", { month: "numeric", day: "numeric" }).format(date);
  };

  const taskMatchesView = (task) => {
    if (taskView === "today") return task.due && task.due <= todayISO() && task.status !== "done";
    if (taskView === "high") return task.priority === "high" && task.status !== "done";
    return true;
  };

  const taskMarkup = (task) => {
    const overdue = task.due && task.due < todayISO() && task.status !== "done";
    return `
      <article class="task-card${task.status === "done" ? " is-done" : ""}" data-task-id="${escapeHTML(task.id)}">
        <div class="task-card-top">
          <button class="task-check" type="button" data-task-complete aria-label="${task.status === "done" ? "未完了に戻す" : "完了にする"}">${task.status === "done" ? "✓" : ""}</button>
          <p class="task-card-title">${escapeHTML(task.title)}</p>
          <button class="delete-task" type="button" data-task-delete aria-label="タスクを削除">×</button>
        </div>
        <div class="task-card-foot">
          <span class="task-category ${escapeHTML(task.category)}">${escapeHTML(categoryLabels[task.category] || "その他")}</span>
          ${task.priority !== "normal" ? `<span class="task-priority ${escapeHTML(task.priority)}">${escapeHTML(priorityLabels[task.priority])}</span>` : ""}
          ${task.due ? `<time class="task-date${overdue ? " is-overdue" : ""}" datetime="${escapeHTML(task.due)}">${overdue ? "期限超過 · " : ""}${escapeHTML(formatDate(task.due))}</time>` : ""}
        </div>
        <label>
          <span class="sr-only">状態を変更</span>
          <select class="task-status" data-task-status>
            ${Object.entries(statusLabels).map(([value, label]) => `<option value="${value}"${task.status === value ? " selected" : ""}>${label}</option>`).join("")}
          </select>
        </label>
      </article>`;
  };

  const renderTasks = () => {
    const visibleTasks = tasks.filter(taskMatchesView);
    ["todo", "doing", "done"].forEach((status) => {
      const list = document.querySelector(`[data-task-list="${status}"]`);
      const statusTasks = visibleTasks
        .filter((task) => task.status === status)
        .sort((a, b) => {
          if (a.priority === "high" && b.priority !== "high") return -1;
          if (a.priority !== "high" && b.priority === "high") return 1;
          return (a.due || "9999") .localeCompare(b.due || "9999") || b.createdAt - a.createdAt;
        });
      if (list) list.innerHTML = statusTasks.map(taskMarkup).join("");
      const count = document.querySelector(`[data-column-count="${status}"]`);
      if (count) count.textContent = statusTasks.length;
    });

    const open = tasks.filter((task) => task.status !== "done").length;
    const doing = tasks.filter((task) => task.status === "doing").length;
    const done = tasks.filter((task) => task.status === "done").length;
    const dueToday = tasks.filter((task) => task.status !== "done" && task.due && task.due <= todayISO()).length;
    const progress = tasks.length ? Math.round((done / tasks.length) * 100) : 0;

    document.querySelectorAll("[data-open-task-count]").forEach((element) => { element.textContent = open; });
    const summaryOpen = document.querySelector("[data-summary-open]");
    const summaryDoing = document.querySelector("[data-summary-doing]");
    const summaryDone = document.querySelector("[data-summary-done]");
    const summaryToday = document.querySelector("[data-summary-today]");
    const summaryProgress = document.querySelector("[data-summary-progress]");
    const progressRing = document.querySelector("[data-progress-ring]");
    if (summaryOpen) summaryOpen.textContent = open;
    if (summaryDoing) summaryDoing.textContent = doing;
    if (summaryDone) summaryDone.textContent = done;
    if (summaryToday) summaryToday.textContent = dueToday;
    if (summaryProgress) summaryProgress.textContent = `${progress}%`;
    if (progressRing) progressRing.style.setProperty("--progress", `${progress * 3.6}deg`);
    const empty = document.querySelector("[data-task-empty]");
    if (empty) empty.hidden = visibleTasks.length > 0;
  };

  document.querySelector("[data-task-form]")?.addEventListener("submit", (event) => {
    event.preventDefault();
    const titleInput = event.currentTarget.querySelector("[data-task-title]");
    const title = titleInput.value.trim();
    if (!title) return;
    tasks.push({
      id: `task-${Date.now()}-${Math.random().toString(16).slice(2)}`,
      title,
      category: event.currentTarget.querySelector("[data-task-category]").value,
      due: event.currentTarget.querySelector("[data-task-date]").value,
      priority: event.currentTarget.querySelector("[data-task-priority]").value,
      status: "todo",
      createdAt: Date.now()
    });
    saveJSON(STORAGE.tasks, tasks);
    event.currentTarget.reset();
    titleInput.focus();
    renderTasks();
    showToast("タスクを追加しました");
  });

  document.querySelector("[data-task-board]")?.addEventListener("click", (event) => {
    const card = event.target.closest("[data-task-id]");
    if (!card) return;
    const task = tasks.find((item) => item.id === card.dataset.taskId);
    if (!task) return;
    if (event.target.closest("[data-task-complete]")) {
      task.status = task.status === "done" ? "todo" : "done";
      saveJSON(STORAGE.tasks, tasks);
      renderTasks();
      showToast(task.status === "done" ? "タスクを完了しました" : "タスクを戻しました");
    }
    if (event.target.closest("[data-task-delete]")) {
      tasks = tasks.filter((item) => item.id !== task.id);
      saveJSON(STORAGE.tasks, tasks);
      renderTasks();
      showToast("タスクを削除しました");
    }
  });

  document.querySelector("[data-task-board]")?.addEventListener("change", (event) => {
    if (!event.target.matches("[data-task-status]")) return;
    const card = event.target.closest("[data-task-id]");
    const task = tasks.find((item) => item.id === card?.dataset.taskId);
    if (!task) return;
    task.status = event.target.value;
    saveJSON(STORAGE.tasks, tasks);
    renderTasks();
    showToast(`「${statusLabels[task.status]}」へ移動しました`);
  });

  document.querySelectorAll("[data-task-view]").forEach((button) => {
    button.addEventListener("click", () => {
      taskView = button.dataset.taskView;
      document.querySelectorAll("[data-task-view]").forEach((item) => item.classList.toggle("is-active", item === button));
      renderTasks();
    });
  });

  document.querySelector("[data-focus-task-input]")?.addEventListener("click", () => {
    document.querySelector("#tasks")?.scrollIntoView({ behavior: "smooth" });
    setTimeout(() => document.querySelector("[data-task-title]")?.focus(), 450);
  });

  const debounceSave = (element, key, stateElement) => {
    let timer;
    element.value = localStorage.getItem(key) || "";
    element.addEventListener("input", () => {
      if (stateElement) stateElement.textContent = "保存中…";
      clearTimeout(timer);
      timer = setTimeout(() => {
        localStorage.setItem(key, element.value);
        if (stateElement) stateElement.textContent = "保存済み";
      }, 350);
    });
  };

  const focusEditor = document.querySelector("[data-daily-focus]");
  if (focusEditor) {
    const focusLength = document.querySelector("[data-focus-length]");
    debounceSave(focusEditor, STORAGE.focus, document.querySelector("[data-focus-state]"));
    const updateLength = () => { if (focusLength) focusLength.textContent = `${focusEditor.value.length} / 240`; };
    focusEditor.addEventListener("input", updateLength);
    updateLength();
  }
  const memoEditor = document.querySelector("[data-quick-memo]");
  if (memoEditor) debounceSave(memoEditor, STORAGE.memo, document.querySelector("[data-memo-state]"));

  const htmlNotesApp = document.querySelector("[data-html-notes-app]");
  if (htmlNotesApp) {
    const defaultHTML = `<article>
  <h1>Microneedle Research</h1>
  <p>This note describes the experiment and the questions to validate next.</p>

  <h2>Research focus</h2>
  <ul>
    <li>Microneedle geometry</li>
    <li>Drug release rate</li>
    <li>Small-data validation</li>
  </ul>

  <blockquote>
    Record the evidence, decision, and next action in the same note.
  </blockquote>
</article>`;
    const makeId = () => `note-${Date.now()}-${Math.random().toString(16).slice(2)}`;
    const makeNote = (title = "無題のノート", html = "<article><h1>無題のノート</h1><p>ここから書き始めます。</p></article>") => ({
      id: makeId(),
      title,
      html,
      createdAt: Date.now(),
      updatedAt: Date.now()
    });
    let htmlNotes = readJSON(STORAGE.htmlNotes, null);
    if (!Array.isArray(htmlNotes) || !htmlNotes.length) {
      const legacyMemo = localStorage.getItem(STORAGE.memo)?.trim();
      htmlNotes = [makeNote("Microneedle Research", defaultHTML)];
      if (legacyMemo) {
        const paragraphs = legacyMemo.split(/\n{2,}/).map((paragraph) => `<p>${escapeHTML(paragraph).replace(/\n/g, "<br>")}</p>`).join("\n");
        htmlNotes.push(makeNote("以前の作業ノート", `<article><h1>以前の作業ノート</h1>${paragraphs}</article>`));
      }
      saveJSON(STORAGE.htmlNotes, htmlNotes);
    }

    const titleInput = htmlNotesApp.querySelector("[data-html-note-title]");
    const visualEditor = htmlNotesApp.querySelector("[data-html-visual-editor]");
    const sourceEditor = htmlNotesApp.querySelector("[data-html-source-editor]");
    const sourceWrap = htmlNotesApp.querySelector("[data-html-source-wrap]");
    const previewWrap = htmlNotesApp.querySelector("[data-html-preview-wrap]");
    const previewFrame = htmlNotesApp.querySelector("[data-html-preview]");
    const visualToolbar = htmlNotesApp.querySelector("[data-html-visual-toolbar]");
    const saveState = htmlNotesApp.querySelector("[data-html-note-save-state]");
    const noteList = htmlNotesApp.querySelector("[data-html-note-list]");
    const noteSearchInput = htmlNotesApp.querySelector("[data-html-note-search]");
    const noteCount = htmlNotesApp.querySelector("[data-html-note-count]");
    const listEmpty = htmlNotesApp.querySelector("[data-html-note-list-empty]");
    const stats = htmlNotesApp.querySelector("[data-html-note-stats]");
    const updatedLabel = htmlNotesApp.querySelector("[data-html-note-updated]");
    const kindLabel = htmlNotesApp.querySelector("[data-html-note-kind]");
    const importInput = htmlNotesApp.querySelector("[data-html-note-import]");
    let activeHtmlNoteId = localStorage.getItem(STORAGE.activeHtmlNote);
    if (!htmlNotes.some((note) => note.id === activeHtmlNoteId)) activeHtmlNoteId = htmlNotes[0].id;
    let htmlMode = "visual";
    let htmlSaveTimer;

    const activeNote = () => htmlNotes.find((note) => note.id === activeHtmlNoteId);
    const plainText = (html) => {
      const template = document.createElement("template");
      template.innerHTML = html;
      return (template.content.textContent || "").replace(/\s+/g, " ").trim();
    };
    const relativeTime = (timestamp) => {
      const delta = Math.max(0, Date.now() - Number(timestamp || 0));
      if (delta < 60000) return "たった今";
      if (delta < 3600000) return `${Math.floor(delta / 60000)}分前`;
      if (delta < 86400000) return `${Math.floor(delta / 3600000)}時間前`;
      return new Intl.DateTimeFormat("ja-JP", { month: "numeric", day: "numeric" }).format(new Date(timestamp));
    };
    const isFullDocument = (html) => /<!doctype|<html[\s>]|<head[\s>]|<body[\s>]/i.test(html);
    const sanitizeDOM = (html, allowStyles = false) => {
      const parser = new DOMParser();
      const documentNode = parser.parseFromString(String(html || ""), "text/html");
      const blocked = allowStyles
        ? "script,iframe,object,embed,form,base,link,meta[http-equiv]"
        : "script,style,iframe,object,embed,form,base,link,meta";
      documentNode.querySelectorAll(blocked).forEach((node) => node.remove());
      documentNode.querySelectorAll("*").forEach((element) => {
        [...element.attributes].forEach((attribute) => {
          const name = attribute.name.toLowerCase();
          const value = attribute.value.trim().toLowerCase();
          const unsafeVisualAttribute = !allowStyles && (name === "style" || name === "class" || name === "id");
          if (unsafeVisualAttribute || name.startsWith("on") || name === "srcdoc" || ((name === "href" || name === "src" || name === "xlink:href") && value.startsWith("javascript:"))) {
            element.removeAttribute(attribute.name);
          }
        });
      });
      return documentNode;
    };
    const safeVisualHTML = (html) => sanitizeDOM(html, false).body.innerHTML;
    const previewDocument = (html, title) => {
      const documentNode = sanitizeDOM(html, true);
      const csp = documentNode.createElement("meta");
      csp.setAttribute("http-equiv", "Content-Security-Policy");
      csp.setAttribute("content", "default-src 'none'; img-src data: blob: https: http:; media-src data: blob: https: http:; font-src data: https:; style-src 'unsafe-inline';");
      documentNode.head.prepend(csp);
      const titleElement = documentNode.createElement("title");
      titleElement.textContent = title;
      documentNode.head.append(titleElement);
      const baseStyle = documentNode.createElement("style");
      baseStyle.textContent = `
        :root { color-scheme: light; }
        * { box-sizing: border-box; }
        body { max-width: 780px; margin: 0 auto; padding: 48px 42px 72px; color: #25272d; background: #fff; font: 16px/1.75 Georgia, "Yu Mincho", serif; }
        h1, h2, h3 { color: #17181c; font-family: ui-sans-serif, system-ui, sans-serif; line-height: 1.25; }
        h1 { margin: 0 0 24px; font-size: 2rem; } h2 { margin-top: 2rem; font-size: 1.4rem; }
        a { color: #0c52d1; } img, video { max-width: 100%; height: auto; }
        blockquote { margin: 1.5rem 0; padding-left: 1rem; border-left: 3px solid #1a6bff; color: #54555c; }
        pre { padding: 1rem; overflow: auto; border-radius: 10px; background: #f3f5f7; }
        code { font-family: ui-monospace, monospace; }
      `;
      documentNode.head.prepend(baseStyle);
      return `<!doctype html>\n${documentNode.documentElement.outerHTML}`;
    };
    const updateNoteMeta = () => {
      const note = activeNote();
      if (!note) return;
      const text = plainText(note.html);
      if (stats) stats.textContent = `${text.length.toLocaleString("ja-JP")}文字`;
      if (updatedLabel) updatedLabel.textContent = `更新 ${relativeTime(note.updatedAt)}`;
      if (kindLabel) kindLabel.textContent = isFullDocument(note.html) ? "Full HTML document" : "HTML fragment";
    };
    const renderHtmlNoteList = () => {
      const query = noteSearchInput?.value.trim().toLocaleLowerCase("ja") || "";
      const visibleNotes = htmlNotes
        .filter((note) => !query || `${note.title} ${plainText(note.html)}`.toLocaleLowerCase("ja").includes(query))
        .sort((a, b) => b.updatedAt - a.updatedAt);
      noteList.innerHTML = visibleNotes.map((note) => `
        <button class="html-note-list-item${note.id === activeHtmlNoteId ? " is-active" : ""}" type="button" data-html-note-id="${escapeHTML(note.id)}">
          <span class="html-note-list-icon" aria-hidden="true">H</span>
          <span class="html-note-list-copy">
            <strong>${escapeHTML(note.title || "無題のノート")}</strong>
            <small>${escapeHTML(relativeTime(note.updatedAt))} · ${plainText(note.html).length.toLocaleString("ja-JP")}文字</small>
          </span>
        </button>`).join("");
      if (noteCount) noteCount.textContent = htmlNotes.length;
      if (listEmpty) listEmpty.hidden = visibleNotes.length > 0;
    };
    const persistHtmlNotes = (withToast = false) => {
      clearTimeout(htmlSaveTimer);
      saveJSON(STORAGE.htmlNotes, htmlNotes);
      localStorage.setItem(STORAGE.activeHtmlNote, activeHtmlNoteId);
      if (saveState) saveState.textContent = "保存済み";
      renderHtmlNoteList();
      updateNoteMeta();
      if (withToast) showToast("HTMLノートを保存しました");
    };
    const scheduleHtmlSave = () => {
      const note = activeNote();
      if (!note) return;
      note.updatedAt = Date.now();
      if (saveState) saveState.textContent = "保存中…";
      updateNoteMeta();
      clearTimeout(htmlSaveTimer);
      htmlSaveTimer = setTimeout(() => persistHtmlNotes(), 420);
    };
    const updatePreview = () => {
      const note = activeNote();
      if (previewFrame && note) previewFrame.srcdoc = previewDocument(note.html, note.title);
    };
    const loadHtmlNote = () => {
      const note = activeNote();
      if (!note) return;
      titleInput.value = note.title;
      sourceEditor.value = note.html;
      visualEditor.innerHTML = safeVisualHTML(note.html);
      updatePreview();
      renderHtmlNoteList();
      updateNoteMeta();
      if (saveState) saveState.textContent = "保存済み";
    };
    const syncActiveNote = (source) => {
      const note = activeNote();
      if (!note) return;
      if (source === "visual") {
        note.html = visualEditor.innerHTML;
        sourceEditor.value = note.html;
      } else if (source === "source") {
        note.html = sourceEditor.value;
      }
      scheduleHtmlSave();
    };
    const setHtmlMode = (mode) => {
      const note = activeNote();
      if (!note || !["visual", "source", "preview"].includes(mode)) return;
      htmlMode = mode;
      if (mode === "visual") visualEditor.innerHTML = safeVisualHTML(note.html);
      if (mode === "source") sourceEditor.value = note.html;
      if (mode === "preview") updatePreview();
      visualEditor.hidden = mode !== "visual";
      sourceWrap.hidden = mode !== "source";
      previewWrap.hidden = mode !== "preview";
      visualToolbar.hidden = mode !== "visual";
      htmlNotesApp.querySelectorAll("[data-html-mode]").forEach((button) => {
        const active = button.dataset.htmlMode === mode;
        button.classList.toggle("is-active", active);
        button.setAttribute("aria-selected", String(active));
      });
      scheduleHtmlSave();
    };

    titleInput.addEventListener("input", () => {
      const note = activeNote();
      if (!note) return;
      note.title = titleInput.value || "無題のノート";
      scheduleHtmlSave();
    });
    visualEditor.addEventListener("input", () => syncActiveNote("visual"));
    sourceEditor.addEventListener("input", () => syncActiveNote("source"));
    sourceEditor.addEventListener("keydown", (event) => {
      if (event.key !== "Tab") return;
      event.preventDefault();
      const start = sourceEditor.selectionStart;
      const end = sourceEditor.selectionEnd;
      sourceEditor.setRangeText("  ", start, end, "end");
      syncActiveNote("source");
    });
    noteList.addEventListener("click", (event) => {
      const button = event.target.closest("[data-html-note-id]");
      if (!button || button.dataset.htmlNoteId === activeHtmlNoteId) return;
      persistHtmlNotes();
      activeHtmlNoteId = button.dataset.htmlNoteId;
      loadHtmlNote();
    });
    noteSearchInput?.addEventListener("input", renderHtmlNoteList);
    htmlNotesApp.querySelectorAll("[data-html-mode]").forEach((button) => {
      button.addEventListener("click", () => setHtmlMode(button.dataset.htmlMode));
    });
    document.querySelector("[data-html-note-new]")?.addEventListener("click", () => {
      persistHtmlNotes();
      const note = makeNote();
      htmlNotes.push(note);
      activeHtmlNoteId = note.id;
      if (noteSearchInput) noteSearchInput.value = "";
      setHtmlMode("visual");
      loadHtmlNote();
      titleInput.focus();
      titleInput.select();
      persistHtmlNotes();
      showToast("新しいHTMLノートを作成しました");
    });
    htmlNotesApp.querySelector("[data-html-note-delete]")?.addEventListener("click", () => {
      const note = activeNote();
      if (!note || !window.confirm(`「${note.title}」を削除しますか？`)) return;
      htmlNotes = htmlNotes.filter((item) => item.id !== note.id);
      if (!htmlNotes.length) htmlNotes.push(makeNote());
      activeHtmlNoteId = htmlNotes[0].id;
      loadHtmlNote();
      persistHtmlNotes();
      showToast("HTMLノートを削除しました");
    });
    htmlNotesApp.querySelector("[data-html-note-export]")?.addEventListener("click", () => {
      const note = activeNote();
      if (!note) return;
      persistHtmlNotes();
      const blob = new Blob([note.html], { type: "text/html;charset=utf-8" });
      const url = URL.createObjectURL(blob);
      const link = document.createElement("a");
      const filename = (note.title || "untitled").normalize("NFKC").replace(/[\\/:*?"<>|]+/g, "-").replace(/\s+/g, "-").slice(0, 80) || "untitled";
      link.href = url;
      link.download = `${filename}.html`;
      link.click();
      setTimeout(() => URL.revokeObjectURL(url), 0);
      showToast("HTMLファイルを書き出しました");
    });
    htmlNotesApp.querySelector("[data-html-note-import-trigger]")?.addEventListener("click", () => importInput?.click());
    importInput?.addEventListener("change", async () => {
      const file = importInput.files?.[0];
      if (!file) return;
      const html = await file.text();
      const parsed = new DOMParser().parseFromString(html, "text/html");
      const parsedTitle = parsed.querySelector("title")?.textContent?.trim() || parsed.querySelector("h1")?.textContent?.trim();
      const fallbackTitle = file.name.replace(/\.html?$/i, "");
      const note = makeNote(parsedTitle || fallbackTitle || "読み込んだノート", html);
      htmlNotes.push(note);
      activeHtmlNoteId = note.id;
      if (noteSearchInput) noteSearchInput.value = "";
      setHtmlMode("source");
      loadHtmlNote();
      persistHtmlNotes();
      importInput.value = "";
      showToast("HTMLファイルを読み込みました");
    });
    htmlNotesApp.querySelector("[data-html-format]")?.addEventListener("change", (event) => {
      visualEditor.focus();
      document.execCommand("formatBlock", false, event.target.value);
      syncActiveNote("visual");
    });
    htmlNotesApp.querySelectorAll("[data-html-command]").forEach((button) => {
      button.addEventListener("mousedown", (event) => event.preventDefault());
      button.addEventListener("click", () => {
        visualEditor.focus();
        document.execCommand(button.dataset.htmlCommand, false);
        syncActiveNote("visual");
      });
    });
    htmlNotesApp.querySelector("[data-html-link]")?.addEventListener("click", () => {
      const url = window.prompt("リンク先URL（内部リンクは note://slug）");
      if (!url) return;
      visualEditor.focus();
      document.execCommand("createLink", false, url);
      syncActiveNote("visual");
    });
    document.addEventListener("keydown", (event) => {
      if (!(event.metaKey || event.ctrlKey) || event.key.toLowerCase() !== "s") return;
      if (!htmlNotesApp.contains(document.activeElement)) return;
      event.preventDefault();
      persistHtmlNotes(true);
    });
    loadHtmlNote();
  }

  const favorites = new Set(readJSON(STORAGE.favorites, []));
  const refreshFavorites = () => {
    document.querySelectorAll("[data-favorite]").forEach((button) => {
      const active = favorites.has(button.dataset.favorite);
      button.classList.toggle("is-favorite", active);
      button.textContent = active ? "★" : "☆";
      button.setAttribute("aria-label", active ? "お気に入りから外す" : "お気に入りに追加");
    });
    const favoriteCount = document.querySelector("[data-favorite-count]");
    if (favoriteCount) favoriteCount.textContent = favorites.size;
  };

  const filterNotes = () => {
    let visible = 0;
    document.querySelectorAll("[data-note]").forEach((card) => {
      const favoriteId = card.querySelector("[data-favorite]")?.dataset.favorite;
      const matchesCategory = noteFilter === "all"
        || (noteFilter === "favorite"
          ? favorites.has(favoriteId)
          : card.dataset.category === noteFilter || card.dataset.type === noteFilter);
      const haystack = `${card.dataset.search || ""} ${card.textContent}`.toLocaleLowerCase("ja");
      const matchesQuery = !noteQuery || haystack.includes(noteQuery);
      card.hidden = !(matchesCategory && matchesQuery);
      if (!card.hidden) visible += 1;
    });
    const empty = document.querySelector("[data-note-empty]");
    if (empty) empty.hidden = visible > 0;
  };

  document.querySelector("[data-note-grid]")?.addEventListener("click", (event) => {
    const favorite = event.target.closest("[data-favorite]");
    if (favorite) {
      event.preventDefault();
      const id = favorite.dataset.favorite;
      if (favorites.has(id)) favorites.delete(id);
      else favorites.add(id);
      saveJSON(STORAGE.favorites, [...favorites]);
      refreshFavorites();
      filterNotes();
      showToast(favorites.has(id) ? "お気に入りに追加しました" : "お気に入りから外しました");
    }
  });

  document.querySelectorAll("[data-note-filter]").forEach((button) => {
    button.addEventListener("click", () => {
      noteFilter = button.dataset.noteFilter;
      document.querySelectorAll("[data-note-filter]").forEach((item) => item.classList.toggle("is-active", item === button));
      filterNotes();
    });
  });

  const noteSearch = document.querySelector("[data-note-search]");
  const globalSearch = document.querySelector("[data-global-search]");
  const updateSearch = (value) => {
    noteQuery = value.trim().toLocaleLowerCase("ja");
    if (noteSearch && noteSearch.value !== value) noteSearch.value = value;
    if (globalSearch && globalSearch.value !== value) globalSearch.value = value;
    filterNotes();
  };
  noteSearch?.addEventListener("input", () => updateSearch(noteSearch.value));
  globalSearch?.addEventListener("input", () => {
    updateSearch(globalSearch.value);
    if (globalSearch.value.trim()) document.querySelector("#library")?.scrollIntoView({ behavior: "smooth" });
  });
  document.addEventListener("keydown", (event) => {
    if ((event.metaKey || event.ctrlKey) && event.key.toLowerCase() === "k") {
      event.preventDefault();
      const target = window.matchMedia("(max-width: 800px)").matches ? noteSearch : globalSearch;
      target?.focus();
      target?.select();
    }
  });

  document.querySelectorAll("[data-quick-filter]").forEach((link) => {
    link.addEventListener("click", () => {
      noteFilter = link.dataset.quickFilter;
      const targetButton = document.querySelector(`[data-note-filter="${noteFilter}"]`);
      document.querySelectorAll("[data-note-filter]").forEach((item) => item.classList.toggle("is-active", item === targetButton));
      filterNotes();
    });
  });

  document.querySelectorAll("[data-library-filter]").forEach((link) => {
    link.addEventListener("click", () => {
      noteFilter = link.dataset.libraryFilter || "all";
      const targetButton = document.querySelector(`[data-note-filter="${noteFilter}"]`);
      document.querySelectorAll("[data-note-filter]").forEach((item) => item.classList.toggle("is-active", item === targetButton));
      filterNotes();
    });
  });

  document.querySelectorAll("[data-note-link]").forEach((link) => {
    link.addEventListener("click", () => {
      const recent = readJSON(STORAGE.recent, []);
      saveJSON(STORAGE.recent, [link.dataset.noteLink, ...recent.filter((item) => item !== link.dataset.noteLink)].slice(0, 8));
    });
  });

  const weekly = readJSON(STORAGE.weekly, { goals: ["", "", ""], checks: [false, false, false] });
  document.querySelectorAll("[data-week-goal]").forEach((input) => {
    const index = Number(input.dataset.weekGoal);
    input.value = weekly.goals?.[index] || "";
    input.addEventListener("input", () => {
      weekly.goals[index] = input.value;
      saveJSON(STORAGE.weekly, weekly);
    });
  });
  document.querySelectorAll("[data-week-check]").forEach((input) => {
    const index = Number(input.dataset.weekCheck);
    input.checked = Boolean(weekly.checks?.[index]);
    input.addEventListener("change", () => {
      weekly.checks[index] = input.checked;
      saveJSON(STORAGE.weekly, weekly);
    });
  });

  const pathState = readJSON(STORAGE.path, [false, false, false, false, false, false]);
  const pathChecks = [...document.querySelectorAll("[data-path-check]")];
  const refreshPath = () => {
    const completed = pathChecks.filter((input) => input.checked).length;
    const progress = pathChecks.length ? Math.round((completed / pathChecks.length) * 100) : 0;
    document.querySelectorAll("[data-path-count]").forEach((element) => { element.textContent = completed; });
    const progressLabel = document.querySelector("[data-path-progress]");
    const progressBar = document.querySelector("[data-path-bar]");
    if (progressLabel) progressLabel.textContent = `${progress}%`;
    if (progressBar) progressBar.style.width = `${progress}%`;
  };
  pathChecks.forEach((input, index) => {
    input.checked = Boolean(pathState[index]);
    input.addEventListener("change", () => {
      pathState[index] = input.checked;
      saveJSON(STORAGE.path, pathState);
      refreshPath();
      showToast(input.checked ? "読了として記録しました" : "未読に戻しました");
    });
  });
  refreshPath();

  const now = new Date();
  const weekdays = ["日", "月", "火", "水", "木", "金", "土"];
  const hours = now.getHours();
  const greeting = hours < 11 ? "GOOD MORNING" : hours < 17 ? "GOOD AFTERNOON" : "GOOD EVENING";
  const greetingElement = document.querySelector("[data-greeting]");
  if (greetingElement) greetingElement.textContent = `${greeting} / RESEARCH WORKSPACE`;
  const weekdayElement = document.querySelector("[data-today-weekday]");
  const dayElement = document.querySelector("[data-today-day]");
  if (weekdayElement) weekdayElement.textContent = `${weekdays[now.getDay()]}曜`;
  if (dayElement) dayElement.textContent = now.getDate();
  const monday = new Date(now);
  const mondayDelta = now.getDay() === 0 ? -6 : 1 - now.getDay();
  monday.setDate(now.getDate() + mondayDelta);
  const sunday = new Date(monday);
  sunday.setDate(monday.getDate() + 6);
  const weekLabel = document.querySelector("[data-week-label]");
  if (weekLabel) weekLabel.textContent = `${monday.getMonth() + 1}/${monday.getDate()} — ${sunday.getMonth() + 1}/${sunday.getDate()}`;

  const menuButton = document.querySelector("[data-menu-toggle]");
  menuButton?.addEventListener("click", () => {
    const isOpen = document.body.classList.toggle("menu-open");
    menuButton.setAttribute("aria-expanded", String(isOpen));
  });
  document.querySelectorAll(".sidebar a").forEach((link) => {
    link.addEventListener("click", () => {
      document.body.classList.remove("menu-open");
      menuButton?.setAttribute("aria-expanded", "false");
    });
  });
  document.addEventListener("click", (event) => {
    if (!document.body.classList.contains("menu-open")) return;
    if (event.target.closest(".sidebar, [data-menu-toggle]")) return;
    document.body.classList.remove("menu-open");
    menuButton?.setAttribute("aria-expanded", "false");
  });

  const sections = [...document.querySelectorAll("main section[id]")];
  const navLinks = [...document.querySelectorAll(".primary-nav a")];
  const sectionLabels = {
    home: "Home",
    path: "進める順番",
    tasks: "タスク",
    notes: "ノート",
    papers: "論文",
    library: "全資料",
    weekly: "今週"
  };
  if ("IntersectionObserver" in window) {
    const observer = new IntersectionObserver((entries) => {
      const visible = entries.filter((entry) => entry.isIntersecting).sort((a, b) => b.intersectionRatio - a.intersectionRatio)[0];
      if (!visible) return;
      navLinks.forEach((link) => {
        const active = link.getAttribute("href") === `#${visible.target.id}`;
        link.classList.toggle("is-active", active);
        if (active) link.setAttribute("aria-current", "page");
        else link.removeAttribute("aria-current");
      });
      const title = document.querySelector(".topbar-title strong");
      if (title) title.textContent = sectionLabels[visible.target.id] || "Home";
    }, { rootMargin: "-20% 0px -65%", threshold: [0, .15, .4] });
    sections.forEach((section) => observer.observe(section));
  }

  refreshFavorites();
  filterNotes();
  renderTasks();
})();
