# Bebaca Backend (Node.js + Express + Supabase)

## 1. Siapkan Supabase
1. Buat project di https://supabase.com
2. Buka **SQL Editor**, jalankan berurutan:
   1. isi `supabase/schema.sql`
   2. isi `supabase/seed.sql` (cukup sekali; berisi Unit 1-2 dan data dongeng)
3. Buka **Project Settings -> API**, salin:
   - Project URL
   - anon / publishable key
   - service_role / secret key (RAHASIA, hanya untuk backend)
4. (Opsional) **Authentication -> Providers -> Email**: matikan "Confirm email"
   kalau tidak ingin verifikasi email (backend sudah membuat akun yang langsung aktif).

## 2. Jalankan backend
```bash
cp .env.example .env     # lalu isi nilainya
npm install
npm run dev              # http://localhost:3000
```
Cek: `curl localhost:3000/health`

## Swagger (tanpa Postman)
Buka **http://localhost:3000/docs** di browser. Cara pakai:
1. `POST /api/auth/register` -> Try it out -> Execute.
2. `POST /api/auth/login` -> salin `access_token` dari response.
3. Klik tombol **Authorize** (kanan atas) -> tempel token (tanpa kata `Bearer`) -> Authorize.
4. Semua endpoint bergembok kini bisa dicoba. Token tersimpan walau halaman di-refresh.

Spesifikasi mentah (JSON) ada di `/docs.json`. Dokumentasi ditulis di `src/docs/openapi.js`;
kalau menambah endpoint baru, tambahkan juga di file itu.

## 3. Endpoint
Semua endpoint selain `/api/auth/*` butuh header `Authorization: Bearer <access_token>`.
Error selalu berbentuk `{ "message": "..." }`.

| Method | Path | Keterangan |
|---|---|---|
| POST | /api/auth/register | `{umur, nama, email, password}` |
| POST | /api/auth/login | `{email, password}` -> `access_token`, `refresh_token` |
| POST | /api/auth/refresh | `{refresh_token}` |
| POST | /api/auth/logout | |
| GET | /api/lessons | daftar unit + status lesson (`locked/unlocked/completed`) |
| POST | /api/lessons/:id/complete | tandai selesai, update streak & materi terakhir |
| GET | /api/stories | kategori + dongeng |
| GET | /api/stories/:id | detail + isi dongeng |
| GET | /api/profile | profil |
| PUT | /api/profile | `{nama?, tanggalLahir?, umur?, tingkatKesulitan?, avatarUrl?}` |
| GET | /api/settings | pengaturan + timespent hari ini |
| PUT | /api/settings | kirim field yang berubah saja |
| POST | /api/settings/usage | `{minutes}` tambah waktu belajar hari ini |
| GET | /api/subscription | status Bebaca Premium |
| POST | /api/subscription/activate | **simulasi** `{plan: monthly\|yearly}` jadi premium tanpa bayar |
| POST | /api/subscription/deactivate | **simulasi** kembali ke gratis |

Contoh:
```bash
curl -X POST localhost:3000/api/auth/register -H 'Content-Type: application/json' \
  -d '{"umur":7,"nama":"Budi","email":"budi@mail.com","password":"rahasia123"}'

curl -X POST localhost:3000/api/auth/login -H 'Content-Type: application/json' \
  -d '{"email":"budi@mail.com","password":"rahasia123"}'

curl localhost:3000/api/lessons -H "Authorization: Bearer <access_token>"
```

## 4. Bebaca Premium (sementara MODE SIMULASI)
Belum ada pembayaran sungguhan. Di aplikasi, tombol "Langganan Sekarang" langsung menjadikan akun
premium (30 hari / 365 hari), dan "Pulihkan pembelian" mengembalikan akun ke gratis.
Endpoint simulasi otomatis ditolak saat `NODE_ENV=production`.

**Database:** jalankan `supabase/migrations/003_premium.sql` (instalasi baru: sudah ada di `schema.sql` + `seed.sql`).
- Bawaan: Unit 1 gratis, Unit 2 dst premium; 2 dongeng pertama tiap kategori gratis.
- Ubah kapan saja lewat kolom `is_premium` di tabel `sections` / `stories` (tanpa update aplikasi).

Nanti saat memakai Google Play Billing / Apple In-App Purchase, ganti `activate()` di
`src/services/subscriptionService.js` dengan verifikasi pembelian ke toko.

## 5. Catatan
- Aturan lesson: lesson berikutnya otomatis terbuka setelah lesson sebelumnya selesai
  (urut lintas unit). Lesson terkunci tidak bisa diselesaikan (403).
- Konten premium untuk akun gratis ditolak dengan status 402 (lesson & isi dongeng).
- Streak dihitung dengan zona waktu WIB (Asia/Jakarta).
- Semua tabel memakai RLS tanpa policy, jadi data hanya bisa diakses lewat backend ini.
- Aplikasi Flutter di emulator Android memanggil `http://10.0.2.2:3000`;
  di HP asli pakai IP komputer / URL hasil deploy.
- Deploy (Render/Railway): set semua variabel di `.env.example`, `TRUST_PROXY=true`,
  start command `npm start`. Pakai HTTPS di produksi.
