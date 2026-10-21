import crypto from 'node:crypto';
import { Router } from 'express';
import { z } from 'zod';
import { supabaseAdmin } from '../config/supabase.js';
import { must } from '../utils/errors.js';
import { buildReport } from '../services/reportService.js';
import { getEntitlement } from '../services/subscriptionService.js';

const router = Router();

// GET /api/report?week=0  -> Laporan Perkembangan (0 = minggu ini, 1 = minggu lalu, ...)
// Akun gratis: ringkasan & aktivitas. Premium: + grafik harian, penguasaan huruf, saran.
router.get('/', async (req, res) => {
  const { week } = z
    .object({ week: z.coerce.number().int().min(0).max(52).default(0) })
    .parse(req.query);
  const { isPremium } = await getEntitlement(req.user.id);
  res.json(await buildReport(req.user.id, { detailed: isPremium, weekOffset: week }));
});

// ---------------- Pantau Langsung (QR) ----------------
const hashToken = (t) => crypto.createHash('sha256').update(t).digest('hex');
const baseUrl = (req) => `${req.protocol}://${req.get('host')}`;

// GET /api/report/monitor-link -> { active } (token tidak bisa dibaca ulang; buat baru untuk QR)
router.get('/monitor-link', async (req, res) => {
  const row = must(
    await supabaseAdmin.from('parent_links').select('created_at').eq('user_id', req.user.id).maybeSingle()
  );
  res.json({ active: Boolean(row), createdAt: row?.created_at ?? null });
});

// POST /api/report/monitor-link -> buat tautan BARU (tautan lama otomatis tidak berlaku)
router.post('/monitor-link', async (req, res) => {
  const token = crypto.randomBytes(24).toString('base64url');
  must(
    await supabaseAdmin.from('parent_links').upsert(
      { user_id: req.user.id, token_hash: hashToken(token), created_at: new Date().toISOString() },
      { onConflict: 'user_id' }
    )
  );
  res.json({ active: true, url: `${baseUrl(req)}/pantau/${token}` });
});

// DELETE /api/report/monitor-link -> cabut akses (QR lama tidak bisa dipakai lagi)
router.delete('/monitor-link', async (req, res) => {
  must(await supabaseAdmin.from('parent_links').delete().eq('user_id', req.user.id));
  res.json({ active: false });
});

export { hashToken };
export default router;
