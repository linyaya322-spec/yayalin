import { proxyPublic } from '../../../_lib/publicProxy.js';

export async function onRequest({ request, env }) {
  const url = new URL(request.url);
  const q = url.searchParams.get('q') || '';
  return proxyPublic({ request, env, path: `/v1/landmarks/search?q=${encodeURIComponent(q)}`, methods: ['GET'] });
}
