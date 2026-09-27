// Shared with the App's LandmarkCategory enum and transitgo-server's LANDMARK_CATEGORIES —
// kept as a plain copy here (not imported cross-repo) but MUST stay in sync with both. Used by
// both shop/[id].js (one business) and shop/index.js (the directory) so the label mapping only
// has to be edited in one place on this side.
export const CATEGORY_LABEL = {
  restaurant: '餐廳', cafe: '咖啡廳', teaShop: '飲料店', bakery: '麵包店', dessertShop: '甜點店', bar: '酒吧',
  breakfastShop: '早餐店', nightMarketStall: '夜市小吃', buffet: '自助餐', fastFood: '速食店',
  groceryStore: '雜貨店', convenienceStore: '便利商店', supermarket: '超市', clothingStore: '服飾店',
  bookstore: '書店', electronicsStore: '3C／電器行', giftShop: '禮品店', marketplace: '市場',
  hospital: '醫院', clinic: '診所', dentist: '牙醫', pharmacy: '藥局', veterinary: '獸醫院',
  gasStation: '加油站', evCharging: '電動車充電站', parkingLot: '停車場', carRepair: '汽機車保養廠', bikeShop: '自行車行',
  school: '學校', kindergarten: '幼兒園', cramSchool: '補習班', library: '圖書館',
  bank: '銀行', atm: 'ATM', insurance: '保險',
  policeStation: '警察局', fireStation: '消防局', postOffice: '郵局', cityHall: '行政機關',
  park: '公園', cinema: '電影院', museum: '博物館', artGallery: '藝廊', karaoke: 'KTV', arcade: '遊藝場',
  gym: '健身房', swimmingPool: '游泳池', sportsField: '運動場', yogaStudio: '瑜伽教室',
  hotel: '飯店', hostel: '青年旅館', bnb: '民宿', campground: '露營地',
  temple: '廟宇', church: '教堂',
  hairSalon: '美髮沙龍', laundry: '洗衣店', petGrooming: '寵物美容', repairShop: '維修行', other: '其他',
};
export const categoryLabel = (c) => CATEGORY_LABEL[c] ?? '其他';
