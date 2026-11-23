-- =====================================================
-- Migration 007: Belajar Bersama (suku kata, kata, kalimat) + kolom dongeng baru
-- Jalankan di Supabase SQL Editor SEBELUM 008. Aman dijalankan ulang.
--
-- 1. Jenis lesson baru: syllable (suku kata), word (kata), sentence (kalimat)
-- 2. Kolom dongeng baru: prompts (pertanyaan ngobrol) & vocab (kata baru)
-- 3. Materi baru: Unit 3 sampai 9 (huruf H-Z, suku kata, kata, dan kalimat)
--    Aplikasi versi lama (sebelum 1.2) otomatis tidak menerima lesson jenis baru.
-- =====================================================

alter table public.lessons drop constraint if exists lessons_kind_check;
alter table public.lessons add constraint lessons_kind_check
  check (kind in ('letter', 'review', 'quiz', 'challenge', 'syllable', 'word', 'sentence'));

alter table public.stories add column if not exists prompts jsonb not null default '[]';
alter table public.stories add column if not exists vocab jsonb not null default '[]';
comment on column public.stories.prompts is '[{page, text}] pertanyaan "Ayo ngobrol" untuk orang tua (page mulai 0)';
comment on column public.stories.vocab is '[{word, meaning}] kata baru yang bisa diketuk di Baca Bersama';


-- ---------------------------------------------------- Unit 3: Suku Kata Pertama
insert into public.sections (unit, section, title, guide, is_premium)
values (3, 1, $t$Suku Kata Pertama$t$, $g$Gabungkan huruf konsonan dengan huruf vokal: b + a = ba. Ucapkan pelan lalu cepat bersama si kecil, "b... a... ba!", dan tepuk tangan sekali untuk setiap suku kata. Setelah itu susun suku kata menjadi kata pertama, seperti i-bu dan da-du.$g$, true)
on conflict (unit, section) do update
  set title = excluded.title, guide = excluded.guide, is_premium = excluded.is_premium;
insert into public.lessons (section_id, order_index, title, kind, letters)
select s.id, v.order_index, v.title, v.kind, v.letters
from public.sections s, (values
  (1, $t$Suku Kata B$t$, 'syllable', array['B']::text[]),
  (2, $t$Suku Kata C$t$, 'syllable', array['C']::text[]),
  (3, $t$Suku Kata D$t$, 'syllable', array['D']::text[]),
  (4, $t$Suku Kata G$t$, 'syllable', array['G']::text[]),
  (5, $t$Latihan Suku Kata$t$, 'syllable', array['B', 'C', 'D', 'G']::text[]),
  (6, $t$Kata Pertama$t$, 'word', array['i-bu', 'da-du', 'gi-gi']::text[]),
  (7, $t$Kata Pertama 2$t$, 'word', array['ba-ca', 'du-a', 'cu-ci']::text[])
) as v(order_index, title, kind, letters)
where s.unit = 3 and s.section = 1
on conflict (section_id, order_index) do update
  set title = excluded.title, kind = excluded.kind, letters = excluded.letters;

-- ---------------------------------------------------- Unit 4: Huruf H sampai M
insert into public.sections (unit, section, title, guide, is_premium)
values (4, 1, $t$Huruf H sampai M$t$, $g$Kenali huruf H, J, K, L, dan M beserta bunyinya. Ajak si kecil menyebut benda di rumah yang diawali huruf-huruf ini, misalnya kursi, lampu, dan meja.$g$, true)
on conflict (unit, section) do update
  set title = excluded.title, guide = excluded.guide, is_premium = excluded.is_premium;
insert into public.lessons (section_id, order_index, title, kind, letters)
select s.id, v.order_index, v.title, v.kind, v.letters
from public.sections s, (values
  (1, $t$Huruf H$t$, 'letter', array['H']::text[]),
  (2, $t$Huruf J$t$, 'letter', array['J']::text[]),
  (3, $t$Huruf K$t$, 'letter', array['K']::text[]),
  (4, $t$Huruf L$t$, 'letter', array['L']::text[]),
  (5, $t$Huruf M$t$, 'letter', array['M']::text[]),
  (6, $t$Latihan Huruf H-M$t$, 'review', array['H', 'J', 'K', 'L', 'M']::text[]),
  (7, $t$Kuis Huruf H-M$t$, 'quiz', array['H', 'J', 'K', 'L', 'M']::text[]),
  (8, $t$Tantangan Huruf H-M$t$, 'challenge', array['H', 'J', 'K', 'L', 'M']::text[])
) as v(order_index, title, kind, letters)
where s.unit = 4 and s.section = 1
on conflict (section_id, order_index) do update
  set title = excluded.title, kind = excluded.kind, letters = excluded.letters;

-- ---------------------------------------------------- Unit 5: Suku Kata H sampai M
insert into public.sections (unit, section, title, guide, is_premium)
values (5, 1, $t$Suku Kata H sampai M$t$, $g$Suku kata baru dari huruf H, J, K, L, dan M. Sekarang makin banyak kata yang bisa dibaca: bola, buku, kuda, kaki. Tepuk tangan untuk setiap suku kata: bo-la, dua tepukan.$g$, true)
on conflict (unit, section) do update
  set title = excluded.title, guide = excluded.guide, is_premium = excluded.is_premium;
insert into public.lessons (section_id, order_index, title, kind, letters)
select s.id, v.order_index, v.title, v.kind, v.letters
from public.sections s, (values
  (1, $t$Suku Kata H$t$, 'syllable', array['H']::text[]),
  (2, $t$Suku Kata J$t$, 'syllable', array['J']::text[]),
  (3, $t$Suku Kata K$t$, 'syllable', array['K']::text[]),
  (4, $t$Suku Kata L$t$, 'syllable', array['L']::text[]),
  (5, $t$Suku Kata M$t$, 'syllable', array['M']::text[]),
  (6, $t$Latihan Suku Kata H-M$t$, 'syllable', array['H', 'J', 'K', 'L', 'M']::text[]),
  (7, $t$Ayo Baca Kata$t$, 'word', array['bo-la', 'bu-ku', 'ku-da']::text[]),
  (8, $t$Ayo Baca Kata 2$t$, 'word', array['ka-ki', 'ma-ta', 'ba-ju']::text[]),
  (9, $t$Ayo Baca Kata 3$t$, 'word', array['ma-du', 'li-ma', 'ku-e']::text[])
) as v(order_index, title, kind, letters)
where s.unit = 5 and s.section = 1
on conflict (section_id, order_index) do update
  set title = excluded.title, kind = excluded.kind, letters = excluded.letters;

-- ---------------------------------------------------- Unit 6: Huruf N sampai T
insert into public.sections (unit, section, title, guide, is_premium)
values (6, 1, $t$Huruf N sampai T$t$, $g$Kenali huruf N, P, R, S, dan T. Bunyi R kadang masih sulit untuk balita. Tidak apa-apa, pujilah usahanya dan contohkan bunyinya dengan pelan.$g$, true)
on conflict (unit, section) do update
  set title = excluded.title, guide = excluded.guide, is_premium = excluded.is_premium;
insert into public.lessons (section_id, order_index, title, kind, letters)
select s.id, v.order_index, v.title, v.kind, v.letters
from public.sections s, (values
  (1, $t$Huruf N$t$, 'letter', array['N']::text[]),
  (2, $t$Huruf P$t$, 'letter', array['P']::text[]),
  (3, $t$Huruf R$t$, 'letter', array['R']::text[]),
  (4, $t$Huruf S$t$, 'letter', array['S']::text[]),
  (5, $t$Huruf T$t$, 'letter', array['T']::text[]),
  (6, $t$Latihan Huruf N-T$t$, 'review', array['N', 'P', 'R', 'S', 'T']::text[]),
  (7, $t$Kuis Huruf N-T$t$, 'quiz', array['N', 'P', 'R', 'S', 'T']::text[]),
  (8, $t$Tantangan Huruf N-T$t$, 'challenge', array['N', 'P', 'R', 'S', 'T']::text[])
) as v(order_index, title, kind, letters)
where s.unit = 6 and s.section = 1
on conflict (section_id, order_index) do update
  set title = excluded.title, kind = excluded.kind, letters = excluded.letters;

-- ---------------------------------------------------- Unit 7: Suku Kata N sampai T
insert into public.sections (unit, section, title, guide, is_premium)
values (7, 1, $t$Suku Kata N sampai T$t$, $g$Suku kata dari huruf N, P, R, S, dan T. Kata-kata di sini dekat dengan keseharian si kecil: nasi, roti, susu, sapi. Ajak ia menunjuk bendanya di rumah setelah membaca.$g$, true)
on conflict (unit, section) do update
  set title = excluded.title, guide = excluded.guide, is_premium = excluded.is_premium;
insert into public.lessons (section_id, order_index, title, kind, letters)
select s.id, v.order_index, v.title, v.kind, v.letters
from public.sections s, (values
  (1, $t$Suku Kata N$t$, 'syllable', array['N']::text[]),
  (2, $t$Suku Kata P$t$, 'syllable', array['P']::text[]),
  (3, $t$Suku Kata R$t$, 'syllable', array['R']::text[]),
  (4, $t$Suku Kata S$t$, 'syllable', array['S']::text[]),
  (5, $t$Suku Kata T$t$, 'syllable', array['T']::text[]),
  (6, $t$Latihan Suku Kata N-T$t$, 'syllable', array['N', 'P', 'R', 'S', 'T']::text[]),
  (7, $t$Kata di Rumah$t$, 'word', array['na-si', 'ro-ti', 'su-su']::text[]),
  (8, $t$Kata di Rumah 2$t$, 'word', array['sa-pi', 'ru-sa', 'to-pi']::text[]),
  (9, $t$Kata di Rumah 3$t$, 'word', array['ko-pi', 'pi-ta', 'sa-te']::text[])
) as v(order_index, title, kind, letters)
where s.unit = 7 and s.section = 1
on conflict (section_id, order_index) do update
  set title = excluded.title, kind = excluded.kind, letters = excluded.letters;

-- ---------------------------------------------------- Unit 8: Huruf Q sampai Z
insert into public.sections (unit, section, title, guide, is_premium)
values (8, 1, $t$Huruf Q sampai Z$t$, $g$Huruf terakhir di alfabet: Q, V, W, X, Y, dan Z. Beberapa huruf ini jarang dipakai dalam bahasa Indonesia, jadi cukup dikenali bentuk dan bunyinya.$g$, true)
on conflict (unit, section) do update
  set title = excluded.title, guide = excluded.guide, is_premium = excluded.is_premium;
insert into public.lessons (section_id, order_index, title, kind, letters)
select s.id, v.order_index, v.title, v.kind, v.letters
from public.sections s, (values
  (1, $t$Huruf Q$t$, 'letter', array['Q']::text[]),
  (2, $t$Huruf V$t$, 'letter', array['V']::text[]),
  (3, $t$Huruf W$t$, 'letter', array['W']::text[]),
  (4, $t$Huruf X$t$, 'letter', array['X']::text[]),
  (5, $t$Huruf Y$t$, 'letter', array['Y']::text[]),
  (6, $t$Huruf Z$t$, 'letter', array['Z']::text[]),
  (7, $t$Latihan Huruf Q-Z$t$, 'review', array['Q', 'V', 'W', 'X', 'Y', 'Z']::text[]),
  (8, $t$Kuis Huruf Q-Z$t$, 'quiz', array['Q', 'V', 'W', 'X', 'Y', 'Z']::text[]),
  (9, $t$Tantangan Huruf Q-Z$t$, 'challenge', array['Q', 'V', 'W', 'X', 'Y', 'Z']::text[])
) as v(order_index, title, kind, letters)
where s.unit = 8 and s.section = 1
on conflict (section_id, order_index) do update
  set title = excluded.title, kind = excluded.kind, letters = excluded.letters;

-- ---------------------------------------------------- Unit 9: Ayo Membaca Kalimat
insert into public.sections (unit, section, title, guide, is_premium)
values (9, 1, $t$Ayo Membaca Kalimat$t$, $g$Saatnya membaca kata yang lebih panjang dan kalimat pendek. Tunjuk tiap kata dengan jari saat si kecil membaca, lalu tanyakan isi kalimatnya, misalnya "Siapa yang suka susu?"$g$, true)
on conflict (unit, section) do update
  set title = excluded.title, guide = excluded.guide, is_premium = excluded.is_premium;
insert into public.lessons (section_id, order_index, title, kind, letters)
select s.id, v.order_index, v.title, v.kind, v.letters
from public.sections s, (values
  (1, $t$Kata Panjang$t$, 'word', array['se-pa-tu', 'se-pe-da', 'bo-ne-ka']::text[]),
  (2, $t$Kata Panjang 2$t$, 'word', array['ke-la-pa', 'ke-re-ta', 'ce-la-na']::text[]),
  (3, $t$Ini dan Itu$t$, 'sentence', array['Ini bola.', 'Itu kuda.', 'Ini topi.']::text[]),
  (4, $t$Aku Suka$t$, 'sentence', array['Rara suka susu.', 'Dodi suka roti.', 'Budi suka bola.']::text[]),
  (5, $t$Ayo Membaca$t$, 'sentence', array['Mama baca buku.', 'Bibi beli roti.', 'Nina cuci kaki.']::text[])
) as v(order_index, title, kind, letters)
where s.unit = 9 and s.section = 1
on conflict (section_id, order_index) do update
  set title = excluded.title, kind = excluded.kind, letters = excluded.letters;
