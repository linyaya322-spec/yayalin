-- 圖片上傳功能：貼到 Supabase SQL Editor 執行一次
-- (儲存桶 post-images 已經用 API 建立好了，這裡只需要補權限規則 + 一個欄位)

alter table blog_posts add column if not exists cover_image text;

create policy "public can view post-images"
  on storage.objects for select
  using (bucket_id = 'post-images');

create policy "only admin can upload to post-images"
  on storage.objects for insert
  with check (bucket_id = 'post-images' and auth.jwt() ->> 'email' = 'yayalin322@gmail.com');

create policy "only admin can delete from post-images"
  on storage.objects for delete
  using (bucket_id = 'post-images' and auth.jwt() ->> 'email' = 'yayalin322@gmail.com');
