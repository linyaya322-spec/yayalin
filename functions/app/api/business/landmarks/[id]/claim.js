import { proxyPublic } from '../../../../../_lib/publicProxy.js';

export async function onRequest({ request, env, params }) {
  const id = String(params.id ?? '');
  if (!/^[0-9]+$/.test(id)) return new Response(JSON.stringify({ error: 'bad_id' }), { status: 400 });
  return proxyPublic({ request, env, path: `/v1/landmarks/${id}/claim`, methods: ['POST'] });
}
