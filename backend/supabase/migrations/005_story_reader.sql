-- =====================================================
-- Migrasi 005: Baca Bersama (buku bergambar), pesan moral, kuis, progres membaca
-- Jalankan di Supabase SQL Editor. Aman dijalankan ulang.
-- =====================================================

alter table public.stories
  add column if not exists moral text,                         -- "Pesan dari cerita ini"
  add column if not exists quiz jsonb not null default '[]',   -- [{question, options[], answer(index)}]
  add column if not exists page_images text[] not null default '{}'; -- gambar per halaman (URL), opsional

-- Progres membaca per anak
create table if not exists public.story_progress (
  user_id uuid not null references auth.users(id) on delete cascade,
  story_id uuid not null references public.stories(id) on delete cascade,
  last_page int not null default 0,        -- halaman terakhir dibuka (mulai 0)
  completed_at timestamptz,                -- null = belum selesai
  stars int not null default 0 check (stars between 0 and 3),
  updated_at timestamptz not null default now(),
  primary key (user_id, story_id)
);
alter table public.story_progress enable row level security;

-- Contoh isi: Malin Kundang
update public.stories
set moral = 'Hormati dan sayangilah ibumu, dan jangan pernah melupakan asal-usulmu.',
    quiz = $q$[
      {"question": "Mengapa Malin Kundang pergi merantau?",
       "options": ["Ingin mengubah nasib keluarganya", "Ingin bermain di pantai", "Disuruh raja"],
       "answer": 0},
      {"question": "Apa yang Malin katakan saat bertemu ibunya?",
       "options": ["Ibu, aku rindu!", "Aku tidak mengenal wanita tua ini!", "Ayo ikut ke kapalku!"],
       "answer": 1},
      {"question": "Malin Kundang berubah menjadi apa?",
       "options": ["Ikan", "Pohon", "Batu"],
       "answer": 2}
    ]$q$::jsonb
where title = 'Malin Kundang' and moral is null;
