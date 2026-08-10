-- 學生意見箱、聯絡表單、問卷、收件匣：可以標記「結案」，結案滿 30 天後
-- 自動刪除（含附件），撤銷結案就不會被清除。貼到 Supabase SQL Editor 執行一次。
-- 不含金鑰，安全可以進 git。實際自動清除的排程與函式在另一段（含金鑰）SQL 裡。

alter table student_suggestions add column if not exists case_closed_at timestamptz;
alter table contact_submissions add column if not exists case_closed_at timestamptz;
alter table surveys add column if not exists case_closed_at timestamptz;

create table if not exists inbox_threads (
  contact_email text primary key,
  case_closed_at timestamptz
);

alter table inbox_threads enable row level security;

create policy "only admin can access inbox_threads"
  on inbox_threads for all
  using (auth.jwt() ->> 'email' = 'yayalin322@gmail.com')
  with check (auth.jwt() ->> 'email' = 'yayalin322@gmail.com');
