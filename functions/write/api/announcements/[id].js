// DELETE 下架一則公告。
import { proxyAdmin } from '../../../_lib/adminProxy.js';

export async function onRequest({ request, env, params }) {
  const id = String(params.id ?? '');
  if (!/^[0-9]+$/.test(id)) {
    return new Response(JSON.stringify({ error: 'bad_id' }), { status: 400, headers: { 'content-type': 'application/json; charset=utf-8' } });
  }
  return proxyAdmin({ request, env, path: `/v1/admin/announcements/${id}`, methods: ['DELETE'] });
}
