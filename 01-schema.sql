-- ============================================================
-- PANEL HIDUP OURIN — Schema Supabase (project: bot-Ourin)
-- Cara pakai: Supabase Dashboard -> SQL Editor -> paste -> Run
-- ============================================================

-- 1) Status bot terkini (satu baris, id selalu 1)
create table if not exists public.bot_status (
  id           int primary key default 1 check (id = 1),
  status       text not null default 'mati' check (status in ('hidup','mati')),
  last_backup  timestamptz,
  checked_at   timestamptz not null default now(),
  detail       jsonb not null default '{}'::jsonb
);

-- 2) Riwayat perubahan status (hanya tercatat saat status BERUBAH)
create table if not exists public.bot_history (
  id          bigint generated always as identity primary key,
  status      text not null check (status in ('hidup','mati')),
  last_backup timestamptz,
  checked_at  timestamptz not null default now()
);

-- 3) Snapshot data bot (sewa.json, prefix.json, dll: key -> json)
create table if not exists public.bot_stats (
  key        text primary key,
  value      jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

-- Baris awal status
insert into public.bot_status (id, status)
values (1, 'mati')
on conflict (id) do nothing;

-- ============================================================
-- KEAMANAN: semua tabel boleh DIBACA publik (anon key panel),
-- tapi menulis hanya lewat service key (workflow GitHub).
-- ============================================================
alter table public.bot_status  enable row level security;
alter table public.bot_history enable row level security;
alter table public.bot_stats   enable row level security;

drop policy if exists "panel publik boleh baca status"  on public.bot_status;
drop policy if exists "panel publik boleh baca history" on public.bot_history;
drop policy if exists "panel publik boleh baca stats"   on public.bot_stats;

create policy "panel publik boleh baca status"  on public.bot_status  for select using (true);
create policy "panel publik boleh baca history" on public.bot_history for select using (true);
create policy "panel publik boleh baca stats"   on public.bot_stats   for select using (true);

-- (Tidak ada policy INSERT/UPDATE untuk anon => tulis ditolak.
--  Workflow GitHub pakai service_role key yang otomatis bypass RLS.)

-- 4) Realtime: aktifkan agar panel update TANPA reload
-- (di-wrap DO block supaya aman dijalankan ulang / idempotent)
do $$ begin
  alter publication supabase_realtime add table public.bot_status;
exception when duplicate_object then null; end $$;

do $$ begin
  alter publication supabase_realtime add table public.bot_history;
exception when duplicate_object then null; end $$;

-- 5) Cek hasil (harus muncul 3 tabel + 1 baris status)
select table_name from information_schema.tables
where table_schema = 'public' and table_name like 'bot_%'
order by table_name;
