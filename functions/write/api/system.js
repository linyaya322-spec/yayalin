// 系統狀態：合併 /v1/health（公開、不需要 admin token）與 /v1/admin/bike-status（需要）成一個回應，
// 給後台的「系統」區塊一次拿齊。
import { backendBase } from '../../_lib/shareProxy.js';
import { requireAdmin } from '../../_lib/adminAuth.js';

const json = (status, body) =>
  new Response(JSON.stringify(body), { status, headers: { 'content-type': 'application/json; charset=utf-8', 'cache-control': 'no-store' } });

export async function onRequest({ request, env }) {
  if (request.method !== 'GET') return json(405, { error: 'method_not_allowed' });
  const admin = await requireAdmin(request);
  if (!admin) return json(401, { error: 'unauthorized' });

  const adminToken = env?.TRANSITGO_ADMIN_TOKEN;
  if (!adminToken) return json(500, { error: 'admin_token_not_configured' });
  const base = backendBase(env);

  const [health, bike] = await Promise.all([
    fetch(`${base}/v1/health`, { signal: AbortSignal.timeout(10000) }).then((r) => (r.ok ? r.json() : null)).catch(() => null),
    fetch(`${base}/v1/admin/bike-status`, { headers: { authorization: `Bearer ${adminToken}` }, signal: AbortSignal.timeout(10000) })
      .then((r) => (r.ok ? r.json() : null)).catch(() => null),
  ]);
  return json(200, { health, bikeStatus: bike?.status ?? null });
}
