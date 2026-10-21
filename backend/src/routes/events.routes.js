import { Router } from 'express';
import { z } from 'zod';
import { supabaseAdmin } from '../config/supabase.js';
import { must } from '../utils/errors.js';
import { notifyMonitor } from '../services/realtimeService.js';

const router = Router();

const TYPES = [
  'app_open', 'app_pause', 'tab', 'heartbeat', 'ui',
  'lesson_start', 'step', 'answer', 'lesson_complete', 'lesson_exit',
  'story_open', 'story_page', 'story_read', 'story_complete',
];

const batchSchema = z.object({
  events: z
    .array(
      z.object({
        type: z.enum(TYPES),
        data: z.record(z.string(), z.unknown()).optional(),
        at: z.string().datetime({ offset: true }).optional(), // waktu kejadian di HP
      })
    )
    .min(1)
    .max(50),
});

// POST /api/events  { events: [{type, data?, at?}] }
// Dikirim aplikasi anak berkala (dikumpulkan dulu supaya hemat kuota).
router.post('/', async (req, res) => {
  const { events } = batchSchema.parse(req.body);
  const now = Date.now();
  const rows = events.map((e) => {
    // waktu dari HP dipakai, tapi tidak boleh di masa depan / lebih dari 1 hari lalu
    let at = e.at ? Date.parse(e.at) : now;
    if (!Number.isFinite(at) || at > now || at < now - 86400000) at = now;
    // 'step' boleh lebih besar (berisi goresan tulisan anak untuk pratinjau)
    const limit = e.type === 'step' ? 8000 : 2000;
    const data = JSON.stringify(e.data ?? {}).length > limit ? {} : e.data ?? {};
    return { user_id: req.user.id, type: e.type, data, created_at: new Date(at).toISOString() };
  });
  must(await supabaseAdmin.from('learning_events').insert(rows), undefined, 'simpan kejadian');

  // beri tahu halaman Pantau Langsung (realtime). Gagal = tidak apa-apa, halaman tetap
  // memperbarui sendiri secara berkala.
  await notifyMonitor(req.user.id).catch((e) => console.warn('[pantau] realtime gagal:', e.message));
  res.json({ saved: rows.length });
});

export default router;
