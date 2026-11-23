-- =====================================================
-- Migration 008: Isi 35 dongeng (teks ramah anak, pesan moral, kuis,
-- pertanyaan ngobrol, kata baru) + pertanyaan ngobrol & kata baru Malin Kundang.
-- Jalankan di Supabase SQL Editor SETELAH 007. Aman dijalankan ulang.
-- Beberapa judul lama yang masih berupa nama kategori diganti cerita sungguhan
-- (mis. "Mitologi Yunani" -> "Raja Midas dan Sentuhan Emas").
-- Gambar sampul & halaman belum ada; bisa diisi nanti lewat kolom cover_url & page_images.
-- =====================================================


-- Dongeng tradisional: Timun Mas
update public.stories set
  title = $t$Timun Mas$t$,
  content = $c$Dahulu kala, di sebuah desa di tepi hutan, hiduplah Mbok Sirni. Ia tinggal sendirian dan sangat ingin punya seorang anak.

Suatu hari, datanglah raksasa hijau bernama Buto Ijo. "Tanamlah biji timun ini," katanya, "kelak kau akan punya anak."

"Tapi saat anak itu besar, aku akan menjemputnya," lanjut Buto Ijo. Mbok Sirni ketakutan, tetapi ia menerima biji itu.

Biji itu tumbuh menjadi timun emas yang besar. Saat dibelah, di dalamnya ada bayi perempuan yang mungil dan cantik.

Mbok Sirni menamainya Timun Mas. Timun Mas tumbuh menjadi anak yang rajin, baik hati, dan sangat sayang kepada ibunya.

Suatu hari, tanah bergetar. Buto Ijo datang menagih janji! Mbok Sirni memberi Timun Mas empat bungkusan kecil.

"Isinya biji timun, jarum, garam, dan terasi. Larilah, Nak, dan lemparkan satu per satu bila raksasa mendekat," bisik Mbok Sirni.

Timun Mas berlari secepat kilat. Saat Buto Ijo hampir menangkapnya, ia melempar biji timun. Tumbuhlah ladang timun yang lebat!

Buto Ijo malah sibuk makan timun. Lalu ia mengejar lagi. Timun Mas melempar jarum, dan muncullah hutan bambu yang rapat.

Raksasa itu berhasil keluar dari hutan bambu. Timun Mas melempar garam, dan tiba-tiba terbentang laut yang luas.

Buto Ijo berenang menyeberangi laut. Terakhir, Timun Mas melempar terasi. Jadilah lautan lumpur yang lengket dan dalam.

Buto Ijo terjebak dalam lumpur dan tidak bisa mengejar lagi. Sejak hari itu, raksasa itu tidak pernah kembali.

Timun Mas pulang dan memeluk ibunya erat-erat. Mereka hidup bahagia, saling menyayangi, dan saling menjaga selamanya.$c$,
  moral = $m$Jangan mudah menyerah. Dengan berani, cerdik, dan mendengar nasihat orang tua, kita bisa melewati masalah yang sulit.$m$,
  quiz = $q$[{"question": "Timun Mas keluar dari mana?", "options": ["Dari bunga mawar", "Dari telur ayam", "Dari timun emas"], "answer": 2}, {"question": "Apa yang dilempar Timun Mas pertama kali?", "options": ["Biji timun", "Terasi", "Garam"], "answer": 0}, {"question": "Apa yang membuat Buto Ijo berhenti mengejar?", "options": ["Hutan bambu", "Laut yang luas", "Lautan lumpur"], "answer": 2}]$q$::jsonb,
  prompts = $p$[{"page": 5, "text": "Menurutmu, bagaimana perasaan Timun Mas saat Buto Ijo datang?"}, {"page": 7, "text": "Coba tebak, kalau jarum yang dilempar, kira-kira akan muncul apa?"}, {"page": 12, "text": "Kalau kamu jadi Timun Mas, bungkusan mana yang paling kamu suka? Kenapa?"}]$p$::jsonb,
  vocab = $v$[{"word": "menagih", "meaning": "meminta sesuatu yang sudah dijanjikan"}, {"word": "terasi", "meaning": "bumbu masak dari udang kecil yang baunya tajam"}]$v$::jsonb
where id = '2ef163d3-4133-41ea-a9fd-1b0cbf8aa046';

-- Dongeng tradisional: Legenda Jaka Tarub
update public.stories set
  title = $t$Legenda Jaka Tarub$t$,
  content = $c$Dahulu kala, di sebuah desa di Jawa, hiduplah pemuda baik hati bernama Jaka Tarub. Ia suka berjalan-jalan di hutan.

Suatu sore, ia mendengar tawa riang dari sebuah telaga. Ternyata ada tujuh bidadari dari kahyangan sedang bermain air.

Di atas batu, tergeletak selendang-selendang yang berkilauan. Jaka Tarub penasaran dan menyimpan satu selendang di balik semak.

Hari mulai gelap. Enam bidadari memakai selendangnya dan terbang pulang. Tinggallah satu bidadari, Nawang Wulan, yang kebingungan mencari selendangnya.

Tanpa selendang, Nawang Wulan tidak bisa terbang kembali ke kahyangan. Jaka Tarub pun menawarkan diri untuk menolongnya.

Lama-kelamaan mereka saling menyayangi dan menikah. Mereka dikaruniai seorang putri cantik bernama Nawangsih.

Nawang Wulan punya kesaktian. Ia bisa memasak nasi untuk sekeluarga hanya dari sebutir padi. Tetapi ada satu pesannya.

"Kakanda, jangan pernah membuka tutup periuk saat aku memasak, ya," pesan Nawang Wulan. Jaka Tarub berjanji.

Suatu hari, Jaka Tarub sangat penasaran. Ia mengintip ke dalam periuk dan melihat hanya ada sebutir padi di sana.

Sejak saat itu, kesaktian Nawang Wulan hilang. Ia harus menumbuk padi setiap hari, sehingga lumbung padi makin kosong.

Di dasar lumbung yang kosong, Nawang Wulan menemukan selendangnya yang dulu hilang. Kini ia tahu siapa yang menyimpannya.

Dengan sedih, Nawang Wulan memakai selendangnya. "Aku harus pulang ke kahyangan. Jagalah Nawangsih baik-baik," katanya.

Nawang Wulan terbang ke langit. Namun setiap malam ia turun diam-diam untuk menemani Nawangsih dan menyanyikan lagu untuknya.

Jaka Tarub menyesal. Ia belajar bahwa janji harus ditepati dan kejujuran sangat berharga. Ia merawat Nawangsih dengan penuh kasih.$c$,
  moral = $m$Tepatilah janji dan bersikaplah jujur, karena kepercayaan orang lain sangat berharga.$m$,
  quiz = $q$[{"question": "Berapa bidadari yang bermain di telaga?", "options": ["Lima", "Tujuh", "Sepuluh"], "answer": 1}, {"question": "Apa pesan Nawang Wulan kepada Jaka Tarub?", "options": ["Jangan membuka tutup periuk", "Jangan pergi ke hutan", "Jangan tidur siang"], "answer": 0}, {"question": "Di mana Nawang Wulan menemukan selendangnya?", "options": ["Di atas pohon", "Di dasar lumbung padi", "Di dalam sungai"], "answer": 1}]$q$::jsonb,
  prompts = $p$[{"page": 2, "text": "Menurutmu, bolehkah kita menyimpan barang milik orang lain? Kenapa?"}, {"page": 8, "text": "Kalau kamu sudah berjanji, apa yang sebaiknya kamu lakukan?"}, {"page": 12, "text": "Bagaimana ya perasaan Nawangsih saat ibunya datang setiap malam?"}]$p$::jsonb,
  vocab = $v$[{"word": "kahyangan", "meaning": "tempat tinggal para dewa dan bidadari di langit"}, {"word": "periuk", "meaning": "panci dari tanah liat untuk memasak nasi"}, {"word": "lumbung", "meaning": "bangunan untuk menyimpan padi"}]$v$::jsonb
where id = '2a8faa13-ca78-4c07-b665-32086734e013';

-- Dongeng tradisional: Keong Mas (dulu: Putri Sambaria)
update public.stories set
  title = $t$Keong Mas$t$,
  content = $c$Dahulu kala, di Kerajaan Daha, hiduplah dua putri raja, Candra Kirana dan Dewi Galuh. Candra Kirana sangat baik hati.

Candra Kirana bertunangan dengan Raden Inu Kertapati, pangeran yang gagah dan bijaksana. Dewi Galuh merasa iri.

Dewi Galuh meminta bantuan seorang penyihir. Dengan mantra, penyihir itu mengubah Candra Kirana menjadi seekor keong berwarna emas.

Keong emas itu terbawa arus sungai sampai ke sebuah desa. Di sana, seorang nenek pencari ikan menemukannya di dalam jalanya.

"Cantik sekali keong ini," kata Nenek. Ia membawanya pulang dan menaruhnya di dalam tempayan berisi air.

Keesokan harinya, Nenek pulang dari sungai. Ia heran, di meja sudah tersedia makanan lezat dan rumahnya bersih sekali.

Hal itu terjadi setiap hari. Nenek pun mengintip diam-diam. Ternyata keong emas berubah menjadi putri cantik yang sedang memasak!

"Siapakah kamu, Nak?" tanya Nenek lembut. Candra Kirana menceritakan semuanya. Sejak itu, mereka tinggal bersama dan saling menyayangi.

Sementara itu, Raden Inu Kertapati terus mencari Candra Kirana. Ia berjalan jauh melewati hutan, gunung, dan banyak desa.

Suatu hari, Raden Inu singgah di rumah Nenek karena haus. Ia mencicipi masakan di sana dan merasa sangat mengenal rasanya.

"Ini masakan Candra Kirana!" serunya. Saat itu juga, Candra Kirana keluar dari dapur. Mantra penyihir pun hilang untuk selamanya.

Raden Inu membawa Candra Kirana dan Nenek ke istana. Dewi Galuh menyesal dan meminta maaf atas perbuatannya.

Candra Kirana memaafkan adiknya. Ia dan Raden Inu menikah, dan semua orang di kerajaan hidup bahagia.$c$,
  moral = $m$Jangan iri hati kepada orang lain, dan tetaplah berbuat baik seperti Candra Kirana.$m$,
  quiz = $q$[{"question": "Candra Kirana diubah menjadi apa?", "options": ["Burung kecil", "Keong emas", "Ikan merah"], "answer": 1}, {"question": "Siapa yang menemukan keong emas?", "options": ["Anak gembala", "Seorang raja", "Nenek pencari ikan"], "answer": 2}, {"question": "Bagaimana Raden Inu mengenali Candra Kirana?", "options": ["Dari rasa masakannya", "Dari suaranya", "Dari bajunya"], "answer": 0}]$q$::jsonb,
  prompts = $p$[{"page": 2, "text": "Kenapa ya Dewi Galuh merasa iri? Pernahkah kamu merasa iri?"}, {"page": 5, "text": "Coba tebak, siapa yang memasak di rumah Nenek?"}, {"page": 12, "text": "Kalau ada yang berbuat salah lalu minta maaf, apa yang sebaiknya kita lakukan?"}]$p$::jsonb,
  vocab = $v$[{"word": "mantra", "meaning": "kata-kata yang dipercaya punya kekuatan ajaib"}, {"word": "tempayan", "meaning": "tempat air besar dari tanah liat"}, {"word": "singgah", "meaning": "mampir sebentar"}]$v$::jsonb
where id = '94862ce7-b0cd-40fc-ba03-48abedbbc590';

-- Dongeng tradisional: Bawang Merah Bawang Putih
update public.stories set
  title = $t$Bawang Merah Bawang Putih$t$,
  content = $c$Di sebuah desa, hiduplah Bawang Putih bersama ibu tiri dan saudara tirinya, Bawang Merah. Ayah Bawang Putih sudah lama tiada.

Bawang Putih rajin dan baik hati. Setiap hari ia memasak, menyapu, dan mencuci. Sementara itu, Bawang Merah hanya bermalas-malasan.

Suatu pagi, Bawang Putih mencuci baju di sungai. Tanpa sengaja, selendang kesayangan ibu tirinya hanyut terbawa arus.

"Cari sampai dapat!" bentak ibu tirinya. Bawang Putih pun menyusuri sungai sambil bertanya kepada siapa saja yang ia temui.

Sampai di hilir, ia bertemu seorang nenek di depan sebuah gubuk. "Nek, apakah Nenek melihat selendang merah?" tanya Bawang Putih sopan.

"Nenek menyimpannya. Tapi maukah kamu membantu Nenek bersih-bersih dulu?" Bawang Putih mengangguk dan bekerja dengan senang hati.

Setelah selesai, Nenek memberikan selendang itu. "Pilihlah hadiah, labu kecil atau labu besar," kata Nenek. Bawang Putih memilih labu kecil.

Di rumah, labu kecil itu dibelah. Wah, isinya emas dan permata yang berkilauan! Ibu tiri dan Bawang Merah terbelalak.

Keesokan harinya, Bawang Merah sengaja menghanyutkan selendang dan pergi ke gubuk Nenek. Tetapi ia malas dan tidak mau membantu.

Bawang Merah langsung memilih labu yang besar. Ia membawanya pulang dengan tergesa-gesa karena ingin mendapat emas yang lebih banyak.

Saat dibelah, labu besar itu berisi lumpur dan katak yang melompat ke sana kemari! Bawang Merah dan ibunya lari terbirit-birit.

Akhirnya mereka sadar telah berbuat salah. Mereka meminta maaf kepada Bawang Putih, dan Bawang Putih memaafkan mereka dengan tulus.

Sejak hari itu, mereka bekerja bersama-sama di rumah. Keluarga itu pun hidup rukun dan bahagia.$c$,
  moral = $m$Kebaikan dan kerja keras selalu berbuah manis, sedangkan sifat malas dan serakah merugikan diri sendiri.$m$,
  quiz = $q$[{"question": "Apa yang hanyut di sungai?", "options": ["Keranjang", "Sepatu", "Selendang"], "answer": 2}, {"question": "Labu mana yang dipilih Bawang Putih?", "options": ["Tidak memilih", "Labu besar", "Labu kecil"], "answer": 2}, {"question": "Apa isi labu besar milik Bawang Merah?", "options": ["Lumpur dan katak", "Emas dan permata", "Kue dan roti"], "answer": 0}]$q$::jsonb,
  prompts = $p$[{"page": 5, "text": "Kenapa ya Bawang Putih mau membantu Nenek?"}, {"page": 9, "text": "Menurutmu, kenapa Bawang Merah memilih labu yang besar?"}, {"page": 12, "text": "Apa yang bisa kamu bantu di rumah hari ini?"}]$p$::jsonb,
  vocab = $v$[{"word": "hilir", "meaning": "bagian sungai yang mengalir ke arah laut"}, {"word": "gubuk", "meaning": "rumah kecil yang sederhana"}, {"word": "terbelalak", "meaning": "membuka mata lebar-lebar karena kaget"}]$v$::jsonb
where id = 'ba4591fb-d6b4-44ad-9f63-1653ad003c31';

-- Dongeng tradisional: Si Kancil dan Buaya
update public.stories set
  title = $t$Si Kancil dan Buaya$t$,
  content = $c$Di sebuah hutan, hiduplah Kancil yang kecil tetapi sangat cerdik. Suatu hari, perutnya keroncongan karena lapar sekali.

Di seberang sungai, Kancil melihat pohon-pohon penuh buah ranum. "Hmm, lezat sekali kelihatannya," katanya sambil menelan ludah.

Tetapi sungai itu lebar dan dalam. Di dalamnya banyak buaya yang lapar sedang menunggu mangsa.

Kancil berpikir keras. Lalu ia berseru, "Hai, para Buaya! Raja Hutan mengundang kalian ke pesta besar!"

Buaya-buaya muncul satu per satu. "Pesta? Benarkah?" tanya pemimpin Buaya. "Benar," jawab Kancil, "tapi aku harus menghitung kalian dulu."

"Berbarislah dari sini sampai ke seberang sungai, supaya mudah kuhitung," kata Kancil. Para buaya pun berbaris rapi.

Kancil melompat ke punggung buaya pertama. "Satu!" Lalu ke punggung berikutnya. "Dua! Tiga! Empat!"

Kancil terus melompat dan berhitung sampai ia tiba di seberang sungai. "Sepuluh!" serunya sambil melompat ke tanah.

"Mana pestanya?" tanya para buaya. Kancil tersenyum. "Maaf ya, sebenarnya tidak ada pesta. Aku hanya ingin menyeberang."

Para buaya kesal sekali karena tertipu. Mereka memukul-mukulkan ekornya ke air, tetapi Kancil sudah jauh.

Kancil makan buah sampai kenyang. Namun ia mulai berpikir, "Menipu itu tidak baik. Buaya pasti sedih."

Esok harinya, Kancil kembali ke tepi sungai dan meminta maaf. Para buaya memaafkannya, asalkan Kancil tidak mengulanginya lagi.

Sejak hari itu, Kancil memakai kecerdikannya untuk menolong teman-temannya di hutan.$c$,
  moral = $m$Kecerdikan sebaiknya dipakai untuk kebaikan, dan kalau berbuat salah kita harus berani meminta maaf.$m$,
  quiz = $q$[{"question": "Kenapa Kancil ingin menyeberang sungai?", "options": ["Ingin bermain", "Ingin makan buah", "Ingin mandi"], "answer": 1}, {"question": "Kenapa Kancil meminta buaya berbaris?", "options": ["Supaya bisa difoto", "Supaya bisa dihitung", "Supaya bisa menari"], "answer": 1}, {"question": "Apa yang dilakukan Kancil keesokan harinya?", "options": ["Menipu lagi", "Meminta maaf kepada buaya", "Pindah rumah"], "answer": 1}]$q$::jsonb,
  prompts = $p$[{"page": 3, "text": "Menurutmu, apa rencana Kancil?"}, {"page": 6, "text": "Ayo berhitung bersama Kancil: satu, dua, tiga... sampai sepuluh!"}, {"page": 10, "text": "Apakah menipu itu baik? Kenapa?"}]$p$::jsonb,
  vocab = $v$[{"word": "keroncongan", "meaning": "bunyi perut saat lapar"}, {"word": "ranum", "meaning": "sudah matang dan siap dimakan"}, {"word": "mangsa", "meaning": "hewan yang diburu untuk dimakan"}]$v$::jsonb
where id = 'e4f7546d-7336-49d9-a809-f13c91dec2c5';

-- Dongeng tradisional: Sangkuriang
update public.stories set
  title = $t$Sangkuriang$t$,
  content = $c$Di tanah Sunda, hiduplah seorang putri cantik bernama Dayang Sumbi. Ia tinggal bersama putranya, Sangkuriang, dan anjing setia bernama Tumang.

Sangkuriang suka berburu ke hutan bersama Tumang. Suatu hari, mereka tidak mendapat seekor hewan buruan pun.

Sangkuriang kesal dan memarahi Tumang, lalu mengusirnya. Tumang pergi jauh ke dalam hutan dan tidak pernah kembali.

Dayang Sumbi sangat sedih mendengarnya. Saat menegur Sangkuriang, centong nasi di tangannya tanpa sengaja mengenai kepala anaknya hingga berbekas.

Sangkuriang merasa malu dan pergi mengembara. Bertahun-tahun ia berkelana dan tumbuh menjadi pemuda yang kuat dan sakti.

Suatu hari, ia tiba di sebuah desa dan bertemu wanita yang sangat cantik. Sangkuriang tidak tahu bahwa wanita itu adalah Dayang Sumbi.

Dayang Sumbi tetap awet muda karena anugerah para dewa. Sangkuriang ingin menikahinya, tetapi Dayang Sumbi melihat bekas luka di kepalanya.

"Ia anakku, Sangkuriang!" pikir Dayang Sumbi. Agar Sangkuriang membatalkan niatnya, ia memberi syarat yang sangat sulit.

"Buatlah danau dan perahu besar dalam satu malam, sebelum ayam berkokok," kata Dayang Sumbi. Sangkuriang langsung menyanggupinya.

Dengan kesaktiannya, Sangkuriang membendung sungai dan menebang pohon besar. Menjelang pagi, danau dan perahu itu hampir selesai.

Dayang Sumbi cemas. Ia membentangkan kain merah di timur dan menumbuk padi. Ayam-ayam mengira pagi tiba dan berkokok.

Sangkuriang kecewa karena pekerjaannya belum selesai. Dengan kesal, ia menendang perahu besar itu hingga terbalik.

Perahu yang terbalik itu menjadi sebuah gunung. Orang menyebutnya Gunung Tangkuban Perahu, yang masih bisa kita lihat di Jawa Barat.$c$,
  moral = $m$Belajarlah menahan marah, karena keputusan yang diambil saat marah sering membuat kita menyesal.$m$,
  quiz = $q$[{"question": "Siapa nama anjing setia Dayang Sumbi?", "options": ["Belang", "Tumang", "Si Putih"], "answer": 1}, {"question": "Apa syarat yang diminta Dayang Sumbi?", "options": ["Menangkap seribu ikan", "Membuat danau dan perahu dalam satu malam", "Membuat rumah dari emas"], "answer": 1}, {"question": "Perahu yang terbalik menjadi apa?", "options": ["Pulau", "Gunung Tangkuban Perahu", "Sungai"], "answer": 1}]$q$::jsonb,
  prompts = $p$[{"page": 2, "text": "Apa yang bisa dilakukan Sangkuriang supaya tidak marah-marah?"}, {"page": 10, "text": "Kenapa ya ayam-ayam berkokok padahal belum pagi?"}, {"page": 12, "text": "Pernahkah kamu melihat gunung? Bentuknya seperti apa?"}]$p$::jsonb,
  vocab = $v$[{"word": "mengembara", "meaning": "pergi jauh ke banyak tempat"}, {"word": "berkokok", "meaning": "bunyi ayam jantan di pagi hari"}, {"word": "membendung", "meaning": "menahan aliran air sungai"}]$v$::jsonb
where id = 'a8096171-e817-48e3-a901-1cbe4b58ddcb';

-- Dongeng tradisional: Roro Jonggrang
update public.stories set
  title = $t$Roro Jonggrang$t$,
  content = $c$Dahulu kala, di Kerajaan Prambanan, hiduplah putri cantik bernama Roro Jonggrang. Ayahnya adalah Prabu Baka, raja yang bertubuh besar.

Suatu hari, pasukan Bandung Bondowoso dari Kerajaan Pengging datang menyerang. Prabu Baka kalah, dan Prambanan dikuasai Bandung Bondowoso.

Bandung Bondowoso melihat Roro Jonggrang dan ingin menikahinya. Roro Jonggrang tidak mau, tetapi ia takut menolak secara langsung.

"Aku mau menikah denganmu," kata Roro Jonggrang, "asalkan kamu membangun seribu candi dalam satu malam." Ia mengira itu mustahil.

Bandung Bondowoso menyanggupinya. Malam itu juga, ia memanggil makhluk-makhluk halus untuk membantu menyusun batu menjadi candi.

Candi demi candi berdiri dengan cepat. Lewat tengah malam, sudah ada sembilan ratus candi. Roro Jonggrang mulai cemas.

Ia membangunkan para gadis desa. "Ayo menumbuk padi dan nyalakan api di sebelah timur!" pintanya.

Suara lesung bertalu-talu dan langit timur tampak merah. Ayam-ayam jantan berkokok, dan makhluk halus lari karena mengira pagi telah tiba.

Saat matahari terbit, candi baru berjumlah sembilan ratus sembilan puluh sembilan. Kurang satu lagi!

Bandung Bondowoso tahu ia telah diperdaya. "Kamu curang, Roro Jonggrang!" serunya dengan marah.

Dengan kesaktiannya, ia mengubah Roro Jonggrang menjadi patung batu untuk melengkapi candi yang keseribu.

Sampai sekarang, patung itu masih bisa kita lihat di Candi Prambanan, dekat Yogyakarta. Orang menyebutnya Arca Roro Jonggrang.$c$,
  moral = $m$Berkatalah jujur, dan jangan memaksakan kehendak kepada orang lain.$m$,
  quiz = $q$[{"question": "Berapa candi yang diminta Roro Jonggrang?", "options": ["Sepuluh", "Seratus", "Seribu"], "answer": 2}, {"question": "Apa yang dilakukan para gadis desa?", "options": ["Menumbuk padi", "Bernyanyi", "Menari"], "answer": 0}, {"question": "Roro Jonggrang diubah menjadi apa?", "options": ["Pohon", "Burung", "Patung batu"], "answer": 2}]$q$::jsonb,
  prompts = $p$[{"page": 3, "text": "Menurutmu, kenapa Roro Jonggrang memberi syarat yang sulit?"}, {"page": 8, "text": "Candinya kurang berapa lagi ya?"}, {"page": 11, "text": "Kalau tidak setuju dengan sesuatu, bagaimana cara mengatakannya dengan baik?"}]$p$::jsonb,
  vocab = $v$[{"word": "candi", "meaning": "bangunan batu kuno untuk beribadah"}, {"word": "lesung", "meaning": "alat dari kayu untuk menumbuk padi"}, {"word": "diperdaya", "meaning": "dibohongi atau ditipu"}]$v$::jsonb
where id = '82a80a9a-238b-4e5d-b68b-bec2b2da2552';

-- Fabel: Kancil dan Siput (dulu: Fabel Nusantara)
update public.stories set
  title = $t$Kancil dan Siput$t$,
  content = $c$Di tepi sungai, Kancil sedang berjalan-jalan sambil bernyanyi. "Akulah hewan paling cerdik dan paling cepat di hutan ini!" katanya bangga.

Di atas daun, Siput mendengarnya. "Kancil, jangan sombong. Bagaimana kalau kita lomba lari?" kata Siput pelan.

Kancil tertawa terbahak-bahak. "Kamu? Lomba lari denganku? Baiklah! Kita lomba besok pagi, menyusuri tepi sungai sampai ke pohon beringin."

Malam itu, Siput mengumpulkan teman-temannya. "Berjajarlah di sepanjang tepi sungai. Kalau Kancil memanggil, jawablah dari depannya," pesan Siput.

Pagi pun tiba. "Satu, dua, tiga, mulai!" Kancil berlari kencang. Siput tetap diam di tempatnya.

Setelah berlari agak jauh, Kancil berhenti. "Siput, di mana kamu?" serunya sambil tertawa. "Aku di sini!" jawab suara di depannya.

Kancil kaget dan berlari lebih kencang. "Siput, di mana kamu?" tanyanya lagi. "Aku di sini!" jawab seekor siput di depannya.

Begitu terus berulang kali. Kancil berlari sampai napasnya terengah-engah dan kakinya pegal.

Akhirnya Kancil tiba di pohon beringin. Ternyata seekor siput sudah menunggunya di sana sambil tersenyum.

"Wah, kamu menang, Siput," kata Kancil malu. "Maafkan aku karena sudah sombong."

Siput tertawa kecil. "Kami menang karena bekerja sama. Setiap hewan punya kelebihan masing-masing, Kancil."

Sejak hari itu, Kancil tidak lagi menyombongkan diri. Ia malah sering bermain bersama Siput dan teman-temannya.$c$,
  moral = $m$Jangan sombong, karena setiap orang punya kelebihan, dan bersama-sama kita bisa melakukan hal yang hebat.$m$,
  quiz = $q$[{"question": "Kancil menyombongkan diri sebagai hewan yang paling apa?", "options": ["Paling besar", "Paling tinggi", "Paling cepat"], "answer": 2}, {"question": "Bagaimana Siput bisa menang?", "options": ["Teman-teman siput berjajar di tepi sungai", "Kancil tertidur", "Siput naik burung"], "answer": 0}, {"question": "Di mana garis akhir lomba?", "options": ["Di rumah Kancil", "Di pohon beringin", "Di batu besar"], "answer": 1}]$q$::jsonb,
  prompts = $p$[{"page": 3, "text": "Coba tebak, apa rencana Siput dan teman-temannya?"}, {"page": 7, "text": "Bagaimana ya perasaan Kancil saat terus mendengar \"Aku di sini!\"?"}, {"page": 10, "text": "Apa kelebihanmu? Apa kelebihan temanmu?"}]$p$::jsonb,
  vocab = $v$[{"word": "sombong", "meaning": "merasa diri paling hebat"}, {"word": "beringin", "meaning": "pohon besar yang rindang dengan akar menggantung"}, {"word": "terengah-engah", "meaning": "bernapas cepat karena lelah"}]$v$::jsonb
where id = 'e8c13be8-e20e-493c-a703-a2c37c12df05';

-- Fabel: Ayo Jadi Anak Baik!
update public.stories set
  title = $t$Ayo Jadi Anak Baik!$t$,
  content = $c$Di Hutan Ceria, tinggallah kelinci kecil bernama Kiko. Kiko lucu dan lincah, tetapi ia belum terbiasa berkata baik.

Suatu pagi, Kiko ingin bermain ayunan. Tupai sedang memakainya. "Minggir! Aku mau main!" teriak Kiko. Tupai pun pergi dengan sedih.

Siangnya, Kiko tidak sengaja menginjak ekor Rusa. Kiko langsung berlari pergi tanpa berkata apa-apa. Rusa mengusap ekornya yang sakit.

Sorenya, Bebek memberi Kiko sebuah wortel manis. Kiko langsung memakannya dan pergi begitu saja. Bebek hanya terdiam.

Malamnya, Kiko merasa kesepian. "Kenapa teman-teman tidak mau bermain denganku?" tanyanya kepada Bu Burung Hantu yang bijak.

Bu Burung Hantu tersenyum. "Kiko, ada tiga kata ajaib yang bisa membuat teman-temanmu senang. Tolong, maaf, dan terima kasih."

"Kalau ingin meminta sesuatu, ucapkan tolong. Kalau berbuat salah, ucapkan maaf. Kalau diberi sesuatu, ucapkan terima kasih," lanjutnya.

Keesokan harinya, Kiko menemui Tupai. "Tupai, maaf ya kemarin aku kasar. Tolong, boleh aku ikut bermain ayunan?"

Tupai tersenyum lebar. "Tentu boleh, Kiko! Ayo kita main bergantian." Mereka pun tertawa bersama.

Kiko juga menemui Rusa dan meminta maaf. Lalu ia berkata kepada Bebek, "Terima kasih untuk wortelnya, Bebek. Manis sekali!"

Sejak hari itu, teman-teman Kiko bertambah banyak. Hutan Ceria terasa makin ceria karena semua saling menghargai.

Bagaimana denganmu? Sudahkah kamu mengucapkan tolong, maaf, dan terima kasih hari ini?$c$,
  moral = $m$Ucapkan tolong, maaf, dan terima kasih, supaya teman-teman senang bermain bersama kita.$m$,
  quiz = $q$[{"question": "Siapa yang sedang memakai ayunan?", "options": ["Rusa", "Tupai", "Bebek"], "answer": 1}, {"question": "Apa tiga kata ajaib dari Bu Burung Hantu?", "options": ["Halo, dah, ayo", "Tolong, maaf, terima kasih", "Makan, minum, tidur"], "answer": 1}, {"question": "Apa yang Kiko katakan kepada Bebek?", "options": ["Aku mau lagi!", "Terima kasih untuk wortelnya", "Minggir!"], "answer": 1}]$q$::jsonb,
  prompts = $p$[{"page": 1, "text": "Menurutmu, bagaimana perasaan Tupai saat Kiko berteriak?"}, {"page": 3, "text": "Kalau kamu diberi hadiah, apa yang sebaiknya kamu ucapkan?"}, {"page": 11, "text": "Ayo ucapkan bersama: tolong, maaf, terima kasih!"}]$p$::jsonb,
  vocab = $v$[{"word": "bijak", "meaning": "pandai dan baik dalam memberi nasihat"}, {"word": "bergantian", "meaning": "satu per satu sesuai giliran"}, {"word": "menghargai", "meaning": "memperlakukan orang lain dengan baik"}]$v$::jsonb
where id = 'f154e473-3b0d-4800-b4d4-b12aebab8cb7';

-- Fabel: Guru Baru untuk Kelinci (dulu: Guru Baru Untuk Kelinci)
update public.stories set
  title = $t$Guru Baru untuk Kelinci$t$,
  content = $c$Di Sekolah Hutan, ada murid yang paling cepat. Namanya Lili si Kelinci. Ia cepat berlari, cepat bicara, dan cepat bosan.

Setiap mengerjakan tugas, Lili ingin cepat selesai. Gambarnya sering belum diwarnai, dan tulisannya sering belum rapi.

Suatu hari, datanglah guru baru. Ia adalah Bu Kura-kura. Langkahnya pelan, suaranya lembut, dan senyumnya hangat.

"Aduh, guru baru kita lambat sekali," bisik Lili kepada Tupai. "Pasti pelajarannya membosankan."

Bu Kura-kura membagikan biji wortel. "Hari ini kita akan berkebun. Tanamlah bijinya, lalu siramlah setiap hari," katanya.

Lili menanam bijinya dengan cepat. Keesokan harinya ia menggali tanah. "Kok wortelnya belum ada?" keluhnya kecewa.

Bu Kura-kura tertawa kecil. "Sabar, Lili. Biji perlu waktu untuk tumbuh. Kalau digali terus, bijinya tidak bisa bertunas."

Lili menanam biji yang baru. Kali ini ia menyiramnya setiap pagi dan menunggu dengan sabar, walaupun rasanya lama sekali.

Beberapa hari kemudian, muncullah tunas hijau kecil. "Bu Guru, lihat! Tunasku tumbuh!" seru Lili gembira.

Minggu demi minggu, daunnya makin lebat. Lili juga mulai sabar saat menggambar, mewarnai, dan menulis dengan rapi.

Akhirnya tiba hari panen. Lili mencabut wortel yang besar dan oranye. "Ini wortel paling manis yang pernah kumakan!" katanya.

Lili memeluk Bu Kura-kura. "Terima kasih, Bu. Sekarang aku tahu, pelan-pelan dan sabar itu ternyata menyenangkan."$c$,
  moral = $m$Kesabaran membuat hasil kerja kita lebih baik, dan setiap guru punya cara hebat untuk mengajar.$m$,
  quiz = $q$[{"question": "Siapa guru baru di Sekolah Hutan?", "options": ["Pak Gajah", "Bu Kura-kura", "Bu Kucing"], "answer": 1}, {"question": "Apa yang ditanam murid-murid?", "options": ["Biji wortel", "Biji jagung", "Biji bunga matahari"], "answer": 0}, {"question": "Apa yang dipelajari Lili?", "options": ["Bersabar", "Berlari lebih cepat", "Melompat lebih tinggi"], "answer": 0}]$q$::jsonb,
  prompts = $p$[{"page": 3, "text": "Apakah benar guru yang pelan pasti membosankan? Kenapa?"}, {"page": 6, "text": "Kenapa biji tidak boleh digali terus?"}, {"page": 10, "text": "Pernahkah kamu menunggu sesuatu dengan sabar? Apa itu?"}]$p$::jsonb,
  vocab = $v$[{"word": "berkebun", "meaning": "menanam dan merawat tanaman"}, {"word": "bertunas", "meaning": "mulai tumbuh daun kecil"}, {"word": "panen", "meaning": "memetik hasil tanaman"}]$v$::jsonb
where id = '3a77f90f-b068-4db0-9fda-0de08594adef';

-- Fabel: Semut dan Merpati (dulu: Dongeng Fabel Imajinatif)
update public.stories set
  title = $t$Semut dan Merpati$t$,
  content = $c$Pada suatu hari yang panas, seekor semut kecil merasa sangat haus. Ia berjalan ke tepi sungai untuk minum.

Tiba-tiba, angin bertiup kencang. Semut tergelincir dan jatuh ke air! "Tolong! Tolong!" teriaknya sambil terbawa arus.

Di atas pohon, seekor merpati melihatnya. Merpati segera memetik sehelai daun dan menjatuhkannya di dekat semut.

Semut naik ke atas daun itu. Daun mengapung pelan sampai ke tepi sungai, dan semut pun selamat.

"Terima kasih, Merpati! Kamu sudah menyelamatkanku," kata Semut. "Sama-sama, Semut kecil," jawab Merpati ramah.

Beberapa hari kemudian, seorang pemburu datang ke hutan. Ia membawa jaring dan mengendap-endap mendekati merpati yang sedang bertengger.

Semut melihat pemburu itu. "Gawat! Merpati dalam bahaya," pikirnya. "Aku harus menolongnya!"

Semut berlari secepat-cepatnya, lalu menggigit kaki si pemburu. "Aduh!" teriak pemburu sambil melompat kaget.

Mendengar teriakan itu, Merpati terkejut dan langsung terbang tinggi. Jaring si pemburu hanya menangkap angin.

Pemburu pulang dengan tangan kosong. Merpati terbang turun dan hinggap di dekat Semut.

"Terima kasih, Semut! Walaupun kamu kecil, kamu sangat berani," kata Merpati. Sejak itu, mereka menjadi sahabat yang saling menjaga.$c$,
  moral = $m$Kebaikan akan dibalas dengan kebaikan, dan siapa pun bisa menolong walaupun bertubuh kecil.$m$,
  quiz = $q$[{"question": "Kenapa Semut pergi ke sungai?", "options": ["Karena ingin berenang", "Karena mencari makan", "Karena haus"], "answer": 2}, {"question": "Bagaimana Merpati menolong Semut?", "options": ["Menjatuhkan sehelai daun", "Menariknya dengan paruh", "Memanggil ikan"], "answer": 0}, {"question": "Bagaimana Semut menolong Merpati?", "options": ["Bernyanyi keras", "Memanggil teman-teman", "Menggigit kaki pemburu"], "answer": 2}]$q$::jsonb,
  prompts = $p$[{"page": 2, "text": "Coba tebak, apa yang akan dilakukan Merpati?"}, {"page": 6, "text": "Kalau temanmu dalam bahaya, apa yang bisa kamu lakukan?"}, {"page": 10, "text": "Siapa yang pernah menolongmu? Sudahkah kamu berterima kasih?"}]$p$::jsonb,
  vocab = $v$[{"word": "mengapung", "meaning": "terapung di atas air, tidak tenggelam"}, {"word": "pemburu", "meaning": "orang yang menangkap hewan di hutan"}, {"word": "bertengger", "meaning": "hinggap dan duduk di dahan pohon"}]$v$::jsonb
where id = '279b2337-5079-4475-b073-9df9a83e578f';

-- Fabel: Kura-kura dan Kelinci
update public.stories set
  title = $t$Kura-kura dan Kelinci$t$,
  content = $c$Di sebuah padang rumput, Kelinci suka sekali memamerkan kakinya yang cepat. "Tidak ada yang bisa mengalahkanku!" katanya.

Kura-kura yang sedang lewat berkata pelan, "Bagaimana kalau kita berlomba lari sampai ke pohon besar di atas bukit?"

Kelinci tertawa sampai berguling-guling. "Kamu? Jalanmu saja lambat sekali! Baiklah, ayo kita berlomba!"

Hewan-hewan hutan berkumpul untuk menonton. Burung Hantu menjadi wasit. "Bersiap... satu, dua, tiga, mulai!"

Kelinci melesat seperti angin. Dalam sekejap, Kura-kura sudah tertinggal sangat jauh di belakang.

Di tengah jalan, Kelinci menoleh. "Kura-kura masih jauh sekali. Aku tidur siang dulu saja di bawah pohon ini," katanya.

Kelinci pun tertidur pulas. Sementara itu, Kura-kura terus berjalan, selangkah demi selangkah, tanpa pernah berhenti.

Kura-kura melewati Kelinci yang sedang mendengkur. Ia terus berjalan pelan tetapi pasti, menaiki bukit sedikit demi sedikit.

Saat Kelinci bangun, matahari hampir terbenam. Ia melihat Kura-kura sudah hampir sampai di pohon besar!

Kelinci berlari secepat-cepatnya, tetapi sudah terlambat. Kura-kura menyentuh pohon besar lebih dulu. Hewan-hewan bersorak gembira.

Kelinci tertunduk malu. "Selamat, Kura-kura. Kamu hebat. Maafkan aku karena sudah sombong."

Kura-kura tersenyum. "Tidak apa-apa. Yang penting kita tidak menyerah dan tidak meremehkan orang lain." Mereka pun berteman baik.$c$,
  moral = $m$Jangan sombong dan jangan meremehkan orang lain. Terus berusaha walaupun pelan pasti akan berhasil.$m$,
  quiz = $q$[{"question": "Siapa yang menjadi wasit lomba?", "options": ["Gajah", "Rusa", "Burung Hantu"], "answer": 2}, {"question": "Apa yang dilakukan Kelinci di tengah lomba?", "options": ["Tidur siang", "Makan wortel", "Berenang"], "answer": 0}, {"question": "Siapa yang memenangkan lomba?", "options": ["Kelinci", "Burung Hantu", "Kura-kura"], "answer": 2}]$q$::jsonb,
  prompts = $p$[{"page": 5, "text": "Menurutmu, apakah Kelinci sebaiknya tidur? Kenapa?"}, {"page": 7, "text": "Kura-kura berjalan pelan tetapi tidak berhenti. Apa yang terjadi kalau kita terus berusaha?"}, {"page": 10, "text": "Bagaimana perasaan Kelinci? Apa yang ia pelajari?"}]$p$::jsonb,
  vocab = $v$[{"word": "wasit", "meaning": "orang yang memimpin dan mengawasi perlombaan"}, {"word": "mendengkur", "meaning": "bersuara keras saat tidur"}, {"word": "meremehkan", "meaning": "menganggap orang lain lemah atau tidak mampu"}]$v$::jsonb
where id = '3727d509-d83a-4d20-91ea-b8f737ad23c6';

-- Fabel: Semut dan Belalang
update public.stories set
  title = $t$Semut dan Belalang$t$,
  content = $c$Pada musim panas, Belalang bernyanyi dan menari sepanjang hari di padang rumput. "Hidup ini indah!" katanya riang.

Tidak jauh dari situ, sekelompok semut bekerja keras. Mereka mengangkat biji-bijian dan menyimpannya di sarang.

"Hai, Semut! Ayo bernyanyi bersamaku!" ajak Belalang. "Maaf, kami sedang menyiapkan makanan untuk musim dingin," jawab Semut.

Belalang tertawa. "Musim dingin masih lama! Lebih baik bersenang-senang dulu." Ia pun kembali bernyanyi.

Hari berganti hari. Para semut tetap bekerja, sedangkan Belalang terus bermain dan bermalas-malasan.

Lalu datanglah musim dingin. Angin bertiup dingin dan salju turun menutupi padang rumput. Tidak ada lagi makanan di luar.

Belalang kedinginan dan kelaparan. Ia berjalan pelan-pelan menuju sarang semut dan mengetuk pintunya.

"Semut, bolehkah aku meminta sedikit makanan? Aku sangat lapar," kata Belalang dengan suara gemetar.

Para semut saling berpandangan. "Masuklah, Belalang. Hangatkan dirimu di sini," kata Ratu Semut dengan baik hati.

Para semut membagi makanan mereka. Belalang makan dengan lahap dan merasa sangat berterima kasih.

"Aku menyesal tidak bekerja dulu," kata Belalang. "Musim panas nanti, aku akan membantu kalian mengumpulkan makanan."

Belalang menepati janjinya. Musim panas berikutnya, ia bekerja bersama para semut, dan saat istirahat ia bernyanyi menghibur mereka.$c$,
  moral = $m$Bersiaplah sejak awal dan rajinlah bekerja, lalu berbagilah kepada teman yang membutuhkan.$m$,
  quiz = $q$[{"question": "Apa yang dilakukan Belalang di musim panas?", "options": ["Bernyanyi dan menari", "Membangun rumah", "Mengumpulkan makanan"], "answer": 0}, {"question": "Apa yang disimpan para semut?", "options": ["Mainan", "Batu", "Biji-bijian"], "answer": 2}, {"question": "Apa yang dilakukan Belalang pada musim panas berikutnya?", "options": ["Pergi jauh", "Tidur sepanjang hari", "Bekerja bersama para semut"], "answer": 2}]$q$::jsonb,
  prompts = $p$[{"page": 3, "text": "Menurutmu, apakah Belalang benar? Kenapa?"}, {"page": 8, "text": "Kenapa ya para semut mau berbagi makanan?"}, {"page": 11, "text": "Apa yang bisa kamu siapkan sebelum berangkat sekolah besok?"}]$p$::jsonb,
  vocab = $v$[{"word": "sarang", "meaning": "rumah hewan, seperti semut atau burung"}, {"word": "lahap", "meaning": "makan dengan cepat dan banyak karena lapar"}, {"word": "menyesal", "meaning": "merasa sedih karena sudah berbuat salah"}]$v$::jsonb
where id = '13c72657-c3b5-4c4d-94df-80454bf9b288';

-- Fabel: Singa dan Tikus
update public.stories set
  title = $t$Singa dan Tikus$t$,
  content = $c$Di sebuah hutan, Raja Singa sedang tidur siang di bawah pohon yang rindang. Dengkurannya terdengar sampai jauh.

Seekor tikus kecil berlari-lari bermain. Tanpa sengaja, ia melompat ke atas hidung Singa!

Singa terbangun dan menangkap tikus dengan cakarnya yang besar. "Berani-beraninya kamu mengganggu tidurku!" aumnya keras.

Tikus gemetar ketakutan. "Ampun, Raja Singa! Lepaskan aku. Suatu hari nanti, aku pasti akan membalas kebaikanmu."

Singa tertawa. "Kamu yang sekecil ini mau menolongku? Lucu sekali! Baiklah, pergilah." Singa pun melepaskan Tikus.

Beberapa hari kemudian, Singa berjalan-jalan di hutan. Tiba-tiba, ia terjerat jaring pemburu yang kuat!

Singa meronta-ronta, tetapi jaringnya makin erat. "Tolong! Tolong!" aumnya. Suaranya menggema ke seluruh hutan.

Tikus mendengar suara itu. "Itu suara Raja Singa!" katanya. Ia segera berlari ke arah suara itu.

"Tenang, Raja Singa. Aku akan menolongmu," kata Tikus. Ia mulai menggigit tali jaring dengan giginya yang tajam.

Krek, krek, krek! Satu per satu tali jaring putus. Akhirnya terbuka lubang besar, dan Singa pun bebas.

"Terima kasih, Tikus kecil," kata Singa terharu. "Maaf aku sudah menertawakanmu. Ternyata kamu sahabat yang hebat."

Sejak hari itu, Singa dan Tikus bersahabat. Singa belajar bahwa siapa pun bisa menolong, sekecil apa pun dia.$c$,
  moral = $m$Jangan meremehkan orang lain, karena siapa pun bisa menolong, sekecil apa pun dia.$m$,
  quiz = $q$[{"question": "Apa yang dilakukan Singa saat Tikus melompat ke hidungnya?", "options": ["Bernyanyi", "Menangkap Tikus", "Berlari pergi"], "answer": 1}, {"question": "Apa yang menjerat Singa?", "options": ["Lumpur", "Akar pohon", "Jaring pemburu"], "answer": 2}, {"question": "Bagaimana Tikus menolong Singa?", "options": ["Menggigit tali jaring", "Memanggil gajah", "Mendorong jaring"], "answer": 0}]$q$::jsonb,
  prompts = $p$[{"page": 4, "text": "Kenapa Singa tertawa? Apakah tikus kecil bisa menolong?"}, {"page": 8, "text": "Coba tebak, bagaimana cara Tikus menolong Singa?"}, {"page": 11, "text": "Kamu juga bisa menolong orang lain. Apa contohnya?"}]$p$::jsonb,
  vocab = $v$[{"word": "rindang", "meaning": "banyak daunnya sehingga teduh"}, {"word": "terjerat", "meaning": "tertangkap dan terikat oleh tali atau jaring"}, {"word": "terharu", "meaning": "sangat tersentuh hatinya sampai ingin menangis bahagia"}]$v$::jsonb
where id = '197b5760-33c9-4dba-80f8-b4b03f038933';

-- Fabel: Burung Gagak yang Haus
update public.stories set
  title = $t$Burung Gagak yang Haus$t$,
  content = $c$Pada suatu siang yang sangat panas, seekor burung gagak terbang mencari air. Sudah lama ia tidak minum.

Sungai-sungai kering, dan kolam-kolam pun tidak berair. "Aduh, haus sekali," keluh Gagak sambil terus terbang.

Akhirnya, Gagak melihat sebuah kendi di halaman rumah. Ia segera turun dan melihat ke dalamnya.

Ada air di dalam kendi itu, tetapi hanya sedikit di bagian bawah. Paruh Gagak tidak sampai ke airnya.

Gagak mencoba memiringkan kendi, tetapi kendinya terlalu berat. Ia mencoba lagi dan lagi, tetapi tetap tidak berhasil.

Gagak hampir menyerah. Lalu ia melihat banyak batu kerikil di sekitar kendi. "Aha, aku punya ide!" katanya.

Gagak memungut sebutir kerikil dengan paruhnya, lalu menjatuhkannya ke dalam kendi. Plung!

Ia memungut kerikil lagi. Plung! Lalu satu lagi, dan satu lagi. Gagak bekerja dengan sabar.

Perlahan-lahan, air di dalam kendi naik makin tinggi. Kerikil-kerikil itu mendorong airnya ke atas.

Akhirnya air sampai di dekat mulut kendi. Gagak pun minum sepuasnya. "Segar sekali!" katanya gembira.

Gagak terbang lagi dengan riang. Ia belajar, kalau mau berpikir dan bersabar, selalu ada jalan keluar.$c$,
  moral = $m$Jangan cepat menyerah. Dengan berpikir dan bersabar, kita bisa menemukan jalan keluar.$m$,
  quiz = $q$[{"question": "Apa yang dicari Gagak?", "options": ["Sarang", "Makanan", "Air minum"], "answer": 2}, {"question": "Apa yang dimasukkan Gagak ke dalam kendi?", "options": ["Ranting", "Batu kerikil", "Daun"], "answer": 1}, {"question": "Kenapa airnya bisa naik?", "options": ["Karena kerikil mendorong air ke atas", "Karena kendi dibalik", "Karena hujan"], "answer": 0}]$q$::jsonb,
  prompts = $p$[{"page": 4, "text": "Kalau kamu jadi Gagak, apa yang akan kamu lakukan?"}, {"page": 8, "text": "Ayo coba di rumah bersama Ayah/Ibu: masukkan batu ke gelas berisi air. Apa yang terjadi?"}, {"page": 10, "text": "Pernahkah kamu hampir menyerah? Apa yang kamu lakukan?"}]$p$::jsonb,
  vocab = $v$[{"word": "kendi", "meaning": "tempat air dari tanah liat yang berleher"}, {"word": "paruh", "meaning": "mulut burung yang keras"}, {"word": "kerikil", "meaning": "batu kecil-kecil"}]$v$::jsonb
where id = 'c95c6d26-98b2-4a13-a397-b83d178f54b1';

-- Mitologi: Raja Midas dan Sentuhan Emas (dulu: Mitologi Yunani)
update public.stories set
  title = $t$Raja Midas dan Sentuhan Emas$t$,
  content = $c$Dahulu kala, di negeri Yunani, ada seorang raja bernama Midas. Ia sangat menyukai emas, lebih dari apa pun.

Raja Midas punya seorang putri kecil bernama Zoe. Zoe sangat sayang kepada ayahnya dan suka bermain di taman mawar.

Suatu hari, Midas menolong seorang tua yang tersesat. Ternyata ia adalah sahabat Dewa Dionisos. Sang dewa ingin membalas kebaikan Midas.

"Mintalah apa saja, Midas," kata Dionisos. "Aku ingin semua yang kusentuh berubah menjadi emas!" jawab Midas gembira.

Keesokan paginya, Midas menyentuh sebuah kursi. Kursi itu berubah menjadi emas! Ia menyentuh meja, pintu, dan bunga. Semuanya menjadi emas.

"Akulah raja terkaya di dunia!" seru Midas sambil tertawa. Lalu ia duduk untuk sarapan karena perutnya lapar.

Midas mengambil roti, tetapi roti itu menjadi emas yang keras. Ia minum susu, tetapi susunya pun menjadi emas.

"Bagaimana aku bisa makan?" Midas mulai cemas. Saat itu, Zoe berlari dan memeluk ayahnya.

Seketika, Zoe berubah menjadi patung emas! "Tidak! Putriku!" teriak Midas. Ia menangis karena sangat menyesal.

Midas berlari memohon kepada Dionisos. "Ambillah kembali sentuhan emas ini. Aku lebih sayang putriku daripada semua emas di dunia!"

"Mandilah di Sungai Paktolus," kata Dionisos. Midas segera mandi di sungai itu, dan sentuhan emasnya pun hilang.

Ia memercikkan air sungai ke patung Zoe. Zoe pun hidup kembali dan tersenyum! Midas memeluknya erat-erat.

Sejak hari itu, Midas tidak lagi serakah. Ia tahu bahwa keluarga dan kasih sayang jauh lebih berharga daripada emas.$c$,
  moral = $m$Jangan serakah. Keluarga dan kasih sayang jauh lebih berharga daripada harta.$m$,
  quiz = $q$[{"question": "Apa permintaan Raja Midas?", "options": ["Semua yang disentuhnya menjadi emas", "Punya banyak mainan", "Bisa terbang"], "answer": 0}, {"question": "Kenapa Midas tidak bisa makan?", "options": ["Makanannya berubah menjadi emas", "Ia tidak lapar", "Makanannya habis"], "answer": 0}, {"question": "Bagaimana Zoe hidup kembali?", "options": ["Dipercik air sungai", "Dipeluk ayahnya", "Dinyanyikan lagu"], "answer": 0}]$q$::jsonb,
  prompts = $p$[{"page": 3, "text": "Kalau kamu boleh meminta satu hal, apa yang akan kamu minta?"}, {"page": 6, "text": "Apa ya yang terjadi kalau semua makanan menjadi emas?"}, {"page": 12, "text": "Apa yang lebih berharga dari emas bagimu?"}]$p$::jsonb,
  vocab = $v$[{"word": "memohon", "meaning": "meminta dengan sangat"}, {"word": "memercikkan", "meaning": "menyiramkan air sedikit-sedikit"}, {"word": "serakah", "meaning": "ingin memiliki semuanya untuk diri sendiri"}]$v$::jsonb
where id = 'a1c0202d-31a8-4e51-b03e-35f589449049';

-- Mitologi: Pegasus
update public.stories set
  title = $t$Pegasus$t$,
  content = $c$Dahulu kala, di negeri Yunani, hiduplah seekor kuda putih yang sangat istimewa. Namanya Pegasus, dan ia punya sepasang sayap besar.

Pegasus bisa terbang tinggi menembus awan. Ia sangat lincah, sehingga tidak ada seorang pun yang bisa menaikinya.

Seorang pemuda pemberani bernama Bellerophon ingin berteman dengan Pegasus. Ia ingin menolong kerajaannya yang sedang diganggu monster.

Monster itu bernama Kimera. Ia menyemburkan api dan membuat penduduk ketakutan. Tidak ada yang berani melawannya.

Bellerophon berdoa kepada Dewi Athena. Malam itu, ia bermimpi Athena memberinya tali kekang emas. Saat bangun, tali itu benar-benar ada!

Bellerophon pergi ke mata air tempat Pegasus minum. Ia mendekat pelan-pelan dan berbicara dengan lembut.

Dengan tali kekang emas, Pegasus menjadi tenang. Ia membiarkan Bellerophon naik ke punggungnya. Wusss! Mereka terbang tinggi ke langit.

Bersama-sama, mereka terbang menuju sarang Kimera. Pegasus terbang cepat menghindari semburan api monster itu.

Bellerophon dan Pegasus bekerja sama dengan cerdik. Akhirnya Kimera kalah dan lari jauh, tidak pernah mengganggu lagi.

Penduduk bersorak gembira. Bellerophon menjadi pahlawan, dan Pegasus menjadi sahabatnya yang setia.

Namun lama-lama, Bellerophon menjadi sombong. "Aku hebat! Aku akan terbang ke Gunung Olympus, tempat tinggal para dewa!" katanya.

Pegasus tahu itu tidak baik. Ia mengibaskan tubuhnya, dan Bellerophon terjatuh ke semak-semak. Ia selamat, tetapi belajar untuk rendah hati.

Pegasus terbang ke langit dan menjadi rasi bintang. Sampai sekarang, di malam yang cerah, kita bisa melihat bintang-bintang berbentuk Pegasus.$c$,
  moral = $m$Bekerja sama membuat kita kuat, tetapi jangan pernah menjadi sombong.$m$,
  quiz = $q$[{"question": "Apa yang istimewa dari Pegasus?", "options": ["Bisa berbicara", "Punya tanduk emas", "Punya sayap dan bisa terbang"], "answer": 2}, {"question": "Apa yang diberikan Dewi Athena kepada Bellerophon?", "options": ["Pedang", "Tali kekang emas", "Mahkota"], "answer": 1}, {"question": "Pegasus akhirnya menjadi apa?", "options": ["Rasi bintang", "Gunung", "Pohon"], "answer": 0}]$q$::jsonb,
  prompts = $p$[{"page": 5, "text": "Kenapa Bellerophon mendekati Pegasus pelan-pelan dan lembut?"}, {"page": 10, "text": "Apakah sombong itu baik? Kenapa?"}, {"page": 12, "text": "Nanti malam, ayo lihat bintang bersama Ayah/Ibu!"}]$p$::jsonb,
  vocab = $v$[{"word": "kekang", "meaning": "tali untuk mengendalikan kuda"}, {"word": "pahlawan", "meaning": "orang yang berani menolong banyak orang"}, {"word": "rasi", "meaning": "kumpulan bintang yang membentuk gambar"}]$v$::jsonb
where id = '88285c4e-9a4b-4cf7-99d0-a64eaab7ccb9';

-- Mitologi: Anansi dan Guci Kebijaksanaan (dulu: Mitologi Dunia)
update public.stories set
  title = $t$Anansi dan Guci Kebijaksanaan$t$,
  content = $c$Di Afrika Barat, hiduplah seekor laba-laba cerdik bernama Anansi. Ia suka sekali mendengar cerita dan mengumpulkan pengetahuan.

Suatu hari, Dewa Langit memberinya sebuah guci besar. "Di dalam guci ini ada semua kebijaksanaan di dunia," kata sang dewa.

"Bagikanlah kepada semua makhluk," pesan Dewa Langit. Tetapi Anansi berpikir, "Kalau kusimpan sendiri, akulah yang paling pintar!"

Anansi memutuskan menyembunyikan guci itu di puncak pohon yang sangat tinggi, supaya tidak ada yang bisa mengambilnya.

Ia mengikat guci di depan perutnya, lalu mulai memanjat. Tetapi gucinya terus membentur batang pohon. Anansi pun tergelincir lagi dan lagi.

Anak Anansi, si kecil Kweku, memperhatikan dari bawah. "Ayah, kenapa gucinya tidak diikat di punggung saja? Pasti lebih mudah," katanya.

Anansi terdiam. "Benar juga," pikirnya. Ia memindahkan guci ke punggungnya, dan memanjat jadi jauh lebih mudah.

Sampai di puncak pohon, Anansi tersadar. "Aku membawa semua kebijaksanaan, tetapi anakku yang kecil lebih pintar dariku tadi!"

Anansi merasa malu. Ia tahu, tidak ada seorang pun yang bisa memiliki semua kebijaksanaan sendirian.

Ia pun membuka guci itu. Angin bertiup kencang dan membawa kebijaksanaan ke seluruh dunia, untuk semua makhluk.

Sejak saat itu, setiap orang punya sedikit kebijaksanaan. Kita bisa belajar dari siapa saja, bahkan dari anak kecil.$c$,
  moral = $m$Ilmu akan lebih bermanfaat jika dibagikan, dan kita bisa belajar dari siapa saja.$m$,
  quiz = $q$[{"question": "Apa isi guci pemberian Dewa Langit?", "options": ["Madu", "Kebijaksanaan", "Permen"], "answer": 1}, {"question": "Di mana Anansi ingin menyembunyikan gucinya?", "options": ["Di puncak pohon", "Di dalam sungai", "Di bawah tanah"], "answer": 0}, {"question": "Siapa yang memberi Anansi ide yang bagus?", "options": ["Dewa Langit", "Seekor burung", "Kweku, anaknya"], "answer": 2}]$q$::jsonb,
  prompts = $p$[{"page": 2, "text": "Apakah Anansi benar ingin menyimpannya sendiri? Kenapa?"}, {"page": 4, "text": "Kamu punya ide untuk membantu Anansi memanjat?"}, {"page": 10, "text": "Apa hal baru yang kamu pelajari hari ini? Ceritakan, yuk!"}]$p$::jsonb,
  vocab = $v$[{"word": "guci", "meaning": "tempat seperti botol besar dari tanah liat"}, {"word": "kebijaksanaan", "meaning": "kepandaian untuk berpikir dan bertindak dengan baik"}, {"word": "puncak", "meaning": "bagian paling atas"}]$v$::jsonb
where id = '2a073a36-e727-434c-bdd7-bed956bd7885';

-- Mitologi: Pertempuran Para Titan
update public.stories set
  title = $t$Pertempuran Para Titan$t$,
  content = $c$Dahulu kala, sebelum ada manusia, dunia dipimpin oleh para Titan. Mereka adalah raksasa yang sangat kuat, dan rajanya bernama Kronos.

Kronos takut takhta kerajaannya direbut. Karena itu, ia mengurung anak-anaknya di dalam istana gelap yang tersembunyi.

Istrinya, Rhea, sangat sedih. Saat anak bungsunya, Zeus, lahir, Rhea diam-diam membawanya ke sebuah gua di Pulau Kreta.

Di gua itu, Zeus dirawat oleh seekor kambing baik hati bernama Amaltea. Zeus tumbuh menjadi pemuda yang kuat dan berani.

Setelah dewasa, Zeus kembali untuk membebaskan kakak-kakaknya. Dengan cerdik, ia membuka istana gelap itu, dan kakak-kakaknya pun bebas.

Mereka adalah Hera, Poseidon, Hades, Demeter, dan Hestia. "Terima kasih, adikku!" kata mereka. "Ayo kita bersatu!"

Zeus juga membebaskan para Kiklops, raksasa bermata satu yang pandai membuat senjata. Mereka membuatkan Zeus petir yang menyala-nyala.

Poseidon mendapat trisula untuk mengendalikan laut, dan Hades mendapat helm ajaib yang bisa membuatnya tak terlihat.

Lalu terjadilah pertempuran besar antara para dewa muda dan para Titan. Gunung berguncang, dan langit bergemuruh selama bertahun-tahun.

Dengan bekerja sama, para dewa muda akhirnya menang. Para Titan dikurung di tempat yang sangat jauh agar tidak membuat kerusuhan lagi.

Zeus menjadi raja para dewa. Ia dan saudara-saudaranya tinggal di Gunung Olympus dan menjaga dunia bersama-sama.$c$,
  moral = $m$Dengan bersatu dan saling menolong, kita bisa mengalahkan kesulitan sebesar apa pun.$m$,
  quiz = $q$[{"question": "Siapa raja para Titan?", "options": ["Zeus", "Poseidon", "Kronos"], "answer": 2}, {"question": "Siapa yang merawat Zeus kecil?", "options": ["Seekor singa", "Seekor kambing bernama Amaltea", "Seekor burung elang"], "answer": 1}, {"question": "Apa yang dibuat para Kiklops untuk Zeus?", "options": ["Mahkota", "Petir", "Perahu"], "answer": 1}]$q$::jsonb,
  prompts = $p$[{"page": 3, "text": "Kenapa ya Rhea menyembunyikan Zeus?"}, {"page": 7, "text": "Kalau kamu punya benda ajaib, kamu mau punya apa?"}, {"page": 10, "text": "Kenapa para dewa muda bisa menang?"}]$p$::jsonb,
  vocab = $v$[{"word": "takhta", "meaning": "kursi raja, tanda kekuasaan"}, {"word": "trisula", "meaning": "tombak bermata tiga"}, {"word": "bergemuruh", "meaning": "berbunyi keras seperti guntur"}]$v$::jsonb
where id = 'eda59c21-76ec-4f27-a0da-dfd58339d57a';

-- Mitologi: Hercules
update public.stories set
  title = $t$Hercules$t$,
  content = $c$Hercules adalah putra Zeus, raja para dewa. Sejak bayi, ia sudah sangat kuat. Ia bisa mengangkat batu besar dengan satu tangan!

Tetapi Hercules belum pandai mengatur tenaganya. Saat bermain, pintu bisa copot dan kursi bisa patah. Ia sering merasa bersalah.

"Hercules, kekuatanmu adalah anugerah," kata gurunya. "Pakailah untuk menolong orang lain." Hercules pun bertekad untuk belajar.

Raja Eurystheus memberinya dua belas tugas yang sangat sulit. "Kalau berhasil, kamu akan menjadi pahlawan sejati," kata sang raja.

Tugas pertama, menangkap singa raksasa yang mengganggu desa. Kulit singa itu sangat keras, tetapi Hercules berhasil menaklukkannya dengan tangan kosong.

Tugas berikutnya, menangkap rusa bertanduk emas yang larinya sangat cepat. Hercules mengejarnya dengan sabar selama setahun tanpa melukainya.

Lalu ia harus membersihkan kandang raksasa berisi ribuan sapi dalam satu hari. Kandang itu sangat kotor dan bau!

Hercules berpikir cerdik. Ia membelokkan aliran dua sungai ke dalam kandang. Byuurr! Dalam sekejap, kandang itu bersih berkilau.

Tugas lainnya, mengambil apel emas dari kebun para dewi. Raksasa Atlas mau membantu, asalkan Hercules menyangga langit sebentar.

Wah, langit ternyata berat sekali! Tetapi Hercules kuat menahannya sampai Atlas kembali membawa apel-apel emas itu.

Satu demi satu, kedua belas tugas berhasil diselesaikan. Hercules tidak hanya kuat, tetapi juga sabar dan cerdik.

Orang-orang menyebutnya pahlawan. Hercules senang, karena kini kekuatannya dipakai untuk menolong banyak orang.$c$,
  moral = $m$Kekuatan sejati adalah saat kita memakai kemampuan kita untuk menolong orang lain.$m$,
  quiz = $q$[{"question": "Siapa ayah Hercules?", "options": ["Atlas", "Raja Eurystheus", "Zeus"], "answer": 2}, {"question": "Bagaimana Hercules membersihkan kandang raksasa?", "options": ["Membelokkan aliran dua sungai", "Meminta bantuan semut", "Dengan sapu besar"], "answer": 0}, {"question": "Apa yang disangga Hercules untuk Atlas?", "options": ["Langit", "Pohon", "Gunung"], "answer": 0}]$q$::jsonb,
  prompts = $p$[{"page": 2, "text": "Apa yang bisa kamu lakukan dengan tanganmu untuk menolong orang lain?"}, {"page": 7, "text": "Wah, cerdik sekali! Kalau kamu, bagaimana cara membersihkan kandang itu?"}, {"page": 11, "text": "Menurutmu, apa yang membuat seseorang menjadi pahlawan?"}]$p$::jsonb,
  vocab = $v$[{"word": "anugerah", "meaning": "hadiah atau pemberian yang berharga"}, {"word": "bertekad", "meaning": "bersungguh-sungguh ingin melakukan sesuatu"}, {"word": "menyangga", "meaning": "menahan dari bawah supaya tidak jatuh"}]$v$::jsonb
where id = '0549f02b-0b01-47b9-a65c-9c27779293e3';

-- Mitologi: Dewi Athena
update public.stories set
  title = $t$Dewi Athena$t$,
  content = $c$Di negeri Yunani, ada sebuah kota indah yang belum punya nama. Para dewa ingin menjadi pelindung kota itu.

Dua dewa maju ke depan. Ada Poseidon, dewa laut yang perkasa, dan Athena, dewi kebijaksanaan yang cerdas.

"Kita adakan lomba," kata Zeus. "Siapa yang memberi hadiah paling berguna, dialah yang menjadi pelindung kota ini."

Poseidon menghentakkan trisulanya ke batu. Byur! Memancarlah air dari batu itu. Penduduk bersorak dan berlari untuk mencicipinya.

"Uhuk, asin!" kata mereka. Ternyata airnya adalah air laut. Airnya tidak bisa diminum dan tidak bisa menyiram tanaman.

Lalu Athena berlutut dan menanam sesuatu di tanah. Perlahan, tumbuhlah sebatang pohon zaitun yang hijau dan rindang.

"Pohon ini memberi kalian buah untuk dimakan, minyak untuk memasak, serta kayu untuk membangun rumah," kata Athena.

Penduduk kota mengagumi pohon itu. Pohon zaitun bisa hidup bertahun-tahun dan berguna setiap hari.

Akhirnya penduduk memilih hadiah Athena. Kota itu pun dinamai Athena, sesuai nama sang dewi.

Poseidon sempat kecewa, tetapi ia menerima hasil lomba. Penduduk kota tetap menghormatinya sebagai penjaga lautan.

Sampai sekarang, Athena menjadi ibu kota negara Yunani. Pohon zaitun pun masih tumbuh di sana dan menjadi lambang perdamaian.$c$,
  moral = $m$Hadiah terbaik adalah yang bermanfaat bagi banyak orang, dan kita harus mau menerima hasil lomba dengan lapang dada.$m$,
  quiz = $q$[{"question": "Hadiah apa yang diberikan Athena?", "options": ["Kuda putih", "Pohon zaitun", "Mata air"], "answer": 1}, {"question": "Kenapa air dari Poseidon tidak bisa diminum?", "options": ["Karena berwarna hitam", "Karena panas", "Karena asin"], "answer": 2}, {"question": "Kota itu akhirnya diberi nama apa?", "options": ["Athena", "Olympus", "Poseidonia"], "answer": 0}]$q$::jsonb,
  prompts = $p$[{"page": 2, "text": "Kalau kamu jadi dewa, hadiah apa yang akan kamu berikan untuk kota itu?"}, {"page": 7, "text": "Kenapa pohon zaitun sangat berguna?"}, {"page": 9, "text": "Kalau kalah lomba, apa yang sebaiknya kita lakukan?"}]$p$::jsonb,
  vocab = $v$[{"word": "perkasa", "meaning": "sangat kuat"}, {"word": "zaitun", "meaning": "pohon yang buahnya kecil dan bisa dibuat minyak"}, {"word": "lambang", "meaning": "tanda yang punya arti"}]$v$::jsonb
where id = '52bea5c1-3561-4da1-a460-61dbb8df44e3';

-- Mitologi: Odysseus
update public.stories set
  title = $t$Odysseus$t$,
  content = $c$Odysseus adalah raja dari Pulau Ithaka. Ia terkenal sangat cerdik. Setelah perang panjang, ia berlayar pulang bersama para awak kapalnya.

Di rumah, istrinya Penelope dan putranya Telemakus menunggu dengan sabar. Tetapi perjalanan pulang Odysseus ternyata sangat panjang.

Suatu hari, kapalnya singgah di pulau raksasa bermata satu bernama Polifemus. Raksasa itu mengurung Odysseus dan teman-temannya di dalam gua.

"Siapa namamu?" tanya Polifemus. "Namaku Bukan Siapa-siapa," jawab Odysseus cerdik. Malam itu, Odysseus menyusun rencana.

Saat raksasa tertidur, Odysseus dan teman-temannya bersembunyi di bawah perut domba-domba yang berbulu tebal.

Pagi harinya, Polifemus membuka pintu gua agar domba-dombanya bisa makan rumput. Ia meraba punggung domba satu per satu.

Raksasa itu tidak tahu ada orang yang bergantung di bawah perut domba. Odysseus dan teman-temannya pun berhasil keluar!

"Tolong! Bukan Siapa-siapa kabur!" teriak Polifemus. Raksasa lain hanya tertawa. "Kalau bukan siapa-siapa, kenapa kamu ribut?"

Perjalanan berlanjut. Kapal mereka melewati pulau para Siren, makhluk yang nyanyiannya bisa membuat pelaut lupa arah.

Odysseus menyuruh awaknya menyumbat telinga dengan lilin. Ia sendiri diikat di tiang kapal supaya tetap aman saat mendengar nyanyian itu.

Bertahun-tahun mereka berlayar melewati badai dan rintangan. Odysseus tidak pernah menyerah, karena ia rindu pada keluarganya.

Akhirnya, Odysseus tiba di Ithaka. Penelope dan Telemakus memeluknya dengan bahagia. Keluarga itu kembali berkumpul.$c$,
  moral = $m$Jangan menyerah dan gunakan akalmu saat menghadapi kesulitan, seperti Odysseus yang selalu ingat keluarganya.$m$,
  quiz = $q$[{"question": "Dari pulau mana Odysseus berasal?", "options": ["Olympus", "Ithaka", "Kreta"], "answer": 1}, {"question": "Bagaimana Odysseus keluar dari gua raksasa?", "options": ["Bersembunyi di bawah perut domba", "Menggali terowongan", "Terbang"], "answer": 0}, {"question": "Apa yang dipakai awak kapal untuk menyumbat telinga?", "options": ["Kapas", "Daun", "Lilin"], "answer": 2}]$q$::jsonb,
  prompts = $p$[{"page": 3, "text": "Kenapa ya Odysseus menyebut namanya \"Bukan Siapa-siapa\"?"}, {"page": 9, "text": "Kalau kamu ada di kapal itu, apa yang akan kamu lakukan?"}, {"page": 11, "text": "Siapa yang paling kamu rindukan kalau kamu pergi jauh?"}]$p$::jsonb,
  vocab = $v$[{"word": "awak", "meaning": "orang-orang yang bekerja di kapal"}, {"word": "menyumbat", "meaning": "menutup lubang supaya tidak ada yang masuk"}, {"word": "rintangan", "meaning": "hal yang menghalangi perjalanan"}]$v$::jsonb
where id = 'c36cc5a4-1ce7-4092-a9f0-cb0d96785bc7';

-- Mitologi: Thor dan Palu Ajaib
update public.stories set
  title = $t$Thor dan Palu Ajaib$t$,
  content = $c$Di negeri para dewa Nordik, hiduplah Thor, dewa petir yang kuat. Ia punya palu ajaib bernama Mjolnir yang selalu kembali ke tangannya.

Dengan palu itu, Thor menjaga dunia dari para raksasa jahat. Setiap kali palunya diayunkan, langit bergemuruh dan petir menyambar.

Suatu pagi, Thor terbangun dan mencari palunya. "Di mana Mjolnir? Paluku hilang!" serunya kebingungan.

Loki, dewa yang licik tetapi pintar, terbang mencari palu itu. Ternyata palu itu dicuri Thrym, raja para raksasa.

"Aku akan mengembalikannya," kata Thrym, "asalkan Dewi Freya mau menikah denganku!" Dewi Freya menolak dengan marah.

Loki punya ide lucu. "Thor, kamu saja yang menyamar menjadi Freya! Pakailah gaun pengantin dan kerudung panjang," katanya.

Thor mengerutkan dahi, tetapi ia setuju. Ia memakai gaun, kalung, dan kerudung yang menutupi wajah dan janggutnya.

Di pesta raksasa, "pengantin" itu makan seekor sapi utuh dan delapan ekor ikan! Para raksasa terheran-heran.

"Kenapa Freya makan banyak sekali?" tanya Thrym. "Ia terlalu gembira sampai tidak makan selama delapan hari," jawab Loki cepat.

Akhirnya Thrym menyuruh pelayan membawa palu Mjolnir sebagai hadiah pernikahan dan meletakkannya di pangkuan sang pengantin.

Thor langsung menggenggam palunya dan membuka kerudung. "Aku bukan Freya, aku Thor!" Para raksasa ketakutan dan lari tunggang langgang.

Thor dan Loki pulang sambil tertawa. Mereka belajar bahwa akal yang cerdik dan kerja sama bisa menyelesaikan masalah.$c$,
  moral = $m$Dengan akal yang cerdik dan kerja sama, masalah yang sulit pun bisa diselesaikan.$m$,
  quiz = $q$[{"question": "Apa nama palu ajaib Thor?", "options": ["Trisula", "Tongkat Emas", "Mjolnir"], "answer": 2}, {"question": "Siapa yang mencuri palu Thor?", "options": ["Loki", "Thrym, raja raksasa", "Dewi Freya"], "answer": 1}, {"question": "Thor menyamar menjadi siapa?", "options": ["Raja raksasa", "Seorang petani", "Dewi Freya"], "answer": 2}]$q$::jsonb,
  prompts = $p$[{"page": 5, "text": "Hihi, lucu ya! Menurutmu, apakah penyamaran Thor akan berhasil?"}, {"page": 8, "text": "Kenapa para raksasa heran?"}, {"page": 11, "text": "Kapan kamu dan temanmu pernah bekerja sama?"}]$p$::jsonb,
  vocab = $v$[{"word": "menyamar", "meaning": "berpura-pura menjadi orang lain dengan mengubah pakaian"}, {"word": "kerudung", "meaning": "kain penutup kepala"}, {"word": "pangkuan", "meaning": "bagian atas paha saat duduk"}]$v$::jsonb
where id = '9becbe0c-aecf-45f0-ab2d-edd831df68ba';

-- Legenda Nusantara: Asal Usul Danau Toba
update public.stories set
  title = $t$Asal Usul Danau Toba$t$,
  content = $c$Dahulu kala, di Sumatra Utara, hiduplah seorang pemuda petani bernama Toba. Ia rajin bekerja di ladang dan suka memancing di sungai.

Suatu hari, kail Toba menangkap ikan besar bersisik emas. Toba senang sekali, tetapi tiba-tiba ikan itu berbicara!

"Tolong jangan makan aku," kata ikan itu. Seketika, ikan itu berubah menjadi seorang putri yang sangat cantik.

Putri itu mau menikah dengan Toba, tetapi dengan satu syarat. "Jangan pernah mengatakan bahwa aku berasal dari ikan," pesannya.

Toba berjanji. Mereka pun menikah dan dikaruniai seorang anak laki-laki bernama Samosir.

Samosir tumbuh menjadi anak yang lincah, tetapi ia suka makan banyak dan kadang belum mau menurut.

Suatu siang, ibunya menyuruh Samosir mengantar makanan untuk ayahnya di ladang. Di jalan, Samosir yang lapar menghabiskan sebagian bekal itu.

Toba yang lelah dan lapar menjadi sangat marah. Tanpa berpikir, ia berkata, "Dasar anak keturunan ikan!"

Samosir berlari pulang sambil menangis dan menceritakan semuanya kepada ibunya. Sang ibu sangat sedih, karena janji itu telah dilanggar.

"Samosir, naiklah ke bukit itu sekarang," kata ibunya. Samosir pun berlari ke atas bukit yang tinggi.

Tiba-tiba hujan turun sangat deras. Dari bekas pijakan sang ibu, air memancar tanpa henti, dan lembah itu perlahan tergenang.

Lembah itu berubah menjadi danau yang sangat luas. Sang ibu kembali menjadi ikan dan berenang di dalamnya.

Danau itu dinamakan Danau Toba. Bukit tempat Samosir berlindung menjadi pulau di tengahnya, yaitu Pulau Samosir.

Toba sangat menyesal karena telah melanggar janji dan berkata kasar. Sejak itu, ia selalu ingat pentingnya menepati janji.$c$,
  moral = $m$Tepatilah janji dan jagalah ucapan, karena kata-kata kasar bisa menyakiti hati orang lain.$m$,
  quiz = $q$[{"question": "Ikan yang ditangkap Toba berubah menjadi apa?", "options": ["Sebatang pohon", "Seorang putri cantik", "Seekor burung"], "answer": 1}, {"question": "Apa janji Toba kepada istrinya?", "options": ["Tidak pergi ke ladang", "Tidak memancing lagi", "Tidak mengatakan istrinya berasal dari ikan"], "answer": 2}, {"question": "Bukit tempat Samosir berlindung menjadi apa?", "options": ["Gunung api", "Sungai", "Pulau Samosir"], "answer": 2}]$q$::jsonb,
  prompts = $p$[{"page": 3, "text": "Kenapa ya sang putri meminta Toba berjanji?"}, {"page": 7, "text": "Kalau sedang marah, apa yang sebaiknya kita lakukan supaya tidak berkata kasar?"}, {"page": 12, "text": "Danau Toba sangat luas. Pernahkah kamu melihat danau?"}]$p$::jsonb,
  vocab = $v$[{"word": "kail", "meaning": "kait kecil di ujung tali pancing"}, {"word": "dilanggar", "meaning": "tidak ditepati"}, {"word": "lembah", "meaning": "tanah rendah di antara bukit-bukit"}]$v$::jsonb
where id = 'c5f17e63-f3e8-42ac-8127-4ba5a2bac6c4';

-- Legenda Nusantara: Legenda Banyuwangi
update public.stories set
  title = $t$Legenda Banyuwangi$t$,
  content = $c$Dahulu kala, di ujung timur Pulau Jawa, hiduplah seorang patih gagah bernama Sidopekso. Istrinya, Sri Tanjung, cantik dan berhati lembut.

Raja negeri itu, Prabu Sulahkromo, iri melihat kebahagiaan mereka. Ia mengutus Sidopekso pergi jauh untuk menjalankan tugas yang lama.

Selama Sidopekso pergi, Sri Tanjung tetap setia menunggu. Ia merawat rumah dan menanam bunga tanjung yang wangi di halaman.

Saat Sidopekso pulang, sang raja berbohong. "Istrimu tidak setia selama kamu pergi," katanya. Sidopekso pun termakan fitnah itu.

Sidopekso marah dan tidak mau mendengar penjelasan Sri Tanjung. "Aku tidak percaya lagi kepadamu!" katanya.

Sri Tanjung menangis. Ia mengajak suaminya ke tepi sungai yang airnya keruh dan berbau tidak sedap.

"Kanda, aku akan menjatuhkan bunga tanjung ini ke sungai. Kalau airnya menjadi harum, berarti aku berkata jujur," kata Sri Tanjung.

Bunga itu jatuh ke air. Perlahan, air sungai menjadi jernih, dan bau harum menyebar ke seluruh desa.

Sidopekso terkejut. "Banyu wangi! Airnya wangi!" serunya. Ia sadar istrinya jujur dan sang raja telah berbohong.

Sidopekso meminta maaf dengan sungguh-sungguh. Sri Tanjung memaafkannya, dan mereka kembali hidup bahagia.

Sejak itu, daerah tersebut dinamai Banyuwangi, yang artinya air yang wangi. Kini Banyuwangi adalah sebuah kota di Jawa Timur.$c$,
  moral = $m$Jangan mudah percaya pada berita bohong. Dengarkan dulu penjelasan orang lain dengan tenang.$m$,
  quiz = $q$[{"question": "Bunga apa yang dijatuhkan Sri Tanjung ke sungai?", "options": ["Bunga matahari", "Bunga mawar", "Bunga tanjung"], "answer": 2}, {"question": "Apa yang terjadi pada air sungai?", "options": ["Menjadi wangi", "Menjadi panas", "Menjadi kering"], "answer": 0}, {"question": "Apa arti kata Banyuwangi?", "options": ["Gunung tinggi", "Air yang wangi", "Kota besar"], "answer": 1}]$q$::jsonb,
  prompts = $p$[{"page": 4, "text": "Menurutmu, apa yang sebaiknya dilakukan Sidopekso?"}, {"page": 8, "text": "Kenapa air sungai bisa menjadi wangi?"}, {"page": 10, "text": "Banyuwangi ada di Jawa Timur. Kita tinggal di kota apa?"}]$p$::jsonb,
  vocab = $v$[{"word": "setia", "meaning": "selalu sayang dan tidak berpaling"}, {"word": "fitnah", "meaning": "cerita bohong untuk menjelekkan orang lain"}, {"word": "keruh", "meaning": "kotor, tidak jernih"}]$v$::jsonb
where id = '8828dbaf-9066-49b7-8047-1db21fe9c1ae';

-- Legenda Nusantara: Batu Menangis
update public.stories set
  title = $t$Batu Menangis$t$,
  content = $c$Di sebuah bukit di Kalimantan, hiduplah seorang janda miskin bersama putrinya, Darmi. Darmi sangat cantik, tetapi ia malas dan manja.

Setiap hari ibunya bekerja keras di ladang. Darmi hanya bersolek di depan cermin dan tidak mau membantu sama sekali.

Darmi juga sering meminta baju dan bedak baru. Ibunya selalu berusaha menurutinya, walaupun uang mereka sedikit.

Suatu hari, mereka pergi ke pasar di desa. Darmi berjalan di depan dengan baju indah, sedangkan ibunya berjalan di belakang membawa keranjang.

Seorang pemuda bertanya, "Siapakah ibu yang berjalan di belakangmu?" Darmi malu, lalu menjawab, "Dia pembantuku."

Ibunya terdiam. Hatinya sangat sedih. Di sepanjang jalan, setiap kali ada yang bertanya, Darmi selalu memberi jawaban yang sama.

Akhirnya sang ibu tidak kuat menahan sedih. Ia berdoa, "Ya Tuhan, sadarkanlah anakku yang durhaka ini."

Tiba-tiba, langit menjadi gelap dan petir menyambar. Kaki Darmi terasa berat dan perlahan berubah menjadi batu.

"Ibu, maafkan aku! Aku menyesal!" tangis Darmi. Tetapi tubuhnya terus berubah menjadi batu, dari kaki sampai kepala.

Batu itu terus mengeluarkan air mata. Orang-orang menyebutnya Batu Menangis, sebagai pengingat agar anak-anak selalu menyayangi ibunya.$c$,
  moral = $m$Sayangi dan hormatilah ibumu, dan jangan pernah malu mengakui orang tua sendiri.$m$,
  quiz = $q$[{"question": "Apa yang biasa dilakukan Darmi setiap hari?", "options": ["Bekerja di ladang", "Bersolek di depan cermin", "Memasak"], "answer": 1}, {"question": "Darmi mengaku ibunya sebagai siapa?", "options": ["Pembantunya", "Neneknya", "Bibinya"], "answer": 0}, {"question": "Darmi berubah menjadi apa?", "options": ["Batu", "Pohon", "Burung"], "answer": 0}]$q$::jsonb,
  prompts = $p$[{"page": 4, "text": "Bagaimana perasaan ibu Darmi saat mendengar jawaban itu?"}, {"page": 5, "text": "Kalau kamu jadi Darmi, apa jawabanmu kepada pemuda itu?"}, {"page": 9, "text": "Apa yang bisa kamu lakukan hari ini untuk membuat ibumu senang?"}]$p$::jsonb,
  vocab = $v$[{"word": "manja", "meaning": "selalu ingin dituruti"}, {"word": "bersolek", "meaning": "berdandan supaya terlihat cantik"}, {"word": "durhaka", "meaning": "tidak menghormati dan menyakiti hati orang tua"}]$v$::jsonb
where id = '048f8214-e62b-4e44-874a-596b0e88ebb6';

-- Legenda Nusantara: Legenda Rawa Pening (dulu: Tangkuban Perahu)
update public.stories set
  title = $t$Legenda Rawa Pening$t$,
  content = $c$Di sebuah desa di Jawa Tengah, penduduk sedang mengadakan pesta besar. Mereka memasak banyak makanan lezat untuk dimakan bersama.

Datanglah seorang anak laki-laki bernama Baru Klinting. Bajunya kotor dan kulitnya penuh luka. Ia sangat lapar.

"Bolehkah aku meminta sedikit makanan?" tanyanya. Tetapi penduduk malah mengejek dan mengusirnya. "Pergi sana, anak kotor!"

Baru Klinting berjalan dengan sedih. Di ujung desa, ia bertemu Nyai Latung, seorang nenek tua yang tinggal sendirian.

"Masuklah, Nak. Makanlah bersama Nenek," kata Nyai Latung ramah. Ia memberikan nasi dan sayur terbaik yang ia punya.

Setelah kenyang, Baru Klinting berkata, "Nek, siapkanlah lesung. Kalau nanti ada air datang, naiklah ke atasnya."

Baru Klinting kembali ke pesta. Ia menancapkan sebatang lidi ke tanah. "Siapa yang bisa mencabut lidi ini?" tantangnya.

Penduduk tertawa dan mencoba satu per satu. Orang dewasa yang paling kuat pun tidak bisa mencabutnya. Lidi itu tidak bergerak sedikit pun!

Akhirnya Baru Klinting sendiri yang mencabut lidi itu dengan mudah. Dari lubang bekas lidi, menyemburlah air yang sangat deras.

Air terus memancar dan menggenangi desa. Penduduk berlari ke bukit, dan mereka menyesal telah bersikap jahat.

Nyai Latung naik ke atas lesung sesuai pesan Baru Klinting. Lesung itu mengapung seperti perahu, dan ia pun selamat.

Desa itu berubah menjadi danau yang luas dan jernih. Orang-orang menyebutnya Rawa Pening, yang masih ada di dekat Ambarawa.$c$,
  moral = $m$Jangan mengejek orang lain, dan berbuat baiklah kepada siapa saja seperti Nyai Latung.$m$,
  quiz = $q$[{"question": "Siapa yang mau berbagi makanan dengan Baru Klinting?", "options": ["Nyai Latung", "Kepala desa", "Anak-anak desa"], "answer": 0}, {"question": "Apa yang ditancapkan Baru Klinting ke tanah?", "options": ["Sebatang lidi", "Tombak", "Bambu"], "answer": 0}, {"question": "Bagaimana Nyai Latung bisa selamat?", "options": ["Naik ke atas lesung", "Berenang", "Memanjat pohon"], "answer": 0}]$q$::jsonb,
  prompts = $p$[{"page": 2, "text": "Apakah sikap penduduk desa itu baik? Bagaimana seharusnya?"}, {"page": 7, "text": "Coba tebak, siapa yang bisa mencabut lidi itu?"}, {"page": 11, "text": "Apa kebaikan yang bisa kamu lakukan untuk temanmu?"}]$p$::jsonb,
  vocab = $v$[{"word": "mengejek", "meaning": "menertawakan atau menghina orang lain"}, {"word": "lesung", "meaning": "alat dari kayu untuk menumbuk padi"}, {"word": "lidi", "meaning": "batang tipis dari daun kelapa"}]$v$::jsonb
where id = 'c4988d67-3623-4588-a367-f1656fb144ae';

-- Legenda Nusantara: Putri Mandalika
update public.stories set
  title = $t$Putri Mandalika$t$,
  content = $c$Di Lombok, ada seorang putri cantik bernama Mandalika. Ia baik hati, ramah, dan sangat disayangi oleh rakyatnya.

Banyak pangeran dari berbagai kerajaan datang melamar. Semuanya ingin Putri Mandalika menjadi permaisuri mereka.

Para pangeran mulai bertengkar. "Akulah yang pantas!" kata yang satu. "Bukan, aku!" kata yang lain. Mereka bahkan bersiap untuk berperang.

Putri Mandalika sangat sedih. "Kalau aku memilih satu pangeran, yang lain akan marah, dan rakyat akan menderita," pikirnya.

Sang putri bersemedi dan berdoa meminta petunjuk. Ia ingin semua orang hidup damai tanpa pertengkaran.

Pada suatu pagi, ia mengundang semua pangeran dan rakyat ke Pantai Seger. Semua orang berkumpul menunggu keputusannya.

"Aku tidak akan memilih satu orang saja," kata Putri Mandalika. "Aku ingin menjadi milik kalian semua, untuk selamanya."

Sang putri lalu melangkah ke arah ombak dan menghilang di laut. Semua orang terkejut dan mencarinya ke mana-mana.

Tidak lama kemudian, muncullah ribuan cacing laut berwarna-warni di tepi pantai. Orang menyebutnya nyale.

Rakyat percaya, nyale itu adalah jelmaan Putri Mandalika. Sejak itu, para pangeran berhenti bertengkar dan hidup rukun.

Setiap tahun, masyarakat Lombok merayakan Bau Nyale. Mereka beramai-ramai ke pantai untuk mengenang putri yang mencintai perdamaian.$c$,
  moral = $m$Perdamaian lebih indah daripada pertengkaran, jadi pikirkanlah kebaikan untuk semua orang.$m$,
  quiz = $q$[{"question": "Di pulau mana Putri Mandalika tinggal?", "options": ["Lombok", "Bali", "Papua"], "answer": 0}, {"question": "Kenapa Putri Mandalika sedih?", "options": ["Karena para pangeran bertengkar", "Karena kehilangan mainan", "Karena hujan"], "answer": 0}, {"question": "Apa nama cacing laut berwarna-warni itu?", "options": ["Teripang", "Nyale", "Ubur-ubur"], "answer": 1}]$q$::jsonb,
  prompts = $p$[{"page": 3, "text": "Kenapa sang putri tidak mau memilih salah satu pangeran?"}, {"page": 6, "text": "Kalau teman-temanmu bertengkar, apa yang bisa kamu lakukan?"}, {"page": 10, "text": "Bau Nyale adalah pesta rakyat. Pesta apa yang pernah kamu ikuti?"}]$p$::jsonb,
  vocab = $v$[{"word": "permaisuri", "meaning": "istri raja"}, {"word": "bersemedi", "meaning": "duduk diam dan berdoa dengan tenang"}, {"word": "jelmaan", "meaning": "wujud baru dari sesuatu yang berubah bentuk"}]$v$::jsonb
where id = 'd0eded2b-1e91-45fa-a802-d9c7166a8787';

-- Legenda Nusantara: Asal Mula Nama Surabaya
update public.stories set
  title = $t$Asal Mula Nama Surabaya$t$,
  content = $c$Dahulu kala, di laut dekat muara sungai di Jawa Timur, hiduplah seekor ikan hiu besar bernama Sura.

Di sungai yang sama, tinggal seekor buaya yang kuat bernama Baya. Keduanya sama-sama lapar dan suka berburu ikan.

Suatu hari, Sura dan Baya berebut seekor ikan besar. "Itu milikku!" seru Sura. "Bukan, itu milikku!" seru Baya.

Mereka bertarung dengan sengit. Ekor mereka mengibas-ngibas, dan air muara menjadi bergelombang tinggi. Tetapi tidak ada yang menang.

Karena lelah, mereka membuat perjanjian. Laut menjadi wilayah Sura, dan sungai menjadi wilayah Baya. Keduanya setuju.

Untuk beberapa lama, keduanya hidup tenang. Sura mencari makan di laut, dan Baya mencari makan di sungai.

Namun ikan di laut mulai berkurang. Diam-diam, Sura berenang masuk ke sungai untuk mencari makan.

Baya melihatnya. "Sura! Kamu melanggar perjanjian kita!" serunya marah. Pertarungan pun terjadi lagi, lebih seru dari sebelumnya.

Mereka bertarung berhari-hari sampai sama-sama kelelahan. Akhirnya mereka sadar, bertengkar terus hanya membuat keduanya kesakitan.

"Maafkan aku, Baya. Aku tidak menepati janji," kata Sura. Baya mengangguk. "Ayo kita berbagi dan saling menjaga."

Penduduk sekitar sering menceritakan kisah Sura dan Baya. Karena itu, daerah di muara sungai itu dinamai Surabaya.

Kini Surabaya menjadi kota besar di Jawa Timur. Patung hiu dan buaya menjadi lambang kota itu sampai sekarang.$c$,
  moral = $m$Tepatilah janji dan berbagilah, karena bertengkar hanya membuat semua pihak rugi.$m$,
  quiz = $q$[{"question": "Sura adalah hewan apa?", "options": ["Ikan hiu", "Kura-kura", "Buaya"], "answer": 0}, {"question": "Apa isi perjanjian Sura dan Baya?", "options": ["Laut untuk Sura, sungai untuk Baya", "Tidur bergantian", "Bermain bersama"], "answer": 0}, {"question": "Kenapa daerah itu dinamai Surabaya?", "options": ["Dari nama Sura dan Baya", "Karena banyak ikan", "Karena airnya asin"], "answer": 0}]$q$::jsonb,
  prompts = $p$[{"page": 3, "text": "Kenapa Sura dan Baya bertengkar? Apa yang sebaiknya mereka lakukan?"}, {"page": 7, "text": "Apakah boleh melanggar janji? Kenapa?"}, {"page": 11, "text": "Lambang kota Surabaya adalah hiu dan buaya. Hewan apa yang ingin kamu jadikan lambang?"}]$p$::jsonb,
  vocab = $v$[{"word": "muara", "meaning": "tempat sungai bertemu dengan laut"}, {"word": "sengit", "meaning": "sangat seru dan keras"}, {"word": "wilayah", "meaning": "daerah yang dimiliki atau dijaga"}]$v$::jsonb
where id = '16fb9596-ecbb-4c44-ab76-1f17f3a40cb1';

-- Dongeng Dunia: Cinderella
update public.stories set
  title = $t$Cinderella$t$,
  content = $c$Dahulu kala, hiduplah seorang gadis baik hati bernama Cinderella. Ia tinggal bersama ibu tiri dan dua saudara tirinya.

Setiap hari Cinderella menyapu, mencuci, dan memasak. Ia sering duduk di dekat perapian yang penuh abu, sehingga bajunya kotor.

Suatu hari, datang undangan pesta dansa dari istana. Pangeran ingin mencari teman menari. Semua gadis di kerajaan diundang.

Kedua saudara tiri sibuk berdandan. "Kamu tidak boleh ikut, Cinderella! Bajumu kotor," kata ibu tirinya. Mereka pun berangkat.

Cinderella menangis di taman. Tiba-tiba, muncullah seorang ibu peri. "Jangan sedih, Nak. Kamu akan pergi ke pesta," katanya lembut.

Ibu peri mengayunkan tongkatnya. Labu berubah menjadi kereta kencana, tikus-tikus menjadi kuda, dan baju Cinderella menjadi gaun yang indah.

Kakinya pun memakai sepasang sepatu kaca yang berkilauan. "Ingat, sihirnya hilang tepat tengah malam," pesan ibu peri.

Di istana, Pangeran mengajak Cinderella menari. Mereka menari dan bercakap-cakap dengan gembira sampai Cinderella lupa waktu.

Teng, teng, teng! Jam berdentang dua belas kali. Cinderella berlari pulang, dan sebelah sepatu kacanya tertinggal di tangga istana.

Pangeran memungut sepatu itu. "Aku akan mencari gadis pemilik sepatu ini," katanya. Ia pun berkeliling ke setiap rumah.

Di rumah Cinderella, kedua saudara tiri mencoba sepatu itu. Tetapi kaki mereka terlalu besar. Sepatunya tidak muat!

"Bolehkah aku mencobanya?" tanya Cinderella. Sepatu kaca itu pas sekali di kakinya! Pangeran tersenyum bahagia.

Cinderella memaafkan ibu dan saudara tirinya. Ia dan Pangeran kemudian menikah dan hidup bahagia.$c$,
  moral = $m$Tetaplah baik hati dan sabar, karena kebaikan akan membawa kebahagiaan.$m$,
  quiz = $q$[{"question": "Labu diubah ibu peri menjadi apa?", "options": ["Kereta kencana", "Kapal", "Rumah"], "answer": 0}, {"question": "Kapan sihir ibu peri akan hilang?", "options": ["Saat hujan turun", "Saat matahari terbit", "Tepat tengah malam"], "answer": 2}, {"question": "Apa yang tertinggal di tangga istana?", "options": ["Mahkota", "Kalung", "Sepatu kaca"], "answer": 2}]$q$::jsonb,
  prompts = $p$[{"page": 4, "text": "Bagaimana perasaan Cinderella saat tidak boleh ikut ke pesta?"}, {"page": 8, "text": "Kenapa Cinderella harus pulang tepat tengah malam?"}, {"page": 12, "text": "Cinderella memaafkan saudara tirinya. Kenapa memaafkan itu baik?"}]$p$::jsonb,
  vocab = $v$[{"word": "perapian", "meaning": "tempat menyalakan api di dalam rumah"}, {"word": "kencana", "meaning": "terbuat dari emas atau berhias emas"}, {"word": "berdentang", "meaning": "berbunyi seperti lonceng"}]$v$::jsonb
where id = '5886c77a-0e08-42e9-ac37-b67e5a53944e';

-- Dongeng Dunia: Pinokio
update public.stories set
  title = $t$Pinokio$t$,
  content = $c$Dahulu kala, ada seorang tukang kayu tua bernama Geppetto. Ia tinggal sendirian dan sangat ingin punya seorang anak.

Suatu hari, Geppetto membuat boneka kayu yang lucu. Ia menamainya Pinokio. Ajaib, boneka itu bisa bergerak dan berbicara!

"Pinokio, mulai besok kamu harus sekolah, ya," kata Geppetto. Ia menjual mantel kesayangannya untuk membelikan Pinokio buku.

Di jalan, Pinokio bertemu Jangkrik Bijak. "Pergilah ke sekolah dan jadilah anak yang jujur," pesan Jangkrik. Tetapi Pinokio tidak mendengarkan.

Pinokio malah menjual bukunya untuk menonton pertunjukan boneka. Lalu ia ditipu Rubah dan Kucing yang licik sampai kehilangan uangnya.

Peri Berambut Biru datang menolong. "Kenapa kamu tidak ke sekolah?" tanyanya. Pinokio berbohong, dan hidungnya pun memanjang!

Setiap kali berbohong, hidung Pinokio makin panjang, sampai tidak muat lewat pintu. "Maaf, Peri, aku tidak akan berbohong lagi," tangisnya.

Sang Peri tersenyum, dan hidung Pinokio kembali seperti semula. Tetapi Pinokio masih suka bermain dan lupa pulang.

Sementara itu, Geppetto mencari Pinokio ke mana-mana. Ia berlayar ke laut, tetapi perahunya ditelan seekor ikan raksasa.

Pinokio mendengar kabar itu. Ia berenang ke laut dan ikut masuk ke perut ikan raksasa. Di sana, ia menemukan ayahnya!

Dengan berani, Pinokio menggendong Geppetto dan berenang keluar saat ikan raksasa menguap. Mereka pun selamat sampai ke pantai.

Sejak itu, Pinokio rajin, jujur, dan merawat ayahnya. Suatu pagi, ia terbangun dan sudah menjadi anak laki-laki sungguhan.$c$,
  moral = $m$Jadilah anak yang jujur dan mau mendengar nasihat, karena kebohongan hanya membawa masalah.$m$,
  quiz = $q$[{"question": "Siapa yang membuat Pinokio?", "options": ["Peri Berambut Biru", "Geppetto", "Jangkrik Bijak"], "answer": 1}, {"question": "Apa yang terjadi saat Pinokio berbohong?", "options": ["Rambutnya rontok", "Hidungnya memanjang", "Telinganya membesar"], "answer": 1}, {"question": "Di mana Pinokio menemukan Geppetto?", "options": ["Di sekolah", "Di perut ikan raksasa", "Di hutan"], "answer": 1}]$q$::jsonb,
  prompts = $p$[{"page": 3, "text": "Kenapa sebaiknya Pinokio mendengar nasihat Jangkrik?"}, {"page": 6, "text": "Kalau kamu berbuat salah, mana yang lebih baik: berbohong atau berkata jujur?"}, {"page": 11, "text": "Apa yang membuat Pinokio akhirnya menjadi anak sungguhan?"}]$p$::jsonb,
  vocab = $v$[{"word": "mantel", "meaning": "jaket tebal dan panjang"}, {"word": "licik", "meaning": "pandai menipu"}, {"word": "menguap", "meaning": "membuka mulut lebar-lebar karena mengantuk"}]$v$::jsonb
where id = '77badd4d-5e1f-4776-9897-b9b4fabae98b';

-- Dongeng Dunia: Putri Salju
update public.stories set
  title = $t$Putri Salju$t$,
  content = $c$Di sebuah kerajaan, hiduplah seorang putri berkulit putih seperti salju dan berambut hitam. Namanya Putri Salju.

Ibu tirinya, sang ratu, punya cermin ajaib. Setiap hari ratu bertanya, "Cermin, siapakah yang paling cantik di negeri ini?"

Suatu hari cermin menjawab, "Putri Salju yang paling cantik." Ratu menjadi sangat iri dan marah.

Ratu menyuruh seorang pemburu membawa Putri Salju ke hutan. Tetapi pemburu itu baik hati. "Larilah, Putri, dan jangan kembali," bisiknya.

Putri Salju berlari ke dalam hutan dan menemukan sebuah rumah mungil. Di dalamnya ada tujuh kursi kecil dan tujuh tempat tidur kecil.

Rumah itu milik tujuh kurcaci yang bekerja di tambang. Mereka senang Putri Salju tinggal bersama mereka dan membantu merawat rumah.

"Hati-hati, jangan bukakan pintu untuk orang yang tidak dikenal," pesan para kurcaci setiap pagi sebelum berangkat bekerja.

Sang ratu tahu Putri Salju masih ada. Ia menyamar menjadi nenek penjual apel dan datang ke rumah kurcaci.

"Cobalah apel merah yang manis ini, Nak," kata nenek itu. Putri Salju menggigitnya, lalu jatuh tertidur sangat lelap.

Para kurcaci pulang dan sangat sedih. Mereka menjaga Putri Salju yang tertidur di dalam peti kaca di tengah hutan.

Seorang pangeran lewat dan melihatnya. Saat peti itu diangkat, potongan apel terlepas dari mulut Putri Salju. Ia pun terbangun!

Putri Salju dan pangeran berterima kasih kepada para kurcaci. Mereka hidup bahagia, sedangkan ratu yang iri pergi jauh dan tidak kembali.$c$,
  moral = $m$Rasa iri membuat hati tidak tenang, sedangkan kebaikan hati membuat kita punya banyak sahabat.$m$,
  quiz = $q$[{"question": "Apa benda ajaib milik ratu?", "options": ["Sepatu ajaib", "Tongkat ajaib", "Cermin ajaib"], "answer": 2}, {"question": "Siapa yang tinggal di rumah mungil di hutan?", "options": ["Tujuh kurcaci", "Seekor serigala", "Tiga beruang"], "answer": 0}, {"question": "Apa yang membuat Putri Salju tertidur?", "options": ["Susu hangat", "Apel dari nenek penjual", "Lagu merdu"], "answer": 1}]$q$::jsonb,
  prompts = $p$[{"page": 6, "text": "Kenapa kita tidak boleh membukakan pintu untuk orang yang tidak dikenal?"}, {"page": 8, "text": "Apa yang sebaiknya dilakukan Putri Salju saat ditawari apel oleh orang asing?"}, {"page": 11, "text": "Siapa sahabatmu? Apa yang kalian suka lakukan bersama?"}]$p$::jsonb,
  vocab = $v$[{"word": "kurcaci", "meaning": "makhluk kecil dalam dongeng"}, {"word": "tambang", "meaning": "tempat menggali batu dan logam dari dalam tanah"}, {"word": "lelap", "meaning": "tidur sangat nyenyak"}]$v$::jsonb
where id = '4181a3e8-51b2-4652-baf3-e56f9f6acf7d';

-- Dongeng Dunia: Si Kerudung Merah
update public.stories set
  title = $t$Si Kerudung Merah$t$,
  content = $c$Ada seorang gadis kecil yang selalu memakai kerudung merah. Karena itu, semua orang memanggilnya Si Kerudung Merah.

Suatu hari, ibunya berkata, "Nenek sedang sakit. Antarkan kue dan madu ini ke rumah Nenek, ya. Jangan berbelok dari jalan setapak!"

Si Kerudung Merah berjalan melewati hutan. Di tengah jalan, seekor serigala menyapanya. "Mau ke mana, gadis manis?"

"Aku mau ke rumah Nenek di ujung hutan," jawab Si Kerudung Merah. Ia lupa pesan ibunya untuk tidak berbicara dengan orang asing.

"Lihat, di sana banyak bunga cantik. Petiklah untuk nenekmu," kata Serigala. Si Kerudung Merah pun berbelok dari jalan setapak.

Sementara itu, Serigala berlari cepat ke rumah Nenek. Nenek melihatnya dari jendela dan segera bersembunyi di dalam lemari.

Serigala memakai baju tidur dan topi Nenek, lalu berbaring di tempat tidur sambil menunggu.

Si Kerudung Merah datang. "Nenek, kenapa telingamu besar sekali?" "Supaya bisa mendengarmu, Cucuku," jawab Serigala dengan suara serak.

"Nenek, kenapa matamu besar sekali?" "Supaya bisa melihatmu." "Nenek, kenapa mulutmu besar sekali?" "Supaya bisa memakanmu!"

Serigala melompat! Si Kerudung Merah berteriak minta tolong. Seorang penebang kayu yang lewat mendengarnya dan segera datang.

Penebang kayu mengusir Serigala jauh ke dalam hutan. Nenek keluar dari lemari, dan mereka berpelukan dengan lega.

Si Kerudung Merah meminta maaf. "Mulai sekarang, aku akan selalu mendengar pesan Ibu dan tidak berbicara dengan orang asing."$c$,
  moral = $m$Dengarkan pesan orang tua, dan jangan mudah percaya kepada orang asing.$m$,
  quiz = $q$[{"question": "Apa yang dibawa Si Kerudung Merah untuk Nenek?", "options": ["Kue dan madu", "Roti dan susu", "Bunga dan buku"], "answer": 0}, {"question": "Di mana Nenek bersembunyi?", "options": ["Di bawah meja", "Di atap rumah", "Di dalam lemari"], "answer": 2}, {"question": "Siapa yang menolong Si Kerudung Merah?", "options": ["Penebang kayu", "Seekor kelinci", "Ibunya"], "answer": 0}]$q$::jsonb,
  prompts = $p$[{"page": 3, "text": "Apa pesan ibu Si Kerudung Merah? Apakah ia ingat?"}, {"page": 7, "text": "Siapa sebenarnya yang berbaring di tempat tidur Nenek?"}, {"page": 11, "text": "Kalau ada orang asing mengajakmu pergi, apa yang harus kamu lakukan?"}]$p$::jsonb,
  vocab = $v$[{"word": "setapak", "meaning": "jalan kecil untuk orang berjalan kaki"}, {"word": "asing", "meaning": "belum dikenal"}, {"word": "serak", "meaning": "suara yang parau dan kasar"}]$v$::jsonb
where id = '587df5a3-acbf-4b2e-8f9a-396f183a90ee';

-- Dongeng Dunia: Aladin dan Lampu Ajaib (dulu: Aladdin)
update public.stories set
  title = $t$Aladin dan Lampu Ajaib$t$,
  content = $c$Dahulu kala, di sebuah kota di negeri Timur, hiduplah anak muda miskin bernama Aladin bersama ibunya.

Suatu hari, datang seorang penyihir yang mengaku sebagai pamannya. "Aladin, bantulah aku mengambil sebuah lampu tua di dalam gua," katanya.

Penyihir memberi Aladin sebuah cincin. Aladin masuk ke gua yang penuh permata berkilauan, lalu menemukan lampu tua di ujung gua.

"Berikan lampunya dulu, baru kutolong kau keluar!" kata penyihir. Aladin curiga dan menolak. Penyihir marah dan menutup pintu gua.

Aladin ketakutan di dalam gua yang gelap. Tanpa sengaja ia menggosok cincinnya. Wuss! Muncullah jin cincin yang siap membantu.

Jin cincin membawa Aladin pulang. Di rumah, ibunya menggosok lampu tua itu supaya bersih. Wuss! Muncullah jin lampu yang besar sekali!

"Tuanku, apa permintaanmu?" tanya jin lampu. Aladin meminta makanan untuk ibunya, dan meja mereka langsung penuh hidangan lezat.

Suatu hari, Aladin melihat putri raja dan ingin melamarnya. Dengan bantuan jin, ia membawa hadiah indah ke istana.

Raja senang melihat Aladin yang sopan dan baik hati. Aladin dan sang putri pun menikah dan tinggal di istana yang megah.

Penyihir jahat mendengar kabar itu. Ia menyamar menjadi pedagang. "Tukarkan lampu lama dengan lampu baru!" serunya di depan istana.

Sang putri tidak tahu lampu itu ajaib dan menukarnya. Penyihir pun memakai jin lampu untuk memindahkan istana jauh sekali.

Aladin memanggil jin cincin dan menyusul ke sana. Dengan cerdik, ia dan sang putri mengambil kembali lampu ajaib dari penyihir.

Jin lampu membawa istana pulang. Sejak itu, Aladin memakai lampu ajaibnya dengan bijak untuk menolong banyak orang.$c$,
  moral = $m$Berhati-hatilah kepada orang yang licik, dan gunakan kelebihanmu dengan bijak untuk menolong sesama.$m$,
  quiz = $q$[{"question": "Apa yang diminta penyihir dari dalam gua?", "options": ["Peti emas", "Pedang", "Sebuah lampu tua"], "answer": 2}, {"question": "Jin apa yang pertama kali muncul?", "options": ["Jin lampu", "Jin cincin", "Jin botol"], "answer": 1}, {"question": "Bagaimana penyihir mendapatkan lampu dari sang putri?", "options": ["Mencurinya malam hari", "Meminjamnya", "Menukarnya dengan lampu baru"], "answer": 2}]$q$::jsonb,
  prompts = $p$[{"page": 3, "text": "Kenapa Aladin curiga kepada penyihir itu?"}, {"page": 6, "text": "Kalau kamu punya jin, apa permintaanmu?"}, {"page": 12, "text": "Bagaimana cara Aladin memakai lampu ajaibnya dengan bijak?"}]$p$::jsonb,
  vocab = $v$[{"word": "curiga", "meaning": "merasa ada yang tidak beres"}, {"word": "hidangan", "meaning": "makanan yang disajikan"}, {"word": "megah", "meaning": "besar dan indah"}]$v$::jsonb
where id = 'ecbe961e-92aa-48c4-a008-22f45d324772';

-- Dongeng Dunia: Hansel dan Gretel
update public.stories set
  title = $t$Hansel dan Gretel$t$,
  content = $c$Di tepi hutan, hiduplah dua kakak beradik, Hansel dan Gretel, bersama ayah mereka, seorang penebang kayu yang miskin.

Suatu hari, mereka ikut ayah mencari kayu ke hutan. Hansel menjatuhkan remah roti di sepanjang jalan supaya bisa pulang.

Hansel dan Gretel bermain terlalu jauh. Saat mencari jalan pulang, ternyata remah rotinya sudah dimakan burung-burung.

Mereka tersesat. Setelah berjalan lama, mereka melihat rumah yang terbuat dari kue jahe, permen, dan cokelat!

Karena lapar, mereka mencuil atap kue dan jendela permen. Tiba-tiba pintu terbuka, dan keluarlah seorang nenek tua.

"Masuklah, anak-anak," katanya manis. Ternyata ia adalah penyihir yang ingin Hansel dan Gretel bekerja untuknya selamanya.

Penyihir mengurung Hansel di dalam kandang dan menyuruh Gretel memasak sepanjang hari. Gretel sedih, tetapi ia tetap berpikir.

Mata penyihir kurang awas. Setiap hari ia meraba jari Hansel. Hansel yang cerdik menyodorkan tulang ayam, bukan jarinya.

Suatu hari, penyihir menyuruh Gretel memeriksa oven. "Aku tidak tahu caranya. Bisakah Nenek menunjukkannya?" tanya Gretel cerdik.

Saat penyihir membungkuk ke oven, Gretel mengambil kunci kandang dan membebaskan Hansel. Lalu mereka mengunci penyihir di dapurnya sendiri.

Di rumah itu, mereka menemukan peti berisi permata. Mereka membawanya dan berlari secepat-cepatnya keluar dari hutan.

Seekor bebek baik hati menyeberangkan mereka di sungai. Akhirnya mereka melihat rumah mereka dan ayah yang menunggu.

Ayah memeluk mereka sambil menangis bahagia. Berkat permata itu, mereka tidak kekurangan lagi dan hidup bahagia bersama.$c$,
  moral = $m$Kakak beradik yang saling menjaga dan berpikir cerdik bisa melewati masalah yang sulit.$m$,
  quiz = $q$[{"question": "Rumah penyihir terbuat dari apa?", "options": ["Kue jahe, permen, dan cokelat", "Batu dan kayu", "Es krim"], "answer": 0}, {"question": "Apa yang disodorkan Hansel kepada penyihir?", "options": ["Ranting", "Pensil", "Tulang ayam"], "answer": 2}, {"question": "Siapa yang menyeberangkan mereka di sungai?", "options": ["Seorang nelayan", "Seekor bebek", "Seekor ikan"], "answer": 1}]$q$::jsonb,
  prompts = $p$[{"page": 2, "text": "Kenapa remah roti Hansel hilang?"}, {"page": 7, "text": "Wah, Hansel cerdik! Apa yang akan kamu lakukan kalau jadi Hansel?"}, {"page": 12, "text": "Bagaimana kamu dan saudaramu saling menjaga?"}]$p$::jsonb,
  vocab = $v$[{"word": "remah", "meaning": "potongan kecil-kecil dari roti"}, {"word": "mencuil", "meaning": "mengambil sedikit dengan ujung jari"}, {"word": "awas", "meaning": "tajam penglihatannya"}]$v$::jsonb
where id = '5baeeac0-1103-4df7-99eb-a0630e47422e';

-- Dongeng tradisional: Malin Kundang (isi cerita tetap, hanya menambah ngobrol & kata baru)
update public.stories set
  prompts = $p$[{"page": 3, "text": "Menurutmu, kenapa Malin pergi merantau?"}, {"page": 9, "text": "Bagaimana perasaan ibu saat bertemu Malin lagi?"}, {"page": 11, "text": "Apakah sikap Malin kepada ibunya baik? Apa yang seharusnya ia lakukan?"}]$p$::jsonb,
  vocab = $v$[{"word": "merantau", "meaning": "pergi jauh dari kampung untuk bekerja"}, {"word": "lusuh", "meaning": "kotor dan sudah lama dipakai"}, {"word": "renta", "meaning": "sangat tua dan lemah"}, {"word": "durhaka", "meaning": "tidak menghormati dan menyakiti hati orang tua"}]$v$::jsonb
where id = '83dab26f-53b2-467c-b01e-79e0d70bebe2';
