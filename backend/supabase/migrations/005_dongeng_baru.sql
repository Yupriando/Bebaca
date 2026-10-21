-- =====================================================
-- Migration 005: Tambah Dongeng Baru
-- Jalankan di Supabase SQL Editor (aman dijalankan ulang)
-- =====================================================

do $$
declare
  cat_rakyat uuid;
  cat_fabel   uuid;
  cat_dunia   uuid;
begin

  -- Ambil ID kategori yang ada
  select id into cat_rakyat from public.story_categories where name = 'Cerita Rakyat';
  select id into cat_fabel   from public.story_categories where name = 'Fabel';
  select id into cat_dunia   from public.story_categories where name ilike '%dunia%';

  -- Jika kategori "Dunia" tidak ada, pakai Fabel sebagai fallback
  if cat_dunia is null then
    cat_dunia := cat_fabel;
  end if;

  -- ─────────────────────────────────────────────────
  -- 1. Malin Kundang (Cerita Rakyat)
  -- ─────────────────────────────────────────────────
  if cat_rakyat is not null then
    insert into public.stories (category_id, title, sort_order, is_premium, content)
    values (cat_rakyat, 'Malin Kundang', 20, false, $story$Dahulu kala di sebuah desa nelayan di pesisir Sumatera Barat, hiduplah seorang ibu miskin bersama anaknya yang bernama Malin Kundang. Ayah Malin sudah lama pergi merantau dan tidak pernah kembali.

Meski hidup susah, sang ibu selalu menyayangi Malin dengan sepenuh hati. Ia bekerja keras siang dan malam untuk membiayai makan mereka sehari-hari.

Ketika dewasa, Malin memohon izin kepada ibunya untuk merantau mencari kehidupan yang lebih baik. Sang ibu mengizinkan dengan berat hati dan penuh air mata.

"Baik-baiklah di rantau, Nak. Ibu akan selalu mendoakanmu," kata sang ibu.

Malin pun pergi berlayar. Bertahun-tahun ia tidak memberi kabar. Namun akhirnya kabar angin pun terdengar: Malin telah berhasil. Ia kini menjadi saudagar kaya dan menikahi wanita bangsawan.

Suatu hari, kapal megah merapat di pelabuhan desa. Sang ibu yang mendengar kabar itu segera berlari ke pelabuhan dengan hati yang sangat rindu.

"Malin! Anakku! Ibu sangat merindukanmu!" seru sang ibu sambil memeluk Malin.

Namun Malin mendorong ibunya. Di depan istri dan anak buahnya, ia malu mengakui bahwa wanita tua miskin berpakaian compang-camping itu adalah ibunya.

"Pergi! Aku tidak mengenalmu, wanita tua! Aku tidak mungkin punya ibu sepertimu!" bentak Malin dengan keras.

Sang ibu terdiam. Hatinya hancur berkeping-keping. Air matanya jatuh deras. Lalu dengan suara parau ia berdoa, "Ya Tuhan, jika dia memang anakku, berilah ia pelajaran atas kedurhakaan ini."

Langit pun berubah gelap. Badai besar datang menerpa. Petir menyambar kapal Malin. Malin Kundang yang durhaka berteriak ketakutan, namun sudah terlambat. Ia berubah menjadi batu.

Sampai kini, di pantai Air Manis, Sumatera Barat, terdapat batu yang bentuknya menyerupai orang yang sedang berlutut. Orang-orang menyebutnya Batu Malin Kundang.

Pesan cerita ini: jangan pernah durhaka kepada orang tua yang telah membesarkan kita dengan kasih sayang.$story$)
    on conflict do nothing;
  end if;

  -- ─────────────────────────────────────────────────
  -- 2. Sangkuriang (Cerita Rakyat)
  -- ─────────────────────────────────────────────────
  if cat_rakyat is not null then
    insert into public.stories (category_id, title, sort_order, is_premium, content)
    values (cat_rakyat, 'Sangkuriang', 21, false, $story$Di tanah Sunda, hiduplah seorang putri cantik bernama Dayang Sumbi. Ia memiliki seekor anjing setia bernama Tumang yang sesungguhnya adalah dewa dalam wujud anjing.

Mereka dikaruniai seorang putra bernama Sangkuriang. Suatu hari, Sangkuriang dan Tumang berburu ke hutan. Karena tidak mendapat hewan buruan, Sangkuriang dalam amarahnya membunuh Tumang. Ia tidak tahu bahwa Tumang adalah ayah kandungnya.

Dayang Sumbi yang mengetahui hal itu sangat marah dan memukul kepala Sangkuriang hingga terluka. Sangkuriang pun diusir dari rumah.

Bertahun-tahun berlalu. Sangkuriang tumbuh menjadi pemuda tampan dan gagah. Suatu hari ia bertemu seorang wanita cantik di hutan — tanpa ia sadari, itu adalah Dayang Sumbi, ibunya sendiri. Dayang Sumbi awet muda karena karunia para dewa.

Sangkuriang jatuh cinta dan melamar Dayang Sumbi. Namun Dayang Sumbi melihat bekas luka di kepala pemuda itu dan menyadari bahwa ia adalah Sangkuriang, anaknya!

Dayang Sumbi kebingungan. Ia tidak mau menolak terang-terangan karena takut Sangkuriang marah. Akhirnya ia mengajukan syarat yang mustahil:

"Aku mau menikah denganmu, tapi kamu harus membuat danau besar beserta perahunya dalam satu malam sebelum ayam jantan berkokok."

Sangkuriang menyanggupi. Dengan kesaktiannya ia memanggil para makhluk gaib untuk membantu. Pekerjaan hampir selesai menjelang subuh.

Dayang Sumbi panik. Ia menebarkan kain merah di ufuk timur, membuat sinar menyerupai fajar. Ayam jantan pun berkokok. Para makhluk gaib kabur karena mengira hari sudah pagi.

Sangkuriang marah besar karena pekerjaannya belum selesai. Dalam amarahnya, ia menendang perahu besar yang sedang dibuatnya. Perahu terbalik dan menjadi sebuah gunung. Gunung itulah yang kini kita kenal sebagai Gunung Tangkuban Perahu di Jawa Barat.$story$)
    on conflict do nothing;
  end if;

  -- ─────────────────────────────────────────────────
  -- 3. Roro Jonggrang (Cerita Rakyat)
  -- ─────────────────────────────────────────────────
  if cat_rakyat is not null then
    insert into public.stories (category_id, title, sort_order, is_premium, content)
    values (cat_rakyat, 'Roro Jonggrang', 22, false, $story$Di Kerajaan Prambanan, hiduplah putri cantik bernama Roro Jonggrang, putri Raja Prabu Baka. Ayahnya adalah raja yang zalim dan ditakuti seluruh negeri.

Suatu hari, Kerajaan Prambanan diserang oleh Kerajaan Pengging yang dipimpin oleh pemuda sakti bernama Bandung Bondowoso. Prabu Baka tewas dalam pertempuran itu.

Bandung Bondowoso melihat kecantikan Roro Jonggrang dan langsung jatuh hati. Ia pun melamar sang putri.

Roro Jonggrang tidak mau menikah dengan orang yang membunuh ayahnya. Namun ia tidak berani menolak secara terang-terangan. Ia pun mengajukan syarat:

"Aku mau menikah denganmu jika kamu bisa membangun seribu candi dalam satu malam."

Bandung Bondowoso menyanggupi. Dengan bantuan para jin dan makhluk gaib, ia mulai membangun candi. Pekerjaannya sangat cepat. Menjelang subuh, sudah hampir 1.000 candi selesai.

Roro Jonggrang panik. Ia segera membangunkan dayang-dayang dan wanita desa untuk menumbuk padi dan membakar jerami di sebelah timur. Ayam-ayam jantan pun terbangun dan berkokok mengira hari sudah pagi.

Para jin kabur meninggalkan pekerjaan mereka. Bandung Bondowoso marah besar ketika menghitung candi yang telah selesai — hanya 999 buah.

Mengetahui tipu daya Roro Jonggrang, Bandung Bondowoso murka. Ia mengutuk Roro Jonggrang menjadi arca batu untuk melengkapi candi yang keseribu.

Candi-candi itu kini dikenal sebagai Candi Prambanan yang terletak di perbatasan Yogyakarta dan Jawa Tengah. Arca Roro Jonggrang masih bisa kita lihat hingga hari ini.$story$)
    on conflict do nothing;
  end if;

  -- ─────────────────────────────────────────────────
  -- 4. Lutung Kasarung (Cerita Rakyat)
  -- ─────────────────────────────────────────────────
  if cat_rakyat is not null then
    insert into public.stories (category_id, title, sort_order, is_premium, content)
    values (cat_rakyat, 'Lutung Kasarung', 23, true, $story$Di Kerajaan Pasundan, hiduplah tujuh orang putri. Putri bungsu bernama Purbasari adalah yang paling baik hati dan bijaksana. Namun kakaknya, Purbararang, sangat iri dan jahat.

Purbararang memfitnah Purbasari kepada ayah mereka. Akibatnya, Purbasari diusir dari istana dan diasingkan ke tengah hutan.

Di hutan, Purbasari bertemu dengan seekor lutung (monyet) hitam yang ternyata bisa berbicara. Lutung itu bernama Guruminda, seorang pangeran dari kahyangan yang sedang dikutuk.

Lutung Kasarung (lutung yang tersesat) menemani dan melindungi Purbasari di hutan. Ia membantu Purbasari mendapat makanan dan membuatkan tempat tinggal yang nyaman.

Suatu hari, Purbararang mengadakan sayembara: siapapun yang memiliki kolam paling indah akan memenangkan hadiah. Lutung Kasarung membantu Purbasari dengan menciptakan kolam ajaib yang sangat indah, jauh lebih cantik dari kolam Purbararang.

Malu dan marah, Purbararang menantang Purbasari: siapa yang memiliki tunangan paling tampan. Purbararang menunjuk tunangannya yang gagah. Tapi ketika Purbasari menunjuk Lutung Kasarung, terjadi keajaiban.

Lutung Kasarung berubah menjadi seorang pangeran muda yang sangat tampan dan berwibawa. Guruminda telah bebas dari kutukan.

Purbararang akhirnya mengakui kesalahannya. Purbasari yang baik hati memaafkannya. Purbasari dan Guruminda pun menikah dan memerintah kerajaan dengan adil dan bijaksana.$story$)
    on conflict do nothing;
  end if;

  -- ─────────────────────────────────────────────────
  -- 5. Kucing dan Tikus (Fabel)
  -- ─────────────────────────────────────────────────
  if cat_fabel is not null then
    insert into public.stories (category_id, title, sort_order, is_premium, content)
    values (cat_fabel, 'Kucing dan Tikus', 10, false, $story$Dahulu kala, Kucing dan Tikus adalah sahabat baik. Mereka sering bermain bersama dan berbagi makanan.

Suatu musim dingin, keduanya sepakat untuk menyimpan makanan bersama di dalam sebuah panci lemak untuk dimakan saat musim dingin tiba. Panci itu mereka sembunyikan di bawah altar sebuah gereja.

Namun Kucing tidak sabar. Ia sering diam-diam pergi ke gereja sendirian. Pertama kali ia berkata kepada Tikus, "Aku diundang menjadi ayah baptis anak kucing tetangga."

"Apa nama bayi itu?" tanya Tikus.

"Mulai-Habis," jawab Kucing. Padahal itu bohong. Kucing pergi ke gereja dan makan sepertiga panci lemak itu sendirian.

Beberapa hari kemudian Kucing berbohong lagi. "Ada undangan baptis lagi. Nama bayinya Setengah-Habis."

Kucing kembali ke gereja dan menghabiskan setengah lemak yang tersisa.

Tidak lama kemudian, Kucing berbohong untuk ketiga kalinya. "Ada bayi lagi. Namanya Habis-Sama-Sekali."

Kali ini Kucing menghabiskan seluruh lemak di dalam panci.

Ketika musim dingin tiba, Tikus mengajak Kucing mengambil makanan mereka. Namun ketika mereka membuka panci, panci itu sudah kosong!

Tikus baru menyadari bahwa selama ini ia telah ditipu. Ia tidak mau berteman dengan Kucing lagi.

Pesan cerita ini: persahabatan yang dibangun di atas kebohongan tidak akan bertahan lama. Kejujuran adalah dasar dari setiap hubungan yang baik.$story$)
    on conflict do nothing;
  end if;

  -- ─────────────────────────────────────────────────
  -- 6. Singa dan Tikus Kecil (Fabel)
  -- ─────────────────────────────────────────────────
  if cat_fabel is not null then
    insert into public.stories (category_id, title, sort_order, is_premium, content)
    values (cat_fabel, 'Singa dan Tikus Kecil', 11, false, $story$Suatu hari, Singa Raja Hutan sedang tidur siang dengan nyenyak di bawah pohon besar. Tiba-tiba seekor tikus kecil berlari melewati hidungnya dan tanpa sengaja membangunkannya.

Singa mengaum keras dan menangkap si Tikus dengan cakarnya yang besar.

"Ampun, Raja! Jangan makan aku!" pinta Tikus dengan ketakutan. "Suatu hari nanti aku pasti bisa membalas kebaikanmu!"

Singa tertawa terbahak-bahak. Ia merasa lucu mendengar seekor tikus kecil berjanji akan membalas jasanya. Namun karena merasa kasihan, ia melepaskan tikus itu.

"Pergilah, aku tidak lapar hari ini."

Beberapa minggu kemudian, Singa terperangkap dalam jaring yang dipasang oleh para pemburu. Ia mengaum keras meminta tolong, tapi tidak ada yang berani membantu.

Tikus yang mendengar suara itu segera berlari mendekati Singa. Tanpa ragu-ragu, Tikus mulai menggigiti tali-tali jaring itu satu per satu.

"Apa yang kamu lakukan?" tanya Singa keheranan.

"Aku membalas kebaikanmu, Singa!" kata Tikus sambil terus bekerja keras.

Tidak lama kemudian, jaring itu putus dan Singa berhasil bebas. Singa sangat terharu.

"Aku tadi tertawa ketika kamu berjanji akan menolongku. Ternyata seekor tikus kecil pun bisa menjadi pahlawan yang besar. Terima kasih, sahabatku."

Pesan cerita ini: jangan pernah meremehkan siapapun. Pertolongan bisa datang dari mana saja, bahkan dari yang paling lemah sekalipun.$story$)
    on conflict do nothing;
  end if;

  -- ─────────────────────────────────────────────────
  -- 7. Putri Salju (Dongeng Dunia)
  -- ─────────────────────────────────────────────────
  if cat_dunia is not null then
    insert into public.stories (category_id, title, sort_order, is_premium, content)
    values (cat_dunia, 'Putri Salju', 10, true, $story$Di sebuah kerajaan yang diselimuti salju, lahirlah seorang putri cantik dengan kulit seputih salju, bibir semerah mawar, dan rambut sehitam eboni. Sang raja menamainya Putri Salju.

Ketika Putri Salju masih kecil, ibunya meninggal dunia. Raja menikah lagi dengan seorang wanita cantik. Namun ibu tiri itu sangat jahat dan sombong.

Ibu tiri memiliki sebuah cermin ajaib. Setiap hari ia bertanya, "Cermin, cermin di dinding, siapakah yang paling cantik di negeri ini?"

Selama bertahun-tahun cermin selalu menjawab, "Engkaulah yang paling cantik, Ratu."

Namun suatu hari, ketika Putri Salju beranjak dewasa, cermin menjawab berbeda: "Putri Saljulah yang paling cantik sekarang."

Ratu murka. Ia memerintahkan pemburu untuk membawa Putri Salju ke hutan dan membunuhnya. Namun pemburu tidak tega. Ia melepaskan Putri Salju dan berpesan agar gadis itu jangan pernah kembali ke istana.

Putri Salju berlari jauh ke dalam hutan hingga menemukan sebuah gubuk kecil milik tujuh kurcaci. Para kurcaci yang baik hati mengizinkan Putri Salju tinggal bersama mereka.

Namun ratu jahat mengetahui bahwa Putri Salju masih hidup. Ia menyamar menjadi nenek tua dan menawarkan apel merah yang telah diracun.

Putri Salju yang polos memakan apel itu dan langsung jatuh tertidur seperti mati. Para kurcaci bersedih dan meletakkannya dalam peti kaca.

Suatu hari, seorang pangeran dari kerajaan lain melewati hutan itu. Ia melihat Putri Salju dalam peti kaca dan langsung jatuh cinta. Ketika ia mencium kening Putri Salju, keajaiban terjadi: racun apel hilang dan Putri Salju terbangun.

Pangeran dan Putri Salju menikah dan hidup bahagia. Kebaikan hati Putri Salju telah membawanya kepada kebahagiaan sejati.$story$)
    on conflict do nothing;
  end if;

  -- ─────────────────────────────────────────────────
  -- 8. Beauty and The Beast / Si Cantik dan Si Buas (Dongeng Dunia)
  -- ─────────────────────────────────────────────────
  if cat_dunia is not null then
    insert into public.stories (category_id, title, sort_order, is_premium, content)
    values (cat_dunia, 'Si Cantik dan Si Buas', 11, true, $story$Di sebuah kota kecil, hiduplah seorang pedagang dengan tiga putrinya. Putri bungsunya bernama Belle, dikenal karena kecantikan dan kecintaannya pada buku.

Suatu hari sang ayah tersesat di hutan dan menemukan sebuah istana besar yang misterius. Ia bermalam di sana. Ketika hendak pulang, ia memetik mawar untuk Belle. Tiba-tiba muncullah makhluk menakutkan bertubuh besar dan berbulu.

"Berani kamu mencuri mawarku! Sekarang kamu harus mati atau menyerahkan seorang putrimu untuk tinggal bersamaku!" bentak Si Buas.

Belle yang mendengar cerita ayahnya bersedia mengorbankan dirinya demi menyelamatkan sang ayah. Ia pergi ke istana Si Buas.

Awalnya Belle sangat takut dengan penampilan Si Buas yang mengerikan. Namun lama-kelamaan ia menyadari bahwa Si Buas sebenarnya baik hati, cerdas, dan lembut.

Mereka banyak menghabiskan waktu bersama: membaca buku, makan malam, dan berjalan di taman. Belle mulai melupakan rupa Si Buas dan melihat hatinya yang baik.

Suatu hari, Belle mendapat kabar bahwa ayahnya sakit keras. Si Buas mengizinkan Belle pulang, meski hatinya sangat sedih karena takut kehilangan Belle selamanya.

Di rumah, saudara-saudara Belle yang iri berusaha membujuknya untuk tidak kembali. Namun Belle melihat dalam cermin ajaib bahwa Si Buas sekarat karena patah hati.

Belle segera berlari kembali ke istana. Di sisi Si Buas yang terbaring lemah, Belle berkata, "Aku mencintaimu."

Seketika itu, sinar cahaya menyinari Si Buas. Kutukan yang selama ini membebaninya akhirnya terpatahkan. Si Buas berubah menjadi seorang pangeran tampan.

"Seorang penyihir mengutukku karena aku dulu sombong dan tidak mau membantu orang lain. Hanya cinta yang tulus yang bisa membebaskanku," kata sang pangeran.

Belle dan sang pangeran menikah dan hidup bahagia. Cerita ini mengajarkan kita bahwa keindahan sejati ada di dalam hati, bukan pada penampilan luar.$story$)
    on conflict do nothing;
  end if;

end $$;
