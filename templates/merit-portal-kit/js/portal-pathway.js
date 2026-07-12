/**
 * MERIT portal pathway — pills + now/next/next2 from portal.json tier_ladder.
 * Bullets come only from tier JSON (now_gains / synthesized fields). No product invention.
 * Contract: portal.json → pathway + tier_ladder (FR-070 / FR-072).
 */
(function () {
  function $(sel, root) {
    return (root || document).querySelector(sel);
  }
  function $all(sel, root) {
    return Array.prototype.slice.call((root || document).querySelectorAll(sel));
  }

function findTier(ladder, currentId) {
  var idx = 0;
  for (var i = 0; i < ladder.length; i++) {
    if (ladder[i].id === currentId) {
      idx = i;
      break;
    }
  }
  return { current: ladder[idx], next: ladder[idx + 1] || null, next2: ladder[idx + 2] || null, idx: idx };
}

function esc(s) {
  return String(s == null ? '' : s)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

function sanitizeGainText(s) {
  return String(s || '')
    .replace(/\s*\(was\s+\d+\)\s*/gi, '')
    .replace(/^scheduled broker sync$/i, 'regularly syncs with your broker')
    .replace(/^(\d+)\s+on-demand refresh\s*\/\s*hr$/i, '$1 refresh/hr + on-demand')
    .replace(/^Decide AI$/i, 'Decide w/AI')
    .replace(/^symbol packs\s*\(\+?\d+\)$/i, '+5 add-on packs')
    .replace(/^\$([\d.]+)\/wk intro$/i, '$$$1/week intro price')
    .trim();
}

function formatGain(g) {
  if (g == null) return '';
  if (typeof g === 'string') {
    var cleaned = sanitizeGainText(g);
    if (/^unlimited symbols$/i.test(cleaned)) return esc('unlimited symbols');
    var introOnly = cleaned.match(/^\$([\d.]+)\/week intro price$/i);
    if (introOnly) {
      return formatGain({ kind: 'price', intro: cleaned });
    }
    var sym = cleaned.match(/^(\d+)\s+symbols$/i);
    // Paid tiers with packs (not freemium's 2): show add-on packs link
    if (sym && [7, 15, 25].indexOf(parseInt(sym[1], 10)) >= 0) {
      return formatGain({
        text: sym[1] + ' symbols',
        link_label: '+5 add-on packs',
        href: 'https://m4fi.vercel.app/app/upgrade.html#symbol-packs',
      });
    }
    if (/^\+?\d+\s+add-on packs$/i.test(cleaned) || cleaned === '+5 add-on packs') {
      return (
        '<a class="tier-addon-link" href="https://m4fi.vercel.app/app/upgrade.html#symbol-packs" target="_blank" rel="noopener noreferrer">' +
        esc(cleaned.indexOf('+') === 0 ? cleaned : '+5 add-on packs') +
        '</a>'
      );
    }
    return esc(cleaned);
  }
  if (g.kind === 'price') {
    var html = '';
    if (g.regular) {
      html += '<s class="tier-price-was">' + esc(g.regular) + '</s> ';
    }
    html += '<span class="tier-price-intro">' + esc(g.intro || '') + '</span>';
    return html;
  }
  var text = esc(sanitizeGainText(g.text || ''));
  if (g.link_label && g.href) {
    return (
      text +
      ' (<a class="tier-addon-link" href="' +
      esc(g.href) +
      '" target="_blank" rel="noopener noreferrer">' +
      esc(g.link_label) +
      '</a>)'
    );
  }
  return text;
}

function formatGainPlain(g) {
  if (g == null) return '';
  if (typeof g === 'string') return sanitizeGainText(g);
  if (g.kind === 'price') {
    return (g.regular ? g.regular + ' → ' : '') + (g.intro || '');
  }
  if (g.link_label) return sanitizeGainText(g.text || '') + ' (' + g.link_label + ')';
  return sanitizeGainText(g.text || '');
}

function freeNowGainsFallback() {
  return [
    'free forever',
    'no registration required',
    'Come back with handle + pass-phrase - this device only, no email or phone',
  ];
}

function synthesizeNowGains(row) {
  var out = [];
  if (row.intro_week != null && row.std_week != null) {
    out.push({
      kind: 'price',
      regular: '$' + Number(row.std_week).toFixed(2).replace(/\.00$/, '') + '/week',
      intro: '$' + Number(row.intro_week).toFixed(2).replace(/\.00$/, '') + '/week intro price',
    });
  } else if (row.price_label) {
    out.push({ kind: 'price', intro: row.price_label });
  }
  var sym = row.symbols == null ? 0 : Number(row.symbols);
  if (sym <= 0) {
    out.push('unlimited symbols');
  } else if (row.packs) {
    out.push({
      text: sym + ' symbols',
      link_label: '+5 add-on packs',
      href: 'https://m4fi.vercel.app/app/upgrade.html#symbol-packs',
    });
  } else {
    out.push(sym + ' symbols');
  }
  if (row.sync_min) out.push('regularly syncs with your broker');
  if (row.refresh_hr) out.push(row.refresh_hr + ' refresh/hr + on-demand');
  if (row.ask_ai) out.push('Ask AI');
  if (row.decide_ai) out.push('Decide w/AI');
  // Trade w/Agents is T4+ only (Subscription Tiers.xlsx / plans.jpg)
  if (row.id === 'ai_wizard_standard' || row.id === 'ai_wizard_pro') {
    out.push('Trade with Agents');
  }
  return out;
}

/** Absolute bullets for any tier column — never empty for paid/freemium rows. */
function gainsForRow(row) {
  if (!row) return [];
  if (row.id === 'free') {
    if (row.now_gains && row.now_gains.length) return row.now_gains;
    return freeNowGainsFallback();
  }
  // Always synthesize from entitlement fields so is-now never depends on
  // precomputed now_gains/next_gains (those were empty in older ladder JSON).
  var synth = synthesizeNowGains(row);
  if (synth.length) return synth;
  if (row.now_gains && row.now_gains.length) return row.now_gains;
  if (row.price_label) return [{ kind: 'price', intro: row.price_label }];
  return ['See Full subscription details'];
}

function gainsListHtml(gains) {
  return (
    '<ul>' +
    (gains || [])
      .map(function (g) {
        return '<li>' + formatGain(g) + '</li>';
      })
      .join('') +
    '</ul>'
  );
}

function renderLadder(data, currentId, opts) {
  var _opts = opts || {};
  var pathCfg = (window.__M4FI_PORTAL && window.__M4FI_PORTAL.pathway) || {};
  if (pathCfg.enabled === false) {
    var sec = document.getElementById('tiers');
    if (sec) sec.hidden = true;
    return;
  }
  var pillsSel = (pathCfg.mounts && pathCfg.mounts.pills) || '#tier-steps';
  var colsSel = (pathCfg.mounts && pathCfg.mounts.columns) || '#tier-ladder';
  var mount = $(colsSel);
  if (!mount || !data || !data.ladder) return;
  var pack = findTier(data.ladder, currentId || data.default_current || 'free');
  var cur = pack.current;
  var layout = mount.getAttribute('data-layout') || 'cards';
  var html = '';
  var nowGains = gainsForRow(cur);
  var nextGains = pack.next ? gainsForRow(pack.next) : [];
  var next2Gains = pack.next2 ? gainsForRow(pack.next2) : [];

  if (layout === 'timeline') {
    html += '<ol class="tier-timeline">';
    // Absolute bullets only — same gainsForRow() whether this tier is now/next/next2.
    // No <em>price_label</em> (price lives in the bullet list so columns match).
    html +=
      '<li class="is-now" data-tier-id="' +
      esc(cur.id) +
      '"><span class="tl-badge">' +
      (cur.badge || '') +
      '</span><strong>' +
      cur.title +
      '</strong>' +
      gainsListHtml(nowGains) +
      '</li>';
    if (pack.next) {
      html +=
        '<li class="is-next" data-tier-id="' +
        esc(pack.next.id) +
        '"><span class="tl-badge">' +
        (pack.next.badge || '') +
        '</span><strong>' +
        pack.next.title +
        '</strong>' +
        gainsListHtml(nextGains) +
        '</li>';
    }
    if (pack.next2) {
      html +=
        '<li class="is-next2" data-tier-id="' +
        esc(pack.next2.id) +
        '"><span class="tl-badge">' +
        (pack.next2.badge || '') +
        '</span><strong>' +
        pack.next2.title +
        '</strong>' +
        gainsListHtml(next2Gains) +
        '</li>';
    }
    html += '</ol>';
  } else if (layout === 'console') {
    html += '<pre class="console-ladder" tabindex="0">';
    html +=
      'YOU  ' +
      (cur.badge || '') +
      '  ' +
      cur.title +
      '  |  ' +
      (cur.price_label || '-') +
      '  |  symbols=' +
      cur.symbols +
      '\n';
    if (pack.next) {
      html +=
        'NEXT ' +
        (pack.next.badge || '') +
        '  ' +
        pack.next.title +
        '\n     + ' +
        nextGains.map(formatGainPlain).join('\n     + ') +
        '\n';
    }
    if (pack.next2) {
      html +=
        '++   ' +
        (pack.next2.badge || '') +
        '  ' +
        pack.next2.title +
        '\n     + ' +
        next2Gains.map(formatGainPlain).join('\n     + ') +
        '\n';
    }
    html += '</pre>';
  } else {
    html += '<div class="ladder-now" aria-current="true">';
    html += '<p class="ladder-kicker">You are here</p>';
    html += '<h3>' + (cur.badge ? cur.badge + ' · ' : '') + cur.title + '</h3>';
    html +=
      '<p class="ladder-meta">' +
      (cur.price_label || '—') +
      ' · ' +
      cur.symbols +
      ' symbol' +
      (cur.symbols === 1 ? '' : 's') +
      '</p>';
    html += gainsListHtml(nowGains);
    html += '</div>';
    if (pack.next) {
      html += '<div class="ladder-next">';
      html += '<p class="ladder-kicker">Next level</p>';
      html += '<h3>' + (pack.next.badge ? pack.next.badge + ' · ' : '') + pack.next.title + '</h3>';
      html += gainsListHtml(nextGains);
      html += '</div>';
    }
    if (pack.next2) {
      html += '<div class="ladder-next2">';
      html += '<p class="ladder-kicker">Two levels up</p>';
      html +=
        '<h3>' + (pack.next2.badge ? pack.next2.badge + ' · ' : '') + pack.next2.title + '</h3>';
      html += gainsListHtml(next2Gains);
      html += '</div>';
    }
  }
  mount.innerHTML = html;

  // Belt: if any timeline column rendered without bullets, force-fill from fields
  $all('.tier-timeline > li', mount).forEach(function (col) {
    var ul = col.querySelector('ul');
    if (ul && ul.children.length) return;
    var badge = (col.querySelector('.tl-badge') || {}).textContent || '';
    var tier = null;
    for (var i = 0; i < data.ladder.length; i++) {
      if (data.ladder[i].badge === badge) {
        tier = data.ladder[i];
        break;
      }
    }
    if (!tier) return;
    var fill = gainsListHtml(gainsForRow(tier));
    if (ul) ul.outerHTML = fill;
    else col.insertAdjacentHTML('beforeend', fill);
  });

  var steps = $(pillsSel);
  if (steps) {
    steps.innerHTML = data.ladder
      .map(function (t, i) {
        var on = i === pack.idx ? ' is-current' : i === pack.idx + 1 ? ' is-next' : '';
        return (
          '<button type="button" class="tier-step' +
          on +
          '" data-tier="' +
          t.id +
          '" aria-pressed="' +
          (i === pack.idx) +
          '">' +
          (t.badge || '') +
          '<span>' +
          t.title.replace(/\(.*?\)/g, '').trim() +
          '</span></button>'
        );
      })
      .join('');
    $all('.tier-step', steps).forEach(function (btn) {
      btn.addEventListener('click', function () {
        // Always re-render from absolute gainsForRow — never delta next_gains
        renderLadder(data, btn.getAttribute('data-tier'), _opts);
        if (_opts && typeof _opts.wireCtas === 'function') _opts.wireCtas();
        if (window.M4FIHealLadder) window.M4FIHealLadder();
      });
    });
  }
  window.M4FI_LADDER_DATA = data;
  window.M4FI_LADDER_CURRENT = cur.id;
}


  window.M4FIPathway = {
    render: renderLadder,
    gainsForRow: gainsForRow,
    findTiers: findTiers,
    formatGain: formatGain,
  };
})();
