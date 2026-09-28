// Must stay in sync with transitgo-server's landmarks.mjs LANDMARK_LINK_KINDS (same raw
// values) and the App's own LandmarkLinks struct — a fixed set of external-link kinds, not
// free text.
export const LINK_LABEL = {
  menu: '菜單', order: '線上點餐', website: '官網', delivery: '外送',
};

export const LINK_ORDER = ['menu', 'order', 'website', 'delivery'];
