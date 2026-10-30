-- 部落格 SEO/GEO 欄位：在 Supabase SQL Editor 執行一次
-- 支援文章自訂搜尋標題、摘要、主題詞，以及封面圖片替代文字。

alter table blog_posts
  add column if not exists seo_title text,
  add column if not exists seo_description text,
  add column if not exists seo_keywords text[] not null default '{}'::text[],
  add column if not exists cover_image_alt text;
