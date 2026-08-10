-- 學生意見箱、聯絡訊息、收件匣，每一筆（收件匣是每個對話串）都加上帶日期的案件編號
-- 格式：YYYYMMDD-001。貼到 Supabase SQL Editor 執行一次。不含金鑰，安全可以進 git。

create table if not exists case_number_counters (
  day date primary key,
  seq integer not null default 0
);

create or replace function generate_case_number(p_day date default current_date)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  v_seq integer;
begin
  insert into case_number_counters (day, seq) values (p_day, 1)
  on conflict (day) do update set seq = case_number_counters.seq + 1
  returning seq into v_seq;
  return to_char(p_day, 'YYYYMMDD') || '-' || lpad(v_seq::text, 3, '0');
end;
$$;

alter table student_suggestions add column if not exists case_number text unique;
alter table contact_submissions add column if not exists case_number text unique;
alter table inbox_messages add column if not exists case_number text;

-- 補上既有資料的案件編號（按原本的建立時間排序，編號會照當時的日期）
do $$
declare
  r record;
begin
  for r in
    select id, created_at from student_suggestions where case_number is null order by created_at asc
  loop
    update student_suggestions set case_number = generate_case_number(r.created_at::date) where id = r.id;
  end loop;

  for r in
    select id, created_at from contact_submissions where case_number is null order by created_at asc
  loop
    update contact_submissions set case_number = generate_case_number(r.created_at::date) where id = r.id;
  end loop;
end $$;

do $$
declare
  grp record;
  first_created timestamptz;
  v_case text;
begin
  for grp in
    select distinct lower(contact_email) as email from inbox_messages where case_number is null
  loop
    select created_at into first_created
    from inbox_messages
    where lower(contact_email) = grp.email
    order by created_at asc
    limit 1;

    v_case := generate_case_number(first_created::date);

    update inbox_messages
    set case_number = v_case
    where lower(contact_email) = grp.email and case_number is null;
  end loop;
end $$;

-- 之後新資料自動產生案件編號
create or replace function assign_case_number_new_case()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.case_number is null then
    new.case_number := generate_case_number(coalesce(new.created_at::date, current_date));
  end if;
  return new;
end;
$$;

drop trigger if exists student_suggestions_case_number on student_suggestions;
create trigger student_suggestions_case_number
  before insert on student_suggestions
  for each row execute function assign_case_number_new_case();

drop trigger if exists contact_submissions_case_number on contact_submissions;
create trigger contact_submissions_case_number
  before insert on contact_submissions
  for each row execute function assign_case_number_new_case();

-- 收件匣是同一個對話串（同一個 email）共用一個案件編號，不是每筆訊息各給一個
create or replace function assign_inbox_case_number()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_existing text;
begin
  if new.case_number is null then
    select case_number into v_existing
    from inbox_messages
    where lower(contact_email) = lower(new.contact_email) and case_number is not null
    order by created_at asc
    limit 1;
    if v_existing is not null then
      new.case_number := v_existing;
    else
      new.case_number := generate_case_number(coalesce(new.created_at::date, current_date));
    end if;
  end if;
  return new;
end;
$$;

drop trigger if exists inbox_messages_case_number on inbox_messages;
create trigger inbox_messages_case_number
  before insert on inbox_messages
  for each row execute function assign_inbox_case_number();
