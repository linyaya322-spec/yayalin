-- Yaya 林個人網站 — Supabase 資料表 + 權限規則 + 種子資料
-- 使用方式：複製整份貼到 Supabase 專案的 SQL Editor，執行一次即可。

create extension if not exists "pgcrypto";

-- ---------- 部落格文章 ----------
create table if not exists blog_posts (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  date timestamptz not null default now(),
  category text not null check (category in ('生活隨筆', '兒少議題', '興趣分享')),
  excerpt text not null,
  body text not null,
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
