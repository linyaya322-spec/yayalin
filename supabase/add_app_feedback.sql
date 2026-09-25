-- TransitGo App 意見回饋：工單（案件編號、輕重緩急、狀態、來回對話）。貼到 Supabase SQL Editor 執行一次（可重複執行）。
-- 不含金鑰，安全可以進 git。整段包在交易裡：任何一步失敗就全部不套用。
--
-- 流程：
--   App 呼叫 submit_app_feedback（需要 request_email_code 寄出的 6 位數驗證碼，沿用網站聯絡表單那一套）
--     → 建立一張工單，回傳案件編號與只有這支手機知道的 token
--   App 用 token 呼叫 get_app_feedback 看回覆、add_app_feedback_message 追問
--   你在 /write/feedback 依優先級處理、回覆（回覆會寄 Email，並讓 App 看到）
-- App 不能列出別人的工單：所有讀取都要 token，token 是 64 位隨機十六進位，猜不到。

begin;

create sequence if not exists app_feedback_seq;

create table if not exists app_feedback (
  id uuid primary key default gen_random_uuid(),
  case_number text not null unique
    default ('A' || to_char(now() at time zone 'Asia/Taipei', 'YYMMDD') || '-' || lpad(nextval('app_feedback_seq')::text, 4, '0')),
  kind text not null check (kind in ('bug', 'idea', 'other')),
  message text not null,
  email text not null,
  email_verified_at timestamptz not null default now(),
  app_version text,
  os text,
  -- 輕重緩急：urgent 緊急、high 重要、normal 一般、low 不急
  priority text not null default 'normal' check (priority in ('urgent', 'high', 'normal', 'low')),
  -- 狀態：new 新的、in_progress 處理中、waiting 等對方回覆、resolved 已解決
  status text not null default 'new' check (status in ('new', 'in_progress', 'waiting', 'resolved')),
  access_token text not null unique default (replace(gen_random_uuid()::text, '-', '') || replace(gen_random_uuid()::text, '-', '')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  last_reply_at timestamptz
);
create index if not exists app_feedback_triage_idx on app_feedback (status, priority, created_at desc);
create index if not exists app_feedback_email_idx on app_feedback (email);

create table if not exists app_feedback_messages (
  id uuid primary key default gen_random_uuid(),
  feedback_id uuid not null references app_feedback(id) on delete cascade,
  direction text not null check (direction in ('inbound', 'outbound')),   -- inbound 使用者、outbound 你的回覆
  body text not null,
  created_at timestamptz not null default now()
);
create index if not exists app_feedback_messages_thread_idx on app_feedback_messages (feedback_id, created_at);

alter table app_feedback enable row level security;
alter table app_feedback_messages enable row level security;

drop policy if exists "only admin can access app_feedback" on app_feedback;
create policy "only admin can access app_feedback"
  on app_feedback for all
  using (auth.jwt() ->> 'email' = 'yayalin322@gmail.com')
  with check (auth.jwt() ->> 'email' = 'yayalin322@gmail.com');

drop policy if exists "only admin can access app_feedback_messages" on app_feedback_messages;
create policy "only admin can access app_feedback_messages"
  on app_feedback_messages for all
  using (auth.jwt() ->> 'email' = 'yayalin322@gmail.com')
  with check (auth.jwt() ->> 'email' = 'yayalin322@gmail.com');

-- 送出回饋：驗證碼對才會建立；回傳 { case_number, token }，驗證碼錯／過期／用過回傳 null
create or replace function submit_app_feedback(
  p_kind text,
  p_message text,
  p_email text,
  p_code text,
  p_app_version text default null,
  p_os text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_kind text := coalesce(nullif(trim(p_kind), ''), 'other');
  v_message text := left(trim(coalesce(p_message, '')), 4000);
  v_email text := lower(trim(coalesce(p_email, '')));
  v_priority text;
  v_row app_feedback%rowtype;
begin
  if v_kind not in ('bug', 'idea', 'other') then
    v_kind := 'other';
  end if;
  if v_message = '' then
    raise exception 'empty_message';
  end if;
  if v_email !~ '^[^@\s]+@[^@\s]+\.[^@\s]+$' then
    raise exception 'invalid_email';
  end if;
  if not consume_email_code(v_email, 'contact', p_code) then
    return null;
  end if;
  if (select count(*) from app_feedback where email = v_email and created_at > now() - interval '1 day') >= 10 then
    raise exception 'too_many_requests';
  end if;

  -- 第一次分級的建議值（你之後可以在後台改）：功能建議不急；問題回報裡出現閃退、打不開、無法…等字眼先標「重要」
  v_priority := case
    when v_kind = 'idea' then 'low'
    when v_kind = 'bug' and v_message ~* '(閃退|當機|crash|打不開|無法|不能|沒辦法|沒反應|扣款|付款|登入)' then 'high'
    else 'normal'
  end;

  insert into app_feedback (kind, message, email, app_version, os, priority)
  values (v_kind, v_message, v_email, left(p_app_version, 40), left(p_os, 80), v_priority)
  returning * into v_row;

  insert into app_feedback_messages (feedback_id, direction, body)
  values (v_row.id, 'inbound', v_message);

  return jsonb_build_object('case_number', v_row.case_number, 'token', v_row.access_token);
end;
$$;
grant execute on function submit_app_feedback(text, text, text, text, text, text) to anon, authenticated;

-- 用 token 讀自己的工單與對話（不含內部優先級）
create or replace function get_app_feedback(p_token text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_row app_feedback%rowtype;
begin
  select * into v_row from app_feedback where access_token = p_token;
  if not found then
    return null;
  end if;
  return jsonb_build_object(
    'case_number', v_row.case_number,
    'kind', v_row.kind,
    'status', v_row.status,
    'created_at', v_row.created_at,
    'messages', coalesce((
      select jsonb_agg(
        jsonb_build_object('direction', m.direction, 'body', m.body, 'created_at', m.created_at)
        order by m.created_at
      )
      from app_feedback_messages m
      where m.feedback_id = v_row.id
    ), '[]'::jsonb)
  );
end;
$$;
grant execute on function get_app_feedback(text) to anon, authenticated;

-- 使用者追問（在 App 的「我的回饋」）；已解決或等對方回覆的工單會重新變成「新的」
create or replace function add_app_feedback_message(p_token text, p_body text)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  v_row app_feedback%rowtype;
  v_body text := left(trim(coalesce(p_body, '')), 2000);
begin
  if v_body = '' then
    return false;
  end if;
  select * into v_row from app_feedback where access_token = p_token;
  if not found then
    return false;
  end if;
  if (select count(*) from app_feedback_messages
       where feedback_id = v_row.id and direction = 'inbound' and created_at > now() - interval '1 hour') >= 10 then
    raise exception 'too_many_requests';
  end if;
  insert into app_feedback_messages (feedback_id, direction, body) values (v_row.id, 'inbound', v_body);
  update app_feedback
     set status = case when status in ('waiting', 'resolved') then 'new' else status end,
         updated_at = now()
   where id = v_row.id;
  return true;
end;
$$;
grant execute on function add_app_feedback_message(text, text) to anon, authenticated;

commit;
