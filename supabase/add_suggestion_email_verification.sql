-- 學生意見箱：Email 驗證
-- 送出後寄一封含驗證連結的信，點擊後才標記為「已驗證」。
alter table student_suggestions add column if not exists verify_token uuid not null default gen_random_uuid();
alter table student_suggestions add column if not exists email_verified_at timestamptz;

create or replace function verify_suggestion_email(p_token uuid)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  v_case text;
begin
  update student_suggestions
     set email_verified_at = coalesce(email_verified_at, now())
   where verify_token = p_token
  returning case_number into v_case;
  return v_case;
end;
$$;

grant execute on function verify_suggestion_email(uuid) to anon, authenticated;
