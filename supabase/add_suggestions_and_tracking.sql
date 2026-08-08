-- 學生意見箱 + 提案追蹤（時間軸狀態/縣府回應）：貼到 Supabase SQL Editor 執行一次

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

-- ---------- 時間軸：加上提案狀態與縣府回應 ----------
alter table timeline_entries add column if not exists status text;
alter table timeline_entries add column if not exists government_response text;
