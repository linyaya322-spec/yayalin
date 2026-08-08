-- 問卷存取控制（Gmail 白名單／QR Code／密碼）：貼到 Supabase SQL Editor 執行一次

alter table surveys add column if not exists access_mode text not null default 'public'
  check (access_mode in ('public', 'gmail_whitelist', 'qr_code', 'password'));
alter table surveys add column if not exists access_password text;
alter table surveys add column if not exists access_password_expires_at timestamptz;
alter table surveys add column if not exists qr_token text;
alter table surveys add column if not exists qr_token_expires_at timestamptz;

alter table survey_responses add column if not exists respondent_email text;

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

-- 公開可讀/可更新 used_count 是刻意的：這一層驗證是「自報式」防呆，不是真正的身分驗證，
-- 目的是擋掉沒被邀請、沒收到連結的人，不是防止懂技術的人繞過。
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
