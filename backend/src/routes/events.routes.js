import { Router } from 'express';
import { z } from 'zod';
import { supabaseAdmin } from '../config/supabase.js';
import { must } from '../utils/errors.js';

const router = Router();

const TYPES = [
  'app_open', 'tab', 'heartbeat',
  'lesson_start', 'answer', 'lesson_complete', 'lesson_exit',
  'story_open', 'story_page', 'story_complete',
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
    const data = JSON.stringify(e.data ?? {}).length > 2000 ? {} : e.data ?? {};
    return { user_id: req.user.id, type: e.type, data, created_at: new Date(at).toISOString() };
  });
  must(await supabaseAdmin.from('learning_events').insert(rows), undefined, 'simpan kejadian');
  res.json({ saved: rows.length });
});

export default router;
