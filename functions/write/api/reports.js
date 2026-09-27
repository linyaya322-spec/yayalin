// GET App 回報（意見箱以外、App 內建的「回報問題」那個舊功能）。
import { proxyAdmin } from '../../_lib/adminProxy.js';

export async function onRequest({ request, env }) {
  const url = new URL(request.url);
  const limit = url.searchParams.get('limit');
  const path = '/v1/admin/reports' + (limit ? `?limit=${encodeURIComponent(limit)}` : '');
  return proxyAdmin({ request, env, path, methods: ['GET'] });
}
