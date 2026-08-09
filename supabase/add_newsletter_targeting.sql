-- 電子報：指定收件人。貼到 Supabase SQL Editor 執行一次。
-- 不含金鑰，安全可以進 git。

alter table newsletters add column if not exists target_emails text[];
