import { requireAdmin } from '../../../../_lib/adminAuth.js';
import { setBusinessBanned } from '../../../../_lib/businessAccounts.js';

const json = (status, body) => new Response(JSON.stringify(body), { status, headers: { 'content-type': 'application/json; charset=utf-8', 'cache-control': 'no-store' } });

export async function onRequest({ request, env, params }) {
  if (request.method !== 'POST') return json(405, { error: 'method_not_allowed' });
  const admin = await requireAdmin(request);
  if (!admin) return json(401, { error: 'unauthorized' });
  if (!env.SUPABASE_SECRET_KEY) return json(500, { error: 'not_configured' });
  const ok = await setBusinessBanned(env, String(params.id ?? ''), true);
  return json(ok ? 200 : 502, { ok });
}
