(function () {
  function text(path, value) {
    document.querySelectorAll('[data-portal="' + path + '"]').forEach(function (node) {
      node.textContent = value || node.textContent;
    });
  }

  function link(label, href, secondary) {
    var a = document.createElement('a');
    a.className = 'button' + (secondary ? ' secondary' : '');
    a.href = href || '#';
    a.textContent = label || 'Open';
    return a;
  }

  function render(cfg) {
    cfg = cfg || {};
    var brand = cfg.brand || {};
    text('brand.name', brand.name);
    text('brand.tagline', brand.tagline);
    text('brand.description', brand.description);
    text('footer', cfg.footer || 'MERIT Powered');
    if (brand.name) document.title = brand.name + ' Portal';

    var ctas = document.getElementById('portal-ctas');
    (cfg.ctas || []).forEach(function (cta, idx) {
      ctas.appendChild(link(cta.label, cta.href, idx > 0));
    });

    var cards = document.getElementById('provider-cards');
    (cfg.providers || []).forEach(function (provider) {
      var card = document.createElement('article');
      card.className = 'card';
      var href = provider.href || cfg.appBaseUrl || '#';
      card.innerHTML =
        '<h3></h3><p></p><a></a>';
      card.querySelector('h3').textContent = provider.name || 'MERIT provider';
      card.querySelector('p').textContent = provider.summary || '';
      card.querySelector('a').href = href;
      card.querySelector('a').textContent = provider.statusPath ? 'Open ' + provider.statusPath : 'Open';
      cards.appendChild(card);
    });

    var notes = document.getElementById('portal-notes');
    (cfg.notes || []).forEach(function (note) {
      var li = document.createElement('li');
      li.textContent = note;
      notes.appendChild(li);
    });
  }

  fetch('portal.json', { cache: 'no-store' })
    .then(function (res) { return res.json(); })
    .then(render)
    .catch(function () { render({}); });
})();

