-- 可編輯頁面（關於我／隱私權政策／服務條款）：貼到 Supabase SQL Editor 執行一次

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

insert into site_pages (slug, title, content) values
(
  'about',
  '嗨，我是 Yaya 林',
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
