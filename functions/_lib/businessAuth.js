// 商家後台的登入：跟 adminAuth.js 用同一個 Supabase Auth 專案、同一種驗證方式（把瀏覽器帶來的
// token 拿去問 Supabase「這是誰」），但不限定信箱——任何登入過的人都是「一個商家」，不是站長。
// 站長本人的權限完全另外用 adminAuth.js 的 ADMIN_EMAIL 判斷，這裡驗證過的商家永遠不會通過那邊的檢查，
// 兩邊互不影響。

const SUPABASE_URL = 'https://lvxmefggedsozhrdjkqf.supabase.co';
const SUPABASE_ANON_KEY = 'sb_publishable_M30HHIufBozr-_BnGASdSQ_37nL5aWq';

/** 回傳登入商家的 Supabase user 物件（含 email），或 null（沒登入、token 過期、或帳號已被封鎖——
 * 封鎖是透過 Supabase Auth 本身的 ban 做的，被封鎖的帳號這裡直接驗證失敗，不需要另外查表）。
 * `fetchImpl` 只為了測試方便注入假的 Supabase 回應。 */
export async function requireBusinessUser(request, fetchImpl = fetch) {
  const auth = request.headers.get('authorization') || '';
  const token = auth.match(/^Bearer\s+(.+)$/i)?.[1];
  if (!token) return null;
  let res;
  try {
    res = await fetchImpl(`${SUPABASE_URL}/auth/v1/user`, {
      headers: { authorization: `Bearer ${token}`, apikey: SUPABASE_ANON_KEY },
      signal: AbortSignal.timeout(8000),
    });
  } catch {
    return null;
  }
  if (!res.ok) return null;
  const user = await res.json().catch(() => null);
  return user?.email ? user : null;
}
