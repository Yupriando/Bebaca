-- =====================================================
-- Bebaca - Skema database (jalankan di Supabase SQL Editor)
-- =====================================================

-- Profil pengguna (1 baris per akun di auth.users)
create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  nama text not null,
  tanggal_lahir date,
  umur int check (umur between 1 and 120),
  tingkat_kesulitan text not null default 'Mudah'
    check (tingkat_kesulitan in ('Mudah', 'Sedang', 'Sulit')),
  hari_berturut int not null default 0,
  last_study_date date,
  materi_terakhir text,
  avatar_url text,
  created_at timestamptz not null default now()
);

-- Pengaturan (Settings)
create table public.user_settings (
  user_id uuid primary key references auth.users(id) on delete cascade,
  sound_effect boolean not null default true,
  animation boolean not null default true,
  listening_exercise boolean not null default true,
  parental_control boolean not null default false,
  time_limit_minutes int not null default 60 check (time_limit_minutes >= 0), -- 0 = tanpa batas
  curfew text not null default '20:00'
    check (curfew ~ '^([01][0-9]|2[0-3]):[0-5][0-9]$'),
  parent_pin_hash text, -- PIN orang tua (hash scrypt), null = belum dibuat
  updated_at timestamptz not null default now()
);

-- Waktu belajar per hari (untuk "Timespent")
create table public.daily_usage (
  user_id uuid not null references auth.users(id) on delete cascade,
  usage_date date not null,
  minutes int not null default 0,
  primary key (user_id, usage_date)
);

-- Belajar: unit/section -> lesson
create table public.sections (
  id uuid primary key default gen_random_uuid(),
  unit int not null,
  section int not null,
  title text not null,
  guide text,
  is_premium boolean not null default false, -- true = khusus Bebaca Premium
  unique (unit, section)
);

create table public.lessons (
  id uuid primary key default gen_random_uuid(),
  section_id uuid not null references public.sections(id) on delete cascade,
  order_index int not null,
  title text not null,
  -- letter = belajar 1 huruf | review = latihan | quiz = kuis | challenge = tantangan baca
  kind text not null default 'letter'
    check (kind in ('letter', 'review', 'quiz', 'challenge')),
  letters text[] not null default '{}',
  unique (section_id, order_index)
);
create index lessons_section_idx on public.lessons(section_id);

create table public.lesson_progress (
  user_id uuid not null references auth.users(id) on delete cascade,
  lesson_id uuid not null references public.lessons(id) on delete cascade,
  completed_at timestamptz not null default now(),
  stars int not null default 1 check (stars between 0 and 3),
  primary key (user_id, lesson_id)
);

-- Dongeng
create table public.story_categories (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  sort_order int not null default 0
);

create table public.stories (
  id uuid primary key default gen_random_uuid(),
  category_id uuid not null references public.story_categories(id) on delete cascade,
  title text not null,
  cover_url text,
  video_url text,
  content text,
  sort_order int not null default 0,
  is_premium boolean not null default false, -- true = khusus Bebaca Premium
  moral text,                                -- "Pesan dari cerita ini"
  quiz jsonb not null default '[]',          -- [{question, options[], answer(index)}]
  page_images text[] not null default '{}'   -- gambar per halaman Baca Bersama (URL), opsional
);
create index stories_category_idx on public.stories(category_id);

-- Progres membaca dongeng (Baca Bersama)
create table public.story_progress (
  user_id uuid not null references auth.users(id) on delete cascade,
  story_id uuid not null references public.stories(id) on delete cascade,
  last_page int not null default 0,
  completed_at timestamptz,
  stars int not null default 0 check (stars between 0 and 3),
  updated_at timestamptz not null default now(),
  primary key (user_id, story_id)
);

-- Bebaca Premium: 1 baris per pembelian di toko (Google Play purchase token /
-- Apple original transaction). platform 'manual' = hadiah/promo yang diisi admin.
create table public.subscriptions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  platform text not null check (platform in ('android', 'ios', 'manual')),
  product_id text not null,
  store_id text not null,            -- android: purchase token | ios: originalTransactionId
  expires_at timestamptz not null,
  auto_renew boolean not null default true,
  status text not null default 'active',
  checked_at timestamptz not null default now(),  -- terakhir dicek ke toko
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (platform, store_id)
);
create index subscriptions_user_idx on public.subscriptions(user_id, expires_at desc);

-- Tambah waktu belajar secara atomik
create or replace function public.add_usage(p_user uuid, p_date date, p_minutes int)
returns void
language sql
as $$
  insert into public.daily_usage (user_id, usage_date, minutes)
  values (p_user, p_date, p_minutes)
  on conflict (user_id, usage_date)
  do update set minutes = public.daily_usage.minutes + excluded.minutes;
$$;

-- Hanya backend (service_role) yang boleh memanggil fungsi ini
revoke all on function public.add_usage(uuid, date, int) from public, anon, authenticated;
grant execute on function public.add_usage(uuid, date, int) to service_role;

-- Keamanan: aktifkan RLS TANPA policy => akses langsung lewat anon key ditolak.
-- Backend memakai service_role key yang melewati RLS.
alter table public.profiles enable row level security;
alter table public.user_settings enable row level security;
alter table public.daily_usage enable row level security;
alter table public.sections enable row level security;
alter table public.lessons enable row level security;
alter table public.lesson_progress enable row level security;
alter table public.story_categories enable row level security;
alter table public.stories enable row level security;
alter table public.subscriptions enable row level security;
alter table public.story_progress enable row level security;
