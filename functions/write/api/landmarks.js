// GET 全部使用者新增的地標（含未核准、被檢舉、自稱店家未驗證）。
import { proxyAdmin } from '../../_lib/adminProxy.js';

export async function onRequest({ request, env }) {
  return proxyAdmin({ request, env, path: '/v1/admin/landmarks', methods: ['GET'] });
}
