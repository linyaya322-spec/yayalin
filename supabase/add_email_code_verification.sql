-- 送出前必須先驗證 Email（6 位數驗證碼）：學生意見箱、聯絡表單共用。
-- 訪客先按「寄驗證碼」，輸入收到的碼後才能送出；驗證在資料庫端強制檢查，
-- 不能繞過前端。不含金鑰，可進 git。寄信的觸發器在另一段（含金鑰）SQL。

create table if not exists email_verifications (
  id uuid primary key default gen_random_uuid(),
  email text not null,
  purpose text not null check (purpose in ('suggestion', 'contact')),
  code text not null,
  attempts int not null default 0,
  used boolean not null default false,
  created_at timestamptz not null default now(),
  expires_at timestamptz not null default now() + interval '10 minutes'
);
alter table email_verifications enable row level security;
-- 不建立任何 policy：只有 security definer 的函式能存取。

alter table contact_submissions add column if not exists email_verified_at timestamptz;

-- 索取驗證碼（同一信箱一小時最多 5 次）
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
  if p_purpose not in ('suggestion', 'contact') then
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

-- 檢查並用掉驗證碼（內部使用）；錯誤會累計次數，5 次錯就作廢
create or replace function consume_email_code(p_email text, p_purpose text, p_code text)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  v_row email_verifications%rowtype;
begin
  select * into v_row from email_verifications
   where email = lower(trim(p_email)) and purpose = p_purpose
     and used = false and expires_at > now()
   order by created_at desc limit 1;
  if not found or v_row.attempts >= 5 then
    return false;
  end if;
  if v_row.code <> trim(coalesce(p_code, '')) then
    update email_verifications set attempts = attempts + 1 where id = v_row.id;
    return false;
  end if;
  update email_verifications set used = true where id = v_row.id;
  return true;
end;
$$;
revoke execute on function consume_email_code(text, text, text) from public, anon, authenticated;

-- 舊版沒有驗證碼的函式必須移除，否則可以繞過驗證
drop function if exists submit_suggestion(text, text, text, text, text, text[]);
drop function if exists submit_contact(text, text, text);
drop function if exists verify_suggestion_email(uuid);

-- 有填 Email 時，必須帶正確驗證碼；驗證失敗回傳 null
create or replace function submit_suggestion(
  p_message text,
  p_school text,
  p_grade text,
  p_contact_name text,
  p_contact_email text,
  p_attachment_paths text[],
  p_code text default null
)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  v_case_number text;
  v_verified timestamptz;
begin
  if p_contact_email is not null then
    if not consume_email_code(p_contact_email, 'suggestion', p_code) then
      return null;
    end if;
    v_verified := now();
  end if;
  insert into student_suggestions (message, school, grade, contact_name, contact_email, attachment_paths, email_verified_at)
  values (p_message, p_school, p_grade, p_contact_name, lower(trim(p_contact_email)), p_attachment_paths, v_verified)
  returning case_number into v_case_number;
  return v_case_number;
end;
$$;
grant execute on function submit_suggestion(text, text, text, text, text, text[], text) to anon, authenticated;

create or replace function submit_contact(
  p_name text,
  p_email text,
  p_message text,
  p_code text default null
)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  v_case_number text;
begin
  if not consume_email_code(p_email, 'contact', p_code) then
    return null;
  end if;
  insert into contact_submissions (name, email, message, email_verified_at)
  values (p_name, lower(trim(p_email)), p_message, now())
  returning case_number into v_case_number;
  return v_case_number;
end;
$$;
grant execute on function submit_contact(text, text, text, text) to anon, authenticated;

-- 清掉過期的驗證碼（順手，每次索取時不處理，交給排程或手動）
delete from email_verifications where created_at < now() - interval '1 day';
