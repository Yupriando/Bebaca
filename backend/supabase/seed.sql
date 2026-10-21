-- =====================================================
-- Data awal. Jalankan SEKALI setelah schema.sql
-- =====================================================

do $$
declare
  s1 uuid; s2 uuid; c uuid;
begin
  -- ===== Belajar =====
  insert into sections (unit, section, title, guide)
  values (1, 1, 'Huruf Vokal', 'Kenali huruf vokal A, I, U, E, O dan cara membacanya.')
  returning id into s1;

  insert into lessons (section_id, order_index, title, kind, letters) values
    (s1, 1, 'Huruf A', 'letter', array['A']),
    (s1, 2, 'Huruf I', 'letter', array['I']),
    (s1, 3, 'Huruf U', 'letter', array['U']),
    (s1, 4, 'Huruf E', 'letter', array['E']),
    (s1, 5, 'Huruf O', 'letter', array['O']),
    (s1, 6, 'Latihan Vokal', 'review', array['A','I','U','E','O']),
    (s1, 7, 'Kuis Vokal', 'quiz', array['A','I','U','E','O']),
    (s1, 8, 'Tantangan Vokal', 'challenge', array['A','I','U','E','O']);

  insert into sections (unit, section, title, guide)
  values (2, 1, 'Huruf Konsonan', 'Kenali huruf konsonan dan gabungkan dengan huruf vokal.')
  returning id into s2;

  insert into lessons (section_id, order_index, title, kind, letters) values
    (s2, 1, 'Huruf B', 'letter', array['B']),
    (s2, 2, 'Huruf C', 'letter', array['C']),
    (s2, 3, 'Huruf D', 'letter', array['D']),
    (s2, 4, 'Huruf F', 'letter', array['F']),
    (s2, 5, 'Huruf G', 'letter', array['G']),
    (s2, 6, 'Latihan Konsonan', 'review', array['B','C','D','F','G']),
    (s2, 7, 'Kuis Konsonan', 'quiz', array['B','C','D','F','G']),
    (s2, 8, 'Tantangan Konsonan', 'challenge', array['B','C','D','F','G']);

  -- ===== Dongeng =====
  insert into story_categories (name, sort_order) values ('Dongeng tradisional', 1) returning id into c;
  insert into stories (category_id, title, sort_order)
  select c, t, ord from unnest(array[
    'Malin Kundang', 'Timun Mas', 'Legenda Jaka Tarub', 'Putri Sambaria',
    'Bawang Merah Bawang Putih', 'Si Kancil dan Buaya', 'Sangkuriang', 'Roro Jonggrang'
  ]) with ordinality as x(t, ord);

  insert into story_categories (name, sort_order) values ('Fabel', 2) returning id into c;
  insert into stories (category_id, title, sort_order)
  select c, t, ord from unnest(array[
    'Fabel Nusantara', 'Ayo Jadi Anak Baik!', 'Guru Baru Untuk Kelinci', 'Dongeng Fabel Imajinatif',
    'Kura-kura dan Kelinci', 'Semut dan Belalang', 'Singa dan Tikus', 'Burung Gagak yang Haus'
  ]) with ordinality as x(t, ord);

  insert into story_categories (name, sort_order) values ('Mitologi', 3) returning id into c;
  insert into stories (category_id, title, sort_order)
  select c, t, ord from unnest(array[
    'Mitologi Yunani', 'Pegasus', 'Mitologi Dunia', 'Pertempuran Para Titan',
    'Hercules', 'Dewi Athena', 'Odysseus', 'Thor dan Palu Ajaib'
  ]) with ordinality as x(t, ord);

  insert into story_categories (name, sort_order) values ('Legenda Nusantara', 4) returning id into c;
  insert into stories (category_id, title, sort_order)
  select c, t, ord from unnest(array[
    'Asal Usul Danau Toba', 'Legenda Banyuwangi', 'Batu Menangis',
    'Tangkuban Perahu', 'Putri Mandalika', 'Asal Mula Nama Surabaya'
  ]) with ordinality as x(t, ord);

  insert into story_categories (name, sort_order) values ('Dongeng Dunia', 5) returning id into c;
  insert into stories (category_id, title, sort_order)
  select c, t, ord from unnest(array[
    'Cinderella', 'Pinokio', 'Putri Salju', 'Si Kerudung Merah', 'Aladdin', 'Hansel dan Gretel'
  ]) with ordinality as x(t, ord);
end $$;

-- Isi cerita contoh + (opsional) video
update public.stories
set content = $cerita$Pada zaman dahulu kala, hiduplah seorang ibu dan anak yang bernama Malin Kundang. Karena sang ayah telah meninggal dunia, ibu Malin Kundang harus bekerja keras untuk menghidupi keluarganya.

Saat beranjak dewasa, Malin Kundang merasa kasihan dengan ibunya yang sudah tua dan kelelahan bekerja. Ia ingin mengubah nasib keluarganya. Maka ia memutuskan untuk merantau ke negeri seberang dan mencari pekerjaan di sana.

Ibu merasa sedih, tetapi ia merestui kepergian anaknya. "Pulanglah kalau kamu sudah berhasil, Nak. Ibu akan selalu menunggumu," pesan sang ibu sambil melambaikan tangan di tepi pantai.

Di perantauan, Malin Kundang bekerja dengan rajin dan jujur. Bertahun-tahun kemudian ia menjadi pedagang yang kaya raya. Ia memiliki kapal yang besar dan menikah dengan seorang putri yang cantik.

Suatu hari, kapal Malin Kundang singgah di kampung halamannya. Kabar itu cepat sampai ke telinga sang ibu. Dengan hati gembira, ibu berlari ke pantai dan memeluk anaknya sambil berkata, "Malin, anakku! Ibu sangat rindu padamu!"

Namun Malin Kundang merasa malu di depan istri dan anak buahnya, karena ibunya berpakaian lusuh dan sudah renta. Ia berkata, "Aku tidak mengenal wanita tua ini! Ibuku tidak seperti ini!" Lalu ia menyuruh ibunya pergi.

Ibu sangat sedih dan terluka. Sambil menengadahkan tangan, ia berdoa, "Ya Tuhan, jika dia benar anakku Malin Kundang, berilah dia pelajaran karena telah durhaka."

Tiba-tiba langit menjadi gelap. Angin bertiup kencang dan ombak besar menghantam kapal Malin Kundang hingga hancur. Malin Kundang pun berubah menjadi batu.

Sampai sekarang, batu yang berbentuk orang sedang bersujud itu masih ada di tepi pantai. Pesan dari cerita ini: hormati dan sayangilah ibumu, dan jangan pernah melupakan asal-usulmu.$cerita$
where title = 'Malin Kundang' and content is null;

-- Cara mengisi video & gambar sampul (ganti URL dengan milikmu):
-- update public.stories
-- set video_url = 'https://xxxx.supabase.co/storage/v1/object/public/stories/malin-kundang.mp4',
--     cover_url = 'https://xxxx.supabase.co/storage/v1/object/public/stories/malin-kundang.jpg'
-- where title = 'Malin Kundang';

-- Bebaca Premium: Unit 1 gratis, Unit 2 dst premium;
-- 2 dongeng pertama di tiap kategori gratis, sisanya premium.
update public.sections set is_premium = (unit >= 2);
update public.stories s
set is_premium = r.rn > 2
from (
  select id, row_number() over (partition by category_id order by sort_order, title) as rn
  from public.stories
) r
where r.id = s.id;

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
