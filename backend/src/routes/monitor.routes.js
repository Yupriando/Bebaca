import { Router } from 'express';
import rateLimit from 'express-rate-limit';
import { supabaseAdmin } from '../config/supabase.js';
import { HttpError, must } from '../utils/errors.js';
import { buildLiveSnapshot } from '../services/reportService.js';
import { hashToken } from './report.routes.js';
import { PAGE_HTML, PAGE_JS } from '../monitor/page.js';
import { env } from '../config/env.js';

// Halaman pantau terhubung ke Supabase Realtime memakai anon key (memang publik; data
// tetap terlindungi RLS). Yang diterima halaman hanya sinyal "ada data baru".
const SUPABASE_JS = 'https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2.117.3/dist/umd/supabase.js';
const attr = (v) => String(v).replace(/[&"<>]/g, (c) => ({ '&': '&amp;', '"': '&quot;', '<': '&lt;', '>': '&gt;' })[c]);

// ======================================================================
// Pantau Langsung: halaman web PUBLIK yang dibuka orang tua dengan scan QR.
// Akses hanya lewat token rahasia di URL (/pantau/<token>). Tanpa login, tanpa aplikasi.
// Tidak ada gambar layar / suara anak yang dikirim: hanya kejadian belajar.
// ======================================================================

const router = Router();

router.use(
  rateLimit({
    windowMs: 60 * 1000,
    limit: 120,
    standardHeaders: true,
    legacyHeaders: false,
    message: { message: 'Terlalu banyak permintaan, tunggu sebentar' },
  })
);

// halaman ini pribadi: jangan diindeks mesin pencari, jangan di-cache
router.use((req, res, next) => {
  res.set('X-Robots-Tag', 'noindex, nofollow');
  res.set('Cache-Control', 'no-store');
  next();
});

const TOKEN_RE = /^[A-Za-z0-9_-]{20,64}$/;

async function userIdFromToken(token) {
  if (!TOKEN_RE.test(token)) throw new HttpError(404, 'Tautan pantau tidak berlaku');
  const row = must(
    await supabaseAdmin
      .from('parent_links')
      .select('user_id')
      .eq('token_hash', hashToken(token))
      .maybeSingle()
  );
  if (!row) throw new HttpError(404, 'Tautan pantau tidak berlaku');
  return row.user_id;
}

// GET /pantau/app.js -> skrip halaman (dipisah supaya lolos Content-Security-Policy)
router.get('/app.js', (req, res) => {
  res.type('application/javascript').send(PAGE_JS);
});

// GET /pantau/:token -> halaman pantau
router.get('/:token', (req, res) => {
  const sb = new URL(env.supabaseUrl);
  res.set(
    'Content-Security-Policy',
    "default-src 'self'; script-src 'self' https://cdn.jsdelivr.net; " +
      "style-src 'self' 'unsafe-inline' https://fonts.googleapis.com; font-src https://fonts.gstatic.com; " +
      `img-src 'self' https: data:; connect-src 'self' ${sb.origin} wss://${sb.host}`
  );
  res.type('html').send(
    PAGE_HTML.replace('__SB_URL__', attr(env.supabaseUrl))
      .replace('__SB_KEY__', attr(env.supabaseAnonKey))
      .replace('__SB_JS__', SUPABASE_JS)
  );
});

// GET /pantau/:token/data -> data terbaru (diambil halaman tiap beberapa detik)
router.get('/:token/data', async (req, res) => {
  const userId = await userIdFromToken(req.params.token);
  res.json(await buildLiveSnapshot(userId));
});

export default router;
