-- 全站 SEO/GEO 設定：貼到 Supabase SQL Editor 執行一次
-- path 使用網站路徑（例如 /、/about、/committee）；不含網域、query string 或 fragment。

create table if not exists public.page_seo (
  path text primary key check (path like '/%' and path !~ '[?#]'),
  title text,
  description text,
  keywords text[] not null default '{}'::text[],
  og_image text,
  geo_summary text,
  geo_faq jsonb not null default '[]'::jsonb check (jsonb_typeof(geo_faq) = 'array'),
  updated_at timestamptz not null default now()
);

alter table public.page_seo enable row level security;

grant select on public.page_seo to anon, authenticated;
grant insert, update, delete on public.page_seo to authenticated;

drop policy if exists "page_seo is publicly readable" on public.page_seo;
create policy "page_seo is publicly readable"
  on public.page_seo for select
  using (true);

drop policy if exists "only admin can manage page_seo" on public.page_seo;
create policy "only admin can manage page_seo"
  on public.page_seo for all to authenticated
  using (auth.jwt() ->> 'email' = 'yayalin322@gmail.com')
  with check (auth.jwt() ->> 'email' = 'yayalin322@gmail.com');
