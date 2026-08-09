-- 回覆附件記錄欄位（實際信件用簽名連結附上檔案，不需要改寄送邏輯）。
-- 貼到 Supabase SQL Editor 執行一次，不含金鑰，安全可以進 git。

alter table student_suggestions add column if not exists reply_attachment_paths text[];
