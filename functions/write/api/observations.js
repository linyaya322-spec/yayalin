import { proxyAdmin } from '../../_lib/adminProxy.js';

export async function onRequest({ request, env }) {
  return proxyAdmin({ request, env, path: '/v1/admin/observations', methods: ['GET'] });
}
