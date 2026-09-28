// 商家後台（Supabase Auth 登入取代信箱驗證碼）的三個共用模組：誰登入了、代打 transitgo-server 時
// email 有沒有被冒充、站長封鎖帳號有沒有真的打對 Supabase Admin API。
import { requireBusinessUser } from '../functions/_lib/businessAuth.js';
import { proxyBusiness } from '../functions/_lib/businessProxy.js';
import { listBusinessAccounts, setBusinessBanned } from '../functions/_lib/businessAccounts.js';

let failed = false;
const check = (label, cond, detail) => { console.log(`${cond ? 'PASS' : 'FAIL'} - ${label}`); if (!cond) { failed = true; if (detail) console.log('   ', detail); } };

const req = (method, extra = {}, body) => new Request('https://yayalin.com/app/api/business/mine', { method, headers: extra, body });

// ---- businessAuth.requireBusinessUser ----
{
  const user = await requireBusinessUser(req('POST'));
  check('no Authorization header at all → null, no network call', user === null);
}
{
  const fakeFetch = async (url) => { check('asks Supabase who this token belongs to', url.includes('/auth/v1/user')); return new Response(JSON.stringify({ email: 'biz@example.com', id: 'u1' }), { status: 200 }); };
  const user = await requireBusinessUser(req('POST', { authorization: 'Bearer real-token' }), fakeFetch);
  check('a token Supabase recognises → the user object, with email', user?.email === 'biz@example.com');
}
{
  const fakeFetch = async () => new Response('', { status: 401 });
  const user = await requireBusinessUser(req('POST', { authorization: 'Bearer expired-or-banned' }), fakeFetch);
  check('an expired/invalid/banned token → null', user === null);
}
{
  const fakeFetch = async () => { throw new Error('network down'); };
  const user = await requireBusinessUser(req('POST', { authorization: 'Bearer x' }), fakeFetch);
  check('Supabase unreachable → null, not a throw', user === null);
}

// ---- businessProxy.proxyBusiness ----
{
  const r = await proxyBusiness({ request: req('POST'), env: { TRUSTED_PROXY_SECRET: 's' }, path: '/v1/landmarks/mine', methods: ['POST'] });
  check('no session at all → 401, never reaches the backend', r.status === 401);
}
{
  const authedReq = req('DELETE', { authorization: 'Bearer x' });
  const fakeFetch = async (url) => (url.includes('/auth/v1/user') ? new Response(JSON.stringify({ email: 'biz@example.com' }), { status: 200 }) : new Response('{}'));
  const r = await proxyBusiness({ request: authedReq, env: { TRUSTED_PROXY_SECRET: 's' }, path: '/v1/landmarks/mine', methods: ['POST'], fetchImpl: fakeFetch });
  check('a method the route does not allow is refused before even checking the session', r.status === 405);
}
{
  const authedReq = req('POST', { authorization: 'Bearer x' });
  const fakeFetch = async (url) => (url.includes('/auth/v1/user') ? new Response(JSON.stringify({ email: 'biz@example.com' }), { status: 200 }) : new Response('{}'));
  const r = await proxyBusiness({ request: authedReq, env: {}, path: '/v1/landmarks/mine', methods: ['POST'], fetchImpl: fakeFetch });
  check('a logged-in session but no TRUSTED_PROXY_SECRET configured on this deploy → 500, not a silent bypass', r.status === 500);
}
{
  // The security-critical property: whatever email the client puts in the body is IGNORED —
  // the trusted header always goes out with the Supabase-verified email, so a logged-in
  // business can never act as someone else's email by just typing it into the request.
  const calls = [];
  const authedReq = req('POST', { authorization: 'Bearer x', 'content-type': 'application/json' }, JSON.stringify({ email: 'someone-elses-business@example.com', businessHours: '9-5' }));
  const fakeFetch = async (url, init) => {
    if (url.includes('/auth/v1/user')) return new Response(JSON.stringify({ email: 'real-logged-in-user@example.com' }), { status: 200 });
    calls.push({ url, init });
    return new Response(JSON.stringify({ ok: true }), { status: 200 });
  };
  const r = await proxyBusiness({ request: authedReq, env: { TRUSTED_PROXY_SECRET: 'shh' }, path: '/v1/landmarks/mine', methods: ['POST'], fetchImpl: fakeFetch });
  check('the request reaches the backend', r.status === 200 && calls.length === 1);
  const sentBody = JSON.parse(calls[0].init.body);
  check('the email actually sent is the AUTHENTICATED one, not what the client typed', sentBody.email === 'real-logged-in-user@example.com');
  check('the client-supplied email never survives at all', sentBody.email !== 'someone-elses-business@example.com');
  check('the shared secret header is attached so transitgo-server trusts this without a code', calls[0].init.headers['x-trusted-proxy-secret'] === 'shh');
  check('other fields (businessHours) pass through untouched', sentBody.businessHours === '9-5');
}
{
  // extraBody pins down fields the client must never control (e.g. forcing isBusinessClaim on
  // the "new landmark" route) — it has to win even if the client tried to send the same field.
  const calls = [];
  const authedReq = req('POST', { authorization: 'Bearer x', 'content-type': 'application/json' }, JSON.stringify({ name: '我的店', isBusinessClaim: false }));
  const fakeFetch = async (url, init) => {
    if (url.includes('/auth/v1/user')) return new Response(JSON.stringify({ email: 'biz@example.com' }), { status: 200 });
    calls.push({ url, init });
    return new Response(JSON.stringify({ ok: true }), { status: 200 });
  };
  const r = await proxyBusiness({
    request: authedReq, env: { TRUSTED_PROXY_SECRET: 'shh' }, path: '/v1/landmarks', methods: ['POST'],
    extraBody: { isBusinessClaim: true }, fetchImpl: fakeFetch,
  });
  check('extraBody request reaches the backend', r.status === 200 && calls.length === 1);
  const sentBody = JSON.parse(calls[0].init.body);
  check('extraBody overrides a client-supplied value for the same field', sentBody.isBusinessClaim === true);
  check('fields the client sent that extraBody does not touch still pass through', sentBody.name === '我的店');
}
{
  const authedReq = req('POST', { authorization: 'Bearer x', 'content-type': 'application/json' }, 'not json');
  const fakeFetch = async (url) => (url.includes('/auth/v1/user') ? new Response(JSON.stringify({ email: 'biz@example.com' }), { status: 200 }) : new Response('{}'));
  const r = await proxyBusiness({ request: authedReq, env: { TRUSTED_PROXY_SECRET: 's' }, path: '/v1/landmarks/mine', methods: ['POST'], fetchImpl: fakeFetch });
  check('malformed JSON body is refused, not forwarded as-is', r.status === 400);
}
{
  // Photos (up to 6 data: URIs) push a real request body well past the old 4000-byte cap this
  // proxy used to have — it has to be sized for that, not just the common tiny edits.
  const bigPhoto = 'data:image/jpeg;base64,' + 'A'.repeat(500_000);
  const authedReq = req('POST', { authorization: 'Bearer x', 'content-type': 'application/json' }, JSON.stringify({ photos: [{ url: bigPhoto, category: 'food' }] }));
  const fakeFetch = async (url) => (url.includes('/auth/v1/user') ? new Response(JSON.stringify({ email: 'biz@example.com' }), { status: 200 }) : new Response(JSON.stringify({ ok: true }), { status: 200 }));
  const r = await proxyBusiness({ request: authedReq, env: { TRUSTED_PROXY_SECRET: 's' }, path: '/v1/landmarks/mine', methods: ['POST'], fetchImpl: fakeFetch });
  check('a half-megabyte photo (well past the old 4000-byte cap) is NOT rejected as too_large', r.status === 200);
}
{
  const hugeBody = JSON.stringify({ photos: [{ url: 'data:image/jpeg;base64,' + 'A'.repeat(9_000_000), category: 'food' }] });
  const authedReq = req('POST', { authorization: 'Bearer x', 'content-type': 'application/json' }, hugeBody);
  const fakeFetch = async (url) => (url.includes('/auth/v1/user') ? new Response(JSON.stringify({ email: 'biz@example.com' }), { status: 200 }) : new Response('{}'));
  const r = await proxyBusiness({ request: authedReq, env: { TRUSTED_PROXY_SECRET: 's' }, path: '/v1/landmarks/mine', methods: ['POST'], fetchImpl: fakeFetch });
  check('but something past the new (8mb) cap is still refused, not an unbounded proxy', r.status === 413);
}

// ---- businessAccounts: listing and banning ----
{
  const fakeFetch = async (url) => {
    check('lists via the Supabase Admin API', url.includes('/auth/v1/admin/users'));
    return new Response(JSON.stringify({ users: [
      { id: 'admin-id', email: 'yayalin322@gmail.com', created_at: '2026-01-01', last_sign_in_at: null, banned_until: null },
      { id: 'biz-1', email: 'a@b.com', created_at: '2026-01-02', last_sign_in_at: '2026-09-01', banned_until: null },
      { id: 'biz-2', email: 'c@d.com', created_at: '2026-01-03', last_sign_in_at: null, banned_until: '2099-01-01T00:00:00Z' },
      { id: 'biz-3', email: 'e@f.com', created_at: '2026-01-04', last_sign_in_at: null, banned_until: '2020-01-01T00:00:00Z' },   // ban already expired
    ] }), { status: 200 });
  };
  const accounts = await listBusinessAccounts({ SUPABASE_SECRET_KEY: 'k' }, fakeFetch);
  check('the site owner\'s own admin login is excluded from the business list', !accounts.some((a) => a.email === 'yayalin322@gmail.com'));
  check('a never-banned account reads as not banned', accounts.find((a) => a.id === 'biz-1')?.banned === false);
  check('a ban dated in the future reads as banned', accounts.find((a) => a.id === 'biz-2')?.banned === true);
  check('a ban dated in the PAST (expired) reads as not banned, not stuck banned forever', accounts.find((a) => a.id === 'biz-3')?.banned === false);
}
{
  const calls = [];
  const fakeFetch = async (url, init) => { calls.push({ url, init }); return new Response('', { status: 200 }); };
  await setBusinessBanned({ SUPABASE_SECRET_KEY: 'k' }, 'biz-1', true, fakeFetch);
  check('banning sets a long ban_duration (GoTrue has no literal "forever")', JSON.parse(calls[0].init.body).ban_duration === '876000h');
  await setBusinessBanned({ SUPABASE_SECRET_KEY: 'k' }, 'biz-1', false, fakeFetch);
  check('unbanning sets ban_duration back to "none"', JSON.parse(calls[1].init.body).ban_duration === 'none');
}

process.exit(failed ? 1 : 0);
