-- =====================================================
-- Migrasi 004: PIN orang tua (menggantikan soal penjumlahan)
-- Jalankan di Supabase SQL Editor. Aman dijalankan ulang.
-- =====================================================

-- Disimpan sebagai hash (scrypt), bukan angka aslinya.
alter table public.user_settings add column if not exists parent_pin_hash text;
