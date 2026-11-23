import { supabaseAdmin } from '../config/supabase.js';
import { must } from '../utils/errors.js';
import { getEntitlement } from './subscriptionService.js';

/** Jenis lesson yang dikenal aplikasi versi 1.x. */
const LEGACY_KINDS = new Set(['letter', 'review', 'quiz', 'challenge']);

/** Aplikasi baru mengirim header "X-Bebaca-Client: 2" (atau lebih). */
export const isLegacyClient = (req) => !(Number(req.get('x-bebaca-client')) >= 2);

/**
 * Hitung status tiap lesson (fungsi murni, mudah diuji).
 * completed = sudah selesai | unlocked = lesson berikutnya (hanya 1) | locked = sisanya.
 * @param sections  hasil query sections + lessons
 * @param doneStars Map<lessonId, stars> lesson yang sudah selesai user ini
 * @param isPremium user berlangganan Bebaca Premium?
 * Section premium milik user gratis ditandai premiumLocked (lesson-nya tetap terlihat).
 */
export function computeSections(sections, doneStars, isPremium = false, { legacy = false } = {}) {
  let unlockedAssigned = false;

  // Aplikasi versi lama belum bisa membuka lesson suku kata / kata / kalimat:
  // lesson itu (dan section yang jadi kosong) tidak dikirim ke mereka.
  const visible = sections
    .map((sec) => ({ ...sec, lessons: (sec.lessons ?? []).filter((l) => !legacy || LEGACY_KINDS.has(l.kind)) }))
    .filter((sec) => sec.lessons.length > 0);

  return visible.map((sec) => {
    const lessons = [...sec.lessons]
      .sort((a, b) => a.order_index - b.order_index)
      .map((l) => {
        let status;
        if (doneStars.has(l.id)) {
          status = 'completed';
        } else if (!unlockedAssigned) {
          status = 'unlocked';
          unlockedAssigned = true;
        } else {
          status = 'locked';
        }
        return {
          id: l.id,
          title: l.title,
          kind: l.kind,
          letters: l.letters ?? [],
          status,
          stars: status === 'completed' ? doneStars.get(l.id) : 0,
        };
      });

    const premium = Boolean(sec.is_premium);
    return {
      unit: sec.unit,
      section: sec.section,
      title: sec.title,
      guide: sec.guide,
      isPremium: premium,
      premiumLocked: premium && !isPremium,
      lessons,
    };
  });
}

/** Susun daftar section + status lesson untuk 1 user. [legacy] = aplikasi versi lama. */
export async function buildSections(userId, { legacy = false } = {}) {
  const [secRes, progRes, entitlement] = await Promise.all([
    supabaseAdmin
      .from('sections')
      .select('id, unit, section, title, guide, is_premium, lessons(id, order_index, title, kind, letters)')
      .order('unit')
      .order('section'),
    supabaseAdmin.from('lesson_progress').select('lesson_id, stars').eq('user_id', userId),
    getEntitlement(userId),
  ]);

  const sections = must(secRes);
  const done = new Map(must(progRes).map((r) => [r.lesson_id, r.stars]));
  return computeSections(sections, done, entitlement.isPremium, { legacy });
}
