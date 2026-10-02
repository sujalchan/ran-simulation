/* Navigation and search for the static RAN Network Simulator documentation. */
(() => {
  'use strict';

  const { pages, scripts, events, navigation, h } = window.DOCS_DATA;
  const byId = new Map(pages.map((page) => [page.id, page]));
  const navIds = navigation.flatMap((group) => group.ids);
  const $ = (selector) => document.querySelector(selector);
  const sidebarNav = $('#sidebarNav');
  const article = $('#article');
  const breadcrumb = $('#breadcrumb');
  const toc = $('#pageToc');
  const neighbors = $('#pageNeighbors');
  const dialog = $('#searchDialog');
  const searchInput = $('#searchInput');
  const searchResults = $('#searchResults');
  const mobileScrim = $('#mobileScrim');
  const mobileQuery = window.matchMedia('(max-width: 820px)');
  const lightMode = $('#lightMode');
  const darkMode = $('#darkMode');
  let selectedResult = 0;
  let visibleResults = [];
  let scrollScheduled = false;
  let chosenTheme = null;

  try {
    const savedTheme = localStorage.getItem('ran-docs-theme');
    if (savedTheme === 'dark' || savedTheme === 'light') chosenTheme = savedTheme;
  } catch (_) { /* The theme switch still works without saved preferences. */ }

  function applyTheme(theme) {
    document.documentElement.dataset.theme = theme;
    lightMode.setAttribute('aria-pressed', String(theme === 'light'));
    darkMode.setAttribute('aria-pressed', String(theme === 'dark'));
    $('meta[name="theme-color"]').content = theme === 'dark' ? '#171719' : '#102f4b';
  }

  for (const [button, theme] of [[lightMode, 'light'], [darkMode, 'dark']]) {
    button.addEventListener('click', () => {
      chosenTheme = theme;
      applyTheme(theme);
      try { localStorage.setItem('ran-docs-theme', theme); } catch (_) { /* Keep this page's choice. */ }
    });
  }
  applyTheme(chosenTheme || 'dark');

  const pathFor = (id, anchor = '') => `#/${id}${anchor ? `@${anchor}` : ''}`;
  const routeFromHash = () => {
    const raw = decodeURIComponent(window.location.hash.slice(2) || 'overview');
    const separator = raw.indexOf('@');
    return separator < 0 ? { id: raw, anchor: '' } : { id: raw.slice(0, separator), anchor: raw.slice(separator + 1) };
  };

  function renderSidebar() {
    sidebarNav.innerHTML = navigation.map((group) => {
      const links = group.ids.map((id) => {
        const page = byId.get(id);
        return `<a class="nav-link" data-nav-id="${h(id)}" href="${pathFor(id)}">${h(page.title)}</a>`;
      }).join('');
      return `<div class="nav-group"><p class="nav-label">${h(group.label)}</p>${links}</div>`;
    }).join('') + `<div class="nav-group"><p class="nav-label">Individual scripts</p><details class="nav-details" id="scriptNav"><summary>Browse all 32 scripts</summary><div class="nav-nested">${[
      ['material-lab', 'Material lab'],
      ['small-town', 'Small town']
    ].map(([place, label]) => `<details class="nav-details" data-place="${place}"><summary>${label}</summary><div class="nav-nested">${scripts.filter((item) => item.place === place).map((item) => `<a class="nav-link" data-nav-id="script/${h(item.id)}" href="${pathFor(`script/${item.id}`)}">${h(item.name)}</a>`).join('')}</div></details>`).join('')}</div></details></div>`;
  }

  function markSidebar(id) {
    sidebarNav.querySelectorAll('.nav-link').forEach((link) => {
      const active = link.dataset.navId === id;
      link.classList.toggle('active', active);
      if (active) link.setAttribute('aria-current', 'page');
      else link.removeAttribute('aria-current');
    });
    if (id.startsWith('script/')) {
      const item = scripts.find((script) => `script/${script.id}` === id);
      if (item) {
        $('#scriptNav').open = true;
        sidebarNav.querySelector(`[data-place="${item.place}"]`).open = true;
      }
    }
  }

  function renderBreadcrumb(page) {
    if (page.id === 'overview') {
      breadcrumb.innerHTML = '<span class="current">Documentation</span><span class="sep">/</span><span>Overview</span>';
      return;
    }
    const group = page.id.startsWith('script/') ? 'Code reference' : page.group;
    const parent = page.id.startsWith('script/') ? `<a href="#/code-reference">Script index</a><span class="sep">/</span>` : `<span>${h(group)}</span><span class="sep">/</span>`;
    breadcrumb.innerHTML = `<a href="#/overview">Documentation</a><span class="sep">/</span>${parent}<span class="current">${h(page.title)}</span>`;
  }

  function renderNeighbors(page) {
    const index = navIds.indexOf(page.id);
    if (index < 0) {
      neighbors.innerHTML = `<a class="neighbor-link" href="#/code-reference"><small>Back to reference</small><strong>← All scripts</strong></a>`;
      return;
    }
    const previous = byId.get(navIds[index - 1]);
    const next = byId.get(navIds[index + 1]);
    neighbors.innerHTML = `${previous ? `<a class="neighbor-link" href="${pathFor(previous.id)}"><small>Previous page</small><strong>← ${h(previous.title)}</strong></a>` : '<span></span>'}${next ? `<a class="neighbor-link next" href="${pathFor(next.id)}"><small>Next page</small><strong>${h(next.title)} →</strong></a>` : '<span></span>'}`;
  }

  function renderToc(page) {
    const headings = [...article.querySelectorAll('h2[id]:not([hidden]), h3[id]:not([hidden])')];
    if (!headings.length) {
      toc.innerHTML = '';
      toc.hidden = true;
      return;
    }
    toc.hidden = false;
    toc.innerHTML = `<p>On this page</p>${headings.map((heading) => `<a class="${heading.tagName === 'H3' ? 'toc-sub' : ''}" href="${pathFor(page.id, heading.id)}">${h(heading.textContent)}</a>`).join('')}`;
    updateActiveToc();
  }

  function updateActiveToc() {
    const headings = [...article.querySelectorAll('h2[id]:not([hidden]), h3[id]:not([hidden])')];
    if (!headings.length) return;
    let active = headings[0].id;
    for (const heading of headings) {
      if (heading.getBoundingClientRect().top <= 125) active = heading.id;
      else break;
    }
    toc.querySelectorAll('a').forEach((link) => {
      const selected = link.getAttribute('href').endsWith(`@${active}`);
      link.classList.toggle('active', selected);
      if (selected) link.setAttribute('aria-current', 'location');
      else link.removeAttribute('aria-current');
    });
  }

  function applyScriptFilter(place) {
    article.querySelectorAll('[data-script-place]').forEach((item) => {
      item.hidden = place !== 'all' && item.dataset.scriptPlace !== place;
    });
    article.querySelectorAll('[data-filter]').forEach((button) => {
      const active = button.dataset.filter === place;
      button.classList.toggle('active', active);
      button.setAttribute('aria-pressed', String(active));
    });
    const headings = [$('#material-lab-scripts'), $('#small-town-scripts')];
    headings.forEach((heading) => {
      if (!heading) return;
      heading.hidden = place !== 'all' && (heading.id === 'material-lab-scripts' ? place !== 'material-lab' : place !== 'small-town');
      heading.nextElementSibling.hidden = heading.hidden;
    });
    renderToc(byId.get('code-reference'));
  }

  function renderPage() {
    const { id, anchor } = routeFromHash();
    const page = byId.get(id);
    if (!page) {
      article.innerHTML = `<p class="eyebrow">Documentation</p><h1>Page not found</h1><p class="lede">This documentation route does not exist.</p><p><a href="#/overview">Return to the overview →</a></p>`;
      breadcrumb.innerHTML = '<a href="#/overview">Documentation</a><span class="sep">/</span><span class="current">Page not found</span>';
      toc.innerHTML = '';
      neighbors.innerHTML = '';
      document.title = 'Page not found · RAN Network Simulator Docs';
      $('#topbarPage').textContent = 'Page not found';
      window.scrollTo(0, 0);
      return;
    }

    article.innerHTML = `<p class="eyebrow">${h(page.group)}</p><h1>${h(page.title)}</h1><p class="lede">${h(page.summary)}</p><hr class="article-rule">${page.body()}`;
    document.title = `${page.title} · RAN Network Simulator Docs`;
    $('#topbarPage').textContent = page.title;
    renderBreadcrumb(page);
    renderNeighbors(page);
    renderToc(page);
    markSidebar(id);
    closeMobileNavigation();
    if (id === 'code-reference') applyScriptFilter('all');

    if (anchor) {
      requestAnimationFrame(() => {
        const target = document.getElementById(anchor);
        if (target) target.scrollIntoView({ block: 'start' });
        updateActiveToc();
      });
    } else {
      window.scrollTo(0, 0);
    }
  }

  function closeMobileNavigation() {
    document.body.classList.remove('mobile-nav-open');
    mobileScrim.hidden = true;
    syncMenuButton();
  }

  function syncMenuButton() {
    const expanded = mobileQuery.matches ? document.body.classList.contains('mobile-nav-open') : !document.body.classList.contains('sidebar-collapsed');
    $('#menuToggle').setAttribute('aria-expanded', String(expanded));
  }

  $('#menuToggle').addEventListener('click', () => {
    if (mobileQuery.matches) {
      const opening = !document.body.classList.contains('mobile-nav-open');
      document.body.classList.toggle('mobile-nav-open', opening);
      mobileScrim.hidden = !opening;
    } else {
      const collapsed = document.body.classList.toggle('sidebar-collapsed');
      try { localStorage.setItem('ran-docs-sidebar-collapsed', String(collapsed)); } catch (_) { /* Private mode can disallow storage. */ }
    }
    syncMenuButton();
  });
  $('#sidebarClose').addEventListener('click', closeMobileNavigation);
  mobileScrim.addEventListener('click', closeMobileNavigation);
  $('.skip-link').addEventListener('click', (event) => {
    event.preventDefault();
    $('#main-content').focus();
  });
  mobileQuery.addEventListener('change', () => { closeMobileNavigation(); syncMenuButton(); });
  article.addEventListener('click', (event) => {
    const button = event.target.closest('[data-filter]');
    if (button) applyScriptFilter(button.dataset.filter);
  });
  window.addEventListener('hashchange', renderPage);
  window.addEventListener('scroll', () => {
    if (scrollScheduled) return;
    scrollScheduled = true;
    requestAnimationFrame(() => { updateActiveToc(); scrollScheduled = false; });
  }, { passive: true });

  const normalize = (value) => value.toLowerCase().normalize('NFKD');
  const searchIndex = pages.map((page) => {
    const content = document.createElement('div');
    content.innerHTML = page.body();
    return {
      title: page.title,
      kind: page.id.startsWith('script/') ? 'Script reference' : page.group,
      summary: page.id.startsWith('script/') ? scripts.find((script) => `script/${script.id}` === page.id).path : page.summary,
      href: pathFor(page.id),
      titleText: normalize(page.title),
      tagText: normalize(page.tags.join(' ')),
      bodyText: normalize(content.textContent || '')
    };
  }).concat(events.map((event) => ({
    title: event.name,
    kind: `${event.place} event`,
    summary: event.arguments,
    href: pathFor('events', event.id),
    titleText: normalize(event.name),
    tagText: normalize(`${event.place} ${event.direction}`),
    bodyText: normalize(`${event.purpose} ${event.arguments}`)
  })));

  function scoreResult(item, query) {
    const terms = normalize(query).split(/\s+/).filter(Boolean);
    if (!terms.length) return 0;
    let score = 0;
    for (const term of terms) {
      if (item.titleText === term) score += 80;
      else if (item.titleText.startsWith(term)) score += 45;
      else if (item.titleText.includes(term)) score += 28;
      else if (item.tagText.includes(term)) score += 13;
      else if (item.bodyText.includes(term)) score += 4;
      else return 0;
    }
    if (item.kind === 'Script reference' && terms.some((term) => item.titleText.includes(term))) score += 6;
    return score;
  }

  function renderResults() {
    const query = searchInput.value.trim();
    if (!query) {
      const quickIds = ['overview', 'simulation/signal', 'events', 'code-reference', 'developer-guide'];
      visibleResults = quickIds.map((id) => searchIndex.find((item) => item.href === pathFor(id)));
    } else {
      visibleResults = searchIndex.map((item) => ({ item, score: scoreResult(item, query) }))
        .filter((entry) => entry.score > 0)
        .sort((a, b) => b.score - a.score || a.item.title.localeCompare(b.item.title))
        .slice(0, 8).map((entry) => entry.item);
    }
    selectedResult = 0;
    searchResults.innerHTML = visibleResults.length ? visibleResults.map((item, index) => `<button class="search-result${index === 0 ? ' selected' : ''}" type="button" role="option" aria-selected="${index === 0}" data-result-index="${index}"><small>${h(item.kind)}</small><strong>${h(item.title)}</strong><span>${h(item.summary)}</span></button>`).join('') : '<p class="search-empty">No matching topic, script, or event.</p>';
  }

  function selectResult(index) {
    if (!visibleResults.length) return;
    selectedResult = (index + visibleResults.length) % visibleResults.length;
    searchResults.querySelectorAll('[data-result-index]').forEach((button, buttonIndex) => {
      const selected = buttonIndex === selectedResult;
      button.classList.toggle('selected', selected);
      button.setAttribute('aria-selected', String(selected));
      if (selected) button.scrollIntoView({ block: 'nearest' });
    });
  }

  function openSearch() {
    if (dialog.open) return;
    searchInput.value = '';
    renderResults();
    dialog.showModal();
    searchInput.focus();
  }

  function navigateResult(index) {
    const item = visibleResults[index];
    if (!item) return;
    dialog.close();
    if (window.location.hash === item.href) {
      renderPage();
    } else {
      window.location.hash = item.href;
    }
  }

  $('#searchTrigger').addEventListener('click', openSearch);
  $('#searchClose').addEventListener('click', () => dialog.close());
  searchInput.addEventListener('input', renderResults);
  searchInput.addEventListener('keydown', (event) => {
    if (event.key === 'ArrowDown') { event.preventDefault(); selectResult(selectedResult + 1); }
    if (event.key === 'ArrowUp') { event.preventDefault(); selectResult(selectedResult - 1); }
    if (event.key === 'Enter') { event.preventDefault(); navigateResult(selectedResult); }
  });
  searchResults.addEventListener('click', (event) => {
    const result = event.target.closest('[data-result-index]');
    if (result) navigateResult(Number(result.dataset.resultIndex));
  });
  dialog.addEventListener('click', (event) => { if (event.target === dialog) dialog.close(); });
  document.addEventListener('keydown', (event) => {
    const editing = /^(INPUT|TEXTAREA|SELECT)$/.test(document.activeElement?.tagName || '') || document.activeElement?.isContentEditable;
    if ((event.key.toLowerCase() === 'k' && (event.metaKey || event.ctrlKey)) || (event.key === '/' && !editing && !dialog.open)) {
      event.preventDefault();
      openSearch();
    }
  });

  try {
    if (localStorage.getItem('ran-docs-sidebar-collapsed') === 'true') document.body.classList.add('sidebar-collapsed');
  } catch (_) { /* The navigation still works without saved preferences. */ }
  renderSidebar();
  syncMenuButton();
  renderPage();
})();
