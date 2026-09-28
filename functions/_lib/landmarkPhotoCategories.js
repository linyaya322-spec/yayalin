// Must stay in sync with transitgo-server's landmarks.mjs PHOTO_CATEGORIES (same raw values)
// and the App's own PhotoCategory enum — a fixed vocabulary, not free text.
export const PHOTO_CATEGORY_LABEL = {
  food: '餐點', menu: '菜單', interior: '店內', exterior: '店外', other: '其他',
};

export const photoCategoryLabel = (c) => PHOTO_CATEGORY_LABEL[c] ?? c;
