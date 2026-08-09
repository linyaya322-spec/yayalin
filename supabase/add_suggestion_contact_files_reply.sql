-- 學生意見箱：聯絡方式、附件上傳、站長回覆。貼到 Supabase SQL Editor 執行一次。
-- 不含金鑰，安全可以進 git。儲存桶 suggestion-files 已經另外用 API 建立好（私人，只有站長看得到檔案）。

alter table student_suggestions add column if not exists contact_name text;
alter table student_suggestions add column if not exists contact_email text;
alter table student_suggestions add column if not exists attachment_paths text[];
alter table student_suggestions add column if not exists admin_reply text;
alter table student_suggestions add column if not exists reply_status text check (reply_status in ('pending', 'sent'));
alter table student_suggestions add column if not exists reply_sent_at timestamptz;

insert into app_settings (key, value) values
  ('suggestion_box_collect_contact', 'false')
on conflict (key) do nothing;

create policy "only admin can update student_suggestions"
  on student_suggestions for update
  using (auth.jwt() ->> 'email' = 'yayalin322@gmail.com')
  with check (auth.jwt() ->> 'email' = 'yayalin322@gmail.com');

-- ---------- 意見箱附件（儲存桶 suggestion-files，私人，只有站長看得到） ----------
create policy "anyone can upload to suggestion-files"
  on storage.objects for insert
  with check (bucket_id = 'suggestion-files');

create policy "only admin can view suggestion-files"
  on storage.objects for select
  using (bucket_id = 'suggestion-files' and auth.jwt() ->> 'email' = 'yayalin322@gmail.com');

create policy "only admin can delete from suggestion-files"
  on storage.objects for delete
  using (bucket_id = 'suggestion-files' and auth.jwt() ->> 'email' = 'yayalin322@gmail.com');
