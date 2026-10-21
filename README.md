# Bebaca - Aplikasi Belajar Baca

```
bebaca-app/
├── frontend/   Flutter (aplikasi)
└── backend/    Node.js + Express + Supabase (API + database)
```

Alur: **Flutter  --HTTP-->  Backend Node.js  -->  Supabase (Postgres + Auth)**

---
## LANGKAH 1 - Supabase (sekali saja)
1. Buat project di https://supabase.com
2. SQL Editor: jalankan `backend/supabase/schema.sql`, lalu `backend/supabase/seed.sql`.
3. Project Settings -> API: salin Project URL, anon key, dan service_role key.
4. (Disarankan) Authentication -> Providers -> Email: matikan "Confirm email".

## LANGKAH 2 - Jalankan backend
```bash
cd backend
cp .env.example .env        # isi 3 nilai Supabase dari langkah 1
npm install
npm run dev
```
- Cek: http://localhost:3000/health  -> `{"status":"ok"}`
- Swagger (untuk tes API tanpa Postman): http://localhost:3000/docs

## LANGKAH 3 - Siapkan & jalankan Flutter
```bash
cd frontend
flutter create .            # sekali saja: membuat folder android/ios/web
flutter pub get
```
Taruh gambar di `frontend/assets/images/` (opsional, ada ikon pengganti):
`logo.png`, `nav_belajar.png`, `nav_dongeng.png`, `nav_profile.png`, `nav_settings.png`.

### Izin jaringan (WAJIB, sekali saja)
**Android** - edit `frontend/android/app/src/main/AndroidManifest.xml`:
```xml
<manifest ...>
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.RECORD_AUDIO"/>   <!-- latihan membaca (mikrofon) -->
    <queries>   <!-- suara: pengenalan ucapan & text-to-speech (Android 11+) -->
        <intent><action android:name="android.speech.RecognitionService"/></intent>
        <intent><action android:name="android.intent.action.TTS_SERVICE"/></intent>
    </queries>
    <application
        android:usesCleartextTraffic="true"
        ... >
```
(`usesCleartextTraffic` hanya untuk development memakai http. Hapus saat produksi dan pakai HTTPS.)

**iOS** - tambahkan di `frontend/ios/Runner/Info.plist` (di dalam `<dict>` utama):
```xml
<key>NSAppTransportSecurity</key>
<dict><key>NSAllowsArbitraryLoads</key><true/></dict>
<key>NSMicrophoneUsageDescription</key>
<string>Bebaca memakai mikrofon agar anak bisa belajar membaca huruf.</string>
<key>NSSpeechRecognitionUsageDescription</key>
<string>Bebaca mengenali suara anak saat membaca huruf.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Bebaca memakai foto dari galeri sebagai foto profil.</string>
<key>NSCameraUsageDescription</key>
<string>Bebaca memakai kamera untuk mengambil foto profil.</string>
```
(Android: untuk foto profil tidak perlu izin tambahan.)

### Menjalankan (sesuaikan alamat backend)
| Perangkat | Perintah |
|---|---|
| Emulator Android | `flutter run` (otomatis ke `http://10.0.2.2:3000`) |
| iOS simulator / web / desktop | `flutter run` (otomatis ke `http://localhost:3000`) |
| HP asli (satu Wi-Fi dengan komputer) | `flutter run --dart-define=API_BASE_URL=http://IP_KOMPUTER:3000` |

Cari IP komputer: `ipconfig` (Windows) / `ifconfig` atau `ip a` (Mac/Linux).
Kalau tidak tersambung di HP asli, cek firewall komputer untuk port 3000.

---
## Coba alurnya
1. Landing -> **Buat Akun** -> isi data -> otomatis ke halaman Login.
2. Login -> masuk main menu.
3. **Belajar**: ketuk lesson biru (mis. Huruf A) -> kerjakan langkah-langkahnya -> hasil bintang -> lesson berikutnya terbuka.
4. **Dongeng**: ketuk sampul cerita (mis. Malin Kundang) -> video di atas (kalau sudah diisi), teks cerita di bawah.
5. **Profile**: "Materi terakhir" dan "Hari belajar berturut-turut" ikut berubah.
6. **Settings**: ubah toggle / Parental Control -> tersimpan di Supabase (tetap ada setelah app dibuka ulang).
7. **Logout** -> kembali ke Landing. Buka app lagi tanpa logout -> langsung masuk main menu.

## Cara kerja lesson
Tiap lesson dibuka di dalam tab Belajar (sidebar tetap tampil). Tombol **Next** baru aktif setelah langkah selesai;
tombol **X** untuk keluar. Anak yang belum lancar membaca bisa mengetuk ikon speaker untuk mendengar perintahnya.

| Jenis lesson (`kind`) | Langkah |
|---|---|
| `letter` (mis. "Huruf A") | 1 Kenalan huruf besar & kecil -> 2 Carilah huruf -> 3 Dengar lalu pilih* -> 4 Gambarkan huruf besar -> 5 Gambarkan huruf kecil -> 6 Baca huruf (mikrofon) |
| `review` (Latihan) | Carilah huruf, untuk tiap huruf di lesson |
| `quiz` (Kuis) | Dengar lalu pilih*, untuk tiap huruf |
| `challenge` (Tantangan) | Baca huruf (mikrofon), untuk tiap huruf |

\* langkah "dengar lalu pilih" hanya muncul jika **Listening Exercise** di Settings menyala (kalau mati, kuis memakai "Carilah huruf").
**Sound Effect** mengatur suara otomatis (perintah & huruf dibacakan sendiri), **Animation** mengatur animasi & konfeti.

- **Menulis**: jari menelusuri huruf abu-abu. Hasilnya baru BENAR jika **seluruh** huruf tertelusuri dengan tepat:
  hampir seluruh garis tengah huruf tertutup goresan, tidak ada bagian yang terlewat (mis. garis silang huruf A),
  dan goresan tetap di dalam badan huruf. Bar progres tidak pernah penuh sebelum lulus. Jika ada bagian terlewat,
  muncul **titik oranye** berdenyut di bagian itu. *Hapus* mengulang; tombol *Lewati* baru muncul setelah 3 kali mencoba
  (mengurangi bintang).
  Ambang ketelitian sudah diuji dengan simulasi memakai bentuk huruf Itim asli (goresan rapi lulus ±100%, bagian terlewat ≥15%,
  setengah huruf, coretan, dan kotak penuh hampir semuanya gagal). Mau lebih longgar/ketat? Ubah konstanta
  `_needCore`, `_needCell`, `_brush` di bagian atas `frontend/lib/features/lesson/steps/trace_step.dart`.
- **Membaca**: ucapan dikenali lewat mikrofon (bahasa Indonesia bila tersedia di perangkat). Kalau mikrofon tidak bisa dipakai,
  muncul tombol "Aku sudah membaca".
- **Bintang**: 0 salah = 3 bintang, 1-2 salah = 2 bintang, lebih = 1 bintang. Lesson yang sudah selesai boleh diulang;
  bintang tersimpan hanya yang terbaik.
- Huruf pengecoh diambil dari seluruh huruf di section itu (Unit 1 = vokal, Unit 2 = konsonan).
- Suara huruf memakai **nama huruf** ("be", "ce", "de"), belum bunyi fonetik.

**Menambah lesson/huruf baru** (tanpa mengubah aplikasi) - contoh Huruf H di Unit 2:
```sql
insert into public.lessons (section_id, order_index, title, kind, letters)
select id, 9, 'Huruf H', 'letter', array['H'] from public.sections where unit = 2 and section = 1;
```
(`order_index` menentukan urutan; lesson berikutnya otomatis terbuka setelah yang sebelumnya selesai.)

> Ingin tahu skema database sudah lengkap? Buka `http://localhost:3000/health/db` (hanya aktif saat development).

> Database lama? Jalankan berurutan: `migrations/001_story_video.sql` lalu `migrations/002_lesson_content.sql`
> (menambah jenis lesson, daftar huruf, dan bintang). Keduanya aman dijalankan ulang.

## Video & isi dongeng
Tiap dongeng punya 3 kolom di tabel `stories` (Supabase -> Table Editor):
| Kolom | Fungsi |
|---|---|
| `video_url` | link video **mp4** (format H.264). Tampil di atas. Kosong = tidak ada video |
| `cover_url` | gambar sampul; dipakai di daftar dongeng dan sebagai gambar awal sebelum video diputar |
| `content` | teks cerita. Pisahkan paragraf dengan **baris kosong** |

Contoh dongeng **Malin Kundang** sudah berisi teks dari `seed.sql`. Cara menambah video:
1. Supabase -> Storage -> buat bucket **public** (mis. `stories`) -> upload `malin-kundang.mp4` dan gambar sampulnya.
   (Paket gratis Supabase membatasi ukuran file 50 MB; kompres videonya bila perlu.)
2. Salin URL publik masing-masing, lalu jalankan di SQL Editor:
```sql
update public.stories
set video_url = 'https://xxxx.supabase.co/storage/v1/object/public/stories/malin-kundang.mp4',
    cover_url = 'https://xxxx.supabase.co/storage/v1/object/public/stories/malin-kundang.jpg'
where title = 'Malin Kundang';
```
Video diputar saat anak menekan tombol play (tidak otomatis, hemat kuota). Ketuk video untuk jeda, geser bar di bawahnya untuk maju/mundur.
Link YouTube **tidak** bisa dipakai; harus link langsung ke file video.

> Sudah terlanjur menjalankan `schema.sql` versi lama? Jalankan `backend/supabase/migrations/001_story_video.sql`
> (menambah kolom `video_url` dan mengisi teks Malin Kundang). Aman dijalankan ulang.

## Baca Bersama (dongeng sebagai buku bergambar)
Migrasi: `backend/supabase/migrations/005_story_reader.sql` (kolom `moral`, `quiz`, `page_images` + tabel `story_progress`).
- Halaman dongeng: sampul + info (menit, jumlah halaman), tombol **Baca Bersama** / **Lanjut Baca** dan **Tonton Video**.
- Pembaca: isi cerita dipecah per halaman (1-2 kalimat). **Dengarkan** = narasi membacakan, kata yang dibaca
  menyala kuning, lalu otomatis pindah halaman. **Ketuk kata** = dengar kata itu. **Aku baca** = anak membaca
  lewat mikrofon, kata yang terbaca jadi hijau.
- Akhir cerita: kartu **Pesan dari cerita ini** (`moral`), **kuis** (`quiz`: `[{question, options[], answer}]`),
  bintang + konfeti. Progres & bintang tersimpan; rak dongeng menampilkan ✅ dan baris **Lanjutkan membaca**.
- Gambar per halaman: isi `page_images` (array URL, urut sesuai halaman). Kosong = pakai gambar sampul.
- Narasi AI (opsional, sekali saja; tanpanya dipakai suara perangkat):
  `cd frontend; $env:ELEVENLABS_API_KEY="sk_..."; python tool/generate_story_voice.py --voice <VOICE_ID> --title "Malin Kundang"`
  Hasil: `frontend/assets/stories/st_*.mp3` + `.json` (waktu tiap kata). Kalau isi cerita diubah, jalankan lagi.

## Untuk Orang Tua: Laporan Perkembangan & Pantau Langsung (QR)
Migrasi: `backend/supabase/migrations/006_parent_report.sql` (tabel `learning_events` & `parent_links`).
Settings -> **Untuk Orang Tua** (dibuka dengan PIN orang tua):
- **Laporan Perkembangan** (`GET /api/report?week=0`): waktu belajar, hari aktif, hari beruntun, lesson & dongeng
  selesai, ketepatan jawaban, aktivitas terbaru. **Premium**: grafik harian, penguasaan tiap huruf
  (dikuasai / sedang belajar / perlu latihan, termasuk "sering tertukar dengan"), dan saran otomatis.
- **Pantau Langsung**: aplikasi menampilkan QR. Orang tua scan dengan kamera HP -> halaman web
  `https://<backend>/pantau/<token>` yang diperbarui tiap 4 detik (sedang belajar apa, langkah ke berapa,
  jawaban benar/salah, waktu hari ini). Tanpa memasang aplikasi. "Ganti QR" membuat token baru
  (yang lama tidak berlaku), "Matikan" mencabut akses. Hanya hash token yang disimpan di database.
- Aplikasi anak mengirim **kejadian belajar** (`POST /api/events`, dikumpulkan tiap ~2 detik): buka aplikasi,
  pindah menu, mulai/selesai lesson, tiap jawaban (huruf, jenis soal, benar/salah, huruf yang dipilih),
  buka/halaman/selesai dongeng, dan detak "aktif" tiap menit. **Tidak** ada isi layar, foto, atau suara.

## Efek suara & animasi
Semua efek mengikuti pengaturan **Sound Effect** dan **Animation** di Settings (mati = tidak ada suara / animasi diam).

| Di mana | Suara | Animasi |
|---|---|---|
| Splash | nada berkilau naik | logo membal, huruf "Bebaca" muncul satu-satu |
| Jalur lesson | ketuk = "tok" kayu; lesson terkunci = nada lembut | lesson aktif berdenyut dengan cincin; ketuk = menekan; terkunci = bergoyang; lesson selesai menampilkan bintang yang didapat |
| Kenalan huruf | ketuk kotak = "tok" + nama huruf | kotak muncul membal, melayang pelan, memantul saat diketuk |
| Cari huruf / Dengar & pilih | benar = "ting", semua ketemu = nada sukses, salah = nada rendah lembut | kotak benar meledak jadi kilau + centang; kotak salah bergetar merah |
| Menulis | selesai = nada sukses | ledakan kilau + centang membal |
| Membaca | mikrofon menyala = "bip" naik; benar = nada sukses; salah = nada rendah | gelombang memancar dari tombol mikrofon; ledakan kilau saat benar |
| Pindah soal | "whoosh" kecil | soal baru geser masuk dari kanan; tombol **Next** berdenyut saat boleh ditekan; bar progres bergerak halus |
| Maskot | - | maskot kuning berjalan di atas bar progres: melompat gembira saat benar, menggeleng sedih saat salah |
| Hasil | fanfare, lalu "ting" tiap bintang (nada makin tinggi) | sinar berputar, "Hebat!" membal, bintang berputar masuk + kilau, konfeti, api streak berdenyut |
| Pindah tab | "tok" pelan | - |

File suara ada di `frontend/assets/sounds/` (WAV, total ±740 KB) dan dibuat oleh `frontend/tool/generate_sounds.py`
(`pip install numpy && python3 tool/generate_sounds.py`). Mau pakai suara sendiri? Ganti file dengan nama yang sama.
Efek suara dicampur dengan suara pembacaan huruf (tidak saling memotong).

## Profil: edit data & foto
Tab **Profile**:
- **Edit Profil**: ubah nama, tanggal lahir, dan umur. Jika tanggal lahir diisi, **umur dihitung otomatis** (dan bertambah sendiri tiap ulang tahun);
  jika tanggal lahir dikosongkan, umur diisi manual.
- **Foto profil**: ketuk foto (ada lencana kamera) -> ambil foto / pilih dari galeri / hapus. Foto dikecilkan di perangkat lebih dulu,
  lalu diunggah ke **Supabase Storage** (bucket publik `avatars`, dibuat otomatis oleh backend saat unggahan pertama).
  Batas 2 MB, hanya JPEG/PNG/WebP, tipe file dicek dari isinya (bukan dari nama file). Foto lama otomatis dihapus.
- "Materi terakhir" yang panjang kini turun ke baris berikutnya, tidak terpotong lagi.

## Pengaturan: semua berfungsi
| Pengaturan | Pengaruhnya |
|---|---|
| **Sound Effect** | Semua efek suara (lesson, jalur lesson, tab, splash, hasil) dan suara otomatis (perintah & huruf dibacakan) |
| **Animation** | Animasi lesson (maskot, ledakan kilau, geser soal), cincin berdenyut di jalur lesson, konfeti halaman hasil, animasi splash |
| **Listening Exercise** | Menampilkan langkah "dengar lalu pilih huruf" di lesson huruf dan kuis (mati = kuis memakai "Carilah huruf") |
| **Parental Control** | Mengunci aplikasi (lihat di bawah) |

Parental Control, saat menyala:
- **Time Limit**: bila waktu belajar hari ini (**Timespent**, dicatat tiap menit selama app terbuka) mencapai batas -> layar terkunci
  "Waktu belajar habis". Waktu saat terkunci tidak dihitung. Pilih "Tanpa batas" untuk mematikan batas.
- **Curfew**: dari jam yang dipilih sampai **05:00 pagi** layar terkunci "Waktunya istirahat" (mis. 20:00 -> 05:00).
- **Gerbang orang tua (PIN 4 angka)**: mematikan Parental Control, mengubah Time Limit / Curfew saat sedang menyala,
  dan membuka Bebaca Premium harus memasukkan PIN orang tua. PIN dibuat pertama kali (dan diatur ulang lewat "Lupa PIN?")
  dengan memasukkan **password akun**, jadi anak tidak bisa membuatnya sendiri. PIN disimpan di server sebagai hash
  (migrasi `004_parent_pin.sql`); salah PIN dibatasi 10x per 5 menit. Di layar terkunci, tombol **Untuk orang tua** (juga lewat PIN) menawarkan
  *Tambah 15 menit hari ini* atau *Matikan kontrol orang tua*.
- Pengaturan tersimpan di server (ikut ke perangkat lain) dan di perangkat (dipakai splash sebelum login).

## Splash screen
Saat aplikasi dibuka tampil splash animasi (langit berbintang, kotak huruf melayang, logo membal, tulisan "Bebaca" muncul
huruf demi huruf, ±3 detik) sambil mengecek sesi login. Kode: `frontend/lib/features/splash/splash_page.dart`
(warna & durasi mudah diubah di file itu). Jika ingin layar putih sebelum Flutter siap juga ikut berwarna biru,
tambahkan paket `flutter_native_splash` (opsional).

**Suara splash di web:** browser (Chrome dkk.) memblokir suara sebelum pengguna menyentuh halaman, jadi di web (jika Sound Effect
menyala) splash menampilkan "Ketuk layar untuk mulai" dan baru memutar animasi + nada setelah diketuk. Di HP/emulator langsung berbunyi.
Splash mengikuti pengaturan Sound Effect & Animation terakhir (disimpan di perangkat).

## Deploy aplikasi Android (APK)
Nama aplikasi **Bebaca**, ID `id.bebaca.app` (jangan diganti setelah upload pertama ke Play Store).
Ikon dari logo maskot: sumber di `frontend/assets/icon/` (dibuat `tool/generate_icons.py`),
dipasang ke semua platform dengan `dart run flutter_launcher_icons`.

1. Backend sudah online (Vercel). Isi `frontend/config/dart_defines.json`:
   `{ "API_BASE_URL": "https://<nama-project>.vercel.app" }`
2. Pastikan disk punya ruang kosong minimal ~5 GB, lalu:
   ```bash
   cd frontend
   flutter build apk --release --split-per-abi --dart-define-from-file=config/dart_defines.json
   ```
   Hasil: `frontend/build/app/outputs/flutter-apk/app-arm64-v8a-release.apk` (untuk hampir semua HP sekarang).
   Tanpa `--split-per-abi` -> satu file `app-release.apk` untuk semua HP (lebih besar).
3. Kirim APK ke HP (Drive/WhatsApp/kabel), buka, izinkan "Instal aplikasi tidak dikenal".
4. Versi berikutnya: naikkan `version:` di `pubspec.yaml` (mis. `1.0.1+2`), build ulang, pasang menimpa.

**Kunci tanda tangan** (`frontend/android/upload-keystore.jks` + `key.properties`, tidak ikut git):
SIMPAN CADANGANNYA di tempat aman. Kalau hilang, APK baru tidak bisa meng-update aplikasi yang
sudah terpasang, dan tidak bisa dipakai untuk update di Play Store.

## Masalah umum
| Gejala | Penyebab / solusi |
|---|---|
| "Tidak bisa terhubung ke server" | Backend belum jalan, alamat salah (lihat tabel di atas), atau izin jaringan belum diset |
| `Cleartext HTTP traffic not permitted` | `usesCleartextTraffic` di AndroidManifest belum ditambahkan |
| "Email atau password salah" padahal benar | Akun belum aktif: matikan "Confirm email" di Supabase, atau register ulang |
| Setelah restart, minta login lagi | Sesi habis / token dicabut; login ulang |
| Video: "Video tidak bisa diputar" | `video_url` bukan link langsung ke mp4 (mis. YouTube), bucket belum public, atau format bukan H.264 |
| Mikrofon tidak bekerja | Izin mikrofon belum diberikan, atau `RECORD_AUDIO`/`queries` (Android) / Info.plist (iOS) belum ditambahkan. Emulator sering tidak punya pengenalan suara; coba di HP asli |
| Suara huruf tidak keluar | Perangkat belum punya mesin text-to-speech bahasa Indonesia (Pengaturan -> Bahasa -> Text-to-speech) |
| Menulis: tidak pernah "selesai" | Ikuti titik oranye (bagian yang masih terlewat) dan telusuri sampai ujung setiap garis huruf, di tengah badan huruf. Setelah 3 kali mencoba muncul *Lewati* |
| Foto profil: "Gagal mengunggah foto" | Lihat terminal backend (`[avatar]`). Pastikan `SUPABASE_SERVICE_ROLE_KEY` benar; backend membuat bucket `avatars` otomatis |
| Foto profil: "Tidak bisa mengambil foto" | Izin kamera/galeri belum diberikan, atau (iOS) kunci `NSPhotoLibraryUsageDescription` / `NSCameraUsageDescription` belum ditambahkan. Kamera tidak tersedia di web/desktop, pakai galeri |
| Splash di web tidak berbunyi | Normal sebelum diketuk (aturan browser); ketuk layar "Ketuk untuk mulai". Jika Sound Effect mati, tidak ada suara |
| Layar terkunci padahal tidak diatur | Parental Control menyala: cek Time Limit (waktu hari ini sudah habis?) dan Curfew. Orang tua: tombol *Untuk orang tua* |
| Lesson selesai tapi muncul "Terjadi kesalahan pada database" | Lihat terminal backend: baris `[DB] ... gagal:` menyebut query yang bermasalah. Buka http://localhost:3000/health/db untuk mengecek apakah semua tabel/kolom sudah ada (migrasi 001 & 002). Backend terbaru menyimpan progres lebih dulu, jadi lesson tetap tercatat meski streak gagal diperbarui |
| Suara efek tidak terdengar | "Sound Effect" di Settings mati, volume HP nol / mode senyap, atau (web) browser butuh satu ketukan dulu sebelum boleh memutar suara |
| Server error 500 | Lihat log terminal backend; biasanya `schema.sql` belum dijalankan atau key Supabase salah |

## Yang belum ada
- Lesson huruf lain di luar Unit 1-2 (tambah lewat SQL), lesson kata/suku kata, dan bunyi fonetik huruf
- Video & teks untuk dongeng selain Malin Kundang (isi lewat Supabase, lihat bagian "Video & isi dongeng")

## Logo
Logo ada di `frontend/assets/images/`: `logo.png` (lengkap, dipakai di Landing & Splash) dan `logo_icon.png` (tanpa tulisan, dipakai di header & sidebar). Ganti file ini untuk mengubah logo.
