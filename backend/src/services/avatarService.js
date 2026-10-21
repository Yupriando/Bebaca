import { supabaseAdmin } from '../config/supabase.js';
import { HttpError } from '../utils/errors.js';
import { sniffImageType } from '../utils/image.js';

export const AVATAR_BUCKET = 'avatars';
export const MAX_AVATAR_BYTES = 2 * 1024 * 1024; // 2 MB

let bucketReady = false;

/** Buat bucket publik "avatars" otomatis jika belum ada (cukup sekali per proses). */
async function ensureBucket() {
  if (bucketReady) return;
  const { data } = await supabaseAdmin.storage.getBucket(AVATAR_BUCKET);
  if (!data) {
    const { error } = await supabaseAdmin.storage.createBucket(AVATAR_BUCKET, {
      public: true,
      fileSizeLimit: MAX_AVATAR_BYTES,
      allowedMimeTypes: ['image/jpeg', 'image/png', 'image/webp'],
    });
    if (error && !/already exists|duplicate/i.test(error.message)) {
      console.error('[avatar] gagal membuat bucket:', error);
      throw new HttpError(500, 'Gagal menyiapkan penyimpanan foto', error.message);
    }
  }
  bucketReady = true;
}

/** Validasi file lalu unggah. Mengembalikan URL publik. */
export async function uploadAvatar(userId, file) {
  if (!file) throw new HttpError(400, 'Foto belum dipilih (kirim field "avatar")');
  const type = sniffImageType(file.buffer);
  if (!type) throw new HttpError(400, 'File harus berupa gambar JPEG, PNG, atau WebP');

  await ensureBucket();
  const path = `${userId}/avatar-${Date.now()}.${type.ext}`; // nama unik -> tidak kena cache
  const { error } = await supabaseAdmin.storage.from(AVATAR_BUCKET).upload(path, file.buffer, {
    contentType: type.mime,
    cacheControl: '31536000',
    upsert: false,
  });
  if (error) {
    console.error('[avatar] upload gagal:', error);
    throw new HttpError(500, 'Gagal mengunggah foto', error.message);
  }
  return supabaseAdmin.storage.from(AVATAR_BUCKET).getPublicUrl(path).data.publicUrl;
}

/** Hapus file lama (best effort). Foto dari luar (mis. akun Google) dilewati. */
export async function removeAvatarByUrl(url) {
  if (!url) return;
  const marker = `/${AVATAR_BUCKET}/`;
  const i = url.indexOf(marker);
  if (i === -1) return;
  const path = decodeURIComponent(url.slice(i + marker.length).split('?')[0]);
  try {
    await supabaseAdmin.storage.from(AVATAR_BUCKET).remove([path]);
  } catch (e) {
    console.error('[avatar] gagal menghapus file lama:', e);
  }
}
