import { proxyAdmin } from '../../../../_lib/adminProxy.js';

export async function onRequest({ request, env, params }) {
  const id = String(params.id ?? '');
  if (!/^[0-9]+$/.test(id)) return new Response(JSON.stringify({ error: 'bad_id' }), { status: 400 });
  return proxyAdmin({ request, env, path: `/v1/admin/landmarks/${id}/verify-business`, methods: ['POST'] });
}
