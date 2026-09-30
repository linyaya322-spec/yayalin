// Must stay in sync with the App's own LandmarkCategoryGroup enum — groups the fine-grained
// CATEGORY_LABEL entries (landmarkCategories.js) into a coarser "先選大分類" first step, so a
// two-step picker only ever needs this mapping edited in one place.
export const GROUP_LABEL = {
  foodDrink: '餐飲與美食', medical: '醫療與健康', shopping: '購物與零售', transportation: '交通與基礎設施',
  education: '教育與學術', finance: '金融與商務', government: '公共服務與政府機構',
  recreation: '休閒、娛樂與觀光', sports: '運動與健身', lodging: '住宿', religion: '宗教與信仰',
  personalServices: '生活服務', other: '其他',
};

export const GROUP_ORDER = [
  'foodDrink', 'shopping', 'medical', 'transportation', 'education', 'finance', 'government',
  'recreation', 'sports', 'lodging', 'religion', 'personalServices', 'other',
];

// fine category -> group
export const CATEGORY_GROUP = {
  restaurant: 'foodDrink', cafe: 'foodDrink', teaShop: 'foodDrink', bakery: 'foodDrink', dessertShop: 'foodDrink',
  bar: 'foodDrink', breakfastShop: 'foodDrink', nightMarketStall: 'foodDrink', buffet: 'foodDrink', fastFood: 'foodDrink',
  groceryStore: 'shopping', convenienceStore: 'shopping', supermarket: 'shopping', clothingStore: 'shopping',
  bookstore: 'shopping', electronicsStore: 'shopping', giftShop: 'shopping', marketplace: 'shopping',
  hospital: 'medical', clinic: 'medical', dentist: 'medical', pharmacy: 'medical', veterinary: 'medical',
  gasStation: 'transportation', evCharging: 'transportation', parkingLot: 'transportation', carRepair: 'transportation', bikeShop: 'transportation',
  school: 'education', kindergarten: 'education', cramSchool: 'education', library: 'education',
  bank: 'finance', atm: 'finance', insurance: 'finance',
  policeStation: 'government', fireStation: 'government', postOffice: 'government', cityHall: 'government',
  park: 'recreation', cinema: 'recreation', museum: 'recreation', artGallery: 'recreation', karaoke: 'recreation', arcade: 'recreation',
  gym: 'sports', swimmingPool: 'sports', sportsField: 'sports', yogaStudio: 'sports',
  hotel: 'lodging', hostel: 'lodging', bnb: 'lodging', campground: 'lodging',
  temple: 'religion', church: 'religion',
  hairSalon: 'personalServices', laundry: 'personalServices', petGrooming: 'personalServices', repairShop: 'personalServices',
  other: 'other',
};

export const groupOf = (category) => CATEGORY_GROUP[category] ?? 'other';
