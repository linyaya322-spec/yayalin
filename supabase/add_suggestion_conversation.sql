-- 學生意見箱：完整對話串。貼到 Supabase SQL Editor 執行一次。
-- 不含金鑰，安全可以進 git。

create table if not exists suggestion_messages (
  id uuid primary key default gen_random_uuid(),
  suggestion_id uuid not null references student_suggestions(id) on delete cascade,
  direction text not null check (direction in ('outbound', 'inbound')),
  body text not null,
  attachment_paths text[],
  status text not null default 'sent' check (status in ('pending', 'sent')),
  sent_at timestamptz,
  created_at timestamptz not null default now()
);

alter table suggestion_messages enable row level security;

create policy "only admin can access suggestion_messages"
  on suggestion_messages for all
  using (auth.jwt() ->> 'email' = 'yayalin322@gmail.com')
  with check (auth.jwt() ->> 'email' = 'yayalin322@gmail.com');

-- 寫入 inbound（學生回信）紀錄的是 Cloudflare Worker，用 service role 金鑰直接寫入，
-- 會繞過上面這條只允許站長的 RLS 規則，不需要另外開放公開寫入權限。
