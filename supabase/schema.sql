-- yaya 林個人網站 — Supabase 資料表 + 權限規則 + 種子資料
-- 使用方式：複製整份貼到 Supabase 專案的 SQL Editor，執行一次即可。

create extension if not exists "pgcrypto";

-- ---------- 部落格文章 ----------
create table if not exists blog_posts (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  date timestamptz not null default now(),
  category text not null check (category in ('生活隨筆', '兒少議題', '興趣分享', '茶葉蛋')),
  excerpt text not null,
  body text not null,
  cover_image text,
  tags text[] not null default '{}'::text[],
  created_at timestamptz not null default now()
);

alter table blog_posts enable row level security;

create policy "blog_posts are publicly readable"
  on blog_posts for select
  using (true);

create policy "only admin can write blog_posts"
  on blog_posts for all
  using (auth.jwt() ->> 'email' = 'yayalin322@gmail.com')
  with check (auth.jwt() ->> 'email' = 'yayalin322@gmail.com');

-- ---------- 兒少委員時間軸 ----------
create table if not exists timeline_entries (
  id uuid primary key default gen_random_uuid(),
  date timestamptz not null default now(),
  title text not null,
  description text not null,
  pdf_url text,
  link_url text,
  status text,
  government_response text,
  created_at timestamptz not null default now()
);

alter table timeline_entries enable row level security;

create policy "timeline_entries are publicly readable"
  on timeline_entries for select
  using (true);

create policy "only admin can write timeline_entries"
  on timeline_entries for all
  using (auth.jwt() ->> 'email' = 'yayalin322@gmail.com')
  with check (auth.jwt() ->> 'email' = 'yayalin322@gmail.com');

-- ---------- 今日小語 ----------
create table if not exists quotes (
  id uuid primary key default gen_random_uuid(),
  text text not null,
  created_at timestamptz not null default now()
);

alter table quotes enable row level security;

create policy "quotes are publicly readable"
  on quotes for select
  using (true);

create policy "only admin can write quotes"
  on quotes for all
  using (auth.jwt() ->> 'email' = 'yayalin322@gmail.com')
  with check (auth.jwt() ->> 'email' = 'yayalin322@gmail.com');

-- ---------- 訪客留言板 ----------
create table if not exists guestbook_messages (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  message text not null,
  is_approved boolean not null default false,
  created_at timestamptz not null default now()
);

alter table guestbook_messages enable row level security;

create policy "anyone can leave a guestbook message"
  on guestbook_messages for insert
  with check (true);

create policy "only approved guestbook messages are publicly readable"
  on guestbook_messages for select
  using (is_approved = true or auth.jwt() ->> 'email' = 'yayalin322@gmail.com');

create policy "only admin can moderate guestbook_messages"
  on guestbook_messages for update
  using (auth.jwt() ->> 'email' = 'yayalin322@gmail.com')
  with check (auth.jwt() ->> 'email' = 'yayalin322@gmail.com');

create policy "only admin can delete guestbook_messages"
  on guestbook_messages for delete
  using (auth.jwt() ->> 'email' = 'yayalin322@gmail.com');

-- ---------- 聯絡表單 ----------
create table if not exists contact_submissions (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  email text not null,
  message text not null,
  created_at timestamptz not null default now()
);

alter table contact_submissions enable row level security;

create policy "anyone can submit the contact form"
  on contact_submissions for insert
  with check (true);

create policy "only admin can read contact_submissions"
  on contact_submissions for select
  using (auth.jwt() ->> 'email' = 'yayalin322@gmail.com');

create policy "only admin can delete contact_submissions"
  on contact_submissions for delete
  using (auth.jwt() ->> 'email' = 'yayalin322@gmail.com');

-- ---------- 可編輯頁面（關於我／隱私權政策／服務條款） ----------
create table if not exists site_pages (
  slug text primary key,
  title text not null,
  content text not null,
  updated_at timestamptz not null default now()
);

alter table site_pages enable row level security;

create policy "site_pages are publicly readable"
  on site_pages for select
  using (true);

create policy "only admin can write site_pages"
  on site_pages for all
  using (auth.jwt() ->> 'email' = 'yayalin322@gmail.com')
  with check (auth.jwt() ->> 'email' = 'yayalin322@gmail.com');

-- ---------- 種子資料：把目前網站上的範例內容搬進來 ----------

insert into blog_posts (title, date, category, excerpt, body) values
(
  '嗨，這裡是我的新窩',
  '2026-08-01',
  '生活隨筆',
  '第一篇文章，紀錄一下建立這個網站的心情，也算是跟大家打個招呼。',
  $$其實猶豫了很久才決定要有自己的網站。一直覺得「這種事等我準備好再做」，後來發現根本沒有準備好的一天，不如就先開始寫。

這裡會放一些生活的隨筆、身為兒少委員參與公共事務的紀錄，還有一些我自己的興趣分享。想到什麼就寫什麼，希望之後回頭看的時候，能看到自己一點一點的成長。

謝謝你看到這裡，歡迎常來逛逛。$$
),
(
  '第一次參加兒少委員會議的心情',
  '2026-08-03',
  '兒少議題',
  '從緊張到敢舉手發言，紀錄我第一次參與縣府會議的觀察與感想。',
  $$第一次坐進會議室的時候，說真的滿緊張的。桌子對面都是平常在新聞裡才會看到的長官，而我是代表所有像我一樣的青少年，把我們的想法帶進這個場合。

會議討論的是校園周邊的通學安全，我把之前收集到同學們的意見整理成三點，鼓起勇氣講完之後，發現大家其實都很願意聽、也會認真回應。那一刻覺得，原來我們的聲音真的可以被聽見。

之後會慢慢把每次參與的重點紀錄在「兒少委員專區」，如果你也對青少年參與公共事務有興趣，歡迎一起討論。$$
),
(
  '最近迷上的幾件小事',
  '2026-08-05',
  '興趣分享',
  '分享幾個最近讓我很療癒的小興趣，歡迎推薦更多給我。',
  $$除了學校跟委員會的事情，我也想分享一些讓自己放鬆的小興趣：

- **拍照**：喜歡用手機隨手拍下天空跟路邊的植物，沒什麼技巧，純粹紀錄心情。
- **手寫筆記**：比起打字，手寫更能讓我靜下來整理思緒。
- **散步**：沒有目的地的散步，常常會想通一些卡住的事情。

如果你也有類似的興趣，或有什麼想推薦給我的，歡迎透過聯絡頁面跟我說。$$
);

insert into timeline_entries (date, title, description) values
('2026-01-15', '獲選為新竹縣兒少委員', '通過遴選，正式成為新竹縣兒童及少年福利與權益促進委員會的青少年代表委員。'),
('2026-03-10', '參加新任委員培力工作坊', '與其他縣市的兒少代表交流，學習如何在會議中有效表達訴求、蒐集同儕意見。'),
('2026-08-03', '出席第一次全體委員會議', '就校園周邊通學安全議題，代表青少年提出三項具體建議，並獲得與會委員回應與討論。');

insert into quotes (text) values
('慢慢來，比較快。'),
('今天的自己，已經很努力了。'),
('有些聲音很小，但值得被聽見。'),
('先照顧好自己，才有力氣照顧別人。'),
('每一次舉手發言，都是一次練習。'),
('累的時候，休息也是一種前進。'),
('小小的行動，也能推動一點點改變。');

insert into site_pages (slug, title, content) values
(
  'about',
  '嗨，我是 yaya 林',
  $$目前是一名學生，同時也是新竹縣兒少委員，希望能把同齡人的想法帶進公共討論裡，也讓更多人知道青少年其實很願意參與、很願意被聽見。

平常喜歡觀察生活裡的小細節，拍照、手寫筆記、沒有目的地的散步，都是我讓自己慢下來的方式。這個網站是我紀錄這些事情的地方——有正經的公共議題，也有很日常的碎碎念。

如果你也關心青少年參與、或只是想跟我聊聊天，歡迎透過[聯絡頁面](/contact)找我。$$
),
(
  'privacy',
  '隱私權政策',
  $$本網站重視你的隱私，以下說明我們會蒐集哪些資料、如何使用。

## 我們會蒐集的資料

- **留言板**：你留言時填寫的暱稱與留言內容，會先送進審核，經過核准才會公開顯示在網站上。
- **聯絡表單**：你填寫的姓名、Email、訊息內容，只有網站管理者看得到，不會公開顯示，僅用於回覆你的訊息。
- **學生意見箱**：你填寫的建議內容（及選填的學校/年級），完全不公開，只有網站管理者看得到，會作為爭取校園權益、向縣政府等單位提案的參考。
- **問卷**：你填寫的問卷回覆內容，只有網站管理者看得到，用於了解大家的想法、統計分析，並可能提供給相關單位（例如縣政府）參考。
- **後台登入**：僅網站管理者本人使用 Email 一次性連結登入後台，一般訪客不會被要求登入或提供帳號密碼。

## 我們不會做的事

- 不會將你的個人資料賣給或分享給第三方。
- 網站沒有安裝廣告追蹤或第三方分析工具。

## 資料存放

網站內容與表單資料使用 [Supabase](https://supabase.com) 儲存與管理。

## 聯絡我們

如果你對隱私權政策有任何問題，歡迎透過[聯絡頁面](/contact)與我聯絡。$$
),
(
  'terms',
  '服務條款',
  $$歡迎使用這個網站，使用本網站即表示你同意以下條款。

## 內容使用

網站上的文章、圖片與其他內容僅供個人閱讀與非商業性分享，轉載或引用請註明出處。

## 留言板規範

留言板開放給所有訪客使用，請勿留下以下內容，管理者有權不予公開或事後移除：

- 廣告、垃圾訊息或詐騙連結
- 人身攻擊、歧視或不實指控
- 違反法律規定的內容

## 學生意見箱與問卷規範

學生意見箱與問卷開放給所有訪客填寫，請提供真實、與主題相關的內容，請勿惡意灌水、留下廣告或不實資訊。管理者保留刪除不當回覆的權利。

## 免責聲明

網站內容多為個人生活紀錄與意見分享，不代表任何機關立場，若有引用公共議題相關資訊，會盡量確保正確，但不保證完全無誤。

## 條款修改

本條款可能會不定期更新，異動後會直接反映在這個頁面上。

## 聯絡我們

有任何問題歡迎透過[聯絡頁面](/contact)與我聯絡。$$
),
(
  'committee-intro',
  '什麼是兒少代表？',
  $$兒少代表（全名「兒童及少年福利與權益促進委員會委員」）是政府依法邀請青少年參與地方公共事務的機制，讓 18 歲以下的兒童及少年也能對跟自己切身相關的政策表達意見。

新竹縣兒少委員會由各局處代表、專家學者，以及像我這樣的青少年代表共同組成，定期召開會議，討論教育、交通安全、學生權益等與兒少相關的議題，並可以正式提案給縣政府。

我在這裡的每一次參與，都是想讓「大人世界」多聽一點「我們的想法」。$$
)
on conflict (slug) do nothing;

-- ---------- 網站設定（目前只用來控制意見箱要不要收集學校/年級） ----------
create table if not exists app_settings (
  key text primary key,
  value text not null
);

alter table app_settings enable row level security;

create policy "app_settings are publicly readable"
  on app_settings for select
  using (true);

create policy "only admin can write app_settings"
  on app_settings for all
  using (auth.jwt() ->> 'email' = 'yayalin322@gmail.com')
  with check (auth.jwt() ->> 'email' = 'yayalin322@gmail.com');

insert into app_settings (key, value) values
  ('suggestion_box_collect_school', 'false')
on conflict (key) do nothing;

-- ---------- 學生意見箱（完全私密，只有你在 /write 看得到） ----------
create table if not exists student_suggestions (
  id uuid primary key default gen_random_uuid(),
  message text not null,
  school text,
  grade text,
  created_at timestamptz not null default now()
);

alter table student_suggestions enable row level security;

create policy "anyone can submit a suggestion"
  on student_suggestions for insert
  with check (true);

create policy "only admin can read student_suggestions"
  on student_suggestions for select
  using (auth.jwt() ->> 'email' = 'yayalin322@gmail.com');

create policy "only admin can delete student_suggestions"
  on student_suggestions for delete
  using (auth.jwt() ->> 'email' = 'yayalin322@gmail.com');

-- ---------- 問卷系統 ----------
create table if not exists surveys (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  description text not null default '',
  is_active boolean not null default true,
  link_url text,
  pdf_url text,
  opens_at timestamptz,
  closes_at timestamptz,
  access_mode text not null default 'public' check (access_mode in ('public', 'gmail_whitelist', 'qr_code', 'password')),
  access_password text,
  access_password_expires_at timestamptz,
  qr_token text,
  qr_token_expires_at timestamptz,
  created_at timestamptz not null default now()
);

alter table surveys enable row level security;

create policy "surveys are publicly readable"
  on surveys for select
  using (true);

create policy "only admin can write surveys"
  on surveys for all
  using (auth.jwt() ->> 'email' = 'yayalin322@gmail.com')
  with check (auth.jwt() ->> 'email' = 'yayalin322@gmail.com');

create table if not exists survey_allowed_emails (
  id uuid primary key default gen_random_uuid(),
  survey_id uuid not null references surveys(id) on delete cascade,
  email text not null,
  max_submissions integer not null default 1,
  used_count integer not null default 0,
  created_at timestamptz not null default now(),
  unique (survey_id, email)
);

alter table survey_allowed_emails enable row level security;

create policy "anyone can read survey_allowed_emails"
  on survey_allowed_emails for select
  using (true);

create policy "anyone can update used_count on survey_allowed_emails"
  on survey_allowed_emails for update
  using (true)
  with check (true);

create policy "only admin can insert survey_allowed_emails"
  on survey_allowed_emails for insert
  with check (auth.jwt() ->> 'email' = 'yayalin322@gmail.com');

create policy "only admin can delete survey_allowed_emails"
  on survey_allowed_emails for delete
  using (auth.jwt() ->> 'email' = 'yayalin322@gmail.com');

create table if not exists survey_questions (
  id uuid primary key default gen_random_uuid(),
  survey_id uuid not null references surveys(id) on delete cascade,
  position integer not null default 0,
  question_text text not null,
  type text not null check (type in ('text', 'single', 'multiple')),
  required boolean not null default false,
  options jsonb not null default '[]'::jsonb,
  created_at timestamptz not null default now()
);

alter table survey_questions enable row level security;

create policy "survey_questions are publicly readable"
  on survey_questions for select
  using (true);

create policy "only admin can write survey_questions"
  on survey_questions for all
  using (auth.jwt() ->> 'email' = 'yayalin322@gmail.com')
  with check (auth.jwt() ->> 'email' = 'yayalin322@gmail.com');

create table if not exists survey_responses (
  id uuid primary key default gen_random_uuid(),
  survey_id uuid not null references surveys(id) on delete cascade,
  answers jsonb not null default '{}'::jsonb,
  respondent_email text,
  submitted_at timestamptz not null default now()
);

alter table survey_responses enable row level security;

create policy "anyone can submit a survey response"
  on survey_responses for insert
  with check (true);

create policy "only admin can read survey_responses"
  on survey_responses for select
  using (auth.jwt() ->> 'email' = 'yayalin322@gmail.com');

create policy "only admin can delete survey_responses"
  on survey_responses for delete
  using (auth.jwt() ->> 'email' = 'yayalin322@gmail.com');

-- ---------- 問卷完成率/中途離開追蹤 ----------
create table if not exists survey_progress (
  id uuid primary key default gen_random_uuid(),
  survey_id uuid not null references surveys(id) on delete cascade,
  furthest_position integer not null default 0,
  status text not null default 'in_progress' check (status in ('in_progress', 'submitted', 'closed')),
  started_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table survey_progress enable row level security;

create policy "anyone can insert survey_progress"
  on survey_progress for insert
  with check (true);

create policy "anyone can update survey_progress"
  on survey_progress for update
  using (true)
  with check (true);

create policy "only admin can read survey_progress"
  on survey_progress for select
  using (auth.jwt() ->> 'email' = 'yayalin322@gmail.com');

create policy "only admin can delete survey_progress"
  on survey_progress for delete
  using (auth.jwt() ->> 'email' = 'yayalin322@gmail.com');

-- ---------- 文章圖片（儲存桶 post-images 需另外用 Storage API/介面建立，公開讀取） ----------

create policy "public can view post-images"
  on storage.objects for select
  using (bucket_id = 'post-images');

create policy "only admin can upload to post-images"
  on storage.objects for insert
  with check (bucket_id = 'post-images' and auth.jwt() ->> 'email' = 'yayalin322@gmail.com');

create policy "only admin can delete from post-images"
  on storage.objects for delete
  using (bucket_id = 'post-images' and auth.jwt() ->> 'email' = 'yayalin322@gmail.com');

-- ---------- 時間軸附件（儲存桶 timeline-files 需另外用 Storage API/介面建立，公開讀取） ----------

create policy "public can view timeline-files"
  on storage.objects for select
  using (bucket_id = 'timeline-files');

create policy "only admin can upload to timeline-files"
  on storage.objects for insert
  with check (bucket_id = 'timeline-files' and auth.jwt() ->> 'email' = 'yayalin322@gmail.com');

create policy "only admin can delete from timeline-files"
  on storage.objects for delete
  using (bucket_id = 'timeline-files' and auth.jwt() ->> 'email' = 'yayalin322@gmail.com');
