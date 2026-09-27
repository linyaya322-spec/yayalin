// 站長封鎖濫用商家帳號：直接用 Supabase Auth 自己的 ban 機制（GoTrue Admin API），不用另外自己存一個
// 「blocked」欄位——被封鎖的帳號連登入都會被 Supabase Auth 擋下來，business.astro 那邊完全不用
// 額外檢查什麼，商家後台的每一支 API 也一樣（都先要求登入）。需要 SUPABASE_SECRET_KEY（service
// role key，只在 Cloudflare Pages 的環境變數裡，前端絕對看不到）。
const SUPABASE_URL = 'https://lvxmefggedsozhrdjkqf.supabase.co';
const ADMIN_EMAIL = 'yayalin322@gmail.com';

function headers(env) {
  return { authorization: `Bearer ${env.SUPABASE_SECRET_KEY}`, apikey: env.SUPABASE_SECRET_KEY, 'content-type': 'application/json' };
}

/** 所有商家帳號（排除站長自己那組登入）——GoTrue 一頁最多回 50 筆，這裡撈到 200 筆應該夠用很久。
 * `fetchImpl` 只為了測試方便注入假的 Supabase 回應。 */
export async function listBusinessAccounts(env, fetchImpl = fetch) {
  const res = await fetchImpl(`${SUPABASE_URL}/auth/v1/admin/users?page=1&per_page=200`, { headers: headers(env), signal: AbortSignal.timeout(15000) });
  if (!res.ok) throw new Error(`supabase_admin_list_failed_${res.status}`);
  const { users } = await res.json();
  return (users ?? [])
    .filter((u) => u.email && u.email !== ADMIN_EMAIL)
    .map((u) => ({
      id: u.id, email: u.email, createdAt: u.created_at, lastSignInAt: u.last_sign_in_at ?? null,
      banned: !!u.banned_until && new Date(u.banned_until).getTime() > Date.now(),
    }));
}

/** `ban: true` 封鎖（近乎永久——GoTrue 的 ban_duration 沒有真正的「永遠」，用很長的期間代替）；
 * `ban: false` 解除封鎖。 */
export async function setBusinessBanned(env, userId, ban, fetchImpl = fetch) {
  const res = await fetchImpl(`${SUPABASE_URL}/auth/v1/admin/users/${encodeURIComponent(userId)}`, {
    method: 'PUT',
    headers: headers(env),
    body: JSON.stringify({ ban_duration: ban ? '876000h' : 'none' }),
    signal: AbortSignal.timeout(15000),
  });
  return res.ok;
}
