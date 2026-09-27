import { proxyPublic } from '../../../_lib/publicProxy.js';

export async function onRequest({ request, env }) {
  return proxyPublic({ request, env, path: '/v1/email-code/request', methods: ['POST'] });
}
