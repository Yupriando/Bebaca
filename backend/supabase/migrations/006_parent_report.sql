-- =====================================================
-- Migrasi 006: Laporan Perkembangan & Pantau Langsung (QR) untuk orang tua
-- Jalankan di Supabase SQL Editor. Aman dijalankan ulang.
-- =====================================================

-- Kejadian belajar yang dikirim aplikasi anak (dipakai laporan & pantau langsung).
-- type: app_open | tab | lesson_start | answer | lesson_complete | lesson_exit
--       | story_open | story_page | story_complete | heartbeat
-- data: detail, mis. answer -> {letter, step, correct, picked}
create table if not exists public.learning_events (
  id bigint generated always as identity primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  type text not null,
  data jsonb not null default '{}',
  created_at timestamptz not null default now()
);
create index if not exists learning_events_user_time_idx
  on public.learning_events(user_id, created_at desc);
alter table public.learning_events enable row level security;

-- Tautan "Pantau Langsung": QR berisi token rahasia; yang disimpan hanya hash-nya.
create table if not exists public.parent_links (
  user_id uuid primary key references auth.users(id) on delete cascade,
  token_hash text not null unique,
  created_at timestamptz not null default now()
);
alter table public.parent_links enable row level security;
