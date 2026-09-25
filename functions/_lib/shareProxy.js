// 行程分享連結經 yayalin.com 開啟：這裡把 /app/s/<token>（分享頁）與 /app/api/shares/<token>[/live|/rating]
// 轉發到 TransitGo 後端。只轉發這幾條、只允許固定方法、代幣必須是 22 字元，其他一律不轉。
// 後端網址預設是 Tailscale Funnel 網域；可用 Pages 的環境變數 TRANSITGO_BACKEND（https）覆寫。

export const DEFAULT_BACKEND = 'https://macbook-neo-1.tail72b04d.ts.net';
const TOKEN = /^[A-Za-z0-9_-]{22}$/;
const MAX_BODY = 2048;
// 只把這些後端回應標頭帶回給訪客（不帶 Set-Cookie 等）
const PASS = ['content-type', 'x-robots-tag', 'referrer-policy', 'content-security-policy'];

export const isToken = (v) => typeof v === 'string' && TOKEN.test(v);

export function backendBase(env) {
  try {
    const u = new URL(env?.TRANSITGO_BACKEND);
    if (u.protocol === 'https:') return u.origin;
    // 本機開發（wrangler pages dev）才會指到 localhost；正式的 Cloudflare 環境連不到 localhost，所以這不會開任何洞
    if (u.protocol === 'http:' && (u.hostname === 'localhost' || u.hostname === '127.0.0.1')) return u.origin;
  } catch { /* not set or not a URL */ }
  return DEFAULT_BACKEND;
}

const json = (status, body, extra = {}) =>
  new Response(JSON.stringify(body), { status, headers: { 'content-type': 'application/json; charset=utf-8', 'cache-control': 'no-store', ...extra } });

/**
 * @param path   builds the backend path from the token, e.g. (t) => `/v1/shares/${t}/live`
 * @param methods the only methods this route accepts
 */
export async function forward({ request, env, token, path, methods, fetchImpl = fetch, timeoutMs = 25000 }) {
  if (!methods.includes(request.method)) return json(405, { ok: false, error: 'method_not_allowed' }, { allow: methods.join(', ') });
  if (!isToken(token)) return json(404, { ok: false, error: 'not_found' });

  const headers = { accept: request.headers.get('accept') || '*/*' };
  // 後端要用真正的訪客 IP 做限流與「每人評一次」，否則所有人看起來都是這個代理
  const ip = request.headers.get('cf-connecting-ip');
  if (ip) headers['x-viewer-ip'] = ip;

  let body;
  if (request.method === 'POST') {
    body = await request.text();
    if (body.length > MAX_BODY) return json(413, { ok: false, error: 'too_large' });
    headers['content-type'] = 'application/json';
  }

  let upstream;
  try {
    upstream = await fetchImpl(backendBase(env) + path(token), { method: request.method, headers, body, signal: AbortSignal.timeout(timeoutMs) });
  } catch {
    return json(502, { ok: false, error: 'backend_unreachable' });
  }

  const out = new Headers();
  for (const name of PASS) { const v = upstream.headers.get(name); if (v) out.set(name, v); }
  // no-transform：不讓 Cloudflare 改寫分享頁的 HTML／腳本
  out.set('cache-control', 'no-store, no-transform');
  return new Response(upstream.body, { status: upstream.status, headers: out });
}
