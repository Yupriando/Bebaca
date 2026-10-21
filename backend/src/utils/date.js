const WIB_OFFSET_MS = 7 * 3600 * 1000; // WIB = UTC+7, tanpa DST

/**
 * Tanggal (YYYY-MM-DD) di zona waktu WIB. offsetDays: -1 = kemarin.
 * Dihitung manual (bukan toLocaleDateString) supaya hasilnya selalu sama
 * di semua versi/instalasi Node, apa pun pengaturan bahasa/ICU-nya.
 */
export function jakartaDate(offsetDays = 0) {
  return new Date(Date.now() + WIB_OFFSET_MS + offsetDays * 86400000)
    .toISOString()
    .slice(0, 10);
}

/** Umur (tahun penuh) dari tanggal lahir "YYYY-MM-DD", dihitung terhadap tanggal WIB hari ini. */
export function ageFromBirthDate(dateStr) {
  const [by, bm, bd] = dateStr.split('-').map(Number);
  const [ty, tm, td] = jakartaDate(0).split('-').map(Number);
  let age = ty - by;
  if (tm < bm || (tm === bm && td < bd)) age--;
  return age;
}

/** Tanggal lahir valid: tanggal nyata (bukan 31 Feb), tidak di masa depan, maksimal 120 tahun lalu. */
export function isValidBirthDate(dateStr) {
  if (!/^\d{4}-\d{2}-\d{2}$/.test(dateStr)) return false;
  const [y, m, d] = dateStr.split('-').map(Number);
  const dt = new Date(Date.UTC(y, m - 1, d));
  const real = dt.getUTCFullYear() === y && dt.getUTCMonth() === m - 1 && dt.getUTCDate() === d;
  if (!real) return false;
  if (dateStr > jakartaDate(0)) return false;
  return ageFromBirthDate(dateStr) <= 120;
}
