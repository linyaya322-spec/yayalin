// 商家後台已登入（Supabase Auth）之後打的這幾支 API：轉發到 transitgo-server，但用
// TRUSTED_PROXY_SECRET 這個共用密鑰代替信箱驗證碼——因為商家的信箱已經在這一層（Supabase Auth
// session）驗證過了，不需要再叫 transitgo-server 走一次寄信驗證碼的流程。
//
// 最重要的一點：request body 裡不管前端傳了什麼 email，這裡一律覆寫成「Supabase Auth 驗證過的那個
// email」——不這樣做的話，一個登入的商家帳號就能靠著換 email 欄位冒充成任何人的信箱去編輯別人的地標，
// 等於 TRUSTED_PROXY_SECRET 形同虛設。
import { backendBase } from './shareProxy.js';
import { requireBusinessUser } from './businessAuth.js';

const json = (status, body) =>
  new Response(JSON.stringify(body), { status, headers: { 'content-type': 'application/json; charset=utf-8', 'cache-control': 'no-store' } });

// Most calls through here (edit hours/phone/status, claim) are tiny — but the landmark
// create/edit routes can now carry up to 6 photos as data: URIs, so this has to be sized for
// that, not for the common case. Matches transitgo-server's own 8mb JSON body limit (see
// index.mjs's express.json({ limit: "8mb" })) so this proxy is never the tighter bottleneck.
const MAX_BODY = 8_000_000;

/** `extraBody` merges in AFTER the client's own body (and after `email`), so a caller can pin
 * down fields the client must never control — e.g. forcing isBusinessClaim: true on the "new
 * landmark" route, the same way `email` itself is always overwritten below. */
export async function proxyBusiness({ request, env, path, methods, extraBody, fetchImpl = fetch }) {
  if (!methods.includes(request.method)) return json(405, { error: 'method_not_allowed' });

  const user = await requireBusinessUser(request, fetchImpl);
  if (!user) return json(401, { error: 'unauthorized' });
  if (!env.TRUSTED_PROXY_SECRET) return json(500, { error: 'not_configured' });

  let body = {};
  if (request.method === 'POST' || request.method === 'PUT') {
    const raw = await request.text();
    if (raw.length > MAX_BODY) return json(413, { error: 'too_large' });
    try { body = raw ? JSON.parse(raw) : {}; } catch { return json(400, { error: 'invalid_json' }); }
    if (typeof body !== 'object' || body === null || Array.isArray(body)) return json(400, { error: 'invalid_json' });
  }
  body.email = user.email;   // always the verified one, never what the client sent
  if (extraBody) Object.assign(body, extraBody);

  let upstream;
  try {
    upstream = await fetchImpl(backendBase(env) + path, {
      method: request.method,
      headers: { 'content-type': 'application/json', 'x-trusted-proxy-secret': env.TRUSTED_PROXY_SECRET },
      body: JSON.stringify(body),
      signal: AbortSignal.timeout(15000),
    });
  } catch {
    return json(502, { error: 'backend_unreachable' });
  }

  const text = await upstream.text();
  return new Response(text, {
    status: upstream.status,
    headers: { 'content-type': 'application/json; charset=utf-8', 'cache-control': 'no-store' },
  });
}
