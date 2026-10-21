import { supabaseAdmin } from '../config/supabase.js';
import { must } from '../utils/errors.js';

/** Pastikan baris profiles & user_settings ada (tidak menimpa yang sudah ada). */
export async function ensureUserRows(user, { nama, umur } = {}) {
  const meta = user.user_metadata || {};
  const displayName =
    nama || meta.full_name || meta.name || user.email?.split('@')[0] || 'Pengguna';

  must(
    await supabaseAdmin.from('profiles').upsert(
      {
        id: user.id,
        nama: displayName,
        umur: umur ?? null,
        avatar_url: meta.avatar_url || meta.picture || null,
      },
      { onConflict: 'id', ignoreDuplicates: true }
    ),
    'Gagal membuat profil'
  );

  must(
    await supabaseAdmin
      .from('user_settings')
      .upsert({ user_id: user.id }, { onConflict: 'user_id', ignoreDuplicates: true }),
    'Gagal membuat pengaturan'
  );
}
