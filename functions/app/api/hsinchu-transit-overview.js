// yayalin.com/hsinchu/transit 頁面的資料來源——單純轉發到 transitgo-server 的公開端點
// （沒有登入/驗證需求，跟商家搜尋 API 一樣，只是讓瀏覽器不用直接打 transitgo-server）。
import { proxyPublic } from '../../_lib/publicProxy.js';

export async function onRequest({ request, env }) {
  return proxyPublic({ request, env, path: '/v1/hsinchu/transit-overview', methods: ['GET'] });
}
