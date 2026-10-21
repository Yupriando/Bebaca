-- =====================================================
-- Migration 006: Update & Insert Konten Dongeng (FINAL)
-- Aman dijalankan ulang. Menggabungkan 004 + 005 + fix.
-- =====================================================

do $$
declare
  cat_tradisional uuid;
  cat_fabel       uuid;
  cat_dunia       uuid;
  cat_legenda     uuid;
begin

  -- Ambil ID semua kategori
  select id into cat_tradisional from public.story_categories where name ilike '%tradisional%' or name ilike '%rakyat%' limit 1;
  select id into cat_fabel       from public.story_categories where name ilike 'fabel' limit 1;
  select id into cat_dunia       from public.story_categories where name ilike '%dunia%' limit 1;
  select id into cat_legenda     from public.story_categories where name ilike '%legenda%' or name ilike '%nusantara%' limit 1;

  -- Fallback: kalau kategori masih null, pakai fabel
  if cat_tradisional is null then cat_tradisional := cat_fabel; end if;
  if cat_dunia       is null then cat_dunia       := cat_fabel; end if;
  if cat_legenda     is null then cat_legenda     := cat_fabel; end if;

  -- =======================================================
  -- UPDATE cerita yang sudah ada di database (cocokkan judul)
  -- Pakai ilike agar tidak sensitif huruf besar/kecil
  -- =======================================================

  -- Malin Kundang
  update public.stories set content = $c$Dahulu kala di sebuah desa nelayan di pesisir Sumatera Barat, hiduplah seorang ibu miskin bersama anaknya yang bernama Malin Kundang. Sang ayah sudah lama pergi merantau dan tidak pernah kembali.

Meski hidup susah, sang ibu selalu menyayangi Malin dengan sepenuh hati. Ia bekerja keras siang dan malam untuk membiayai makan mereka sehari-hari.

Ketika dewasa, Malin memohon izin kepada ibunya untuk merantau mencari kehidupan yang lebih baik. Sang ibu mengizinkan dengan berat hati.

"Baik-baiklah di rantau, Nak. Ibu akan selalu mendoakanmu," kata sang ibu.

Malin pun pergi berlayar. Bertahun-tahun ia tidak memberi kabar. Namun akhirnya kabar angin terdengar: Malin telah menjadi saudagar kaya dan menikahi wanita bangsawan.

Suatu hari, kapal megah merapat di pelabuhan desa. Sang ibu berlari ke pelabuhan dengan hati yang sangat rindu.

"Malin! Anakku! Ibu sangat merindukanmu!" seru sang ibu sambil memeluk Malin.

Namun Malin mendorong ibunya. Di depan istri dan anak buahnya, ia malu mengakui bahwa wanita tua miskin itu adalah ibunya.

"Pergi! Aku tidak mengenalmu, wanita tua! Aku tidak mungkin punya ibu sepertimu!" bentak Malin.

Sang ibu terdiam. Hatinya hancur berkeping-keping. Dengan suara parau ia berdoa, "Ya Tuhan, jika dia memang anakku, berilah ia pelajaran atas kedurhakaan ini."

Langit pun berubah gelap. Badai besar datang menerpa. Petir menyambar kapal Malin. Malin Kundang yang durhaka berteriak ketakutan, namun sudah terlambat. Ia berubah menjadi batu.

Sampai kini, di pantai Air Manis, Sumatera Barat, terdapat batu yang bentuknya menyerupai orang yang sedang berlutut. Orang-orang menyebutnya Batu Malin Kundang.

Pesan cerita ini: jangan pernah durhaka kepada orang tua yang telah membesarkan kita dengan kasih sayang.$c$
  where title ilike '%malin kundang%';

  -- Timun Mas
  update public.stories set content = $c$Dahulu kala, hiduplah seorang petani tua yang sangat mendambakan seorang anak. Suatu hari, raksasa jahat bernama Buto Ijo datang dan menawarkan bantuan.

"Aku akan memberikanmu seorang anak. Tapi saat ia berusia tujuh tahun, aku akan mengambilnya kembali," kata Buto Ijo.

Petani itu pun menerima sebuah biji timun ajaib. Biji itu ditanam dan tumbuh menjadi buah besar berwarna emas. Ketika dibelah, keluarlah seorang bayi cantik. Petani menamainya Timun Mas.

Timun Mas tumbuh menjadi gadis yang baik hati. Tepat di hari ulang tahunnya yang ketujuh, Buto Ijo datang untuk menagih janji. Sang ibu memberikan empat bungkus bekal ajaib: biji timun, jarum, garam, dan terasi.

Timun Mas berlari sekencang mungkin. Buto Ijo mengejarnya. Timun Mas melempar biji timun – tiba-tiba tumbuh semak belukar tebal yang menghambat langkah Buto Ijo.

Timun Mas berlari lagi. Ia melempar jarum – muncullah hutan bambu yang sangat lebat. Buto Ijo kesulitan melewatinya.

Masih terus dikejar, Timun Mas melempar garam – lautan luas tiba-tiba muncul. Buto Ijo hampir tenggelam, tapi ia berhasil menyeberang.

Akhirnya Timun Mas melempar terasi. Seketika muncullah lautan lumpur yang sangat dalam. Buto Ijo tersedot ke dalamnya dan tidak bisa keluar.

Timun Mas selamat dan kembali ke pelukan ibunya. Mereka hidup bahagia selamanya.

Pesan cerita ini: dengan kecerdikan dan keberanian, kita bisa menghadapi masalah sebesar apapun.$c$
  where title ilike '%timun mas%';

  -- Bawang Merah Bawang Putih
  update public.stories set content = $c$Di sebuah desa, hiduplah dua orang bersaudara tiri bernama Bawang Merah dan Bawang Putih. Bawang Putih adalah gadis yang rajin, baik hati, dan suka menolong. Sedangkan Bawang Merah sangat pemalas dan iri hati.

Setiap hari Bawang Putih mengerjakan semua pekerjaan rumah: memasak, mencuci, menyapu, dan merawat kebun. Namun semua jerih payahnya tidak pernah dihargai oleh ibu tiri yang pilih kasih.

Suatu hari, saat Bawang Putih sedang mencuci pakaian di sungai, selendang ibu tirinya terbawa arus. Bawang Putih segera mencarinya ke hilir sungai dan bertemu dengan nenek tua yang menyimpan selendang itu.

"Nek, apakah Nenek melihat selendang yang terbawa arus?" tanya Bawang Putih.

"Ya, ada. Tapi maukah kamu membantuku membersihkan rumah ini dulu?" pinta si nenek.

Bawang Putih dengan senang hati membantu. Setelah selesai, nenek memberikan selendang dan menghadiahi Bawang Putih dengan sebuah labu kuning.

Ketika labu dipecah di rumah, keluarlah emas dan perhiasan yang berkilau! Ibu tiri dan Bawang Merah yang iri pun pergi ke nenek itu. Tapi Bawang Merah yang malas tidak mau membantu, bahkan berlaku kasar kepada nenek.

Nenek memberikan Bawang Merah sebuah labu besar. Ketika dipecah, keluarlah binatang berbisa yang mengejar mereka.

Ibu tiri dan Bawang Merah akhirnya menyesal dan meminta maaf kepada Bawang Putih. Bawang Putih yang baik hati memaafkan mereka dengan tulus.

Pesan cerita ini: kebaikan hati selalu mendapat balasan yang baik, sedangkan keserakahan dan kemalasan hanya akan membawa petaka.$c$
  where title ilike '%bawang merah%';

  -- Sangkuriang
  update public.stories set content = $c$Di tanah Sunda, hiduplah seorang putri cantik bernama Dayang Sumbi. Ia memiliki seekor anjing setia bernama Tumang yang sesungguhnya adalah dewa dalam wujud anjing.

Mereka dikaruniai seorang putra bernama Sangkuriang. Suatu hari, Sangkuriang dan Tumang berburu ke hutan. Karena tidak mendapat hewan buruan, Sangkuriang dalam amarahnya membunuh Tumang. Ia tidak tahu bahwa Tumang adalah ayah kandungnya sendiri.

Dayang Sumbi yang mengetahui hal itu sangat marah dan memukul kepala Sangkuriang hingga terluka. Sangkuriang pun diusir dari rumah.

Bertahun-tahun berlalu. Sangkuriang tumbuh menjadi pemuda tampan dan gagah. Suatu hari ia bertemu seorang wanita cantik di hutan. Tanpa ia sadari, itu adalah Dayang Sumbi, ibunya sendiri! Dayang Sumbi awet muda karena karunia para dewa.

Sangkuriang jatuh cinta dan melamar Dayang Sumbi. Namun Dayang Sumbi melihat bekas luka di kepala pemuda itu dan menyadari bahwa ia adalah Sangkuriang, anaknya!

Dayang Sumbi mengajukan syarat yang mustahil: "Aku mau menikah denganmu, tapi kamu harus membuat danau besar beserta perahunya dalam satu malam sebelum ayam berkokok."

Sangkuriang menyanggupi. Dengan kesaktiannya ia memanggil para makhluk gaib. Pekerjaan hampir selesai menjelang subuh.

Dayang Sumbi panik. Ia menebarkan kain merah di ufuk timur, membuat sinar menyerupai fajar. Ayam jantan pun berkokok mengira hari sudah pagi. Para makhluk gaib kabur.

Sangkuriang marah besar karena pekerjaannya belum selesai. Dalam amarahnya, ia menendang perahu besar yang sedang dibuatnya. Perahu terbalik dan menjadi sebuah gunung yang kini kita kenal sebagai Gunung Tangkuban Perahu di Jawa Barat.$c$
  where title ilike '%sangkuriang%';

  -- Roro Jonggrang
  update public.stories set content = $c$Di Kerajaan Prambanan, hiduplah putri cantik bernama Roro Jonggrang, putri Raja Prabu Baka. Suatu hari, kerajaan diserang oleh pemuda sakti bernama Bandung Bondowoso. Prabu Baka tewas dalam pertempuran itu.

Bandung Bondowoso melihat kecantikan Roro Jonggrang dan langsung jatuh hati. Ia pun melamar sang putri.

Roro Jonggrang tidak mau menikah dengan orang yang membunuh ayahnya. Ia mengajukan syarat: "Aku mau menikah denganmu jika kamu bisa membangun seribu candi dalam satu malam."

Bandung Bondowoso menyanggupi. Dengan bantuan para jin, ia mulai membangun candi. Pekerjaan sangat cepat. Menjelang subuh, sudah hampir 1.000 candi selesai.

Roro Jonggrang panik. Ia segera membangunkan dayang-dayang dan wanita desa untuk menumbuk padi dan membakar jerami di sebelah timur. Ayam-ayam jantan pun berkokok mengira hari sudah pagi. Para jin kabur.

Bandung Bondowoso marah besar ketika menghitung candi yang selesai, hanya 999 buah. Mengetahui tipu daya Roro Jonggrang, ia mengutuk Roro Jonggrang menjadi arca batu untuk melengkapi candi yang keseribu.

Candi-candi itu kini dikenal sebagai Candi Prambanan yang terletak di perbatasan Yogyakarta dan Jawa Tengah. Arca Roro Jonggrang masih bisa kita lihat hingga hari ini.$c$
  where title ilike '%roro jonggrang%';

  -- Si Kancil dan Buaya
  update public.stories set content = $c$Di tepi sebuah sungai besar, hiduplah seekor kancil kecil yang sangat cerdik. Suatu hari, kancil ingin menyeberangi sungai untuk mencari buah-buahan segar di seberang.

Namun sungai itu dihuni oleh gerombolan buaya yang ganas. Kancil tidak bisa berenang dan harus memutar otak.

"Hai Buaya! Aku membawa pesan dari Raja Hutan," teriak Kancil. "Raja ingin menghitung jumlah buaya di sungai ini untuk memberikan hadiah kepada kalian semua!"

Para buaya sangat gembira mendengar kabar hadiah. Mereka segera berbaris rapi dari tepi ke tepi sungai membentuk jembatan.

"Aku akan menghitung satu per satu ya," kata Kancil sambil mulai melompat dari punggung satu buaya ke buaya lainnya. "Satu, dua, tiga... empat, lima... terima kasih atas bantuannya!"

Kancil pun sampai di seberang sungai dengan selamat. Para buaya baru sadar bahwa mereka telah ditipu.

"Curang! Kancil penipu!" teriak para buaya.

"Maaf ya, aku hanya menggunakan kecerdikanku. Kalian tidak terluka kan?" jawab Kancil sambil berlari.

Dari cerita ini kita belajar bahwa kecerdikan bisa membantu kita keluar dari kesulitan. Namun ingat, kita harus menggunakan kecerdikan untuk hal yang baik, bukan untuk menipu orang lain.$c$
  where title ilike '%kancil%' and title ilike '%buaya%';

  -- Kura-kura dan Kelinci
  update public.stories set content = $c$Di sebuah hutan yang rindang, hiduplah seekor kelinci yang sangat sombong. Setiap hari ia berlari-lari dan selalu membanggakan kecepatannya.

"Tidak ada yang lebih cepat dariku di hutan ini!" sombong Kelinci.

Suatu hari, Kelinci bertemu dengan Kura-kura yang berjalan pelan. Kelinci pun mengejek.

"Hahaha, Kura-kura! Kamu berjalan sangat lambat. Bahkan siput pun bisa lebih cepat darimu!"

Kura-kura tidak marah. Dengan tenang ia berkata, "Kalau begitu, ayo kita berlomba lari sampai ke pohon besar di ujung hutan."

Semua hewan di hutan berkumpul untuk menyaksikan perlombaan. Ketika dimulai, Kelinci langsung berlari kencang jauh meninggalkan Kura-kura.

Melihat Kura-kura masih jauh di belakang, Kelinci memutuskan untuk beristirahat di bawah pohon rindang. "Aku akan tidur sebentar. Kura-kura tidak akan bisa menyusulku."

Kelinci pun tertidur pulas. Sementara itu, Kura-kura terus berjalan dengan sabar, tidak berhenti, tidak mengeluh, selangkah demi selangkah.

Ketika Kelinci terbangun, ia kaget melihat Kura-kura sudah hampir sampai di garis finish! Kelinci berlari sekencang mungkin, tapi sudah terlambat. Kura-kura menang!

"Selamat, Kura-kura!" seru semua hewan sambil bertepuk tangan.

Kelinci malu dan berjanji tidak akan sombong lagi.

Pesan cerita ini: kesabaran dan ketekunan lebih bermakna daripada bakat tanpa usaha.$c$
  where title ilike '%kura-kura%' and title ilike '%kelinci%';

  -- Semut dan Belalang
  update public.stories set content = $c$Suatu musim panas yang terik, Belalang asyik bermain musik dan bernyanyi seharian. Ia melompat-lompat riang di antara dedaunan hijau.

Tidak jauh dari sana, Semut bekerja keras mengangkut makanan. Walaupun hari sangat panas, Semut tidak berhenti bekerja.

"Hai Semut! Mengapa kamu bekerja terus? Ayo bermain bersamaku!" ajak Belalang.

"Tidak, aku harus mengumpulkan makanan untuk musim dingin nanti," jawab Semut sambil terus berjalan.

Belalang tertawa. "Musim dingin masih lama! Santai saja dulu." Belalang tidak peduli dan terus bernyanyi.

Waktu berlalu. Musim dingin pun tiba. Angin bertiup kencang dan salju turun lebat. Belalang kedinginan dan kelaparan karena tidak punya persediaan makanan.

Dengan susah payah, Belalang pergi mengetuk pintu rumah Semut. "Semut, tolonglah aku. Aku kelaparan dan kedinginan."

Semut membukakan pintu. Ia sudah punya banyak persediaan makanan di dalam rumahnya yang hangat.

"Masuklah, Belalang. Kamu boleh tinggal bersamaku. Tapi mulai sekarang, kita harus sama-sama bekerja ya."

Belalang sangat bersyukur. Ia berjanji tidak akan malas lagi. Mereka pun hidup bersama dengan rukun.

Pesan cerita ini: jangan suka menunda pekerjaan. Rajin bekerja sekarang akan membuat hidup kita lebih baik di kemudian hari.$c$
  where title ilike '%semut%' and title ilike '%belalang%';

  -- Cinderella
  update public.stories set content = $c$Di sebuah kerajaan yang indah, hiduplah seorang gadis baik hati bernama Cinderella. Ia tinggal bersama ibu tiri dan dua saudara tirinya yang sangat jahat dan pemalas.

Cinderella dipaksa mengerjakan semua pekerjaan rumah: memasak, membersihkan, mencuci, dan berbagai pekerjaan berat lainnya. Meski begitu, Cinderella tidak pernah mengeluh.

Suatu hari, datang undangan dari istana: Pangeran akan mengadakan pesta dansa besar-besaran. Ibu tiri dan saudara tirinya bersorak kegirangan.

"Kamu tidak boleh ikut!" bentak ibu tiri kepada Cinderella.

Cinderella sedih. Namun tiba-tiba muncullah peri baik hati. Dengan tongkat ajaibnya, peri mengubah labu menjadi kereta emas, tikus menjadi kuda, dan pakaian lusuh Cinderella menjadi gaun pesta yang indah berkilau, lengkap dengan sepatu kaca yang menawan.

"Ingat, sebelum tengah malam kamu harus pulang. Setelah itu, semua keajaiban ini akan lenyap," pesan sang peri.

Di istana, Pangeran langsung terpesona oleh Cinderella. Mereka menari bersama sepanjang malam. Namun ketika jam mulai berdentang dua belas kali, Cinderella berlari keluar. Sebuah sepatu kacanya tertinggal di tangga istana.

Pangeran mencari gadis itu ke seluruh kerajaan dengan membawa sepatu kaca. Ketika tiba di rumah Cinderella, saudara tirinya gagal memakai sepatu itu. Tapi sepatu kaca itu cocok sempurna di kaki Cinderella.

Cinderella dan Pangeran menikah dan hidup bahagia selamanya. Kebaikan hati Cinderella membawanya ke kehidupan yang indah.$c$
  where title ilike '%cinderella%';

  -- Putri Salju
  update public.stories set content = $c$Di sebuah kerajaan yang diselimuti salju, lahirlah seorang putri cantik dengan kulit seputih salju, bibir semerah mawar, dan rambut sehitam eboni. Sang raja menamainya Putri Salju.

Ketika Putri Salju masih kecil, ibunya meninggal dunia. Raja menikah lagi dengan seorang wanita cantik yang sangat jahat dan sombong.

Ibu tiri memiliki sebuah cermin ajaib. Setiap hari ia bertanya, "Cermin, cermin di dinding, siapakah yang paling cantik di negeri ini?"

Selama bertahun-tahun cermin selalu menjawab, "Engkaulah yang paling cantik, Ratu."

Namun suatu hari, cermin menjawab berbeda: "Putri Saljulah yang paling cantik sekarang."

Ratu murka. Ia memerintahkan pemburu untuk membunuh Putri Salju. Namun pemburu tidak tega dan melepaskannya di hutan.

Putri Salju berlari ke dalam hutan hingga menemukan sebuah gubuk kecil milik tujuh kurcaci. Para kurcaci yang baik hati mengizinkan Putri Salju tinggal bersama mereka.

Namun ratu jahat mengetahui bahwa Putri Salju masih hidup. Ia menyamar menjadi nenek tua dan menawarkan apel merah yang telah diracun. Putri Salju yang polos memakan apel itu dan langsung jatuh tertidur seperti mati.

Para kurcaci bersedih dan meletakkannya dalam peti kaca. Suatu hari, seorang pangeran melewati hutan itu dan melihat Putri Salju. Ketika ia mencium kening Putri Salju, keajaiban terjadi: racun apel hilang dan Putri Salju terbangun.

Pangeran dan Putri Salju menikah dan hidup bahagia. Kebaikan hati Putri Salju telah membawanya kepada kebahagiaan sejati.$c$
  where title ilike '%putri salju%';

  -- Asal Usul Danau Toba
  update public.stories set content = $c$Dahulu kala di tanah Batak, Sumatera Utara, hiduplah seorang pemuda miskin bernama Toba. Setiap hari ia memancing di sungai untuk mencari makan.

Suatu hari, Toba mendapat ikan yang luar biasa indah berwarna emas. Tapi ketika ia ingin memasaknya, ikan itu berubah menjadi seorang gadis cantik.

"Jangan takut. Aku adalah gadis dari dunia ikan. Karena kamu telah menyelamatkanku, aku ingin menjadi istrimu," kata gadis itu.

"Tapi ada satu syarat: jangan pernah ceritakan kepada siapapun bahwa aku berasal dari ikan."

Toba setuju. Mereka pun menikah dan dikaruniai seorang putra bernama Samosir. Mereka hidup bahagia.

Samosir tumbuh menjadi anak yang nakal. Suatu hari ia diminta ibunya mengantarkan makanan untuk ayahnya di ladang. Di tengah jalan, Samosir memakan habis semua bekal itu karena lapar.

Toba yang lapar dan lelah marah besar. Tanpa sadar ia berteriak, "Dasar anak ikan! Sama seperti ibumu!"

Langit pun berubah gelap. Hujan deras turun dengan petir yang menggelegar. Air terus naik menggenangi daratan.

Ibu Samosir berubah kembali menjadi ikan dan masuk ke air. Toba menyesal tapi sudah terlambat.

Samosir berlari ke bukit yang tinggi untuk selamat. Banjir besar itu akhirnya membentuk sebuah danau yang luas dan indah. Di tengahnya terdapat sebuah pulau yang kemudian dinamakan Pulau Samosir, dan danaunya disebut Danau Toba.

Danau Toba kini menjadi salah satu danau terindah di dunia, dan merupakan kebanggaan tanah Batak.$c$
  where title ilike '%danau toba%';

  -- Singa dan Tikus (ada di seed dengan nama ini)
  update public.stories set content = $c$Suatu hari, Singa Raja Hutan sedang tidur siang dengan nyenyak di bawah pohon besar. Tiba-tiba seekor tikus kecil berlari melewati hidungnya dan tanpa sengaja membangunkannya.

Singa mengaum keras dan menangkap si Tikus dengan cakarnya yang besar.

"Ampun, Raja! Jangan makan aku!" pinta Tikus dengan ketakutan. "Suatu hari nanti aku pasti bisa membalas kebaikanmu!"

Singa tertawa terbahak-bahak. Ia merasa lucu mendengar seekor tikus kecil berjanji akan membalas jasanya. Namun karena merasa kasihan, ia melepaskan tikus itu.

"Pergilah, aku tidak lapar hari ini."

Beberapa minggu kemudian, Singa terperangkap dalam jaring yang dipasang oleh para pemburu. Ia mengaum keras meminta tolong, tapi tidak ada yang berani membantu.

Tikus yang mendengar suara itu segera berlari mendekati Singa. Tanpa ragu-ragu, Tikus mulai menggigiti tali-tali jaring itu satu per satu.

Tidak lama kemudian, jaring itu putus dan Singa berhasil bebas. Singa sangat terharu.

"Aku tadi tertawa ketika kamu berjanji akan menolongku. Ternyata seekor tikus kecil pun bisa menjadi pahlawan yang besar. Terima kasih, sahabatku."

Pesan cerita ini: jangan pernah meremehkan siapapun. Pertolongan bisa datang dari mana saja, bahkan dari yang paling lemah sekalipun.$c$
  where title ilike '%singa%' and title ilike '%tikus%';

  -- Burung Gagak yang Haus (ada di seed)
  update public.stories set content = $c$Di musim kemarau yang panjang, seekor Gagak kehausan terbang ke sana ke mari mencari air minum. Tenggorokannya sangat kering dan ia sudah hampir putus asa.

Akhirnya ia menemukan sebuah kendi berisi sedikit air. Tapi paruhnya tidak bisa mencapai air di dalam kendi karena airnya terlalu sedikit dan kendi terlalu dalam.

Gagak tidak putus asa. Ia berpikir keras mencari solusi. Kemudian ia menemukan ide cemerlang: ia mulai mengambil kerikil satu per satu dengan paruhnya dan memasukkannya ke dalam kendi.

Kerikil demi kerikil dimasukkan dengan sabar. Pelan-pelan permukaan air dalam kendi naik. Sedikit demi sedikit, air itu semakin dekat ke mulut kendi.

Akhirnya air itu bisa dijangkau oleh paruh Gagak. Gagak minum sepuasnya dan merasa sangat lega.

Dari cerita ini kita belajar: ketika menghadapi masalah, gunakan akal pikiran untuk mencari solusi. Kesabaran dan ketekunan selalu membuahkan hasil. Jangan menyerah hanya karena masalah terlihat sulit!$c$
  where title ilike '%gagak%';

  -- Tangkuban Perahu (ada di kategori Legenda)
  update public.stories set content = $c$Di tanah Sunda, hiduplah seorang putri cantik bernama Dayang Sumbi. Ia dikaruniai seorang putra bernama Sangkuriang dari seekor anjing sakti bernama Tumang.

Suatu hari Sangkuriang membunuh Tumang karena tidak mendapat hewan buruan. Dayang Sumbi yang marah besar mengusir Sangkuriang dari rumah.

Bertahun-tahun berlalu. Sangkuriang tumbuh dewasa dan berkelana ke berbagai daerah. Suatu hari ia bertemu seorang wanita cantik yang ternyata adalah Dayang Sumbi, ibunya sendiri! Dayang Sumbi awet muda karena karunia dewa.

Sangkuriang ingin menikah dengan Dayang Sumbi. Dayang Sumbi menyadari bahwa pemuda itu adalah anaknya ketika melihat bekas luka di kepalanya. Ia pun mengajukan syarat mustahil: membuat danau dan perahu dalam satu malam.

Sangkuriang hampir berhasil dengan bantuan para makhluk gaib. Namun Dayang Sumbi menyabotase pekerjaan dengan membuat ayam berkokok lebih awal.

Sangkuriang marah besar dan menendang perahu yang hampir selesai. Perahu itu terbalik dan menjadi Gunung Tangkuban Perahu yang terkenal di Jawa Barat.

Gunung Tangkuban Perahu yang berarti "perahu yang terbalik" kini menjadi objek wisata terkenal yang dikunjungi jutaan orang setiap tahunnya.$c$
  where title ilike '%tangkuban%' or title ilike '%tangkuban perahu%';

  -- Putri Mandalika
  update public.stories set content = $c$Di Pulau Lombok, hiduplah seorang putri cantik bernama Putri Mandalika, putri Raja Tonjang Beru. Kecantikan dan kebaikan hatinya terkenal ke seluruh penjuru negeri.

Banyak pangeran dan raja dari berbagai kerajaan datang untuk melamar Putri Mandalika. Di antara mereka adalah Pangeran Dewa Muda, Pangeran Terong Sidare, dan banyak lagi.

Putri Mandalika bingung. Jika ia memilih salah satu, yang lain akan merasa kecewa dan mungkin akan berperang. Ia tidak ingin rakyatnya menderita karena dirinya.

Dengan hati yang berat, Putri Mandalika mengumpulkan semua pelamarnya di tepi pantai. "Aku telah memutuskan. Aku akan memberikan diri untuk kalian semua dan untuk seluruh rakyat," katanya.

Sebelum semua orang memahami maksudnya, Putri Mandalika terjun ke laut dan menghilang. Dari tempat ia terjun, muncullah ribuan cacing berwarna-warni yang disebut Nyale.

Masyarakat Lombok percaya bahwa Nyale adalah jelmaan Putri Mandalika. Setiap tahun, saat musim Nyale tiba, masyarakat Lombok mengadakan Festival Bau Nyale (menangkap Nyale) untuk mengenang pengorbanan Putri Mandalika.

Putri Mandalika mengajarkan kita tentang pengorbanan dan cinta yang tulus kepada sesama.$c$
  where title ilike '%mandalika%';

  -- =====================================================
  -- INSERT cerita baru yang belum ada di database
  -- =====================================================

  -- Lutung Kasarung
  if cat_tradisional is not null then
    insert into public.stories (category_id, title, sort_order, is_premium, content)
    values (cat_tradisional, 'Lutung Kasarung', 15, true, $c$Di Kerajaan Pasundan, hiduplah tujuh orang putri. Putri bungsu bernama Purbasari adalah yang paling baik hati dan bijaksana. Namun kakaknya, Purbararang, sangat iri dan jahat.

Purbararang memfitnah Purbasari kepada ayah mereka. Akibatnya, Purbasari diusir dari istana dan diasingkan ke tengah hutan.

Di hutan, Purbasari bertemu dengan seekor lutung (monyet) hitam yang ternyata bisa berbicara. Lutung itu bernama Guruminda, seorang pangeran dari kahyangan yang sedang dikutuk.

Lutung Kasarung menemani dan melindungi Purbasari di hutan. Ia membantu Purbasari mendapat makanan dan membuatkan tempat tinggal yang nyaman.

Suatu hari, Purbararang mengadakan sayembara: siapapun yang memiliki kolam paling indah akan memenangkan hadiah. Lutung Kasarung membantu Purbasari dengan menciptakan kolam ajaib yang sangat indah.

Purbararang kemudian menantang Purbasari: siapa yang memiliki tunangan paling tampan. Ketika Purbasari menunjuk Lutung Kasarung, terjadi keajaiban. Lutung Kasarung berubah menjadi seorang pangeran muda yang sangat tampan dan berwibawa!

Purbararang akhirnya mengakui kesalahannya. Purbasari yang baik hati memaafkannya. Purbasari dan Guruminda pun menikah dan memerintah kerajaan dengan adil dan bijaksana.$c$)
    on conflict do nothing;
  end if;

  -- Kucing dan Tikus
  if cat_fabel is not null then
    insert into public.stories (category_id, title, sort_order, is_premium, content)
    values (cat_fabel, 'Kucing dan Tikus', 9, false, $c$Dahulu kala, Kucing dan Tikus adalah sahabat baik. Mereka sering bermain bersama dan berbagi makanan.

Suatu musim dingin, keduanya sepakat untuk menyimpan makanan bersama di dalam sebuah panci lemak untuk dimakan saat musim dingin tiba. Panci itu mereka sembunyikan di tempat yang aman.

Namun Kucing tidak sabar dan tidak jujur. Ia sering diam-diam pergi mengambil makanan sendirian dengan berbagai alasan.

Pertama kali ia berkata kepada Tikus, "Aku diundang menjadi ayah baptis anak kucing tetangga." Padahal ia diam-diam pergi makan sepertiga panci lemak itu sendirian.

Beberapa hari kemudian Kucing berbohong lagi dengan alasan yang sama. Kali ini ia menghabiskan setengah lemak yang tersisa.

Tidak lama kemudian, Kucing pergi lagi dan menghabiskan seluruh lemak di dalam panci.

Ketika musim dingin tiba, Tikus mengajak Kucing mengambil makanan mereka. Namun ketika mereka membuka tempat penyimpanan, persediaan itu sudah kosong!

Tikus baru menyadari bahwa selama ini ia telah ditipu. Ia tidak mau berteman dengan Kucing lagi.

Pesan cerita ini: persahabatan yang dibangun di atas kebohongan tidak akan bertahan lama. Kejujuran adalah dasar dari setiap hubungan yang baik.$c$)
    on conflict do nothing;
  end if;

  -- Si Cantik dan Si Buas
  if cat_dunia is not null then
    insert into public.stories (category_id, title, sort_order, is_premium, content)
    values (cat_dunia, 'Si Cantik dan Si Buas', 7, true, $c$Di sebuah kota kecil, hiduplah seorang pedagang dengan tiga putrinya. Putri bungsunya bernama Belle, dikenal karena kecantikan dan kecintaannya pada buku.

Suatu hari sang ayah tersesat di hutan dan menemukan sebuah istana besar yang misterius. Ketika hendak pulang, ia memetik mawar untuk Belle. Tiba-tiba muncullah makhluk menakutkan bertubuh besar dan berbulu.

"Berani kamu mencuri mawarku! Sekarang kamu harus mati atau menyerahkan seorang putrimu untuk tinggal bersamaku!" bentak Si Buas.

Belle yang mendengar cerita ayahnya bersedia mengorbankan dirinya demi menyelamatkan sang ayah. Ia pergi ke istana Si Buas.

Awalnya Belle sangat takut dengan penampilan Si Buas yang mengerikan. Namun lama-kelamaan ia menyadari bahwa Si Buas sebenarnya baik hati, cerdas, dan lembut.

Mereka banyak menghabiskan waktu bersama: membaca buku, makan malam, dan berjalan di taman. Belle mulai melupakan rupa Si Buas dan melihat hatinya yang baik.

Suatu hari, Belle mendapat kabar bahwa ayahnya sakit keras. Si Buas mengizinkan Belle pulang, meski hatinya sangat sedih.

Belle segera berlari kembali ke istana setelah melihat dalam cermin ajaib bahwa Si Buas sekarat karena patah hati. Di sisi Si Buas yang terbaring lemah, Belle berkata, "Aku mencintaimu."

Seketika itu, Si Buas berubah menjadi seorang pangeran tampan. Kutukan yang selama ini membebaninya akhirnya terpatahkan oleh cinta yang tulus.

Cerita ini mengajarkan kita bahwa keindahan sejati ada di dalam hati, bukan pada penampilan luar.$c$)
    on conflict do nothing;
  end if;

end $$;
