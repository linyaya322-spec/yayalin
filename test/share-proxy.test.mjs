// Runs the share proxy against a fake backend: what it forwards, what it refuses, what it strips.
import { forward, isToken, backendBase, DEFAULT_BACKEND } from '../functions/_lib/shareProxy.js';

let failed = false;
const check = (label, cond, detail) => { console.log(`${cond ? 'PASS' : 'FAIL'} - ${label}`); if (!cond) { failed = true; if (detail) console.log('   ', detail); } };

const TOKEN = 'kZR5OhIGM2auOVYcuRt1fw';
const calls = [];
const fakeBackend = (status = 200, body = '{"ok":true}', headers = { 'content-type': 'application/json', 'set-cookie': 'a=b', 'x-powered-by': 'express', 'x-robots-tag': 'noindex, nofollow' }) =>
  async (url, init) => { calls.push({ url, init }); return new Response(body, { status, headers }); };
const req = (method, extra = {}, body) => new Request('https://yayalin.com/app/x', { method, headers: { 'cf-connecting-ip': '203.0.113.7', cookie: 'session=secret', authorization: 'Bearer nope', ...extra }, body });
const live = (t) => `/v1/shares/${t}/live`;

// tokens
check('a 22-char URL-safe token is accepted', isToken(TOKEN) && isToken('A_-'.repeat(7) + 'A'));
check('anything else is not a token', !isToken('short') && !isToken(TOKEN + 'x') && !isToken('../etc/passwd/aaaaaaaa') && !isToken(TOKEN.slice(0, 21) + '/') && !isToken(undefined) && !isToken(''));

// happy path
{
  calls.length = 0;
  const r = await forward({ request: req('GET'), env: {}, token: TOKEN, path: live, methods: ['GET'], fetchImpl: fakeBackend() });
  check('GET is forwarded to the backend path for that token', r.status === 200 && calls[0].url === `${DEFAULT_BACKEND}/v1/shares/${TOKEN}/live` && calls[0].init.method === 'GET');
  check('the real visitor IP is passed as X-Viewer-IP', calls[0].init.headers['x-viewer-ip'] === '203.0.113.7');
  check('cookies and Authorization are NOT forwarded', !('cookie' in calls[0].init.headers) && !('authorization' in calls[0].init.headers));
  check('only whitelisted response headers come back (no Set-Cookie / X-Powered-By)', r.headers.get('x-robots-tag') === 'noindex, nofollow' && !r.headers.get('set-cookie') && !r.headers.get('x-powered-by'));
  check('never cached, never rewritten by Cloudflare', r.headers.get('cache-control') === 'no-store, no-transform');
}

// refusals
{
  calls.length = 0;
  const r1 = await forward({ request: req('DELETE'), env: {}, token: TOKEN, path: live, methods: ['GET'], fetchImpl: fakeBackend() });
  check('a method the route does not allow is refused (DELETE on a GET route) and never reaches the backend', r1.status === 405 && calls.length === 0);
  const r2 = await forward({ request: req('GET'), env: {}, token: '../admin', path: live, methods: ['GET'], fetchImpl: fakeBackend() });
  check('a malformed token is a 404 and never reaches the backend', r2.status === 404 && calls.length === 0);
  const r3 = await forward({ request: req('POST', {}, 'x'.repeat(5000)), env: {}, token: TOKEN, path: live, methods: ['POST'], fetchImpl: fakeBackend() });
  check('an oversized POST body is refused', r3.status === 413 && calls.length === 0);
}

// POST (rating)
{
  calls.length = 0;
  const r = await forward({ request: req('POST', { 'content-type': 'text/plain' }, '{"stars":5,"legIndex":1}'), env: {}, token: TOKEN, path: (t) => `/v1/shares/${t}/rating`, methods: ['POST'], fetchImpl: fakeBackend(200, '{"ok":true}') });
  check('a rating POST is forwarded with its body and a JSON content type', r.status === 200 && calls[0].init.body === '{"stars":5,"legIndex":1}' && calls[0].init.headers['content-type'] === 'application/json');
}

// backend answers pass straight through; failures are a clean 502
{
  const notFound = await forward({ request: req('GET'), env: {}, token: TOKEN, path: live, methods: ['GET'], fetchImpl: fakeBackend(404, '{"ok":false}') });
  check('a backend 404 (link expired) is passed through as 404', notFound.status === 404);
  const down = await forward({ request: req('GET'), env: {}, token: TOKEN, path: live, methods: ['GET'], fetchImpl: async () => { throw new Error('ECONNREFUSED'); } });
  check('backend unreachable → a JSON 502 (the share page keeps retrying), not an error page', down.status === 502 && (await down.json()).error === 'backend_unreachable');
}

// backend address
check('the backend address defaults, can be overridden by an https TRANSITGO_BACKEND, and ignores junk / http',
  backendBase({}) === DEFAULT_BACKEND && backendBase({ TRANSITGO_BACKEND: 'https://example.com/whatever' }) === 'https://example.com' && backendBase({ TRANSITGO_BACKEND: 'http://example.com' }) === DEFAULT_BACKEND && backendBase({ TRANSITGO_BACKEND: 'nope' }) === DEFAULT_BACKEND && backendBase({ TRANSITGO_BACKEND: 'http://localhost:8787/x' }) === 'http://localhost:8787');

// the route files wire the right path and methods
{
  const routes = [
    ['../functions/app/s/[token].js', 'GET', `${DEFAULT_BACKEND}/s/${TOKEN}`],
    ['../functions/app/api/shares/[token].js', 'GET', `${DEFAULT_BACKEND}/v1/shares/${TOKEN}`],
    ['../functions/app/api/shares/[token]/live.js', 'GET', `${DEFAULT_BACKEND}/v1/shares/${TOKEN}/live`],
    ['../functions/app/api/shares/[token]/rating.js', 'POST', `${DEFAULT_BACKEND}/v1/shares/${TOKEN}/rating`],
  ];
  const realFetch = globalThis.fetch;
  for (const [file, method, expected] of routes) {
    calls.length = 0;
    globalThis.fetch = fakeBackend();
    const mod = await import(new URL(file.replace(/\[/g, '%5B').replace(/\]/g, '%5D'), import.meta.url));
    const r = await mod.onRequest({ request: req(method, {}, method === 'POST' ? '{"stars":4,"legIndex":0}' : undefined), env: {}, params: { token: TOKEN } });
    check(`${file.split('functions/')[1]} → ${method} ${expected.replace(DEFAULT_BACKEND, '<backend>')}`, r.status === 200 && calls[0]?.url === expected);
  }
  globalThis.fetch = realFetch;
}

process.exit(failed ? 1 : 0);
