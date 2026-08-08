-- 問卷開放/截止時間：貼到 Supabase SQL Editor 執行一次

alter table surveys add column if not exists opens_at timestamptz;
alter table surveys add column if not exists closes_at timestamptz;
