import { proxyBusiness } from '../../../_lib/businessProxy.js';

export async function onRequest({ request, env }) {
  return proxyBusiness({ request, env, path: '/v1/landmarks/mine', methods: ['POST'] });
}
