-- App 信件外觀再美化一次：現在有正式的 logo 圖檔了（上一版只有暫時的「TG」色塊字標），
-- 換成真的 logo，另外加一條呼應 logo 漸層色（藍到綠）的頂部色條，卡片陰影、圓角也再調過。
-- 沿用 update_app_mail_style.sql 建立的 app_email_button；可重複執行。

begin;

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
.ap-bg{background-color:#0b1626 !important}
.ap-card{background-color:#101d33 !important;border-color:#24344c !important}
.ap-head{background-color:#0d1a30 !important}
.ap-body,.ap-body *{color:#eef3fa !important}
.ap-muted,.ap-muted *{color:#9fb0c6 !important}
.ap-quote{background-color:#182946 !important;border-color:#2c4066 !important}
.ap-code{background-color:#182946 !important;color:#8fc6ff !important;border-color:#2c4066 !important}
.ap-foot{border-color:#24344c !important}
.ap-btn{background-color:#4da3ff !important;color:#ffffff !important}
a{color:#8fc6ff !important}
}
</style></head>
<body class="ap-bg" style="margin:0;padding:0;background-color:#fbfdff">
<div class="ap-bg" style="background-color:#fbfdff;padding:32px 12px;font-family:-apple-system,'PingFang TC','Noto Sans TC','Microsoft JhengHei',sans-serif">
<div class="ap-card" style="max-width:560px;margin:0 auto;background-color:#ffffff;border:1px solid #e2e8f1;border-radius:20px;overflow:hidden;box-shadow:0 20px 44px -28px rgba(14,32,56,0.35)">
<div style="height:6px;background:linear-gradient(90deg,#0a6cf0,#0fb88a)"></div>
<div class="ap-head" style="background-color:#0e2038;padding:22px 26px">
<table role="presentation" cellpadding="0" cellspacing="0"><tr>
<td style="width:30px"><img src="https://yayalin.com/app-assets/logo-icon.png" width="30" height="30" alt="" style="display:block;border:0"></td>
<td style="padding-left:11px;color:#ffffff;font-size:16px;font-weight:700;letter-spacing:.2px;vertical-align:middle">交通即時查 TransitGo</td>
</tr></table>
</div>
<div class="ap-body" style="padding:30px 26px 8px;color:#0e2038;font-size:15px;line-height:1.8">
<h1 style="margin:0 0 16px;font-size:21px;line-height:1.4;color:#0e2038;font-weight:800;letter-spacing:-.01em">{{title}}</h1>
{{body}}
</div>
<div class="ap-foot ap-muted" style="margin:22px 26px 0;padding:16px 0 24px;border-top:1px solid #e2e8f1;color:#57667e;font-size:12px;line-height:1.7">{{footer}}這封信由「交通即時查 TransitGo」寄出，直接回信即可聯絡我們。</div>
</div></div></body></html>$t$, '{{title}}', p_title), '{{body}}', p_body), '{{footer}}', case when coalesce(p_footer, '') = '' then '' else p_footer || '<br>' end)
$shell$;

create or replace function app_email_button(p_label text, p_href text)
returns text
language sql
immutable
as $$
  select '<table role="presentation" cellpadding="0" cellspacing="0" style="margin:16px 0 4px"><tr><td style="background-color:#0a6cf0;border-radius:999px">'
    || '<a href="' || p_href || '" class="ap-btn" style="display:inline-block;padding:11px 22px;color:#ffffff;font-size:14px;font-weight:700;text-decoration:none;border-radius:999px">'
    || p_label || '</a></td></tr></table>'
$$;

commit;
