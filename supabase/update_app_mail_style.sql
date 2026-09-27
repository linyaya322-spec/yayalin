-- 美化 App 的信件外觀：拿掉 emoji（改成純文字/色塊的小標誌），連結改成按鈕樣式。
-- 沿用 add_app_mail_branding.sql 建立的 app_email_shell / send_resend_from，只是重新定義外觀和幾個連結。
-- 可重複執行；整段在交易裡。前提：已執行 add_app_feedback.sql 與 add_app_mail_branding.sql。

begin;

-- ---------- 1) 信件外觀：拿掉 🚌 emoji，改成色塊字標；新增按鈕樣式 ----------
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
.ap-head{background-color:#121930 !important}
.ap-body,.ap-body *{color:#edf0f7 !important}
.ap-muted,.ap-muted *{color:#9aa5be !important}
.ap-quote{background-color:#1e2740 !important;border-color:#3a4a73 !important}
.ap-code{background-color:#1e2740 !important;color:#8fb8ff !important;border-color:#3a4a73 !important}
.ap-foot{border-color:#27314a !important}
.ap-btn{background-color:#3d7bff !important;color:#ffffff !important}
a{color:#8fb8ff !important}
}
</style></head>
<body class="ap-bg" style="margin:0;padding:0;background-color:#f5f7fb">
<div class="ap-bg" style="background-color:#f5f7fb;padding:24px 12px;font-family:-apple-system,'PingFang TC','Noto Sans TC','Microsoft JhengHei',sans-serif">
<div class="ap-card" style="max-width:560px;margin:0 auto;background-color:#ffffff;border:1px solid #dfe4ee;border-radius:16px;overflow:hidden">
<div class="ap-head" style="background-color:#0a1a3d;padding:20px 24px;display:flex">
<table role="presentation" cellpadding="0" cellspacing="0"><tr>
<td style="background-color:#3d7bff;color:#ffffff;font-size:13px;font-weight:800;letter-spacing:.5px;border-radius:7px;width:30px;height:30px;text-align:center;vertical-align:middle">TG</td>
<td style="padding-left:10px;color:#ffffff;font-size:16px;font-weight:700;letter-spacing:.2px;vertical-align:middle">交通即時查 TransitGo</td>
</tr></table>
</div>
<div class="ap-body" style="padding:28px 24px 8px;color:#1a2233;font-size:15px;line-height:1.8">
<h1 style="margin:0 0 16px;font-size:20px;line-height:1.4;color:#1a2233">{{title}}</h1>
{{body}}
</div>
<div class="ap-foot ap-muted" style="margin:20px 24px 0;padding:14px 0 22px;border-top:1px solid #dfe4ee;color:#5b6579;font-size:12px;line-height:1.7">{{footer}}這封信由「交通即時查 TransitGo」寄出，直接回信即可聯絡我們。</div>
</div></div></body></html>$t$, '{{title}}', p_title), '{{body}}', p_body), '{{footer}}', case when coalesce(p_footer, '') = '' then '' else p_footer || '<br>' end)
$shell$;

-- 按鈕樣式的連結（取代信件裡裸露的 <a>連結）
create or replace function app_email_button(p_label text, p_href text)
returns text
language sql
immutable
as $$
  select '<table role="presentation" cellpadding="0" cellspacing="0" style="margin:14px 0 4px"><tr><td style="background-color:#0a6cf0;border-radius:9px">'
    || '<a href="' || p_href || '" class="ap-btn" style="display:inline-block;padding:10px 20px;color:#ffffff;font-size:14px;font-weight:700;text-decoration:none;border-radius:9px">'
    || p_label || '</a></td></tr></table>'
$$;

-- ---------- 2) 回饋相關的信：連結改成按鈕 ----------
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
  v_n int := 0;
begin
  select * into v_ticket from app_feedback where id = new.feedback_id;
  if new.attachment_paths is not null then
    foreach v_path in array new.attachment_paths loop
      v_n := v_n + 1;
      v_files := v_files || app_email_button('查看照片' || case when array_length(new.attachment_paths, 1) > 1 then ' ' || v_n else '' end, app_feedback_file_url(v_path));
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
        || app_email_button('到後台回覆', 'https://yayalin.com/write/feedback'),
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
      || app_email_button('到後台回覆', 'https://yayalin.com/write/feedback'),
      '直接回這封信會寄給使用者；請把寄件人切成 app@yayalin.com。'),
    new.email
  );
  return new;
end;
$$;

commit;
