-- 時間軸附件（PDF / 連結）：貼到 Supabase SQL Editor 執行一次
-- (儲存桶 timeline-files 已經用 API 建立好了，這裡只需要補權限規則 + 兩個欄位)

alter table timeline_entries add column if not exists pdf_url text;
alter table timeline_entries add column if not exists link_url text;

create policy "public can view timeline-files"
  on storage.objects for select
  using (bucket_id = 'timeline-files');

create policy "only admin can upload to timeline-files"
  on storage.objects for insert
  with check (bucket_id = 'timeline-files' and auth.jwt() ->> 'email' = 'yayalin322@gmail.com');

create policy "only admin can delete from timeline-files"
  on storage.objects for delete
  using (bucket_id = 'timeline-files' and auth.jwt() ->> 'email' = 'yayalin322@gmail.com');
