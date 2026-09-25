import { forward } from '../../_lib/shareProxy.js';

// /app/s/<token>：分享頁本身（HTML）
export const onRequest = ({ request, env, params }) =>
  forward({ request, env, token: params.token, path: (t) => `/s/${t}`, methods: ['GET'] });
