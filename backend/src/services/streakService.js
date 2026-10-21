import { supabaseAdmin } from '../config/supabase.js';
import { must } from '../utils/errors.js';
import { jakartaDate } from '../utils/date.js';
import { ensureUserRows } from './userService.js';

/**
 * Catat bahwa user belajar hari ini.
 * - sudah belajar hari ini  -> streak tetap
 * - terakhir belajar kemarin -> streak + 1
 * - selain itu               -> streak mulai lagi dari 1
 * @param user objek user dari Supabase Auth (req.user)
 */
export async function touchStreak(user) {
  const today = jakartaDate(0);
  const yesterday = jakartaDate(-1);

  const read = async () =>
    must(
      await supabaseAdmin
        .from('profiles')
        .select('hari_berturut, last_study_date')
        .eq('id', user.id)
        .maybeSingle(),
      undefined,
      'streak: baca profil'
    );

  let p = await read();
  if (!p) {
    // akun belum punya baris profil -> buatkan, lalu baca lagi
    await ensureUserRows(user);
    p = await read();
  }
  if (!p) return 0;

  if (p.last_study_date === today) return p.hari_berturut;

  const streak = p.last_study_date === yesterday ? p.hari_berturut + 1 : 1;
  must(
    await supabaseAdmin
      .from('profiles')
      .update({ hari_berturut: streak, last_study_date: today })
      .eq('id', user.id),
    undefined,
    'streak: simpan'
  );
  return streak;
}
