-- 文章標籤：貼到 Supabase SQL Editor 執行一次

alter table blog_posts add column if not exists tags text[] not null default '{}'::text[];
