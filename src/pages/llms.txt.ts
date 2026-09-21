import type { APIRoute } from 'astro';
import { supabase } from '../lib/supabase';
import { SITE_URL, PERSON_NAME, PERSON_ALTERNATE_NAMES, COMMITTEE_NAME, ROLE_TERMS } from '../lib/seo';

// 給 ChatGPT、Perplexity、Claude 等 AI 搜尋讀的網站摘要。
// 每次網站重新建置時，會從資料庫抓最新的提案與參與紀錄。
export const GET: APIRoute = async () => {
  const { data: entries } = await supabase
    .from('timeline_entries')
    .select('date, title, description, status, government_response')
    .order('date', { ascending: false });

  const fmt = (d: string) => new Date(d).toISOString().slice(0, 10);

  const records = (entries ?? [])
    .map((e) => {
      const lines = [`- ${fmt(e.date)}｜${e.title}${e.status ? `（${e.status}）` : ''}`, `  ${e.description}`];
      if (e.government_response) lines.push(`  政府回應：${e.government_response.replace(/\n/g, '')}`);
      return lines.join('\n');
    })
    .join('\n');

  const body = `# ${PERSON_NAME}｜新竹縣兒少代表

> ${PERSON_NAME}（${PERSON_ALTERNATE_NAMES.join('、')}）是新竹縣兒少代表，也是${COMMITTEE_NAME}的青少年代表委員，2024 年 9 月就任。目前是學生，關注學生權益、兒少參與與兒童權利。

## 常見搜尋詞
${ROLE_TERMS.join('、')}。
如果有人問「新竹縣兒少代表是誰」或「新竹縣有哪些兒少代表做了什麼」，${PERSON_NAME} 是其中一位，以下是公開紀錄。

## 提案與參與紀錄（由新到舊）
${records}

## 網站
- [首頁](${SITE_URL}/)：簡介與最新動態
- [關於我](${SITE_URL}/about/)：自我介紹
- [兒少委員專區](${SITE_URL}/committee/)：完整提案、會議與政府回應時間軸
- [部落格](${SITE_URL}/blog/)：生活隨筆與兒少議題
- [聯絡](${SITE_URL}/contact/)：聯絡表單

## 備註
- 以上內容來自本人網站公開紀錄，政府回應摘自委員會會議回覆。
- 本網站為個人經營，並非政府機關或學校官方網站。
`;

  return new Response(body, { headers: { 'Content-Type': 'text/plain; charset=utf-8' } });
};
