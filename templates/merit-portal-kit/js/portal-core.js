
  function normalizePortalCfg(portal) {
    if (!portal || typeof portal !== 'object') return portal;
    if (portal.marque && !portal.floor_pulse) portal.floor_pulse = portal.marque;
    if (portal.floor_pulse && !portal.marque) portal.marque = portal.floor_pulse;
    return portal;
  }

  function renderCtasFromConfig(portal) {
    var ctas = (portal && portal.ctas) || {};
    var copy = ((portal && portal.marque) || (portal && portal.floor_pulse) || {}).copy || {};
    var stack = document.querySelector(ctas.slots && ctas.slots.stack || '#cta-stack') || document.getElementById('cta-stack');
    var primary = document.querySelector(ctas.slots && ctas.slots.primary || '#cta-primary') || document.getElementById('cta-primary');
    var prompt = document.querySelector(ctas.slots && ctas.slots.prompt || '#cta-prompt') || document.getElementById('cta-prompt');
    if (!primary && !prompt && !stack) return;
    var layout = ctas.layout || 'pair_plus_prompt';
    var items = (ctas.items || []).filter(function (it) { return it && it.enabled !== false; });
    if (!items.length) {
      var defId = ctas.default || 'try';
      items = [{ id: defId, label: copy.ctaPrimary || 'Try it Out', hrefKey: defId, placement: 'primary', style: 'solid', enabled: true }];
    }
    items = items.slice(0, ctas.max || 3);
    items.sort(function (a, b) { return (a.order || 0) - (b.order || 0); });

    function makeCta(it, extraClass) {
      var a = document.createElement('a');
      a.className = 'cta ' + (it.style === 'solid' ? 'solid' : 'ghost') + (extraClass ? ' ' + extraClass : '');
      a.setAttribute('data-cta', it.hrefKey || it.id);
      a.textContent = it.label || it.id;
      a.href = '#';
      return a;
    }

    if (stack) {
      var st = ctas.stack || {};
      if (st.maxWidth) stack.style.maxWidth = st.maxWidth;
      if (st.gap) stack.style.gap = st.gap;
      var pr = ctas.prompt || {};
      if (pr.matchPrimaryWidth !== false) stack.style.width = '100%';
      var justify = pr.align === 'start' ? 'flex-start' : pr.align === 'end' ? 'flex-end' : 'space-between';
      stack.style.setProperty('--cta-prompt-justify', justify);
      stack.setAttribute('data-cta-layout', layout);
    }

    if (layout === 'primary_only') {
      var only = items.filter(function (it) { return it.id === (ctas.default || items[0].id); })[0] || items[0];
      items = only ? [only] : items.slice(0, 1);
      layout = 'stack';
    }

    if (layout === 'triple_row' || layout === 'stack') {
      if (primary) {
        primary.innerHTML = '';
        primary.className = layout === 'stack' ? 'cta-row cta-row--stack' : 'cta-row cta-row--triple';
        if (layout === 'triple_row') {
          primary.style.gridTemplateColumns = 'repeat(' + Math.min(items.length, 3) + ', 1fr)';
        } else {
          primary.style.gridTemplateColumns = '1fr';
        }
        items.forEach(function (it) { primary.appendChild(makeCta(it)); });
      }
      if (prompt) prompt.innerHTML = '';
      return;
    }

    // pair_plus_prompt (default)
    if (primary) {
      primary.innerHTML = '';
      primary.className = 'cta-row';
      primary.style.gridTemplateColumns = '';
      var primaries = items.filter(function (it) { return (it.placement || 'primary') === 'primary'; });
      var cols = (ctas.primary && ctas.primary.columns) || Math.max(primaries.length, 1);
      primary.style.gridTemplateColumns = 'repeat(' + cols + ', 1fr)';
      primaries.forEach(function (it) { primary.appendChild(makeCta(it)); });
    }
    if (prompt) {
      prompt.innerHTML = '';
      prompt.style.justifyContent = 'var(--cta-prompt-justify, space-between)';
      var login = items.filter(function (it) { return it.placement === 'prompt'; })[0];
      if (login) {
        var span = document.createElement('span');
        var key = login.promptCopyKey || 'loginPrompt';
        span.textContent = login.promptText || copy[key] || 'If you already have an account...';
        span.setAttribute('data-copy', key);
        prompt.appendChild(span);
        prompt.appendChild(makeCta(login, 'cta-login'));
      }
    }
  }

/**
 * M4FI portal idea engine — config-driven theme + copy + tier ladder.
 * CTAs are absolute links to Vercel app/ (Approach A'). Never calls register APIs.
 */
(function () {
  function resolveAppBase(cfg) {
    if (window.M4FI_APP_BASE) return String(window.M4FI_APP_BASE).replace(/\/$/, '');
    if (cfg && cfg.appBaseUrl) return String(cfg.appBaseUrl).replace(/\/$/, '');
    return 'https://m4fi.vercel.app';
  }

  var APP = resolveAppBase(null);

  function appUrl(path) {
    if (typeof window.M4FI_appUrl === 'function') return window.M4FI_appUrl(path);
    var p = String(path || '').replace(/^\//, '');
    if (p.indexOf('app/') !== 0) p = 'app/' + p;
    return APP + '/' + p;
  }

  function $(sel, root) {
    return (root || document).querySelector(sel);
  }

  function $all(sel, root) {
    return Array.prototype.slice.call((root || document).querySelectorAll(sel));
  }

  function applyTheme(theme, brand) {
    var root = document.documentElement;
    var colors = theme.colors || {};
    var sizes = theme.sizes || {};
    var fonts = theme.fonts || {};
    Object.keys(colors).forEach(function (k) {
      root.style.setProperty('--c-' + k, colors[k]);
    });
    Object.keys(sizes).forEach(function (k) {
      root.style.setProperty('--s-' + k, sizes[k]);
    });
    if (fonts.display) root.style.setProperty('--f-display', fonts.display);
    if (fonts.body) root.style.setProperty('--f-body', fonts.body);
    if (fonts.mono) root.style.setProperty('--f-mono', fonts.mono);

    var wm = theme.watermark || {};
    var bannerSrc =
      (brand && brand.banner) ||
      wm.src ||
      (theme.brandAssets && theme.brandAssets.banner) ||
      'img/banner.jpg';
    root.style.setProperty('--wm-url', 'url("' + bannerSrc + '")');
    root.style.setProperty('--wm-opacity', String(wm.opacity != null ? wm.opacity : 0.14));
    root.style.setProperty('--wm-blend', wm.blend || 'soft-light');
    root.style.setProperty('--wm-size', wm.size || 'min(52vw, 28rem)');
    root.style.setProperty('--wm-position', wm.position || 'right center');

    var logoSrc =
      (brand && brand.logo) ||
      (theme.brandAssets && theme.brandAssets.logo) ||
      'img/logo.jpg';
    $all('[data-brand-logo]').forEach(function (img) {
      img.setAttribute('src', logoSrc);
      img.addEventListener(
        'error',
        function () {
          img.hidden = true;
        },
        { once: true }
      );
    });

    if (theme.bodyClass) document.body.classList.add(theme.bodyClass);
  }

  /** Resolve logo/banner under portal/logo — banner falls back to logo.jpg */
  function resolveBrandAssets(cfg, done) {
    var assets = (cfg && cfg.theme && cfg.theme.brandAssets) || {};
    var wm = (cfg && cfg.theme && cfg.theme.watermark) || {};
    var logo = assets.logo || 'img/logo.jpg';
    var banner = assets.banner || wm.src || 'img/banner.jpg';
    var fallback = wm.fallback || logo;
    var probe = new Image();
    probe.onload = function () {
      done({ logo: logo, banner: banner });
    };
    probe.onerror = function () {
      done({ logo: logo, banner: fallback });
    };
    probe.src = banner;
  }

  function ensureFontLink(href) {
    if (!href) return;
    var exists = Array.prototype.some.call(document.querySelectorAll('link[rel="stylesheet"]'), function (l) {
      return l.href === href || l.getAttribute('href') === href;
    });
    if (exists) return;
    var link = document.createElement('link');
    link.rel = 'stylesheet';
    link.href = href;
    document.head.appendChild(link);
  }

  function flankSvgMarkup(side) {
    var mirror = side === 'right' ? ' wordmark-flank--mirror' : '';
    return (
      '<svg class="wordmark-flank' +
      mirror +
      '" data-brand-flank="' +
      side +
      '" viewBox="0 0 48 48" width="40" height="40" aria-hidden="true" focusable="false">' +
      '<path d="M6 36 L18 24 L28 30 L42 12" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"/>' +
      '<circle cx="42" cy="12" r="3.2" fill="currentColor"/>' +
      '<path d="M6 36 H42" fill="none" stroke="currentColor" stroke-opacity="0.28" stroke-width="1.4" stroke-linecap="round"/>' +
      '</svg>'
    );
  }

  function applyWordmark(brandDef) {
    var wm = (brandDef && brandDef.wordmark) || {};
    var font = wm.font || {};
    if (font.google_css) ensureFontLink(font.google_css);
    if (font.stack) document.documentElement.style.setProperty('--f-wordmark', font.stack);
    if (font.letter_spacing) {
      document.documentElement.style.setProperty('--wordmark-tracking', font.letter_spacing);
    }
    // Heal stale <img src="img/flank.svg"> previews into inline SVG
    $all('[data-brand-flank]').forEach(function (el) {
      if (el.tagName !== 'IMG') return;
      var side = el.getAttribute('data-brand-flank') || 'left';
      el.insertAdjacentHTML('afterend', flankSvgMarkup(side));
      el.parentNode.removeChild(el);
    });
    var flanks = wm.flanks || {};
    var left = flanks.left || {};
    var right = flanks.right || {};
    $all('[data-brand-flank="left"]').forEach(function (node) {
      node.classList.toggle('wordmark-flank--mirror', !!left.mirror);
    });
    $all('[data-brand-flank="right"]').forEach(function (node) {
      node.classList.toggle('wordmark-flank--mirror', right.mirror !== false);
    });
  }

  function loadBrandDefinition(done) {
    if (window.__M4FI_PORTAL && window.__M4FI_PORTAL.brand) {
      done(window.__M4FI_PORTAL.brand);
      return;
    }
    fetch('portal.json')
      .then(function (r) {
        return r.ok ? r.json() : null;
      })
      .then(function (portal) {
        done((portal && portal.brand) || null);
      })
      .catch(function () {
        done(null);
      });
  }

  function injectCopy(copy) {
    // User SSOT: plans CTA label (never "Official plan matrix")
    if (copy && (!copy.plansBtn || /official plan matrix/i.test(String(copy.plansBtn)))) {
      copy.plansBtn = 'Full subscription details';
    }
    // Prefer ASCII/entity footer — Design Mode and some hosts mojibake raw UTF-8 symbols
    if (copy && !copy.footerNoteHtml) {
      var note = copy.footerNote || '(c) 2026 M4FI | Cloud Centric Security First | Powered by MERIT';
      copy.footerNoteHtml = String(note)
        .replace(/\u00a9/g, '&copy;')
        .replace(/\u00c2\u00a9/g, '&copy;')
        .replace(/\u00b7/g, ' &middot; ')
        .replace(/\u00c2\u00b7/g, ' &middot; ')
        .replace(/\s+/g, ' ')
        .trim();
    }
    $all('[data-copy]').forEach(function (el) {
      var key = el.getAttribute('data-copy');
      if (key === 'footerNote') return; // use footerNoteHtml only
      if (copy[key] != null) el.textContent = copy[key];
    });
    var plansBtn = $('#btn-plans');
    if (plansBtn) plansBtn.textContent = (copy && copy.plansBtn) || 'Full subscription details';
    $all('[data-copy-html]').forEach(function (el) {
      var key = el.getAttribute('data-copy-html');
      if (copy[key] != null) el.innerHTML = copy[key];
    });
    var statusBtn = $('#status-float');
    if (statusBtn) statusBtn.textContent = '';
    paintMarquee(copy && copy.marquee);
    renderCtasFromConfig(window.__M4FI_PORTAL || { marque: { copy: copy }, ctas: window.__M4FI_CTAS });
  }

  var MARQUEE_FALLBACK = [
    'X-ray insight',
    'Predictable small gains',
    'Compound slow & steady',
    'Financial independence',
    'You control the path',
    'Set your financial pathway',
    'Systemic investment + trading',
  ];

  function paintMarquee(items) {
    var track = $('#marquee-track');
    if (!track) return;
    var list = Array.isArray(items) && items.length ? items : MARQUEE_FALLBACK;
    var parts = list.concat(list);
    track.innerHTML = parts
      .map(function (t) {
        return '<span>' + String(t) + '</span>';
      })
      .join('');
  }

  function wireCtas() {
    $all('[data-cta="try"]').forEach(function (a) {
      a.setAttribute('href', appUrl('workbench.html'));
    });
    $all('[data-cta="join"]').forEach(function (a) {
      a.setAttribute('href', appUrl('login.html?register=1'));
    });
    $all('[data-cta="upgrade"]').forEach(function (a) {
      a.setAttribute('href', appUrl('upgrade.html'));
    });
    $all('[data-cta="login"]').forEach(function (a) {
      a.setAttribute('href', appUrl('login.html'));
    });
    // Secrets / status are never marketing CTAs — deep links land inside the app shell.
    $all('[data-cta="secrets"]').forEach(function (a) {
      a.setAttribute('href', appUrl('workbench.html#advanced'));
    });
    $all('[data-cta="status"]').forEach(function (a) {
      a.setAttribute('href', appUrl('workbench.html#status'));
    });
  }

  function pollHealth(appBase) {
    var btn = $('#status-float');
    if (!btn) return;
    var base = String(appBase || APP || 'https://m4fi.vercel.app').replace(/\/$/, '');
    function setState(state, title) {
      btn.className = 'status-float status-float--' + state;
      btn.textContent = '';
      btn.title = title || 'Service status';
      btn.setAttribute('aria-label', title || 'Service status');
    }
    function tick() {
      fetch(base + '/status?view=json&section=health', { credentials: 'omit' })
        .then(function (r) {
          return r.json().then(function (j) {
            return { ok: r.ok, j: j };
          });
        })
        .then(function (pack) {
          var h = (pack.j && (pack.j.section || (pack.j.sections && pack.j.sections.health) || pack.j)) || {};
          var st = String(h.status || h.state || (pack.ok ? 'ok' : 'down')).toLowerCase();
          if (st === 'ok' || st === 'healthy' || st === 'up') {
            setState('ok', 'Service healthy');
          } else if (st === 'degraded' || st === 'warn' || st === 'warning') {
            setState('warn', 'Service degraded');
          } else if (pack.ok && !h.status) {
            setState('ok', 'Service reachable');
          } else {
            setState('down', 'Service unavailable');
          }
        })
        .catch(function () {
          setState('down', 'Service unreachable');
        });
    }
    tick();
    setInterval(tick, 60000);
  }

  function renderLadder(data, currentId) {
    if (window.M4FIPathway && typeof window.M4FIPathway.render === 'function') {
      return window.M4FIPathway.render(data, currentId, { wireCtas: wireCtas });
    }
    var mount = $('#tier-ladder');
    if (mount) mount.innerHTML = '<p class="ladder-error">Load js/portal-pathway.js</p>';
  }

  function gainsForRow(row) {
    if (window.M4FIPathway && window.M4FIPathway.gainsForRow) {
      return window.M4FIPathway.gainsForRow(row);
    }
    return [];
  }

  function boot(cfg) {
    APP = resolveAppBase(cfg);
    window.M4FI_APP_BASE = APP;
    loadBrandDefinition(function (brandDef) {
      window.M4FI_BRAND_DEF = brandDef;
      if (brandDef) applyWordmark(brandDef);
      resolveBrandAssets(cfg, function (brand) {
        window.M4FI_BRAND = brand;
        applyTheme(cfg.theme || {}, brand);
        injectCopy(cfg.copy || {});
        wireCtas();
        finishBoot(cfg);
      });
    });
  }

  function finishBoot(cfg) {
    var tryBtn = $('#cta-try-expand');
    var panel = $('#path-panel');
    if (tryBtn && panel) {
      tryBtn.addEventListener('click', function () {
        var open = panel.classList.toggle('open');
        tryBtn.setAttribute('aria-expanded', open ? 'true' : 'false');
      });
    }

    var plansBtn = $('#btn-plans');
    var plansDlg = $('#plans-dialog');
    if (plansBtn && plansDlg) {
      plansBtn.addEventListener('click', function () {
        if (typeof plansDlg.showModal === 'function') plansDlg.showModal();
        else plansDlg.setAttribute('open', '');
      });
      var close = $('#plans-close');
      if (close) {
        close.addEventListener('click', function () {
          if (typeof plansDlg.close === 'function') plansDlg.close();
          else plansDlg.removeAttribute('open');
        });
      }
    }

    function applyLadder(data) {
      var mount = $('#tier-ladder');
      if (!data) {
        if (window.M4FIPaintLadder && window.M4FIPaintLadder('free')) return;
        if (mount) mount.innerHTML = '<p class="ladder-error">Tier ladder unavailable.</p>';
        return;
      }
      try {
        renderLadder(data, cfg.defaultTier || (cfg.pathway && cfg.pathway.default_current) || data.default_current);
        wireCtas();
      } catch (err) {
        if (window.M4FIPaintLadder) window.M4FIPaintLadder(cfg.defaultTier || (cfg.pathway && cfg.pathway.default_current) || data.default_current || 'free');
      }
    }

    // Prefer inline SSOT (defeats CDN/preview cache of stale ladder)
    var embedded = null;
    var embEl = document.getElementById('m4fi-tier-ladder-data');
    if (embEl && embEl.textContent) {
      try {
        embedded = JSON.parse(embEl.textContent);
      } catch (e) {
        embedded = null;
      }
    }
    if (!embedded && window.M4FI_TIER_LADDER) embedded = window.M4FI_TIER_LADDER;
    if (embedded) {
      applyLadder(embedded);
      return;
    }

    var ladderUrl = cfg.tierLadderUrl || 'portal.json';
    ladderUrl += (ladderUrl.indexOf('?') < 0 ? '?' : '&') + 'v=' + Date.now();
    fetch(ladderUrl)
      .then(function (r) {
        return r.json();
      })
      .then(function (j) {
        applyLadder((j && j.tier_ladder) ? j.tier_ladder : j);
      })
      .catch(function () {
        applyLadder(null);
      });
  }

  // Eager wire any static fallbacks already in DOM
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', wireCtas);
  } else {
    wireCtas();
  }

  window.M4FIPortalIdea = {
    boot: boot,
    appUrl: appUrl,
    wireCtas: wireCtas,
    pollHealth: pollHealth,
    paintMarquee: paintMarquee,
    gainsForRow: gainsForRow,
    renderLadder: renderLadder,
    pathway: function () { return window.M4FIPathway; },
  };
})();
