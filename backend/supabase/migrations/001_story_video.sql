-- =====================================================
-- Migrasi 001: video dongeng + isi cerita Malin Kundang
-- Jalankan di Supabase SQL Editor HANYA jika database sudah dibuat
-- dengan schema.sql versi lama (belum ada kolom video_url).
-- Aman dijalankan ulang.
-- =====================================================

alter table public.stories add column if not exists video_url text;

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
