(() => {
  const progress = document.querySelector('[data-reading-progress]');
  const updateProgress = () => {
    if (!progress) return;
    const root = document.documentElement;
    const distance = root.scrollHeight - root.clientHeight;
    const value = distance > 0 ? Math.min(100, Math.max(0, root.scrollTop / distance * 100)) : 0;
    progress.style.width = `${value}%`;
  };
  updateProgress();
  document.addEventListener('scroll', updateProgress, { passive: true });
  window.addEventListener('resize', updateProgress);

  const toggle = document.querySelector('[data-toc-toggle]');
  const sidebar = document.querySelector('[data-sidebar]');
  if (toggle && sidebar) {
    toggle.addEventListener('click', () => {
      const open = sidebar.classList.toggle('is-open');
      toggle.setAttribute('aria-expanded', String(open));
    });
    sidebar.addEventListener('click', (event) => {
      if (event.target.closest('a') && window.matchMedia('(max-width: 900px)').matches) {
        sidebar.classList.remove('is-open');
        toggle.setAttribute('aria-expanded', 'false');
      }
    });
  }

  document.querySelectorAll('.article table').forEach((table) => {
    if (table.parentElement?.classList.contains('table-scroll')) return;
    const wrapper = document.createElement('div');
    wrapper.className = 'table-scroll';
    wrapper.setAttribute('role', 'region');
    wrapper.setAttribute('aria-label', '横スクロール可能な表');
    wrapper.tabIndex = 0;
    table.parentNode.insertBefore(wrapper, table);
    wrapper.appendChild(table);
  });

  const tokens = new Map([
    ['[論文]', ['type-paper', '論文本文に基づく内容']],
    ['[統合]', ['type-synthesis', '4論文を横断した統合解釈']],
    ['[提案]', ['type-proposal', 'BIGで議論するための提案']]
  ]);
  const walker = document.createTreeWalker(
    document.querySelector('.article'),
    NodeFilter.SHOW_TEXT,
    { acceptNode(node) {
      if (!node.nodeValue || !/\[(論文|統合|提案)\]/.test(node.nodeValue)) return NodeFilter.FILTER_REJECT;
      if (node.parentElement?.closest('code, pre, a, script, style')) return NodeFilter.FILTER_REJECT;
      return NodeFilter.FILTER_ACCEPT;
    }}
  );
  const textNodes = [];
  while (walker.nextNode()) textNodes.push(walker.currentNode);
  textNodes.forEach((node) => {
    const fragment = document.createDocumentFragment();
    const parts = node.nodeValue.split(/(\[(?:論文|統合|提案)\])/g);
    parts.forEach((part) => {
      const config = tokens.get(part);
      if (!config) {
        fragment.appendChild(document.createTextNode(part));
        return;
      }
      const chip = document.createElement('span');
      chip.className = `type-chip ${config[0]}`;
      chip.textContent = part.slice(1, -1);
      chip.title = config[1];
      fragment.appendChild(chip);
    });
    node.replaceWith(fragment);
  });

  const tocLinks = [...document.querySelectorAll('#TOC a[href^="#"]')];
  const linkById = new Map(tocLinks.map((link) => [decodeURIComponent(link.hash.slice(1)), link]));
  const headings = [...document.querySelectorAll('.article h2[id], .article h3[id]')];
  if ('IntersectionObserver' in window && headings.length) {
    const observer = new IntersectionObserver((entries) => {
      const visible = entries
        .filter((entry) => entry.isIntersecting)
        .sort((a, b) => a.boundingClientRect.top - b.boundingClientRect.top)[0];
      if (!visible) return;
      tocLinks.forEach((link) => link.classList.remove('is-active'));
      const link = linkById.get(visible.target.id);
      if (link) link.classList.add('is-active');
    }, { rootMargin: '-18% 0px -70% 0px', threshold: [0, 1] });
    headings.forEach((heading) => observer.observe(heading));
  }
})();
