-- PANEL HIDUP OURIN - Schema Supabase (project bot-Ourin)
-- Jalankan: SQL Editor -> paste semua -> Run
-- Versi anti-error: tanpa dollar-quote, tanpa spasi di nama policy

create table if not exists public.bot_status (
  id int primary key default 1 check (id = 1),
  status text not null default 'mati' check (status in ('hidup','mati')),
  last_backup timestamptz,
  checked_at timestamptz not null default now(),
  detail jsonb not null default '{}'::jsonb
);

create table if not exists public.bot_history (
  id bigint generated always as identity primary key,
  status text not null check (status in ('hidup','mati')),
  last_backup timestamptz,
  checked_at timestamptz not null default now()
);

create table if not exists public.bot_stats (
  key text primary key,
  value jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

insert into public.bot_status (id, status) values (1, 'mati')
on conflict (id) do nothing;

alter table public.bot_status enable row level security;
alter table public.bot_history enable row level security;
alter table public.bot_stats enable row level security;

drop policy if exists panel_baca_status on public.bot_status;
drop policy if exists panel_baca_history on public.bot_history;
drop policy if exists panel_baca_stats on public.bot_stats;

create policy panel_baca_status on public.bot_status for select using (true);
create policy panel_baca_history on public.bot_history for select using (true);
create policy panel_baca_stats on public.bot_stats for select using (true);

-- Realtime (panel update tanpa reload).
-- Catatan: kalau muncul error "already member of publication",
-- abaikan saja -> artinya realtime memang sudah aktif.
alter publication supabase_realtime add table public.bot_status;
alter publication supabase_realtime add table public.bot_history;

-- Cek hasil: harus muncul 3 tabel
select table_name from information_schema.tables
where table_schema = 'public' and table_name in
('bot_status','bot_history','bot_stats')
order by table_name;
