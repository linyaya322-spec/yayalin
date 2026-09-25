-- TransitGo App 的信件：獨立的外觀、以 app@yayalin.com 名義寄出，不帶個人網站的身分。可重複執行；整段在交易裡。
-- 前提：已執行 add_app_feedback.sql。不含金鑰：寄信的 Resend 金鑰留在資料庫裡，
-- send_resend_from 是在資料庫內由既有的 send_resend 衍生出來的（只換寄件人與預設回信地址），金鑰不會離開資料庫。
--
-- 之後 App 的信（驗證碼、新回饋通知、對方的追問、你的回覆、對話結束）都走：
--   寄件人  交通即時查 TransitGo <app@yayalin.com>
--   外觀    app_email_shell（藍色 TransitGo 風格，深色模式），跟個人網站的黃色信件框不同
-- 網站原本的信（聯絡表單、意見箱、電子報…）完全不動。

begin;

-- ---------- 1) 驗證碼多一種用途 'app'（App 與網站的驗證碼信才能各用各的外觀）----------
alter table email_verifications drop constraint if exists email_verifications_purpose_check;
alter table email_verifications add constraint email_verifications_purpose_check
  check (purpose in ('suggestion', 'contact', 'app'));

create or replace function request_email_code(p_email text, p_purpose text)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_email text := lower(trim(p_email));
begin
  if v_email is null or v_email !~ '^[^@\s]+@[^@\s]+\.[^@\s]+$' then
    raise exception 'invalid_email';
  end if;
  if p_purpose not in ('suggestion', 'contact', 'app') then
    raise exception 'invalid_purpose';
  end if;
  if (select count(*) from email_verifications
       where email = v_email and created_at > now() - interval '1 hour') >= 5 then
    raise exception 'too_many_requests';
  end if;
  insert into email_verifications (email, purpose, code)
  values (v_email, p_purpose, lpad(floor(random() * 1000000)::int::text, 6, '0'));
end;
$$;
grant execute on function request_email_code(text, text) to anon, authenticated;

-- ---------- 2) 可以指定寄件人的寄信函式（金鑰不離開資料庫）----------
do $$
declare
  v_src text;
begin
  select prosrc into v_src from pg_proc
   where proname = 'send_resend' and pronamespace = 'public'::regnamespace and pronargs = 4;
  if v_src is null or position($q$'yaya 林 <contact@yayalin.com>'$q$ in v_src) = 0 then
    raise exception 'send_resend 的內容和預期不同，為了安全不建立 send_resend_from';
  end if;
  v_src := replace(v_src, $q$'yaya 林 <contact@yayalin.com>'$q$, 'p_from');
  v_src := replace(v_src, $q$'contact@yayalin.com'$q$, $q$'app@yayalin.com'$q$);   -- 預設的回信地址
  execute format(
    $f$create or replace function public.send_resend_from(p_from text, p_to text, p_subject text, p_html text, p_reply_to text default null)
       returns void language plpgsql security definer set search_path = public as %L$f$, v_src);
end;
$$;
-- 跟 send_resend 一樣：只有資料庫內部（觸發器）與 service_role 能呼叫，匿名／登入使用者都不行
revoke all on function send_resend_from(text, text, text, text, text) from public, anon, authenticated;
grant execute on function send_resend_from(text, text, text, text, text) to service_role;

-- ---------- 3) App 的信件外觀 ----------
create or replace function app_email_shell(p_title text, p_body text, p_footer text default '')
returns text
language sql
immutable
as $shell$
  select replace(replace(replace($t$<!DOCTYPE html><html lang="zh-Hant"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<meta name="color-scheme" content="light dark"><meta name="supported-color-schemes" content="light dark">
<style>
:root{color-scheme:light dark;supported-color-schemes:light dark}
@media (prefers-color-scheme: dark){
.ap-bg{background-color:#0d1220 !important}
.ap-card{background-color:#161d30 !important;border-color:#27314a !important}
.ap-head{background-color:#1d3f7a !important}
.ap-body,.ap-body *{color:#edf0f7 !important}
.ap-muted,.ap-muted *{color:#9aa5be !important}
.ap-quote{background-color:#1e2740 !important;border-color:#3a4a73 !important}
.ap-code{background-color:#1e2740 !important;color:#8fb8ff !important;border-color:#3a4a73 !important}
.ap-foot{border-color:#27314a !important}
a{color:#8fb8ff !important}
}
</style></head>
<body class="ap-bg" style="margin:0;padding:0;background-color:#f5f7fb">
<div class="ap-bg" style="background-color:#f5f7fb;padding:24px 12px;font-family:-apple-system,'PingFang TC','Noto Sans TC','Microsoft JhengHei',sans-serif">
<div class="ap-card" style="max-width:560px;margin:0 auto;background-color:#ffffff;border:1px solid #dfe4ee;border-radius:16px;overflow:hidden">
<div class="ap-head" style="background-color:#0a6cf0;padding:18px 24px"><span style="font-size:20px;vertical-align:middle">🚌</span> <span style="color:#ffffff;font-size:17px;font-weight:700;vertical-align:middle;letter-spacing:.3px">交通即時查 TransitGo</span></div>
<div class="ap-body" style="padding:26px 24px 8px;color:#1a2233;font-size:15px;line-height:1.8">
<h1 style="margin:0 0 14px;font-size:20px;line-height:1.4;color:#1a2233">{{title}}</h1>
{{body}}
</div>
<div class="ap-foot ap-muted" style="margin:18px 24px 0;padding:14px 0 22px;border-top:1px solid #dfe4ee;color:#5b6579;font-size:12px;line-height:1.7">{{footer}}這封信由「交通即時查 TransitGo」寄出，直接回信即可聯絡我們。</div>
</div></div></body></html>$t$, '{{title}}', p_title), '{{body}}', p_body), '{{footer}}', case when coalesce(p_footer, '') = '' then '' else p_footer || '<br>' end)
$shell$;

-- ---------- 4) 驗證碼信：用途是 app 就用 App 的外觀，其他維持原樣 ----------
create or replace function send_email_code()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.purpose = 'app' then
    perform send_resend_from(
      '交通即時查 TransitGo <app@yayalin.com>',
      new.email,
      '交通即時查 TransitGo 驗證碼：' || new.code,
      app_email_shell(
        '你的 Email 驗證碼',
        '<p style="margin:0 0 16px">請回到 App 輸入下面的 6 位數驗證碼，10 分鐘內有效：</p>'
        || '<p class="ap-code" style="margin:0 0 20px;font-size:32px;font-weight:700;letter-spacing:8px;background-color:#eaf2ff;display:inline-block;padding:8px 20px;border:1px solid #b9d2ff;border-radius:10px;color:#0a5bd0">' || new.code || '</p>'
        || '<p class="ap-muted" style="margin:0;font-size:13px;color:#5b6579">如果你沒有在「交通即時查」App 索取驗證碼，請直接忽略這封信。</p>'
      )
    );
  else
    perform send_resend(
      new.email,
      '你的驗證碼：' || new.code,
      email_shell(
        '你的 Email 驗證碼',
        '<p style="margin:0 0 16px">請回到網站輸入下面的 6 位數驗證碼，10 分鐘內有效：</p>'
        || '<p class="em-code" style="margin:0 0 20px;font-size:32px;font-weight:700;letter-spacing:8px;background-color:#fff7b0;display:inline-block;padding:8px 20px;border:2px solid #1d2742;color:#1d2742">' || new.code || '</p>'
        || '<p class="em-muted" style="margin:0;font-size:13px;color:#58627e">如果你沒有在 yayalin.com 索取驗證碼，請直接忽略這封信。</p>',
        ''
      )
    );
  end if;
  return new;
end;
$$;

-- ---------- 5) 送出回饋：驗證碼用途是 app（舊版 App 用的 contact 也照收）----------
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
  if not (consume_email_code(v_email, 'app', p_code) or consume_email_code(v_email, 'contact', p_code)) then
    return null;
  end if;
  if (select count(*) from app_feedback where email = v_email and created_at > now() - interval '1 day') >= 10 then
    raise exception 'too_many_requests';
  end if;
  v_priority := case
    when v_kind = 'idea' then 'low'
    when v_kind = 'bug' and v_message ~* '(閃退|當機|crash|打不開|無法|不能|沒辦法|沒反應|扣款|付款|登入)' then 'high'
    else 'normal'
  end;
  insert into app_feedback (kind, message, email, app_version, os, priority)
  values (v_kind, v_message, v_email, left(p_app_version, 40), left(p_os, 80), v_priority)
  returning * into v_row;
  insert into app_feedback_messages (feedback_id, direction, body) values (v_row.id, 'inbound', v_message);
  return jsonb_build_object('case_number', v_row.case_number, 'token', v_row.access_token);
end;
$$;
grant execute on function submit_app_feedback(text, text, text, text, text, text) to anon, authenticated;

-- ---------- 6) 回饋相關的信：App 外觀、app@ 名義 ----------
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
      v_files := v_files || '<p style="margin:8px 0"><a href="' || app_feedback_file_url(v_path) || '">查看照片</a></p>';
    end loop;
  end if;

  if new.direction = 'outbound' then
    -- 你回覆 → 使用者（回信會進 app@yayalin.com）
    perform send_resend_from(
      '交通即時查 TransitGo <app@yayalin.com>',
      v_ticket.email,
      'Re: 你的意見回饋（案件 ' || v_ticket.case_number || '）',
      app_email_shell('我們回覆了你的意見回饋',
        '<p style="margin:0 0 12px">' || app_feedback_esc(new.body) || '</p>' || v_files,
        '案件編號 ' || v_ticket.case_number || '。你也可以在 App「設定 › 支援與法律 › 我的回饋」繼續對話、傳照片。'),
      'app@yayalin.com'
    );
  elsif (select count(*) from app_feedback_messages where feedback_id = new.feedback_id) > 1 then
    -- 使用者追問 → 你。回信地址是使用者，要以 app@ 名義回：到後台，或在 Gmail 把寄件人切成 app@yayalin.com
    perform send_resend_from(
      '交通即時查 回饋通知 <app@yayalin.com>',
      'yayalin322@gmail.com',
      '[App 回饋・' || app_feedback_priority_label(v_ticket.priority) || '] 新訊息 ' || v_ticket.case_number,
      app_email_shell('使用者回覆了',
        '<p style="margin:0 0 8px"><strong>' || app_feedback_esc(v_ticket.email) || '</strong> 在案件 ' || v_ticket.case_number || ' 說：</p>'
        || '<div class="ap-quote" style="background-color:#f0f4fb;border:1px solid #dfe4ee;border-radius:10px;padding:12px 14px;margin:0 0 12px">' || app_feedback_esc(new.body) || '</div>' || v_files
        || '<p style="margin:12px 0 0"><a href="https://yayalin.com/write/feedback">到後台回覆</a></p>',
        '直接回這封信會寄給使用者；請把寄件人切成 app@yayalin.com。'),
      v_ticket.email
    );
  end if;
  return new;
end;
$$;

create or replace function notify_new_app_feedback()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  perform send_resend_from(
    '交通即時查 回饋通知 <app@yayalin.com>',
    'yayalin322@gmail.com',
    '[App 回饋・' || app_feedback_priority_label(new.priority) || '] ' || new.case_number || '：' || left(regexp_replace(new.message, '\s+', ' ', 'g'), 40),
    app_email_shell('有新的 App 意見回饋',
      '<p style="margin:0 0 4px"><strong>案件：</strong>' || new.case_number || '（' || case new.kind when 'bug' then '問題回報' when 'idea' then '功能建議' else '其他' end || '）</p>'
      || '<p style="margin:0 0 4px"><strong>輕重緩急：</strong>' || app_feedback_priority_label(new.priority) || '（系統依內容建議，可在後台調整）</p>'
      || '<p style="margin:0 0 4px"><strong>Email（已驗證）：</strong>' || app_feedback_esc(new.email) || '</p>'
      || '<p style="margin:0 0 12px"><strong>App：</strong>' || app_feedback_esc(coalesce(new.app_version, '?')) || '・' || app_feedback_esc(coalesce(new.os, '?')) || '</p>'
      || '<div class="ap-quote" style="background-color:#f0f4fb;border:1px solid #dfe4ee;border-radius:10px;padding:12px 14px;margin:0 0 12px">' || app_feedback_esc(new.message) || '</div>'
      || '<p style="margin:12px 0 0"><a href="https://yayalin.com/write/feedback">到後台回覆</a></p>',
      '直接回這封信會寄給使用者；請把寄件人切成 app@yayalin.com。'),
    new.email
  );
  return new;
end;
$$;

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
  perform send_resend_from(
    '交通即時查 回饋通知 <app@yayalin.com>',
    'yayalin322@gmail.com',
    '[App 回饋・已結束] ' || v_row.case_number,
    app_email_shell('使用者結束了對話',
      '<p style="margin:0">案件 <strong>' || v_row.case_number || '</strong>（' || app_feedback_esc(v_row.email) || '）已由使用者結束。</p>',
      '在 /write/feedback 可以重新開啟。')
  );
  return true;
end;
$$;

commit;
