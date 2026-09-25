import { forward } from '../../../../_lib/shareProxy.js';

// /app/api/shares/<token>/live：即時狀態
export const onRequest = ({ request, env, params }) =>
  forward({ request, env, token: params.token, path: (t) => `/v1/shares/${t}/live`, methods: ['GET'] });
