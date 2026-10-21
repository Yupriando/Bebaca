-- =====================================================
-- Migration 004: Tambah Materi & Dongeng
-- Jalankan di Supabase SQL Editor (aman dijalankan ulang)
-- =====================================================

-- -------------------------------------------------------
-- MATERI BARU: Unit 2 (Konsonan lanjutan) & Unit 3 (Suku Kata)
-- -------------------------------------------------------
do $$
declare
  s2 uuid;
  s3 uuid;
  s4 uuid;
  c   uuid;
begin

  -- Cari section Unit 2 Section 1 (Konsonan) untuk menambah huruf
  select id into s2 from public.sections where unit = 2 and section = 1;

  if s2 is not null then
    -- Tambah huruf konsonan baru (H, J, K, L, M, N, P, R, S, T)
    -- order_index mulai dari 9 (setelah Tantangan Konsonan di 8)
    insert into public.lessons (section_id, order_index, title, kind, letters)
    values
      (s2,  9, 'Huruf H', 'letter', array['H']),
      (s2, 10, 'Huruf J', 'letter', array['J']),
      (s2, 11, 'Huruf K', 'letter', array['K']),
      (s2, 12, 'Huruf L', 'letter', array['L']),
      (s2, 13, 'Huruf M', 'letter', array['M']),
      (s2, 14, 'Huruf N', 'letter', array['N']),
      (s2, 15, 'Huruf P', 'letter', array['P']),
      (s2, 16, 'Huruf R', 'letter', array['R']),
      (s2, 17, 'Huruf S', 'letter', array['S']),
      (s2, 18, 'Huruf T', 'letter', array['T'])
    on conflict (section_id, order_index) do nothing;

    -- Latihan & Kuis untuk konsonan grup 2
    insert into public.lessons (section_id, order_index, title, kind, letters)
    values
      (s2, 19, 'Latihan Konsonan II',   'review',    array['H','J','K','L','M','N','P','R','S','T']),
      (s2, 20, 'Kuis Konsonan II',      'quiz',      array['H','J','K','L','M','N','P','R','S','T']),
      (s2, 21, 'Tantangan Konsonan II', 'challenge', array['H','J','K','L','M','N','P','R','S','T'])
    on conflict (section_id, order_index) do nothing;
  end if;

  -- Unit 2, Section 2: Konsonan Lanjutan (V, W, X, Y, Z, Q)
  insert into public.sections (unit, section, title, guide, is_premium)
  values (2, 2, 'Konsonan Langka', 'Huruf V, W, X, Y, Z yang jarang dipakai dalam bahasa Indonesia.', true)
  on conflict (unit, section) do nothing;

  select id into s3 from public.sections where unit = 2 and section = 2;
  if s3 is not null then
    insert into public.lessons (section_id, order_index, title, kind, letters)
    values
      (s3, 1, 'Huruf V', 'letter', array['V']),
      (s3, 2, 'Huruf W', 'letter', array['W']),
      (s3, 3, 'Huruf X', 'letter', array['X']),
      (s3, 4, 'Huruf Y', 'letter', array['Y']),
      (s3, 5, 'Huruf Z', 'letter', array['Z']),
      (s3, 6, 'Latihan Konsonan Langka',   'review',    array['V','W','X','Y','Z']),
      (s3, 7, 'Kuis Konsonan Langka',      'quiz',      array['V','W','X','Y','Z']),
      (s3, 8, 'Tantangan Konsonan Langka', 'challenge', array['V','W','X','Y','Z'])
    on conflict (section_id, order_index) do nothing;
  end if;

  -- Unit 3: Suku Kata (Premium)
  insert into public.sections (unit, section, title, guide, is_premium)
  values (3, 1, 'Suku Kata Dasar', 'Gabungkan huruf vokal dan konsonan menjadi suku kata.', true)
  on conflict (unit, section) do nothing;

  select id into s4 from public.sections where unit = 3 and section = 1;
  if s4 is not null then
    insert into public.lessons (section_id, order_index, title, kind, letters)
    values
      (s4, 1, 'BA, BI, BU, BE, BO', 'letter', array['B']),
      (s4, 2, 'CA, CI, CU, CE, CO', 'letter', array['C']),
      (s4, 3, 'DA, DI, DU, DE, DO', 'letter', array['D']),
      (s4, 4, 'FA, FI, FU, FE, FO', 'letter', array['F']),
      (s4, 5, 'GA, GI, GU, GE, GO', 'letter', array['G']),
      (s4, 6, 'HA, HI, HU, HE, HO', 'letter', array['H']),
      (s4, 7, 'Latihan Suku Kata',   'review',    array['B','C','D','F','G','H']),
      (s4, 8, 'Kuis Suku Kata',      'quiz',      array['B','C','D','F','G','H']),
      (s4, 9, 'Tantangan Suku Kata', 'challenge', array['B','C','D','F','G','H'])
    on conflict (section_id, order_index) do nothing;
  end if;

  -- -------------------------------------------------------
  -- DONGENG BARU: Isi teks untuk dongeng yang belum ada
  -- -------------------------------------------------------

  -- Timun Mas
  update public.stories set content = $timun$Dahulu kala, hiduplah seorang petani tua yang sangat mendambakan seorang anak. Suatu hari, raksasa jahat bernama Buto Ijo datang dan menawarkan bantuan.

"Aku akan memberikanmu seorang anak. Tapi saat ia berusia tujuh tahun, aku akan mengambilnya kembali," kata Buto Ijo.

Petani itu pun menerima sebuah biji timun ajaib. Biji itu ditanam dan tumbuh menjadi buah besar berwarna emas. Ketika dibelah, keluarlah seorang bayi cantik. Petani menamainya Timun Mas.

Timun Mas tumbuh menjadi gadis yang baik hati. Tepat di hari ulang tahunnya yang ketujuh, Buto Ijo datang untuk menagih janji. Sang ibu memberikan tiga bungkus bekal ajaib: biji timun, jarum, garam, dan terasi.

Timun Mas berlari sekencang mungkin. Buto Ijo mengejarnya. Timun Mas melempar biji timun – tiba-tiba tumbuh semak belukar tebal yang menghambat langkah Buto Ijo.

Timun Mas berlari lagi. Ia melempar jarum – muncullah hutan bambu yang sangat lebat. Buto Ijo kesulitan melewatinya.

Masih terus dikejar, Timun Mas melempar garam – lautan luas tiba-tiba muncul. Buto Ijo hampir tenggelam, tapi ia berhasil menyeberang.

Akhirnya Timun Mas melempar terasi. Seketika muncullah lautan lumpur yang sangat dalam. Buto Ijo tersedot ke dalamnya dan tidak bisa keluar.

Timun Mas selamat dan kembali ke pelukan ibunya. Mereka hidup bahagia selamanya. Pesan cerita ini: dengan kecerdikan dan keberanian, kita bisa menghadapi masalah sebesar apapun.$timun$
  where title = 'Timun Mas' and content is null;

  -- Bawang Merah Bawang Putih
  update public.stories set content = $bawang$Di sebuah desa, hiduplah dua orang bersaudara tiri bernama Bawang Merah dan Bawang Putih. Bawang Putih adalah gadis yang rajin, baik hati, dan suka menolong. Sedangkan Bawang Merah sangat pemalas dan iri hati.

Ayah mereka telah meninggal, dan kini mereka tinggal bersama ibu tiri Bawang Putih yang pilih kasih.

Setiap hari Bawang Putih mengerjakan semua pekerjaan rumah: memasak, mencuci, menyapu, dan merawat kebun. Namun semua jerih payahnya tidak pernah dihargai.

Suatu hari, saat Bawang Putih sedang mencuci pakaian di sungai, selendang ibu tirinya terbawa arus. Bawang Putih segera mencarinya ke hilir sungai. Ia bertemu dengan nenek tua yang ternyata menyimpan selendang itu.

"Nek, apakah Nenek melihat selendang yang terbawa arus?" tanya Bawang Putih.

"Ya, ada. Tapi maukah kamu membantuku membersihkan rumah ini dulu?" pinta si nenek.

Bawang Putih dengan senang hati membantu nenek itu. Setelah selesai, nenek memberikan selendang dan menghadiahi Bawang Putih dengan sebuah labu kuning.

Ketika labu dipecah di rumah, keluarlah emas dan perhiasan yang berkilau. Ibu tiri dan Bawang Merah yang iri pun pergi ke nenek itu. Tapi Bawang Merah yang malas tidak mau membantu, bahkan berlaku kasar.

Nenek memberikan Bawang Merah sebuah labu besar. Ketika dipecah, keluarlah binatang berbisa yang mengejar mereka.

Ibu tiri dan Bawang Merah akhirnya menyesal dan meminta maaf kepada Bawang Putih. Mereka berjanji tidak akan jahat lagi. Bawang Putih yang baik hati memaafkan mereka.$bawang$
  where title = 'Bawang Merah Bawang Putih' and content is null;

  -- Si Kancil dan Buaya
  update public.stories set content = $kancil$Di tepi sebuah sungai besar, hiduplah seekor kancil kecil yang sangat cerdik. Suatu hari, kancil ingin menyeberangi sungai untuk mencari buah-buahan segar di seberang.

Namun sungai itu dihuni oleh gerombolan buaya yang ganas dan lapar. Kancil tidak bisa berenang dan harus memutar otak.

"Hai Buaya! Aku membawa pesan dari Raja Hutan," teriak Kancil dengan lantang. "Raja ingin menghitung jumlah buaya di sungai ini untuk memberikan hadiah kepada kalian semua!"

Para buaya sangat gembira mendengar kabar hadiah. Mereka segera berbaris rapi dari tepi ke tepi sungai membentuk jembatan.

"Aku akan menghitung satu per satu ya," kata Kancil sambil mulai melompat dari punggung satu buaya ke buaya lainnya. "Satu, dua, tiga... empat, lima... terima kasih atas bantuannya!"

Kancil pun sampai di seberang sungai dengan selamat. Para buaya baru sadar bahwa mereka telah ditipu.

"Curang! Kancil penipu!" teriak para buaya.

"Maaf ya, aku hanya menggunakan kecerdikanku. Kalian tidak terluka kan?" jawab Kancil sambil berlari.

Dari cerita ini kita belajar bahwa kecerdikan dan akal yang baik bisa membantu kita keluar dari kesulitan. Namun ingat, kita harus menggunakan kecerdikan untuk hal yang baik, bukan untuk menipu orang lain.$kancil$
  where title = 'Si Kancil dan Buaya' and content is null;

  -- Kura-kura dan Kelinci
  update public.stories set content = $kura$Di sebuah hutan yang rindang, hiduplah seekor kelinci yang sangat sombong. Setiap hari ia berlari-lari dan selalu membanggakan kecepatannya.

"Tidak ada yang lebih cepat dariku di hutan ini!" sombong Kelinci.

Suatu hari, Kelinci bertemu dengan Kura-kura yang berjalan pelan. Kelinci pun mengejek.

"Hahaha, Kura-kura! Kamu berjalan sangat lambat. Bahkan siput pun bisa lebih cepat darimu!"

Kura-kura tidak marah. Dengan tenang ia berkata, "Kalau begitu, ayo kita berlomba lari sampai ke pohon besar di ujung hutan."

Semua hewan di hutan berkumpul untuk menyaksikan perlombaan. Ketika dimulai, Kelinci langsung berlari kencang jauh meninggalkan Kura-kura.

Melihat Kura-kura masih jauh di belakang, Kelinci memutuskan untuk beristirahat di bawah pohon rindang. "Aku akan tidur sebentar. Kura-kura tidak akan bisa menyusulku."

Kelinci pun tertidur pulas. Sementara itu, Kura-kura terus berjalan dengan sabar, tidak berhenti, tidak mengeluh, selangkah demi selangkah.

Ketika Kelinci terbangun, ia kaget melihat Kura-kura sudah hampir sampai di garis finish! Kelinci berlari sekencang mungkin, tapi sudah terlambat.

Kura-kura menang! Semua hewan bertepuk tangan.

"Selamat, Kura-kura!" seru semua hewan.

Kelinci malu dan berjanji tidak akan sombong lagi. Dari cerita ini kita belajar: kesabaran dan ketekunan lebih bermakna daripada bakat tanpa usaha.$kura$
  where title = 'Kura-kura dan Kelinci' and content is null;

  -- Semut dan Belalang
  update public.stories set content = $semut$Suatu musim panas yang terik, Belalang asyik bermain musik dan bernyanyi seharian. Ia melompat-lompat riang di antara dedaunan hijau.

Tidak jauh dari sana, Semut bekerja keras mengangkut makanan. Walaupun hari sangat panas, Semut tidak berhenti bekerja.

"Hai Semut! Mengapa kamu bekerja terus? Ayo bermain bersamaku!" ajak Belalang.

"Tidak, aku harus mengumpulkan makanan untuk musim dingin nanti," jawab Semut sambil terus berjalan.

Belalang tertawa. "Musim dingin masih lama! Santai saja dulu." Belalang tidak peduli dan terus bernyanyi.

Waktu berlalu. Musim dingin pun tiba. Angin bertiup kencang dan salju turun lebat. Belalang kedinginan dan kelaparan karena tidak punya persediaan makanan.

Dengan susah payah, Belalang pergi mengetuk pintu rumah Semut. "Semut, tolonglah aku. Aku kelaparan dan kedinginan."

Semut membukakan pintu. Ia sudah punya banyak persediaan makanan di dalam rumahnya yang hangat.

"Masuklah, Belalang. Kamu boleh tinggal bersamaku. Tapi mulai sekarang, kita harus sama-sama bekerja ya."

Belalang sangat bersyukur. Ia berjanji tidak akan malas lagi. Mereka pun hidup bersama dengan rukun.

Pesan cerita ini: jangan suka menunda pekerjaan. Rajin bekerja sekarang akan membuat hidup kita lebih baik di kemudian hari.$semut$
  where title = 'Semut dan Belalang' and content is null;

  -- Cinderella
  update public.stories set content = $cinderella$Di sebuah kerajaan yang indah, hiduplah seorang gadis baik hati bernama Cinderella. Ia tinggal bersama ibu tiri dan dua saudara tirinya yang sangat jahat dan pemalas.

Cinderella dipaksa mengerjakan semua pekerjaan rumah: memasak, membersihkan, mencuci, dan berbagai pekerjaan berat lainnya. Meski begitu, Cinderella tidak pernah mengeluh.

Suatu hari, datang undangan dari istana: Pangeran akan mengadakan pesta dansa besar-besaran untuk mencari calon permaisuri. Ibu tiri dan saudara tirinya bersorak kegirangan.

"Kamu tidak boleh ikut!" bentak ibu tiri kepada Cinderella.

Cinderella sedih. Namun tiba-tiba muncullah peri baik hati. Dengan tongkat ajaibnya, peri mengubah labu menjadi kereta emas, tikus menjadi kuda, dan pakaian lusuh Cinderella menjadi gaun pesta yang indah berkilau, lengkap dengan sepatu kaca yang menawan.

"Ingat, sebelum tengah malam kamu harus pulang. Setelah itu, semua keajaiban ini akan lenyap," pesan sang peri.

Di istana, Pangeran langsung terpesona oleh Cinderella. Mereka menari bersama sepanjang malam. Namun ketika jam mulai berdentang dua belas kali, Cinderella berlari keluar. Sebuah sepatu kacanya tertinggal di tangga istana.

Pangeran mencari gadis itu ke seluruh kerajaan dengan membawa sepatu kaca. Ketika tiba di rumah Cinderella, saudara tirinya gagal memakai sepatu itu. Tapi sepatu kaca itu cocok sempurna di kaki Cinderella.

Cinderella dan Pangeran menikah dan hidup bahagia selamanya. Kebaikan hati Cinderella membawanya ke kehidupan yang indah.$cinderella$
  where title = 'Cinderella' and content is null;

  -- Asal Usul Danau Toba
  update public.stories set content = $toba$Dahulu kala di tanah Batak, Sumatera Utara, hiduplah seorang pemuda miskin bernama Toba. Setiap hari ia memancing di sungai untuk mencari makan.

Suatu hari, Toba mendapat ikan yang luar biasa indah berwarna emas. Tapi ketika ia ingin memasaknya, ikan itu berubah menjadi seorang gadis cantik.

"Jangan takut. Aku adalah gadis dari dunia ikan. Karena kamu telah menyelamatkanku, aku ingin menjadi istrimu," kata gadis itu.

"Tapi ada satu syarat: jangan pernah ceritakan kepada siapapun bahwa aku berasal dari ikan."

Toba setuju. Mereka pun menikah dan dikaruniai seorang putra bernama Samosir. Mereka hidup bahagia.

Samosir tumbuh menjadi anak yang nakal dan pelupa. Suatu hari ia diminta ibunya mengantarkan makanan untuk ayahnya di ladang. Di tengah jalan, Samosir memakan habis semua bekal itu karena lapar.

Toba yang lapar dan lelah marah besar. Tanpa sadar ia berteriak, "Dasar anak ikan! Sama seperti ibumu!"

Langit pun berubah gelap. Hujan deras turun dengan petir yang menggelegar. Air terus naik menggenangi daratan.

Ibu Samosir berubah kembali menjadi ikan dan masuk ke air. Toba menyesal tapi sudah terlambat.

Samosir berlari ke bukit yang tinggi untuk selamat. Banjir besar itu akhirnya membentuk sebuah danau yang luas dan indah. Di tengahnya terdapat sebuah pulau yang kemudian dinamakan Pulau Samosir, dan danaunya disebut Danau Toba.

Danau Toba kini menjadi salah satu danau terindah di dunia, dan merupakan kebanggaan tanah Batak.$toba$
  where title = 'Asal Usul Danau Toba' and content is null;

  -- Dongeng baru: Kategori Fabel
  select id into c from public.story_categories where name = 'Fabel';
  if c is not null then
    insert into public.stories (category_id, title, sort_order, is_premium, content)
    values (c, 'Gagak dan Kendi Air', 9, false, $gagak$Di musim kemarau yang panjang, seekor Gagak kehausan terbang ke sana ke mari mencari air minum.

Akhirnya ia menemukan sebuah kendi berisi sedikit air. Tapi paruhnya tidak bisa mencapai air di dalam kendi karena airnya terlalu sedikit.

Gagak tidak putus asa. Ia berpikir keras. Kemudian ia menemukan ide: ia mulai mengambil kerikil satu per satu dengan paruhnya dan memasukkannya ke dalam kendi.

Kerikil demi kerikil dimasukkan. Pelan-pelan permukaan air dalam kendi naik. Akhirnya air itu bisa dijangkau oleh paruh Gagak.

Gagak minum sepuasnya dan merasa sangat lega.

Dari cerita ini kita belajar: ketika menghadapi masalah, gunakan akal pikiran untuk mencari solusi. Kesabaran dan ketekunan selalu membuahkan hasil.$gagak$)
    on conflict do nothing;
  end if;

  -- -------------------------------------------------------
  -- Update premium status untuk materi baru
  -- -------------------------------------------------------
  -- Section baru (unit >= 2 section >= 2, dan unit >= 3) = premium
  update public.sections set is_premium = true
  where (unit = 2 and section >= 2) or unit >= 3;

end $$;
