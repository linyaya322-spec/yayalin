// 商家的公開頁面 yayalin.com/shop/<id> —— 讓已認領的店家有一個可以分享出去的網址（貼在自己的社群、
// LINE 名片等）。伺服器端直接渲染 HTML（同一種做法見 functions/app/s/[token].js 的分享頁），這樣分享出去
// 在 LINE／Messenger 等地方才有正確的預覽（標題、說明），純前端 fetch 渲染做不到這件事。
//
// Google 地圖風格的資訊量：相簿、營業狀態（自動算出現在有沒有開）、特色標籤、評論——不是只有一張照片
// 加一段自由文字。
import { backendBase } from '../_lib/shareProxy.js';
import { categoryLabel } from '../_lib/landmarkCategories.js';
import { featureLabel } from '../_lib/landmarkFeatures.js';

const esc = (v) =>
  String(v ?? '').replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));

const STATUS_LABEL = { temporarily_closed: '暫停營業', permanently_closed: '已停業' };
const WEEKDAYS = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
const DAY_LABEL = { mon: '週一', tue: '週二', wed: '週三', thu: '週四', fri: '週五', sat: '週六', sun: '週日' };
// Same key transitgo-server's siteEmailCode-adjacent review flow and the App's own
// PlaceReviewService.key(name:coordinate:) use — deterministic from name + coordinate rounded to
// ~11m, so this page can look up the same place's reviews without a landmark-id-keyed API.
// Swift's Double.description always shows at least one decimal digit (e.g. 121 -> "121.0"),
// where JS's template-literal number formatting drops it for whole numbers ("121") — matching
// this exactly matters, this string has to come out byte-identical to what the App's own
// PlaceReviewService.key(name:coordinate:) produces, or a coordinate that happens to round to a
// whole degree would silently never find that place's reviews.
export const swiftDoubleString = (n) => (Number.isInteger(n) ? `${n}.0` : String(n));
export const placeKey = (name, lat, lon) => `${name}_${swiftDoubleString(Math.round(lat * 10000) / 10000)}_${swiftDoubleString(Math.round(lon * 10000) / 10000)}`;

const STAR_SVG = (filled) =>
  `<svg viewBox="0 0 20 20" width="14" height="14" fill="${filled ? '#f5a623' : 'none'}" stroke="${filled ? '#f5a623' : 'currentColor'}" stroke-width="1.4"><path d="M10 1.5l2.6 5.3 5.9.9-4.3 4.1 1 5.8L10 14.8l-5.2 2.8 1-5.8L1.5 7.7l5.9-.9z"/></svg>`;
const stars = (n) => Array.from({ length: 5 }, (_, i) => STAR_SVG(i < Math.round(n))).join('');

function galleryHtml(photos) {
  if (!photos.length) return '';
  return `<div class="gallery">${photos.map((p) => `<img src="${esc(p)}" alt="" loading="lazy">`).join('')}</div>`;
}

function hoursHtml(hours, todayKey) {
  if (!hours) return '';
  return `<div class="hours">${WEEKDAYS.map((d) => {
    const entry = hours[d];
    return `<div class="hours-row${d === todayKey ? ' today' : ''}"><span>${DAY_LABEL[d]}</span><span>${entry ? `${esc(entry.open)}–${esc(entry.close)}` : '公休'}</span></div>`;
  }).join('')}</div>`;
}

function reviewsHtml(reviews, stats) {
  if (!stats || !stats.count) {
    return `<p class="empty">還沒有評論——在 App 裡可以留下第一則。</p>`;
  }
  const list = reviews.slice(0, 20).map((r) => `
    <div class="review">
      <div class="review-stars">${stars(r.stars)}</div>
      ${r.comment ? `<p>${esc(r.comment)}</p>` : ''}
      <p class="review-date">${new Date(r.createdAt).toLocaleDateString('zh-TW', { timeZone: 'Asia/Taipei' })}</p>
    </div>`).join('');
  return `<div class="review-summary">${stars(stats.avg)}<b>${esc(stats.avg)}</b><span>（${stats.count} 則評論）</span></div>${list}`;
}

function page({ landmark, reviews, stats, origin }) {
  const title = `${landmark.name}｜交通即時查 TransitGo`;
  const desc = landmark.description || `${landmark.name} 的地標資訊 —— 交通即時查 TransitGo`;
  const mapsUrl = `https://maps.apple.com/?ll=${landmark.lat},${landmark.lon}&q=${encodeURIComponent(landmark.name)}`;
  const canonical = `${origin}/shop/${landmark.id}`;
  const weekdayShort = new Intl.DateTimeFormat('en-US', { timeZone: 'Asia/Taipei', weekday: 'short' }).format(new Date());
  const todayKey = { Mon: 'mon', Tue: 'tue', Wed: 'wed', Thu: 'thu', Fri: 'fri', Sat: 'sat', Sun: 'sun' }[weekdayShort] ?? null;

  // 營業狀態：business_status（店家自己標的長期狀態，例如整修中）永遠優先於算出來的 openNow。
  let statusText = null, statusClass = 'open';
  if (landmark.businessStatus && landmark.businessStatus !== 'open') {
    statusText = STATUS_LABEL[landmark.businessStatus] ?? landmark.businessStatus;
    statusClass = 'closed';
  } else if (landmark.openNow) {
    statusText = landmark.openNow.open ? `營業中 · ${esc(landmark.openNow.changesLabel)}` : `休息中 · ${esc(landmark.openNow.changesLabel)}`;
    statusClass = landmark.openNow.open ? 'open' : 'closed';
  }

  const photos = landmark.photos || [];
  const features = landmark.features || [];

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
${photos[0] ? `<meta property="og:image" content="${esc(photos[0])}">` : ''}
<meta name="twitter:card" content="${photos[0] ? 'summary_large_image' : 'summary'}">
<link rel="icon" type="image/png" href="/app-assets/app-touch-icon.png">
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@500;700;800&display=swap" rel="stylesheet">
<style>
:root { color-scheme: light dark; --bg:#fbfdff; --card:#fff; --text:#0e2038; --muted:#57667e; --line:#e2e8f1; --accent:#0a6cf0; --accent-soft:#e6f1ff; --accent2:#0fb88a; --accent2-soft:#e3faf3; }
@media (prefers-color-scheme: dark) { :root { --bg:#0b1626; --card:#101d33; --text:#eef3fa; --muted:#9fb0c6; --line:#24344c; --accent:#4da3ff; --accent-soft:#0a6cf033; --accent2:#2bd9ac; --accent2-soft:#0fb88a33; } }
* { box-sizing: border-box; }
body { margin:0; position:relative; overflow-x:hidden; background:var(--bg); color:var(--text); font:16px/1.7 -apple-system,"PingFang TC","Noto Sans TC",system-ui,sans-serif; }
h1, .brand { font-family: "Plus Jakarta Sans", -apple-system, "PingFang TC", system-ui, sans-serif; letter-spacing: -0.01em; }
.glow { position:absolute; top:-140px; left:50%; transform:translateX(-50%); width:700px; height:380px; pointer-events:none; z-index:0;
  background: radial-gradient(closest-side, var(--accent-soft), transparent 70%), radial-gradient(closest-side at 75% 30%, var(--accent2-soft), transparent 65%); opacity:.9; }
main { position:relative; z-index:1; max-width: 560px; margin: 0 auto; padding: 28px 20px 56px; }
.brand { display:flex; align-items:center; gap:10px; font-weight:800; font-size:17px; text-decoration:none; color:var(--text); margin-bottom: 18px; }
.brand img { width:28px; height:28px; }
.gallery { display:flex; gap:8px; overflow-x:auto; scroll-snap-type:x mandatory; margin: 0 0 16px; padding-bottom: 2px; -webkit-overflow-scrolling:touch; }
.gallery img { width: 78%; max-width: 340px; aspect-ratio: 4/3; object-fit:cover; border-radius:16px; flex:none; scroll-snap-align:start; background:var(--line); }
.card { background:var(--card); border:1px solid var(--line); border-radius:16px; padding:22px 22px 26px; }
h1 { font-size: 1.5rem; margin: 0 0 6px; }
.category { font-size: 0.85rem; color: var(--muted); margin: 0 0 12px; }
.status { display:inline-flex; align-items:center; gap:6px; font-size:0.82rem; font-weight:700; padding:4px 12px; border-radius:999px; margin-bottom:14px; }
.status.open { background:var(--accent2-soft); color:var(--accent2); }
.status.closed { background:#fde4e2; color:#a82727; }
.chips { display:flex; flex-wrap:wrap; gap:6px; margin: 0 0 16px; }
.chip { font-size:0.78rem; font-weight:600; padding:4px 11px; border-radius:999px; background:var(--accent-soft); color:var(--accent); }
.row { display:flex; gap:10px; align-items:flex-start; padding: 10px 0; border-top:1px solid var(--line); font-size:0.94rem; }
.row:first-of-type { border-top: none; }
.row b { color: var(--muted); font-weight:600; min-width: 4.5em; flex: none; }
.hours { flex:1; display:grid; gap:3px; }
.hours-row { display:flex; justify-content:space-between; font-size:0.88rem; color:var(--muted); }
.hours-row.today { color:var(--text); font-weight:700; }
a.tel, a.map { color: var(--accent); font-weight: 600; text-decoration: none; }
.unverified { font-size:0.85rem; color:var(--muted); margin-top:16px; }
.section-title { font-size:1.05rem; font-weight:800; margin: 26px 0 10px; font-family:"Plus Jakarta Sans",sans-serif; }
.review-summary { display:flex; align-items:center; gap:8px; margin-bottom:14px; }
.review-summary b { font-size:1.1rem; }
.review-summary span { color:var(--muted); font-size:0.88rem; }
.review { border-top:1px solid var(--line); padding:12px 0; }
.review:first-of-type { border-top:none; padding-top:0; }
.review-stars { display:flex; gap:2px; margin-bottom:4px; }
.review p { margin: 0 0 4px; font-size:0.92rem; }
.review-date { color:var(--muted); font-size:0.78rem; }
.empty { color:var(--muted); font-size:0.9rem; }
footer { text-align:center; margin-top: 22px; font-size: 0.8rem; color: var(--muted); }
footer a { color: var(--accent); }
</style>
</head>
<body>
<div class="glow" aria-hidden="true"></div>
<main>
  <a class="brand" href="/app"><img src="/app-assets/logo-icon.png" alt=""><span>交通即時查 TransitGo</span></a>
  ${galleryHtml(photos)}
  <div class="card">
    <h1>${esc(landmark.name)}</h1>
    <p class="category">${esc(categoryLabel(landmark.category))}</p>
    ${statusText ? `<span class="status ${statusClass}">${statusText}</span>` : ''}
    ${features.length ? `<div class="chips">${features.map((f) => `<span class="chip">${esc(featureLabel(f))}</span>`).join('')}</div>` : ''}
    ${landmark.description ? `<p>${esc(landmark.description)}</p>` : ''}
    ${landmark.hours ? `<div class="row"><b>營業時間</b>${hoursHtml(landmark.hours, todayKey)}</div>`
      : landmark.businessHours ? `<div class="row"><b>營業時間</b><span>${esc(landmark.businessHours)}</span></div>` : ''}
    ${landmark.phone ? `<div class="row"><b>電話</b><a class="tel" href="tel:${esc(landmark.phone.replace(/[^0-9+]/g, ''))}">${esc(landmark.phone)}</a></div>` : ''}
    <div class="row"><b>地圖</b><a class="map" href="${esc(mapsUrl)}" target="_blank" rel="noopener">在地圖中開啟 →</a></div>
    ${!landmark.businessVerified ? '<p class="unverified">這個地標還沒有店家認領。如果是你的店，到 <a href="/app/business">商家後台</a> 認領它，就能顯示營業時間、電話、相簿與特色標籤。</p>' : ''}
  </div>
  <p class="section-title">評論</p>
  ${reviewsHtml(reviews, stats)}
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

  // Reviews are keyed by name+coordinate (see placeKey above), not by landmark id — best-effort:
  // a failed/slow reviews fetch never blocks the page, it just shows "no reviews yet".
  let reviews = [], stats = null;
  try {
    const key = placeKey(landmark.name, landmark.lat, landmark.lon);
    const r = await fetch(`${backendBase(env)}/v1/places/reviews?placeKey=${encodeURIComponent(key)}`, { signal: AbortSignal.timeout(8000) });
    if (r.ok) ({ reviews, stats } = await r.json());
  } catch { /* best-effort */ }

  return new Response(page({ landmark, reviews, stats, origin }), {
    status: 200,
    headers: { 'content-type': 'text/html; charset=utf-8', 'cache-control': 'public, max-age=60' },
  });
}
