-- 電子報：訂閱名單 + 電子報草稿/寄送。貼到 Supabase SQL Editor 執行一次。
-- 這個檔案不含任何金鑰，安全可以進 git；寄信用的 trigger（含 Resend API 金鑰）
-- 站長會另外直接在對話裡拿到，不會存進這個檔案。

create table if not exists newsletter_subscribers (
  id uuid primary key default gen_random_uuid(),
  email text not null unique,
  unsubscribe_token uuid not null default gen_random_uuid(),
  subscribed_at timestamptz not null default now(),
  unsubscribed_at timestamptz
);

alter table newsletter_subscribers enable row level security;

create policy "anyone can subscribe to the newsletter"
  on newsletter_subscribers for insert
  with check (true);

create policy "only admin can read newsletter_subscribers"
  on newsletter_subscribers for select
  using (auth.jwt() ->> 'email' = 'yayalin322@gmail.com');

create policy "only admin can delete newsletter_subscribers"
  on newsletter_subscribers for delete
  using (auth.jwt() ->> 'email' = 'yayalin322@gmail.com');

-- 讓訪客可以用自己收到的 token 取消訂閱，不需要開放整張表的 select/update 權限
create or replace function unsubscribe_newsletter(p_token uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update newsletter_subscribers
  set unsubscribed_at = now()
  where unsubscribe_token = p_token and unsubscribed_at is null;
end;
$$;

grant execute on function unsubscribe_newsletter(uuid) to anon, authenticated;

create table if not exists newsletters (
  id uuid primary key default gen_random_uuid(),
  subject text not null,
  content text not null,
  status text not null default 'draft' check (status in ('draft', 'sending', 'sent')),
  sent_at timestamptz,
  recipient_count integer,
  created_at timestamptz not null default now()
);

alter table newsletters enable row level security;

create policy "only admin can access newsletters"
  on newsletters for all
  using (auth.jwt() ->> 'email' = 'yayalin322@gmail.com')
  with check (auth.jwt() ->> 'email' = 'yayalin322@gmail.com');
