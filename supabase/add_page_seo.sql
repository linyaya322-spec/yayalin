-- 全站 SEO/GEO 設定：貼到 Supabase SQL Editor 執行一次
-- path 使用網站路徑（例如 /、/about、/committee）；不含網域、query string 或 fragment。

create table if not exists public.page_seo (
  path text primary key check (path like '/%' and path !~ '[?#]'),
  title text,
  description text,
  keywords text[] not null default '{}'::text[],
  og_image text,
  geo_summary text,
  geo_faq jsonb not null default '[]'::jsonb check (jsonb_typeof(geo_faq) = 'array'),
  updated_at timestamptz not null default now()
);

alter table public.page_seo enable row level security;

grant select on public.page_seo to anon, authenticated;
grant insert, update, delete on public.page_seo to authenticated;

drop policy if exists "page_seo is publicly readable" on public.page_seo;
create policy "page_seo is publicly readable"
  on public.page_seo for select
  using (true);

drop policy if exists "only admin can manage page_seo" on public.page_seo;
create policy "only admin can manage page_seo"
  on public.page_seo for all to authenticated
  using (auth.jwt() ->> 'email' = 'yayalin322@gmail.com')
  with check (auth.jwt() ->> 'email' = 'yayalin322@gmail.com');

-- ────────────────────────────────────────────────────
-- 預設 SEO／GEO 資料（針對 yayalin.com 內容優化）
-- ────────────────────────────────────────────────────

insert into public.page_seo (path, title, description, keywords, og_image, geo_summary, geo_faq, updated_at)
values

-- 首頁
(
  '/',
  'yaya 林｜新竹縣兒少代表',
  'yaya 林（林逸霞）是新竹縣兒少代表，2024 年起擔任新竹縣兒童及少年福利與權益促進委員會青少年代表委員，關注學生權益、兒少參與與兒童權利公約，這裡記錄提案、會議紀錄與生活。',
  ARRAY['yaya 林','新竹縣兒少代表','兒少代表','林逸霞','兒童委員','學生權益','兒少參與','新竹縣','兒童權利公約'],
  '/og-image.png',
  'yaya 林（林逸霞）是新竹縣兒童及少年福利與權益促進委員會的青少年代表委員，2024 年就任，致力於推動學生權益、改善兒少就學交通安全，並提升兒少在公共政策制定過程中的參與。本站是 yaya 林的個人官方網站，記錄提案進度、會議資訊與兒少相關議題。',
  '[
    {"question": "yaya 林是誰？", "answer": "yaya 林（林逸霞）是新竹縣兒少代表，2024 年起擔任新竹縣兒童及少年福利與權益促進委員會的青少年代表委員。"},
    {"question": "新竹縣兒少代表的職責是什麼？", "answer": "新竹縣兒少代表負責出席縣級的兒童及少年福利與權益促進委員會，為在地兒少發聲，提出有關學生權益、兒少安全、兒童參與等政策建議。"},
    {"question": "yaya 林關注哪些兒少議題？", "answer": "yaya 林主要關注校園獎懲制度改革、兒少就學交通安全、以及提升兒少在公共政策中的參與度，並以兒童權利公約（CRC）框架推動相關倡議。"}
  ]'::jsonb,
  now()
),

-- 關於我
(
  '/about',
  'yaya 林的自我介紹｜新竹縣兒少代表',
  '認識 yaya 林：新竹縣兒少代表、青少年公民參與倡議者。了解她的背景、擔任委員的動機與在兒少議題上的關注焦點。',
  ARRAY['yaya 林','yaya lin','新竹縣兒少代表','自我介紹','林逸霞','兒少委員','青少年參與','兒童代表'],
  '/og-image.png',
  '這個頁面介紹 yaya 林的個人背景：她是新竹縣兒少代表（任期 2024 年起），也是一名關注兒少議題的高中生，致力於讓兒童的聲音在地方政策中被聽見。',
  '[
    {"question": "yaya 林的代表任期從什麼時候開始？", "answer": "yaya 林於 2024 年起擔任新竹縣兒童及少年福利與權益促進委員會的青少年代表委員。"},
    {"question": "yaya 林為什麼成為兒少代表？", "answer": "yaya 林希望讓兒少的聲音在縣政決策中被重視，並透過正式管道推動對學生與兒少有益的政策改變。"}
  ]'::jsonb,
  now()
),

-- 兒少代表專區
(
  '/committee',
  '兒少代表專區｜yaya 林｜新竹縣',
  '新竹縣兒少代表 yaya 林的提案紀錄、會議資訊與工作成果。追蹤學生權益、兒少交通安全等議題的進展。',
  ARRAY['兒少代表','提案紀錄','新竹縣兒童委員會','學生權益','兒少參與','兒少交通','會議紀錄','兒少代表專區'],
  '/og-image.png',
  '這個頁面匯整 yaya 林擔任新竹縣兒少代表期間的提案與工作紀錄。內容包含各次會議的提案主題、進度追蹤，以及兒少在政策討論中發揮作用的具體成果，供關注兒少政策的民眾參考。',
  '[
    {"question": "yaya 林提出哪些代表性提案？", "answer": "yaya 林提案的議題包含校園獎懲制度改革、兒少就學交通安全改善，以及提升兒少在公共政策制定中的參與機制。"},
    {"question": "在哪裡可以看到 yaya 林的提案進度？", "answer": "在 yayalin.com 的「兒少代表專區」頁面可以看到 yaya 林歷次提案的主題、會議紀錄摘要與後續追蹤。"},
    {"question": "新竹縣兒少代表是民選還是任命的？", "answer": "新竹縣兒少代表是透過遴選或相關程序由縣政府任命，代表新竹縣兒童及少年出席縣級委員會。"}
  ]'::jsonb,
  now()
),

-- 部落格列表
(
  '/blog',
  '部落格｜yaya 林的生活與兒少議題',
  'yaya 林的部落格：記錄生活隨筆、兒少議題觀察、興趣分享與新竹在地故事。',
  ARRAY['部落格','yaya 林','兒少議題','生活隨筆','興趣分享','新竹','茶葉蛋'],
  '/og-image.png',
  'yaya 林的部落格收錄生活隨筆、兒少議題思考、興趣分享與新竹在地觀察，文章分類包含「生活隨筆」、「兒少議題」、「興趣分享」與「茶葉蛋」（輕鬆短文）。',
  '[
    {"question": "yaya 林的部落格寫什麼主題？", "answer": "yaya 林的部落格涵蓋生活隨筆、兒少議題觀察、個人興趣分享，以及輕鬆的「茶葉蛋」小文章。"},
    {"question": "如何找到 yaya 林關於兒少議題的文章？", "answer": "在 yayalin.com/blog 可用分類篩選，選擇「兒少議題」標籤即可找到相關文章。"}
  ]'::jsonb,
  now()
),

-- 聯絡
(
  '/contact',
  '聯絡 yaya 林｜意見、提案與合作',
  '歡迎透過聯絡表單向 yaya 林反映兒少相關意見、提案建議或合作邀請，也可發起聯署或提出學生問題。',
  ARRAY['聯絡','意見反映','提案','合作','yaya 林','兒少代表聯絡','新竹縣兒少'],
  '/og-image.png',
  '這個頁面提供向 yaya 林提出意見、建議或合作邀請的管道。無論是對兒少政策的建議、校園問題的反映，或是媒體採訪邀請，都可以透過此頁的表單聯繫。',
  '[
    {"question": "如何向 yaya 林反映兒少問題？", "answer": "可透過 yayalin.com/contact 的表單送出意見或提案，yaya 林會盡力回覆。"},
    {"question": "yaya 林接受媒體採訪或合作邀請嗎？", "answer": "可透過聯絡頁面說明需求，yaya 林視情況與議題性質回應採訪或合作邀請。"}
  ]'::jsonb,
  now()
),

-- 新竹交通
(
  '/hsinchu/transit',
  '新竹縣交通地圖｜公車路線與轉運資訊',
  '新竹縣公車路線、轉運站與學生通勤交通資訊整理，協助了解縣內大眾運輸現況。',
  ARRAY['新竹縣交通','新竹公車','新竹轉運','學生通勤','大眾運輸','新竹縣公車路線','新竹交通地圖'],
  '/og-image.png',
  '這個頁面整理新竹縣的大眾運輸資訊，包含主要公車路線與轉運站分布，特別關注學生通勤使用情境，是 yaya 林推動兒少就學交通安全議題的延伸資源。',
  '[
    {"question": "新竹縣有哪些主要公車轉運站？", "answer": "新竹縣主要的公車轉運節點包含竹北車站、新竹火車站周邊，以及各鄉鎮與學校附近的公車站點。"},
    {"question": "學生如何查詢新竹縣的通勤公車路線？", "answer": "可在 yayalin.com/hsinchu/transit 查看整理好的新竹縣公車路線圖與轉運資訊，也可搭配台灣各地公車 App 使用。"}
  ]'::jsonb,
  now()
)

on conflict (path) do update set
  title        = excluded.title,
  description  = excluded.description,
  keywords     = excluded.keywords,
  og_image     = excluded.og_image,
  geo_summary  = excluded.geo_summary,
  geo_faq      = excluded.geo_faq,
  updated_at   = now();
