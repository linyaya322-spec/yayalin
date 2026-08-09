-- 電子報：固定版型（依類型套版）。貼到 Supabase SQL Editor 執行一次。
-- 不含金鑰，安全可以進 git。

alter table newsletters add column if not exists type text not null default 'news' check (type in ('news', 'issue', 'survey'));
alter table newsletters add column if not exists body text;

update newsletters set body = content where body is null;
alter table newsletters alter column body set not null;
