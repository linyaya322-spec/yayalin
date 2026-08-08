-- 問卷完成率/中途離開追蹤：貼到 Supabase SQL Editor 執行一次

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
