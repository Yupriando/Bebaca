import { Router } from 'express';
import { supabaseAdmin } from '../config/supabase.js';
import { HttpError } from '../utils/errors.js';

// ======================================================================
// Keep-alive: Supabase (paket gratis) menghentikan project yang tidak ada aktivitas
// database selama 7 hari. Endpoint ini menjalankan query kecil ke database dan
// dipanggil otomatis tiap hari oleh Vercel Cron (vercel.json) + GitHub Actions (cadangan).
// ======================================================================

const router = Router();

// GET /api/keepalive
// Kalau env CRON_SECRET diisi, wajib header "Authorization: Bearer <CRON_SECRET>"
// (Vercel Cron mengirim header ini otomatis).
router.get('/', async (req, res) => {
  const secret = process.env.CRON_SECRET;
  if (secret && req.headers.authorization !== `Bearer ${secret}`) {
    throw new HttpError(401, 'Tidak diizinkan');
  }

  const started = Date.now();
  // query ringan ke beberapa tabel = aktivitas database nyata bagi Supabase
  const [stories, lessons] = await Promise.all([
    supabaseAdmin.from('stories').select('id').limit(1),
    supabaseAdmin.from('lessons').select('id').limit(1),
  ]);
  const error = stories.error || lessons.error;
  if (error) {
    console.error('[keepalive] gagal:', error.message);
    throw new HttpError(503, 'Database tidak merespons', error.message);
  }

  console.log(`[keepalive] database aktif (${Date.now() - started} ms)`);
  res.json({
    status: 'ok',
    database: 'aktif',
    ms: Date.now() - started,
    at: new Date().toISOString(),
  });
});

export default router;
