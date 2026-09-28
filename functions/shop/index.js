// 商家目錄 yayalin.com/shop —— 瀏覽所有已認領的商家（shop/[id] 只能靠已經拿到連結才能看到那一家，
// 這裡讓人可以直接逛）。伺服器端渲染同一種做法（見 shop/[id].js），純資料頁不需要互動就能先上線；
// 之後有需要（分類篩選、換頁）再視情況補前端 JS，目前用最簡單的 query-string + 表單就夠。
import { backendBase } from '../_lib/shareProxy.js';
import { CATEGORY_LABEL, categoryLabel } from '../_lib/landmarkCategories.js';

const esc = (v) =>
  String(v ?? '').replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));

const STATUS_LABEL = { open: '營業中', temporarily_closed: '暫停營業', permanently_closed: '已停業' };
const PAGE_SIZE = 60;

function page({ businesses, total, offset, category, origin }) {
  const title = category
    ? `${categoryLabel(category)}商家目錄｜交通即時查 TransitGo`
    : '商家目錄｜交通即時查 TransitGo';
  const desc = '交通即時查 TransitGo 上已經認領的商家 —— 營業時間、狀態、地圖一次看。';
  const canonical = `${origin}/shop${category ? `?category=${encodeURIComponent(category)}` : ''}`;
  const hasPrev = offset > 0;
  const hasNext = offset + businesses.length < total;
  const qs = (o) => {
    const p = new URLSearchParams();
    if (category) p.set('category', category);
    if (o) p.set('offset', String(o));
    const s = p.toString();
    return s ? `?${s}` : '';
  };

  const categoryOptions = Object.entries(CATEGORY_LABEL)
    .map(([value, label]) => `<option value="${esc(value)}"${category === value ? ' selected' : ''}>${esc(label)}</option>`)
    .join('');

  const cards = businesses.length
    ? businesses.map((b) => {
        // business_status（店家自己標的長期狀態）永遠優先於算出來的 openNow。
        let status, statusClass;
        if (b.businessStatus && b.businessStatus !== 'open') { status = STATUS_LABEL[b.businessStatus] ?? b.businessStatus; statusClass = 'closed'; }
        else if (b.openNow) { status = b.openNow.open ? '營業中' : '休息中'; statusClass = b.openNow.open ? 'open' : 'closed'; }
        else { status = '營業中'; statusClass = 'open'; }
        return `<a class="card" href="/shop/${b.id}">
          ${b.coverPhoto ? `<img class="thumb" src="${esc(b.coverPhoto)}" alt="" loading="lazy">` : ''}
          <div class="card-body">
            <h2>${esc(b.name)}</h2>
            <p class="meta"><span class="category">${esc(categoryLabel(b.category))}</span><span class="status ${statusClass}">${esc(status)}</span></p>
            ${b.description ? `<p class="desc">${esc(b.description)}</p>` : ''}
            ${b.businessHours && !b.openNow ? `<p class="hours">${esc(b.businessHours)}</p>` : ''}
          </div>
        </a>`;
      }).join('')
    : `<p class="empty">${category ? '這個分類目前還沒有商家。' : '目前還沒有商家加入。'}</p>`;

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
main { max-width: 720px; margin: 0 auto; padding: 28px 20px 56px; }
.brand { display:flex; align-items:center; gap:10px; font-weight:800; font-size:17px; text-decoration:none; color:var(--text); margin-bottom: 22px; }
.brand img { width:28px; height:28px; }
h1 { font-size: 1.4rem; margin: 0 0 4px; }
.sub { color: var(--muted); font-size: 0.9rem; margin: 0 0 18px; }
form.filter { margin: 0 0 20px; }
form.filter select { font: inherit; padding: 8px 12px; border-radius: 10px; border: 1px solid var(--line); background: var(--card); color: var(--text); width: 100%; max-width: 280px; }
.grid { display: grid; gap: 12px; }
.card { display: flex; gap: 12px; align-items: flex-start; background: var(--card); border: 1px solid var(--line); border-radius: 14px; padding: 12px 16px; text-decoration: none; color: var(--text); transition: border-color .15s; }
.card .thumb { width: 64px; height: 64px; border-radius: 10px; object-fit: cover; flex: none; background: var(--line); }
.card .card-body { flex: 1; min-width: 0; }
.card:hover { border-color: var(--accent); }
.card h2 { font-size: 1.05rem; margin: 0 0 4px; }
.meta { display: flex; gap: 8px; align-items: center; margin: 0 0 6px; font-size: 0.82rem; }
.category { color: var(--muted); }
.status { font-weight: 700; padding: 1px 9px; border-radius: 999px; }
.status.open { background: var(--accent-soft); color: var(--accent); }
.status.closed { background: #fde4e2; color: #a82727; }
.desc { margin: 0 0 4px; font-size: 0.9rem; color: var(--muted); }
.hours { margin: 0; font-size: 0.85rem; color: var(--muted); }
.empty { color: var(--muted); text-align: center; padding: 40px 0; }
.pager { display: flex; justify-content: space-between; margin-top: 20px; font-size: 0.9rem; }
.pager a { color: var(--accent); font-weight: 600; text-decoration: none; }
.pager span { color: var(--muted); }
footer { text-align:center; margin-top: 30px; font-size: 0.8rem; color: var(--muted); }
footer a { color: var(--accent); }
</style>
</head>
<body>
<main>
  <a class="brand" href="/app"><img src="/app-assets/logo-icon.png" alt=""><span>交通即時查 TransitGo</span></a>
  <h1>商家目錄</h1>
  <p class="sub">交通即時查 TransitGo 上已經認領的商家，共 ${total} 家${category ? `（${esc(categoryLabel(category))}）` : ''}。</p>
  <form class="filter" method="get">
    <select name="category" onchange="this.form.submit()">
      <option value="">全部分類</option>
      ${categoryOptions}
    </select>
  </form>
  <div class="grid">${cards}</div>
  ${(hasPrev || hasNext) ? `<div class="pager">
    ${hasPrev ? `<a href="/shop${qs(Math.max(0, offset - PAGE_SIZE))}">← 上一頁</a>` : '<span></span>'}
    ${hasNext ? `<a href="/shop${qs(offset + PAGE_SIZE)}">下一頁 →</a>` : '<span></span>'}
  </div>` : ''}
  <footer>是店家嗎？到 <a href="/app/business">商家後台</a> 認領你的地標 · <a href="/app">下載 App</a></footer>
</main>
</body>
</html>`;
}

export async function onRequest({ request, env }) {
  const url = new URL(request.url);
  const category = url.searchParams.get('category') || '';
  const offsetParam = parseInt(url.searchParams.get('offset') ?? '0', 10);
  const offset = Number.isFinite(offsetParam) && offsetParam > 0 ? offsetParam : 0;

  const qs = new URLSearchParams({ limit: String(PAGE_SIZE), offset: String(offset) });
  if (category) qs.set('category', category);

  let businesses = [], total = 0;
  try {
    const upstream = await fetch(`${backendBase(env)}/v1/landmarks/directory?${qs}`, { signal: AbortSignal.timeout(15000) });
    if (upstream.ok) ({ businesses, total } = await upstream.json());
  } catch {
    // backend unreachable — show an empty directory rather than a hard error page; the
    // filter/pager still work once it's back.
  }

  return new Response(page({ businesses, total, offset, category, origin: url.origin }), {
    status: 200,
    headers: { 'content-type': 'text/html; charset=utf-8', 'cache-control': 'public, max-age=60' },
  });
}
