// Must stay in sync with transitgo-server's landmarks.mjs LANDMARK_FEATURES (same raw values)
// and the App's own LandmarkFeature enum — a fixed vocabulary, not free text, so it can always
// render as a recognisable chip instead of an arbitrary string.
export const FEATURE_LABEL = {
  reservations: '接受訂位', parking: '有停車位', petFriendly: '寵物友善', outdoorSeating: '戶外座位',
  wifi: '提供 Wi-Fi', creditCard: '可刷卡', delivery: '提供外送', takeout: '可外帶',
  wheelchairAccessible: '無障礙設施', kidsFriendly: '適合親子', airConditioning: '有冷氣', groupFriendly: '適合聚會',
};

export const featureLabel = (f) => FEATURE_LABEL[f] ?? f;
