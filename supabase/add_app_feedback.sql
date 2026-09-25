-- TransitGo App 意見回饋：聊天式工單。可重複執行；整段包在交易裡，任何一步失敗就全部不套用。
-- 不含金鑰（寄信一律呼叫網站現有的 send_resend()／email_shell()）。
--
-- 流程
--   App 送出回饋 → submit_app_feedback（需要 request_email_code 寄出的 6 位數驗證碼）→ 一張工單 + 只有這支手機知道的 token
--   雙方都能在工單裡打字（add_app_feedback_message / 後台）、傳照片（儲存桶 app-feedback-files）
--   雙方都能結束對話：你在後台按「結束對話」，使用者在 App 按「結束」
--     你結束的：使用者不能再回，要有新問題請重新送出回饋
--     使用者結束的：使用者可以「重新開啟」
--   新工單、使用者的新訊息、使用者結束對話 → 寄信通知你（含輕重緩急）；你的回覆 → 寄信給使用者
--   讀取工單一律要 token（64 位隨機十六進位），使用者只看得到自己的

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
  -- 狀態：new 新的、in_progress 處理中、waiting 等對方回覆、resolved 已結束
  status text not null default 'new' check (status in ('new', 'in_progress', 'waiting', 'resolved')),
  access_token text not null unique default (replace(gen_random_uuid()::text, '-', '') || replace(gen_random_uuid()::text, '-', '')),
  closed_at timestamptz,
  closed_by text check (closed_by in ('owner', 'user')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  last_reply_at timestamptz
);
alter table app_feedback add column if not exists closed_at timestamptz;
alter table app_feedback add column if not exists closed_by text;
create index if not exists app_feedback_triage_idx on app_feedback (status, priority, created_at desc);
create index if not exists app_feedback_email_idx on app_feedback (email);

create table if not exists app_feedback_messages (
  id uuid primary key default gen_random_uuid(),
  feedback_id uuid not null references app_feedback(id) on delete cascade,
  direction text not null check (direction in ('inbound', 'outbound')),   -- inbound 使用者、outbound 你
  body text not null default '',
  attachment_paths text[],                                                  -- 儲存桶 app-feedback-files 裡的路徑（<token>/<檔名>）
  created_at timestamptz not null default now()
);
alter table app_feedback_messages add column if not exists attachment_paths text[];
alter table app_feedback_messages alter column body set default '';
create index if not exists app_feedback_messages_thread_idx on app_feedback_messages (feedback_id, created_at);

alter table app_feedback enable row level security;
alter table app_feedback_messages enable row level security;

drop policy if exists "only admin can access app_feedback" on app_feedback;
create policy "only admin can access app_feedback" on app_feedback for all
  using (auth.jwt() ->> 'email' = 'yayalin322@gmail.com')
  with check (auth.jwt() ->> 'email' = 'yayalin322@gmail.com');

drop policy if exists "only admin can access app_feedback_messages" on app_feedback_messages;
create policy "only admin can access app_feedback_messages" on app_feedback_messages for all
  using (auth.jwt() ->> 'email' = 'yayalin322@gmail.com')
  with check (auth.jwt() ->> 'email' = 'yayalin322@gmail.com');

-- ---------- 照片：公開儲存桶 + 猜不到的路徑 ----------
-- 路徑是 <token>/<檔名>，token 有 256 位元，所以連結只有這支手機和你知道；沒有人能列出桶內檔案。
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('app-feedback-files', 'app-feedback-files', true, 5242880, array['image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do update
  set public = true, file_size_limit = 5242880, allowed_mime_types = array['image/jpeg', 'image/png', 'image/webp'];

-- 這個 token 對應一張還沒結束的工單嗎？（上傳前的檢查；匿名不能直接讀工單，所以用 security definer）
create or replace function app_feedback_token_open(p_token text)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (select 1 from app_feedback where access_token = p_token and closed_at is null);
$$;
grant execute on function app_feedback_token_open(text) to anon, authenticated;

drop policy if exists "app feedback: phone uploads to its own open ticket" on storage.objects;
create policy "app feedback: phone uploads to its own open ticket" on storage.objects for insert to anon, authenticated
  with check (bucket_id = 'app-feedback-files' and app_feedback_token_open((storage.foldername(name))[1]));

drop policy if exists "app feedback: admin manages files" on storage.objects;
create policy "app feedback: admin manages files" on storage.objects for all to authenticated
  using (bucket_id = 'app-feedback-files' and auth.jwt() ->> 'email' = 'yayalin322@gmail.com')
  with check (bucket_id = 'app-feedback-files' and auth.jwt() ->> 'email' = 'yayalin322@gmail.com');

-- ---------- 小工具 ----------
create or replace function app_feedback_esc(t text)
returns text language sql immutable as $$
  select replace(replace(replace(replace(coalesce(t, ''), '&', '&amp;'), '<', '&lt;'), '>', '&gt;'), chr(10), '<br>')
$$;

create or replace function app_feedback_priority_label(p text)
returns text language sql immutable as $$
  select case p when 'urgent' then '緊急' when 'high' then '重要' when 'low' then '不急' else '一般' end
$$;

-- 附件路徑 → 完整網址（公開儲存桶）。網址前綴放在這裡一處。
create or replace function app_feedback_file_url(p_path text)
returns text language sql immutable as $$
  select 'https://lvxmefggedsozhrdjkqf.supabase.co/storage/v1/object/public/app-feedback-files/' || p_path
$$;

-- ---------- App 呼叫的函式 ----------
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

-- 用 token 讀自己的工單與對話（不含內部的輕重緩急）
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
    'closed_by', v_row.closed_by,
    'created_at', v_row.created_at,
    'messages', coalesce((
      select jsonb_agg(
        jsonb_build_object(
          'direction', m.direction,
          'body', m.body,
          'created_at', m.created_at,
          'attachments', coalesce((select jsonb_agg(app_feedback_file_url(a)) from unnest(m.attachment_paths) a), '[]'::jsonb)
        )
        order by m.created_at
      )
      from app_feedback_messages m
      where m.feedback_id = v_row.id
    ), '[]'::jsonb)
  );
end;
$$;
grant execute on function get_app_feedback(text) to anon, authenticated;

drop function if exists add_app_feedback_message(text, text);

-- 使用者打字／傳照片。已結束的對話不能再發；照片路徑必須在自己的 token 底下，最多 3 張。
create or replace function add_app_feedback_message(p_token text, p_body text, p_attachments text[] default null)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  v_row app_feedback%rowtype;
  v_body text := left(trim(coalesce(p_body, '')), 2000);
  v_paths text[] := coalesce(p_attachments, '{}');
  v_path text;
begin
  select * into v_row from app_feedback where access_token = p_token;
  if not found then
    return false;
  end if;
  if v_row.closed_at is not null then
    raise exception 'conversation_closed';
  end if;
  if array_length(v_paths, 1) > 3 then
    raise exception 'too_many_files';
  end if;
  foreach v_path in array v_paths loop
    if v_path is null or left(v_path, length(p_token) + 1) <> p_token || '/' or length(v_path) > 200 or v_path like '%..%' then
      raise exception 'bad_attachment';
    end if;
  end loop;
  if v_body = '' and array_length(v_paths, 1) is null then
    return false;
  end if;
  if (select count(*) from app_feedback_messages
       where feedback_id = v_row.id and direction = 'inbound' and created_at > now() - interval '1 hour') >= 12 then
    raise exception 'too_many_requests';
  end if;
  insert into app_feedback_messages (feedback_id, direction, body, attachment_paths)
  values (v_row.id, 'inbound', v_body, nullif(v_paths, '{}'));
  update app_feedback
     set status = case when status in ('waiting', 'resolved') then 'new' else status end,
         updated_at = now()
   where id = v_row.id;
  return true;
end;
$$;
grant execute on function add_app_feedback_message(text, text, text[]) to anon, authenticated;

-- 使用者結束對話
create or replace function close_app_feedback(p_token text)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  v_row app_feedback%rowtype;
begin
  select * into v_row from app_feedback where access_token = p_token;
  if not found then
    return false;
  end if;
  if v_row.closed_at is not null then
    return true;
  end if;
  update app_feedback set status = 'resolved', closed_at = now(), closed_by = 'user', updated_at = now() where id = v_row.id;
  perform send_resend(
    'yayalin322@gmail.com',
    '[App 回饋・已結束] ' || v_row.case_number,
    email_shell('使用者結束了對話', '<p>案件 <strong>' || v_row.case_number || '</strong>（' || app_feedback_esc(v_row.email) || '）已由使用者結束。</p>', '在 /write/feedback 可以重新開啟。')
  );
  return true;
end;
$$;
grant execute on function close_app_feedback(text) to anon, authenticated;

-- 使用者重新開啟：只有「使用者自己結束」的可以；你結束的不行（要有新問題就重新送出回饋）
create or replace function reopen_app_feedback(p_token text)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  v_row app_feedback%rowtype;
begin
  select * into v_row from app_feedback where access_token = p_token;
  if not found or v_row.closed_at is null or v_row.closed_by is distinct from 'user' then
    return false;
  end if;
  update app_feedback set status = 'new', closed_at = null, closed_by = null, updated_at = now() where id = v_row.id;
  return true;
end;
$$;
grant execute on function reopen_app_feedback(text) to anon, authenticated;

-- ---------- 寄信（沿用網站現有的 send_resend / email_shell）----------
-- 新訊息（使用者的追問／你的回覆）。第一則 inbound 是工單本身，由 notify_new_app_feedback 通知，這裡略過。
create or replace function app_feedback_message_mail()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_ticket app_feedback%rowtype;
  v_files text := '';
  v_path text;
begin
  select * into v_ticket from app_feedback where id = new.feedback_id;
  if new.attachment_paths is not null then
    foreach v_path in array new.attachment_paths loop
      v_files := v_files || '<p><a href="' || app_feedback_file_url(v_path) || '">照片：' || app_feedback_file_url(v_path) || '</a></p>';
    end loop;
  end if;

  if new.direction = 'outbound' then
    -- 你回覆 → 寄給使用者（回信會進 app@yayalin.com 的收件匣）
    perform send_resend(
      v_ticket.email,
      'Re: 你的 TransitGo 意見回饋（案件 ' || v_ticket.case_number || '）',
      email_shell('我們回覆了你的意見回饋',
        '<p>' || app_feedback_esc(new.body) || '</p>' || v_files ||
        '<p style="color:#888;font-size:12px">案件編號：' || v_ticket.case_number || '。你也可以在 App「設定 › 支援與法律 › 我的回饋」看到這則回覆並繼續回覆，也可以直接回這封信。</p>'),
      'app@yayalin.com'
    );
  elsif (select count(*) from app_feedback_messages where feedback_id = new.feedback_id) > 1 then
    perform send_resend(
      'yayalin322@gmail.com',
      '[App 回饋・' || app_feedback_priority_label(v_ticket.priority) || '] 新訊息 ' || v_ticket.case_number,
      email_shell('使用者回覆了',
        '<p><strong>' || app_feedback_esc(v_ticket.email) || '</strong> 在案件 ' || v_ticket.case_number || ' 說：</p><p>' || app_feedback_esc(new.body) || '</p>' || v_files ||
        '<p><a href="https://yayalin.com/write/feedback">到後台回覆</a></p>'),
      v_ticket.email
    );
  end if;
  return new;
end;
$$;
drop trigger if exists app_feedback_message_mail on app_feedback_messages;
create trigger app_feedback_message_mail after insert on app_feedback_messages
  for each row execute function app_feedback_message_mail();

-- 新工單 → 通知你（主旨帶輕重緩急）
create or replace function notify_new_app_feedback()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  perform send_resend(
    'yayalin322@gmail.com',
    '[App 回饋・' || app_feedback_priority_label(new.priority) || '] ' || new.case_number || '：' || left(regexp_replace(new.message, '\s+', ' ', 'g'), 40),
    email_shell('有新的 App 意見回饋',
      '<p><strong>案件：</strong>' || new.case_number || '（' || case new.kind when 'bug' then '問題回報' when 'idea' then '功能建議' else '其他' end || '）</p>' ||
      '<p><strong>輕重緩急：</strong>' || app_feedback_priority_label(new.priority) || '（系統依內容建議，可在後台調整）</p>' ||
      '<p><strong>Email（已驗證）：</strong>' || app_feedback_esc(new.email) || '</p>' ||
      '<p><strong>App：</strong>' || app_feedback_esc(coalesce(new.app_version, '?')) || '・' || app_feedback_esc(coalesce(new.os, '?')) || '</p>' ||
      '<p>' || app_feedback_esc(new.message) || '</p>' ||
      '<p><a href="https://yayalin.com/write/feedback">到後台回覆</a></p>'),
    new.email
  );
  return new;
end;
$$;
drop trigger if exists app_feedback_notify on app_feedback;
create trigger app_feedback_notify after insert on app_feedback
  for each row execute function notify_new_app_feedback();

commit;
