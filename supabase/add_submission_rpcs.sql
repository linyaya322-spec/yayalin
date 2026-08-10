-- 讓學生意見箱、聯絡表單改用 RPC 送出，這樣才能把資料庫自動產生的
-- 案件編號回傳給前端（一般訪客沒有讀取權限，直接 insert 拿不到）。
-- 貼到 Supabase SQL Editor 執行一次。不含金鑰，安全可以進 git。

create or replace function submit_suggestion(
  p_message text,
  p_school text,
  p_grade text,
  p_contact_name text,
  p_contact_email text,
  p_attachment_paths text[]
)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  v_case_number text;
begin
  insert into student_suggestions (message, school, grade, contact_name, contact_email, attachment_paths)
  values (p_message, p_school, p_grade, p_contact_name, p_contact_email, p_attachment_paths)
  returning case_number into v_case_number;
  return v_case_number;
end;
$$;

grant execute on function submit_suggestion(text, text, text, text, text, text[]) to anon, authenticated;

create or replace function submit_contact(
  p_name text,
  p_email text,
  p_message text
)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  v_case_number text;
begin
  insert into contact_submissions (name, email, message)
  values (p_name, p_email, p_message)
  returning case_number into v_case_number;
  return v_case_number;
end;
$$;

grant execute on function submit_contact(text, text, text) to anon, authenticated;
