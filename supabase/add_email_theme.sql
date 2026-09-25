-- 寄給訪客的 Email 共用外框：白色筆記本紙張風格，支援淺色 / 深色模式
-- （用 prefers-color-scheme，Apple Mail、iOS、Outlook.com 等會依系統切換；
-- Gmail 會自己處理深色）。不含金鑰，可進 git。
-- p_title：標題列（螢光筆黃底）；p_body：內文 HTML；p_footer_note：頁尾小字（可空）。
create or replace function email_shell(p_title text, p_body text, p_footer_note text default '歡迎直接回信給我，我會收到。')
returns text
language sql
immutable
as $fn$
select
  '<!DOCTYPE html><html lang="zh-Hant"><head><meta charset="utf-8">'
  || '<meta name="viewport" content="width=device-width,initial-scale=1">'
  || '<meta name="color-scheme" content="light dark"><meta name="supported-color-schemes" content="light dark">'
  || '<style>'
  || ':root{color-scheme:light dark;supported-color-schemes:light dark}'
  || '@media (prefers-color-scheme: dark){'
  || '.em-bg{background-color:#0e1424 !important}'
  || '.em-card{background-color:#182038 !important;border-color:#7d8bb5 !important}'
  || '.em-head{background-color:#ffe94a !important;border-color:#7d8bb5 !important}'
  || '.em-body,.em-body *{color:#eef0f7 !important}'
  || '.em-quote{background-color:#222c4a !important;border-color:#4a5883 !important;color:#eef0f7 !important}'
  || '.em-code{background-color:#ffe94a !important;color:#1d2742 !important;border-color:#ffe94a !important}'
  || '.em-foot{border-color:#7d8bb5 !important}'
  || '.em-muted,.em-muted a{color:#9aa5c7 !important}'
  || '.em-link{color:#8fb0ff !important}'
  || '}'
  || '</style></head>'
  || '<body class="em-bg" style="margin:0;padding:0;background-color:#f1efe8">'
  || '<div class="em-bg" style="background-color:#f1efe8;padding:28px 12px;font-family:''Noto Sans TC'',''PingFang TC'',''Microsoft JhengHei'',sans-serif">'
  || '<table role="presentation" width="100%" cellpadding="0" cellspacing="0" class="em-card" style="max-width:560px;margin:0 auto;background-color:#ffffff;border:2px solid #1d2742;border-radius:6px">'
  || '<tr><td class="em-head" style="padding:18px 28px;background-color:#ffe94a;border-bottom:2px solid #1d2742;border-radius:4px 4px 0 0">'
  || '<h1 style="margin:0;font-size:20px;line-height:1.4;font-weight:700;color:#1d2742;font-family:''LXGW WenKai TC'',''Noto Sans TC'',''PingFang TC'',sans-serif">' || p_title || '</h1>'
  || '</td></tr>'
  || '<tr><td class="em-body" style="padding:28px;font-size:15px;line-height:1.9;color:#1d2742">' || p_body || '</td></tr>'
  || '<tr><td class="em-foot" style="padding:18px 28px;border-top:2px dashed #b9bfd3">'
  || '<p class="em-body" style="margin:0 0 6px;font-size:14px;font-weight:700;color:#1d2742">yaya 林 <span style="color:#d63a3a">&#9998;</span> 新竹縣兒少委員</p>'
  || case when p_footer_note is null or p_footer_note = '' then '' else '<p class="em-muted" style="margin:0 0 6px;font-size:12px;color:#58627e">' || p_footer_note || '</p>' end
  || '<p class="em-muted" style="margin:0;font-size:12px;color:#58627e"><a class="em-link" href="https://yayalin.com/privacy" style="color:#2f5bd0;text-decoration:underline" target="_blank">隱私權政策</a> &middot; <a class="em-link" href="https://yayalin.com/terms" style="color:#2f5bd0;text-decoration:underline" target="_blank">服務條款</a></p>'
  || '</td></tr></table></div></body></html>';
$fn$;
