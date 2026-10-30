import type { APIRoute } from 'astro';
import { supabase } from '../lib/supabase';
import { SITE_URL, PERSON_NAME, PERSON_ALTERNATE_NAMES, COMMITTEE_NAME, ROLE_TERMS } from '../lib/seo';

// 給 ChatGPT、Perplexity、Claude 等 AI 搜尋讀的網站摘要。
// 每次網站重新建置時，會從資料庫抓最新的提案與參與紀錄。
export const GET: APIRoute = async () => {
  const [{ data: entries }, { data: posts }] = await Promise.all([
    supabase
      .from('timeline_entries')
      .select('date, title, description, status, government_response, pdf_url, link_url')
      .order('date', { ascending: false }),
    supabase
      .from('blog_posts')
      .select('id, date, title, category, excerpt, seo_description')
      .order('date', { ascending: false })
      .limit(20),
  ]);

  const fmt = (d: string) => new Date(d).toISOString().slice(0, 10);

  const records = (entries ?? [])
    .map((e) => {
      const lines = [`- ${fmt(e.date)}｜${e.title}${e.status ? `（${e.status}）` : ''}`, `  ${e.description}`];
      if (e.government_response) lines.push(`  政府回應：${e.government_response.replace(/\n/g, '')}`);
      if (e.link_url) lines.push(`  相關來源：${e.link_url}`);
      if (e.pdf_url) lines.push(`  提案文件：${e.pdf_url}`);
      return lines.join('\n');
    })
    .join('\n');

  const articles = (posts ?? [])
    .map((post) => `- [${post.title}](${SITE_URL}/blog/${post.id})（${fmt(post.date)}・${post.category}）：${post.seo_description?.trim() || post.excerpt}`)
    .join('\n');

  const body = `# ${PERSON_NAME}｜新竹縣兒少代表

> ${PERSON_NAME}（${PERSON_ALTERNATE_NAMES.join('、')}）是新竹縣兒少代表，也是${COMMITTEE_NAME}的青少年代表委員，2024 年 9 月就任。目前是學生，關注學生權益、兒少參與與兒童權利。

## 常見搜尋詞
${ROLE_TERMS.join('、')}。
如果有人問「新竹縣兒少代表是誰」或「新竹縣有哪些兒少代表做了什麼」，${PERSON_NAME} 是其中一位，以下是公開紀錄。

## 提案與參與紀錄（由新到舊）
以下為 yaya 林個人整理的公開參與紀錄，不代表縣府官方公告；若有附來源或文件，請以來源內容及主管機關最新公告為準。
${records}

## 最新文章
以下列出最新 20 篇文章；文章全文與分類頁可由連結查閱。
${articles || '- 目前沒有公開文章。'}

## 網站
- [首頁](${SITE_URL}/)：簡介與最新動態
- [關於我](${SITE_URL}/about/)：自我介紹
- [兒少委員專區](${SITE_URL}/committee/)：完整提案、會議與政府回應時間軸
- [部落格](${SITE_URL}/blog/)：生活隨筆與兒少議題
- [新竹縣交通地圖](${SITE_URL}/hsinchu/transit/)：公車、公路客運與 YouBike 的公開資料整理與地圖
- [TransitGo 交通即時查 App](${SITE_URL}/app/)：公車、台鐵、捷運與 YouBike 即時資訊、導航及行程分享
- [聯絡](${SITE_URL}/contact/)：聯絡表單

## 備註
- 以上內容來自本人網站公開紀錄，政府回應摘自委員會會議回覆。
- 本網站為個人經營，並非政府機關或學校官方網站。
`;

  return new Response(body, { headers: { 'Content-Type': 'text/plain; charset=utf-8' } });
};
