-- 讓 transitgo-server（後端，不是這個網站）可以用同一套 Email 驗證碼機制驗證地標／留言。
-- request_email_code 本來就是公開 RPC（沒變）；這裡只新增「驗證碼對不對」這個查詢動作本身也開放，
-- 因為 consume_email_code 是內部函式（只有 submit_contact / submit_app_feedback 這種既有流程在用），
-- 外部服務沒有直接管道可以呼叫。金鑰不會外流——transitgo-server 只有這個網站本來就公開的
-- publishable key，換不到任何機密資料，這支函式也只做「這組 email+purpose+code 對不對」這一件事。
-- 可重複執行。

begin;

create or replace function verify_email_code(p_email text, p_purpose text, p_code text)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
begin
  return consume_email_code(lower(trim(p_email)), p_purpose, p_code);
end;
$$;
grant execute on function verify_email_code(text, text, text) to anon, authenticated;

commit;
