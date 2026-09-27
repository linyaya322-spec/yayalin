// GET 全部地標評論（含被檢舉的）。
import { proxyAdmin } from '../../_lib/adminProxy.js';

export async function onRequest({ request, env }) {
  return proxyAdmin({ request, env, path: '/v1/admin/place-reviews', methods: ['GET'] });
}
