-- 新增「茶葉蛋」分類：貼到 Supabase SQL Editor 執行一次

alter table blog_posts drop constraint if exists blog_posts_category_check;
alter table blog_posts add constraint blog_posts_category_check
  check (category in ('生活隨筆', '兒少議題', '興趣分享', '茶葉蛋'));
