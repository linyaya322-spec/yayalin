// 商家後台這幾支 API 本來就是公開的（跟 App 呼叫的是同一組端點，不需要 ADMIN_TOKEN、也不需要站長
// 登入）——信箱驗證碼本身就是它的身分證明。這裡只是單純轉發，讓瀏覽器不用直接打
// transitgo-server（那邊沒開 CORS）。
import { backendBase } from './shareProxy.js';

const json = (status, body) =>
  new Response(JSON.stringify(body), { status, headers: { 'content-type': 'application/json; charset=utf-8', 'cache-control': 'no-store' } });

const MAX_BODY = 4000;

export async function proxyPublic({ request, env, path, methods }) {
  if (!methods.includes(request.method)) return json(405, { error: 'method_not_allowed' });

  const headers = {};
  let body;
  if (request.method === 'POST' || request.method === 'PUT') {
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
