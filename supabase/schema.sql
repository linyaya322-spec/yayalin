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

-- ---------- 聯絡表單 ----------
create table if not exists contact_submissions (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  email text not null,
  message text not null,
  case_number text unique,
  case_closed_at timestamptz,
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
  $$本網站（yayalin.com）由站長 yaya 林個人經營，重視每一位訪客的隱私。以下詳細說明本網站會蒐集哪些資料、如何使用、儲存在哪裡，以及你可以怎麼做。使用本網站即表示你已閱讀並理解本政策。

## 我們會蒐集的資料

依照你使用的功能不同，我們蒐集的資料也不同：

- **聯絡表單**：你填寫的姓名、Email、訊息內容。這些資料完全不公開，只有站長看得到，僅用於回覆你的訊息，不會用於其他目的。
- **學生意見箱**：你填寫的建議內容，以及選填的學校、年級、姓名資訊（是否顯示由站長設定）。如果站長開啟「聯絡資訊」欄位，Email 會是必填，用於站長就你的建議回覆一封純文字信件給你。你也可以選擇上傳附件（例如照片、影片、錄音、PDF、Word、Excel 等檔案），附件會存放在不公開的儲存空間，只有站長能夠查看。這些資料完全不公開，只有站長看得到，會作為爭取校園權益、向縣政府等單位提案的參考。
- **問卷**：
  - 你填寫的問卷回覆內容，只有站長看得到，用於了解大家的想法、統計分析，並可能提供給相關單位（例如縣政府）參考。
  - 如果問卷開啟「Gmail 白名單」存取模式，你輸入的 Gmail 信箱會跟你的回覆一起被記錄，用來確認填寫資格與計算已填寫次數。
  - 我們也會記錄「填答過程」的統計資訊（例如你什麼時候開始填、填到第幾題、有沒有完成送出），這是為了讓站長了解問卷的完成率、是否有題目讓大家中途放棄，這部分**不會**記錄你的姓名或身分，純粹是匿名的行為統計。
- **電子報訂閱**：你訂閱時留下的 Email，用於寄送電子報內容給你。你可以隨時透過每封電子報信末的取消訂閱連結退出，退出後我們會保留該筆 Email 記錄但標記為已取消訂閱、不會再寄信給你；如需完全刪除這筆記錄，歡迎透過[聯絡頁面](/contact)告知我們。
- **後台登入**：僅站長本人使用 Email 一次性連結（無密碼）登入管理後台，一般訪客不會被要求登入或提供任何帳號密碼。

## 我們如何使用這些資料

- 回覆你透過聯絡表單或意見箱提出的訊息或建議。
- 統計分析問卷結果，作為公共討論、提案或政策倡議的參考依據，統計結果可能會被整理後分享給政府單位、學校或公開發表，分享出去的通常會是彙整後的統計數據，而不是你個人的原始回覆內容。
- 改善網站功能與使用體驗（例如透過問卷完成率了解題目是否設計得不清楚）。

## 我們不會做的事

- 不會將你的個人資料販售或分享給第三方廣告商。
- 網站沒有安裝任何廣告追蹤程式或第三方分析工具（例如 Google Analytics、Meta Pixel 等），我們不會追蹤你在其他網站上的行為。
- 不會在未經你同意的情況下，公開任何你標記為私密提交的內容（聯絡表單、意見箱、問卷回覆）。

## Cookie 與本機儲存

本網站本身不使用行銷或追蹤用的 Cookie。唯一使用到瀏覽器本機儲存（localStorage）的情況，是站長登入管理後台時，用來保持登入狀態；一般訪客瀏覽網站、填寫表單或問卷，不會被寫入任何登入相關的儲存資料。

## 資料存放與第三方服務

為了讓這個網站能夠運作，我們使用以下第三方服務來儲存或處理資料，這些服務都有各自的隱私權政策：

- **[Supabase](https://supabase.com)**：本網站的資料庫、檔案儲存與登入驗證服務，所有上述提到的資料都儲存在 Supabase 提供的雲端資料庫中。
- **[Resend](https://resend.com)**：用於寄送站長的登入連結信件、當有人送出聯絡表單／學生意見箱建議／問卷回覆時通知站長的信件、站長回覆學生意見箱時寄出的信件，以及寄送你主動訂閱的電子報內容給你；我們不會透過 Resend 寄送你未曾同意訂閱的行銷信件。
- **QR Code 產生服務（api.qrserver.com）**：如果問卷開啟「限時 QR Code」存取模式，站長在後台產生 QR Code 圖片時，問卷連結會短暫傳送到這個第三方服務以產生圖片，這個動作只有站長操作後台時才會發生，一般訪客填寫問卷不會觸發。

## 資料保留期限

除非你要求刪除或站長主動清除，你提交的資料會持續保留在資料庫中，沒有自動到期機制。站長可以在後台針對單一問卷「清空所有回覆」，或刪除整份問卷、意見箱訊息等。

## 你的權利

如果你想查詢、更正或要求刪除你曾經提交給本網站的資料（例如聯絡訊息、問卷回覆），歡迎透過[聯絡頁面](/contact)與站長聯絡，我們會盡快協助處理。

## 未成年使用者

本網站部分內容（例如兒少委員專區、部分問卷）主要面向學生與未成年使用者。我們不會主動要求未成年使用者提供超出功能所需的個人資料（例如聯絡表單、意見箱、多數問卷都可以匿名填寫）；若功能設計上需要填寫學校、年級等資訊，會標示為選填或事先說明用途。

## 政策修改

本隱私權政策可能會隨著網站功能增加而更新，異動後會直接反映在這個頁面上，重大變更會盡量透過首頁或相關頁面提醒訪客。

## 聯絡我們

如果你對本隱私權政策有任何問題，歡迎透過[聯絡頁面](/contact)與我聯絡。
$$
),
(
  'terms',
  '服務條款',
  $$歡迎使用 yayalin.com（以下稱「本網站」）。使用本網站即表示你同意以下條款，請詳細閱讀。本網站由站長 yaya 林個人經營與維護，並非任何政府機關或學校的官方網站。

## 服務內容

本網站提供以下功能：部落格文章閱讀、兒少委員專區（含時間軸與相關文件）、聯絡表單、學生意見箱、線上問卷（填寫、瀏覽統計結果），以及電子報訂閱。站長保留隨時新增、修改或終止任何功能的權利，不另行個別通知。

## 內容使用與智慧財產權

- 網站上的文章、圖片、時間軸內容與其他原創內容，其著作權歸站長所有，僅供個人閱讀與非商業性分享；轉載、引用請註明出處與原始連結。
- 使用者透過意見箱、問卷等功能提交的文字內容，視為授權站長於本網站及站長之後續公開倡議、報告、對外說明等用途使用（例如將問卷統計結果或具代表性的意見整理後對外發表），但站長不會未經同意公開你標記為私密的原始個資（如聯絡表單中的姓名、Email）。

## 學生意見箱與問卷規範

學生意見箱與問卷開放給所有訪客填寫，請提供真實、與主題相關的內容：

- 請勿惡意灌水、重複灌票、留下廣告或不實資訊，站長保留刪除不當回覆、限制填寫次數或關閉問卷的權利。
- 部分問卷可能設有存取限制（例如 Gmail 白名單、限時密碼、限時 QR Code），這些機制設計目的是為了篩選受邀對象、避免問卷被無關人士大量填寫，**不是**保護高度機密資料的安全機制；請勿透過這些問卷填寫你認為需要高度保密的個人資訊。
- 問卷或意見箱的回覆內容與統計結果，可能會被站長整理後用於公共倡議、對外說明或提供給相關單位（例如縣政府）參考，詳細說明請參閱[隱私權政策](/privacy)。

## 電子報訂閱與寄送

- 電子報採自願訂閱制，你可以隨時在網站上訂閱，也可以隨時透過每封信件內的取消訂閱連結退出，不需要任何理由。
- 電子報信件由系統自動寄送，寄件信箱不會有人監看回信，請勿直接回信；如有任何問題或想反映意見，請透過[聯絡頁面](/contact)與站長聯繫。
- 電子報內容為站長個人觀點與資訊分享，不代表任何政府機關、學校或團體的官方立場，詳細資料蒐集與使用方式請參閱[隱私權政策](/privacy)。

## 帳號與後台使用

本網站的管理後台僅供站長本人使用，一般訪客不需要、也不應該嘗試登入或存取後台功能。若你發現任何安全性問題，歡迎透過[聯絡頁面](/contact)告知站長，請勿自行嘗試利用漏洞存取非公開資料。

## 免責聲明

- 網站內容多為站長個人生活紀錄、意見分享與公共議題觀察，不代表任何政府機關、學校或團體的官方立場。
- 若內容涉及公共議題、法規或政策相關資訊，站長會盡量確保正確與更新，但不保證內容完全正確、完整或即時，讀者應自行查證官方資訊來源。
- 本網站依「現況」提供，站長不保證服務不會中斷、沒有錯誤，或能滿足使用者的特定需求；因使用或無法使用本網站所生的任何直接或間接損失，站長不負賠償責任，但法律另有強制規定者不在此限。
- 外部連結（例如問卷附加的相關連結、參考文件）內容由第三方提供，站長不對其內容負責。

## 服務變更與終止

站長保留隨時修改、暫停或終止本網站全部或部分功能的權利。若終止服務導致資料無法繼續存取，站長會盡量提前透過網站公告，但不保證能事先通知每一位使用者。

## 準據法

本條款之解釋與適用，以及與本網站有關的爭議，以中華民國法律為準據法。

## 條款修改

本服務條款可能會隨著網站功能增加而不定期更新，異動後會直接反映在這個頁面上，請不定期回來查看。你在條款更新後繼續使用本網站，視為同意更新後的條款。

## 聯絡我們

有任何問題歡迎透過[聯絡頁面](/contact)與我聯絡。
$$
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
  ('suggestion_box_collect_school', 'false'),
  ('suggestion_box_collect_contact', 'false')
on conflict (key) do nothing;

-- ---------- 學生意見箱（完全私密，只有你在 /write 看得到） ----------
create table if not exists student_suggestions (
  id uuid primary key default gen_random_uuid(),
  message text not null,
  school text,
  grade text,
  contact_name text,
  contact_email text,
  attachment_paths text[],
  admin_reply text,
  reply_status text check (reply_status in ('pending', 'sent')),
  reply_sent_at timestamptz,
  reply_attachment_paths text[],
  case_number text unique,
  case_closed_at timestamptz,
  created_at timestamptz not null default now()
);

alter table student_suggestions enable row level security;

create policy "anyone can submit a suggestion"
  on student_suggestions for insert
  with check (true);

create policy "only admin can read student_suggestions"
  on student_suggestions for select
  using (auth.jwt() ->> 'email' = 'yayalin322@gmail.com');

create policy "only admin can update student_suggestions"
  on student_suggestions for update
  using (auth.jwt() ->> 'email' = 'yayalin322@gmail.com')
  with check (auth.jwt() ->> 'email' = 'yayalin322@gmail.com');

create policy "only admin can delete student_suggestions"
  on student_suggestions for delete
  using (auth.jwt() ->> 'email' = 'yayalin322@gmail.com');

-- ---------- 意見箱附件（儲存桶 suggestion-files，私人，只有站長看得到） ----------
create policy "anyone can upload to suggestion-files"
  on storage.objects for insert
  with check (bucket_id = 'suggestion-files');

create policy "only admin can view suggestion-files"
  on storage.objects for select
  using (bucket_id = 'suggestion-files' and auth.jwt() ->> 'email' = 'yayalin322@gmail.com');

create policy "only admin can delete from suggestion-files"
  on storage.objects for delete
  using (bucket_id = 'suggestion-files' and auth.jwt() ->> 'email' = 'yayalin322@gmail.com');

-- ---------- 學生意見箱：完整對話串 ----------
create table if not exists suggestion_messages (
  id uuid primary key default gen_random_uuid(),
  suggestion_id uuid not null references student_suggestions(id) on delete cascade,
  direction text not null check (direction in ('outbound', 'inbound')),
  body text not null,
  attachment_paths text[],
  status text not null default 'sent' check (status in ('pending', 'sent')),
  sent_at timestamptz,
  created_at timestamptz not null default now()
);

alter table suggestion_messages enable row level security;

create policy "only admin can access suggestion_messages"
  on suggestion_messages for all
  using (auth.jwt() ->> 'email' = 'yayalin322@gmail.com')
  with check (auth.jwt() ->> 'email' = 'yayalin322@gmail.com');

-- ---------- 問卷系統 ----------
create table if not exists surveys (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  description text not null default '',
  is_active boolean not null default true,
  theme text not null default 'clay' check (theme in ('clay', 'sage', 'butter', 'ink')),
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

-- ---------- 電子報 ----------
create table if not exists newsletter_subscribers (
  id uuid primary key default gen_random_uuid(),
  email text not null unique,
  unsubscribe_token uuid not null default gen_random_uuid(),
  subscribed_at timestamptz not null default now(),
  unsubscribed_at timestamptz
);

alter table newsletter_subscribers enable row level security;

create policy "anyone can subscribe to the newsletter"
  on newsletter_subscribers for insert
  with check (true);

create policy "only admin can read newsletter_subscribers"
  on newsletter_subscribers for select
  using (auth.jwt() ->> 'email' = 'yayalin322@gmail.com');

create policy "only admin can delete newsletter_subscribers"
  on newsletter_subscribers for delete
  using (auth.jwt() ->> 'email' = 'yayalin322@gmail.com');

create or replace function unsubscribe_newsletter(p_token uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update newsletter_subscribers
  set unsubscribed_at = now()
  where unsubscribe_token = p_token and unsubscribed_at is null;
end;
$$;

grant execute on function unsubscribe_newsletter(uuid) to anon, authenticated;

create table if not exists newsletters (
  id uuid primary key default gen_random_uuid(),
  subject text not null,
  content text not null,
  status text not null default 'draft' check (status in ('draft', 'sending', 'sent')),
  sent_at timestamptz,
  recipient_count integer,
  target_emails text[],
  created_at timestamptz not null default now()
);

alter table newsletters enable row level security;

create policy "only admin can access newsletters"
  on newsletters for all
  using (auth.jwt() ->> 'email' = 'yayalin322@gmail.com')
  with check (auth.jwt() ->> 'email' = 'yayalin322@gmail.com');

-- ---------- 後台一般收件匣 ----------
create table if not exists inbox_messages (
  id uuid primary key default gen_random_uuid(),
  contact_email text not null,
  subject text,
  direction text not null check (direction in ('outbound', 'inbound')),
  body text not null,
  attachment_paths text[],
  status text not null default 'sent' check (status in ('pending', 'sent')),
  sent_at timestamptz,
  case_number text,
  created_at timestamptz not null default now()
);

alter table inbox_messages enable row level security;

create policy "only admin can access inbox_messages"
  on inbox_messages for all
  using (auth.jwt() ->> 'email' = 'yayalin322@gmail.com')
  with check (auth.jwt() ->> 'email' = 'yayalin322@gmail.com');

-- ---------- 案件編號（學生意見箱、聯絡訊息、收件匣） ----------
create table if not exists case_number_counters (
  day date primary key,
  seq integer not null default 0
);

create or replace function generate_case_number(p_day date default current_date)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  v_seq integer;
begin
  insert into case_number_counters (day, seq) values (p_day, 1)
  on conflict (day) do update set seq = case_number_counters.seq + 1
  returning seq into v_seq;
  return to_char(p_day, 'YYYYMMDD') || '-' || lpad(v_seq::text, 3, '0');
end;
$$;

create or replace function assign_case_number_new_case()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.case_number is null then
    new.case_number := generate_case_number(coalesce(new.created_at::date, current_date));
  end if;
  return new;
end;
$$;

create trigger student_suggestions_case_number
  before insert on student_suggestions
  for each row execute function assign_case_number_new_case();

create trigger contact_submissions_case_number
  before insert on contact_submissions
  for each row execute function assign_case_number_new_case();

-- 收件匣是同一個對話串（同一個 email）共用一個案件編號，不是每筆訊息各給一個
create or replace function assign_inbox_case_number()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_existing text;
begin
  if new.case_number is null then
    select case_number into v_existing
    from inbox_messages
    where lower(contact_email) = lower(new.contact_email) and case_number is not null
    order by created_at asc
    limit 1;
    if v_existing is not null then
      new.case_number := v_existing;
    else
      new.case_number := generate_case_number(coalesce(new.created_at::date, current_date));
    end if;
  end if;
  return new;
end;
$$;

create trigger inbox_messages_case_number
  before insert on inbox_messages
  for each row execute function assign_inbox_case_number();

-- ---------- 送出用的 RPC（讓訪客送出後能拿到案件編號） ----------
create or replace function submit_suggestion(
  p_message text,
  p_school text,
  p_grade text,
  p_contact_name text,
  p_contact_email text,
  p_attachment_paths text[]
)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  v_case_number text;
begin
  insert into student_suggestions (message, school, grade, contact_name, contact_email, attachment_paths)
  values (p_message, p_school, p_grade, p_contact_name, p_contact_email, p_attachment_paths)
  returning case_number into v_case_number;
  return v_case_number;
end;
$$;

grant execute on function submit_suggestion(text, text, text, text, text, text[]) to anon, authenticated;

create or replace function submit_contact(
  p_name text,
  p_email text,
  p_message text
)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  v_case_number text;
begin
  insert into contact_submissions (name, email, message)
  values (p_name, p_email, p_message)
  returning case_number into v_case_number;
  return v_case_number;
end;
$$;

grant execute on function submit_contact(text, text, text) to anon, authenticated;
