-- =====================================================
-- Migrasi 003: Bebaca Premium (langganan bulanan / tahunan)
-- Jalankan di Supabase SQL Editor untuk database yang sudah ada.
-- Aman dijalankan ulang.
-- =====================================================

-- Tandai konten premium. Ubah kapan saja dari Table Editor tanpa update aplikasi.
alter table public.sections add column if not exists is_premium boolean not null default false;
alter table public.stories  add column if not exists is_premium boolean not null default false;

-- Bawaan: Unit 1 gratis, Unit 2 dst premium.
update public.sections set is_premium = (unit >= 2);

-- Bawaan: 2 dongeng pertama di tiap kategori gratis, sisanya premium.
update public.stories s
set is_premium = r.rn > 2
from (
  select id, row_number() over (partition by category_id order by sort_order, title) as rn
  from public.stories
) r
where r.id = s.id;

-- Langganan. 1 baris per pembelian di toko (Google Play purchase token / Apple original transaction).
-- platform 'manual' = hadiah/promo/uji coba yang diisi admin langsung di database.
create table if not exists public.subscriptions (
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
create index if not exists subscriptions_user_idx on public.subscriptions(user_id, expires_at desc);

alter table public.subscriptions enable row level security;

-- Contoh memberi premium manual (mis. untuk uji coba tampilan tanpa toko):
-- insert into public.subscriptions (user_id, platform, product_id, store_id, expires_at, auto_renew)
-- values ('<UUID user>', 'manual', 'bebaca_premium_monthly', 'manual-<UUID user>', now() + interval '30 days', false);
