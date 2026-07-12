/** Approach A' — surface config for marketing (here.now) vs app (Vercel). */

(function (global) {

  var cfg = global.M4FI_SURFACE_CFG || {};

  var host = (global.location && global.location.hostname) || '';

  var isLocal = host === '127.0.0.1' || host === 'localhost';

  var appBase =

    cfg.appBaseUrl ||

    (isLocal ? global.location.origin : 'https://m4fi.vercel.app');

  var marketingBase =

    cfg.marketingBaseUrl ||

    (isLocal ? global.location.origin + '/portal' : 'https://pearly-vision-67p6.here.now');

  global.M4FI_APP_BASE = String(appBase).replace(/\/$/, '');

  global.M4FI_MARKETING_BASE = String(marketingBase).replace(/\/$/, '');

  global.M4FI_SURFACE = cfg.surface || 'marketing';

  global.M4FI_appUrl = function (path) {

    var p = String(path || '').replace(/^\//, '');

    if (p.indexOf('app/') !== 0) p = 'app/' + p;

    return global.M4FI_APP_BASE + '/' + p;

  };

})(typeof window !== 'undefined' ? window : globalThis);


