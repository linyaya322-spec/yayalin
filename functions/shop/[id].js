// 商家的公開頁面 yayalin.com/shop/<id> —— 讓已認領的店家有一個可以分享出去的網址（貼在自己的社群、
// LINE 名片等）。伺服器端直接渲染 HTML（同一種做法見 functions/app/s/[token].js 的分享頁），這樣分享出去
// 在 LINE／Messenger 等地方才有正確的預覽（標題、說明），純前端 fetch 渲染做不到這件事。
import { backendBase } from '../_lib/shareProxy.js';
import { categoryLabel } from '../_lib/landmarkCategories.js';

const esc = (v) =>
  String(v ?? '').replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));

const STATUS_LABEL = { open: '營業中', temporarily_closed: '暫停營業', permanently_closed: '已停業' };

function page({ landmark, origin }) {
  const title = `${landmark.name}｜交通即時查 TransitGo`;
  const desc = landmark.description || `${landmark.name} 的地標資訊 —— 交通即時查 TransitGo`;
  const status = landmark.businessVerified ? (STATUS_LABEL[landmark.businessStatus] ?? '營業中') : null;
  const mapsUrl = `https://maps.apple.com/?ll=${landmark.lat},${landmark.lon}&q=${encodeURIComponent(landmark.name)}`;
  const canonical = `${origin}/shop/${landmark.id}`;

  return `<!doctype html>
<html lang="zh-Hant">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="color-scheme" content="light dark">
<title>${esc(title)}</title>
<meta name="description" content="${esc(desc)}">
<link rel="canonical" href="${esc(canonical)}">
<meta property="og:type" content="website">
<meta property="og:site_name" content="交通即時查 TransitGo">
<meta property="og:title" content="${esc(title)}">
<meta property="og:description" content="${esc(desc)}">
<meta name="twitter:card" content="summary">
<link rel="icon" type="image/png" href="/app-assets/app-touch-icon.png">
<style>
:root { color-scheme: light dark; --bg:#fbfdff; --card:#fff; --text:#0e2038; --muted:#57667e; --line:#e2e8f1; --accent:#0a6cf0; --accent-soft:#e6f1ff; }
@media (prefers-color-scheme: dark) { :root { --bg:#0b1626; --card:#101d33; --text:#eef3fa; --muted:#9fb0c6; --line:#24344c; --accent:#4da3ff; --accent-soft:#0a6cf033; } }
* { box-sizing: border-box; }
body { margin:0; background:var(--bg); color:var(--text); font:16px/1.7 -apple-system,"PingFang TC","Noto Sans TC",system-ui,sans-serif; }
main { max-width: 560px; margin: 0 auto; padding: 28px 20px 56px; }
.brand { display:flex; align-items:center; gap:10px; font-weight:800; font-size:17px; text-decoration:none; color:var(--text); margin-bottom: 22px; }
.brand img { width:28px; height:28px; }
.card { background:var(--card); border:1px solid var(--line); border-radius:16px; padding:22px 22px 26px; }
h1 { font-size: 1.5rem; margin: 0 0 6px; }
.category { font-size: 0.85rem; color: var(--muted); margin: 0 0 14px; }
.status { display:inline-block; font-size:0.8rem; font-weight:700; padding:2px 10px; border-radius:999px; margin-bottom:14px; }
.status.open { background:var(--accent-soft); color:var(--accent); }
.status.closed { background:#fde4e2; color:#a82727; }
.row { display:flex; gap:10px; align-items:flex-start; padding: 8px 0; border-top:1px solid var(--line); font-size:0.94rem; }
.row:first-of-type { border-top: none; }
.row b { color: var(--muted); font-weight:600; min-width: 4.5em; flex: none; }
a.tel, a.map { color: var(--accent); font-weight: 600; text-decoration: none; }
.unverified { font-size:0.85rem; color:var(--muted); margin-top:16px; }
footer { text-align:center; margin-top: 22px; font-size: 0.8rem; color: var(--muted); }
footer a { color: var(--accent); }
</style>
</head>
<body>
<main>
  <a class="brand" href="/app"><img src="/app-assets/logo-icon.png" alt=""><span>交通即時查 TransitGo</span></a>
  <div class="card">
    <h1>${esc(landmark.name)}</h1>
    <p class="category">${esc(categoryLabel(landmark.category))}</p>
    ${status ? `<span class="status ${landmark.businessStatus === 'open' ? 'open' : 'closed'}">${esc(status)}</span>` : ''}
    ${landmark.description ? `<p>${esc(landmark.description)}</p>` : ''}
    ${landmark.businessHours ? `<div class="row"><b>營業時間</b><span>${esc(landmark.businessHours)}</span></div>` : ''}
    ${landmark.phone ? `<div class="row"><b>電話</b><a class="tel" href="tel:${esc(landmark.phone.replace(/[^0-9+]/g, ''))}">${esc(landmark.phone)}</a></div>` : ''}
    <div class="row"><b>地圖</b><a class="map" href="${esc(mapsUrl)}" target="_blank" rel="noopener">在地圖中開啟 →</a></div>
    ${!landmark.businessVerified ? '<p class="unverified">這個地標還沒有店家認領。如果是你的店，到 <a href="/app/business">商家後台</a> 認領它，就能顯示營業時間與電話。</p>' : ''}
  </div>
  <footer>資料由「交通即時查 TransitGo」使用者提供 · <a href="/shop">所有商家</a> · <a href="/app">下載 App</a></footer>
</main>
</body>
</html>`;
}

const notFound = (origin) => `<!doctype html><html lang="zh-Hant"><head><meta charset="utf-8">
<title>找不到這個地標｜交通即時查 TransitGo</title><meta name="robots" content="noindex"></head>
<body style="font-family:-apple-system,sans-serif;text-align:center;padding:80px 20px">
<p>找不到這個地標，可能還沒通過審核，或連結有誤。</p><p><a href="${esc(origin)}/app">回 App 首頁</a></p>
</body></html>`;

export async function onRequest({ request, params, env }) {
  const id = String(params.id ?? '');
  const origin = new URL(request.url).origin;
  if (!/^[0-9]+$/.test(id)) {
    return new Response(notFound(origin), { status: 404, headers: { 'content-type': 'text/html; charset=utf-8' } });
  }

  let upstream;
  try {
    upstream = await fetch(`${backendBase(env)}/v1/landmarks/${id}`, { signal: AbortSignal.timeout(15000) });
  } catch {
    return new Response(notFound(origin), { status: 502, headers: { 'content-type': 'text/html; charset=utf-8' } });
  }
  if (!upstream.ok) {
    return new Response(notFound(origin), { status: 404, headers: { 'content-type': 'text/html; charset=utf-8' } });
  }
  const { landmark } = await upstream.json();
  return new Response(page({ landmark, origin }), {
    status: 200,
    headers: { 'content-type': 'text/html; charset=utf-8', 'cache-control': 'public, max-age=60' },
  });
}
