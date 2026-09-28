// 認領一個「原本只存在於 Apple 地圖，還沒被任何人加進我們自己地標資料庫」的地方——網頁版商家
// 後台原本只能搜尋、認領「已經在我們系統裡且審核通過」的地標，這支補上「送出成為一筆新地標」的
// 路徑（跟 App 端 ClaimLandmarkView 在 landmarkID 是 nil 時走的路一樣）。
//
// isBusinessClaim 用 extraBody 強制設成 true，不管前端傳了什麼都一樣——這支路徑只給「已登入商家
// 認領店家」用，不該被拿來冒充成一般使用者的社群新增（那條路本來就不用登入，見 POST /v1/landmarks
// 本身）。
import { proxyBusiness } from '../../../../_lib/businessProxy.js';

export async function onRequest({ request, env }) {
  return proxyBusiness({ request, env, path: '/v1/landmarks', methods: ['POST'], extraBody: { isBusinessClaim: true } });
}
