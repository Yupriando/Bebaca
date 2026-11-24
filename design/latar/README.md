# Latar Bebaca

Panduan lengkap dengan gambar: https://claude.ai/artifact/DKNxMDr4DVSwBK3EXLZ7WP

| # | File | Muncul di | Ukuran (px) |
|---|------|-----------|-------------|
| 1 | `latar_utama.png` | Menu Belajar, Dongeng, Profil, Pengaturan, Premium, Laporan, Pantau Langsung, Detail dongeng | 2560 × 1440 |
| 2 | `peta_unit_1.png` … `peta_unit_9.png` | Peta jalan di menu Belajar (1 per unit) | lebar 1640, tinggi di bawah |
| 3 | `latar_belajar.png` | Semua soal pelajaran + layar hasil bintang | 2560 × 1440 |
| 4 | `latar_dongeng.png` | Membaca dongeng + halaman akhir cerita | 2560 × 1440 |
| 5 | `latar_pembuka.png` | Layar pembuka (logo) | 2560 × 1440 |
| 6 | `latar_masuk.png` | Halaman awal, Login, Daftar | 2560 × 1440 |
| 7 | `latar_terkunci.png` (opsional) | Layar "Waktu belajar habis" | 2560 × 1440 |

Tinggi peta: Unit 1, 2, 4, 6 = 1914 · Unit 3 = 1706 · Unit 5, 7, 8 = 2122 · Unit 9 = 1290.

## Isi folder

- `sekarang/` latar yang dipakai aplikasi sekarang, tanpa tombol dan kartu, dengan ukuran dan nama akhir. Ini bahan untuk di-generate ulang; prompt dan pengaturannya ada di `sekarang/PROMPT.md`.
- `cetakan/` PNG transparan berisi area aman, bagian yang bisa terpotong di HP/tablet, bagian yang tertutup kartu, dan teks yang menempel di latar. Taruh sebagai lapisan paling atas dengan opacity 50–70%.
- `ui/` tampilan aplikasi tanpa latar (laptop 16:9). Taruh di atas gambarmu untuk melihat hasil akhirnya.
- `contoh/` pratinjau seperti di halaman panduan.
- `hasil/` taruh gambar yang sudah jadi di sini, dengan nama file persis seperti tabel (PNG atau JPG kualitas tinggi, tanpa transparan).

Aturan singkat: gambar penuh sampai tepi kanvas, hal penting di dalam garis hijau, tanpa huruf/angka/logo di gambar, satu gaya untuk semua latar.
