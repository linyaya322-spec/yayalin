// 共用的「站長後台 → TransitGo 後端 /v1/admin/*」轉發：驗證是站長本人之後，用只存在 Cloudflare
// 環境變數裡的 ADMIN_TOKEN 代打後端，瀏覽器自己從來看不到那個權杖。
import { backendBase } from './shareProxy.js';
import { requireAdmin } from './adminAuth.js';

const json = (status, body) =>
  new Response(JSON.stringify(body), { status, headers: { 'content-type': 'application/json; charset=utf-8', 'cache-control': 'no-store' } });

const MAX_BODY = 4000;

/**
 * @param path 後端的路徑，例如 '/v1/admin/announcements' 或 (跟 id 有關時) 由呼叫端自己組好傳入
 * @param methods 這條路徑允許的方法
 */
export async function proxyAdmin({ request, env, path, methods }) {
  if (!methods.includes(request.method)) return json(405, { error: 'method_not_allowed' });

  const admin = await requireAdmin(request);
  if (!admin) return json(401, { error: 'unauthorized' });

  const adminToken = env?.TRANSITGO_ADMIN_TOKEN;
  if (!adminToken) return json(500, { error: 'admin_token_not_configured' });

  const headers = { authorization: `Bearer ${adminToken}` };
  let body;
  if (request.method === 'POST') {
    body = await request.text();
    if (body.length > MAX_BODY) return json(413, { error: 'too_large' });
    headers['content-type'] = 'application/json';
  }

  let upstream;
  try {
    upstream = await fetch(backendBase(env) + path, { method: request.method, headers, body, signal: AbortSignal.timeout(15000) });
  } catch {
    return json(502, { error: 'backend_unreachable' });
  }

  const text = await upstream.text();
  return new Response(text, {
    status: upstream.status,
    headers: { 'content-type': 'application/json; charset=utf-8', 'cache-control': 'no-store' },
  });
}
