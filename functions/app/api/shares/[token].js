import { forward } from '../../../_lib/shareProxy.js';

// /app/api/shares/<token>：行程內容
export const onRequest = ({ request, env, params }) =>
  forward({ request, env, token: params.token, path: (t) => `/v1/shares/${t}`, methods: ['GET'] });
