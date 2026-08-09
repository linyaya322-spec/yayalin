-- 問卷填寫頁風格。貼到 Supabase SQL Editor 執行一次。

alter table surveys add column if not exists theme text not null default 'clay' check (theme in ('clay', 'sage', 'butter', 'ink'));
