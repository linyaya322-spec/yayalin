// 驗證「發公告／下架／看回報」這幾支 API 的呼叫者真的是站長本人：把瀏覽器帶來的 Supabase 登入 token
// 拿去問 Supabase Auth「這是誰」，不接受呼叫端自己宣稱的身分。這個 publishable key 本來就是公開值
// （前端本來就會用到），寫在這裡不是洩漏；真正的權限來自 Supabase 驗證過的 email 是不是站長本人。

const SUPABASE_URL = 'https://lvxmefggedsozhrdjkqf.supabase.co';
const SUPABASE_ANON_KEY = 'sb_publishable_M30HHIufBozr-_BnGASdSQ_37nL5aWq';
const ADMIN_EMAIL = 'yayalin322@gmail.com';

/** 回傳站長的 Supabase user 物件，或 null（沒登入／不是站長）。*/
export async function requireAdmin(request) {
  const auth = request.headers.get('authorization') || '';
  const token = auth.match(/^Bearer\s+(.+)$/i)?.[1];
  if (!token) return null;
  let res;
  try {
    res = await fetch(`${SUPABASE_URL}/auth/v1/user`, {
      headers: { authorization: `Bearer ${token}`, apikey: SUPABASE_ANON_KEY },
      signal: AbortSignal.timeout(8000),
    });
  } catch {
    return null;
  }
  if (!res.ok) return null;
  const user = await res.json().catch(() => null);
  return user?.email === ADMIN_EMAIL ? user : null;
}
