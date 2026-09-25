import { forward } from '../../../../_lib/shareProxy.js';

// /app/api/shares/<token>/rating：抵達後評分（POST）
export const onRequest = ({ request, env, params }) =>
  forward({ request, env, token: params.token, path: (t) => `/v1/shares/${t}/rating`, methods: ['POST'] });
