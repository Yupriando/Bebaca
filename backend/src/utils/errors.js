export class HttpError extends Error {
  constructor(status, message, detail) {
    super(message);
    this.status = status;
    this.detail = detail; // info teknis; hanya dikirim ke klien saat NODE_ENV != production
  }
}

/**
 * Lempar HttpError 500 jika query Supabase gagal, kalau tidak kembalikan datanya.
 * `label` menandai query mana yang gagal (muncul di log terminal sebagai [DB]).
 */
export function must(result, message = 'Terjadi kesalahan pada database', label = 'query') {
  if (result.error) {
    console.error(`[DB] ${label} gagal:`, result.error);
    throw new HttpError(
      500,
      message,
      `${label}: ${result.error.message || result.error.code || 'unknown'}`
    );
  }
  return result.data;
}
