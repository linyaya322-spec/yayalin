-- 問卷系統：貼到 Supabase SQL Editor 執行一次

create table if not exists surveys (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  description text not null default '',
  is_active boolean not null default true,
  link_url text,
  pdf_url text,
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

-- 沿用你之前設定的自動重新部署（如果還沒設定過 trigger_site_rebuild()，這兩個 trigger 會失敗，
-- 先設定過那段自動重新部署 SQL 再執行這裡即可）
create trigger surveys_rebuild
  after insert or update or delete on surveys
  for each statement execute function trigger_site_rebuild();

create trigger survey_questions_rebuild
  after insert or update or delete on survey_questions
  for each statement execute function trigger_site_rebuild();
