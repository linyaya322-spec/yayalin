// GET 目前全部公告（含已下架）／POST 發佈新公告（+推播）。實際資料在 TransitGo 後端；
// 這裡只負責「確認是站長本人」再代打過去，見 functions/_lib/adminProxy.js。
import { proxyAdmin } from '../../_lib/adminProxy.js';

export async function onRequest({ request, env }) {
  return proxyAdmin({ request, env, path: '/v1/admin/announcements', methods: ['GET', 'POST'] });
}
