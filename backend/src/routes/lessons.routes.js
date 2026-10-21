import { Router } from 'express';
import { z } from 'zod';
import { supabaseAdmin } from '../config/supabase.js';
import { HttpError, must } from '../utils/errors.js';
import { buildSections } from '../services/lessonService.js';
import { touchStreak } from '../services/streakService.js';
import { ensureUserRows } from '../services/userService.js';

const router = Router();

// GET /api/lessons -> [{unit, section, title, guide, isPremium, premiumLocked, lessons:[{id,title,kind,letters,status,stars}]}]
router.get('/', async (req, res) => {
  res.json(await buildSections(req.user.id));
});

const completeSchema = z.object({
  stars: z.number().int().min(0).max(3).optional(),
});

// POST /api/lessons/:id/complete   body: { stars?: 0-3 }
// - lesson "unlocked"  -> disimpan sebagai selesai
// - lesson "completed" -> boleh diulang; bintang hanya naik, tidak turun
//
// Hanya penyimpanan progres (inti) yang boleh membuat request gagal. Memperbarui
// "materi terakhir" dan streak bersifat tambahan: kalau gagal, dicatat di log
// ([lessons] ...) tetapi lesson tetap tercatat selesai dan respons tetap sukses.
router.post('/:id/complete', async (req, res) => {
  const { id } = z
    .object({ id: z.string().uuid('ID lesson tidak valid') })
    .parse(req.params);
  const { stars } = completeSchema.parse(req.body ?? {});
  const earned = stars ?? 1;
  const userId = req.user.id;

  const sections = await buildSections(userId);
  let lesson = null;
  let section = null;
  for (const s of sections) {
    const found = s.lessons.find((l) => l.id === id);
    if (found) {
      lesson = found;
      section = s;
      break;
    }
  }

  if (!lesson) throw new HttpError(404, 'Lesson tidak ditemukan');
  if (section.premiumLocked) throw new HttpError(402, 'Lesson ini khusus Bebaca Premium');
  if (lesson.status === 'locked') throw new HttpError(403, 'Lesson masih terkunci');

  // ---- INTI: simpan progres ----
  let best = earned;
  const firstTime = lesson.status === 'unlocked';
  if (firstTime) {
    must(
      await supabaseAdmin
        .from('lesson_progress')
        .upsert(
          { user_id: userId, lesson_id: id, stars: earned },
          { onConflict: 'user_id,lesson_id', ignoreDuplicates: true }
        ),
      undefined,
      'simpan lesson_progress'
    );
  } else {
    best = Math.max(earned, lesson.stars ?? 0);
    if (best > (lesson.stars ?? 0)) {
      must(
        await supabaseAdmin
          .from('lesson_progress')
          .update({ stars: best })
          .eq('user_id', userId)
          .eq('lesson_id', id),
        undefined,
        'update bintang'
      );
    }
  }

  // ---- TAMBAHAN (best effort): materi terakhir + streak ----
  let hariBerturut = null;
  try {
    await ensureUserRows(req.user); // pastikan baris profil ada
    if (firstTime) {
      must(
        await supabaseAdmin
          .from('profiles')
          .update({
            materi_terakhir: `Unit ${section.unit}, Section ${section.section} - ${lesson.title}`,
          })
          .eq('id', userId),
        undefined,
        'update materi_terakhir'
      );
    }
    hariBerturut = await touchStreak(req.user);
  } catch (e) {
    console.error('[lessons] progres tersimpan, tetapi gagal memperbarui streak/materi terakhir:', e);
  }

  res.json({ message: 'Lesson selesai', hariBerturut, stars: best });
});

export default router;
