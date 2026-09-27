import { requireAdmin } from '../../_lib/adminAuth.js';
import { listBusinessAccounts } from '../../_lib/businessAccounts.js';

const json = (status, body) => new Response(JSON.stringify(body), { status, headers: { 'content-type': 'application/json; charset=utf-8', 'cache-control': 'no-store' } });

export async function onRequest({ request, env }) {
  if (request.method !== 'GET') return json(405, { error: 'method_not_allowed' });
  const admin = await requireAdmin(request);
  if (!admin) return json(401, { error: 'unauthorized' });
  if (!env.SUPABASE_SECRET_KEY) return json(500, { error: 'not_configured' });
  try {
    return json(200, { accounts: await listBusinessAccounts(env) });
  } catch {
    return json(502, { error: 'supabase_unreachable' });
  }
}
