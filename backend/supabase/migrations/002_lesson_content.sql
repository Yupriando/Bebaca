-- =====================================================
-- Migrasi 002: isi lesson (jenis + huruf) dan bintang
-- Jalankan HANYA jika database dibuat dengan schema.sql / seed.sql versi lama.
-- Aman dijalankan ulang.
-- =====================================================

alter table public.lessons
  add column if not exists kind text not null default 'letter'
    check (kind in ('letter', 'review', 'quiz', 'challenge')),
  add column if not exists letters text[] not null default '{}';

alter table public.lesson_progress
  add column if not exists stars int not null default 1
    check (stars between 0 and 3);

-- Lesson per huruf: "Huruf A" -> kind letter, letters {A}
update public.lessons
set kind = 'letter', letters = array[upper(right(title, 1))]
where title like 'Huruf _';

-- Unit 1: vokal
update public.lessons set kind = 'review',    letters = array['A','I','U','E','O'] where title = 'Latihan Vokal';
update public.lessons set kind = 'quiz',      letters = array['A','I','U','E','O'] where title = 'Kuis Vokal';
update public.lessons set kind = 'challenge', letters = array['A','I','U','E','O'] where title = 'Tantangan Vokal';

-- Unit 2: konsonan
update public.lessons set kind = 'review',    letters = array['B','C','D','F','G'] where title = 'Latihan Konsonan';
update public.lessons set kind = 'quiz',      letters = array['B','C','D','F','G'] where title = 'Kuis Konsonan';
update public.lessons set kind = 'challenge', letters = array['B','C','D','F','G'] where title = 'Tantangan Konsonan';
