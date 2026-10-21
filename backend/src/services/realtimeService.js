import { supabaseAdmin } from '../config/supabase.js';

// ======================================================================
// Pantau Langsung realtime: setiap ada kejadian belajar baru, kirim sinyal lewat
// Supabase Realtime (Broadcast). Halaman pantau orang tua yang sedang terbuka menerima
// sinyal ini dan langsung mengambil data terbaru (biasanya < 1 detik).
// Nama channel diturunkan dari hash token QR, jadi hanya pemegang QR yang tahu.
// ======================================================================

/** Nama channel untuk satu tautan pantau (sama dengan perhitungan di halaman pantau). */
export const monitorChannel = (tokenHash) => `pantau-${tokenHash.slice(0, 32)}`;

/** Kirim sinyal "ada data baru" ke halaman pantau milik user ini (kalau QR-nya aktif). */
export async function notifyMonitor(userId) {
  const { data: link } = await supabaseAdmin
    .from('parent_links')
    .select('token_hash')
    .eq('user_id', userId)
    .maybeSingle();
  if (!link) return; // orang tua belum membuat QR -> tidak perlu menyiarkan

  const channel = supabaseAdmin.channel(monitorChannel(link.token_hash));
  try {
    await channel.httpSend('update', { at: Date.now() }, { timeout: 3000 });
  } finally {
    supabaseAdmin.removeChannel(channel);
  }
}
