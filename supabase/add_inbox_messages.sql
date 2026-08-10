-- 後台一般收件匣：主動寄信、以及回覆寄到 contact@yayalin.com 但沒有意見箱編號的信。
-- 貼到 Supabase SQL Editor 執行一次。不含金鑰，安全可以進 git。

create table if not exists inbox_messages (
  id uuid primary key default gen_random_uuid(),
  contact_email text not null,
  subject text,
  direction text not null check (direction in ('outbound', 'inbound')),
  body text not null,
  attachment_paths text[],
  status text not null default 'sent' check (status in ('pending', 'sent')),
  sent_at timestamptz,
  created_at timestamptz not null default now()
);

alter table inbox_messages enable row level security;

create policy "only admin can access inbox_messages"
  on inbox_messages for all
  using (auth.jwt() ->> 'email' = 'yayalin322@gmail.com')
  with check (auth.jwt() ->> 'email' = 'yayalin322@gmail.com');

-- 寫入 inbound（對方寄來）紀錄的是 Cloudflare Worker，用 service role 金鑰直接寫入，
-- 會繞過上面這條只允許站長的 RLS 規則，不需要另外開放公開寫入權限。
-- 附件沿用學生意見箱既有的 suggestion-files 儲存桶，不需要另外建立。
