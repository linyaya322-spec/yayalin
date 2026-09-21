// 搜尋引擎與 AI 搜尋用的「我是誰」資料，集中在這裡，BaseLayout、llms.txt 共用。

export const SITE_URL = 'https://yayalin.com';
export const PERSON_NAME = 'yaya 林';
export const PERSON_ALTERNATE_NAMES = ['yaya', 'lin yaya', 'yaya lin', 'Yaya Lin'];

export const COMMITTEE_NAME = '新竹縣兒童及少年福利與權益促進委員會';

// 人們可能拿來搜尋的稱呼
export const ROLE_TERMS = [
  '新竹縣兒少代表',
  '兒少代表',
  '諮詢代表',
  '兒童代表',
  '新竹縣兒少',
  '兒童及少年代表',
  '兒童委員',
  '新竹縣委員',
  '新竹縣兒少委員',
];

export const KEYWORDS = [...ROLE_TERMS, ...PERSON_ALTERNATE_NAMES, 'yaya 林', '兒少參與', '兒童權利公約', '學生權益'];

export const DEFAULT_DESCRIPTION =
  'yaya 林（lin yaya、yaya lin）是新竹縣兒少代表，2024 年起擔任新竹縣兒童及少年福利與權益促進委員會青少年代表委員，關注學生權益、兒少參與與兒童權利，這裡記錄提案、會議與生活。';

export const KNOWS_ABOUT = [
  '兒少參與',
  '兒童權利公約',
  '學生權益',
  '校園獎懲制度',
  '兒少就學交通安全',
];
